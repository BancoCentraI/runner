import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/offline.dart';
import 'notificacao.dart';
import 'emergencia.dart';
import 'corrida.dart';
import 'rotas.dart';
import 'perfil.dart';
import 'evolucao.dart';
import 'treinos.dart';
import '../services/preferencia.dart';

// =============================================================================
// CORES
// =============================================================================

class _Cores {
  // Cores que são iguais nos dois temas
  static const tinta = Color(0xFF1A1A1A); // texto/ícone sobre verde-limão
  static const destaque = Color(0xFFD0FD38);
  static const vermelho = Color(0xFFEF4444);
  static Color get escuro => // texto principal
      _modoEscuro ? const Color(0xFFF3F4F6) : const Color(0xFF1A1A1A);
  static Color get textoSecundario =>
      _modoEscuro ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  static Color get fundo =>
      _modoEscuro ? const Color(0xFF111311) : const Color(0xFFF9FAFB);
  static Color get cinzaClaro =>
      _modoEscuro ? const Color(0xFF252923) : const Color(0xFFF3F4F6);
  static Color get borda =>
      _modoEscuro ? const Color(0xFF2C302A) : const Color(0xFFE5E7EB);
  static Color get verde =>
      _modoEscuro ? const Color(0xFF9BC27A) : const Color(0xFF386641);
  static Color get vermelhoFundo =>
      _modoEscuro ? const Color(0xFF2A1616) : const Color(0xFFFEF2F2);
  static Color get vermelhoBorda =>
      _modoEscuro ? const Color(0xFF5A2A2A) : const Color(0xFFFCA5A5);
  static Color get cardTreinador =>
      _modoEscuro ? const Color(0xFF1E2620) : const Color(0xFFE8EDE9);

  /// Cards e botões que são pretos no tema claro.
  static Color get superficie =>
      _modoEscuro ? const Color(0xFF262A23) : const Color(0xFF1A1A1A);

  /// Superfícies que são brancas no tema claro.
  static Color get card => _modoEscuro ? const Color(0xFF1C1F1B) : Colors.white;
}

/// Tema atual (claro/escuro), controlado nas Configurações.
bool get _modoEscuro => Preferencias.instancia.modoEscuro;

// =============================================================================
// MODELOS (convertem o JSON da API em objetos seguros)
// =============================================================================

int _toInt(Object? v, [int padrao = 0]) =>
    v is num ? v.toInt() : (int.tryParse('$v') ?? padrao);

double _toDouble(Object? v, [double padrao = 0]) =>
    v is num ? v.toDouble() : (double.tryParse('$v') ?? padrao);

String? _toStr(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// 18.4 -> "18,4" | 28.0 -> "28"
String _formatarKm(double v) {
  final texto =
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return texto.replaceAll('.', ',');
}

/// "Maria Silva Santos" -> "Maria" | vazio/nulo -> "Atleta"
String _primeiroNome(String? nomeCompleto) {
  final nome = nomeCompleto?.trim() ?? '';
  if (nome.isEmpty) return 'Atleta';
  return nome.split(RegExp(r'\s+')).first;
}

class TreinoHoje {
  const TreinoHoje(
      {required this.titulo, required this.detalhes, this.imagemUrl});

  final String titulo;
  final String detalhes;
  final String? imagemUrl;

  factory TreinoHoje.fromJson(Map<String, dynamic> json) => TreinoHoje(
        titulo: _toStr(json['titulo']) ?? '',
        detalhes: _toStr(json['detalhes']) ?? '',
        imagemUrl: _toStr(json['imagemUrl']),
      );
}

class ResumoSemana {
  const ResumoSemana({
    this.diasCompletos = 0,
    this.metaDias = 4,
    this.diasConcluidos = const [],
    this.km = 0,
    this.metaKm = 0,
    this.percentual = 0,
  });

  final int diasCompletos;
  final int metaDias;

  /// Opcional: dias da semana concluídos (1 = segunda ... 7 = domingo).
  final List<int> diasConcluidos;
  final double km;
  final double metaKm;
  final int percentual;

  int get totalConcluidos =>
      diasConcluidos.isNotEmpty ? diasConcluidos.length : diasCompletos;

  factory ResumoSemana.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ResumoSemana();

    final km = _toDouble(json['kmPercorridos']);
    final metaKm = _toDouble(json['metaKm']);
    final percentualApi = json['percentual'];

    return ResumoSemana(
      diasCompletos: _toInt(json['diasCompletos']),
      metaDias: _toInt(json['metaDias'], 4),
      diasConcluidos: json['diasConcluidos'] is List
          ? (json['diasConcluidos'] as List).map((e) => _toInt(e)).toList()
          : const [],
      km: km,
      metaKm: metaKm,
      percentual: percentualApi != null
          ? _toInt(percentualApi)
          : (metaKm > 0 ? (km / metaKm * 100).round() : 0),
    );
  }

  bool diaConcluido(DateTime data, int indice) {
    if (diasConcluidos.isNotEmpty) return diasConcluidos.contains(data.weekday);
    return indice < diasCompletos;
  }
}

