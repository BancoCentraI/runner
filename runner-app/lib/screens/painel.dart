import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/offline.dart';
import 'corrida.dart';

// =============================================================================
// PAINEL — uma tela, duas visões
// =============================================================================
//
// A API decide o papel de quem está logado (pelo token do Firebase):
//   GET /painel  ->  { "papel": "aluno",     "aluno":     {...} }
//                ou  { "papel": "treinador", "treinador": {...} }
// O aluno só vê os próprios dados; o treinador só vê os alunos dele.
// Tudo funciona offline: leituras vêm do cache e envios entram na fila.

// =============================================================================
// CORES (mesma lógica do perfil: lidas do Theme, mudam sozinhas)
// =============================================================================

const _destaque = Color(0xFFD0FD38);
const _tinta = Color(0xFF1A1A1A);
const _vermelho = Color(0xFFEF4444);
const _laranja = Color(0xFFF59E0B);

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
  Color get superficie =>
      escuro ? const Color(0xFF262A23) : const Color(0xFF1A1A1A);
  Color get cinza => escuro ? const Color(0xFF252923) : const Color(0xFFF1F2EE);
  Color get verde => escuro ? const Color(0xFF9BC27A) : const Color(0xFF386641);
  Color get vermelhoSuave =>
      escuro ? const Color(0xFF3A1D1D) : const Color(0xFFFEF2F2);
  Color get laranjaSuave =>
      escuro ? const Color(0xFF3A2E12) : const Color(0xFFFEF3C7);
  Color get sombra => Colors.black.withValues(alpha: escuro ? 0.3 : 0.05);

  /// Topo da tela: grafite no escuro, verde-limão no claro (igual ao perfil).
  List<Color> get heroi => escuro
      ? const [Color(0xFF2B3122), Color(0xFF161A14)]
      : const [Color(0xFFE6FC86), Color(0xFFC6F12C)];
  Color get heroiTexto => escuro ? Colors.white : _tinta;
  Color get heroiTextoSec =>
      escuro ? const Color(0xFF9CA3AF) : const Color(0xFF4A5A12);
  Color get heroiLinha => escuro ? _destaque : _tinta;
  Color get vidro => escuro ? Colors.white : _tinta;

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

DateTime? _toData(Object? v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

List<Map<String, dynamic>> _lista(Object? v) => v is List
    ? v.whereType<Map<String, dynamic>>().toList()
    : const <Map<String, dynamic>>[];

DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _segunda(DateTime d) =>
    _soData(d).subtract(Duration(days: d.weekday - 1));

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 6.0 -> "6" | 6.25 -> "6,3"
String _km(double v) {
  final t = v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return t.replaceAll('.', ',');
}

/// 330 -> "5:30"
String _pace(double segPorKm) {
  final s = segPorKm.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// "5:30" -> 330 (null se inválido)
double? _lerPace(String texto) {
  final m = RegExp(r'^\s*(\d{1,2})[:.,](\d{1,2})\s*$').firstMatch(texto);
  if (m == null) return null;
  final seg = int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  return seg > 0 ? seg.toDouble() : null;
}

/// 2160 -> "36 min" | 4000 -> "1h 06"
String _duracao(int segundos) {
  final h = segundos ~/ 3600;
  final m = (segundos % 3600) ~/ 60;
  return h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}' : '$m min';
}

const _meses = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];
const _dias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

String _dataCurta(DateTime d) => '${d.day} ${_meses[d.month - 1]}';

String _dataLonga(DateTime d) {
  final hoje = _soData(DateTime.now());
  final dia = _soData(d);
  final diff = dia.difference(hoje).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  if (diff == -1) return 'Ontem';
  return '${_dias[d.weekday - 1]}, ${_dataCurta(d)}';
}

String _iniciais(String nome) {
  final p = nome.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (p.isEmpty) return '?';
  if (p.length == 1) return p.first[0].toUpperCase();
  return (p.first[0] + p.last[0]).toUpperCase();
}

String _dataIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// =============================================================================
// MODELOS
// =============================================================================

enum Papel { aluno, treinador }

enum StatusTreino { concluido, hoje, futuro, perdido }

class TreinoPlano {
  const TreinoPlano({
    required this.id,
    required this.data,
    required this.titulo,
    this.tipo,
    this.distanciaKm,
    this.ritmoAlvo,
    this.duracaoMin,
    this.instrucoes,
    this.concluido = false,
    this.realizadoKm,
    this.realizadoSeg,
    this.realizadoPace,
    this.alunoId,
    this.alunoNome,
    this.pendenteEnvio = false,
  });

  final String id;
  final DateTime data;
  final String titulo;
  final String? tipo;
  final double? distanciaKm;

  /// Ritmo desejado em segundos por km.
  final double? ritmoAlvo;
  final int? duracaoMin;
  final String? instrucoes;
  final bool concluido;
  final double? realizadoKm;
  final int? realizadoSeg;
  final double? realizadoPace;

  /// Preenchidos na visão do treinador.
  final String? alunoId;
  final String? alunoNome;

  /// Criado offline, ainda na fila.
  final bool pendenteEnvio;

  StatusTreino get status {
    if (concluido) return StatusTreino.concluido;
    final hoje = _soData(DateTime.now());
    final dia = _soData(data);
    if (dia == hoje) return StatusTreino.hoje;
    return dia.isBefore(hoje) ? StatusTreino.perdido : StatusTreino.futuro;
  }

  /// Ritmo realizado: o da API ou calculado.
  double? get paceReal =>
      realizadoPace ??
      ((realizadoKm ?? 0) > 0.05 && (realizadoSeg ?? 0) > 0
          ? realizadoSeg! / realizadoKm!
          : null);

  static TreinoPlano? fromJson(Map<String, dynamic> j, {bool pendente = false}) {
    final data = _toData(j['data']);
    final titulo = _toStr(j['titulo']);
    if (data == null || titulo == null) return null;
    final r = j['realizado'] is Map<String, dynamic>
        ? j['realizado'] as Map<String, dynamic>
        : null;
    final aluno = j['aluno'] is Map<String, dynamic>
        ? j['aluno'] as Map<String, dynamic>
        : null;
    return TreinoPlano(
      id: _toStr(j['id']) ?? 'local-${data.millisecondsSinceEpoch}-$titulo',
      data: data,
      titulo: titulo,
      tipo: _toStr(j['tipo']),
      distanciaKm: _toDoubleOuNulo(j['distanciaKm']),
      ritmoAlvo: _toDoubleOuNulo(j['ritmoAlvoSegPorKm']),
      duracaoMin: j['duracaoMin'] == null ? null : _toInt(j['duracaoMin']),
      instrucoes: _toStr(j['instrucoes']),
      concluido: j['concluido'] == true || r != null,
      realizadoKm: _toDoubleOuNulo(r?['distanciaKm']),
      realizadoSeg: r?['duracaoSegundos'] == null
          ? null
          : _toInt(r?['duracaoSegundos']),
      realizadoPace: _toDoubleOuNulo(r?['paceSegPorKm']),
      alunoId: _toStr(j['alunoId']) ?? _toStr(aluno?['id']),
      alunoNome: _toStr(j['alunoNome']) ?? _toStr(aluno?['nome']),
      pendenteEnvio: pendente,
    );
  }
}

class SemanaPlano {
  const SemanaPlano({
    required this.inicio,
    required this.planejadoKm,
    required this.realizadoKm,
  });

  final DateTime inicio;
  final double planejadoKm;
  final double realizadoKm;

  static SemanaPlano? fromJson(Map<String, dynamic> j) {
    final inicio = _toData(j['inicio']);
    if (inicio == null) return null;
    return SemanaPlano(
      inicio: inicio,
      planejadoKm: _toDouble(j['planejadoKm']),
      realizadoKm: _toDouble(j['realizadoKm']),
    );
  }
}

class FeedbackTreino {
  const FeedbackTreino({
    required this.id,
    required this.data,
    required this.texto,
    this.autor,
    this.treinoTitulo,
    this.alunoId,
    this.alunoNome,
    this.lido = true,
    this.pendenteEnvio = false,
  });

  final String id;
  final DateTime data;
  final String texto;
  final String? autor;
  final String? treinoTitulo;
  final String? alunoId;
  final String? alunoNome;
  final bool lido;
  final bool pendenteEnvio;

  FeedbackTreino lidoAgora() => FeedbackTreino(
        id: id,
        data: data,
        texto: texto,
        autor: autor,
        treinoTitulo: treinoTitulo,
        alunoId: alunoId,
        alunoNome: alunoNome,
        lido: true,
        pendenteEnvio: pendenteEnvio,
      );

  static FeedbackTreino? fromJson(Map<String, dynamic> j, {bool pendente = false}) {
    final texto = _toStr(j['texto']);
    if (texto == null) return null;
    final data = _toData(j['data']) ?? DateTime.now();
    return FeedbackTreino(
      id: _toStr(j['id']) ?? 'local-${data.millisecondsSinceEpoch}',
      data: data,
      texto: texto,
      autor: _toStr(j['autor']),
      treinoTitulo: _toStr(j['treinoTitulo']),
      alunoId: _toStr(j['alunoId']),
      alunoNome: _toStr(j['alunoNome']),
      lido: pendente || j['lido'] != false,
      pendenteEnvio: pendente,
    );
  }
}

class PerfilAlunoInfo {
  const PerfilAlunoInfo({
    this.nome,
    this.email,
    this.telefone,
    this.objetivo,
    this.nivel,
    this.treinador,
  });

  final String? nome;
  final String? email;
  final String? telefone;
  final String? objetivo;
  final String? nivel;
  final String? treinador;

  factory PerfilAlunoInfo.fromJson(Map<String, dynamic>? j) => PerfilAlunoInfo(
        nome: _toStr(j?['nome']),
        email: _toStr(j?['email']),
        telefone: _toStr(j?['telefone']),
        objetivo: _toStr(j?['objetivo']),
        nivel: _toStr(j?['nivel']),
        treinador: _toStr(j?['treinador']),
      );

  PerfilAlunoInfo com(Map<String, dynamic> e) => PerfilAlunoInfo(
        nome: _toStr(e['nome']) ?? nome,
        email: email,
        telefone: e.containsKey('telefone') ? _toStr(e['telefone']) : telefone,
        objetivo: e.containsKey('objetivo') ? _toStr(e['objetivo']) : objetivo,
        nivel: nivel,
        treinador: treinador,
      );
}

class DadosAluno {
  const DadosAluno({
    this.metaKmSemana = 0,
    this.treinos = const [],
    this.semanas = const [],
    this.feedbacks = const [],
    this.perfil = const PerfilAlunoInfo(),
  });

  final double metaKmSemana;
  final List<TreinoPlano> treinos;
  final List<SemanaPlano> semanas;
  final List<FeedbackTreino> feedbacks;
  final PerfilAlunoInfo perfil;

  factory DadosAluno.fromJson(Map<String, dynamic> j) {
    final perfil = j['perfil'] is Map<String, dynamic>
        ? j['perfil'] as Map<String, dynamic>
        : null;
    return DadosAluno(
      metaKmSemana: _toDouble(j['metaKmSemana']),
      treinos: _lista(j['treinos'])
          .map((e) => TreinoPlano.fromJson(e))
          .whereType<TreinoPlano>()
          .toList()
        ..sort((a, b) => a.data.compareTo(b.data)),
      semanas: _lista(j['semanas'])
          .map(SemanaPlano.fromJson)
          .whereType<SemanaPlano>()
          .toList()
        ..sort((a, b) => a.inicio.compareTo(b.inicio)),
      feedbacks: _lista(j['feedbacks'])
          .map((e) => FeedbackTreino.fromJson(e))
          .whereType<FeedbackTreino>()
          .toList()
        ..sort((a, b) => b.data.compareTo(a.data)),
      perfil: PerfilAlunoInfo.fromJson(perfil),
    );
  }
}

