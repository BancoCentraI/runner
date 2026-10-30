import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/offline.dart';
import '../services/preferencia.dart';

// =============================================================================
// CORES (mesma paleta do app)
// =============================================================================

class _Cores {
  // Cores que são iguais nos dois temas
  static const tinta = Color(0xFF1A1A1A); // texto/ícone sobre verde-limão
  static const destaque = Color(0xFFD0FD38);
  static const textoClaro = Color(0xFF9CA3AF);
  static const vermelho = Color(0xFFEF4444);
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
  static Color get barra =>
      _modoEscuro ? const Color(0xFF2C302A) : const Color(0xFFE5E7E3);
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

String? _toStr(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

DateTime? _toData(Object? v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

const _meses = [
  'JAN',
  'FEV',
  'MAR',
  'ABR',
  'MAI',
  'JUN',
  'JUL',
  'AGO',
  'SET',
  'OUT',
  'NOV',
  'DEZ',
];
const _diasSemana = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

String _dataCurta(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_meses[d.month - 1]}';

/// "30/10 às 15:20"
String _dataHora(DateTime d) {
  final l = d.toLocal();
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(l.day)}/${dois(l.month)} às ${dois(l.hour)}:${dois(l.minute)}';
}

String _dataTreino(DateTime d) =>
    '${_diasSemana[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}';

String _tempo(int segundos) {
  final h = segundos ~/ 3600;
  final m = (segundos % 3600) ~/ 60;
  final s = segundos % 60;
  String dois(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${dois(m)}:${dois(s)}' : '${dois(m)}:${dois(s)}';
}

/// Converte e formata distâncias conforme a preferência (km ou milhas).
class _Unidade {
  const _Unidade(this.milhas);

  final bool milhas;

  static const _kmPorMilha = 1.609344;

  String get sigla => milhas ? 'mi' : 'km';

  double converter(double km) => milhas ? km / _kmPorMilha : km;

  /// 84.2 -> "84,2" | 28.0 -> "28"
  String numero(double km, {int casas = 1}) {
    final v = converter(km);
    final t = v == v.truncateToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(casas);
    return t.replaceAll('.', ',');
  }

  String distancia(double km) => '${numero(km)} $sigla';

  /// Pace em segundos por km -> "4:51 /km" (ou /mi)
  String pace(double segPorKm) {
    final s = (milhas ? segPorKm * _kmPorMilha : segPorKm).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')} /$sigla';
  }
}

// =============================================================================
// MODELOS
// =============================================================================

class TreinoFeito {
  const TreinoFeito({
    required this.titulo,
    required this.data,
    required this.distanciaKm,
    required this.duracaoSegundos,
    this.paceSegPorKm,
    this.pendente = false,
  });

  final String titulo;
  final DateTime? data;
  final double distanciaKm;
  final int duracaoSegundos;
  final double? paceSegPorKm;

  /// Corrida salva no aparelho que ainda não chegou na API.
  final bool pendente;

  /// Corpo de um POST /corridas que está na fila offline.
  static TreinoFeito? dePendente(Map<String, dynamic> c) {
    final data = _toData(c['iniciadoEm'] ?? c['finalizadoEm']);
    if (data == null) return null;
    return TreinoFeito(
      titulo: _toStr(c['titulo']) ?? 'Corrida',
      data: data,
      distanciaKm: _toDouble(c['distanciaKm']),
      duracaoSegundos: _toDouble(c['duracaoSegundos']).round(),
      paceSegPorKm: _toDoubleOuNulo(c['paceMedioSegPorKm']),
      pendente: true,
    );
  }

  /// Usa o pace da API; se não vier, calcula pela distância e tempo.
  double? get pace =>
      paceSegPorKm ??
      (distanciaKm > 0.05 ? duracaoSegundos / distanciaKm : null);

  factory TreinoFeito.fromJson(Map<String, dynamic> j) => TreinoFeito(
        titulo: _toStr(j['titulo']) ?? 'Corrida',
        data: _toData(j['data']),
        distanciaKm: _toDouble(j['distanciaKm']),
        duracaoSegundos: _toDouble(j['duracaoSegundos']).round(),
        paceSegPorKm: _toDoubleOuNulo(j['paceSegPorKm']),
      );
}

class SemanaVolume {
  const SemanaVolume({
    required this.inicio,
    required this.km,
    required this.treinos,
  });

  final DateTime inicio;
  final double km;
  final List<TreinoFeito> treinos;

  DateTime get fim => inicio.add(const Duration(days: 6));

  factory SemanaVolume.fromJson(Map<String, dynamic> j) {
    final treinos = j['treinos'] is List
        ? (j['treinos'] as List)
            .whereType<Map<String, dynamic>>()
            .map(TreinoFeito.fromJson)
            .toList()
        : <TreinoFeito>[];
    treinos.sort(
        (a, b) => (a.data ?? DateTime(0)).compareTo(b.data ?? DateTime(0)));

    // Se a API não mandar o total, soma os treinos.
    final km = _toDoubleOuNulo(j['km']) ??
        treinos.fold<double>(0, (s, t) => s + t.distanciaKm);

    return SemanaVolume(
      inicio: _toData(j['inicio']) ?? DateTime.now(),
      km: km,
      treinos: treinos,
    );
  }
}

class MelhorMarca {
  const MelhorMarca({
    required this.distancia,
    required this.tempoSegundos,
    this.paceSegPorKm,
    this.data,
  });

  /// Ex.: "5 km", "10 km", "Meia maratona"
  final String distancia;
  final int tempoSegundos;
  final double? paceSegPorKm;
  final DateTime? data;

  factory MelhorMarca.fromJson(Map<String, dynamic> j) => MelhorMarca(
        distancia: _toStr(j['distancia']) ?? '',
        tempoSegundos: _toDouble(j['tempoSegundos']).round(),
        paceSegPorKm: _toDoubleOuNulo(j['paceSegPorKm']),
        data: _toData(j['data']),
      );
}

class EvolucaoData {
  const EvolucaoData({
    this.kmUltimos30Dias = 0,
    this.variacaoPercentual,
    this.mesComparacao,
    this.semanas = const [],
    this.melhoresMarcas = const [],
  });

  final double kmUltimos30Dias;
  final double? variacaoPercentual;
  final String? mesComparacao;
  final List<SemanaVolume> semanas;
  final List<MelhorMarca> melhoresMarcas;

  bool get vazio =>
      kmUltimos30Dias == 0 && semanas.isEmpty && melhoresMarcas.isEmpty;

  /// As últimas [quantidade] semanas (segunda a domingo) sem nenhum treino.
  /// Usado para o gráfico aparecer mesmo sem API e sem dados salvos.
  static List<SemanaVolume> semanasZeradas([int quantidade = 7]) {
    final hoje = DateTime.now();
    final segunda = DateTime(hoje.year, hoje.month, hoje.day)
        .subtract(Duration(days: hoje.weekday - 1));
    return [
      for (var i = quantidade - 1; i >= 0; i--)
        SemanaVolume(
          inicio: segunda.subtract(Duration(days: 7 * i)),
          km: 0,
          treinos: const [],
        ),
    ];
  }

  factory EvolucaoData.fromJson(Map<String, dynamic> j) {
    List<T> lista<T>(String chave, T Function(Map<String, dynamic>) f) =>
        j[chave] is List
            ? (j[chave] as List)
                .whereType<Map<String, dynamic>>()
                .map(f)
                .toList()
            : <T>[];

    final semanas = lista('semanas', SemanaVolume.fromJson)
      ..sort((a, b) => a.inicio.compareTo(b.inicio));

    return EvolucaoData(
      kmUltimos30Dias: _toDouble(j['kmUltimos30Dias']),
      variacaoPercentual: _toDoubleOuNulo(j['variacaoPercentual']),
      mesComparacao: _toStr(j['mesComparacao']),
      semanas: semanas,
      melhoresMarcas: lista('melhoresMarcas', MelhorMarca.fromJson)
          .where((m) => m.distancia.isNotEmpty)
          .toList(),
    );
  }
}

// =============================================================================
// API
// =============================================================================

class _EvolucaoApi {
  static const cache = 'evolucao';

  /// GET /evolucao?semanas=7 — devolve o JSON (só quando veio da API agora)
  /// e, se falhar, a mensagem. O cache é salvo pelo ApiOffline.
  static Future<(Map<String, dynamic>?, String?)> buscar() async {
    final r = await ApiOffline.buscar('/evolucao',
        cache: cache, query: {'semanas': '7'});
    if (r.erro != null) return (null, r.erro);
    final corpo = r.mapa;
    return corpo != null
        ? (corpo, null)
        : (null, 'Resposta inválida do servidor.');
  }
}

/// Últimos dados da evolução salvos no aparelho (separados por usuário).
class _EvolucaoCache {
  static Future<(EvolucaoData, DateTime?)?> ler() async {
    final salvo = await CacheLocal.ler(_EvolucaoApi.cache);
    final dados = salvo?.dados;
    if (dados is! Map<String, dynamic>) return null;
    return (EvolucaoData.fromJson(dados), salvo!.salvoEm);
  }
}

/// Corridas da fila offline que ainda não chegaram na API.
List<TreinoFeito> _corridasPendentes() => ApiOffline.corridasPendentes()
    .map(TreinoFeito.dePendente)
    .whereType<TreinoFeito>()
    .toList();

// =============================================================================
// TELA
// =============================================================================

class EvolucaoScreen extends StatefulWidget {
  const EvolucaoScreen({super.key});

  @override
  State<EvolucaoScreen> createState() => _EvolucaoScreenState();
}

class _EvolucaoScreenState extends State<EvolucaoScreen> {
  bool _carregando = true;
  String? _erro;
  EvolucaoData _dados = const EvolucaoData();

  /// Quando os dados exibidos foram salvos no aparelho (null = vieram agora
  /// da API ou não há nada salvo).
  DateTime? _salvoEm;
  bool _temDadosSalvos = false;

  /// Semana tocada no gráfico.
  int? _selecionada;

  @override
  void initState() {
    super.initState();
    Preferencias.instancia.addListener(_atualizar);
    // A fila enviou algo: recarrega para a API já contar a corrida.
    Sincronizador.instancia.enviados.addListener(_carregar);
    _iniciar();
  }

  /// Mostra na hora o que está salvo no aparelho e depois busca na API.
  Future<void> _iniciar() async {
    final cache = await _EvolucaoCache.ler();
    if (!mounted) return;
    if (cache != null) {
      final (dados, salvoEm) = cache;
      setState(() {
        _dados = dados;
        _salvoEm = salvoEm;
        _temDadosSalvos = true;
        _selecionada = _semanaInicial(_semanasExibidas);
      });
    }
    await _carregar();
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
    final (corpo, erro) = await _EvolucaoApi.buscar();
    if (!mounted) return;

    setState(() {
      _carregando = false;
      _erro = erro;
      if (corpo != null) {
        _dados = EvolucaoData.fromJson(corpo);
        _salvoEm = null;
        _temDadosSalvos = false;
      }
      // Mantém a semana tocada se ela ainda existir.
      final total = _semanasExibidas.length;
      if (_selecionada == null || _selecionada! >= total || corpo != null) {
        _selecionada = _semanaInicial(_semanasExibidas);
      }
    });
  }

  /// Semanas do gráfico: as da API/cache ou, sem dados, as últimas 7 zeradas.
  /// Corridas ainda não enviadas entram na semana em que aconteceram.
  List<SemanaVolume> get _semanasExibidas {
    final base = _dados.semanas.isNotEmpty
        ? _dados.semanas
        : EvolucaoData.semanasZeradas();
    final pendentes = _corridasPendentes();
    if (pendentes.isEmpty) return base;

    return [
      for (final s in base)
        () {
          final daSemana = pendentes
              .where((t) =>
                  !t.data!.isBefore(s.inicio) &&
                  t.data!.isBefore(s.inicio.add(const Duration(days: 7))))
              .toList();
          if (daSemana.isEmpty) return s;
          final treinos = [...s.treinos, ...daSemana]..sort((a, b) =>
              (a.data ?? DateTime(0)).compareTo(b.data ?? DateTime(0)));
          return SemanaVolume(
            inicio: s.inicio,
            km: s.km + daSemana.fold<double>(0, (t, c) => t + c.distanciaKm),
            treinos: treinos,
          );
        }(),
    ];
  }

  /// Km das corridas não enviadas nos últimos 30 dias.
  double get _kmPendentes30Dias {
    final limite = DateTime.now().subtract(const Duration(days: 30));
    return _corridasPendentes()
        .where((t) => t.data!.isAfter(limite))
        .fold<double>(0, (s, t) => s + t.distanciaKm);
  }

  /// Começa destacando a semana com mais km (ou a atual, se tudo for zero).
  int? _semanaInicial(List<SemanaVolume> s) {
    if (s.isEmpty) return null;
    var maior = 0;
    for (var i = 1; i < s.length; i++) {
      if (s[i].km > s[maior].km) maior = i;
    }
    return s[maior].km > 0 ? maior : s.length - 1;
  }

  void _selecionar(int i) {
    if (i == _selecionada) return;
    HapticFeedback.selectionClick();
    setState(() => _selecionada = i);
  }

  @override
  Widget build(BuildContext context) {
    final unidade =
        _Unidade(Preferencias.instancia.unidade == UnidadeDistancia.milhas);

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
              Text(
                'SEU DESEMPENHO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _Cores.textoSecundario,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Evolução',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _Cores.escuro,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              ..._conteudo(unidade),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _conteudo(_Unidade unidade) {
    final dados = _dados;
    final semanas = _semanasExibidas;
    final sel = _selecionada;

    return [
      // ---------- Situação da conexão ----------
      if (_carregando)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 3,
              color: _Cores.escuro,
              backgroundColor: _Cores.barra,
            ),
          ),
        )
      else if (_erro != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _FaixaOffline(
            texto: _temDadosSalvos
                ? 'Sem conexão. Mostrando seus dados salvos'
                    '${_salvoEm != null ? ' em ${_dataHora(_salvoEm!)}' : ''}.'
                : 'Sem conexão. Seus dados aparecem quando a internet voltar.',
            onTentar: _carregar,
          ),
        ),

      // ---------- Resumo ----------
      Row(
        children: [
          Expanded(
            child: _CardResumo(
              escuro: true,
              icone: Icons.route_rounded,
              valor: unidade.numero(dados.kmUltimos30Dias + _kmPendentes30Dias),
              rotulo: '${unidade.sigla} nos últimos 30 dias',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: dados.variacaoPercentual == null
                ? _CardResumo(
                    escuro: false,
                    icone: Icons.calendar_month_outlined,
                    valor:
                        '${semanas.fold<int>(0, (s, w) => s + w.treinos.length)}',
                    rotulo: 'treinos nas últimas semanas',
                  )
                : _CardResumo(
                    escuro: false,
                    icone: dados.variacaoPercentual! >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    valor: '${dados.variacaoPercentual! >= 0 ? '+' : ''}'
                        '${dados.variacaoPercentual!.round()}%',
                    rotulo: dados.mesComparacao != null
                        ? 'volume em relação a ${dados.mesComparacao}'
                        : 'volume em relação ao mês anterior',
                  ),
          ),
        ],
      ),

      // ---------- Ainda sem corridas ----------
      if (dados.vazio &&
          !_carregando &&
          _erro == null &&
          ApiOffline.corridasPendentes().isEmpty) ...[
        const SizedBox(height: 16),
        const _Aviso(
          icone: Icons.directions_run_rounded,
          titulo: 'Sua evolução começa aqui',
          texto: 'Salve sua primeira corrida para ver o volume semanal, '
              'as tendências e suas melhores marcas.',
        ),
      ],

      // ---------- Gráfico ----------
      if (semanas.isNotEmpty) ...[
        const SizedBox(height: 16),
        _CardGrafico(
          semanas: semanas,
          selecionada: sel,
          unidade: unidade,
          onSelecionar: _selecionar,
        ),
      ],

      // ---------- Treinos da semana tocada ----------
      if (sel != null && sel < semanas.length) ...[
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(a),
              child: c,
            ),
          ),
          child: _TreinosDaSemana(
            key: ValueKey(sel),
            semana: semanas[sel],
            unidade: unidade,
          ),
        ),
      ],

      // ---------- Melhores marcas ----------
      if (dados.melhoresMarcas.isNotEmpty) ...[
        const SizedBox(height: 28),
        Text(
          'Melhores marcas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _Cores.escuro,
          ),
        ),
        const SizedBox(height: 12),
        for (final m in dados.melhoresMarcas) ...[
          _CardMarca(marca: m, unidade: unidade),
          const SizedBox(height: 10),
        ],
      ],
    ];
  }
}

