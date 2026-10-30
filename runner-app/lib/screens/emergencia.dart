import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/offline.dart';
import '../services/preferencia.dart';

// =============================================================================
// CORES
// =============================================================================

class _Cores {
  // Cores que são iguais nos dois temas
  static const tinta = Color(0xFF1A1A1A); // texto/ícone sobre verde-limão
  static const vermelho = Color(0xFFEA4335);
  static Color get fundo =>
      _modoEscuro ? const Color(0xFF151111) : const Color(0xFFFFF8F6);
  static Color get escuro => // texto principal
      _modoEscuro ? const Color(0xFFF3F4F6) : const Color(0xFF1A1A1A);
  static Color get textoSecundario =>
      _modoEscuro ? const Color(0xFFA3A3A3) : const Color(0xFF6B6B6B);
  static Color get vermelhoTitulo =>
      _modoEscuro ? const Color(0xFFF87171) : const Color(0xFFC0392B);
  static Color get vermelhoClaro =>
      _modoEscuro ? const Color(0xFF3A1D1D) : const Color(0xFFFDE8E5);
  static Color get vermelhoBorda =>
      _modoEscuro ? const Color(0xFF5A2A2A) : const Color(0xFFF5D0CB);
  static Color get borda =>
      _modoEscuro ? const Color(0xFF342C2A) : const Color(0xFFEDE3E0);
  static Color get cinza =>
      _modoEscuro ? const Color(0xFF2A2626) : const Color(0xFFF1F1F1);
  static Color get verde =>
      _modoEscuro ? const Color(0xFF9BC27A) : const Color(0xFF386641);

  /// Cards e botões que são pretos no tema claro.
  static Color get superficie =>
      _modoEscuro ? const Color(0xFF262A23) : const Color(0xFF1A1A1A);

  /// Superfícies que são brancas no tema claro.
  static Color get card => _modoEscuro ? const Color(0xFF1C1F1B) : Colors.white;
}

/// Tema atual (claro/escuro), controlado nas Configurações.
bool get _modoEscuro => Preferencias.instancia.modoEscuro;

// =============================================================================
// MODELO
// =============================================================================

class ContatoEmergencia {
  const ContatoEmergencia({
    required this.nome,
    required this.parentesco,
    required this.telefone,
  });

  final String nome;
  final String parentesco;
  final String telefone;

  /// "Marina Silva · irmã"
  String get descricao =>
      parentesco.isEmpty ? nome : '$nome · ${parentesco.toLowerCase()}';

  String get primeiroNome => nome.trim().split(RegExp(r'\s+')).first;

  factory ContatoEmergencia.fromJson(Map<String, dynamic> json) =>
      ContatoEmergencia(
        nome: json['nome']?.toString().trim() ?? '',
        parentesco: json['parentesco']?.toString().trim() ?? '',
        telefone: json['telefone']?.toString().trim() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'parentesco': parentesco,
        'telefone': telefone,
      };
}

// =============================================================================
// API
// =============================================================================

class _EmergenciaApi {
  static const _cacheContato = 'contato';

  /// GET /contato-emergencia — da API ou, sem internet, do aparelho.
  /// Um contato salvo offline (ainda na fila) vale mais que o da API.
  static Future<ContatoEmergencia?> buscarContato() async {
    final pendentes = FilaOffline.instancia
        .corpos(metodo: 'PUT', caminho: '/contato-emergencia');
    if (pendentes.isNotEmpty) {
      return ContatoEmergencia.fromJson(pendentes.last);
    }

    final r =
        await ApiOffline.buscar('/contato-emergencia', cache: _cacheContato);
    final corpo = r.mapa;
    if (corpo == null) return null;
    final contato = ContatoEmergencia.fromJson(corpo);
    return contato.telefone.isNotEmpty ? contato : null;
  }

  /// PUT /contato-emergencia — salva no aparelho na hora e envia pela fila.
  static Future<ResultadoEnvio> salvarContato(ContatoEmergencia contato) async {
    await CacheLocal.salvar(_cacheContato, contato.toJson());
    return ApiOffline.enviar(
      'PUT',
      '/contato-emergencia',
      corpo: contato.toJson(),
      substitui: 'contato-emergencia',
    );
  }