class AlunoResumo {
  const AlunoResumo({
    required this.id,
    required this.nome,
    this.nivel,
    this.frequencia = 0,
    this.kmSemana = 0,
    this.ultimoTreino,
  });

  final String id;
  final String nome;
  final String? nivel;

  /// 0..1 — treinos feitos / planejados nas últimas semanas.
  final double frequencia;
  final double kmSemana;
  final DateTime? ultimoTreino;

  static AlunoResumo? fromJson(Map<String, dynamic> j) {
    final id = _toStr(j['id']);
    final nome = _toStr(j['nome']);
    if (id == null || nome == null) return null;
    return AlunoResumo(
      id: id,
      nome: nome,
      nivel: _toStr(j['nivel']),
      frequencia: _toDouble(j['frequencia']).clamp(0.0, 1.0),
      kmSemana: _toDouble(j['kmSemana']),
      ultimoTreino: _toData(j['ultimoTreino']),
    );
  }
}

class AvisoTreinador {
  const AvisoTreinador({
    required this.id,
    required this.tipo,
    required this.texto,
    required this.data,
    this.alunoNome,
  });

  final String id;

  /// "concluido", "perdido", "feedback", "sistema"...
  final String tipo;
  final String texto;
  final DateTime data;
  final String? alunoNome;

  static AvisoTreinador? fromJson(Map<String, dynamic> j) {
    final texto = _toStr(j['texto']);
    if (texto == null) return null;
    final data = _toData(j['data']) ?? DateTime.now();
    return AvisoTreinador(
      id: _toStr(j['id']) ?? '${data.millisecondsSinceEpoch}',
      tipo: _toStr(j['tipo']) ?? 'sistema',
      texto: texto,
      data: data,
      alunoNome: _toStr(j['alunoNome']),
    );
  }
}

class DadosTreinador {
  const DadosTreinador({
    this.alunos = const [],
    this.agenda = const [],
    this.desempenho = const [],
    this.feedbacks = const [],
    this.avisos = const [],
  });

  final List<AlunoResumo> alunos;
  final List<TreinoPlano> agenda;
  final List<SemanaPlano> desempenho;
  final List<FeedbackTreino> feedbacks;
  final List<AvisoTreinador> avisos;

  factory DadosTreinador.fromJson(Map<String, dynamic> j) => DadosTreinador(
        alunos: _lista(j['alunos'])
            .map(AlunoResumo.fromJson)
            .whereType<AlunoResumo>()
            .toList()
          ..sort((a, b) => a.nome.compareTo(b.nome)),
        agenda: _lista(j['agenda'])
            .map((e) => TreinoPlano.fromJson(e))
            .whereType<TreinoPlano>()
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data)),
        desempenho: _lista(j['desempenho'])
            .map(SemanaPlano.fromJson)
            .whereType<SemanaPlano>()
            .toList()
          ..sort((a, b) => a.inicio.compareTo(b.inicio)),
        feedbacks: _lista(j['feedbacks'])
            .map((e) => FeedbackTreino.fromJson(e))
            .whereType<FeedbackTreino>()
            .toList()
          ..sort((a, b) => b.data.compareTo(a.data)),
        avisos: _lista(j['notificacoes'])
            .map(AvisoTreinador.fromJson)
            .whereType<AvisoTreinador>()
            .toList()
          ..sort((a, b) => b.data.compareTo(a.data)),
      );
}

// =============================================================================
// API (com cache e fila offline)
// =============================================================================

class _PainelApi {
  static const _cache = 'painel';

  /// GET /painel. Sem internet: cache. Sem cache: usa o "ehTreinador" do
  /// perfil salvo para saber qual visão mostrar (vazia).
  static Future<
      ({
        Papel papel,
        DadosAluno? aluno,
        DadosTreinador? treinador,
        String? erro,
        DateTime? salvoEm,
      })> buscar() async {
    final r = await ApiOffline.buscar('/painel', cache: _cache);
    final j = r.mapa;

    if (j == null) {
      final perfil = await CacheLocal.ler('perfil');
      final eh = perfil?.dados is Map && (perfil!.dados as Map)['ehTreinador'] == true;
      return (
        papel: eh ? Papel.treinador : Papel.aluno,
        aluno: eh ? null : _mesclarAluno(const DadosAluno()),
        treinador: eh ? _mesclarTreinador(const DadosTreinador()) : null,
        erro: r.erro ?? 'Resposta inválida do servidor.',
        salvoEm: null,
      );
    }

    final treinador = _toStr(j['papel'])?.toLowerCase() == 'treinador';
    Map<String, dynamic> bloco(String k) =>
        j[k] is Map<String, dynamic> ? j[k] as Map<String, dynamic> : const {};

    return (
      papel: treinador ? Papel.treinador : Papel.aluno,
      aluno: treinador ? null : _mesclarAluno(DadosAluno.fromJson(bloco('aluno'))),
      treinador: treinador
          ? _mesclarTreinador(DadosTreinador.fromJson(bloco('treinador')))
          : null,
      erro: r.erro,
      salvoEm: r.salvoEm,
    );
  }

  /// Aplica o que o aluno fez offline: perfil editado, feedbacks lidos.
  static DadosAluno _mesclarAluno(DadosAluno d) {
    final edicoes = FilaOffline.instancia.corpos(metodo: 'PUT', caminho: '/perfil');
    final lidos = FilaOffline.instancia
        .caminhos('PATCH')
        .map((c) => RegExp(r'^/painel/feedbacks/(.+)/lido$').firstMatch(c)?.group(1))
        .whereType<String>()
        .toSet();
    if (edicoes.isEmpty && lidos.isEmpty) return d;
    return DadosAluno(
      metaKmSemana: d.metaKmSemana,
      treinos: d.treinos,
      semanas: d.semanas,
      feedbacks: [
        for (final f in d.feedbacks) lidos.contains(f.id) ? f.lidoAgora() : f,
      ],
      perfil: edicoes.isEmpty ? d.perfil : d.perfil.com(edicoes.last),
    );
  }

  /// Aplica o que o treinador fez offline: treinos criados e feedbacks.
  static DadosTreinador _mesclarTreinador(DadosTreinador d) {
    final nomes = {for (final a in d.alunos) a.id: a.nome};
    final novosTreinos = FilaOffline.instancia
        .corpos(metodo: 'POST', caminho: '/painel/treinos')
        .map((c) => TreinoPlano.fromJson(
            {...c, 'alunoNome': c['alunoNome'] ?? nomes[c['alunoId']]},
            pendente: true))
        .whereType<TreinoPlano>();
    final novosFeedbacks = FilaOffline.instancia
        .corpos(metodo: 'POST', caminho: '/painel/feedbacks')
        .map((c) => FeedbackTreino.fromJson(
            {...c, 'alunoNome': c['alunoNome'] ?? nomes[c['alunoId']]},
            pendente: true))
        .whereType<FeedbackTreino>();
    if (novosTreinos.isEmpty && novosFeedbacks.isEmpty) return d;
    return DadosTreinador(
      alunos: d.alunos,
      agenda: [...d.agenda, ...novosTreinos]
        ..sort((a, b) => a.data.compareTo(b.data)),
      desempenho: d.desempenho,
      feedbacks: [...novosFeedbacks, ...d.feedbacks]
        ..sort((a, b) => b.data.compareTo(a.data)),
      avisos: d.avisos,
    );
  }

  /// GET /painel/alunos/{id} — perfil completo de um aluno (treinador).
  static Future<({Map<String, dynamic>? dados, String? erro})> aluno(
      String id) async {
    final r = await ApiOffline.buscar('/painel/alunos/$id', cache: 'painel_aluno_$id');
    return (dados: r.mapa, erro: r.erro);
  }

  static Future<ResultadoEnvio> criarTreino(Map<String, dynamic> corpo) =>
      ApiOffline.enviar('POST', '/painel/treinos', corpo: corpo);

  static Future<ResultadoEnvio> enviarFeedback(Map<String, dynamic> corpo) =>
      ApiOffline.enviar('POST', '/painel/feedbacks', corpo: corpo);

  static Future<ResultadoEnvio> marcarLido(String id) => ApiOffline.enviar(
      'PATCH', '/painel/feedbacks/$id/lido',
      substitui: 'painel-feedback-lido-$id');

  static Future<ResultadoEnvio> salvarPerfil(Map<String, dynamic> corpo) =>
      ApiOffline.enviar('PUT', '/perfil', corpo: corpo, substitui: 'perfil-edicao');
}

// =============================================================================
// TELA
// =============================================================================

class PainelScreen extends StatefulWidget {
  const PainelScreen({super.key});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  bool _carregando = true;
  Papel _papel = Papel.aluno;
  DadosAluno _aluno = const DadosAluno();
  DadosTreinador _treinador = const DadosTreinador();
  String? _erro;
  DateTime? _salvoEm;
  int _aba = 0;

  static const _abasAluno = [
    (Icons.home_rounded, 'Início'),
    (Icons.calendar_month_rounded, 'Treinos'),
    (Icons.trending_up_rounded, 'Evolução'),
    (Icons.chat_bubble_outline_rounded, 'Feedbacks'),
    (Icons.person_outline_rounded, 'Perfil'),
  ];

  static const _abasTreinador = [
    (Icons.space_dashboard_rounded, 'Dashboard'),
    (Icons.groups_rounded, 'Alunos'),
    (Icons.event_note_rounded, 'Agenda'),
    (Icons.insights_rounded, 'Desempenho'),
    (Icons.forum_outlined, 'Feedbacks'),
    (Icons.notifications_none_rounded, 'Avisos'),
  ];

  @override
  void initState() {
    super.initState();
    Sincronizador.instancia.enviados.addListener(_carregar);
    FilaOffline.instancia.pendentes.addListener(_recompor);
    _carregar();
  }

  @override
  void dispose() {
    Sincronizador.instancia.enviados.removeListener(_carregar);
    FilaOffline.instancia.pendentes.removeListener(_recompor);
    super.dispose();
  }

  void _recompor() {
    if (mounted) setState(() {});
  }

  Future<void> _carregar() async {
    final r = await _PainelApi.buscar();
    if (!mounted) return;
    setState(() {
      if (r.papel != _papel) _aba = 0;
      _papel = r.papel;
      _aluno = r.aluno ?? const DadosAluno();
      _treinador = r.treinador ?? const DadosTreinador();
      _erro = r.erro;
      _salvoEm = r.salvoEm;
      _carregando = false;
    });
  }

  void _irPara(int aba) {
    if (aba == _aba) return;
    HapticFeedback.selectionClick();
    setState(() => _aba = aba);
  }

