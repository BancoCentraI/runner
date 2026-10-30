import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_config.dart';

/// Usuário atual (os dados de cada pessoa ficam separados).
String _uidAtual() => FirebaseAuth.instance.currentUser?.uid ?? 'anonimo';

/// Cabeçalhos com o token do Firebase, pego na hora do envio.
Future<Map<String, String>> _cabecalhos({bool comCorpo = false}) async {
  String? token;
  try {
    token = await FirebaseAuth.instance.currentUser?.getIdToken();
  } catch (_) {}
  return {
    if (comCorpo) 'Content-Type': 'application/json; charset=utf-8',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

/// "30/10 às 15:20"
String formatarSalvoEm(DateTime d) {
  final l = d.toLocal();
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(l.day)}/${dois(l.month)} às ${dois(l.hour)}:${dois(l.minute)}';
}

// =============================================================================
// 1. CACHE DAS RESPOSTAS
// =============================================================================

class CacheLocal {
  CacheLocal._();

  static String _chave(String nome) => 'cache_v1_${_uidAtual()}_$nome';

  static Future<void> salvar(String nome, Object? dados) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _chave(nome),
        json.encode({
          'salvoEm': DateTime.now().toUtc().toIso8601String(),
          'dados': dados,
        }),
      );
    } catch (e) {
      debugPrint('[CACHE] Erro ao salvar $nome: $e');
    }
  }

  /// Devolve os dados salvos e quando foram salvos (null se não houver).
  static Future<({Object? dados, DateTime? salvoEm})?> ler(String nome) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_chave(nome));
      if (texto == null) return null;
      final corpo = json.decode(texto);
      if (corpo is! Map<String, dynamic>) return null;
      return (
        dados: corpo['dados'],
        salvoEm: DateTime.tryParse('${corpo['salvoEm']}')?.toLocal(),
      );
    } catch (e) {
      debugPrint('[CACHE] Erro ao ler $nome: $e');
      return null;
    }
  }

  static Future<void> remover(String nome) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chave(nome));
    } catch (_) {}
  }
}

// =============================================================================
// 2. FILA DE ENVIOS
// =============================================================================

class ItemFila {
  ItemFila({
    required this.id,
    required this.uid,
    required this.metodo,
    required this.caminho,
    this.corpo,
    this.substitui,
    this.idLocal,
    required this.criadoEm,
    this.tentativas = 0,
    DateTime? proximaTentativa,
    this.ultimoErro,
  }) : proximaTentativa = proximaTentativa ?? DateTime.now();

  /// Identificador do item dentro da fila.
  final String id;

  /// Dono do item (só é enviado com esse usuário logado).
  final String uid;

  /// POST, PUT, PATCH ou DELETE.
  final String metodo;

  /// Ex.: "/corridas". Pode conter {{local:abc}}, trocado pelo id real
  /// quando o item que criou "abc" for enviado (usado nos alertas).
  final String caminho;
  final Map<String, dynamic>? corpo;

  /// Itens com a mesma chave se substituem: só o mais novo é enviado.
  /// Ex.: "preferencias" — não adianta mandar 10 versões antigas.
  final String? substitui;

  /// Se a resposta tiver "id", ele passa a valer no lugar de {{local:idLocal}}.
  final String? idLocal;

  final DateTime criadoEm;
  int tentativas;
  DateTime proximaTentativa;
  String? ultimoErro;

  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'metodo': metodo,
        'caminho': caminho,
        'corpo': corpo,
        'substitui': substitui,
        'idLocal': idLocal,
        'criadoEm': criadoEm.toUtc().toIso8601String(),
        'tentativas': tentativas,
        'proximaTentativa': proximaTentativa.toUtc().toIso8601String(),
        'ultimoErro': ultimoErro,
      };

  static ItemFila? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    final id = j['id']?.toString();
    final metodo = j['metodo']?.toString();
    final caminho = j['caminho']?.toString();
    if (id == null || metodo == null || caminho == null) return null;
    final corpo = j['corpo'];
    return ItemFila(
      id: id,
      uid: j['uid']?.toString() ?? 'anonimo',
      metodo: metodo,
      caminho: caminho,
      corpo: corpo is Map<String, dynamic> ? corpo : null,
      substitui: j['substitui']?.toString(),
      idLocal: j['idLocal']?.toString(),
      criadoEm:
          DateTime.tryParse('${j['criadoEm']}')?.toLocal() ?? DateTime.now(),
      tentativas: (j['tentativas'] as num?)?.toInt() ?? 0,
      proximaTentativa:
          DateTime.tryParse('${j['proximaTentativa']}')?.toLocal(),
      ultimoErro: j['ultimoErro']?.toString(),
    );
  }
}

