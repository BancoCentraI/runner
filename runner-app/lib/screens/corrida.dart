import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../services/offline.dart';
import '../services/preferencia.dart';

// =============================================================================
// CORES (mesma paleta da home)
// =============================================================================

class _Cores {
  // Cores que são iguais nos dois temas
  static const tinta = Color(0xFF1A1A1A); // texto/ícone sobre verde-limão
  static const destaque = Color(0xFFD0FD38);
  static const vermelho = Color(0xFFEF4444);
  static const laranja = Color(0xFFF59E0B);
  static Color get escuro => // texto principal
      _modoEscuro ? const Color(0xFFF3F4F6) : const Color(0xFF1A1A1A);
  static Color get textoSecundario =>
      _modoEscuro ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  static Color get fundo =>
      _modoEscuro ? const Color(0xFF111311) : const Color(0xFFF6F7F4);
  static Color get cinzaClaro =>
      _modoEscuro ? const Color(0xFF252923) : const Color(0xFFF3F4F6);
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
// FORMATADORES
// =============================================================================

String _formatarTempo(Duration d) {
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(d.inHours)}:${dois(d.inMinutes % 60)}:${dois(d.inSeconds % 60)}';
}

/// segundos por km -> "5:42"
String _formatarPace(double? segPorKm) {
  if (segPorKm == null || segPorKm.isNaN || segPorKm.isInfinite) return '–:–';
  if (segPorKm <= 0 || segPorKm > 59 * 60) return '–:–';
  final s = segPorKm.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

String _formatarKm(double metros) =>
    (metros / 1000).toStringAsFixed(2).replaceAll('.', ',');

// =============================================================================
// MODELOS
// =============================================================================

class _Volta {
  const _Volta(
      {required this.numero, required this.tempo, required this.metros});

  final int numero;
  final Duration tempo;
  final double metros;

  double? get pace => metros < 20 ? null : tempo.inSeconds / (metros / 1000);
}

enum _Estado { parado, contagem, correndo, pausado }

enum _SinalGps { buscando, fraco, medio, bom, desligado }

// =============================================================================
// API
// =============================================================================

class _CorridaApi {
  /// POST /corridas pela fila offline: a corrida é salva no aparelho antes
  /// de tudo e enviada agora ou quando a internet voltar. Nunca se perde.
  static Future<ResultadoEnvio> salvar(Map<String, dynamic> corrida) =>
      ApiOffline.enviar('POST', '/corridas', corpo: corrida);
}

// =============================================================================
// TELA
// =============================================================================

class CorridaScreen extends StatefulWidget {
  const CorridaScreen({
    super.key,
    this.titulo = 'Corrida livre',
    this.subtitulo = 'TREINO DE HOJE',
    this.metaKm,
  });

  final String titulo;
  final String subtitulo;

  /// Se informado, o anel mostra o progresso até a meta.
  final double? metaKm;

  @override
  State<CorridaScreen> createState() => _CorridaScreenState();
}

class _CorridaScreenState extends State<CorridaScreen>
    with SingleTickerProviderStateMixin {
  _Estado _estado = _Estado.parado;
  _SinalGps _sinal = _SinalGps.buscando;

  final _cronometro = Stopwatch();
  Timer? _tick;
  Timer? _timerContagem;
  int _contagem = 3;

  StreamSubscription<Position>? _gps;
  Position? _ultima;
  final List<Position> _rota = [];
  double _metros = 0;
  double? _paceAtual; // seg/km, a partir da velocidade do GPS
  DateTime? _iniciadoEm;

  final List<_Volta> _voltas = [];
  Duration _inicioVoltaTempo = Duration.zero;
  double _inicioVoltaMetros = 0;
  int _proximoKm = 1;

  bool _salvando = false;

  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  Duration get _tempo => _cronometro.elapsed;
  bool get _emAndamento =>
      _estado == _Estado.correndo || _estado == _Estado.pausado;

  double? get _paceMedio =>
      _metros < 50 ? null : _tempo.inSeconds / (_metros / 1000);

  @override
  void initState() {
    super.initState();
    _iniciarGps();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _timerContagem?.cancel();
    _gps?.cancel();
    _pulso.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // GPS
  // ---------------------------------------------------------------------------

  Future<void> _iniciarGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) setState(() => _sinal = _SinalGps.desligado);
      return;
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      if (mounted) setState(() => _sinal = _SinalGps.desligado);
      return;
    }

    await _gps?.cancel();
    _gps = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen(_novaPosicao, onError: (e) {
      debugPrint('[GPS] Erro: $e');
      if (mounted) setState(() => _sinal = _SinalGps.fraco);
    });
  }

  void _novaPosicao(Position p) {
    if (!mounted) return;
    final sinal = p.accuracy <= 12
        ? _SinalGps.bom
        : p.accuracy <= 25
            ? _SinalGps.medio
            : _SinalGps.fraco;

    setState(() {
      _sinal = sinal;
      if (_estado != _Estado.correndo) return;

      // Ignora leituras imprecisas para não "inventar" distância.
      if (p.accuracy > 30) return;

      if (_ultima != null) {
        final d = Geolocator.distanceBetween(
            _ultima!.latitude, _ultima!.longitude, p.latitude, p.longitude);
        // Descarta saltos irreais (> 12 m/s ≈ 43 km/h)
        final dt = p.timestamp.difference(_ultima!.timestamp).inMilliseconds;
        final velocidade = dt > 0 ? d / (dt / 1000) : 0;
        if (velocidade < 12) _metros += d;
      }
      _ultima = p;
      _rota.add(p);
      _paceAtual = p.speed > 0.8 ? 1000 / p.speed : null;

      // Volta automática a cada km
      if (_metros >= _proximoKm * 1000) {
        _proximoKm++;
        _registrarVolta(automatica: true);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // CONTROLES
  // ---------------------------------------------------------------------------

  void _botaoPrincipal() {
    switch (_estado) {
      case _Estado.parado:
        _comecarContagem();
      case _Estado.contagem:
        _cancelarContagem();
      case _Estado.correndo:
        _pausar();
      case _Estado.pausado:
        _retomar();
    }
  }

  void _comecarContagem() {
    if (_sinal == _SinalGps.desligado) {
      _aviso('Ative a localização para registrar a distância.', erro: true);
      _iniciarGps();
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _estado = _Estado.contagem;
      _contagem = 3;
    });
    _timerContagem = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_contagem <= 1) {
        t.cancel();
        _iniciar();
      } else {
        HapticFeedback.selectionClick();
        setState(() => _contagem--);
      }
    });
  }

  void _cancelarContagem() {
    _timerContagem?.cancel();
    setState(() => _estado = _Estado.parado);
  }

  void _iniciar() {
    HapticFeedback.heavyImpact();
    _iniciadoEm = DateTime.now();
    _cronometro
      ..reset()
      ..start();
    _tick = Timer.periodic(const Duration(milliseconds: 500),
        (_) => mounted ? setState(() {}) : null);
    _pulso.repeat();
    setState(() => _estado = _Estado.correndo);
  }

  void _pausar() {
    HapticFeedback.mediumImpact();
    _cronometro.stop();
    _pulso.stop();
    setState(() {
      _estado = _Estado.pausado;
      _paceAtual = null;
      _ultima = null; // não soma o trajeto feito durante a pausa
    });
  }

  void _retomar() {
    HapticFeedback.mediumImpact();
    _cronometro.start();
    _pulso.repeat();
    setState(() => _estado = _Estado.correndo);
  }

  void _registrarVolta({bool automatica = false}) {
    if (!_emAndamento) return;
    HapticFeedback.lightImpact();
    final volta = _Volta(
      numero: _voltas.length + 1,
      tempo: _tempo - _inicioVoltaTempo,
      metros: _metros - _inicioVoltaMetros,
    );
    _inicioVoltaTempo = _tempo;
    _inicioVoltaMetros = _metros;
    setState(() => _voltas.insert(0, volta));
    if (!automatica) {
      _aviso('Volta ${volta.numero}: ${_formatarTempo(volta.tempo)} · '
          '${_formatarPace(volta.pace)} /km');
    }
  }

  Future<void> _finalizar() async {
    if (!_emAndamento) return;
    final estavaCorrendo = _estado == _Estado.correndo;
    if (estavaCorrendo) _pausar();

    final acao = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _Cores.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ResumoFolha(
        tempo: _tempo,
        metros: _metros,
        pace: _paceMedio,
        rota: _rota,
      ),
    );
    if (!mounted) return;

    switch (acao) {
      case 'salvar':
        await _salvar();
      case 'descartar':
        _encerrarSemSalvar();
      default:
        if (estavaCorrendo) _retomar();
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final resultado = await _CorridaApi.salvar({
      'titulo': widget.titulo,
      'iniciadoEm': _iniciadoEm?.toUtc().toIso8601String(),
      'finalizadoEm': DateTime.now().toUtc().toIso8601String(),
      'duracaoSegundos': _tempo.inSeconds,
      'distanciaKm': double.parse((_metros / 1000).toStringAsFixed(3)),
      'paceMedioSegPorKm': _paceMedio?.round(),
      'voltas': _voltas.reversed
          .map((v) => {
                'numero': v.numero,
                'duracaoSegundos': v.tempo.inSeconds,
                'distanciaKm':
                    double.parse((v.metros / 1000).toStringAsFixed(3)),
              })
          .toList(),
      'rota':
          _rota.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    });
    if (!mounted) return;
    setState(() => _salvando = false);

    switch (resultado) {
      case ResultadoEnvio.enviado:
        _aviso('Corrida salva! Bom trabalho 💪');
        _encerrarSemSalvar(sair: true);
      case ResultadoEnvio.naFila:
        // Sem internet: já está guardada no aparelho e conta nas telas.
        _aviso('Corrida salva no celular. Ela será enviada quando houver '
            'internet 💪');
        _encerrarSemSalvar(sair: true);
      case ResultadoEnvio.recusado:
        _aviso('O servidor recusou esta corrida. Tente salvar de novo.',
            erro: true);
    }
  }

  void _encerrarSemSalvar({bool sair = false}) {
    _tick?.cancel();
    _cronometro
      ..stop()
      ..reset();
    _pulso
      ..stop()
      ..reset();
    setState(() {
      _estado = _Estado.parado;
      _metros = 0;
      _rota.clear();
      _voltas.clear();
      _ultima = null;
      _paceAtual = null;
      _inicioVoltaTempo = Duration.zero;
      _inicioVoltaMetros = 0;
      _proximoKm = 1;
    });
    if (sair) Navigator.maybePop(context, true);
  }

  Future<void> _confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da corrida?'),
        content: const Text('A atividade em andamento será descartada.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continuar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _Cores.vermelho),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (sair == true && mounted) _encerrarSemSalvar(sair: true);
  }

  void _verRota() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Cores.superficie,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SEU TRAJETO',
                  style: TextStyle(
                      color: _Cores.destaque,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text('${_formatarKm(_metros)} km percorridos',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1.3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _rota.length < 2
                      ? const Center(
                          child: Text('Comece a correr para ver a rota',
                              style: TextStyle(color: Color(0xFF9CA3AF))))
                      : CustomPaint(painter: _RotaPainter(_rota)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _aviso(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor: erro ? _Cores.vermelho : _Cores.superficie,
      ));
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  double get _progressoAnel {
    final meta = widget.metaKm;
    if (meta != null && meta > 0) return (_metros / 1000 / meta).clamp(0, 1);
    // Sem meta: o anel funciona como um ponteiro de segundos.
    if (_estado == _Estado.parado || _estado == _Estado.contagem) return 0.82;
    return (_tempo.inMilliseconds % 60000) / 60000;
  }

  String get _status {
    switch (_estado) {
      case _Estado.parado:
        return _sinal == _SinalGps.desligado
            ? 'Ative o GPS para começar'
            : 'Pronto para começar';
      case _Estado.contagem:
        return 'Prepare-se...';
      case _Estado.correndo:
        return _paceAtual != null
            ? 'Ritmo atual ${_formatarPace(_paceAtual)} /km'
            : 'Correndo';
      case _Estado.pausado:
        return 'Pausado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_emAndamento,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarSaida();
      },
      child: Scaffold(
        backgroundColor: _Cores.fundo,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _Topo(
                      subtitulo: widget.subtitulo,
                      titulo: widget.titulo,
                      onVoltar: () => _emAndamento
                          ? _confirmarSaida()
                          : Navigator.maybePop(context),
                      onRota: _verRota,
                    ),
                    const SizedBox(height: 10),
                    _ChipGps(sinal: _sinal),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 20, bottom: 16),
                        child: Column(
                          children: [
                            _AnelTempo(
                              progresso: _progressoAnel,
                              tempo: _formatarTempo(_tempo),
                              status: _status,
                              correndo: _estado == _Estado.correndo,
                              pausado: _estado == _Estado.pausado,
                              pulso: _pulso,
                              metaKm: widget.metaKm,
                            ),
                            const SizedBox(height: 28),
                            _CardMetricas(
                              distancia: _formatarKm(_metros),
                              pace: _formatarPace(_paceMedio),
                            ),
                            if (_voltas.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _ListaVoltas(voltas: _voltas),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _Controles(
                      estado: _estado,
                      pulso: _pulso,
                      onPrincipal: _botaoPrincipal,
                      onParar: _emAndamento ? _finalizar : null,
                      onVolta: _emAndamento ? _registrarVolta : null,
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            if (_estado == _Estado.contagem)
              _OverlayContagem(numero: _contagem),
            if (_salvando)
              const ColoredBox(
                color: Color(0x88000000),
                child: Center(
                    child: CircularProgressIndicator(color: _Cores.destaque)),
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

class _BotaoRedondo extends StatelessWidget {
  const _BotaoRedondo({required this.icone, required this.onTap});

  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Cores.card,
      shape: CircleBorder(side: BorderSide(color: _Cores.borda)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icone, color: _Cores.escuro, size: 22),
        ),
      ),
    );
  }
}

class _Topo extends StatelessWidget {
  const _Topo({
    required this.subtitulo,
    required this.titulo,
    required this.onVoltar,
    required this.onRota,
  });

  final String subtitulo;
  final String titulo;
  final VoidCallback onVoltar;
  final VoidCallback onRota;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BotaoRedondo(icone: Icons.chevron_left_rounded, onTap: onVoltar),
        Expanded(
          child: Column(
            children: [
              Text(subtitulo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _Cores.textoSecundario,
                    letterSpacing: 1.4,
                  )),
              const SizedBox(height: 2),
              Text(titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro,
                  )),
            ],
          ),
        ),
        _BotaoRedondo(icone: Icons.route_rounded, onTap: onRota),
      ],
    );
  }
}

