import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/offline.dart';
import 'configuracoes.dart';

// =============================================================================
// CORES
// =============================================================================

const _destaque = Color(0xFFD0FD38);
const _tinta = Color(0xFF1A1A1A); // texto/ícone sobre verde-limão
const _textoClaro = Color(0xFF9CA3AF); // texto sobre fundos escuros

/// Paleta da tela, lida do tema atual com `Theme.of(context)`.
/// Como depende do Theme, o Flutter redesenha tudo sozinho quando o
/// usuário troca entre claro e escuro — inclusive widgets `const`.
class _Paleta {
  const _Paleta(this.escuro);

  factory _Paleta.of(BuildContext context) =>
      _Paleta(Theme.of(context).brightness == Brightness.dark);

  final bool escuro;

  Color get fundo => escuro ? const Color(0xFF111311) : const Color(0xFFF6F7F4);
  Color get card => escuro ? const Color(0xFF1C1F1B) : Colors.white;
  Color get borda => escuro ? const Color(0xFF2C302A) : const Color(0xFFE5E7EB);
  Color get texto => escuro ? const Color(0xFFF3F4F6) : const Color(0xFF1A1A1A);
  Color get textoSecundario =>
      escuro ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get destaqueSuave =>
      escuro ? const Color(0xFF2E3A12) : const Color(0xFFEEF9C9);
  Color get corSobreSuave => escuro ? _destaque : _tinta;
  Color get cardTreinador =>
      escuro ? const Color(0xFF1E2620) : const Color(0xFFE8EDE9);
  Color get verde => escuro ? const Color(0xFF9BC27A) : const Color(0xFF386641);
  Color get vermelhoSuave =>
      escuro ? const Color(0xFF3A1D1D) : const Color(0xFFFEF2F2);
  Color get superficie =>
      escuro ? const Color(0xFF262A23) : const Color(0xFF1A1A1A);
  Color get sombra => Colors.black.withValues(alpha: escuro ? 0.35 : 0.06);

  // ---------------- Topo (herói) ----------------
  // Escuro: degradê grafite com detalhes verde-limão.
  // Claro: degradê verde-limão vibrante com detalhes grafite.

  List<Color> get heroi => escuro
      ? const [Color(0xFF2B3122), Color(0xFF161A14)]
      : const [Color(0xFFE6FC86), Color(0xFFC6F12C)];

  /// Nome e números grandes no topo.
  Color get heroiTexto => escuro ? Colors.white : _tinta;

  /// Nível e textos menores no topo.
  Color get heroiTextoSec => escuro ? _textoClaro : const Color(0xFF4A5A12);

  /// "SUA CONTA", anéis e rota desenhados no fundo.
  Color get heroiLinha => escuro ? _destaque : _tinta;

  /// Base dos elementos "de vidro" (botão, selos).
  Color get vidro => escuro ? Colors.white : _tinta;

  // Avatar
  List<Color> get aro => escuro
      ? const [_destaque, Color(0xFF8DB01E), _destaque]
      : const [_tinta, Color(0xFF4B5320), _tinta];
  Color get aroIntervalo =>
      escuro ? const Color(0xFF1A1D16) : const Color(0xFFF7FDE0);
  Color get avatarFundo => escuro ? const Color(0xFF23271E) : _tinta;
  Color get halo => escuro
      ? _destaque.withValues(alpha: 0.28)
      : Colors.white.withValues(alpha: 0.7);

  /// Ícones da barra de status sobre o topo.
  SystemUiOverlayStyle get barraStatus =>
      escuro ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
}

// =============================================================================
// AJUDANTES
// =============================================================================

