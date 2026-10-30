import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'corrida.dart';
import '../services/preferencia.dart';

// =============================================================================
// CORES (mesma paleta da home)
// =============================================================================

class _Cores {
  // Cores que são iguais nos dois temas
  static const tinta = Color(0xFF1A1A1A); // texto/ícone sobre verde-limão
  static const destaque = Color(0xFFD0FD38);
  static const laranja = Color(0xFFF59E0B);
  static const vermelho = Color(0xFFEF4444);
  static Color get escuro => // texto principal
      _modoEscuro ? const Color(0xFFF3F4F6) : const Color(0xFF1A1A1A);
  static Color get textoSecundario =>
      _modoEscuro ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  static Color get fundo =>
      _modoEscuro ? const Color(0xFF111311) : const Color(0xFFF6F7F4);
  static Color get mapa =>
      _modoEscuro ? const Color(0xFF20241E) : const Color(0xFFE3E7E1);
  static Color get borda =>
      _modoEscuro ? const Color(0xFF2C302A) : const Color(0xFFE5E7EB);
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
// AJUDANTES
// =============================================================================

/// Os serviços do OpenStreetMap exigem um User-Agent identificando o app.
const _userAgent = 'RunnerApp/1.0 (Flutter)';

typedef _Ponto = (double lat, double lng);

double _toDouble(Object? v) =>
    v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

String _km(double v) {
  final t =
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return t.replaceAll('.', ',');
}

double _distancia(_Ponto a, _Ponto b) =>
    Geolocator.distanceBetween(a.$1, a.$2, b.$1, b.$2);

/// Ponto a [metros] de [origem] na direção [rumo] (graus).
_Ponto _destino(_Ponto origem, double rumo, double metros) {
  const raioTerra = 6371000.0;
  final d = metros / raioTerra;
  final r = rumo * math.pi / 180;
  final lat1 = origem.$1 * math.pi / 180;
  final lng1 = origem.$2 * math.pi / 180;
  final lat2 = math.asin(math.sin(lat1) * math.cos(d) +
      math.cos(lat1) * math.sin(d) * math.cos(r));
  final lng2 = lng1 +
      math.atan2(math.sin(r) * math.sin(d) * math.cos(lat1),
          math.cos(d) - math.sin(lat1) * math.sin(lat2));
  return (lat2 * 180 / math.pi, lng2 * 180 / math.pi);
}

// =============================================================================
// MODELOS
// =============================================================================

class Referencia {
  const Referencia(
      {required this.nome, required this.tipo, required this.posicao});

  final String nome;

  /// praca | parque | igreja | prefeitura | mercado | museu | mirante |
  /// historico | estadio | atracao
  final String tipo;
  final _Ponto posicao;

  IconData get icone => switch (tipo) {
        'praca' => Icons.park_outlined,
        'parque' => Icons.forest_outlined,
        'igreja' => Icons.church_outlined,
        'prefeitura' => Icons.account_balance_outlined,
        'mercado' => Icons.storefront_outlined,
        'museu' => Icons.museum_outlined,
        'mirante' => Icons.landscape_outlined,
        'historico' => Icons.history_edu_outlined,
        'estadio' => Icons.stadium_outlined,
        _ => Icons.place_outlined,
      };

  String get tipoRotulo => switch (tipo) {
        'praca' => 'Praça',
        'parque' => 'Parque',
        'igreja' => 'Igreja',
        'prefeitura' => 'Prefeitura',
        'mercado' => 'Mercado',
        'museu' => 'Museu',
        'mirante' => 'Mirante',
        'historico' => 'Histórico',
        'estadio' => 'Esporte',
        _ => 'Ponto turístico',
      };
}

class Rota {
  const Rota({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.uf,
    required this.distanciaKm,
    required this.dificuldade,
    required this.elevacaoM,
    required this.pontos,
    required this.paradas,
    required this.referencias,
    this.destaque = false,
  });

  final String id;
  final String nome;
  final String cidade;
  final String uf;
  final double distanciaKm;

  /// "leve" | "moderada" | "intensa"
  final String dificuldade;
  final int elevacaoM;

  /// Traçado completo pelas ruas
  final List<_Ponto> pontos;

  /// Pontos por onde o percurso passa (início, paradas, volta ao início)
  final List<_Ponto> paradas;
  final List<Referencia> referencias;
  final bool destaque;