class FilaOffline {
  FilaOffline._();
  static final FilaOffline instancia = FilaOffline._();

  static const _chaveFila = 'fila_offline_v1';
  static const _chaveIds = 'fila_ids_v1';
  static const _chaveFalhas = 'fila_falhas_v1';

  final List<ItemFila> _itens = [];

  /// idLocal -> id que a API devolveu.
  final Map<String, String> _ids = {};

  bool _carregada = false;

  /// Quantos envios do usuário atual estão esperando. Útil para a interface.
  final ValueNotifier<int> pendentes = ValueNotifier<int>(0);

  Future<void> carregar() async {
    if (_carregada) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_chaveFila);
      if (texto != null) {
        final lista = json.decode(texto);
        if (lista is List) {
          _itens
            ..clear()
            ..addAll(lista.map(ItemFila.fromJson).whereType<ItemFila>());
        }
      }
      final ids = prefs.getString(_chaveIds);
      if (ids != null) {
        final mapa = json.decode(ids);
        if (mapa is Map) {
          mapa.forEach((k, v) => _ids['$k'] = '$v');
        }
      }
    } catch (e) {
      debugPrint('[FILA] Erro ao carregar: $e');
    }
    _carregada = true;
    _atualizarContagem();
  }

  Future<void> _salvar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _chaveFila, json.encode(_itens.map((i) => i.toJson()).toList()));
      await prefs.setString(_chaveIds, json.encode(_ids));
    } catch (e) {
      debugPrint('[FILA] Erro ao salvar: $e');
    }
    _atualizarContagem();
  }

  void _atualizarContagem() {
    final uid = _uidAtual();
    pendentes.value = _itens.where((i) => i.uid == uid).length;
  }

  /// Coloca um envio na fila (já salvo no aparelho quando retorna).
  Future<ItemFila> adicionar({
    required String metodo,
    required String caminho,
    Map<String, dynamic>? corpo,
    String? substitui,
    String? idLocal,
  }) async {
    await carregar();
    final uid = _uidAtual();
    if (substitui != null) {
      _itens.removeWhere((i) => i.uid == uid && i.substitui == substitui);
    }
    final item = ItemFila(
      id: novoIdLocal(),
      uid: uid,
      metodo: metodo.toUpperCase(),
      caminho: caminho,
      corpo: corpo,
      substitui: substitui,
      idLocal: idLocal,
      criadoEm: DateTime.now(),
    );
    _itens.add(item);
    await _salvar();
    debugPrint('[FILA] + ${item.metodo} ${item.caminho} '
        '(${pendentes.value} pendentes)');
    return item;
  }

  bool contem(String id) => _itens.any((i) => i.id == id);

  /// Corpos dos envios pendentes do usuário atual (ex.: corridas não enviadas).
  List<Map<String, dynamic>> corpos({
    required String metodo,
    required String caminho,
  }) {
    final uid = _uidAtual();
    return _itens
        .where((i) =>
            i.uid == uid &&
            i.metodo == metodo.toUpperCase() &&
            i.caminho == caminho &&
            i.corpo != null)
        .map((i) => i.corpo!)
        .toList();
  }

  /// Caminhos pendentes do usuário atual para um método (ex.: DELETEs).
  List<String> caminhos(String metodo) {
    final uid = _uidAtual();
    return _itens
        .where((i) => i.uid == uid && i.metodo == metodo.toUpperCase())
        .map((i) => i.caminho)
        .toList();
  }

  // ----- usados pelo Sincronizador -----

  List<ItemFila> _prontos(DateTime agora) {
    final uid = _uidAtual();
    return _itens
        .where((i) => i.uid == uid && !i.proximaTentativa.isAfter(agora))
        // Espera o item que cria o id (ex.: localização de um alerta).
        .where((i) => _resolverCaminho(i) != null)
        .toList();
  }

  /// Troca {{local:abc}} pelo id real. Null = ainda não dá para enviar.
  String? _resolverCaminho(ItemFila item) {
    String? faltando;
    final caminho = item.caminho.replaceAllMapped(
      RegExp(r'\{\{local:([^}]+)\}\}'),
      (m) {
        final real = _ids[m.group(1)!];
        if (real == null) faltando = m.group(1);
        return real ?? m.group(0)!;
      },
    );
    if (faltando == null) return caminho;

    // O item que cria esse id ainda está na fila? Então espera por ele.
    final criadorNaFila = _itens.any((i) => i.idLocal == faltando);
    return criadorNaFila ? null : '';
  }

  Future<void> _concluir(ItemFila item, {String? idServidor}) async {
    _itens.removeWhere((i) => i.id == item.id);
    if (item.idLocal != null && idServidor != null && idServidor.isNotEmpty) {
      _ids[item.idLocal!] = idServidor;
    }
    await _salvar();
  }

  Future<void> _adiar(ItemFila item, String erro) async {
    item.tentativas++;
    item.ultimoErro = erro;
    // 30 s, 1 min, 2 min, 4 min... até 30 min, com uma pequena variação
    // para vários celulares não tentarem todos no mesmo segundo.
    final base = 30 * math.pow(2, math.min(item.tentativas - 1, 6)).toInt();
    final segundos = math.min(base, 30 * 60) + math.Random().nextInt(10);
    item.proximaTentativa = DateTime.now().add(Duration(seconds: segundos));
    await _salvar();
  }

  /// Erro que não adianta repetir (ex.: 400 dados inválidos): sai da fila e
  /// fica num registro de falhas para você investigar.
  Future<void> _descartar(ItemFila item, String erro) async {
    _itens.removeWhere((i) => i.id == item.id);
    try {
      final prefs = await SharedPreferences.getInstance();
      final atual = prefs.getStringList(_chaveFalhas) ?? [];
      atual.add(json.encode({...item.toJson(), 'erroFinal': erro}));
      await prefs.setStringList(_chaveFalhas,
          atual.length > 50 ? atual.sublist(atual.length - 50) : atual);
    } catch (_) {}
    await _salvar();
    debugPrint('[FILA] Descartado ${item.metodo} ${item.caminho}: $erro');
  }
}