int _toInt(Object? v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

double _toDouble(Object? v) =>
    v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

double? _toDoubleOuNulo(Object? v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

String? _toStr(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// 284.0 -> "284" | 18.4 -> "18,4"
String _formatarKm(double v) {
  final t =
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return t.replaceAll('.', ',');
}

String _iniciais(String nome) {
  final partes =
      nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first[0].toUpperCase();
  return (partes.first[0] + partes.last[0]).toUpperCase();
}

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

// =============================================================================
// MODELO
// =============================================================================

class Conquista {
  const Conquista({required this.titulo, this.descricao});

  final String titulo;
  final String? descricao;

  factory Conquista.fromJson(Map<String, dynamic> json) => Conquista(
        titulo: _toStr(json['titulo']) ?? '',
        descricao: _toStr(json['descricao']),
      );
}

class PerfilData {
  const PerfilData({
    this.nome,
    this.nivel,
    this.planoAtivo = false,
    this.semanas = 0,
    this.treinos = 0,
    this.kmTotal = 0,
    this.ehTreinador = false,
    this.treinadorNome,
    this.treinadorMensagem,
    this.nivelProgresso,
    this.proximoNivel,
    this.melhorPace,
    this.maiorDistanciaKm,
    this.maiorSequenciaDias,
    this.conquistas = const [],
  });

  final String? nome;

  /// Ex.: "Corredor intermediário"
  final String? nivel;
  final bool planoAtivo;
  final int semanas;
  final int treinos;
  final double kmTotal;

  /// Mostra o card "Acessar painel do treinador"
  final bool ehTreinador;
  final String? treinadorNome;
  final String? treinadorMensagem;

  /// Opcionais: só aparecem se a API mandar.
  final double? nivelProgresso; // 0..1
  final String? proximoNivel;
  final double? melhorPace; // segundos por km
  final double? maiorDistanciaKm;
  final int? maiorSequenciaDias;
  final List<Conquista> conquistas;

  bool get temRecordes =>
      melhorPace != null ||
      maiorDistanciaKm != null ||
      maiorSequenciaDias != null;

  PerfilData comNome(String novo) => PerfilData(
        nome: novo,
        nivel: nivel,
        planoAtivo: planoAtivo,
        semanas: semanas,
        treinos: treinos,
        kmTotal: kmTotal,
        ehTreinador: ehTreinador,
        treinadorNome: treinadorNome,
        treinadorMensagem: treinadorMensagem,
        nivelProgresso: nivelProgresso,
        proximoNivel: proximoNivel,
        melhorPace: melhorPace,
        maiorDistanciaKm: maiorDistanciaKm,
        maiorSequenciaDias: maiorSequenciaDias,
        conquistas: conquistas,
      );

  factory PerfilData.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? objeto(String chave) {
      final v = json[chave];
      return v is Map<String, dynamic> ? v : null;
    }

    final treinador = objeto('treinador');
    final recordes = objeto('recordes');
    final sequencia = recordes?['maiorSequenciaDias'];

    return PerfilData(
      nome: _toStr(json['nome']),
      nivel: _toStr(json['nivel']),
      planoAtivo: json['planoAtivo'] == true,
      semanas: _toInt(json['semanas']),
      treinos: _toInt(json['treinos']),
      kmTotal: _toDouble(json['kmTotal']),
      ehTreinador: json['ehTreinador'] == true,
      treinadorNome: _toStr(treinador?['nome']),
      treinadorMensagem: _toStr(treinador?['mensagem']),
      nivelProgresso: _toDoubleOuNulo(json['nivelProgresso'])?.clamp(0.0, 1.0),
      proximoNivel: _toStr(json['proximoNivel']),
      melhorPace: _toDoubleOuNulo(recordes?['melhorPaceSegPorKm']),
      maiorDistanciaKm: _toDoubleOuNulo(recordes?['maiorDistanciaKm']),
      maiorSequenciaDias: sequencia == null ? null : _toInt(sequencia),
      conquistas: json['conquistas'] is List
          ? (json['conquistas'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Conquista.fromJson)
              .where((c) => c.titulo.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

// =============================================================================
// API
// =============================================================================

class _PerfilApi {
  /// GET /perfil com cache: sem internet, usa o último perfil salvo no
  /// aparelho. Corridas ainda não enviadas já contam em treinos e km.
  static Future<PerfilData> buscar() async {
    final r = await ApiOffline.buscar('/perfil', cache: 'perfil');
    final corpo = r.mapa;
    final dados =
        corpo != null ? PerfilData.fromJson(corpo) : const PerfilData();
    return _somarPendentes(dados);
  }

  static PerfilData _somarPendentes(PerfilData d) {
    final pendentes = ApiOffline.corridasPendentes();
    if (pendentes.isEmpty) return d;
    final km =
        pendentes.fold<double>(0, (s, c) => s + _toDouble(c['distanciaKm']));
    return PerfilData(
      nome: d.nome,
      nivel: d.nivel,
      planoAtivo: d.planoAtivo,
      semanas: d.semanas,
      treinos: d.treinos + pendentes.length,
      kmTotal: d.kmTotal + km,
      ehTreinador: d.ehTreinador,
      treinadorNome: d.treinadorNome,
      treinadorMensagem: d.treinadorMensagem,
      nivelProgresso: d.nivelProgresso,
      proximoNivel: d.proximoNivel,
      melhorPace: d.melhorPace,
      maiorDistanciaKm: d.maiorDistanciaKm,
      maiorSequenciaDias: d.maiorSequenciaDias,
      conquistas: d.conquistas,
    );
  }
}

// =============================================================================
// TELA
// =============================================================================

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({
    super.key,
    this.onPainelTreinador,
    this.onAbrirConversa,
  });

  /// Chamado ao tocar em "Acessar painel do treinador".
  final VoidCallback? onPainelTreinador;

  /// Chamado ao tocar em "Abrir conversa".
  final VoidCallback? onAbrirConversa;

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _carregando = true;
  PerfilData _dados = const PerfilData();

  @override
  void initState() {
    super.initState();
    // A fila enviou algo: recarrega os números.
    Sincronizador.instancia.enviados.addListener(_carregar);
    _carregar();
  }

  @override
  void dispose() {
    Sincronizador.instancia.enviados.removeListener(_carregar);
    super.dispose();
  }

  Future<void> _carregar() async {
    final dados = await _PerfilApi.buscar();
    if (!mounted) return;
    setState(() {
      _dados = dados;
      _carregando = false;
    });
  }

  /// Nome da API; se não vier, usa o nome do cadastro no Firebase.
  String get _nome =>
      _dados.nome ??
      _toStr(FirebaseAuth.instance.currentUser?.displayName) ??
      'Atleta';

  /// "Desde mar 2025", a partir da data de criação da conta no Firebase.
  String? get _membroDesde {
    final criado = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (criado == null) return null;
    return 'Desde ${_meses[criado.month - 1]} ${criado.year}';
  }

  void _acao(String nome) => debugPrint('[BOTÃO] $nome');

  Future<void> _abrirConfiguracoes() async {
    HapticFeedback.selectionClick();
    final alterou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
    );
    if (alterou != true || !mounted) return;

    // O nome pode ter mudado nas configurações.
    final nome = _toStr(FirebaseAuth.instance.currentUser?.displayName);
    if (nome != null) setState(() => _dados = _dados.comNome(nome));
  }

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final dados = _dados;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.barraStatus,
      child: Scaffold(
        backgroundColor: p.fundo,
        body: _carregando
            ? const _Esqueleto()
            : RefreshIndicator(
                color: p.texto,
                backgroundColor: p.card,
                onRefresh: _carregar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    // Topo de ponta a ponta + números sobrepostos
                    _Topo(
                      nome: _nome,
                      nivel: dados.nivel,
                      planoAtivo: dados.planoAtivo,
                      membroDesde: _membroDesde,
                      semanas: dados.semanas,
                      treinos: dados.treinos,
                      kmTotal: dados.kmTotal,
                      onConfiguracoes: _abrirConfiguracoes,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (dados.nivelProgresso != null) ...[
                            const SizedBox(height: 16),
                            _Entrada(
                              ordem: 2,
                              child: _CardNivel(
                                nivel: dados.nivel,
                                proximo: dados.proximoNivel,
                                progresso: dados.nivelProgresso!,
                              ),
                            ),
                          ],
                          if (dados.ehTreinador) ...[
                            const SizedBox(height: 16),
                            _Entrada(
                              ordem: 3,
                              child: _CardPainelTreinador(
                                onTap: widget.onPainelTreinador ??
                                    () => _acao('Painel do treinador'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          _Entrada(
                            ordem: 4,
                            child: _SecaoMedias(
                              semanas: dados.semanas,
                              treinos: dados.treinos,
                              kmTotal: dados.kmTotal,
                            ),
                          ),
                          if (dados.treinadorNome != null) ...[
                            const SizedBox(height: 28),
                            _Entrada(
                              ordem: 5,
                              child: _CardAcompanhamento(
                                treinador: dados.treinadorNome!,
                                mensagem: dados.treinadorMensagem,
                                onAbrirConversa: widget.onAbrirConversa ??
                                    () => _acao('Abrir conversa'),
                              ),
                            ),
                          ],
                          if (dados.conquistas.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _Entrada(
                              ordem: 6,
                              child: _SecaoConquistas(
                                  conquistas: dados.conquistas),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              'Runner · feito para quem corre',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: p.textoSecundario,
                              ),
                            ),
                          ),
                        ],
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
// ANIMAÇÕES
// =============================================================================

/// Faz cada bloco surgir de baixo, um depois do outro.
class _Entrada extends StatelessWidget {
  const _Entrada({required this.ordem, required this.child});

  final int ordem;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + ordem * 110),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

/// Número que "conta" de 0 até o valor final.
class _NumeroAnimado extends StatelessWidget {
  const _NumeroAnimado({
    required this.valor,
    required this.formatar,
    required this.estilo,
  });

  final double valor;
  final String Function(double) formatar;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(formatar(v), style: estilo),
    );
  }
}

/// Placeholder pulsante enquanto o perfil carrega.
class _Esqueleto extends StatefulWidget {
  const _Esqueleto();

  @override
  State<_Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<_Esqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    Widget bloco(double altura) => Container(
          height: altura,
          decoration: BoxDecoration(
            color: p.borda,
            borderRadius: BorderRadius.circular(22),
          ),
        );

    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            height: 360 + MediaQuery.of(context).padding.top,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: p.heroi,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: bloco(92)),
                    const SizedBox(width: 10),
                    Expanded(child: bloco(92)),
                    const SizedBox(width: 10),
                    Expanded(child: bloco(92)),
                  ],
                ),
                const SizedBox(height: 16),
                bloco(110),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TOPO (de ponta a ponta)
// =============================================================================

class _Topo extends StatelessWidget {
  const _Topo({
    required this.nome,
    required this.nivel,
    required this.planoAtivo,
    required this.membroDesde,
    required this.semanas,
    required this.treinos,
    required this.kmTotal,
    required this.onConfiguracoes,
  });

  final String nome;
  final String? nivel;
  final bool planoAtivo;
  final String? membroDesde;
  final int semanas;
  final int treinos;
  final double kmTotal;
  final VoidCallback onConfiguracoes;

  /// Quanto o card de números invade o topo escuro.
  static const _sobreposicao = 52.0;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final topo = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            // ---------------- Fundo escuro ----------------
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: p.heroi,
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(36)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                          painter: _OndasPainter(cor: p.heroiLinha)),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          20, topo + 12, 20, _sobreposicao + 28),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'SUA CONTA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: p.heroiLinha,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                              ),
                              _BotaoVidro(
                                icone: Icons.settings_outlined,
                                onTap: onConfiguracoes,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _Entrada(
                            ordem: 0,
                            child: _Avatar(
                              iniciais: _iniciais(nome),
                              planoAtivo: planoAtivo,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            nome,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 27,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: p.heroiTexto,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (nivel != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              nivel!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14.5, color: p.heroiTextoSec),
                            ),
                          ],
                          if (planoAtivo || membroDesde != null) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (planoAtivo)
                                  const _Selo(
                                    texto: 'PLANO ATIVO',
                                    icone: Icons.bolt,
                                    preenchido: true,
                                  ),
                                if (membroDesde != null)
                                  _Selo(
                                    texto: membroDesde!.toUpperCase(),
                                    icone: Icons.event_outlined,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Espaço para a metade do card de números que fica para fora
            const SizedBox(height: _sobreposicao),
          ],
        ),

        // ---------------- Números (flutuando) ----------------
        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: _Entrada(
            ordem: 1,
            child: Container(
              height: _sobreposicao * 2,
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: p.borda),
                boxShadow: [
                  BoxShadow(
                    color: p.escuro
                        ? p.sombra
                        : const Color(0xFF6B7F1A).withValues(alpha: 0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _Numero(
                    icone: Icons.calendar_month_outlined,
                    valor: semanas.toDouble(),
                    rotulo: semanas == 1 ? 'Semana' : 'Semanas',
                    formatar: (v) => '${v.round()}',
                  ),
                  const _Divisor(),
                  _Numero(
                    icone: Icons.directions_run_rounded,
                    valor: treinos.toDouble(),
                    rotulo: treinos == 1 ? 'Treino' : 'Treinos',
                    formatar: (v) => '${v.round()}',
                  ),
                  const _Divisor(),
                  _Numero(
                    icone: Icons.route_rounded,
                    valor: kmTotal,
                    rotulo: 'km total',
                    destaque: true,
                    formatar: (v) => _formatarKm(
                        kmTotal == kmTotal.truncateToDouble()
                            ? v.roundToDouble()
                            : (v * 10).round() / 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotaoVidro extends StatelessWidget {
  const _BotaoVidro({required this.icone, required this.onTap});

  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Material(
      color: p.vidro.withValues(alpha: 0.08),
      shape: CircleBorder(
        side: BorderSide(color: p.vidro.withValues(alpha: 0.14)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icone, color: p.heroiTexto, size: 21),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.iniciais, required this.planoAtivo});

  final String iniciais;
  final bool planoAtivo;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Halo verde
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: p.halo,
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Anel com degradê
          Container(
            width: 112,
            height: 112,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: p.aro),
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.aroIntervalo,
              ),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.avatarFundo,
                ),
                child: Text(
                  iniciais,
                  style: const TextStyle(
                    color: _destaque,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          if (planoAtivo)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _destaque,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.aroIntervalo, width: 3),
                ),
                child: const Icon(Icons.bolt, size: 17, color: _tinta),
              ),
            ),
        ],
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo({required this.texto, this.icone, this.preenchido = false});

  final String texto;
  final IconData? icone;
  final bool preenchido;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    // Preenchido: verde-limão no escuro, grafite no claro (contraste com o topo).
    final fundoPreenchido = p.escuro ? _destaque : _tinta;
    final cor = preenchido
        ? (p.escuro ? _tinta : _destaque)
        : (p.escuro ? const Color(0xFFD1D5DB) : _tinta);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: preenchido ? fundoPreenchido : p.vidro.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: preenchido
            ? null
            : Border.all(color: p.vidro.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 12, color: cor),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: cor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({
    required this.icone,
    required this.valor,
    required this.rotulo,
    required this.formatar,
    this.destaque = false,
  });

  final IconData icone;
  final double valor;
  final String rotulo;
  final String Function(double) formatar;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: destaque ? _destaque : p.destaqueSuave,
              shape: BoxShape.circle,
            ),
            child: Icon(icone,
                size: 15, color: destaque ? _tinta : p.corSobreSuave),
          ),
          const SizedBox(height: 6),
          _NumeroAnimado(
            valor: valor,
            formatar: formatar,
            estilo: TextStyle(
              color: p.texto,
              fontSize: 21,
              height: 1.1,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(rotulo,
              style: TextStyle(
                  color: p.textoSecundario,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 52, color: _Paleta.of(context).borda);
  }
}

/// Anéis concêntricos e uma rota decorativa no topo escuro.
class _OndasPainter extends CustomPainter {
  const _OndasPainter({required this.cor});

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width * 0.5, size.height * 0.36);
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(
        centro,
        78.0 + i * 34,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = cor.withValues(alpha: 0.11 - i * 0.014),
      );
    }

    final rota = Path()
      ..moveTo(-10, size.height * 0.80)
      ..quadraticBezierTo(size.width * 0.22, size.height * 0.62,
          size.width * 0.40, size.height * 0.76)
      ..quadraticBezierTo(size.width * 0.62, size.height * 0.92,
          size.width * 0.80, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.92, size.height * 0.56,
          size.width + 10, size.height * 0.62);
    canvas.drawPath(
      rota,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = cor.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant _OndasPainter old) => old.cor != cor;
}

// =============================================================================
// NÍVEL
// =============================================================================

class _CardNivel extends StatelessWidget {
  const _CardNivel({
    required this.nivel,
    required this.proximo,
    required this.progresso,
  });

  final String? nivel;
  final String? proximo;
  final double progresso;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.borda),
        boxShadow: [
          BoxShadow(
            color: p.sombra,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progresso),
            duration: const Duration(milliseconds: 1300),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => SizedBox(
              width: 70,
              height: 70,
              child: CustomPaint(
                painter: _AnelPainter(v, trilho: p.borda),
                child: Center(
                  child: Text(
                    '${(v * 100).round()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: p.texto,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROGRESSO DE NÍVEL',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: p.verde,
                      letterSpacing: 1,
                    )),
                const SizedBox(height: 4),
                Text(
                  proximo != null ? 'Rumo a $proximo' : (nivel ?? 'Seu nível'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: p.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  progresso >= 1
                      ? 'Pronto para subir de nível!'
                      : 'Continue treinando para evoluir.',
                  style: TextStyle(fontSize: 12.5, color: p.textoSecundario),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnelPainter extends CustomPainter {
  const _AnelPainter(this.progresso, {required this.trilho});

  final double progresso;
  final Color trilho;

  @override
  void paint(Canvas canvas, Size size) {
    final ret = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.width / 2 - 4);
    canvas.drawArc(
      ret,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = trilho,
    );
    if (progresso > 0) {
      canvas.drawArc(
        ret,
        -math.pi / 2,
        math.pi * 2 * progresso,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = _destaque,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnelPainter old) =>
      old.progresso != progresso || old.trilho != trilho;
}

// =============================================================================
// MÉDIAS (calculadas a partir de semanas, treinos e km da API)
// =============================================================================

class _SecaoMedias extends StatelessWidget {
  const _SecaoMedias({
    required this.semanas,
    required this.treinos,
    required this.kmTotal,
  });

  final int semanas;
  final int treinos;
  final double kmTotal;

  /// 4.25 -> "4,3" | 3.0 -> "3"
  static String _umaCasa(double v) => _formatarKm((v * 10).round() / 10);

  @override
  Widget build(BuildContext context) {
    final kmPorTreino = treinos > 0 ? kmTotal / treinos : 0.0;
    final treinosPorSemana = semanas > 0 ? treinos / semanas : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TituloSecao(sobre: 'SEU RITMO', titulo: 'Suas médias'),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TileNumero(
                  icone: Icons.straighten_rounded,
                  valor: _umaCasa(kmPorTreino),
                  unidade: 'km',
                  rotulo: 'por treino',
                  destacado: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TileNumero(
                  icone: Icons.event_repeat_rounded,
                  valor: _umaCasa(treinosPorSemana),
                  unidade: treinosPorSemana == 1 ? 'treino' : 'treinos',
                  rotulo: 'por semana',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TileNumero extends StatelessWidget {
  const _TileNumero({
    required this.icone,
    required this.valor,
    required this.unidade,
    required this.rotulo,
    this.destacado = false,
  });

  final IconData icone;
  final String valor;
  final String unidade;
  final String rotulo;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);

    // Destacado: card verde-limão, texto escuro.
    final fundo = destacado ? _destaque : p.card;
    final corValor = destacado ? _tinta : p.texto;
    final corRotulo = destacado ? const Color(0xFF3F4A16) : p.textoSecundario;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(24),
        border: destacado ? null : Border.all(color: p.borda),
        boxShadow: [
          BoxShadow(
            color: destacado
                ? _destaque.withValues(alpha: p.escuro ? 0.18 : 0.45)
                : p.sombra,
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: destacado ? _tinta : p.destaqueSuave,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icone,
                size: 20, color: destacado ? _destaque : p.corSobreSuave),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: valor,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: corValor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: ' $unidade',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: corRotulo,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: corRotulo,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ÁREA PROFISSIONAL
// =============================================================================

class _CardPainelTreinador extends StatefulWidget {
  const _CardPainelTreinador({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CardPainelTreinador> createState() => _CardPainelTreinadorState();
}

class _CardPainelTreinadorState extends State<_CardPainelTreinador> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressionado = true),
      onTapUp: (_) => setState(() => _pressionado = false),
      onTapCancel: () => setState(() => _pressionado = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressionado ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.superficie,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _destaque,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.monitor_heart_outlined,
                    color: _tinta, size: 23),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ÁREA PROFISSIONAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _destaque,
                          letterSpacing: 1,
                        )),
                    SizedBox(height: 4),
                    Text('Acessar painel do treinador',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ACOMPANHAMENTO
// =============================================================================

class _CardAcompanhamento extends StatelessWidget {
  const _CardAcompanhamento({
    required this.treinador,
    required this.mensagem,
    required this.onAbrirConversa,
  });

  final String treinador;
  final String? mensagem;
  final VoidCallback onAbrirConversa;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final primeiroNome = treinador.trim().split(RegExp(r'\s+')).first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.cardTreinador,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: p.superficie,
                    child: Text(
                      _iniciais(treinador),
                      style: const TextStyle(
                        color: _destaque,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _destaque,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.cardTreinador, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SEU TREINADOR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: p.verde,
                          letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 2),
                    Text(treinador,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.texto,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('$primeiroNome está com você',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: p.texto,
              )),
          if (mensagem != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(mensagem!,
                  style: TextStyle(fontSize: 14, height: 1.5, color: p.texto)),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAbrirConversa,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Abrir conversa',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: p.superficie,
              foregroundColor: _destaque,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CONQUISTAS
// =============================================================================

class _SecaoConquistas extends StatelessWidget {
  const _SecaoConquistas({required this.conquistas});

  final List<Conquista> conquistas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TituloSecao(
          sobre: 'CONQUISTAS',
          titulo: '${conquistas.length} '
              '${conquistas.length == 1 ? 'medalha' : 'medalhas'}',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: conquistas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _Medalha(conquista: conquistas[i]),
          ),
        ),
      ],
    );
  }
}

class _Medalha extends StatelessWidget {
  const _Medalha({required this.conquista});

  final Conquista conquista;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Container(
      width: 124,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.borda),
        boxShadow: [
          BoxShadow(
            color: p.sombra,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 54,
            height: 54,
            child: CustomPaint(
              painter: _HexagonoPainter(),
              child: Center(
                child:
                    Icon(Icons.emoji_events_rounded, color: _tinta, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            conquista.titulo,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: p.texto,
            ),
          ),
          if (conquista.descricao != null) ...[
            const SizedBox(height: 2),
            Text(
              conquista.descricao!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: p.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fundo hexagonal verde-limão das medalhas.
class _HexagonoPainter extends CustomPainter {
  const _HexagonoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final hexagono = Path();
    for (var i = 0; i < 6; i++) {
      final a = (math.pi / 3) * i - math.pi / 2;
      final ponto = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        hexagono.moveTo(ponto.dx, ponto.dy);
      } else {
        hexagono.lineTo(ponto.dx, ponto.dy);
      }
    }
    hexagono.close();
    canvas.drawPath(hexagono, Paint()..color = _destaque);
    canvas.drawPath(
      hexagono,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _tinta.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// COMUNS
// =============================================================================

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({required this.sobre, required this.titulo});

  final String sobre;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sobre,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.textoSecundario,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: 4),
        Text(titulo,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: p.texto,
            )),
      ],
    );
  }
}