  void _aviso(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor: erro ? _vermelho : const Color(0xFF262A23),
      ));
  }

  void _avisoEnvio(ResultadoEnvio r, String oQue) {
    switch (r) {
      case ResultadoEnvio.enviado:
        _aviso('$oQue enviado.');
      case ResultadoEnvio.naFila:
        _aviso('$oQue salvo no celular. Será enviado quando houver internet.');
      case ResultadoEnvio.recusado:
        _aviso('O servidor recusou. Confira os dados e tente de novo.',
            erro: true);
    }
  }

  // ---------------- Ações compartilhadas ----------------

  Future<void> _abrirDetalhe(TreinoPlano t) async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FolhaDetalhe(treino: t, papel: _papel),
    );
    if (!mounted || acao == null) return;
    if (acao == 'executar') await _executar(t);
    if (acao == 'feedback') {
      await _escreverFeedback(alunoId: t.alunoId, treino: t);
    }
  }

  Future<void> _executar(TreinoPlano t) async {
    HapticFeedback.mediumImpact();
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CorridaScreen(
          titulo: t.titulo,
          subtitulo: 'TREINO DO PLANO',
          metaKm: t.distanciaKm,
        ),
      ),
    );
    if (salvou == true && mounted) _carregar();
  }

  Future<void> _criarTreino({String? alunoId, DateTime? data}) async {
    if (_treinador.alunos.isEmpty) {
      _aviso('Você ainda não tem alunos para programar treinos.', erro: true);
      return;
    }
    final corpo = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FolhaCriarTreino(
        alunos: _treinador.alunos,
        alunoInicial: alunoId,
        dataInicial: data,
      ),
    );
    if (corpo == null || !mounted) return;
    final r = await _PainelApi.criarTreino(corpo);
    if (!mounted) return;
    _avisoEnvio(r, 'Treino');
    _carregar(); // recarrega da API ou do cache + itens da fila
  }

  Future<void> _escreverFeedback({String? alunoId, TreinoPlano? treino}) async {
    if (_treinador.alunos.isEmpty) {
      _aviso('Você ainda não tem alunos.', erro: true);
      return;
    }
    final corpo = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FolhaFeedback(
        alunos: _treinador.alunos,
        alunoInicial: alunoId,
        treino: treino,
      ),
    );
    if (corpo == null || !mounted) return;
    final r = await _PainelApi.enviarFeedback(corpo);
    if (!mounted) return;
    _avisoEnvio(r, 'Feedback');
    _carregar();
  }

  Future<void> _abrirAluno(AlunoResumo a) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PerfilAlunoTela(
          resumo: a,
          onCriarTreino: () => _criarTreino(alunoId: a.id),
          onFeedback: () => _escreverFeedback(alunoId: a.id),
          onDetalhe: _abrirDetalhe,
        ),
      ),
    );
  }

  Future<void> _lerFeedback(FeedbackTreino f) async {
    if (f.lido) return;
    setState(() {
      _aluno = DadosAluno(
        metaKmSemana: _aluno.metaKmSemana,
        treinos: _aluno.treinos,
        semanas: _aluno.semanas,
        feedbacks: [for (final x in _aluno.feedbacks) x.id == f.id ? x.lidoAgora() : x],
        perfil: _aluno.perfil,
      );
    });
    await _PainelApi.marcarLido(f.id);
  }

  Future<void> _editarPerfil() async {
    final corpo = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FolhaEditarPerfil(
        perfil: _aluno.perfil,
        nomeFirebase: FirebaseAuth.instance.currentUser?.displayName,
      ),
    );
    if (corpo == null || !mounted) return;
    setState(() {
      _aluno = DadosAluno(
        metaKmSemana: _aluno.metaKmSemana,
        treinos: _aluno.treinos,
        semanas: _aluno.semanas,
        feedbacks: _aluno.feedbacks,
        perfil: _aluno.perfil.com(corpo),
      );
    });
    final nome = _toStr(corpo['nome']);
    if (nome != null) {
      try {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(nome);
      } catch (_) {}
    }
    final r = await _PainelApi.salvarPerfil(corpo);
    if (mounted) _avisoEnvio(r, 'Perfil');
  }

  // ---------------- Interface ----------------

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final abas = _papel == Papel.treinador ? _abasTreinador : _abasAluno;
    final aba = math.min(_aba, abas.length - 1);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.barraStatus,
      child: Scaffold(
        backgroundColor: p.fundo,
        floatingActionButton: _papel == Papel.treinador && !_carregando
            ? FloatingActionButton.extended(
                onPressed: () => _criarTreino(),
                backgroundColor: _destaque,
                foregroundColor: _tinta,
                elevation: 2,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Criar treino',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              )
            : null,
        body: Column(
          children: [
            _Topo(
              papel: _papel,
              titulo: abas[aba].$2,
              nome: _papel == Papel.aluno
                  ? (_aluno.perfil.nome ??
                      FirebaseAuth.instance.currentUser?.displayName)
                  : FirebaseAuth.instance.currentUser?.displayName,
              abas: abas,
              abaAtual: aba,
              naoLidos: _papel == Papel.aluno
                  ? _aluno.feedbacks.where((f) => !f.lido).length
                  : 0,
              onAba: _irPara,
            ),
            if (_erro != null && !_carregando)
              _FaixaOffline(
                texto: _salvoEm != null
                    ? 'Sem conexão. Mostrando dados salvos em ${formatarSalvoEm(_salvoEm!)}.'
                    : 'Sem conexão. Os dados aparecem quando a internet voltar.',
                pendentes: FilaOffline.instancia.pendentes.value,
                onTentar: () async {
                  await Sincronizador.instancia.sincronizar(imediato: true);
                  await _carregar();
                },
              ),
            Expanded(
              child: _carregando
                  ? const _Carregando()
                  : RefreshIndicator(
                      color: p.texto,
                      backgroundColor: p.card,
                      onRefresh: _carregar,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (c, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                                    begin: const Offset(0, 0.03),
                                    end: Offset.zero)
                                .animate(a),
                            child: c,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey('${_papel.name}-$aba'),
                          child: _papel == Papel.treinador
                              ? _conteudoTreinador(aba)
                              : _conteudoAluno(aba),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudoAluno(int aba) {
    switch (aba) {
      case 0:
        return _AlunoInicio(
          dados: _aluno,
          onDetalhe: _abrirDetalhe,
          onExecutar: _executar,
          onVerFeedbacks: () => _irPara(3),
          onVerTreinos: () => _irPara(1),
        );
      case 1:
        return _AlunoTreinos(dados: _aluno, onDetalhe: _abrirDetalhe);
      case 2:
        return _AlunoEvolucao(dados: _aluno, onDetalhe: _abrirDetalhe);
      case 3:
        return _ListaFeedbacks(
          feedbacks: _aluno.feedbacks,
          visaoTreinador: false,
          onTocar: _lerFeedback,
        );
      default:
        return _AlunoPerfil(dados: _aluno, onEditar: _editarPerfil);
    }
  }

  Widget _conteudoTreinador(int aba) {
    switch (aba) {
      case 0:
        return _TreinadorDashboard(
          dados: _treinador,
          onDetalhe: _abrirDetalhe,
          onAluno: _abrirAluno,
          onVerAgenda: () => _irPara(2),
          onVerAvisos: () => _irPara(5),
        );
      case 1:
        return _TreinadorAlunos(dados: _treinador, onAluno: _abrirAluno);
      case 2:
        return _TreinadorAgenda(
          dados: _treinador,
          onDetalhe: _abrirDetalhe,
          onCriar: (dia) => _criarTreino(data: dia),
        );
      case 3:
        return _TreinadorDesempenho(dados: _treinador, onAluno: _abrirAluno);
      case 4:
        return _ListaFeedbacks(
          feedbacks: _treinador.feedbacks,
          visaoTreinador: true,
          onNovo: () => _escreverFeedback(),
        );
      default:
        return _TreinadorAvisos(avisos: _treinador.avisos);
    }
  }
}

// =============================================================================
// TOPO + ABAS
// =============================================================================

class _Topo extends StatelessWidget {
  const _Topo({
    required this.papel,
    required this.titulo,
    required this.nome,
    required this.abas,
    required this.abaAtual,
    required this.naoLidos,
    required this.onAba,
  });

  final Papel papel;
  final String titulo;
  final String? nome;
  final List<(IconData, String)> abas;
  final int abaAtual;
  final int naoLidos;
  final ValueChanged<int> onAba;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final topo = MediaQuery.of(context).padding.top;
    final primeiro = (nome ?? '').trim().split(RegExp(r'\s+')).first;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.heroi,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _AneisPainter(cor: p.heroiLinha)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, topo + 8, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _BotaoVidro(
                        icone: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              papel == Papel.treinador
                                  ? 'ÁREA DO TREINADOR'
                                  : 'ÁREA DO ALUNO',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: p.heroiLinha,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                titulo,
                                key: ValueKey(titulo),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: p.heroiTexto,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (primeiro.isNotEmpty)
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.escuro ? const Color(0xFF23271E) : _tinta,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: p.heroiLinha.withValues(alpha: 0.5),
                                width: 2),
                          ),
                          child: Text(
                            _iniciais(nome!),
                            style: const TextStyle(
                              color: _destaque,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: abas.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _ChipAba(
                        icone: abas[i].$1,
                        rotulo: abas[i].$2,
                        ativo: i == abaAtual,
                        selo: abas[i].$2 == 'Feedbacks' ? naoLidos : 0,
                        onTap: () => onAba(i),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipAba extends StatelessWidget {
  const _ChipAba({
    required this.icone,
    required this.rotulo,
    required this.ativo,
    required this.selo,
    required this.onTap,
  });

  final IconData icone;
  final String rotulo;
  final bool ativo;
  final int selo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    // Ativo: grafite com texto verde-limão (contrasta nos dois temas).
    final fundo = ativo
        ? (p.escuro ? _destaque : _tinta)
        : p.vidro.withValues(alpha: 0.08);
    final cor = ativo ? (p.escuro ? _tinta : _destaque) : p.heroiTexto;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(20),
          border: ativo
              ? null
              : Border.all(color: p.vidro.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 17, color: cor),
            const SizedBox(width: 6),
            Text(rotulo,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: cor)),
            if (selo > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _vermelho,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$selo',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      ),
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
          side: BorderSide(color: p.vidro.withValues(alpha: 0.14))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icone, color: p.heroiTexto, size: 18),
        ),
      ),
    );
  }
}

class _AneisPainter extends CustomPainter {
  const _AneisPainter({required this.cor});

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width * 0.92, size.height * 0.1);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        centro,
        50.0 + i * 30,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = cor.withValues(alpha: 0.12 - i * 0.017),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AneisPainter old) => old.cor != cor;
}

class _FaixaOffline extends StatelessWidget {
  const _FaixaOffline({
    required this.texto,
    required this.pendentes,
    required this.onTentar,
  });

  final String texto;
  final int pendentes;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borda),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: p.textoSecundario),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pendentes > 0
                  ? '$texto $pendentes ${pendentes == 1 ? 'envio aguarda' : 'envios aguardam'} internet.'
                  : texto,
              style: TextStyle(
                  fontSize: 12, height: 1.35, color: p.textoSecundario),
            ),
          ),
          TextButton(
            onPressed: onTentar,
            style: TextButton.styleFrom(foregroundColor: p.texto),
            child: const Text('Tentar',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _Carregando extends StatelessWidget {
  const _Carregando();

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Center(child: CircularProgressIndicator(color: p.texto));
  }
}

// =============================================================================
// PEÇAS COMUNS
// =============================================================================

/// Lista rolável padrão das abas (com espaço para o botão flutuante).
class _Rolagem extends StatelessWidget {
  const _Rolagem({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: children,
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto, {this.acao, this.onAcao});

  final String texto;
  final String? acao;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(texto,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: p.texto)),
          ),
          if (acao != null)
            GestureDetector(
              onTap: onAcao,
              child: Text(acao!,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.verde)),
            ),
        ],
      ),
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({required this.child, this.onTap, this.padding, this.cor});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Material(
      color: cor ?? p.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: cor == null ? Border.all(color: p.borda) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Quadradinho de número (usado em vários resumos).
class _Numero extends StatelessWidget {
  const _Numero({
    required this.icone,
    required this.valor,
    required this.rotulo,
    this.destacado = false,
  });

  final IconData icone;
  final String valor;
  final String rotulo;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: destacado ? _destaque : p.card,
        borderRadius: BorderRadius.circular(20),
        border: destacado ? null : Border.all(color: p.borda),
        boxShadow: destacado
            ? [
                BoxShadow(
                  color: _destaque.withValues(alpha: p.escuro ? 0.15 : 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: destacado ? _tinta : p.corSobreSuave),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: destacado ? _tinta : p.texto,
                  letterSpacing: -0.5,
                )),
          ),
          Text(rotulo,
              maxLines: 2,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: destacado ? const Color(0xFF3F4A16) : p.textoSecundario,
              )),
        ],
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({required this.icone, required this.titulo, required this.texto});

  final IconData icone;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.borda),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: p.superficie,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icone, color: _destaque, size: 24),
          ),
          const SizedBox(height: 12),
          Text(titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: p.texto)),
          const SizedBox(height: 4),
          Text(texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, height: 1.45, color: p.textoSecundario)),
        ],
      ),
    );
  }
}