  /// POST /alertas-emergencia pela fila. Devolve um id local do alerta (usado
  /// nas próximas chamadas; a fila troca pelo id real da API) e se a API já
  /// recebeu agora.
  static Future<({String id, bool recebido})> enviarAlerta(
      Position? posicao) async {
    final idLocal = novoIdLocal();
    final r = await ApiOffline.enviar(
      'POST',
      '/alertas-emergencia',
      corpo: {
        'latitude': posicao?.latitude,
        'longitude': posicao?.longitude,
        'precisaoMetros': posicao?.accuracy,
        'dataHora': DateTime.now().toUtc().toIso8601String(),
        'nomeUsuario': FirebaseAuth.instance.currentUser?.displayName,
      },
      idLocal: idLocal,
    );
    return (id: idLocal, recebido: r == ResultadoEnvio.enviado);
  }

  /// POST /alertas-emergencia/{id}/localizacao
  static Future<void> atualizarLocalizacao(String id, Position posicao) =>
      ApiOffline.enviar(
        'POST',
        '/alertas-emergencia/{{local:$id}}/localizacao',
        corpo: {
          'latitude': posicao.latitude,
          'longitude': posicao.longitude,
          'precisaoMetros': posicao.accuracy,
          'dataHora': DateTime.now().toUtc().toIso8601String(),
        },
      );

  /// POST /alertas-emergencia/{id}/encerrar
  static Future<void> encerrarAlerta(String id) =>
      ApiOffline.enviar('POST', '/alertas-emergencia/{{local:$id}}/encerrar');
}

// =============================================================================
// RECURSOS DO CELULAR (GPS, ligação, SMS, WhatsApp)
// =============================================================================

class _Localizacao {
  /// Devolve a posição atual e, se algo der errado, o motivo para mostrar.
  static Future<(Position?, String?)> obter() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return (null, 'O GPS está desligado. Ative a localização do celular.');
      }

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied) {
        return (null, 'Permissão de localização negada.');
      }
      if (permissao == LocationPermission.deniedForever) {
        return (
          null,
          'Localização bloqueada. Libere nas configurações do aplicativo.'
        );
      }

      try {
        final posicao = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
        return (posicao, null);
      } catch (_) {
        // Sem sinal de GPS a tempo: usa a última posição conhecida.
        final ultima = await Geolocator.getLastKnownPosition();
        return (
          ultima,
          ultima == null ? 'Não foi possível obter sua localização.' : null
        );
      }
    } catch (e) {
      debugPrint('[GPS] Erro: $e');
      return (null, 'Não foi possível obter sua localização.');
    }
  }

  static String linkMapa(Position p) =>
      'https://maps.google.com/?q=${p.latitude.toStringAsFixed(6)},'
      '${p.longitude.toStringAsFixed(6)}';
}

class _Celular {
  static String _digitos(String numero) =>
      numero.replaceAll(RegExp(r'[^\d+]'), '');

  static Future<bool> _abrir(Uri uri,
      {LaunchMode modo = LaunchMode.platformDefault}) async {
    try {
      return await launchUrl(uri, mode: modo);
    } catch (e) {
      debugPrint('[CELULAR] Não abriu $uri: $e');
      return false;
    }
  }

  static Future<bool> ligar(String numero) =>
      _abrir(Uri(scheme: 'tel', path: _digitos(numero)));

  static Future<bool> sms(String numero, String texto) => _abrir(
      Uri.parse('sms:${_digitos(numero)}?body=${Uri.encodeComponent(texto)}'));

  static Future<bool> whatsapp(String numero, String texto) {
    var d = numero.replaceAll(RegExp(r'\D'), '');
    if (d.length <= 11) d = '55$d'; // número brasileiro sem DDI
    return _abrir(
      Uri.parse('https://wa.me/$d?text=${Uri.encodeComponent(texto)}'),
      modo: LaunchMode.externalApplication,
    );
  }
}

// =============================================================================
// TELA
// =============================================================================

enum _Etapa { pronto, contagem, enviando, enviado }

class EmergenciaScreen extends StatefulWidget {
  const EmergenciaScreen({super.key});

  @override
  State<EmergenciaScreen> createState() => _EmergenciaScreenState();
}