class ProximoTreino {
  const ProximoTreino(
      {required this.dia, this.tipo, required this.nome, required this.resumo});

  final String dia;
  final String? tipo;
  final String nome;
  final String resumo;

  factory ProximoTreino.fromJson(Map<String, dynamic> json) => ProximoTreino(
        dia: _toStr(json['dia']) ?? '',
        tipo: _toStr(json['tipo']),
        nome: _toStr(json['nome']) ?? '',
        resumo: _toStr(json['resumo']) ?? '',
      );
}

class Treinador {
  const Treinador(
      {required this.nome, required this.status, required this.mensagem});

  final String nome;
  final String status;
  final String mensagem;

  bool get online => status.toUpperCase() == 'ONLINE';

  String get iniciais {
    final partes =
        nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  factory Treinador.fromJson(Map<String, dynamic> json) => Treinador(
        nome: _toStr(json['nome']) ?? '',
        status: _toStr(json['status']) ?? '',
        mensagem: _toStr(json['mensagem']) ?? '',
      );
}

class HomeData {
  const HomeData({
    this.nomeUsuario = 'Atleta',
    this.temNotificacao = false,
    this.treinoHoje,
    this.semana = const ResumoSemana(),
    this.proximoTreino,
    this.treinador,
  });

  final String nomeUsuario;
  final bool temNotificacao;
  final TreinoHoje? treinoHoje;
  final ResumoSemana semana;
  final ProximoTreino? proximoTreino;
  final Treinador? treinador;

  factory HomeData.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? objeto(String chave) {
      final valor = json[chave];
      return valor is Map<String, dynamic> ? valor : null;
    }

    final treino = objeto('treinoHoje');
    final proximo = objeto('proximoTreino');
    final treinador = objeto('treinador');

    return HomeData(
      nomeUsuario: _toStr(json['nomeUsuario']) ?? 'Atleta',
      temNotificacao: json['temNotificacao'] == true,
      treinoHoje: treino != null ? TreinoHoje.fromJson(treino) : null,
      semana: ResumoSemana.fromJson(objeto('semana')),
      proximoTreino: proximo != null ? ProximoTreino.fromJson(proximo) : null,
      treinador: treinador != null ? Treinador.fromJson(treinador) : null,
    );
  }
}

// =============================================================================
// SERVIÇO DE API
// =============================================================================

class _HomeApi {
  /// GET /home-dados com cache: sem internet, devolve os últimos dados
  /// salvos no aparelho. Corridas ainda não enviadas já contam na semana.
  static Future<({HomeData dados, String? erro, DateTime? salvoEm})>
      buscar() async {
    final r = await ApiOffline.buscar('/home-dados', cache: 'home');
    final corpo = r.mapa;
    if (r.erro == null && corpo == null) {
      return (
        dados: _somarPendentes(const HomeData()),
        erro: 'Resposta inválida do servidor.',
        salvoEm: null,
      );
    }
    final dados = corpo != null ? HomeData.fromJson(corpo) : const HomeData();
    return (dados: _somarPendentes(dados), erro: r.erro, salvoEm: r.salvoEm);
  }