class _SeloStatus extends StatelessWidget {
  const _SeloStatus({required this.treino});

  final TreinoPlano treino;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final (texto, fundo, cor) = treino.pendenteEnvio
        ? ('AGUARDANDO ENVIO', p.cinza, p.textoSecundario)
        : switch (treino.status) {
            StatusTreino.concluido => ('FEITO', _destaque, _tinta),
            StatusTreino.hoje => ('HOJE', p.superficie, _destaque),
            StatusTreino.futuro => ('PROGRAMADO', p.cinza, p.textoSecundario),
            StatusTreino.perdido => (
                'NÃO FEITO',
                p.vermelhoSuave,
                _vermelho,
              ),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(texto,
          style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: cor,
              letterSpacing: 0.6)),
    );
  }
}

/// Linha de treino usada em listas (aluno e treinador).
class _LinhaTreino extends StatelessWidget {
  const _LinhaTreino({
    required this.treino,
    required this.onTap,
    this.mostrarAluno = false,
  });

  final TreinoPlano treino;
  final VoidCallback onTap;
  final bool mostrarAluno;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final t = treino;
    final detalhes = [
      if (t.distanciaKm != null) '${_km(t.distanciaKm!)} km',
      if (t.ritmoAlvo != null) '${_pace(t.ritmoAlvo!)} /km',
      if (t.duracaoMin != null) '${t.duracaoMin} min',
    ].join(' · ');
    final hoje = t.status == StatusTreino.hoje && !t.pendenteEnvio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Cartao(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: hoje ? _destaque : p.cinza,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(_dias[t.data.weekday - 1].toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: hoje ? _tinta : p.textoSecundario)),
                  Text('${t.data.day}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: hoje ? _tinta : p.texto)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SeloStatus(treino: t),
                      if (t.tipo != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(t.tipo!.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: p.verde,
                                  letterSpacing: 0.6)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(t.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: p.texto)),
                  if (mostrarAluno && t.alunoNome != null)
                    Text(t.alunoNome!,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: p.verde)),
                  if (detalhes.isNotEmpty)
                    Text(detalhes,
                        style: TextStyle(
                            fontSize: 12.5, color: p.textoSecundario)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textoSecundario),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras: planejado (contorno) x realizado (verde-limão).
class _GraficoSemanas extends StatefulWidget {
  const _GraficoSemanas({required this.semanas});

  final List<SemanaPlano> semanas;

  @override
  State<_GraficoSemanas> createState() => _GraficoSemanasState();
}

class _GraficoSemanasState extends State<_GraficoSemanas> {
  int? _sel;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final s = widget.semanas;
    final maximo = s.fold<double>(
        1, (m, w) => math.max(m, math.max(w.planejadoKm, w.realizadoKm)));
    final sel = math.max(0, math.min(_sel ?? s.length - 1, s.length - 1));
    final w = s[sel];
    final pct = w.planejadoKm > 0 ? (w.realizadoKm / w.planejadoKm * 100).round() : null;

    return _Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Semana de ${_dataCurta(w.inicio)}',
                        style: TextStyle(fontSize: 12.5, color: p.textoSecundario)),
                    const SizedBox(height: 2),
                    Text('${_km(w.realizadoKm)} de ${_km(w.planejadoKm)} km',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: p.texto)),
                  ],
                ),
              ),
              if (pct != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: pct >= 90 ? p.destaqueSuave : p.laranjaSuave,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$pct%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: pct >= 90 ? p.corSobreSuave : _laranja)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < s.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _sel = i);
                      },
                      child: LayoutBuilder(builder: (_, c) {
                        final alt = c.maxHeight - 18;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: alt,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // Planejado
                                  Container(
                                    height: math.max(alt * s[i].planejadoKm / maximo, 4),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(8)),
                                      border: Border.all(
                                          color: p.textoSecundario.withValues(alpha: 0.5),
                                          width: 1.2),
                                    ),
                                  ),
                                  // Realizado
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: s[i].realizadoKm / maximo),
                                    duration: Duration(milliseconds: 500 + i * 60),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, v, __) => Container(
                                      height: math.max(alt * v, 3),
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: i == sel
                                            ? _destaque
                                            : (p.escuro
                                                ? const Color(0xFF55682A)
                                                : const Color(0xFFC6E86A)),
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(6)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${s[i].inicio.day}/${s[i].inicio.month}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: i == sel ? FontWeight.w800 : FontWeight.w500,
                                    color: i == sel ? p.texto : p.textoSecundario)),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Legenda(cor: _destaque, texto: 'Realizado'),
              const SizedBox(width: 14),
              _Legenda(cor: p.textoSecundario, texto: 'Planejado', contorno: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto, this.contorno = false});

  final Color cor;
  final String texto;
  final bool contorno;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: contorno ? null : cor,
            borderRadius: BorderRadius.circular(3),
            border: contorno ? Border.all(color: cor, width: 1.2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(fontSize: 11.5, color: p.textoSecundario)),
      ],
    );
  }
}

/// Anel de progresso.
class _Anel extends StatelessWidget {
  const _Anel({required this.valor, required this.tamanho, required this.centro});

  final double valor;
  final double tamanho;
  final Widget centro;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: tamanho,
        height: tamanho,
        child: CustomPaint(
          painter: _AnelPainter(v, trilho: p.borda),
          child: Center(child: centro),
        ),
      ),
    );
  }
}

class _AnelPainter extends CustomPainter {
  const _AnelPainter(this.v, {required this.trilho});

  final double v;
  final Color trilho;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.width / 2 - 5);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, base..color = trilho);
    if (v > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, base..color = _destaque);
    }
  }

  @override
  bool shouldRepaint(covariant _AnelPainter old) =>
      old.v != v || old.trilho != trilho;
}

// =============================================================================
// ALUNO — INÍCIO
// =============================================================================

class _AlunoInicio extends StatelessWidget {
  const _AlunoInicio({
    required this.dados,
    required this.onDetalhe,
    required this.onExecutar,
    required this.onVerFeedbacks,
    required this.onVerTreinos,
  });

  final DadosAluno dados;
  final ValueChanged<TreinoPlano> onDetalhe;
  final ValueChanged<TreinoPlano> onExecutar;
  final VoidCallback onVerFeedbacks;
  final VoidCallback onVerTreinos;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final hoje = DateTime.now();
    final segunda = _segunda(hoje);
    final daSemana = dados.treinos
        .where((t) => !t.data.isBefore(segunda) &&
            t.data.isBefore(segunda.add(const Duration(days: 7))))
        .toList();
    final feitos = daSemana.where((t) => t.concluido).toList();
    final kmFeitos = feitos.fold<double>(0, (s, t) => s + (t.realizadoKm ?? t.distanciaKm ?? 0));
    final meta = dados.metaKmSemana > 0
        ? dados.metaKmSemana
        : daSemana.fold<double>(0, (s, t) => s + (t.distanciaKm ?? 0));
    final doDia = dados.treinos.where((t) => _mesmoDia(t.data, hoje)).toList();
    final proximos = dados.treinos
        .where((t) => _soData(t.data).isAfter(_soData(hoje)))
        .take(3)
        .toList();
    final ultimoFeedback = dados.feedbacks.isEmpty ? null : dados.feedbacks.first;