  String get local => [cidade, uf].where((s) => s.isNotEmpty).join(' · ');

  String get dificuldadeRotulo => switch (dificuldade) {
        'leve' => 'Leve',
        'moderada' => 'Moderada',
        _ => 'Intensa',
      };

  Color get corDificuldade => switch (dificuldade) {
        'leve' => _Cores.verde,
        'moderada' => _Cores.laranja,
        _ => _Cores.vermelho,
      };

  Rota comDestaque() => Rota(
        id: id,
        nome: nome,
        cidade: cidade,
        uf: uf,
        distanciaKm: distanciaKm,
        dificuldade: dificuldade,
        elevacaoM: elevacaoM,
        pontos: pontos,
        paradas: paradas,
        referencias: referencias,
        destaque: true,
      );
}

class _Plano {
  const _Plano(this.metaKm, this.referencias, this.paradas);

  final double metaKm;
  final List<Referencia> referencias;
  final List<_Ponto> paradas;
}

// =============================================================================
// GERADOR DE ROTAS (OpenStreetMap + OSRM + Open-Meteo)
// =============================================================================

class _GeradorRotas {
  /// Gera [quantidade] circuitos que começam e terminam na posição do usuário,
  /// passando por pontos de referência reais próximos.
  static Future<List<Rota>> gerar(
    Position posicao, {
    required double raioKm,
    int quantidade = 5,
    void Function(String etapa)? etapa,
  }) async {
    final rnd = math.Random();
    final origem = (posicao.latitude, posicao.longitude);

    etapa?.call('Procurando pontos de referência...');
    final (refs, local) = await (
      _buscarReferencias(origem, raioKm / 2 * 1000),
      _buscarLocal(origem),
    ).wait;

    etapa?.call('Traçando percursos pelas ruas...');
    final metas = [3.0, 4.0, 5.0, 6.0, 8.0, 10.0]
        .where((d) => d <= raioKm)
        .toList()
      ..shuffle(rnd);
    if (metas.isEmpty) metas.add(raioKm);

    final usados = <String>{};
    final planos = [
      for (var i = 0; i < quantidade; i++)
        _planejar(origem, metas[i % metas.length], refs, rnd, usados),
    ];

    final rotas = await Future.wait([
      for (var i = 0; i < planos.length; i++) _tracar(planos[i], local, i),
    ]);

    rotas.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));