  /// Soma na "Sua semana" as corridas desta semana que estão na fila.
  static HomeData _somarPendentes(HomeData d) {
    final hoje = DateTime.now();
    final segunda =
        DateTime(hoje.year, hoje.month, hoje.day - (hoje.weekday - 1));

    var km = 0.0;
    final dias = <int>{};
    for (final c in ApiOffline.corridasPendentes()) {
      final data = DateTime.tryParse(
              '${c['iniciadoEm'] ?? c['finalizadoEm'] ?? ''}')
          ?.toLocal();
      if (data == null || data.isBefore(segunda)) continue;
      km += _toDouble(c['distanciaKm']);
      dias.add(data.weekday);
    }
    if (dias.isEmpty) return d;

    final s = d.semana;
    final novosDias = s.diasConcluidos.isNotEmpty
        ? ({...s.diasConcluidos, ...dias}.toList()..sort())
        : const <int>[];
    final kmTotal = s.km + km;
    return HomeData(
      nomeUsuario: d.nomeUsuario,
      temNotificacao: d.temNotificacao,
      treinoHoje: d.treinoHoje,
      proximoTreino: d.proximoTreino,
      treinador: d.treinador,
      semana: ResumoSemana(
        diasCompletos: s.diasConcluidos.isNotEmpty
            ? novosDias.length
            : s.diasCompletos + dias.length,
        metaDias: s.metaDias,
        diasConcluidos: novosDias,
        km: kmTotal,
        metaKm: s.metaKm,
        percentual: s.metaKm > 0
            ? (kmTotal / s.metaKm * 100).round()
            : s.percentual,
      ),
    );
  }
}