    return _Rolagem(children: [
      // ----- Treino do dia -----
      if (doDia.isEmpty)
        const _Vazio(
          icone: Icons.self_improvement_rounded,
          titulo: 'Sem treino para hoje',
          texto: 'Aproveite para descansar. Os próximos treinos estão abaixo.',
        )
      else
        for (final t in doDia) _CardTreinoDoDia(
          treino: t,
          onDetalhe: () => onDetalhe(t),
          onExecutar: () => onExecutar(t),
        ),

      // ----- Progresso semanal -----
      const _Titulo('Progresso da semana'),
      _Cartao(
        child: Row(
          children: [
            _Anel(
              valor: meta > 0 ? kmFeitos / meta : 0,
              tamanho: 92,
              centro: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_km(kmFeitos),
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: p.texto)),
                  Text('km',
                      style: TextStyle(fontSize: 11, color: p.textoSecundario)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meta > 0 ? 'Meta: ${_km(meta)} km' : 'Sem meta definida',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: p.texto)),
                  const SizedBox(height: 4),
                  Text('${feitos.length} de ${daSemana.length} treinos feitos',
                      style: TextStyle(fontSize: 13, color: p.textoSecundario)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: _PontoDia(
                            letra: 'STQQSSD'[i],
                            treinos: daSemana
                                .where((t) => t.data.weekday == i + 1)
                                .toList(),
                            hoje: hoje.weekday == i + 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ----- Último feedback -----
      if (ultimoFeedback != null) ...[
        _Titulo('Do seu treinador', acao: 'Ver todos', onAcao: onVerFeedbacks),
        _BalaoFeedback(feedback: ultimoFeedback, visaoTreinador: false),
      ],

      // ----- Próximos -----
      _Titulo('Próximos treinos', acao: 'Ver agenda', onAcao: onVerTreinos),
      if (proximos.isEmpty)
        Text('Nenhum treino programado ainda.',
            style: TextStyle(fontSize: 13, color: p.textoSecundario))
      else
        for (final t in proximos) _LinhaTreino(treino: t, onTap: () => onDetalhe(t)),
    ]);
  }
}

class _PontoDia extends StatelessWidget {
  const _PontoDia({required this.letra, required this.treinos, required this.hoje});

  final String letra;
  final List<TreinoPlano> treinos;
  final bool hoje;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final feito = treinos.isNotEmpty && treinos.every((t) => t.concluido);
    final tem = treinos.isNotEmpty;
    return Column(
      children: [
        Text(letra,
            style: TextStyle(
                fontSize: 10,
                fontWeight: hoje ? FontWeight.w900 : FontWeight.w600,
                color: hoje ? p.texto : p.textoSecundario)),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: feito ? _destaque : (tem ? p.textoSecundario.withValues(alpha: 0.35) : p.cinza),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _CardTreinoDoDia extends StatelessWidget {
  const _CardTreinoDoDia({
    required this.treino,
    required this.onDetalhe,
    required this.onExecutar,
  });

  final TreinoPlano treino;
  final VoidCallback onDetalhe;
  final VoidCallback onExecutar;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final t = treino;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.superficie,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _destaque,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.concluido ? Icons.check_rounded : Icons.bolt,
                        size: 13, color: _tinta),
                    const SizedBox(width: 4),
                    Text(t.concluido ? 'FEITO HOJE' : 'TREINO DE HOJE',
                        style: const TextStyle(
                            color: _tinta,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8)),
                  ],
                ),
              ),
              const Spacer(),
              if (t.tipo != null)
                Text(t.tipo!.toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 14),
          Text(t.titulo,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1)),
          const SizedBox(height: 14),
          Row(
            children: [
              _MetricaClara(
                  rotulo: 'Distância',
                  valor: t.distanciaKm != null ? '${_km(t.distanciaKm!)} km' : '—'),
              _MetricaClara(
                  rotulo: 'Ritmo',
                  valor: t.ritmoAlvo != null ? '${_pace(t.ritmoAlvo!)}/km' : '—'),
              _MetricaClara(
                  rotulo: 'Duração',
                  valor: t.duracaoMin != null ? '${t.duracaoMin} min' : '—'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetalhe,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Detalhes',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              if (!t.concluido) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onExecutar,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Começar treino',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    style: FilledButton.styleFrom(
                      backgroundColor: _destaque,
                      foregroundColor: _tinta,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricaClara extends StatelessWidget {
  const _MetricaClara({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo.toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
          const SizedBox(height: 2),
          Text(valor,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// =============================================================================
// ALUNO — MEUS TREINOS
// =============================================================================

class _AlunoTreinos extends StatefulWidget {
  const _AlunoTreinos({required this.dados, required this.onDetalhe});

  final DadosAluno dados;
  final ValueChanged<TreinoPlano> onDetalhe;

  @override
  State<_AlunoTreinos> createState() => _AlunoTreinosState();
}

class _AlunoTreinosState extends State<_AlunoTreinos> {
  int _filtro = 1; // 0 passados, 1 atuais (hoje + semana), 2 futuros

  @override
  Widget build(BuildContext context) {
    final hoje = _soData(DateTime.now());
    final fimSemana = _segunda(hoje).add(const Duration(days: 7));
    final todos = widget.dados.treinos;
    final lista = switch (_filtro) {
      0 => todos.where((t) => _soData(t.data).isBefore(hoje)).toList().reversed.toList(),
      1 => todos
          .where((t) => !_soData(t.data).isBefore(hoje) && t.data.isBefore(fimSemana))
          .toList(),
      _ => todos.where((t) => !t.data.isBefore(fimSemana)).toList(),
    };

    return _Rolagem(children: [
      _Segmentos(
        opcoes: const ['Passados', 'Esta semana', 'Futuros'],
        atual: _filtro,
        onMudar: (i) => setState(() => _filtro = i),
      ),
      const SizedBox(height: 14),
      if (lista.isEmpty)
        _Vazio(
          icone: Icons.event_busy_rounded,
          titulo: 'Nada por aqui',
          texto: _filtro == 0
              ? 'Seus treinos concluídos aparecem aqui.'
              : 'Quando seu treinador programar treinos, eles aparecem aqui.',
        )
      else
        for (final t in lista)
          _LinhaTreino(treino: t, onTap: () => widget.onDetalhe(t)),
    ]);
  }
}

class _Segmentos extends StatelessWidget {
  const _Segmentos({required this.opcoes, required this.atual, required this.onMudar});

  final List<String> opcoes;
  final int atual;
  final ValueChanged<int> onMudar;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.cinza,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < opcoes.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onMudar(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == atual ? p.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: i == atual
                        ? [BoxShadow(color: p.sombra, blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(opcoes[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: i == atual ? FontWeight.w800 : FontWeight.w600,
                          color: i == atual ? p.texto : p.textoSecundario)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// ALUNO — EVOLUÇÃO
// =============================================================================

class _AlunoEvolucao extends StatelessWidget {
  const _AlunoEvolucao({required this.dados, required this.onDetalhe});

  final DadosAluno dados;
  final ValueChanged<TreinoPlano> onDetalhe;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final feitos = dados.treinos.where((t) => t.concluido).toList();
    final passados = dados.treinos
        .where((t) => _soData(t.data).isBefore(_soData(DateTime.now())) || t.concluido)
        .toList();
    final km = feitos.fold<double>(0, (s, t) => s + (t.realizadoKm ?? 0));
    final paces = feitos.map((t) => t.paceReal).whereType<double>().toList();
    final paceMedio =
        paces.isEmpty ? null : paces.reduce((a, b) => a + b) / paces.length;
    final cumprimento =
        passados.isEmpty ? null : feitos.length / passados.length;

    return _Rolagem(children: [
      Row(
        children: [
          Expanded(
            child: _Numero(
              icone: Icons.route_rounded,
              valor: _km(km),
              rotulo: 'km realizados',
              destacado: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Numero(
              icone: Icons.speed_rounded,
              valor: paceMedio != null ? _pace(paceMedio) : '—',
              rotulo: 'ritmo médio /km',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Numero(
              icone: Icons.task_alt_rounded,
              valor: cumprimento != null ? '${(cumprimento * 100).round()}%' : '—',
              rotulo: 'treinos cumpridos',
            ),
          ),
        ],
      ),
      if (dados.semanas.isNotEmpty) ...[
        const _Titulo('Planejado x realizado'),
        _GraficoSemanas(semanas: dados.semanas),
      ],
      const _Titulo('Histórico'),
      if (feitos.isEmpty)
        const _Vazio(
          icone: Icons.history_rounded,
          titulo: 'Seu histórico começa aqui',
          texto: 'Conclua um treino para ver distância, ritmo e evolução.',
        )
      else
        for (final t in feitos.reversed) _LinhaHistorico(treino: t, onTap: () => onDetalhe(t)),
    ]);
  }
}

/// Treino concluído: realizado em destaque, planejado embaixo.
class _LinhaHistorico extends StatelessWidget {
  const _LinhaHistorico({required this.treino, required this.onTap});

  final TreinoPlano treino;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final t = treino;
    final plan = t.distanciaKm;
    final real = t.realizadoKm;
    final pct = plan != null && plan > 0 && real != null ? real / plan : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Cartao(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: p.texto)),
                ),
                Text(_dataLonga(t.data),
                    style: TextStyle(fontSize: 12, color: p.textoSecundario)),
              ],
            ),
            if (t.alunoNome != null)
              Text(t.alunoNome!,
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600, color: p.verde)),
            const SizedBox(height: 10),
            Row(
              children: [
                _Comparacao(
                    rotulo: 'Distância',
                    real: real != null ? '${_km(real)} km' : '—',
                    plano: plan != null ? '${_km(plan)} km' : null),
                _Comparacao(
                    rotulo: 'Ritmo',
                    real: t.paceReal != null ? '${_pace(t.paceReal!)}/km' : '—',
                    plano: t.ritmoAlvo != null ? '${_pace(t.ritmoAlvo!)}/km' : null),
                _Comparacao(
                    rotulo: 'Tempo',
                    real: t.realizadoSeg != null ? _duracao(t.realizadoSeg!) : '—',
                    plano: t.duracaoMin != null ? '${t.duracaoMin} min' : null),
              ],
            ),
            if (pct != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 6,
                  color: pct >= 0.9 ? _destaque : _laranja,
                  backgroundColor: p.cinza,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Comparacao extends StatelessWidget {
  const _Comparacao({required this.rotulo, required this.real, this.plano});

  final String rotulo;
  final String real;
  final String? plano;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo.toUpperCase(),
              style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: p.textoSecundario,
                  letterSpacing: 0.6)),
          const SizedBox(height: 2),
          Text(real,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: p.texto)),
          if (plano != null)
            Text('meta $plano',
                style: TextStyle(fontSize: 11, color: p.textoSecundario)),
        ],
      ),
    );
  }
}

// =============================================================================
// FEEDBACKS (aluno recebe / treinador envia)
// =============================================================================

class _ListaFeedbacks extends StatelessWidget {
  const _ListaFeedbacks({
    required this.feedbacks,
    required this.visaoTreinador,
    this.onTocar,
    this.onNovo,
  });

  final List<FeedbackTreino> feedbacks;
  final bool visaoTreinador;
  final ValueChanged<FeedbackTreino>? onTocar;
  final VoidCallback? onNovo;

  @override
  Widget build(BuildContext context) {
    return _Rolagem(children: [
      if (visaoTreinador)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _BotaoGrande(
            icone: Icons.edit_note_rounded,
            texto: 'Escrever feedback para um aluno',
            onTap: onNovo,
          ),
        ),
      if (feedbacks.isEmpty)
        _Vazio(
          icone: Icons.forum_outlined,
          titulo: visaoTreinador ? 'Nenhum feedback enviado' : 'Nenhum feedback ainda',
          texto: visaoTreinador
              ? 'Comentários e orientações que você enviar aparecem aqui.'
              : 'Comentários e orientações do seu treinador aparecem aqui.',
        )
      else
        for (final f in feedbacks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: onTocar == null ? null : () => onTocar!(f),
              child: _BalaoFeedback(feedback: f, visaoTreinador: visaoTreinador),
            ),
          ),
    ]);
  }
}

class _BalaoFeedback extends StatelessWidget {
  const _BalaoFeedback({required this.feedback, required this.visaoTreinador});

  final FeedbackTreino feedback;
  final bool visaoTreinador;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final f = feedback;
    final quem = visaoTreinador
        ? 'Para ${f.alunoNome ?? 'aluno'}'
        : (f.autor ?? 'Seu treinador');
    final novo = !f.lido && !visaoTreinador;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: novo ? p.destaqueSuave : p.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: novo ? _destaque : p.borda, width: novo ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: p.superficie,
                child: Text(
                  _iniciais(visaoTreinador ? (f.alunoNome ?? '?') : (f.autor ?? 'T')),
                  style: const TextStyle(
                      color: _destaque, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(quem,
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w800, color: p.texto)),
              ),
              if (f.pendenteEnvio)
                Icon(Icons.cloud_upload_outlined, size: 16, color: p.textoSecundario)
              else if (novo)
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(color: _vermelho, shape: BoxShape.circle),
                ),
              const SizedBox(width: 6),
              Text(_dataLonga(f.data),
                  style: TextStyle(fontSize: 11.5, color: p.textoSecundario)),
            ],
          ),
          if (f.treinoTitulo != null) ...[
            const SizedBox(height: 8),
            Text('Sobre: ${f.treinoTitulo}',
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: p.verde)),
          ],
          const SizedBox(height: 6),
          Text(f.texto, style: TextStyle(fontSize: 14, height: 1.45, color: p.texto)),
        ],
      ),
    );
  }
}

class _BotaoGrande extends StatelessWidget {
  const _BotaoGrande({required this.icone, required this.texto, this.onTap});

  final IconData icone;
  final String texto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Material(
      color: p.superficie,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _destaque,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: _tinta, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(texto,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5)),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ALUNO — PERFIL
// =============================================================================

class _AlunoPerfil extends StatelessWidget {
  const _AlunoPerfil({required this.dados, required this.onEditar});