    // Destaque: a rota com mais pontos de referência
    if (rotas.isNotEmpty) {
      var iDestaque = 0;
      for (var i = 1; i < rotas.length; i++) {
        if (rotas[i].referencias.length > rotas[iDestaque].referencias.length) {
          iDestaque = i;
        }
      }
      rotas[iDestaque] = rotas[iDestaque].comDestaque();
    }
    return rotas;
  }

  // ---------------------------------------------------------------------------
  // 1. Pontos de referência (Overpass / OpenStreetMap)
  // ---------------------------------------------------------------------------

  static Future<List<Referencia>> _buscarReferencias(
      _Ponto origem, double raioM) async {
    final r = raioM.round();
    final a = '(around:$r,${origem.$1},${origem.$2})';
    final consulta = '''
[out:json][timeout:20];
(
  node$a[place=square][name];
  way$a[place=square][name];
  node$a[leisure~"^(park|garden|stadium|sports_centre)\$"][name];
  way$a[leisure~"^(park|garden|stadium|sports_centre)\$"][name];
  node$a[amenity~"^(place_of_worship|townhall|marketplace)\$"][name];
  way$a[amenity~"^(place_of_worship|townhall|marketplace)\$"][name];
  node$a[tourism~"^(attraction|viewpoint|museum|artwork)\$"][name];
  node$a[historic][name];
);
out center 120;
''';

    try {
      final resp = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {'User-Agent': _userAgent},
        body: {'data': consulta},
      ).timeout(const Duration(seconds: 25));

      if (resp.statusCode != 200) {
        debugPrint('[ROTAS] Overpass: ${resp.statusCode}');
        return [];
      }

      final j = json.decode(utf8.decode(resp.bodyBytes));
      final vistos = <String>{};
      final lista = <Referencia>[];
      for (final e in (j['elements'] as List? ?? const [])) {
        final tags = (e['tags'] as Map?) ?? const {};
        final nome = tags['name']?.toString().trim() ?? '';
        if (nome.isEmpty || !vistos.add(nome.toLowerCase())) continue;
        final lat = e['lat'] ?? e['center']?['lat'];
        final lng = e['lon'] ?? e['center']?['lon'];
        if (lat == null || lng == null) continue;
        lista.add(Referencia(
          nome: nome,
          tipo: _tipo(tags),
          posicao: (_toDouble(lat), _toDouble(lng)),
        ));
      }
      debugPrint('[ROTAS] ${lista.length} pontos de referência encontrados.');
      return lista;
    } catch (e) {
      debugPrint('[ROTAS] Erro ao buscar referências: $e');
      return [];
    }
  }

  static String _tipo(Map tags) {
    final place = tags['place'], leisure = tags['leisure'];
    final amenity = tags['amenity'], tourism = tags['tourism'];
    if (place == 'square') return 'praca';
    if (leisure == 'park' || leisure == 'garden') return 'parque';
    if (leisure == 'stadium' || leisure == 'sports_centre') return 'estadio';
    if (amenity == 'place_of_worship') return 'igreja';
    if (amenity == 'townhall') return 'prefeitura';
    if (amenity == 'marketplace') return 'mercado';
    if (tourism == 'museum') return 'museu';
    if (tourism == 'viewpoint') return 'mirante';
    if (tags['historic'] != null) return 'historico';
    return 'atracao';
  }

  // ---------------------------------------------------------------------------
  // 2. Cidade e estado (Nominatim)
  // ---------------------------------------------------------------------------

  static Future<(String, String)> _buscarLocal(_Ponto origem) async {
    try {
      final resp = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse'
            '?format=jsonv2&zoom=10&accept-language=pt-BR'
            '&lat=${origem.$1}&lon=${origem.$2}'),
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final end =
            (json.decode(utf8.decode(resp.bodyBytes))['address'] as Map?) ??
                const {};
        final cidade = (end['city'] ??
                end['town'] ??
                end['village'] ??
                end['municipality'] ??
                '')
            .toString();
        final iso = (end['ISO3166-2-lvl4'] ?? '').toString(); // "BR-PE"
        final uf = iso.contains('-') ? iso.split('-').last : '';
        return (cidade, uf);
      }
    } catch (e) {
      debugPrint('[ROTAS] Erro ao buscar cidade: $e');
    }
    return ('', '');
  }

  // ---------------------------------------------------------------------------
  // 3. Planejamento: escolhe referências que formem um circuito do tamanho certo
  // ---------------------------------------------------------------------------

  static _Plano _planejar(_Ponto origem, double metaKm, List<Referencia> refs,
      math.Random rnd, Set<String> usados) {
    const fatorRuas = 1.3; // ruas são ~30% mais longas que a linha reta
    final alvo = metaKm * 1000 / fatorRuas;

    List<Referencia>? melhor;
    var melhorErro = double.infinity;

    if (refs.isNotEmpty) {
      for (var t = 0; t < 80; t++) {
        final a = refs[rnd.nextInt(refs.length)];
        final List<Referencia> candidato;
        final double perimetro;

        if (refs.length > 1 && rnd.nextDouble() < 0.75) {
          final b = refs[rnd.nextInt(refs.length)];
          if (identical(a, b)) continue;
          candidato = [a, b];
          perimetro = _distancia(origem, a.posicao) +
              _distancia(a.posicao, b.posicao) +
              _distancia(b.posicao, origem);
        } else {
          candidato = [a];
          perimetro = 2 * _distancia(origem, a.posicao);
        }

        final chave = candidato.map((r) => r.nome).join('|');
        if (usados.contains(chave)) continue;

        final erro = (perimetro - alvo).abs() / alvo;
        if (erro < melhorErro) {
          melhorErro = erro;
          melhor = candidato;
        }
      }
    }

    if (melhor != null && melhorErro < 0.35) {
      usados.add(melhor.map((r) => r.nome).join('|'));
      return _Plano(
          metaKm, melhor, [origem, ...melhor.map((r) => r.posicao), origem]);
    }

    // Sem referências adequadas: circuito triangular em direção aleatória.
    final rumo = rnd.nextDouble() * 360;
    final lado = alvo / (2 + math.sqrt2);
    return _Plano(metaKm, const [], [
      origem,
      _destino(origem, rumo, lado),
      _destino(origem, rumo + 90, lado),
      origem,
    ]);
  }

  // ---------------------------------------------------------------------------
  // 4. Traçado pelas ruas (OSRM a pé) + elevação (Open-Meteo)
  // ---------------------------------------------------------------------------

  static Future<Rota> _tracar(
      _Plano plano, (String, String) local, int indice) async {
    var pontos = plano.paradas;
    var metros = 0.0;

    try {
      final coords = plano.paradas.map((p) => '${p.$2},${p.$1}').join(';');
      final resp = await http.get(
        Uri.parse('https://routing.openstreetmap.de/routed-foot/route/v1/foot/'
            '$coords?overview=full&geometries=geojson'),
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final j = json.decode(resp.body);
        final rotas = j['routes'] as List?;
        if (rotas != null && rotas.isNotEmpty) {
          metros = _toDouble(rotas.first['distance']);
          pontos = [
            for (final c in rotas.first['geometry']['coordinates'] as List)
              (_toDouble(c[1]), _toDouble(c[0])),
          ];
        }
      }
    } catch (e) {
      debugPrint('[ROTAS] Erro ao traçar percurso: $e');
    }

    // Sem roteamento: estima pela linha reta
    if (metros <= 0) {
      for (var i = 1; i < plano.paradas.length; i++) {
        metros += _distancia(plano.paradas[i - 1], plano.paradas[i]);
      }
      metros *= 1.3;
    }

    final ganho = await _ganhoElevacao(pontos);
    final km = metros / 1000;

    final dificuldade = (km <= 4 && ganho < 40)
        ? 'leve'
        : (km >= 8 || ganho >= 120)
            ? 'intensa'
            : 'moderada';

    final refs = plano.referencias;
    final nome = switch (refs.length) {
      0 => 'Circuito surpresa',
      1 => 'Ida e volta: ${refs.first.nome}',
      _ => '${refs[0].nome} e ${refs[1].nome}',
    };

    return Rota(
      id: '${DateTime.now().millisecondsSinceEpoch}-$indice',
      nome: nome,
      cidade: local.$1,
      uf: local.$2,
      distanciaKm: double.parse(km.toStringAsFixed(1)),
      dificuldade: dificuldade,
      elevacaoM: ganho,
      pontos: pontos,
      paradas: plano.paradas,
      referencias: refs,
    );
  }

  /// Soma das subidas do percurso, em metros.
  static Future<int> _ganhoElevacao(List<_Ponto> pontos) async {
    if (pontos.length < 2) return 0;
    try {
      const maximo = 80;
      final passo = math.max(1, pontos.length ~/ maximo);
      final amostra = [
        for (var i = 0; i < pontos.length; i += passo) pontos[i],
      ];
      final lats = amostra.map((p) => p.$1.toStringAsFixed(5)).join(',');
      final lngs = amostra.map((p) => p.$2.toStringAsFixed(5)).join(',');

      final resp = await http
          .get(Uri.parse('https://api.open-meteo.com/v1/elevation'
              '?latitude=$lats&longitude=$lngs'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return 0;

      final alturas =
          (json.decode(resp.body)['elevation'] as List).map(_toDouble).toList();
      var ganho = 0.0;
      for (var i = 1; i < alturas.length; i++) {
        final d = alturas[i] - alturas[i - 1];
        if (d > 0) ganho += d;
      }
      return ganho.round();
    } catch (e) {
      debugPrint('[ROTAS] Erro na elevação: $e');
      return 0;
    }
  }
}

// =============================================================================
// LOCALIZAÇÃO
// =============================================================================

Future<Position?> _posicaoAtual() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  } catch (_) {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }
}