class _ChipGps extends StatelessWidget {
  const _ChipGps({required this.sinal});

  final _SinalGps sinal;

  @override
  Widget build(BuildContext context) {
    final (cor, texto) = switch (sinal) {
      _SinalGps.buscando => (_Cores.textoSecundario, 'Buscando GPS...'),
      _SinalGps.desligado => (_Cores.vermelho, 'GPS desligado'),
      _SinalGps.fraco => (_Cores.vermelho, 'GPS fraco'),
      _SinalGps.medio => (_Cores.laranja, 'GPS razoável'),
      _SinalGps.bom => (_Cores.verde, 'GPS forte'),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(texto,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: cor)),
        ],
      ),
    );
  }
}

/// Anel grande com o tempo. Ganha brilho e pulso enquanto corre.
class _AnelTempo extends StatelessWidget {
  const _AnelTempo({
    required this.progresso,
    required this.tempo,
    required this.status,
    required this.correndo,
    required this.pausado,
    required this.pulso,
    this.metaKm,
  });

  final double progresso;
  final String tempo;
  final String status;
  final bool correndo;
  final bool pausado;
  final AnimationController pulso;
  final double? metaKm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 270,
      child: AnimatedBuilder(
        animation: pulso,
        builder: (context, child) {
          final t = pulso.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (correndo)
                Container(
                  width: 250 + 20 * t,
                  height: 250 + 20 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _Cores.destaque.withValues(alpha: 0.5 * (1 - t)),
                      width: 2,
                    ),
                  ),
                ),
              child!,
            ],
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Cores.card.withValues(alpha: 0.5),
                boxShadow: correndo
                    ? [
                        BoxShadow(
                          color: _Cores.destaque.withValues(alpha: 0.35),
                          blurRadius: 40,
                        ),
                      ]
                    : null,
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(end: progresso),
              duration: const Duration(milliseconds: 500),
              builder: (_, v, __) => CustomPaint(
                size: const Size(250, 250),
                painter: _AnelPainter(
                  progresso: v,
                  cor: pausado ? _Cores.laranja : _Cores.destaque,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metaKm != null
                      ? 'TEMPO · META ${metaKm!.toStringAsFixed(metaKm! % 1 == 0 ? 0 : 1)} KM'
                      : 'TEMPO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _Cores.textoSecundario,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: pausado ? 0.45 : 1,
                  child: FittedBox(
                    child: Text(
                      tempo,
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: _Cores.escuro,
                        letterSpacing: -1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    status,
                    key: ValueKey(status),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: pausado ? _Cores.laranja : _Cores.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnelPainter extends CustomPainter {
  const _AnelPainter({required this.progresso, required this.cor});

  final double progresso;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raio = size.width / 2;

    canvas.drawCircle(
      centro,
      raio,
      Paint()
        ..color = _Cores.borda
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final ret = Rect.fromCircle(center: centro, radius: raio - 14);
    canvas.drawArc(
      ret,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = _Cores.cinzaClaro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    if (progresso > 0) {
      canvas.drawArc(
        ret,
        -math.pi / 2,
        math.pi * 2 * progresso,
        false,
        Paint()
          ..color = cor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnelPainter old) =>
      old.progresso != progresso || old.cor != cor;
}

class _CardMetricas extends StatelessWidget {
  const _CardMetricas({required this.distancia, required this.pace});

  final String distancia;
  final String pace;

  @override
  Widget build(BuildContext context) {
    Widget metrica(String rotulo, String valor, String unidade) => Expanded(
          child: Column(
            children: [
              Text(rotulo,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _Cores.textoSecundario,
                    letterSpacing: 0.8,
                  )),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (c, a) =>
                    FadeTransition(opacity: a, child: c),
                child: Text(valor,
                    key: ValueKey(valor),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _Cores.escuro,
                      fontFeatures: [FontFeature.tabularFigures()],
                    )),
              ),
              const SizedBox(height: 2),
              Text(unidade,
                  style:
                      TextStyle(fontSize: 11, color: _Cores.textoSecundario)),
            ],
          ),
        );

    final divisor = SizedBox(
        height: 56, child: VerticalDivider(width: 1, color: _Cores.borda));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          metrica('DISTÂNCIA', distancia, 'km'),
          divisor,
          metrica('PACE MÉDIO', pace, '/km'),
          divisor,
          // Sem sensor conectado: integre aqui um relógio/cinta (BLE ou
          // Health Connect / HealthKit) quando disponível.
          metrica('BATIMENTOS', '–', 'bpm'),
        ],
      ),
    );
  }
}

class _ListaVoltas extends StatelessWidget {
  const _ListaVoltas({required this.voltas});

  final List<_Volta> voltas;

  @override
  Widget build(BuildContext context) {
    // A melhor volta (menor pace) ganha destaque.
    final comPace = voltas.where((v) => v.pace != null);
    final melhor = comPace.isEmpty
        ? null
        : comPace.reduce((a, b) => a.pace! <= b.pace! ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VOLTAS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _Cores.textoSecundario,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 6),
          for (final v in voltas.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v == melhor ? _Cores.destaque : _Cores.cinzaClaro,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${v.numero}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: v == melhor ? _Cores.tinta : _Cores.escuro)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${_formatarKm(v.metros)} km',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: _Cores.escuro)),
                  ),
                  Text(_formatarTempo(v.tempo),
                      style: TextStyle(
                          color: _Cores.textoSecundario, fontSize: 13)),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 64,
                    child: Text('${_formatarPace(v.pace)} /km',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _Cores.escuro,
                            fontSize: 13)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Controles extends StatelessWidget {
  const _Controles({
    required this.estado,
    required this.pulso,
    required this.onPrincipal,
    required this.onParar,
    required this.onVolta,
  });

  final _Estado estado;
  final AnimationController pulso;
  final VoidCallback onPrincipal;
  final VoidCallback? onParar;
  final VoidCallback? onVolta;

  @override
  Widget build(BuildContext context) {
    final correndo = estado == _Estado.correndo;

    Widget lateral(IconData icone, VoidCallback? onTap, String dica) => Tooltip(
          message: dica,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: onTap == null ? 0.4 : 1,
            child: Material(
              color: _Cores.card,
              shape: CircleBorder(side: BorderSide(color: _Cores.borda)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Icon(icone, color: _Cores.escuro, size: 22),
                ),
              ),
            ),
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        lateral(Icons.stop_rounded, onParar, 'Finalizar'),
        const SizedBox(width: 26),
        SizedBox(
          width: 110,
          height: 110,
          child: AnimatedBuilder(
            animation: pulso,
            builder: (_, child) => Stack(
              alignment: Alignment.center,
              children: [
                if (correndo)
                  Container(
                    width: 96 + 14 * pulso.value,
                    height: 96 + 14 * pulso.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _Cores.destaque
                          .withValues(alpha: 0.35 * (1 - pulso.value)),
                    ),
                  ),
                child!,
              ],
            ),
            child: Material(
              color: _Cores.superficie,
              shape: const CircleBorder(),
              elevation: 10,
              shadowColor: Colors.black45,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPrincipal,
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child: Icon(
                      switch (estado) {
                        _Estado.correndo => Icons.pause_rounded,
                        _Estado.contagem => Icons.close_rounded,
                        _ => Icons.play_arrow_rounded,
                      },
                      key: ValueKey(estado),
                      color: _Cores.destaque,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 26),
        lateral(Icons.flag_outlined, onVolta, 'Marcar volta'),
      ],
    );
  }
}

class _OverlayContagem extends StatelessWidget {
  const _OverlayContagem({required this.numero});

  final int numero;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: _Cores.superficie.withValues(alpha: 0.88),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('PREPARE-SE',
                    style: TextStyle(
                      color: _Cores.destaque,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    )),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (c, a) => ScaleTransition(
                    scale: Tween(begin: 1.8, end: 1.0).animate(
                        CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
                    child: FadeTransition(opacity: a, child: c),
                  ),
                  child: Text('$numero',
                      key: ValueKey(numero),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 140,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      )),
                ),
                const SizedBox(height: 24),
                const Text('Toque no X para cancelar',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumoFolha extends StatelessWidget {
  const _ResumoFolha({
    required this.tempo,
    required this.metros,
    required this.pace,
    required this.rota,
  });

  final Duration tempo;
  final double metros;
  final double? pace;
  final List<Position> rota;

  @override
  Widget build(BuildContext context) {
    Widget item(String rotulo, String valor) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _Cores.textoSecundario,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(valor,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _Cores.escuro)),
            ],
          ),
        );

    return SafeArea(
      child: Padding(
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
            Text('Finalizar corrida?',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro)),
            const SizedBox(height: 16),
            if (rota.length >= 2) ...[
              Container(
                height: 130,
                decoration: BoxDecoration(
                  color: _Cores.superficie,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomPaint(painter: _RotaPainter(rota)),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                item('DISTÂNCIA', '${_formatarKm(metros)} km'),
                item('TEMPO', _formatarTempo(tempo)),
                item('PACE', '${_formatarPace(pace)} /km'),
              ],
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'salvar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Cores.superficie,
                foregroundColor: _Cores.destaque,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: const Text('Salvar atividade',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, 'continuar'),
                    child: Text('Continuar correndo',
                        style: TextStyle(color: _Cores.escuro)),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, 'descartar'),
                    child: const Text('Descartar',
                        style: TextStyle(color: _Cores.vermelho)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Desenha o trajeto real do GPS, ajustado ao tamanho da caixa.
class _RotaPainter extends CustomPainter {
  const _RotaPainter(this.rota);

  final List<Position> rota;

  @override
  void paint(Canvas canvas, Size size) {
    if (rota.length < 2) return;

    var minLat = rota.first.latitude, maxLat = minLat;
    var minLng = rota.first.longitude, maxLng = minLng;
    for (final p in rota) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    // Corrige a distorção da longitude conforme a latitude
    final cosLat = math.cos(((minLat + maxLat) / 2) * math.pi / 180);
    final largura = math.max((maxLng - minLng) * cosLat, 1e-6);
    final altura = math.max(maxLat - minLat, 1e-6);
    const margem = 20.0;
    final escala = math.min(
      (size.width - margem * 2) / largura,
      (size.height - margem * 2) / altura,
    );
    final dx = (size.width - largura * escala) / 2;
    final dy = (size.height - altura * escala) / 2;

    Offset ponto(Position p) => Offset(
          dx + (p.longitude - minLng) * cosLat * escala,
          dy + (maxLat - p.latitude) * escala,
        );

    final caminho = Path()..moveTo(ponto(rota.first).dx, ponto(rota.first).dy);
    for (final p in rota.skip(1)) {
      final o = ponto(p);
      caminho.lineTo(o.dx, o.dy);
    }

    canvas.drawPath(
      caminho,
      Paint()
        ..color = _Cores.destaque.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      caminho,
      Paint()
        ..color = _Cores.destaque
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(ponto(rota.first), 6, Paint()..color = Colors.white);
    canvas.drawCircle(ponto(rota.last), 7, Paint()..color = _Cores.destaque);
    canvas.drawCircle(
      ponto(rota.last),
      7,
      Paint()
        ..color = _Cores.tinta
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RotaPainter old) =>
      old.rota.length != rota.length;
}