  final DadosAluno dados;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final u = FirebaseAuth.instance.currentUser;
    final perfil = dados.perfil;
    final nome = perfil.nome ?? u?.displayName ?? 'Atleta';
    final pendente = FilaOffline.instancia
        .corpos(metodo: 'PUT', caminho: '/perfil')
        .isNotEmpty;

    return _Rolagem(children: [
      _Cartao(
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.superficie,
                shape: BoxShape.circle,
                border: Border.all(color: _destaque, width: 2.5),
              ),
              child: Text(_iniciais(nome),
                  style: const TextStyle(
                      color: _destaque, fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome,
                      style: TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800, color: p.texto)),
                  if (perfil.nivel != null)
                    Text(perfil.nivel!,
                        style: TextStyle(fontSize: 13, color: p.textoSecundario)),
                  if (pendente)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Alterações aguardando internet',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: p.verde)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      const _Titulo('Informações pessoais'),
      _Cartao(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _LinhaInfo(icone: Icons.alternate_email_rounded, rotulo: 'E-mail',
                valor: perfil.email ?? u?.email ?? '—'),
            _LinhaInfo(icone: Icons.phone_outlined, rotulo: 'Telefone',
                valor: perfil.telefone ?? '—'),
            _LinhaInfo(icone: Icons.flag_outlined, rotulo: 'Objetivo',
                valor: perfil.objetivo ?? '—'),
            _LinhaInfo(icone: Icons.sports_rounded, rotulo: 'Treinador',
                valor: perfil.treinador ?? '—', ultima: true),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _BotaoGrande(icone: Icons.edit_rounded, texto: 'Editar informações', onTap: onEditar),
    ]);
  }
}

class _LinhaInfo extends StatelessWidget {
  const _LinhaInfo({
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.ultima = false,
  });