class _EmergenciaScreenState extends State<EmergenciaScreen>
    with SingleTickerProviderStateMixin {
  /// Tempo para cancelar caso o botão seja tocado sem querer.
  static const _segundosContagem = 5;

  _Etapa _etapa = _Etapa.pronto;
  int _restante = _segundosContagem;
  Timer? _timer;

  ContatoEmergencia? _contato;
  bool _carregandoContato = true;

  Position? _posicao;
  String? _alertaId;
  bool _apiRecebeu = false;
  DateTime? _enviadoEm;

  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _carregarContato();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulso.dispose();
    super.dispose();
  }

  Future<void> _carregarContato() async {
    final contato = await _EmergenciaApi.buscarContato();
    if (!mounted) return;
    setState(() {
      _contato = contato;
      _carregandoContato = false;
    });
  }

  // ---------------------------------------------------------------------------
  // FLUXO DO ALERTA
  // ---------------------------------------------------------------------------

  void _iniciarContagem() {
    HapticFeedback.heavyImpact();
    setState(() {
      _etapa = _Etapa.contagem;
      _restante = _segundosContagem;
    });
    _pulso.repeat();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_restante <= 1) {
        t.cancel();
        _dispararAlerta();
      } else {
        HapticFeedback.selectionClick();
        setState(() => _restante--);
      }
    });
  }

  void _cancelarContagem() {
    _timer?.cancel();
    _pulso
      ..stop()
      ..reset();
    setState(() => _etapa = _Etapa.pronto);
    _aviso('Alerta cancelado.');
  }

  Future<void> _dispararAlerta() async {
    setState(() => _etapa = _Etapa.enviando);

    final (posicao, motivo) = await _Localizacao.obter();
    final alerta = await _EmergenciaApi.enviarAlerta(posicao);
    if (!mounted) return;

    HapticFeedback.vibrate();
    _pulso
      ..stop()
      ..reset();
    setState(() {
      _posicao = posicao;
      _alertaId = alerta.id;
      _apiRecebeu = alerta.recebido;
      _enviadoEm = DateTime.now();
      _etapa = _Etapa.enviado;
    });

    if (motivo != null) _aviso(motivo, erro: true);

    // Garante o aviso mesmo se a API falhar: abre o SMS já preenchido.
    if (_contato != null) {
      final abriu = await _Celular.sms(_contato!.telefone, _mensagem());
      if (!abriu && mounted) {
        _aviso('Não foi possível abrir o SMS.', erro: true);
      }
    } else if (mounted) {
      _aviso('Cadastre um contato de emergência para avisá-lo por SMS.',
          erro: true);
    }
  }

  Future<void> _reenviarLocalizacao() async {
    setState(() => _etapa = _Etapa.enviando);
    final (posicao, motivo) = await _Localizacao.obter();
    if (posicao != null && _alertaId != null) {
      await _EmergenciaApi.atualizarLocalizacao(_alertaId!, posicao);
    }
    if (!mounted) return;
    setState(() {
      if (posicao != null) _posicao = posicao;
      _etapa = _Etapa.enviado;
    });
    if (motivo != null) _aviso(motivo, erro: true);
    if (_contato != null) {
      await _Celular.sms(_contato!.telefone, _mensagem());
    }
  }

  Future<void> _encerrarAlerta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar alerta?'),
        content: const Text('Confirme que você está bem e seguro.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _Cores.superficie),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Estou bem'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    if (_alertaId != null) await _EmergenciaApi.encerrarAlerta(_alertaId!);
    if (!mounted) return;
    setState(() {
      _etapa = _Etapa.pronto;
      _alertaId = null;
      _posicao = null;
      _enviadoEm = null;
    });
    _aviso('Alerta encerrado. Que bom que está tudo bem!');
  }

  String _mensagem() {
    final nome = FirebaseAuth.instance.currentUser?.displayName?.trim();
    final quem = (nome == null || nome.isEmpty) ? 'Seu contato' : nome;
    final local = _posicao != null
        ? 'Minha localização: ${_Localizacao.linkMapa(_posicao!)}'
        : 'Não consegui obter minha localização.';
    return '🚨 ALERTA DE EMERGÊNCIA\n'
        '$quem precisa de ajuda durante a corrida.\n'
        '$local';
  }

  // ---------------------------------------------------------------------------
  // CONTATO E SERVIÇOS
  // ---------------------------------------------------------------------------

  Future<void> _abrirOpcoesContato() async {
    if (_carregandoContato) return;
    final contato = _contato;
    if (contato == null) return _editarContato();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Cores.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _Folha(
        titulo: contato.descricao,
        subtitulo: contato.telefone,
        itens: [
          _ItemFolha(
            icone: Icons.call_rounded,
            texto: 'Ligar para ${contato.primeiroNome}',
            onTap: () {
              Navigator.pop(ctx);
              _Celular.ligar(contato.telefone);
            },
          ),
          _ItemFolha(
            icone: Icons.sms_outlined,
            texto: 'Enviar SMS com minha localização',
            onTap: () async {
              Navigator.pop(ctx);
              await _atualizarPosicaoSilenciosa();
              _Celular.sms(contato.telefone, _mensagem());
            },
          ),
          _ItemFolha(
            icone: Icons.chat_outlined,
            texto: 'Enviar pelo WhatsApp',
            onTap: () async {
              Navigator.pop(ctx);
              await _atualizarPosicaoSilenciosa();
              final abriu =
                  await _Celular.whatsapp(contato.telefone, _mensagem());
              if (!abriu && mounted) {
                _aviso('WhatsApp não está disponível.', erro: true);
              }
            },
          ),
          _ItemFolha(
            icone: Icons.edit_outlined,
            texto: 'Editar contato',
            onTap: () {
              Navigator.pop(ctx);
              _editarContato();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _atualizarPosicaoSilenciosa() async {
    final (posicao, _) = await _Localizacao.obter();
    if (posicao != null && mounted) setState(() => _posicao = posicao);
  }

  Future<void> _editarContato() async {
    final novo = await showModalBottomSheet<ContatoEmergencia>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Cores.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FormContato(inicial: _contato),
    );
    if (novo == null || !mounted) return;

    setState(() => _contato = novo);
    final resultado = await _EmergenciaApi.salvarContato(novo);
    if (!mounted) return;
    switch (resultado) {
      case ResultadoEnvio.enviado:
        _aviso('Contato de emergência salvo.');
      case ResultadoEnvio.naFila:
        _aviso(
            'Contato salvo no celular. Será enviado quando houver internet.');
      case ResultadoEnvio.recusado:
        _aviso('O servidor recusou este contato. Confira o telefone.',
            erro: true);
    }
  }

  Future<void> _abrirServicos() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Cores.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        void ligar(String n) {
          Navigator.pop(ctx);
          HapticFeedback.mediumImpact();
          _Celular.ligar(n);
        }

        return _Folha(
          titulo: 'Serviço de emergência',
          subtitulo: 'A ligação é gratuita e funciona sem crédito.',
          itens: [
            _ItemFolha(
              icone: Icons.local_hospital_outlined,
              texto: 'SAMU — 192',
              onTap: () => ligar('192'),
            ),
            _ItemFolha(
              icone: Icons.local_fire_department_outlined,
              texto: 'Bombeiros — 193',
              onTap: () => ligar('193'),
            ),
            _ItemFolha(
              icone: Icons.local_police_outlined,
              texto: 'Polícia Militar — 190',
              onTap: () => ligar('190'),
            ),
          ],
        );
      },
    );
  }

  void _aviso(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor: erro ? _Cores.vermelhoTitulo : _Cores.superficie,
      ));
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  String get _titulo => switch (_etapa) {
        _Etapa.pronto => 'Precisa de ajuda?',
        _Etapa.contagem => 'Enviando em $_restante',
        _Etapa.enviando => 'Enviando alerta...',
        _Etapa.enviado => 'Alerta enviado',
      };

  String get _subtitulo {
    switch (_etapa) {
      case _Etapa.pronto:
        return 'Ao ativar, enviaremos sua localização para seus '
            'contatos de emergência.';
      case _Etapa.contagem:
        return 'Toque em cancelar se ativou sem querer.';
      case _Etapa.enviando:
        return 'Obtendo sua localização pelo GPS.';
      case _Etapa.enviado:
        final hora = _enviadoEm == null
            ? ''
            : ' às ${_enviadoEm!.hour.toString().padLeft(2, '0')}:'
                '${_enviadoEm!.minute.toString().padLeft(2, '0')}';
        final destino = _contato != null
            ? '${_contato!.primeiroNome} foi avisado(a)$hora.'
            : 'Alerta registrado$hora.';
        return _apiRecebeu
            ? '$destino Fique em um lugar seguro.'
            : '$destino Sem conexão com o servidor: o alerta será enviado '
                'quando a internet voltar, e o SMS garante o aviso.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloqueado = _etapa == _Etapa.contagem || _etapa == _Etapa.enviando;

    return PopScope(
      canPop: !bloqueado,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _etapa == _Etapa.contagem) _cancelarContagem();
      },
      child: Scaffold(
        backgroundColor: _Cores.fundo,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _Topo(
                  onVoltar: () {
                    if (_etapa == _Etapa.contagem) return _cancelarContagem();
                    if (_etapa != _Etapa.enviando) Navigator.maybePop(context);
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 56, bottom: 24),
                    child: Column(
                      children: [
                        _Escudo(
                          pulso: _pulso,
                          enviado: _etapa == _Etapa.enviado,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _titulo,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _Cores.escuro,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _subtitulo,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: _Cores.textoSecundario,
                            ),
                          ),
                        ),
                        if (_etapa == _Etapa.enviado && _posicao != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Precisão do GPS: ~${_posicao!.accuracy.round()} m',
                            style: TextStyle(fontSize: 12, color: _Cores.verde),
                          ),
                        ],
                        const SizedBox(height: 36),
                        _botoesPrincipais(),
                        const SizedBox(height: 16),
                        _CardContato(
                          contato: _contato,
                          carregando: _carregandoContato,
                          onTap: bloqueado ? null : _abrirOpcoesContato,
                        ),
                        const SizedBox(height: 28),
                        GestureDetector(
                          onTap: _abrirServicos,
                          child: Text(
                            'Ligar para o serviço de emergência',
                            style: TextStyle(
                              fontSize: 15,
                              color: _Cores.textoSecundario,
                              decoration: TextDecoration.underline,
                              decorationColor: _Cores.textoSecundario,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _botoesPrincipais() {
    switch (_etapa) {
      case _Etapa.pronto:
        return _BotaoGrande(
          texto: 'Ativar alerta de emergência',
          cor: _Cores.vermelho,
          sombra: true,
          onTap: _iniciarContagem,
        );
      case _Etapa.contagem:
        return _BotaoGrande(
          texto: 'Cancelar ($_restante)',
          cor: _Cores.superficie,
          progresso: 1 - (_restante - 1) / _segundosContagem,
          onTap: _cancelarContagem,
        );
      case _Etapa.enviando:
        return const _BotaoGrande(
          texto: 'Enviando...',
          cor: _Cores.vermelho,
          carregando: true,
        );
      case _Etapa.enviado:
        return Column(
          children: [
            _BotaoGrande(
              texto: 'Reenviar minha localização',
              cor: _Cores.vermelho,
              sombra: true,
              onTap: _reenviarLocalizacao,
            ),
            const SizedBox(height: 12),
            _BotaoGrande(
              texto: 'Estou bem — encerrar alerta',
              cor: _Cores.superficie,
              onTap: _encerrarAlerta,
            ),
          ],
        );
    }
  }
}

// =============================================================================
// COMPONENTES
// =============================================================================

class _Topo extends StatelessWidget {
  const _Topo({required this.onVoltar});

  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: _Cores.card,
          shape: CircleBorder(side: BorderSide(color: _Cores.borda)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onVoltar,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.chevron_left_rounded,
                  color: _Cores.escuro, size: 26),
            ),
          ),
        ),
        Expanded(
          child: Text(
            'SEGURANÇA DO CORREDOR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _Cores.vermelhoTitulo,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

/// Escudo com anéis; pulsa enquanto a contagem está rodando.
class _Escudo extends StatelessWidget {
  const _Escudo({required this.pulso, required this.enviado});

  final AnimationController pulso;
  final bool enviado;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: AnimatedBuilder(
        animation: pulso,
        builder: (context, _) {
          final t = pulso.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (pulso.isAnimating)
                Transform.scale(
                  scale: 1 + 0.3 * t,
                  child: Container(
                    width: 144,
                    height: 144,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _Cores.vermelho.withValues(alpha: 0.18 * (1 - t)),
                    ),
                  ),
                ),
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _Cores.card.withValues(alpha: 0.5),
                  border: Border.all(color: _Cores.vermelhoBorda),
                ),
              ),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _Cores.vermelhoClaro,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    enviado
                        ? Icons.verified_user_outlined
                        : Icons.gpp_maybe_outlined,
                    key: ValueKey(enviado),
                    size: 46,
                    color: _Cores.vermelho,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BotaoGrande extends StatelessWidget {
  const _BotaoGrande({
    required this.texto,
    required this.cor,
    this.onTap,
    this.sombra = false,
    this.carregando = false,
    this.progresso,
  });

  final String texto;
  final Color cor;
  final VoidCallback? onTap;
  final bool sombra;
  final bool carregando;

  /// 0..1 — preenche o botão durante a contagem.
  final double? progresso;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: sombra
            ? [
                BoxShadow(
                  color: cor.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: cor,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: carregando ? null : onTap,
          child: Stack(
            children: [
              if (progresso != null)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: progresso!.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 900),
                      builder: (_, v, __) => FractionallySizedBox(
                        widthFactor: v,
                        heightFactor: 1,
                        child: Container(
                            color: _Cores.vermelho.withValues(alpha: 0.85)),
                      ),
                    ),
                  ),
                ),
              Center(
                child: carregando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        texto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardContato extends StatelessWidget {
  const _CardContato({
    required this.contato,
    required this.carregando,
    required this.onTap,
  });

  final ContatoEmergencia? contato;
  final bool carregando;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vazio = !carregando && contato == null;

    return Material(
      color: _Cores.card.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _Cores.borda),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(color: _Cores.cinza, shape: BoxShape.circle),
                child: Icon(
                  vazio ? Icons.person_add_alt_outlined : Icons.person_outline,
                  size: 20,
                  color: _Cores.escuro,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTATO DE EMERGÊNCIA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _Cores.textoSecundario,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      carregando
                          ? 'Carregando...'
                          : (contato?.descricao ?? 'Adicionar contato'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: carregando
                            ? _Cores.textoSecundario
                            : (vazio ? _Cores.vermelhoTitulo : _Cores.escuro),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 22, color: _Cores.escuro),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Folha inferior genérica (opções) ---------------------------------------

class _ItemFolha {
  const _ItemFolha(
      {required this.icone, required this.texto, required this.onTap});

  final IconData icone;
  final String texto;
  final VoidCallback onTap;
}

class _Folha extends StatelessWidget {
  const _Folha({required this.titulo, this.subtitulo, required this.itens});

  final String titulo;
  final String? subtitulo;
  final List<_ItemFolha> itens;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _Cores.borda,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(titulo,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro)),
            if (subtitulo != null) ...[
              const SizedBox(height: 4),
              Text(subtitulo!,
                  style:
                      TextStyle(fontSize: 13, color: _Cores.textoSecundario)),
            ],
            const SizedBox(height: 12),
            for (final item in itens)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _Cores.vermelhoClaro,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icone, color: _Cores.vermelho, size: 20),
                ),
                title: Text(item.texto,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: _Cores.escuro)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: item.onTap,
              ),
          ],
        ),
      ),
    );
  }
}