// =============================================================================
// TELA
// =============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _abaAtual = 0;
  bool _carregando = true;
  HomeData _dados = const HomeData();

  /// Mensagem de erro da API (null = tudo certo). Aparece como uma bolinha
  /// vermelha no canto; ao tocar, mostra a mensagem.
  String? _erroConexao;

  @override
  void initState() {
    super.initState();
    // Quando a fila offline envia algo, recarrega (os números mudam).
    Sincronizador.instancia.enviados.addListener(_carregar);
    FilaOffline.instancia.pendentes.addListener(_atualizarAviso);
    _carregar();
  }

  @override
  void dispose() {
    Sincronizador.instancia.enviados.removeListener(_carregar);
    FilaOffline.instancia.pendentes.removeListener(_atualizarAviso);
    super.dispose();
  }

  String? _erroApi;
  DateTime? _salvoEm;

  Future<void> _carregar() async {
    final r = await _HomeApi.buscar();
    if (!mounted) return; // evita setState com a tela já fechada
    setState(() {
      _dados = r.dados;
      _carregando = false;
      _erroApi = r.erro;
      _salvoEm = r.salvoEm;
      _erroConexao = _mensagemAviso();
    });
  }

  void _atualizarAviso() {
    if (mounted) setState(() => _erroConexao = _mensagemAviso());
  }

  /// Texto da bolinha vermelha: o erro, de quando são os dados mostrados e
  /// quantos envios esperam internet. Null = tudo certo (sem bolinha).
  String? _mensagemAviso() {
    final pendentes = FilaOffline.instancia.pendentes.value;
    if (_erroApi == null) return null;
    final partes = <String>[
      _erroApi!,
      if (_salvoEm != null)
        'Mostrando os dados salvos em ${formatarSalvoEm(_salvoEm!)}.',
      if (pendentes > 0)
        pendentes == 1
            ? '1 envio aguardando internet.'
            : '$pendentes envios aguardando internet.',
    ];
    return partes.join(' ');
  }

  // Troque os debugPrint pela navegação real quando tiver as rotas.
  void _acao(String nome) => debugPrint('[BOTÃO] $nome');

  /// Abre a tela de corrida e recarrega a home se a atividade for salva.
  Future<void> _abrirCorrida({
    required String titulo,
    required String subtitulo,
  }) async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CorridaScreen(titulo: titulo, subtitulo: subtitulo),
      ),
    );
    if (salvou == true && mounted) _carregar();
  }

  /// Troca de aba pela barra inferior (ou por botões como "Ver plano").
  void _irParaAba(int i) {
    if (i == _abaAtual) return;
    setState(() => _abaAtual = i);
    // Ao voltar para o Início, atualiza a semana e os km.
    if (i == 0) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Cores.fundo,
      // IndexedStack mantém cada aba viva: ao trocar de aba e voltar,
      // a rolagem e os dados carregados continuam onde estavam.
      body: Stack(
        children: [
          IndexedStack(
            index: _abaAtual,
            children: [
              _abaInicio(),
              const TreinosScreen(),
              const EvolucaoScreen(),
              const PerfilScreen(),
            ],
          ),
          // Bolinha de erro de conexão (só na aba Início)
          if (_erroConexao != null && _abaAtual == 0)
            Positioned(
              right: 16,
              bottom: 16,
              child: _AvisoConexao(
                mensagem: _erroConexao!,
                onTentarDeNovo: _carregar,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _BarraInferior(
        indiceAtual: _abaAtual,
        onSelecionar: _irParaAba,
      ),
    );
  }

  /// Conteúdo da aba Início (a home que já existia).
  Widget _abaInicio() {
    if (_carregando) {
      return Center(child: CircularProgressIndicator(color: _Cores.escuro));
    }

    final dados = _dados;
    // Primeiro nome de quem se cadastrou (salvo no Firebase Auth)
    final nomeExibido =
        _primeiroNome(FirebaseAuth.instance.currentUser?.displayName);

    return RefreshIndicator(
      color: _Cores.escuro,
      onRefresh: _carregar,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cabecalho(
                usuario: nomeExibido,
                temNotificacao: dados.temNotificacao,
                onNotificacoes: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificacoesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              if (dados.treinoHoje != null)
                _TreinoHojeCard(
                  treino: dados.treinoHoje!,
                  onComecar: () => _abrirCorrida(
                    titulo: dados.treinoHoje!.titulo,
                    subtitulo: 'TREINO DE HOJE',
                  ),
                )
              else
                _TreinoVazioCard(
                  onTreinarMesmoAssim: () => _abrirCorrida(
                    titulo: 'Corrida livre',
                    subtitulo: 'TREINO LIVRE',
                  ),
                ),
              const SizedBox(height: 24),
              _SemanaCard(semana: dados.semana),
              if (dados.proximoTreino != null) ...[
                const SizedBox(height: 24),
                _ProximoTreinoSecao(
                  treino: dados.proximoTreino!,
                  onVerPlano: () => _irParaAba(1),
                  onTreino: () => _abrirCorrida(
                    titulo: dados.proximoTreino!.nome,
                    subtitulo: 'PRÓXIMO TREINO',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _ExplorarCard(
                onTap: () async {
                  final salvou = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const RotasScreen()),
                  );
                  if (salvou == true && mounted) _carregar();
                },
              ),
              if (dados.treinador != null) ...[
                const SizedBox(height: 24),
                _TreinadorCard(
                  treinador: dados.treinador!,
                  onFalar: () => _acao('Falar com o treinador'),
                ),
              ],
              const SizedBox(height: 24),
              _EmergenciaCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergenciaScreen()),
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
// CABEÇALHO
// =============================================================================

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.usuario,
    required this.temNotificacao,
    required this.onNotificacoes,
  });

  final String usuario;
  final bool temNotificacao;
  final VoidCallback onNotificacoes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RUNNER',
                style: TextStyle(
                  color: _Cores.verde,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Olá, $usuario',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _Cores.escuro,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: _Cores.card,
          shape: CircleBorder(side: BorderSide(color: _Cores.borda)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onNotificacoes,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      color: _Cores.escuro, size: 22),
                  if (temNotificacao)
                    Positioned(
                      top: 9,
                      right: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _Cores.destaque,
                          shape: BoxShape.circle,
                          border: Border.all(color: _Cores.card, width: 1.5),
                        ),
                      ),
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

// =============================================================================
// TREINO DE HOJE
// =============================================================================

class _TreinoHojeCard extends StatelessWidget {
  const _TreinoHojeCard({required this.treino, required this.onComecar});

  final TreinoHoje treino;
  final VoidCallback onComecar;

  static const _imagemPadrao =
      'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?q=80&w=1000&auto=format&fit=crop';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        color: _Cores.superficie,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                treino.imagemUrl ?? _imagemPadrao,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (context, erro, stack) => const SizedBox.shrink(),
              ),
            ),
            // Degradê: escuro à esquerda (texto) -> foto aparecendo à direita
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _Cores.tinta.withValues(alpha: 0.92),
                      _Cores.tinta.withValues(alpha: 0.55),
                      _Cores.tinta.withValues(alpha: 0.15),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _Cores.destaque,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 14, color: _Cores.tinta),
                        SizedBox(width: 4),
                        Text(
                          'TREINO DE HOJE',
                          style: TextStyle(
                            color: _Cores.tinta,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.6,
                    child: Text(
                      treino.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    treino.detalhes,
                    style:
                        const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: onComecar,
                    icon: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: _Cores.destaque,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: _Cores.tinta, size: 16),
                    ),
                    label: Text(
                      'Começar treino',
                      style: TextStyle(
                        color: _Cores.escuro,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Cores.card,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
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

class _TreinoVazioCard extends StatelessWidget {
  const _TreinoVazioCard({required this.onTreinarMesmoAssim});

  /// Chamado ao tocar em "Treinar mesmo assim" (treino livre, sem personal).
  final VoidCallback onTreinarMesmoAssim;

  static const _imagemPadrao =
      'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?q=80&w=1000&auto=format&fit=crop';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        color: _Cores.superficie,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                _imagemPadrao,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (context, erro, stack) => const SizedBox.shrink(),
              ),
            ),
            // Degradê: escuro à esquerda (texto) -> foto aparecendo à direita
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _Cores.tinta.withValues(alpha: 0.94),
                      _Cores.tinta.withValues(alpha: 0.65),
                      _Cores.tinta.withValues(alpha: 0.25),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _Cores.destaque,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 14, color: _Cores.tinta),
                        SizedBox(width: 4),
                        Text(
                          'TREINO DE HOJE',
                          style: TextStyle(
                            color: _Cores.tinta,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.65,
                    child: Text(
                      'Nenhum treino para hoje',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(right: 60),
                    child: Text(
                      'Não tem treino marcado ou ainda não tem um treinador? '
                      'Corra do seu jeito e registre sua atividade.',
                      style: TextStyle(
                          color: Color(0xFFD1D5DB), fontSize: 14, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: onTreinarMesmoAssim,
                    icon: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: _Cores.destaque,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: _Cores.tinta, size: 16),
                    ),
                    label: Text(
                      'Treinar mesmo assim',
                      style: TextStyle(
                        color: _Cores.escuro,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Cores.card,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
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

// =============================================================================
// SUA SEMANA
// =============================================================================

class _SemanaCard extends StatelessWidget {
  const _SemanaCard({required this.semana});

  final ResumoSemana semana;

  static const _letras = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    // Segunda-feira da semana atual (os números dos dias agora são reais)
    final segunda =
        DateTime(hoje.year, hoje.month, hoje.day - (hoje.weekday - 1));
    final progresso = (semana.percentual / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUA SEMANA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _Cores.textoSecundario,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Consistência é o ritmo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _Cores.escuro,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '${semana.totalConcluidos} de ${semana.metaDias}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _Cores.escuro,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _Cores.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _Cores.borda),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: List.generate(7, (i) {
                  final data =
                      DateTime(segunda.year, segunda.month, segunda.day + i);
                  final ehHoje = data.year == hoje.year &&
                      data.month == hoje.month &&
                      data.day == hoje.day;
                  return Expanded(
                    child: _DiaItem(
                      letra: _letras[i],
                      numero: '${data.day}',
                      concluido: semana.diaConcluido(data, i),
                      hoje: ehHoje,
                    ),
                  );
                }),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: _Cores.borda),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _modoEscuro
                          ? const Color(0xFF2E3A12)
                          : const Color(0xFFEEF9C9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.trending_up_rounded,
                        color: _Cores.escuro, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatarKm(semana.km)} km percorridos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _Cores.escuro,
                          ),
                        ),
                        Text(
                          'Meta semanal: ${_formatarKm(semana.metaKm)} km',
                          style: TextStyle(
                              color: _Cores.textoSecundario, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${semana.percentual}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _Cores.escuro,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progresso,
                  backgroundColor: _Cores.cinzaClaro,
                  color: _Cores.destaque,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiaItem extends StatelessWidget {
  const _DiaItem({
    required this.letra,
    required this.numero,
    required this.concluido,
    required this.hoje,
  });

  final String letra;
  final String numero;
  final bool concluido;
  final bool hoje;

  @override
  Widget build(BuildContext context) {
    final Color fundo = concluido
        ? _Cores.destaque
        : (hoje ? _Cores.superficie : _Cores.cinzaClaro);

    final circulo = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: fundo, shape: BoxShape.circle),
      child: Center(
        child: concluido
            ? const Icon(Icons.check, size: 16, color: _Cores.tinta)
            : Text(
                numero,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hoje ? Colors.white : _Cores.textoSecundario,
                ),
              ),
      ),
    );

    return Column(
      children: [
        Text(
          letra,
          style: TextStyle(
            fontSize: 11,
            color: _Cores.textoSecundario,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        // Caixa de tamanho fixo: o anel do "hoje" não desloca os outros dias
        SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: hoje
                ? Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _Cores.destaque, width: 2),
                    ),
                    child: circulo,
                  )
                : circulo,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PRÓXIMOS TREINOS
// =============================================================================

class _ProximoTreinoSecao extends StatelessWidget {
  const _ProximoTreinoSecao({
    required this.treino,
    required this.onVerPlano,
    required this.onTreino,
  });

  final ProximoTreino treino;
  final VoidCallback onVerPlano;
  final VoidCallback onTreino;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Próximos treinos',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _Cores.escuro),
            ),
            TextButton(
              onPressed: onVerPlano,
              style: TextButton.styleFrom(
                foregroundColor: _Cores.escuro,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Ver plano',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CardPressionavel(
          onTap: onTreino,
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _Cores.superficie,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_run_rounded,
                    color: _Cores.destaque),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            treino.dia.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _Cores.textoSecundario,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (treino.tipo != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '•  ${treino.tipo!.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _Cores.verde,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      treino.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _Cores.escuro,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      treino.resumo,
                      style: TextStyle(
                          fontSize: 12, color: _Cores.textoSecundario),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 22, color: _Cores.escuro),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card branco que ganha borda verde-limão enquanto está sendo pressionado.
class _CardPressionavel extends StatefulWidget {
  const _CardPressionavel({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_CardPressionavel> createState() => _CardPressionavelState();
}

class _CardPressionavelState extends State<_CardPressionavel> {
  bool _pressionado = false;

  void _definir(bool valor) {
    if (_pressionado != valor) setState(() => _pressionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _definir(true),
      onTapUp: (_) => _definir(false),
      onTapCancel: () => _definir(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _Cores.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressionado ? _Cores.destaque : _Cores.borda,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

// =============================================================================
// EXPLORE SUA CIDADE
// =============================================================================

class _ExplorarCard extends StatelessWidget {
  const _ExplorarCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          color: _Cores.superficie,
          child: Stack(
            children: [
              const Positioned.fill(
                  child: CustomPaint(painter: _RotaPainter())),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _Cores.destaque,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.route_rounded,
                          color: _Cores.tinta, size: 20),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'EXPLORE SUA CIDADE',
                      style: TextStyle(
                        color: _Cores.destaque,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Rotas e descobertas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.only(right: 100),
                      child: Text(
                        'Escolha onde correr ou siga sem rota definida.',
                        style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: CircleAvatar(
                  backgroundColor: _Cores.card,
                  radius: 20,
                  child: Icon(Icons.arrow_forward_rounded,
                      color: _Cores.escuro, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desenha o mapa decorativo: linhas finas ao fundo + rota principal em verde.
class _RotaPainter extends CustomPainter {
  const _RotaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fino = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final linhas = [
      [
        Offset(w * 0.58, 0),
        Offset(w * 0.68, h * 0.28),
        Offset(w * 0.85, h * 0.40),
        Offset(w, h * 0.52)
      ],
      [
        Offset(w * 0.52, h * 0.95),
        Offset(w * 0.72, h * 0.62),
        Offset(w * 0.90, h * 0.20),
        Offset(w, h * 0.08)
      ],
      [
        Offset(w * 0.75, 0),
        Offset(w * 0.82, h * 0.22),
        Offset(w * 0.98, h * 0.30)
      ],
      [Offset(w * 0.62, h), Offset(w * 0.80, h * 0.82), Offset(w, h * 0.72)],
    ];
    for (final pontos in linhas) {
      final path = Path()..moveTo(pontos.first.dx, pontos.first.dy);
      for (final p in pontos.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, fino);
    }

    const corRota = Color(0xFF5B7A2B);
    final rota = Paint()
      ..color = corRota
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final inicio = Offset(w * 0.60, h * 0.70);
    final meio1 = Offset(w * 0.77, h * 0.64);
    final meio2 = Offset(w * 0.87, h * 0.43);
    final fim = Offset(w * 0.96, h * 0.53);

    final caminho = Path()
      ..moveTo(inicio.dx, inicio.dy)
      ..lineTo(meio1.dx, meio1.dy)
      ..lineTo(meio2.dx, meio2.dy)
      ..lineTo(fim.dx, fim.dy);
    canvas.drawPath(caminho, rota);

    canvas.drawCircle(inicio, 6, Paint()..color = corRota);
    canvas.drawCircle(
      fim,
      7,
      Paint()
        ..color = corRota
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// TREINADOR
// =============================================================================

class _TreinadorCard extends StatelessWidget {
  const _TreinadorCard({required this.treinador, required this.onFalar});

  final Treinador treinador;
  final VoidCallback onFalar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Cores.cardTreinador,
        borderRadius: BorderRadius.circular(24),
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
                    backgroundColor: _Cores.superficie,
                    child: Text(
                      treinador.iniciais,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (treinador.online)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: _Cores.destaque,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: _Cores.cardTreinador, width: 2),
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
                    Text(
                      'Seu treinador',
                      style: TextStyle(
                          color: _Cores.textoSecundario, fontSize: 12),
                    ),
                    Text(
                      treinador.nome,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _Cores.escuro,
                      ),
                    ),
                  ],
                ),
              ),
              if (treinador.status.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _Cores.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    treinador.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _Cores.escuro,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          if (treinador.mensagem.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              '“${treinador.mensagem}”',
              style: TextStyle(color: _Cores.escuro, fontSize: 15, height: 1.4),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onFalar,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
            label: const Text(
              'Falar com o treinador',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Cores.superficie,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
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
// EMERGÊNCIA
// =============================================================================

class _EmergenciaCard extends StatelessWidget {
  const _EmergenciaCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _Cores.vermelhoFundo,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: _Cores.vermelhoBorda.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _Cores.vermelho,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.gpp_maybe_outlined,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEGURANÇA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _modoEscuro
                          ? const Color(0xFFF87171)
                          : const Color(0xFFDC2626),
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Botão de emergência',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _Cores.escuro,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Envie sua localização ao contato de confiança',
                    style: TextStyle(
                        fontSize: 12,
                        color: _Cores.textoSecundario,
                        height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 22, color: _Cores.escuro),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BARRA INFERIOR (com o indicador verde-limão no topo do item ativo)
// =============================================================================

class _ItemAba {
  const _ItemAba(this.icone, this.iconeAtivo, this.rotulo);

  final IconData icone;
  final IconData iconeAtivo;
  final String rotulo;
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.indiceAtual, required this.onSelecionar});

  final int indiceAtual;
  final ValueChanged<int> onSelecionar;

  static const _itens = [
    _ItemAba(Icons.home_outlined, Icons.home_rounded, 'Início'),
    _ItemAba(
        Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Treinos'),
    _ItemAba(Icons.trending_up_rounded, Icons.trending_up_rounded, 'Evolução'),
    _ItemAba(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Cores.card,
        border: Border(top: BorderSide(color: _Cores.borda)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_itens.length, (i) {
              final item = _itens[i];
              final ativo = i == indiceAtual;
              final cor = ativo ? _Cores.escuro : _Cores.textoSecundario;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelecionar(i),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 26,
                          height: 3,
                          decoration: BoxDecoration(
                            color: ativo ? _Cores.destaque : Colors.transparent,
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(3)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(ativo ? item.iconeAtivo : item.icone,
                                color: cor, size: 24),
                            const SizedBox(height: 3),
                            Text(
                              item.rotulo,
                              style: TextStyle(
                                fontSize: 12,
                                color: cor,
                                fontWeight:
                                    ativo ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// AVISO DE CONEXÃO (bolinha vermelha que abre a mensagem)
// =============================================================================

class _AvisoConexao extends StatefulWidget {
  const _AvisoConexao({required this.mensagem, required this.onTentarDeNovo});

  final String mensagem;
  final Future<void> Function() onTentarDeNovo;

  @override
  State<_AvisoConexao> createState() => _AvisoConexaoState();
}

class _AvisoConexaoState extends State<_AvisoConexao>
    with SingleTickerProviderStateMixin {
  bool _aberto = false;
  bool _tentando = false;

  // Pulso suave em volta da bolinha para chamar atenção.
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  void _alternar(bool abrir) {
    HapticFeedback.selectionClick();
    setState(() => _aberto = abrir);
  }

  Future<void> _tentar() async {
    setState(() => _tentando = true);
    await Sincronizador.instancia.sincronizar(imediato: true);
    await widget.onTentarDeNovo();
    if (mounted) setState(() => _tentando = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (filho, anim) => ScaleTransition(
        scale: anim,
        alignment: Alignment.bottomRight,
        child: FadeTransition(opacity: anim, child: filho),
      ),
      child: _aberto ? _cartao() : _bolinha(),
    );
  }

  Widget _bolinha() {
    return GestureDetector(
      key: const ValueKey('bolinha'),
      onTap: () => _alternar(true),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulso,
              builder: (_, __) => Container(
                width: 28 + 28 * _pulso.value,
                height: 28 + 28 * _pulso.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _Cores.vermelho
                      .withValues(alpha: 0.35 * (1 - _pulso.value)),
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _Cores.vermelho,
                shape: BoxShape.circle,
                border: Border.all(color: _Cores.card, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: _Cores.vermelho.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Colors.white, size: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartao() {
    final largura = math.min(MediaQuery.of(context).size.width - 32, 320.0);
    return Container(
      key: const ValueKey('cartao'),
      width: largura,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: _Cores.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Cores.vermelho.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _Cores.vermelho.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded,
                color: _Cores.vermelho, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  'Sem conexão',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _Cores.escuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.mensagem,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: _Cores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _tentando ? null : _tentar,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _tentando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _Cores.vermelho),
                          )
                        : const Text(
                            'Tentar de novo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _Cores.vermelho,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _alternar(false),
            tooltip: 'Fechar',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded,
                size: 20, color: _Cores.textoSecundario),
          ),
        ],
      ),
    );
  }
}