// =============================================================================
// RESUMO
// =============================================================================

class _CardResumo extends StatelessWidget {
  const _CardResumo({
    required this.escuro,
    required this.icone,
    required this.valor,
    required this.rotulo,
  });

  final bool escuro;
  final IconData icone;
  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final corTexto = escuro ? Colors.white : _Cores.tinta;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c),
      ),
      child: Container(
        height: 136,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: escuro ? _Cores.superficie : _Cores.destaque,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone,
                size: 20, color: escuro ? _Cores.destaque : _Cores.tinta),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valor,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: corTexto,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rotulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: escuro ? _Cores.textoClaro : const Color(0xFF3F4A16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// GRÁFICO DE VOLUME SEMANAL (interativo)
// =============================================================================

class _CardGrafico extends StatelessWidget {
  const _CardGrafico({
    required this.semanas,
    required this.selecionada,
    required this.unidade,
    required this.onSelecionar,
  });

  final List<SemanaVolume> semanas;
  final int? selecionada;
  final _Unidade unidade;
  final ValueChanged<int> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final sel = selecionada;
    final maxKm = semanas.map((s) => s.km).fold<double>(0, math.max);

    // Diferença da semana selecionada para a anterior.
    double? diferenca;
    if (sel != null && sel > 0) {
      diferenca = semanas[sel].km - semanas[sel - 1].km;
      if (diferenca == 0 && semanas[sel].km == 0) diferenca = null;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume semanal',
                        style: TextStyle(
                            fontSize: 13, color: _Cores.textoSecundario)),
                    const SizedBox(height: 4),
                    Text(
                      'Últimas ${semanas.length} '
                      '${semanas.length == 1 ? 'semana' : 'semanas'}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _Cores.escuro,
                      ),
                    ),
                  ],
                ),
              ),
              if (diferenca != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _Selo(
                    key: ValueKey(sel),
                    texto: '${diferenca >= 0 ? '+' : '−'}'
                        '${unidade.distancia(diferenca.abs())}',
                    positivo: diferenca >= 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque numa barra para ver os treinos da semana',
            style: TextStyle(fontSize: 11.5, color: _Cores.textoClaro),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < semanas.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _Barra(
                      ordem: i,
                      fracao: maxKm > 0 ? semanas[i].km / maxKm : 0,
                      rotulo: unidade.numero(semanas[i].km),
                      selecionada: i == sel,
                      onTap: () => onSelecionar(i),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: _Cores.borda),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(_dataCurta(semanas.first.inicio),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _Cores.textoSecundario,
                    letterSpacing: 0.5,
                  )),
              const Spacer(),
              Text(_dataCurta(semanas.last.fim),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _Cores.textoSecundario,
                    letterSpacing: 0.5,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

/// Uma barra do gráfico: cresce ao abrir a tela e fica verde quando tocada.
class _Barra extends StatelessWidget {
  const _Barra({
    required this.ordem,
    required this.fracao,
    required this.rotulo,
    required this.selecionada,
    required this.onTap,
  });

  final int ordem;
  final double fracao;
  final String rotulo;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, c) {
          const espacoRotulo = 26.0;
          final alturaMax = c.maxHeight - espacoRotulo;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fracao),
            duration: Duration(milliseconds: 600 + ordem * 70),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) {
              // Altura mínima para semanas sem corrida continuarem tocáveis.
              final altura = math.max(alturaMax * v, 6.0);
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: espacoRotulo,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: selecionada ? 1 : 0,
                      child: Center(
                        child: FittedBox(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: _Cores.superficie,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rotulo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: altura,
                    decoration: BoxDecoration(
                      color: selecionada ? _Cores.destaque : _Cores.barra,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(10)),
                      boxShadow: selecionada
                          ? [
                              BoxShadow(
                                color: _Cores.destaque.withValues(alpha: 0.5),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo({super.key, required this.texto, required this.positivo});

  final String texto;
  final bool positivo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: positivo
            ? _Cores.destaqueClaro
            : (_modoEscuro ? const Color(0xFF2A1616) : const Color(0xFFFEF2F2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: positivo ? _Cores.escuro : _Cores.vermelho,
        ),
      ),
    );
  }
}

// =============================================================================
// TREINOS DA SEMANA SELECIONADA
// =============================================================================

class _TreinosDaSemana extends StatelessWidget {
  const _TreinosDaSemana({
    super.key,
    required this.semana,
    required this.unidade,
  });

  final SemanaVolume semana;
  final _Unidade unidade;

  @override
  Widget build(BuildContext context) {
    final treinos = semana.treinos;
    final tempoTotal = treinos.fold<int>(0, (s, t) => s + t.duracaoSegundos);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: _Cores.superficie,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEMANA ${_dataCurta(semana.inicio)} – '
                      '${_dataCurta(semana.fim)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _Cores.destaque,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      treinos.isEmpty
                          ? 'Nenhum treino'
                          : '${treinos.length} '
                              '${treinos.length == 1 ? 'treino' : 'treinos'}'
                              ' · ${unidade.distancia(semana.km)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (tempoTotal > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('tempo total',
                        style:
                            TextStyle(fontSize: 11, color: _Cores.textoClaro)),
                    const SizedBox(height: 2),
                    Text(_tempo(tempoTotal),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        )),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (treinos.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Semana de descanso. Tudo bem — recuperar também faz parte.',
                style: TextStyle(
                    fontSize: 13, height: 1.4, color: _Cores.textoClaro),
              ),
            )
          else
            for (var i = 0; i < treinos.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
              _LinhaTreino(treino: treinos[i], unidade: unidade),
            ],
        ],
      ),
    );
  }
}

