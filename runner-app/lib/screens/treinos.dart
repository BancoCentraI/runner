import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/offline.dart';
import 'corrida.dart';
import '../services/preferencia.dart';

// =============================================================================
// CORES (mesma paleta do app)
// =============================================================================

class _Cores {
  // Cores que são iguais nos dois temas
  static const tinta = Color(0xFF1A1A1A); // texto/ícone sobre verde-limão
  static const destaque = Color(0xFFD0FD38);
  static Color get escuro => // texto principal
      _modoEscuro ? const Color(0xFFF3F4F6) : const Color(0xFF1A1A1A);
  static Color get destaqueClaro =>
      _modoEscuro ? const Color(0xFF2E3A12) : const Color(0xFFEEF9C9);
  static Color get textoSecundario =>
      _modoEscuro ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  static Color get fundo =>
      _modoEscuro ? const Color(0xFF111311) : const Color(0xFFF6F7F4);
  static Color get borda =>
      _modoEscuro ? const Color(0xFF2C302A) : const Color(0xFFE5E7EB);
  static Color get segmento =>
      _modoEscuro ? const Color(0xFF252923) : const Color(0xFFE8EBE6);
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

double _toDouble(Object? v) =>
    v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

double? _toDoubleOuNulo(Object? v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

int _toInt(Object? v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

String? _toStr(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

const _letrasDia = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
const _nomesDia = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];
const _meses = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);

/// Distância conforme a preferência do usuário (km ou milhas).
String _distancia(double km, {bool comSigla = true}) {
  final milhas = Preferencias.instancia.unidade == UnidadeDistancia.milhas;
  final v = milhas ? km / 1.609344 : km;
  final t =
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  final n = t.replaceAll('.', ',');
  return comSigla ? '$n ${milhas ? 'mi' : 'km'}' : n;
}

// =============================================================================
// TREINOS PREDEFINIDOS (grátis, ficam no próprio app)
// =============================================================================

enum _Nivel { iniciante, intermediario }

class _Etapa {
  const _Etapa(this.texto, this.minutos);

  final String texto;
  final int minutos;
}

class TreinoPredefinido {
  const TreinoPredefinido({
    required this.titulo,
    required this.minutos,
    required this.resumo,
    required this.icone,
    required this.etapas,
    this.metaKm,
    this.recomendado = false,
  });

  final String titulo;
  final int minutos;
  final String resumo;
  final IconData icone;
  final List<_Etapa> etapas;
  final double? metaKm;
  final bool recomendado;
}

const _predefinidos = <_Nivel, List<TreinoPredefinido>>{
  _Nivel.iniciante: [
    TreinoPredefinido(
      titulo: 'Primeiros passos',
      minutos: 20,
      resumo: 'Caminhada e corrida',
      icone: Icons.directions_walk_rounded,
      recomendado: true,
      etapas: [
        _Etapa('Caminhada leve para aquecer', 5),
        _Etapa('6× (1 min correndo + 1 min caminhando)', 12),
        _Etapa('Caminhada para desacelerar', 3),
      ],
    ),
    TreinoPredefinido(
      titulo: 'Corrida básica',
      minutos: 25,
      resumo: 'Ritmo confortável',
      icone: Icons.monitor_heart_outlined,
      etapas: [
        _Etapa('Caminhada rápida para aquecer', 5),
        _Etapa('Corrida leve, num ritmo em que dá para conversar', 15),
        _Etapa('Caminhada para desacelerar', 5),
      ],
    ),
    TreinoPredefinido(
      titulo: 'Desafio 3 km',
      minutos: 30,
      resumo: 'Sem pressão por tempo',
      icone: Icons.track_changes_rounded,
      metaKm: 3,
      etapas: [
        _Etapa('Caminhada leve para aquecer', 5),
        _Etapa('Complete 3 km no seu ritmo — pode alternar com caminhada', 20),
        _Etapa('Caminhada para desacelerar', 5),
      ],
    ),
  ],
  _Nivel.intermediario: [
    TreinoPredefinido(
      titulo: 'Tiros de 1 minuto',
      minutos: 30,
      resumo: 'Intervalado',
      icone: Icons.bolt_rounded,
      recomendado: true,
      etapas: [
        _Etapa('Trote leve para aquecer', 10),
        _Etapa('8× (1 min forte + 1 min trote leve)', 16),
        _Etapa('Trote bem leve para desacelerar', 4),
      ],
    ),
    TreinoPredefinido(
      titulo: 'Progressivo 5 km',
      minutos: 35,
      resumo: 'Termina mais rápido',
      icone: Icons.trending_up_rounded,
      metaKm: 5,
      etapas: [
        _Etapa('1º e 2º km em ritmo leve', 13),
        _Etapa('3º e 4º km em ritmo moderado', 12),
        _Etapa('Último km no seu ritmo forte', 5),
        _Etapa('Caminhada para desacelerar', 5),
      ],
    ),
    TreinoPredefinido(
      titulo: 'Fartlek livre',
      minutos: 35,
      resumo: 'Brincando com o ritmo',
      icone: Icons.shuffle_rounded,
      etapas: [
        _Etapa('Trote leve para aquecer', 10),
        _Etapa(
            'Acelere até um poste/árvore e volte ao trote; repita '
            'quando quiser',
            20),
        _Etapa('Trote bem leve para desacelerar', 5),
      ],
    ),
  ],
};

// =============================================================================
// MODELOS DA API
// =============================================================================

class PlanoSemanal {
  const PlanoSemanal({
    this.titulo,
    required this.semanaAtual,
    required this.totalSemanas,
    required this.metaKm,
    required this.kmFeitos,
  });

  final String? titulo;
  final int semanaAtual;
  final int totalSemanas;
  final double metaKm;
  final double kmFeitos;

  double get progresso => metaKm > 0 ? (kmFeitos / metaKm).clamp(0.0, 1.0) : 0;
  double get faltam => math.max(0, metaKm - kmFeitos);

  factory PlanoSemanal.fromJson(Map<String, dynamic> j) => PlanoSemanal(
        titulo: _toStr(j['titulo']),
        semanaAtual: _toInt(j['semanaAtual']),
        totalSemanas: _toInt(j['totalSemanas']),
        metaKm: _toDouble(j['metaKm']),
        kmFeitos: _toDouble(j['kmFeitos']),
      );
}

class TreinoAgendado {
  const TreinoAgendado({
    required this.data,
    required this.titulo,
    this.tipo,
    this.resumo,
    this.distanciaKm,
    this.concluido = false,
  });

  final DateTime data;
  final String titulo;
  final String? tipo;
  final String? resumo;
  final double? distanciaKm;
  final bool concluido;

  static TreinoAgendado? fromJson(Map<String, dynamic> j) {
    final data = DateTime.tryParse('${j['data']}');
    final titulo = _toStr(j['titulo']);
    if (data == null || titulo == null) return null;
    return TreinoAgendado(
      data: data.toLocal(),
      titulo: titulo,
      tipo: _toStr(j['tipo']),
      resumo: _toStr(j['resumo']),
      distanciaKm: _toDoubleOuNulo(j['distanciaKm']),
      concluido: j['concluido'] == true,
    );
  }
}

class TreinosData {
  const TreinosData({this.plano, this.agenda = const []});

  final PlanoSemanal? plano;
  final List<TreinoAgendado> agenda;

  factory TreinosData.fromJson(Map<String, dynamic> j) {
    final p = j['plano'];
    return TreinosData(
      plano: p is Map<String, dynamic> ? PlanoSemanal.fromJson(p) : null,
      agenda: j['agenda'] is List
          ? (j['agenda'] as List)
              .whereType<Map<String, dynamic>>()
              .map(TreinoAgendado.fromJson)
              .whereType<TreinoAgendado>()
              .toList()
          : const [],
    );
  }
}

class _TreinosApi {
  /// GET /treinos com cache: sem internet, usa o último plano salvo no
  /// aparelho. Só devolve erro se não houver nada para mostrar.
  static Future<(TreinosData?, String?)> buscar() async {
    final r = await ApiOffline.buscar('/treinos', cache: 'treinos');
    final corpo = r.mapa;
    if (corpo == null) {
      return (null, r.erro ?? 'Resposta inválida do servidor.');
    }
    return (_somarPendentes(TreinosData.fromJson(corpo)), null);
  }

  /// Corridas desta semana ainda na fila já contam no progresso do plano.
  static TreinosData _somarPendentes(TreinosData d) {
    final p = d.plano;
    if (p == null) return d;
    final hoje = DateTime.now();
    final segunda =
        DateTime(hoje.year, hoje.month, hoje.day - (hoje.weekday - 1));
    var km = 0.0;
    for (final c in ApiOffline.corridasPendentes()) {
      final data =
          DateTime.tryParse('${c['iniciadoEm'] ?? c['finalizadoEm'] ?? ''}')
              ?.toLocal();
      if (data == null || data.isBefore(segunda)) continue;
      km += _toDouble(c['distanciaKm']);
    }
    if (km == 0) return d;
    return TreinosData(
      agenda: d.agenda,
      plano: PlanoSemanal(
        titulo: p.titulo,
        semanaAtual: p.semanaAtual,
        totalSemanas: p.totalSemanas,
        metaKm: p.metaKm,
        kmFeitos: p.kmFeitos + km,
      ),
    );
  }
}

// =============================================================================
// TELA
// =============================================================================

class TreinosScreen extends StatefulWidget {
  const TreinosScreen({super.key});

  @override
  State<TreinosScreen> createState() => _TreinosScreenState();
}

class _TreinosScreenState extends State<TreinosScreen> {
  bool _carregando = true;
  String? _erro;
  TreinosData _dados = const TreinosData();

  _Nivel _nivel = _Nivel.iniciante;
  DateTime _diaSelecionado = _soData(DateTime.now());

  @override
  void initState() {
    super.initState();
    Preferencias.instancia.addListener(_atualizar);
    Sincronizador.instancia.enviados.addListener(_carregar);
    _carregar();
  }

  @override
  void dispose() {
    Preferencias.instancia.removeListener(_atualizar);
    Sincronizador.instancia.enviados.removeListener(_carregar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final (dados, erro) = await _TreinosApi.buscar();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = erro;
      if (dados != null) _dados = dados;
    });
  }

  /// Abre a corrida; se for salva, recarrega o progresso da semana.
  Future<void> _correr({
    required String titulo,
    required String subtitulo,
    double? metaKm,
  }) async {
    HapticFeedback.mediumImpact();
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CorridaScreen(
          titulo: titulo,
          subtitulo: subtitulo,
          metaKm: metaKm,
        ),
      ),
    );
    if (salvou == true && mounted) _carregar();
  }

  void _abrirPredefinido(TreinoPredefinido t) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Cores.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _FolhaPredefinido(
        treino: t,
        onComecar: () {
          Navigator.pop(ctx);
          _correr(
            titulo: t.titulo,
            subtitulo: 'TREINO PREDEFINIDO',
            metaKm: t.metaKm,
          );
        },
      ),
    );
  }

  List<TreinoAgendado> get _treinosDoDia =>
      _dados.agenda.where((t) => _mesmoDia(t.data, _diaSelecionado)).toList()
        ..sort((a, b) => a.data.compareTo(b.data));

  @override
  Widget build(BuildContext context) {
    final plano = _dados.plano;

    return Scaffold(
      backgroundColor: _Cores.fundo,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _Cores.escuro,
          onRefresh: _carregar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // ---------------- Cabeçalho ----------------
              Text(
                plano != null ? 'PLANO PERSONALIZADO' : 'SEUS TREINOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _Cores.textoSecundario,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plano != null && plano.totalSemanas > 0
                    ? 'Semana ${plano.semanaAtual} de ${plano.totalSemanas}'
                    : 'Treinos',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _Cores.escuro,
                  letterSpacing: -0.5,
                ),
              ),
              if (plano?.titulo != null) ...[
                const SizedBox(height: 8),
                Text(plano!.titulo!,
                    style: TextStyle(
                        fontSize: 14.5, color: _Cores.textoSecundario)),
              ],
              const SizedBox(height: 20),

              // ---------------- Objetivo semanal ----------------
              if (_carregando)
                const _BlocoCarregando(altura: 132)
              else if (plano != null && plano.metaKm > 0)
                _CardObjetivo(plano: plano)
              else
                _CardSemPlano(erro: _erro, onTentar: _carregar),

              // ---------------- Predefinidos ----------------
              const SizedBox(height: 26),
              Text('TREINE NO SEU RITMO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _Cores.textoSecundario,
                    letterSpacing: 1.3,
                  )),
              const SizedBox(height: 4),
              Text('Treinos predefinidos grátis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro,
                  )),
              const SizedBox(height: 4),
              Text('Escolha seu nível e comece quando quiser.',
                  style:
                      TextStyle(fontSize: 13, color: _Cores.textoSecundario)),
              const SizedBox(height: 14),
              _SeletorNivel(
                nivel: _nivel,
                onChanged: (n) {
                  HapticFeedback.selectionClick();
                  setState(() => _nivel = n);
                },
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) =>
                    FadeTransition(opacity: a, child: c),
                child: Column(
                  key: ValueKey(_nivel),
                  children: [
                    for (final t in _predefinidos[_nivel]!) ...[
                      _CardPredefinido(
                        treino: t,
                        onTap: () => _abrirPredefinido(t),
                        onPlay: () => _correr(
                          titulo: t.titulo,
                          subtitulo: 'TREINO PREDEFINIDO',
                          metaKm: t.metaKm,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),

              // ---------------- Agenda ----------------
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text('Agenda de treinos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _Cores.escuro,
                        )),
                  ),
                  Tooltip(
                    message: 'Voltar para hoje',
                    child: Material(
                      color: _Cores.card,
                      shape:
                          CircleBorder(side: BorderSide(color: _Cores.borda)),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                              () => _diaSelecionado = _soData(DateTime.now()));
                        },
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.calendar_today_outlined,
                              size: 18, color: _Cores.escuro),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SeletorSemana(
                selecionado: _diaSelecionado,
                agenda: _dados.agenda,
                onSelecionar: (d) {
                  HapticFeedback.selectionClick();
                  setState(() => _diaSelecionado = d);
                },
              ),
              const SizedBox(height: 12),
              if (_carregando)
                const _BlocoCarregando(altura: 80)
              else
                _ListaDoDia(
                  dia: _diaSelecionado,
                  treinos: _treinosDoDia,
                  onTreino: (t) => _correr(
                    titulo: t.titulo,
                    subtitulo: 'TREINO DO PLANO',
                    metaKm: t.distanciaKm,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// OBJETIVO SEMANAL
// =============================================================================

class _CardObjetivo extends StatelessWidget {
  const _CardObjetivo({required this.plano});

  final PlanoSemanal plano;

  @override
  Widget build(BuildContext context) {
    final concluido = plano.faltam <= 0.05;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: _Cores.destaque,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Círculos decorativos ao fundo
            Positioned(
              right: -70,
              top: -70,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OBJETIVO SEMANAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _Cores.tinta,
                            letterSpacing: 1.4,
                          )),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _distancia(plano.metaKm),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: _Cores.tinta,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        concluido
                            ? 'Meta da semana concluída! 🎉'
                            : 'Faltam ${_distancia(plano.faltam)} para concluir',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3F4A16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AnelProgresso(progresso: plano.progresso),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Círculo escuro com o percentual e um arco verde que se preenche.
class _AnelProgresso extends StatelessWidget {
  const _AnelProgresso({required this.progresso});

  final double progresso;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progresso),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: 92,
        height: 92,
        child: CustomPaint(
          painter: _AnelPainter(v),
          child: Center(
            child: Text(
              '${(v * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnelPainter extends CustomPainter {
  const _AnelPainter(this.progresso);

  final double progresso;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = _Cores.tinta);

    final ret = Rect.fromCircle(center: c, radius: r - 7);
    canvas.drawArc(
      ret,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    if (progresso > 0) {
      canvas.drawArc(
        ret,
        -math.pi / 2,
        math.pi * 2 * progresso,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = _Cores.destaque,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnelPainter old) => old.progresso != progresso;
}

/// Quem ainda não tem plano (ou a API falhou) vê este card no lugar do objetivo.
class _CardSemPlano extends StatelessWidget {
  const _CardSemPlano({required this.erro, required this.onTentar});

  final String? erro;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Cores.superficie,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _Cores.destaque,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              erro != null ? Icons.wifi_off_rounded : Icons.flag_outlined,
              color: _Cores.tinta,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  erro != null ? 'Plano indisponível' : 'Sem plano no momento',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  erro ??
                      'Quando um treinador montar seu plano, a meta da '
                          'semana aparece aqui. Enquanto isso, use os '
                          'treinos abaixo.',
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 12.5, height: 1.4),
                ),
                if (erro != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onTentar,
                    child: const Text('Tentar de novo',
                        style: TextStyle(
                          color: _Cores.destaque,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TREINOS PREDEFINIDOS
// =============================================================================

class _SeletorNivel extends StatelessWidget {
  const _SeletorNivel({required this.nivel, required this.onChanged});

  final _Nivel nivel;
  final ValueChanged<_Nivel> onChanged;

  @override
  Widget build(BuildContext context) {
    const opcoes = [
      (_Nivel.iniciante, 'Iniciante'),
      (_Nivel.intermediario, 'Intermediário'),
    ];
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _Cores.segmento,
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final largura = c.maxWidth / opcoes.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: nivel == _Nivel.iniciante ? 0 : largura,
                top: 0,
                bottom: 0,
                width: largura,
                child: Container(
                  decoration: BoxDecoration(
                    color: _Cores.superficie,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (valor, rotulo) in opcoes)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(valor),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: valor == nivel
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: valor == nivel
                                  ? Colors.white
                                  : _Cores.textoSecundario,
                            ),
                            child: Text(rotulo),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardPredefinido extends StatefulWidget {
  const _CardPredefinido({
    required this.treino,
    required this.onTap,
    required this.onPlay,
  });

  final TreinoPredefinido treino;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  State<_CardPredefinido> createState() => _CardPredefinidoState();
}

class _CardPredefinidoState extends State<_CardPredefinido> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.treino;
    final realce = t.recomendado || _pressionado;

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
            color: realce ? _Cores.destaque : _Cores.borda,
            width: realce ? 1.5 : 1,
          ),
          boxShadow: t.recomendado
              ? [
                  BoxShadow(
                    color: _Cores.destaque.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _Cores.destaqueClaro,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(t.icone, color: _Cores.escuro, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(t.titulo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _Cores.escuro,
                          )),
                      if (t.recomendado)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _modoEscuro
                                ? const Color(0xFF2A2E28)
                                : const Color(0xFFF1F2F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('RECOMENDADO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _Cores.escuro,
                                letterSpacing: 0.8,
                              )),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${t.minutos} min · ${t.resumo}',
                      style: TextStyle(
                          fontSize: 12.5, color: _Cores.textoSecundario)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _Cores.superficie,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPlay,
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(Icons.play_arrow_rounded,
                      color: _Cores.destaque, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detalhes do treino predefinido: etapas e botão para começar.
class _FolhaPredefinido extends StatelessWidget {
  const _FolhaPredefinido({required this.treino, required this.onComecar});

  final TreinoPredefinido treino;
  final VoidCallback onComecar;

  @override
  Widget build(BuildContext context) {
    final t = treino;
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
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _Cores.superficie,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(t.icone, color: _Cores.destaque, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.titulo,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _Cores.escuro,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        [
                          '${t.minutos} min',
                          t.resumo,
                          if (t.metaKm != null)
                            'meta de ${_distancia(t.metaKm!)}',
                        ].join(' · '),
                        style: TextStyle(
                            fontSize: 13, color: _Cores.textoSecundario),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('COMO FUNCIONA',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: _Cores.textoSecundario,
                  letterSpacing: 1,
                )),
            const SizedBox(height: 10),
            for (var i = 0; i < t.etapas.length; i++)
              _LinhaEtapa(
                numero: i + 1,
                etapa: t.etapas[i],
                ultima: i == t.etapas.length - 1,
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _Cores.fundo,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: _Cores.textoSecundario),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Respeite seus limites: se sentir dor ou falta de ar '
                      'fora do normal, diminua o ritmo ou pare.',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: _Cores.textoSecundario),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onComecar,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Começar treino',
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
          ],
        ),
      ),
    );
  }
}

/// Uma etapa com número, linha vertical ligando as etapas e duração.
class _LinhaEtapa extends StatelessWidget {
  const _LinhaEtapa({
    required this.numero,
    required this.etapa,
    required this.ultima,
  });

  final int numero;
  final _Etapa etapa;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _Cores.destaque,
                    shape: BoxShape.circle,
                  ),
                  child: Text('$numero',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _Cores.tinta,
                      )),
                ),
                if (!ultima)
                  Expanded(
                    child: Container(width: 2, color: _Cores.destaqueClaro),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: ultima ? 0 : 16),
              child: Text(etapa.texto,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: _Cores.escuro,
                  )),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${etapa.minutos} min',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _Cores.textoSecundario,
                )),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// AGENDA
// =============================================================================

/// Os 7 dias da semana atual; dias com treino ganham um pontinho.
class _SeletorSemana extends StatelessWidget {
  const _SeletorSemana({
    required this.selecionado,
    required this.agenda,
    required this.onSelecionar,
  });

  final DateTime selecionado;
  final List<TreinoAgendado> agenda;
  final ValueChanged<DateTime> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final hoje = _soData(DateTime.now());
    final segunda = hoje.subtract(Duration(days: hoje.weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Cores.borda),
      ),
      child: Row(
        children: List.generate(7, (i) {
          final dia = DateTime(segunda.year, segunda.month, segunda.day + i);
          final ativo = _mesmoDia(dia, selecionado);
          final ehHoje = _mesmoDia(dia, hoje);
          final treinosDia = agenda.where((t) => _mesmoDia(t.data, dia));
          final temTreino = treinosDia.isNotEmpty;
          final feito = temTreino && treinosDia.every((t) => t.concluido);

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelecionar(dia),
              child: Column(
                children: [
                  Text(_letrasDia[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _Cores.textoSecundario,
                      )),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ativo
                          ? _Cores.superficie
                          : (feito ? _Cores.destaque : Colors.transparent),
                      shape: BoxShape.circle,
                      border: ehHoje && !ativo
                          ? Border.all(color: _Cores.destaque, width: 2)
                          : null,
                    ),
                    child: Text('${dia.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ativo
                              ? Colors.white
                              : (feito ? _Cores.tinta : _Cores.escuro),
                        )),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: temTreino && !feito
                          ? _Cores.verde
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ListaDoDia extends StatelessWidget {
  const _ListaDoDia({
    required this.dia,
    required this.treinos,
    required this.onTreino,
  });

  final DateTime dia;
  final List<TreinoAgendado> treinos;
  final ValueChanged<TreinoAgendado> onTreino;

  @override
  Widget build(BuildContext context) {
    final rotulo = '${_nomesDia[dia.weekday - 1]}, ${dia.day} de '
        '${_meses[dia.month - 1]}';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Column(
        key: ValueKey(dia),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(rotulo.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: _Cores.textoSecundario,
                  letterSpacing: 1,
                )),
          ),
          if (treinos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _Cores.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _Cores.borda),
              ),
              child: Row(
                children: [
                  Icon(Icons.self_improvement_rounded,
                      color: _Cores.textoSecundario),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nenhum treino marcado. Dia livre para descansar ou '
                      'fazer um treino predefinido.',
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _Cores.textoSecundario),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final t in treinos) ...[
              _CardAgendado(treino: t, onTap: () => onTreino(t)),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _CardAgendado extends StatelessWidget {
  const _CardAgendado({required this.treino, required this.onTap});

  final TreinoAgendado treino;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = treino;
    final detalhes = [
      if (t.distanciaKm != null) _distancia(t.distanciaKm!),
      if (t.resumo != null) t.resumo!,
    ].join(' · ');

    return Material(
      color: _Cores.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _Cores.borda),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: t.concluido ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: t.concluido ? _Cores.destaque : _Cores.superficie,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  t.concluido
                      ? Icons.check_rounded
                      : Icons.directions_run_rounded,
                  color: t.concluido ? _Cores.tinta : _Cores.destaque,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (t.tipo != null)
                      Text(t.tipo!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _Cores.verde,
                            letterSpacing: 0.8,
                          )),
                    const SizedBox(height: 2),
                    Text(t.titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _Cores.escuro,
                          decoration:
                              t.concluido ? TextDecoration.lineThrough : null,
                        )),
                    if (detalhes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(detalhes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5, color: _Cores.textoSecundario)),
                    ],
                  ],
                ),
              ),
              if (t.concluido)
                Text('FEITO',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: _Cores.verde,
                      letterSpacing: 0.8,
                    ))
              else
                Icon(Icons.chevron_right_rounded,
                    size: 22, color: _Cores.escuro),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// COMUNS
// =============================================================================

class _BlocoCarregando extends StatelessWidget {
  const _BlocoCarregando({required this.altura});

  final double altura;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altura,
      decoration: BoxDecoration(
        color: _Cores.borda.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child:
              CircularProgressIndicator(strokeWidth: 2.5, color: _Cores.escuro),
        ),
      ),
    );
  }
}