  final IconData icone;
  final String rotulo;
  final String valor;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: ultima ? null : Border(bottom: BorderSide(color: p.borda)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: p.destaqueSuave,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icone, size: 17, color: p.corSobreSuave),
          ),
          const SizedBox(width: 12),
          Text(rotulo, style: TextStyle(fontSize: 13.5, color: p.textoSecundario)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(valor,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: p.texto)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TREINADOR — DASHBOARD
// =============================================================================

class _TreinadorDashboard extends StatelessWidget {
  const _TreinadorDashboard({
    required this.dados,
    required this.onDetalhe,
    required this.onAluno,
    required this.onVerAgenda,
    required this.onVerAvisos,
  });

  final DadosTreinador dados;
  final ValueChanged<TreinoPlano> onDetalhe;
  final ValueChanged<AlunoResumo> onAluno;
  final VoidCallback onVerAgenda;
  final VoidCallback onVerAvisos;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final hoje = DateTime.now();
    final segunda = _segunda(hoje);
    final semana = dados.agenda
        .where((t) => !t.data.isBefore(segunda) &&
            t.data.isBefore(segunda.add(const Duration(days: 7))))
        .toList();
    final concluidos = semana.where((t) => t.concluido).length;
    final ateHoje = semana.where((t) => !_soData(t.data).isAfter(_soData(hoje))).length;
    final doDia = dados.agenda.where((t) => _mesmoDia(t.data, hoje)).toList();
    final atencao = dados.alunos.where((a) => a.frequencia < 0.5).toList();

    return _Rolagem(children: [
      Row(
        children: [
          Expanded(
            child: _Numero(
              icone: Icons.groups_rounded,
              valor: '${dados.alunos.length}',
              rotulo: dados.alunos.length == 1 ? 'aluno' : 'alunos',
              destacado: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Numero(
              icone: Icons.event_note_rounded,
              valor: '${semana.length}',
              rotulo: 'treinos na semana',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Numero(
              icone: Icons.task_alt_rounded,
              valor: '$concluidos',
              rotulo: 'concluídos',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _Cartao(
        child: Row(
          children: [
            _Anel(
              valor: ateHoje > 0 ? concluidos / ateHoje : 0,
              tamanho: 80,
              centro: Text(
                ateHoje > 0 ? '${(concluidos / ateHoje * 100).round()}%' : '—',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: p.texto),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Taxa de conclusão',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: p.texto)),
                  const SizedBox(height: 4),
                  Text(
                      '$concluidos de $ateHoje treinos programados até hoje '
                      'nesta semana foram feitos.',
                      style: TextStyle(
                          fontSize: 12.5, height: 1.4, color: p.textoSecundario)),
                ],
              ),
            ),
          ],
        ),
      ),
      _Titulo('Hoje', acao: 'Agenda', onAcao: onVerAgenda),
      if (doDia.isEmpty)
        Text('Nenhum treino programado para hoje.',
            style: TextStyle(fontSize: 13, color: p.textoSecundario))
      else
        for (final t in doDia)
          _LinhaTreino(treino: t, mostrarAluno: true, onTap: () => onDetalhe(t)),
      if (atencao.isNotEmpty) ...[
        const _Titulo('Precisam de atenção'),
        for (final a in atencao) _CardAluno(aluno: a, onTap: () => onAluno(a)),
      ],
      if (dados.avisos.isNotEmpty) ...[
        _Titulo('Últimos avisos', acao: 'Ver todos', onAcao: onVerAvisos),
        for (final a in dados.avisos.take(3)) _LinhaAviso(aviso: a),
      ],
    ]);
  }
}

// =============================================================================
// TREINADOR — ALUNOS
// =============================================================================

class _TreinadorAlunos extends StatefulWidget {
  const _TreinadorAlunos({required this.dados, required this.onAluno});

  final DadosTreinador dados;
  final ValueChanged<AlunoResumo> onAluno;

  @override
  State<_TreinadorAlunos> createState() => _TreinadorAlunosState();
}

class _TreinadorAlunosState extends State<_TreinadorAlunos> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final termo = _busca.trim().toLowerCase();
    final lista = widget.dados.alunos
        .where((a) => termo.isEmpty || a.nome.toLowerCase().contains(termo))
        .toList();

    return _Rolagem(children: [
      TextField(
        onChanged: (v) => setState(() => _busca = v),
        style: TextStyle(color: p.texto),
        decoration: _campo(p, 'Buscar aluno', Icons.search_rounded),
      ),
      const SizedBox(height: 14),
      if (lista.isEmpty)
        _Vazio(
          icone: Icons.group_off_rounded,
          titulo: widget.dados.alunos.isEmpty ? 'Nenhum aluno ainda' : 'Nenhum resultado',
          texto: widget.dados.alunos.isEmpty
              ? 'Os alunos vinculados a você aparecem aqui.'
              : 'Tente outro nome.',
        )
      else
        for (final a in lista) _CardAluno(aluno: a, onTap: () => widget.onAluno(a)),
    ]);
  }
}

class _CardAluno extends StatelessWidget {
  const _CardAluno({required this.aluno, required this.onTap});

  final AlunoResumo aluno;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final a = aluno;
    final cor = a.frequencia >= 0.75
        ? _destaque
        : (a.frequencia >= 0.5 ? _laranja : _vermelho);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Cartao(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: p.superficie,
              child: Text(_iniciais(a.nome),
                  style: const TextStyle(
                      color: _destaque, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: p.texto)),
                  Text(
                    [
                      if (a.nivel != null) a.nivel!,
                      '${_km(a.kmSemana)} km na semana',
                    ].join(' · '),
                    style: TextStyle(fontSize: 12, color: p.textoSecundario),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: a.frequencia,
                            minHeight: 6,
                            color: cor,
                            backgroundColor: p.cinza,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(a.frequencia * 100).round()}%',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: p.texto)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: p.textoSecundario),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TREINADOR — PERFIL DO ALUNO (tela própria)
// =============================================================================

class _PerfilAlunoTela extends StatefulWidget {
  const _PerfilAlunoTela({
    required this.resumo,
    required this.onCriarTreino,
    required this.onFeedback,
    required this.onDetalhe,
  });

  final AlunoResumo resumo;
  final VoidCallback onCriarTreino;
  final VoidCallback onFeedback;
  final ValueChanged<TreinoPlano> onDetalhe;

  @override
  State<_PerfilAlunoTela> createState() => _PerfilAlunoTelaState();
}

class _PerfilAlunoTelaState extends State<_PerfilAlunoTela> {
  bool _carregando = true;
  String? _erro;
  List<TreinoPlano> _treinos = const [];
  List<SemanaPlano> _semanas = const [];
  PerfilAlunoInfo _info = const PerfilAlunoInfo();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final r = await _PainelApi.aluno(widget.resumo.id);
    if (!mounted) return;
    final j = r.dados;
    setState(() {
      _carregando = false;
      _erro = j == null ? r.erro : null;
      if (j != null) {
        _treinos = _lista(j['treinos'])
            .map((e) => TreinoPlano.fromJson(e))
            .whereType<TreinoPlano>()
            .toList()
          ..sort((a, b) => b.data.compareTo(a.data));
        _semanas = _lista(j['semanas'])
            .map(SemanaPlano.fromJson)
            .whereType<SemanaPlano>()
            .toList()
          ..sort((a, b) => a.inicio.compareTo(b.inicio));
        _info = PerfilAlunoInfo.fromJson(
            j['perfil'] is Map<String, dynamic> ? j['perfil'] as Map<String, dynamic> : null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final a = widget.resumo;
    final feitos = _treinos.where((t) => t.concluido).toList();
    final km = feitos.fold<double>(0, (s, t) => s + (t.realizadoKm ?? 0));
    final paces = feitos.map((t) => t.paceReal).whereType<double>().toList();
    final paceMedio =
        paces.isEmpty ? null : paces.reduce((x, y) => x + y) / paces.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.barraStatus,
      child: Scaffold(
        backgroundColor: p.fundo,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: p.heroi,
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + 8, 16, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _BotaoVidro(
                        icone: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.maybePop(context),
                      ),
                      const Spacer(),
                      Text('PERFIL DO ALUNO',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: p.heroiLinha,
                              letterSpacing: 1.5)),
                      const Spacer(),
                      const SizedBox(width: 42),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.escuro ? const Color(0xFF23271E) : _tinta,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.heroiLinha, width: 2.5),
                    ),
                    child: Text(_iniciais(a.nome),
                        style: const TextStyle(
                            color: _destaque, fontSize: 26, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 10),
                  Text(a.nome,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, color: p.heroiTexto)),
                  Text(
                    [
                      if (a.nivel != null) a.nivel!,
                      if (_info.objetivo != null) 'Objetivo: ${_info.objetivo}',
                    ].join(' · '),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: p.heroiTextoSec),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _carregando
                  ? const _Carregando()
                  : RefreshIndicator(
                      color: p.texto,
                      backgroundColor: p.card,
                      onRefresh: _carregar,
                      child: _Rolagem(children: [
                        if (_erro != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text('Sem conexão. $_erro',
                                style: TextStyle(fontSize: 12.5, color: p.textoSecundario)),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: _Numero(
                                icone: Icons.task_alt_rounded,
                                valor: '${(a.frequencia * 100).round()}%',
                                rotulo: 'frequência',
                                destacado: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Numero(
                                icone: Icons.route_rounded,
                                valor: _km(km),
                                rotulo: 'km no histórico',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Numero(
                                icone: Icons.speed_rounded,
                                valor: paceMedio != null ? _pace(paceMedio) : '—',
                                rotulo: 'ritmo médio',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _BotaoAcao(
                                icone: Icons.add_rounded,
                                texto: 'Criar treino',
                                destacado: true,
                                onTap: widget.onCriarTreino,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _BotaoAcao(
                                icone: Icons.chat_bubble_outline_rounded,
                                texto: 'Feedback',
                                onTap: widget.onFeedback,
                              ),
                            ),
                          ],
                        ),
                        if (_semanas.isNotEmpty) ...[
                          const _Titulo('Evolução'),
                          _GraficoSemanas(semanas: _semanas),
                        ],
                        const _Titulo('Histórico de treinos'),
                        if (_treinos.isEmpty)
                          const _Vazio(
                            icone: Icons.history_rounded,
                            titulo: 'Sem histórico',
                            texto: 'Os treinos deste aluno aparecem aqui.',
                          )
                        else
                          for (final t in _treinos)
                            t.concluido
                                ? _LinhaHistorico(
                                    treino: t, onTap: () => widget.onDetalhe(t))
                                : _LinhaTreino(
                                    treino: t, onTap: () => widget.onDetalhe(t)),
                      ]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoAcao extends StatelessWidget {
  const _BotaoAcao({
    required this.icone,
    required this.texto,
    required this.onTap,
    this.destacado = false,
  });

  final IconData icone;
  final String texto;
  final VoidCallback onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icone, size: 19),
        label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: FilledButton.styleFrom(
          backgroundColor: destacado ? _destaque : p.superficie,
          foregroundColor: destacado ? _tinta : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// =============================================================================
// TREINADOR — AGENDA
// =============================================================================

class _TreinadorAgenda extends StatefulWidget {
  const _TreinadorAgenda({
    required this.dados,
    required this.onDetalhe,
    required this.onCriar,
  });

  final DadosTreinador dados;
  final ValueChanged<TreinoPlano> onDetalhe;
  final ValueChanged<DateTime> onCriar;

  @override
  State<_TreinadorAgenda> createState() => _TreinadorAgendaState();
}

class _TreinadorAgendaState extends State<_TreinadorAgenda> {
  late DateTime _semana = _segunda(DateTime.now());
  late DateTime _dia = _soData(DateTime.now());

  void _mudarSemana(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _semana = _semana.add(Duration(days: 7 * delta));
      _dia = _semana;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final agenda = widget.dados.agenda;
    final doDia = agenda.where((t) => _mesmoDia(t.data, _dia)).toList();
    final fim = _semana.add(const Duration(days: 6));

    return _Rolagem(children: [
      Row(
        children: [
          IconButton(
            onPressed: () => _mudarSemana(-1),
            icon: Icon(Icons.chevron_left_rounded, color: p.texto),
          ),
          Expanded(
            child: Text('${_dataCurta(_semana)} – ${_dataCurta(fim)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: p.texto)),
          ),
          IconButton(
            onPressed: () => _mudarSemana(1),
            icon: Icon(Icons.chevron_right_rounded, color: p.texto),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: () {
                final d = _semana.add(Duration(days: i));
                final qtd = agenda.where((t) => _mesmoDia(t.data, d)).length;
                final sel = _mesmoDia(d, _dia);
                final hoje = _mesmoDia(d, DateTime.now());
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _dia = d);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? p.superficie : p.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: hoje && !sel ? _destaque : (sel ? p.superficie : p.borda),
                          width: hoje && !sel ? 1.5 : 1),
                    ),
                    child: Column(
                      children: [
                        Text(_dias[i].toUpperCase(),
                            style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: sel ? const Color(0xFF9CA3AF) : p.textoSecundario)),
                        const SizedBox(height: 2),
                        Text('${d.day}',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: sel ? Colors.white : p.texto)),
                        const SizedBox(height: 4),
                        Container(
                          width: 18,
                          height: 4,
                          decoration: BoxDecoration(
                            color: qtd == 0
                                ? Colors.transparent
                                : (sel ? _destaque : p.textoSecundario.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }(),
            ),
          ],
        ],
      ),
      _Titulo(
        _dataLonga(_dia),
        acao: '+ Adicionar',
        onAcao: () => widget.onCriar(_dia),
      ),
      if (doDia.isEmpty)
        _Vazio(
          icone: Icons.event_available_rounded,
          titulo: 'Dia livre',
          texto: 'Nenhum treino programado. Toque em "+ Adicionar" para criar.',
        )
      else
        for (final t in doDia)
          _LinhaTreino(treino: t, mostrarAluno: true, onTap: () => widget.onDetalhe(t)),
    ]);
  }
}

// =============================================================================
// TREINADOR — DESEMPENHO
// =============================================================================

class _TreinadorDesempenho extends StatelessWidget {
  const _TreinadorDesempenho({required this.dados, required this.onAluno});

  final DadosTreinador dados;
  final ValueChanged<AlunoResumo> onAluno;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final hoje = _soData(DateTime.now());

    // Por aluno: km planejado x realizado nos treinos que já passaram.
    final linhas = <({AlunoResumo aluno, double plano, double real, int feitos, int total})>[];
    for (final a in dados.alunos) {
      final passados = dados.agenda
          .where((t) => t.alunoId == a.id && !_soData(t.data).isAfter(hoje))
          .toList();
      if (passados.isEmpty) continue;
      linhas.add((
        aluno: a,
        plano: passados.fold<double>(0, (s, t) => s + (t.distanciaKm ?? 0)),
        real: passados.fold<double>(0, (s, t) => s + (t.realizadoKm ?? 0)),
        feitos: passados.where((t) => t.concluido).length,
        total: passados.length,
      ));
    }
    linhas.sort((x, y) =>
        (y.feitos / y.total).compareTo(x.feitos / x.total));

    return _Rolagem(children: [
      if (dados.desempenho.isNotEmpty) ...[
        Text('Todos os alunos',
            style: TextStyle(fontSize: 12.5, color: p.textoSecundario)),
        const SizedBox(height: 8),
        _GraficoSemanas(semanas: dados.desempenho),
      ],
      const _Titulo('Planejado x realizado por aluno'),
      if (linhas.isEmpty)
        const _Vazio(
          icone: Icons.insights_rounded,
          titulo: 'Ainda sem dados',
          texto: 'Quando seus alunos fizerem os treinos programados, '
              'a comparação aparece aqui.',
        )
      else
        for (final l in linhas)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Cartao(
              onTap: () => onAluno(l.aluno),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(l.aluno.nome,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: p.texto)),
                      ),
                      Text('${l.feitos}/${l.total} treinos',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: p.textoSecundario)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _BarraComparada(plano: l.plano, real: l.real),
                ],
              ),
            ),
          ),
    ]);
  }
}

class _BarraComparada extends StatelessWidget {
  const _BarraComparada({required this.plano, required this.real});

  final double plano;
  final double real;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final maximo = math.max(plano, real);
    final pct = plano > 0 ? real / plano : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (_, c) {
          final w = c.maxWidth;
          return Stack(
            children: [
              Container(
                height: 14,
                width: maximo > 0 ? w * plano / maximo : 0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: p.textoSecundario.withValues(alpha: 0.5), width: 1.2),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: maximo > 0 ? real / maximo : 0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Container(
                  height: 14,
                  width: w * v,
                  decoration: BoxDecoration(
                    color: (pct ?? 0) >= 0.9 ? _destaque : _laranja,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 6),
        Text(
          '${_km(real)} de ${_km(plano)} km'
          '${pct != null ? ' · ${(pct * 100).round()}%' : ''}',
          style: TextStyle(fontSize: 12, color: p.textoSecundario),
        ),
      ],
    );
  }
}

// =============================================================================
// TREINADOR — AVISOS
// =============================================================================

class _TreinadorAvisos extends StatelessWidget {
  const _TreinadorAvisos({required this.avisos});

  final List<AvisoTreinador> avisos;

  @override
  Widget build(BuildContext context) {
    return _Rolagem(children: [
      if (avisos.isEmpty)
        const _Vazio(
          icone: Icons.notifications_none_rounded,
          titulo: 'Tudo tranquilo',
          texto: 'Treinos concluídos e informações importantes aparecem aqui.',
        )
      else
        for (final a in avisos) _LinhaAviso(aviso: a),
    ]);
  }
}

class _LinhaAviso extends StatelessWidget {
  const _LinhaAviso({required this.aviso});

  final AvisoTreinador aviso;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final (icone, fundo, cor) = switch (aviso.tipo.toLowerCase()) {
      'concluido' => (Icons.check_circle_rounded, p.destaqueSuave, p.corSobreSuave),
      'perdido' => (Icons.event_busy_rounded, p.vermelhoSuave, _vermelho),
      'feedback' => (Icons.chat_bubble_rounded, p.cinza, p.texto),
      _ => (Icons.info_outline_rounded, p.laranjaSuave, _laranja),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Cartao(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: fundo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, size: 19, color: cor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (aviso.alunoNome != null)
                    Text(aviso.alunoNome!,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: p.texto)),
                  Text(aviso.texto,
                      style: TextStyle(
                          fontSize: 13.5, height: 1.4, color: p.texto)),
                  const SizedBox(height: 4),
                  Text(_dataLonga(aviso.data),
                      style: TextStyle(fontSize: 11.5, color: p.textoSecundario)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// FOLHAS (bottom sheets)
// =============================================================================

/// Moldura comum das folhas: alça, título, conteúdo rolável.
class _Folha extends StatelessWidget {
  const _Folha({required this.titulo, required this.children, this.sobre});

  final String titulo;
  final String? sobre;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final teclado = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: BoxDecoration(
        color: p.fundo,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: teclado),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.borda,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (sobre != null)
                Text(sobre!,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: p.verde,
                        letterSpacing: 1.2)),
              Text(titulo,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: p.texto)),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _campo(_Paleta p, String dica, IconData icone) => InputDecoration(
      hintText: dica,
      hintStyle: TextStyle(color: p.textoSecundario),
      prefixIcon: Icon(icone, color: p.textoSecundario, size: 20),
      filled: true,
      fillColor: p.card,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.texto, width: 1.5),
      ),
    );

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(texto,
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: p.textoSecundario)),
    );
  }
}

class _BotaoPrincipal extends StatelessWidget {
  const _BotaoPrincipal({required this.texto, required this.onTap, this.icone});

  final String texto;
  final IconData? icone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icone ?? Icons.check_rounded),
        label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        style: FilledButton.styleFrom(
          backgroundColor: p.escuro ? _destaque : _tinta,
          foregroundColor: p.escuro ? _tinta : Colors.white,
          disabledBackgroundColor: p.borda,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

/// Detalhes do treino. Devolve "executar" ou "feedback".
class _FolhaDetalhe extends StatelessWidget {
  const _FolhaDetalhe({required this.treino, required this.papel});

  final TreinoPlano treino;
  final Papel papel;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final t = treino;
    return _Folha(
      sobre: [
        _dataLonga(t.data).toUpperCase(),
        if (t.tipo != null) t.tipo!.toUpperCase(),
      ].join(' · '),
      titulo: t.titulo,
      children: [
        Row(children: [_SeloStatus(treino: t)]),
        if (papel == Papel.treinador && t.alunoNome != null) ...[
          const SizedBox(height: 10),
          Text('Aluno: ${t.alunoNome}',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: p.verde)),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Numero(
                icone: Icons.straighten_rounded,
                valor: t.distanciaKm != null ? '${_km(t.distanciaKm!)} km' : '—',
                rotulo: 'distância',
                destacado: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Numero(
                icone: Icons.speed_rounded,
                valor: t.ritmoAlvo != null ? _pace(t.ritmoAlvo!) : '—',
                rotulo: 'ritmo desejado /km',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Numero(
                icone: Icons.timer_outlined,
                valor: t.duracaoMin != null ? '${t.duracaoMin}' : '—',
                rotulo: 'minutos',
              ),
            ),
          ],
        ),
        const _Rotulo('Instruções do treinador'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.borda),
          ),
          child: Text(
            t.instrucoes ?? 'Sem instruções para este treino.',
            style: TextStyle(fontSize: 14, height: 1.5, color: p.texto),
          ),
        ),
        if (t.concluido) ...[
          const _Rotulo('Realizado'),
          _LinhaHistorico(treino: t, onTap: () {}),
        ],
        const SizedBox(height: 18),
        if (papel == Papel.aluno && !t.concluido)
          _BotaoPrincipal(
            texto: 'Executar treino',
            icone: Icons.play_arrow_rounded,
            onTap: () => Navigator.pop(context, 'executar'),
          ),
        if (papel == Papel.treinador)
          _BotaoPrincipal(
            texto: 'Enviar feedback sobre este treino',
            icone: Icons.chat_bubble_outline_rounded,
            onTap: () => Navigator.pop(context, 'feedback'),
          ),
      ],
    );
  }
}

/// Formulário de criação de treino. Devolve o corpo do POST /painel/treinos.
class _FolhaCriarTreino extends StatefulWidget {
  const _FolhaCriarTreino({
    required this.alunos,
    this.alunoInicial,
    this.dataInicial,
  });