class _LinhaTreino extends StatelessWidget {
  const _LinhaTreino({required this.treino, required this.unidade});

  final TreinoFeito treino;
  final _Unidade unidade;

  @override
  Widget build(BuildContext context) {
    final pace = treino.pace;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_run_rounded,
                color: _Cores.destaque, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  treino.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (treino.data != null) _dataTreino(treino.data!),
                    if (treino.duracaoSegundos > 0)
                      _tempo(treino.duracaoSegundos),
                  ].join(' · '),
                  style:
                      const TextStyle(fontSize: 12, color: _Cores.textoClaro),
                ),
                if (treino.pendente) ...[
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 13, color: _Cores.destaque),
                      SizedBox(width: 4),
                      Text(
                        'Aguardando internet para enviar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _Cores.destaque,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                unidade.distancia(treino.distanciaKm),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (pace != null) ...[
                const SizedBox(height: 2),
                Text(
                  unidade.pace(pace),
                  style:
                      const TextStyle(fontSize: 12, color: _Cores.textoClaro),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MELHORES MARCAS
// =============================================================================

class _CardMarca extends StatelessWidget {
  const _CardMarca({required this.marca, required this.unidade});

  final MelhorMarca marca;
  final _Unidade unidade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Cores.borda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marca.distancia,
                  style:
                      TextStyle(fontSize: 12.5, color: _Cores.textoSecundario),
                ),
                const SizedBox(height: 4),
                Text(
                  _tempo(marca.tempoSegundos),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (marca.data != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _dataCurta(marca.data!),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _Cores.verde,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              if (marca.paceSegPorKm != null)
                Text(
                  unidade.pace(marca.paceSegPorKm!),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _Cores.escuro,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FAIXA SEM CONEXÃO
// =============================================================================

class _FaixaOffline extends StatelessWidget {
  const _FaixaOffline({required this.texto, required this.onTentar});

  final String texto;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Cores.borda),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _Cores.superficie,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wifi_off_rounded,
                color: _Cores.destaque, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: _Cores.textoSecundario,
              ),
            ),
          ),
          TextButton(
            onPressed: onTentar,
            style: TextButton.styleFrom(foregroundColor: _Cores.escuro),
            child: const Text('Tentar',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// AVISO (vazio / erro)
// =============================================================================

class _Aviso extends StatelessWidget {
  const _Aviso({
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
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Cores.borda),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _Cores.superficie,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icone, color: _Cores.destaque, size: 28),
          ),
          const SizedBox(height: 16),
          Text(titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _Cores.escuro,
              )),
          const SizedBox(height: 6),
          Text(texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, height: 1.5, color: _Cores.textoSecundario)),
          if (acao != null) ...[
            const SizedBox(height: 18),
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