/// Id único gerado no aparelho.
String novoIdLocal() {
  final r = math.Random();
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${r.nextInt(1 << 32).toRadixString(36)}';
}

// =============================================================================
// 3. SINCRONIZADOR
// =============================================================================

enum ResultadoEnvio {
  /// A API recebeu agora.
  enviado,

  /// Sem internet ou API fora: salvo no aparelho, será enviado depois.
  naFila,

  /// A API recusou de vez (ex.: dados inválidos). Não será reenviado.
  recusado,
}

class Sincronizador with WidgetsBindingObserver {
  Sincronizador._();
  static final Sincronizador instancia = Sincronizador._();

  // ---- Limites (rate limit) ----
  static const periodo = Duration(minutes: 5);
  static const _intervaloAutomatico = Duration(seconds: 20);
  static const _intervaloImediato = Duration(seconds: 3);
  static const _maxPorRodada = 15;
  static const _pausaEntreEnvios = Duration(milliseconds: 300);
  static const _timeout = Duration(seconds: 15);

  final _fila = FilaOffline.instancia;
  Timer? _timer;
  StreamSubscription<dynamic>? _conexao;
  bool _iniciado = false;
  bool _rodando = false;
  bool _online = true;
  DateTime _ultimaRodada = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _pausadoAte = DateTime.fromMillisecondsSinceEpoch(0);

  /// Resultado final de cada item enviado/recusado (por id do item).
  final Map<String, ResultadoEnvio> _resultados = {};

  /// Aumenta toda vez que algo é enviado com sucesso. As telas escutam
  /// para recarregar (ex.: a corrida pendente agora já conta na API).
  final ValueNotifier<int> enviados = ValueNotifier<int>(0);

  /// Quando a última sincronização terminou sem pendências.
  DateTime? ultimaSincronizacao;