  final List<AlunoResumo> alunos;
  final String? alunoInicial;
  final DateTime? dataInicial;

  @override
  State<_FolhaCriarTreino> createState() => _FolhaCriarTreinoState();
}

class _FolhaCriarTreinoState extends State<_FolhaCriarTreino> {
  static const _tipos = ['Leve', 'Ritmo', 'Intervalado', 'Longo', 'Regenerativo'];

  final _titulo = TextEditingController();
  final _distancia = TextEditingController();
  final _ritmo = TextEditingController();
  final _duracao = TextEditingController();
  final _instrucoes = TextEditingController();
  late String? _alunoId = widget.alunoInicial;
  late DateTime _data = widget.dataInicial ?? _soData(DateTime.now());
  String _tipo = 'Leve';
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _distancia.dispose();
    _ritmo.dispose();
    _duracao.dispose();
    _instrucoes.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => _data = d);
  }

  void _salvar() {
    final distancia = double.tryParse(_distancia.text.replaceAll(',', '.').trim());
    final ritmo = _ritmo.text.trim().isEmpty ? null : _lerPace(_ritmo.text);
    final duracao = int.tryParse(_duracao.text.trim());
    final titulo = _titulo.text.trim();

    String? erro;
    if (_alunoId == null) {
      erro = 'Escolha o aluno.';
    } else if (titulo.isEmpty) {
      erro = 'Dê um nome ao treino.';
    } else if (distancia == null && duracao == null) {
      erro = 'Informe a distância ou a duração.';
    } else if (_ritmo.text.trim().isNotEmpty && ritmo == null) {
      erro = 'Ritmo no formato min:seg, ex.: 5:30';
    }
    if (erro != null) {
      HapticFeedback.heavyImpact();
      setState(() => _erro = erro);
      return;
    }

    Navigator.pop(context, <String, dynamic>{
      'alunoId': _alunoId,
      'data': _dataIso(_data),
      'titulo': titulo,
      'tipo': _tipo,
      'distanciaKm': distancia,
      'ritmoAlvoSegPorKm': ritmo?.round(),
      'duracaoMin': duracao,
      'instrucoes': _instrucoes.text.trim().isEmpty ? null : _instrucoes.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return _Folha(
      sobre: 'NOVO TREINO',
      titulo: 'Criar treino',
      children: [
        const _Rotulo('Aluno'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in widget.alunos)
              _Pilula(
                texto: a.nome.split(' ').first,
                ativo: a.id == _alunoId,
                onTap: () => setState(() => _alunoId = a.id),
              ),
          ],
        ),
        const _Rotulo('Data'),
        _Cartao(
          onTap: _escolherData,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: p.textoSecundario),
              const SizedBox(width: 10),
              Text('${_dataLonga(_data)} (${_data.day}/${_data.month})',
                  style: TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700, color: p.texto)),
              const Spacer(),
              Icon(Icons.edit_calendar_rounded, size: 18, color: p.verde),
            ],
          ),
        ),
        const _Rotulo('Tipo'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _tipos)
              _Pilula(texto: t, ativo: t == _tipo, onTap: () => setState(() => _tipo = t)),
          ],
        ),
        const _Rotulo('Nome do treino'),
        TextField(
          controller: _titulo,
          style: TextStyle(color: p.texto),
          textCapitalization: TextCapitalization.sentences,
          decoration: _campo(p, 'Ex.: Tiros de 400 m', Icons.title_rounded),
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Rotulo('Distância (km)'),
                  TextField(
                    controller: _distancia,
                    style: TextStyle(color: p.texto),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _campo(p, '6', Icons.straighten_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Rotulo('Ritmo (min/km)'),
                  TextField(
                    controller: _ritmo,
                    style: TextStyle(color: p.texto),
                    keyboardType: TextInputType.datetime,
                    decoration: _campo(p, '5:30', Icons.speed_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
        const _Rotulo('Duração (min)'),
        TextField(
          controller: _duracao,
          style: TextStyle(color: p.texto),
          keyboardType: TextInputType.number,
          decoration: _campo(p, '40', Icons.timer_outlined),
        ),
        const _Rotulo('Instruções'),
        TextField(
          controller: _instrucoes,
          style: TextStyle(color: p.texto),
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: _campo(p, 'Aquecimento, séries, descanso, cuidados...',
              Icons.notes_rounded),
        ),
        if (_erro != null) ...[
          const SizedBox(height: 12),
          Text(_erro!,
              style: const TextStyle(
                  color: _vermelho, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
        const SizedBox(height: 18),
        _BotaoPrincipal(texto: 'Salvar treino', onTap: _salvar),
      ],
    );
  }
}

class _Pilula extends StatelessWidget {
  const _Pilula({required this.texto, required this.ativo, required this.onTap});

  final String texto;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: ativo ? _destaque : p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ativo ? _destaque : p.borda),
        ),
        child: Text(texto,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ativo ? _tinta : p.texto)),
      ),
    );
  }
}

/// Escrever feedback. Devolve o corpo do POST /painel/feedbacks.
class _FolhaFeedback extends StatefulWidget {
  const _FolhaFeedback({required this.alunos, this.alunoInicial, this.treino});

  final List<AlunoResumo> alunos;
  final String? alunoInicial;
  final TreinoPlano? treino;

  @override
  State<_FolhaFeedback> createState() => _FolhaFeedbackState();
}

class _FolhaFeedbackState extends State<_FolhaFeedback> {
  final _texto = TextEditingController();
  late String? _alunoId = widget.alunoInicial ?? widget.treino?.alunoId;
  String? _erro;

  static const _sugestoes = [
    'Ótimo treino! Continue assim.',
    'Cuidado com o ritmo no início.',
    'Lembre de hidratar e alongar.',
    'Vamos ajustar o volume da semana.',
  ];

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _texto.text.trim();
    if (_alunoId == null || texto.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() => _erro = _alunoId == null ? 'Escolha o aluno.' : 'Escreva a mensagem.');
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'alunoId': _alunoId,
      'treinoId': widget.treino?.pendenteEnvio == true ? null : widget.treino?.id,
      'treinoTitulo': widget.treino?.titulo,
      'texto': texto,
      'data': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return _Folha(
      sobre: widget.treino != null ? 'SOBRE: ${widget.treino!.titulo.toUpperCase()}' : 'FEEDBACK',
      titulo: 'Escrever feedback',
      children: [
        const _Rotulo('Para'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in widget.alunos)
              _Pilula(
                texto: a.nome.split(' ').first,
                ativo: a.id == _alunoId,
                onTap: () => setState(() => _alunoId = a.id),
              ),
          ],
        ),
        const _Rotulo('Mensagem'),
        TextField(
          controller: _texto,
          style: TextStyle(color: p.texto),
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: _campo(p, 'Comentários, orientações, sugestões...',
              Icons.chat_bubble_outline_rounded),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _sugestoes)
              GestureDetector(
                onTap: () {
                  _texto.text = _texto.text.trim().isEmpty ? s : '${_texto.text.trim()} $s';
                  _texto.selection = TextSelection.collapsed(offset: _texto.text.length);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: p.destaqueSuave,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(s,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: p.corSobreSuave)),
                ),
              ),
          ],
        ),
        if (_erro != null) ...[
          const SizedBox(height: 12),
          Text(_erro!,
              style: const TextStyle(
                  color: _vermelho, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
        const SizedBox(height: 18),
        _BotaoPrincipal(texto: 'Enviar', icone: Icons.send_rounded, onTap: _enviar),
      ],
    );
  }
}

/// Editar informações pessoais do aluno. Devolve o corpo do PUT /perfil.
class _FolhaEditarPerfil extends StatefulWidget {
  const _FolhaEditarPerfil({required this.perfil, this.nomeFirebase});

  final PerfilAlunoInfo perfil;
  final String? nomeFirebase;

  @override
  State<_FolhaEditarPerfil> createState() => _FolhaEditarPerfilState();
}

class _FolhaEditarPerfilState extends State<_FolhaEditarPerfil> {
  late final _nome =
      TextEditingController(text: widget.perfil.nome ?? widget.nomeFirebase ?? '');
  late final _telefone = TextEditingController(text: widget.perfil.telefone ?? '');
  late final _objetivo = TextEditingController(text: widget.perfil.objetivo ?? '');
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  void _salvar() {
    final nome = _nome.text.trim();
    if (nome.length < 2) {
      setState(() => _erro = 'Digite seu nome.');
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'nome': nome,
      'telefone': _telefone.text.trim().isEmpty ? null : _telefone.text.trim(),
      'objetivo': _objetivo.text.trim().isEmpty ? null : _objetivo.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return _Folha(
      sobre: 'PERFIL',
      titulo: 'Editar informações',
      children: [
        const _Rotulo('Nome'),
        TextField(
          controller: _nome,
          style: TextStyle(color: p.texto),
          textCapitalization: TextCapitalization.words,
          decoration: _campo(p, 'Seu nome', Icons.person_outline_rounded),
        ),
        const _Rotulo('Telefone'),
        TextField(
          controller: _telefone,
          style: TextStyle(color: p.texto),
          keyboardType: TextInputType.phone,
          decoration: _campo(p, '(11) 99999-8888', Icons.phone_outlined),
        ),
        const _Rotulo('Objetivo'),
        TextField(
          controller: _objetivo,
          style: TextStyle(color: p.texto),
          textCapitalization: TextCapitalization.sentences,
          decoration: _campo(p, 'Ex.: correr 10 km em 50 min', Icons.flag_outlined),
        ),
        if (_erro != null) ...[
          const SizedBox(height: 12),
          Text(_erro!,
              style: const TextStyle(
                  color: _vermelho, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
        const SizedBox(height: 18),
        _BotaoPrincipal(texto: 'Salvar', onTap: _salvar),
      ],
    );
  }
}