// =============================================================================
// TELA
// =============================================================================

class RotasScreen extends StatefulWidget {
  const RotasScreen({super.key, this.raioKm = 8});

  /// Tamanho máximo das rotas geradas.
  final double raioKm;

  @override
  State<RotasScreen> createState() => _RotasScreenState();
}

class _RotasScreenState extends State<RotasScreen> {
  final _busca = TextEditingController();

  bool _carregando = true;
  bool _semGps = false;
  String _etapa = 'Buscando sua localização...';
  List<Rota> _rotas = [];
  String? _filtro; // null = todas

  static const _filtros = <(String?, String)>[
    (null, 'Todas as rotas'),
    ('leve', 'Leves'),
    ('moderada', 'Moderadas'),
    ('intensa', 'Intensas'),
  ];

  @override
  void initState() {
    super.initState();
    _busca.addListener(() => setState(() {}));
    _gerar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _gerar() async {
    HapticFeedback.lightImpact();
    setState(() {
      _carregando = true;
      _semGps = false;
      _etapa = 'Buscando sua localização...';
    });

    final posicao = await _posicaoAtual();
    if (!mounted) return;
    if (posicao == null) {
      setState(() {
        _carregando = false;
        _semGps = true;
        _rotas = [];
      });
      return;
    }

    final rotas = await _GeradorRotas.gerar(
      posicao,
      raioKm: widget.raioKm,
      etapa: (e) {
        if (mounted) setState(() => _etapa = e);
      },
    );
    if (!mounted) return;

    setState(() {
      _carregando = false;
      _rotas = rotas;
    });
  }

  List<Rota> get _filtradas {
    final termo = _busca.text.trim().toLowerCase();
    return _rotas.where((r) {
      if (_filtro != null && r.dificuldade != _filtro) return false;
      if (termo.isEmpty) return true;
      return r.nome.toLowerCase().contains(termo) ||
          r.referencias.any((ref) => ref.nome.toLowerCase().contains(termo));
    }).toList();
  }

  Rota? get _emDestaque {
    if (_rotas.isEmpty) return null;
    return _rotas.firstWhere((r) => r.destaque, orElse: () => _rotas.first);
  }

  Future<void> _correr(Rota? rota) async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => rota == null
            ? const CorridaScreen(
                titulo: 'Corrida livre', subtitulo: 'SEM ROTA')
            : CorridaScreen(
                titulo: rota.nome,
                subtitulo: 'ROTA GERADA',
                metaKm: rota.distanciaKm > 0 ? rota.distanciaKm : null,
              ),
      ),
    );
    // Corrida salva: volta para a home avisando para recarregar.
    if (salvou == true && mounted) Navigator.pop(context, true);
  }

  /// Abre o percurso completo no Google Maps, passando pelas paradas.
  Future<void> _abrirNoMaps(Rota rota) async {
    final p = rota.paradas;
    if (p.length < 2) return;
    String f(_Ponto x) => '${x.$1},${x.$2}';
    final intermediarias = p.sublist(1, p.length - 1).map(f).join('|');
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1'
        '&origin=${f(p.first)}&destination=${f(p.last)}'
        '${intermediarias.isEmpty ? '' : '&waypoints=${Uri.encodeComponent(intermediarias)}'}'
        '&travelmode=walking');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível abrir o mapa.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _abrirDetalhes(Rota rota) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Cores.card,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _DetalhesRota(
        rota: rota,
        onCorrer: () {
          Navigator.pop(ctx);
          _correr(rota);
        },
        onAbrirMaps: () => _abrirNoMaps(rota),
      ),
    );
  }

  Future<void> _ativarGps() async {
    final permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    } else if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    }
    if (mounted) _gerar();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
    final destaque = _emDestaque;

    return Scaffold(
      backgroundColor: _Cores.fundo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _Topo(onVoltar: () => Navigator.maybePop(context)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: _CampoBusca(controller: _busca),
            ),
            Divider(height: 1, color: _Cores.borda),
            Expanded(
              child: RefreshIndicator(
                color: _Cores.escuro,
                onRefresh: _gerar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    if (_carregando)
                      _CarregandoMapa(etapa: _etapa)
                    else if (destaque != null)
                      _CardDestaque(
                        key: ValueKey(destaque.id),
                        rota: destaque,
                        onTap: () => _abrirDetalhes(destaque),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filtros.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final (valor, rotulo) = _filtros[i];
                          return _ChipFiltro(
                            rotulo: rotulo,
                            ativo: _filtro == valor,
                            onTap: () => setState(() => _filtro = valor),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GERADAS A PARTIR DE VOCÊ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _Cores.textoSecundario,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _carregando
                                    ? 'Criando rotas...'
                                    : '${lista.length} '
                                        '${lista.length == 1 ? 'rota criada' : 'rotas criadas'}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _Cores.escuro,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_carregando && !_semGps)
                          TextButton.icon(
                            onPressed: _gerar,
                            icon: const Icon(Icons.casino_outlined, size: 18),
                            label: const Text('Gerar novas',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            style: TextButton.styleFrom(
                              foregroundColor: _Cores.tinta,
                              backgroundColor: _Cores.destaque,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (!_carregando && _semGps)
                      _Vazio(
                        icone: Icons.location_off_outlined,
                        titulo: 'Localização desativada',
                        texto:
                            'Ative o GPS para criarmos rotas saindo de onde você está.',
                        acao: 'Ativar localização',
                        onAcao: _ativarGps,
                      )
                    else if (!_carregando && lista.isEmpty)
                      _Vazio(
                        icone: Icons.explore_off_outlined,
                        titulo: 'Nenhuma rota encontrada',
                        texto: _busca.text.isNotEmpty || _filtro != null
                            ? 'Tente outra busca ou filtro.'
                            : 'Não conseguimos traçar rotas agora.',
                        acao: 'Tentar de novo',
                        onAcao: _gerar,
                      )
                    else if (!_carregando)
                      for (final rota in lista) ...[
                        _CardRota(
                            rota: rota, onTap: () => _abrirDetalhes(rota)),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 8),
                    _BotaoSemRota(onTap: () => _correr(null)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          child: Column(
            children: [
              Text('EXPLORE E ESCOLHA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _Cores.textoSecundario,
                    letterSpacing: 1.4,
                  )),
              SizedBox(height: 2),
              Text('Rotas e descobertas',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro,
                  )),
            ],
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _CampoBusca extends StatelessWidget {
  const _CampoBusca({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      style: TextStyle(fontSize: 15, color: _Cores.escuro),
      decoration: InputDecoration(
        hintText: 'Buscar rota ou lugar',
        hintStyle: TextStyle(color: _Cores.textoSecundario),
        prefixIcon: Icon(Icons.radio_button_checked_rounded,
            color: _Cores.textoSecundario, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: controller.clear,
              ),
        filled: true,
        fillColor: _Cores.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _Cores.borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _Cores.borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _Cores.escuro, width: 1.5),
        ),
      ),
    );
  }
}

class _CardDestaque extends StatelessWidget {
  const _CardDestaque({super.key, required this.rota, required this.onTap});

  final Rota rota;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 210,
          color: _Cores.mapa,
          child: Stack(
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => CustomPaint(
                    painter: _TracadoPainter(
                      rota.pontos,
                      marcos: rota.referencias.map((r) => r.posicao).toList(),
                      grade: true,
                      espessura: 4,
                      progresso: v,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 14,
                right: 60,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _Cores.superficie,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ROTA EM DESTAQUE',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          )),
                      const SizedBox(height: 3),
                      Text(
                        '${rota.nome} · ${_km(rota.distanciaKm)} km',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _CarregandoMapa extends StatelessWidget {
  const _CarregandoMapa({required this.etapa});

  final String etapa;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: _Cores.mapa,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _Cores.escuro, strokeWidth: 2.5),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              etapa,
              key: ValueKey(etapa),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _Cores.escuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro(
      {required this.rotulo, required this.ativo, required this.onTap});

  final String rotulo;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ativo ? _Cores.superficie : _Cores.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ativo ? _Cores.superficie : _Cores.borda),
        ),
        child: Text(rotulo,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: ativo ? Colors.white : _Cores.escuro,
            )),
      ),
    );
  }
}

class _CardRota extends StatefulWidget {
  const _CardRota({required this.rota, required this.onTap});

  final Rota rota;
  final VoidCallback onTap;

  @override
  State<_CardRota> createState() => _CardRotaState();
}

class _CardRotaState extends State<_CardRota> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final rota = widget.rota;
    final n = rota.referencias.length;
    final subtitulo = [
      if (rota.local.isNotEmpty) rota.local,
      n == 0 ? 'Percurso livre' : '$n ${n == 1 ? 'referência' : 'referências'}',
    ].join(' · ');

    Widget ponto() => Container(
          width: 3,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration:
              BoxDecoration(color: _Cores.borda, shape: BoxShape.circle),
        );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressionado = true),
      onTapUp: (_) => setState(() => _pressionado = false),
      onTapCancel: () => setState(() => _pressionado = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _Cores.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _pressionado ? _Cores.destaque : _Cores.borda,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 64,
                height: 64,
                color: _Cores.mapa,
                child: CustomPaint(
                  painter: _TracadoPainter(rota.pontos,
                      espessura: 2, miniatura: true),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rota.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _Cores.escuro,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12, color: _Cores.textoSecundario),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${_km(rota.distanciaKm)} km',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _Cores.escuro)),
                      ponto(),
                      Text(rota.dificuldadeRotulo,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: rota.corDificuldade)),
                      ponto(),
                      Text('${rota.elevacaoM} m',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _Cores.escuro)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _Cores.borda),
              ),
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: _Cores.escuro),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoSemRota extends StatelessWidget {
  const _BotaoSemRota({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.directions_run_rounded, size: 20),
      label: const Text('Correr sem rota definida',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _Cores.escuro,
        side: BorderSide(color: _Cores.borda),
        backgroundColor: _Cores.card,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({
    required this.icone,
    required this.titulo,
    required this.texto,
    this.acao,
    this.onAcao,
  });

  final IconData icone;
  final String titulo;
  final String texto;
  final String? acao;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Cores.borda),
      ),
      child: Column(
        children: [
          Icon(icone, size: 34, color: _Cores.textoSecundario),
          const SizedBox(height: 10),
          Text(titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _Cores.escuro)),
          const SizedBox(height: 4),
          Text(texto,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _Cores.textoSecundario)),
          if (acao != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAcao,
              style: FilledButton.styleFrom(
                backgroundColor: _Cores.superficie,
                foregroundColor: _Cores.destaque,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(acao!,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetalhesRota extends StatelessWidget {
  const _DetalhesRota({
    required this.rota,
    required this.onCorrer,
    required this.onAbrirMaps,
  });

  final Rota rota;
  final VoidCallback onCorrer;
  final VoidCallback onAbrirMaps;

  @override
  Widget build(BuildContext context) {
    Widget dado(String rotulo, String valor, {Color? cor}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _Cores.textoSecundario,
                    letterSpacing: 0.8,
                  )),
              const SizedBox(height: 4),
              Text(valor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cor ?? _Cores.escuro,
                  )),
            ],
          ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _Cores.borda,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Text(rota.nome,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro)),
            const SizedBox(height: 2),
            Text(
              [
                if (rota.local.isNotEmpty) rota.local,
                'Sai e volta para onde você está',
              ].join(' · '),
              style: TextStyle(fontSize: 13, color: _Cores.textoSecundario),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                height: 190,
                color: _Cores.mapa,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => CustomPaint(
                    painter: _TracadoPainter(
                      rota.pontos,
                      marcos: rota.referencias.map((r) => r.posicao).toList(),
                      grade: true,
                      espessura: 4,
                      progresso: v,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                dado('DISTÂNCIA', '${_km(rota.distanciaKm)} km'),
                dado('NÍVEL', rota.dificuldadeRotulo, cor: rota.corDificuldade),
                dado('SUBIDA', '${rota.elevacaoM} m'),
              ],
            ),
            if (rota.referencias.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('PONTOS DE REFERÊNCIA',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _Cores.textoSecundario,
                    letterSpacing: 0.8,
                  )),
              const SizedBox(height: 8),
              for (final (i, ref) in rota.referencias.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _Cores.destaque,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(ref.icone, size: 19, color: _Cores.tinta),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ref.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _Cores.escuro)),
                            Text('${i + 1}ª parada · ${ref.tipoRotulo}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _Cores.textoSecundario)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onCorrer,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Correr esta rota',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Cores.superficie,
                foregroundColor: _Cores.destaque,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onAbrirMaps,
              icon: const Icon(Icons.map_outlined, size: 19),
              label: const Text('Ver percurso no Google Maps',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _Cores.escuro,
                side: BorderSide(color: _Cores.borda),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DESENHO DO TRAÇADO
// =============================================================================

/// Desenha o traçado real da rota e os pontos de referência ([marcos]).
/// [progresso] anima o desenho de 0 a 1.
class _TracadoPainter extends CustomPainter {
  const _TracadoPainter(
    this.pontos, {
    this.marcos = const [],
    this.grade = false,
    this.miniatura = false,
    this.espessura = 3,
    this.progresso = 1,
  });

  final List<_Ponto> pontos;
  final List<_Ponto> marcos;
  final bool grade;
  final bool miniatura;
  final double espessura;
  final double progresso;

  /// Cria a função que converte lat/lng em pixels dentro da caixa.
  Offset Function(_Ponto)? _projecao(Size size) {
    if (pontos.length < 2) return null;
    final margem = miniatura ? 10.0 : 28.0;

    var minLat = pontos.first.$1, maxLat = minLat;
    var minLng = pontos.first.$2, maxLng = minLng;
    for (final (lat, lng) in [...pontos, ...marcos]) {
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }
    final cosLat = math.cos(((minLat + maxLat) / 2) * math.pi / 180);
    final largura = math.max((maxLng - minLng) * cosLat, 1e-6);
    final altura = math.max(maxLat - minLat, 1e-6);
    final escala = math.min(
      (size.width - margem * 2) / largura,
      (size.height - margem * 2) / altura,
    );
    final dx = (size.width - largura * escala) / 2;
    final dy = (size.height - altura * escala) / 2;

    return (p) => Offset(
        dx + (p.$2 - minLng) * cosLat * escala, dy + (maxLat - p.$1) * escala);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (grade) {
      final linha = Paint()
        ..color = _Cores.fundo.withValues(alpha: 0.7)
        ..strokeWidth = 6;
      for (var x = -size.height; x < size.width; x += 52) {
        canvas.drawLine(
            Offset(x, size.height), Offset(x + size.height, 0), linha);
      }
      linha.strokeWidth = 3;
      for (var x = 0.0; x < size.width + size.height; x += 74) {
        canvas.drawLine(
            Offset(x, 0), Offset(x - size.height * 0.6, size.height), linha);
      }
    } else if (miniatura) {
      canvas.drawLine(
        Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.7),
        Paint()
          ..color = _Cores.fundo.withValues(alpha: 0.6)
          ..strokeWidth = 2,
      );
    }

    final projetar = _projecao(size);
    if (projetar == null) return;
    final pts = pontos.map(projetar).toList();

    final completo = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      completo.lineTo(p.dx, p.dy);
    }

    // Recorta o caminho conforme o progresso da animação
    var caminho = completo;
    var fim = pts.last;
    if (progresso < 1) {
      final metricas = completo.computeMetrics().toList();
      final total = metricas.fold<double>(0, (s, m) => s + m.length);
      var restante = total * progresso;
      caminho = Path();
      for (final m in metricas) {
        final trecho = math.min(restante, m.length);
        caminho.addPath(m.extractPath(0, trecho), Offset.zero);
        final t = m.getTangentForOffset(trecho);
        if (t != null) fim = t.position;
        restante -= trecho;
        if (restante <= 0) break;
      }
    }

    final traco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
        caminho,
        traco
          ..color = _Cores.tinta
          ..strokeWidth = espessura + (miniatura ? 1.5 : 3));
    canvas.drawPath(
        caminho,
        traco
          ..color = miniatura ? _Cores.escuro : _Cores.destaque
          ..strokeWidth = espessura);

    // Pontos de referência
    if (!miniatura && progresso > 0.5) {
      final opacidade = ((progresso - 0.5) * 2).clamp(0.0, 1.0);
      for (final m in marcos) {
        final o = projetar(m);
        canvas.drawCircle(
            o, 8, Paint()..color = _Cores.tinta.withValues(alpha: opacidade));
        canvas.drawCircle(
            o, 4, Paint()..color = Colors.white.withValues(alpha: opacidade));
      }
    }

    // Início (você) e ponta do traçado
    final rInicio = miniatura ? 3.0 : 11.0;
    canvas.drawCircle(pts.first, rInicio, Paint()..color = _Cores.tinta);
    canvas.drawCircle(pts.first, rInicio - (miniatura ? 1.5 : 4),
        Paint()..color = _Cores.destaque);

    if (progresso < 1 && !miniatura) {
      canvas.drawCircle(fim, 6, Paint()..color = _Cores.tinta);
    }
  }

  @override
  bool shouldRepaint(covariant _TracadoPainter old) =>
      old.progresso != progresso ||
      old.pontos != pontos ||
      old.marcos != marcos;
}