  /// Chame uma vez no main(), depois do Firebase.
  Future<void> iniciar() async {
    if (_iniciado) return;
    _iniciado = true;
    await _fila.carregar();

    WidgetsBinding.instance.addObserver(this);

    // Internet voltou -> tenta enviar.
    try {
      _conexao = Connectivity().onConnectivityChanged.listen((dynamic r) {
        final lista = r is List ? r : [r];
        final online = lista.any((x) => x != ConnectivityResult.none);
        final voltou = online && !_online;
        _online = online;
        if (voltou) {
          debugPrint('[SYNC] Internet voltou.');
          sincronizar();
        }
      });
    } catch (e) {
      debugPrint('[SYNC] Sem monitor de conexão: $e');
    }

    // A cada 5 minutos.
    _timer = Timer.periodic(periodo, (_) => sincronizar());

    // Usuário trocou (login/logout): recalcula pendentes e tenta enviar.
    FirebaseAuth.instance.authStateChanges().listen((_) {
      _fila._atualizarContagem();
      sincronizar();
    });

    sincronizar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) sincronizar();
  }

  void parar() {
    _timer?.cancel();
    _agendada?.cancel();
    _conexao?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _iniciado = false;
  }

  /// Coloca na fila e tenta enviar na hora.
  Future<ResultadoEnvio> enviar({
    required String metodo,
    required String caminho,
    Map<String, dynamic>? corpo,
    String? substitui,
    String? idLocal,
  }) async {
    final item = await _fila.adicionar(
      metodo: metodo,
      caminho: caminho,
      corpo: corpo,
      substitui: substitui,
      idLocal: idLocal,
    );
    await sincronizar(imediato: true);
    return _resultados.remove(item.id) ??
        (_fila.contem(item.id)
            ? ResultadoEnvio.naFila
            : ResultadoEnvio.enviado);
  }

  /// Envia o que estiver pronto na fila, respeitando os limites.
  /// [imediato] = pedido do usuário (intervalo mínimo menor).
  Future<void> sincronizar({bool imediato = false}) async {
    if (!ApiConfig.configurada) return;
    if (FirebaseAuth.instance.currentUser == null) return;

    final agora = DateTime.now();
    final prontos = _fila._prontos(agora);
    if (prontos.isEmpty) return;

    // Limites: se ainda não pode, agenda para o primeiro momento permitido
    // (assim um envio feito logo depois de outro não espera 5 minutos).
    if (_rodando) {
      _agendar(_intervaloImediato);
      return;
    }
    if (agora.isBefore(_pausadoAte)) {
      _agendar(_pausadoAte.difference(agora));
      return;
    }
    final minimo = imediato ? _intervaloImediato : _intervaloAutomatico;
    final desde = agora.difference(_ultimaRodada);
    if (desde < minimo) {
      _agendar(minimo - desde);
      return;
    }

    if (_resultados.length > 200) _resultados.clear();
    _rodando = true;
    _ultimaRodada = agora;
    var enviadosNaRodada = 0;
    var parou = false;
    try {
      for (final item in prontos.take(_maxPorRodada)) {
        final continuar = await _enviarItem(item);
        if (_resultados[item.id] == ResultadoEnvio.enviado) enviadosNaRodada++;
        if (!continuar) {
          parou = true;
          break;
        }
        await Future<void>.delayed(_pausaEntreEnvios);
      }
    } finally {
      _rodando = false;
    }

    // Sobrou coisa pronta (mais de 15)? Continua depois do intervalo mínimo.
    if (!parou && _fila._prontos(DateTime.now()).isNotEmpty) {
      _agendar(_intervaloAutomatico);
    }

    if (enviadosNaRodada > 0) {
      enviados.value++;
      debugPrint('[SYNC] $enviadosNaRodada enviado(s), '
          '${_fila.pendentes.value} pendente(s).');
    }
    if (_fila.pendentes.value == 0) ultimaSincronizacao = DateTime.now();
  }

  Timer? _agendada;

  /// Uma única nova tentativa agendada (nunca empilha várias).
  void _agendar(Duration espera) {
    if (_agendada?.isActive == true) return;
    _agendada = Timer(espera + const Duration(milliseconds: 200), () {
      _agendada = null;
      sincronizar(imediato: true);
    });
  }

  /// Devolve false quando a rodada deve parar (sem rede, servidor fora...).
  Future<bool> _enviarItem(ItemFila item) async {
    final caminho = _fila._resolverCaminho(item);
    if (caminho == null) return true; // espera o item que cria o id
    if (caminho.isEmpty) {
      await _fila._descartar(item, 'id local sem correspondente');
      _resultados[item.id] = ResultadoEnvio.recusado;
      return true;
    }

    try {
      final uri = ApiConfig.uri(caminho);
      final cab = await _cabecalhos(comCorpo: item.corpo != null);
      final corpo = item.corpo == null ? null : json.encode(item.corpo);

      final http.Response r;
      switch (item.metodo) {
        case 'POST':
          r = await http.post(uri, headers: cab, body: corpo).timeout(_timeout);
        case 'PUT':
          r = await http.put(uri, headers: cab, body: corpo).timeout(_timeout);
        case 'PATCH':
          r = await http
              .patch(uri, headers: cab, body: corpo)
              .timeout(_timeout);
        case 'DELETE':
          r = await http
              .delete(uri, headers: cab, body: corpo)
              .timeout(_timeout);
        default:
          await _fila._descartar(item, 'método ${item.metodo} desconhecido');
          _resultados[item.id] = ResultadoEnvio.recusado;
          return true;
      }

      final s = r.statusCode;
      if (s >= 200 && s < 300) {
        String? idServidor;
        try {
          if (r.bodyBytes.isNotEmpty) {
            final resp = json.decode(utf8.decode(r.bodyBytes));
            if (resp is Map) idServidor = resp['id']?.toString();
          }
        } catch (_) {}
        await _fila._concluir(item, idServidor: idServidor);
        _resultados[item.id] = ResultadoEnvio.enviado;
        return true;
      }

      if (s == 429) {
        // A API pediu para ir mais devagar: pausa tudo.
        final espera = int.tryParse(r.headers['retry-after'] ?? '') ?? 60;
        _pausadoAte = DateTime.now().add(Duration(seconds: espera));
        await _fila._adiar(item, 'limite da API (429)');
        return false;
      }

      // Pode dar certo mais tarde: sessão expirada, timeout do servidor,
      // servidor fora do ar.
      if (s == 401 || s == 403 || s == 408 || s >= 500) {
        await _fila._adiar(item, ApiConfig.mensagemStatus(s));
        return false;
      }

      // 404 em DELETE = já não existe no servidor: objetivo cumprido.
      if (s == 404 && item.metodo == 'DELETE') {
        await _fila._concluir(item);
        _resultados[item.id] = ResultadoEnvio.enviado;
        return true;
      }

      // 400, 404, 409, 422...: a API recusou os dados. Repetir não ajuda.
      await _fila._descartar(item, 'HTTP $s: ${r.body}');
      _resultados[item.id] = ResultadoEnvio.recusado;
      return true;
    } on ApiNaoConfiguradaException {
      return false;
    } on TimeoutException catch (e) {
      await _fila._adiar(item, ApiConfig.mensagemErro(e));
      return false;
    } on SocketException catch (e) {
      await _fila._adiar(item, ApiConfig.mensagemErro(e));
      return false;
    } on http.ClientException catch (e) {
      await _fila._adiar(item, ApiConfig.mensagemErro(e));
      return false;
    } catch (e) {
      await _fila._adiar(item, '$e');
      return false;
    }
  }
}