// ---- Formulário do contato --------------------------------------------------

class _FormContato extends StatefulWidget {
  const _FormContato({this.inicial});

  final ContatoEmergencia? inicial;

  @override
  State<_FormContato> createState() => _FormContatoState();
}

class _FormContatoState extends State<_FormContato> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.inicial?.nome);
  late final _parentesco =
      TextEditingController(text: widget.inicial?.parentesco);
  late final _telefone = TextEditingController(text: widget.inicial?.telefone);

  @override
  void dispose() {
    _nome.dispose();
    _parentesco.dispose();
    _telefone.dispose();
    super.dispose();
  }

  InputDecoration _campo(String rotulo, {String? dica}) => InputDecoration(
        labelText: rotulo,
        hintText: dica,
        filled: true,
        fillColor: _Cores.fundo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _Cores.borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _Cores.borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _Cores.vermelho, width: 1.5),
        ),
      );

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      ContatoEmergencia(
        nome: _nome.text.trim(),
        parentesco: _parentesco.text.trim(),
        telefone: _telefone.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.inicial == null ? 'Adicionar contato' : 'Editar contato',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _Cores.escuro),
            ),
            const SizedBox(height: 4),
            Text(
              'Essa pessoa recebe sua localização quando você ativa o alerta.',
              style: TextStyle(fontSize: 13, color: _Cores.textoSecundario),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: _campo('Nome', dica: 'Ex.: Marina Silva'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _parentesco,
              textCapitalization: TextCapitalization.sentences,
              decoration: _campo('Parentesco (opcional)', dica: 'Ex.: irmã'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d+()\-\s]')),
              ],
              decoration: _campo('Telefone com DDD', dica: '(81) 99999-9999'),
              validator: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return d.length < 10 ? 'Telefone inválido' : null;
              },
            ),
            const SizedBox(height: 20),
            _BotaoGrande(
              texto: 'Salvar contato',
              cor: _Cores.superficie,
              onTap: _salvar,
            ),
          ],
        ),
      ),
    );
  }
}