// =============================================================================
// AJUDANTE PARA AS TELAS
// =============================================================================

/// Resultado de um GET com cache.
class RespostaApi {
  const RespostaApi({this.dados, this.erro, this.salvoEm});

  /// JSON da API, ou do cache se a API falhou (null se não houver nenhum).
  final Object? dados;

  /// Mensagem de erro se a API falhou (null = veio da API agora).
  final String? erro;

  /// Quando o cache foi salvo (só quando [dados] veio do cache).
  final DateTime? salvoEm;

  bool get doCache => erro != null && dados != null;

  Map<String, dynamic>? get mapa =>
      dados is Map<String, dynamic> ? dados as Map<String, dynamic> : null;
}

class ApiOffline {
  ApiOffline._();

  /// GET com cache: tenta a API; se der certo, salva no aparelho.
  /// Se falhar, devolve o que estiver salvo + a mensagem de erro.
  static Future<RespostaApi> buscar(
    String caminho, {
    required String cache,
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    String erro;
    try {
      final r = await http
          .get(ApiConfig.uri(caminho, query: query),
              headers: await _cabecalhos())
          .timeout(timeout);
      if (r.statusCode == 200) {
        final corpo = json.decode(utf8.decode(r.bodyBytes));
        await CacheLocal.salvar(cache, corpo);
        return RespostaApi(dados: corpo);
      }
      erro = ApiConfig.mensagemStatus(r.statusCode);
    } on FormatException {
      erro = 'Resposta inválida do servidor.';
    } catch (e) {
      erro = ApiConfig.mensagemErro(e);
    }
    debugPrint('[API] GET $caminho falhou: $erro');

    final salvo = await CacheLocal.ler(cache);
    return RespostaApi(
        dados: salvo?.dados, erro: erro, salvoEm: salvo?.salvoEm);
  }

  /// Envio pela fila (POST/PUT/PATCH/DELETE). Nunca perde o dado.
  static Future<ResultadoEnvio> enviar(
    String metodo,
    String caminho, {
    Map<String, dynamic>? corpo,
    String? substitui,
    String? idLocal,
  }) =>
      Sincronizador.instancia.enviar(
        metodo: metodo,
        caminho: caminho,
        corpo: corpo,
        substitui: substitui,
        idLocal: idLocal,
      );

  /// Corridas salvas no aparelho que ainda não chegaram na API.
  static List<Map<String, dynamic>> corridasPendentes() =>
      FilaOffline.instancia.corpos(metodo: 'POST', caminho: '/corridas');
}
