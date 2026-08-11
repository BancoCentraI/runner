import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// =============================================================================
// CORES
// =============================================================================

class _Cores {
  static const escuro = Color(0xFF1A1A1A);
  static const destaque = Color(0xFFD0FD38);
  static const textoSecundario = Color(0xFF6B7280);
  static const fundo = Color(0xFFF9FAFB);
  static const cinzaClaro = Color(0xFFF3F4F6);
  static const borda = Color(0xFFE5E7EB);
  static const verde = Color(0xFF386641);
  static const vermelho = Color(0xFFEF4444);
  static const vermelhoFundo = Color(0xFFFEF2F2);
  static const vermelhoBorda = Color(0xFFFCA5A5);
  static const cardTreinador = Color(0xFFE8EDE9);
}

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
  final texto = v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return texto.replaceAll('.', ',');
}

class TreinoHoje {
  const TreinoHoje({required this.titulo, required this.detalhes, this.imagemUrl});

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
  const ProximoTreino({required this.dia, this.tipo, required this.nome, required this.resumo});

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
  const Treinador({required this.nome, required this.status, required this.mensagem});

  final String nome;
  final String status;
  final String mensagem;

  bool get online => status.toUpperCase() == 'ONLINE';

  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
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
  /// Busca os dados da home. Se a API falhar, devolve tudo vazio (nada é inventado).
  static Future<HomeData> buscar() async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://sua-api.com';
      final response = await http
          .get(Uri.parse('$baseUrl/home-dados'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // utf8.decode evita acentos quebrados (ex.: "EvoluÃ§Ã£o")
        final corpo = json.decode(utf8.decode(response.bodyBytes));
        if (corpo is Map<String, dynamic>) {
          debugPrint('[API] Dados da home carregados com sucesso.');
          return HomeData.fromJson(corpo);
        }
      }
      debugPrint('[API] Resposta inesperada (${response.statusCode}).');
    } catch (e) {
      debugPrint('[API] Erro ao conectar na API: $e');
    }
    return const HomeData();
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

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final dados = await _HomeApi.buscar();
    if (!mounted) return; // evita setState com a tela já fechada
    setState(() {
      _dados = dados;
      _carregando = false;
    });
  }

  // Troque os debugPrint pela navegação real quando tiver as rotas.
  void _acao(String nome) => debugPrint('[BOTÃO] $nome');

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: _Cores.fundo,
        body: Center(child: CircularProgressIndicator(color: _Cores.escuro)),
      );
    }

    final dados = _dados;

    return Scaffold(
      backgroundColor: _Cores.fundo,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cabecalho(
                usuario: dados.nomeUsuario,
                temNotificacao: dados.temNotificacao,
                onNotificacoes: () => _acao('Notificações'),
                onPerfil: () => _acao('Avatar Perfil'),
              ),
              const SizedBox(height: 20),
              if (dados.treinoHoje != null)
                _TreinoHojeCard(
                  treino: dados.treinoHoje!,
                  onComecar: () => _acao('Começar treino: ${dados.treinoHoje!.titulo}'),
                )
              else
                _TreinoVazioCard(
                  onTreinarMesmoAssim: () => _acao('Treino livre'),
                ),
              const SizedBox(height: 24),
              _SemanaCard(semana: dados.semana),
              if (dados.proximoTreino != null) ...[
                const SizedBox(height: 24),
                _ProximoTreinoSecao(
                  treino: dados.proximoTreino!,
                  onVerPlano: () => _acao('Ver plano completo'),
                  onTreino: () => _acao('Próximo treino: ${dados.proximoTreino!.nome}'),
                ),
              ],
              const SizedBox(height: 24),
              _ExplorarCard(onTap: () => _acao('Rotas e descobertas')),
              if (dados.treinador != null) ...[
                const SizedBox(height: 24),
                _TreinadorCard(
                  treinador: dados.treinador!,
                  onFalar: () => _acao('Falar com o treinador'),
                ),
              ],
              const SizedBox(height: 24),
              _EmergenciaCard(onTap: () => _acao('Botão de emergência')),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BarraInferior(
        indiceAtual: _abaAtual,
        onSelecionar: (i) {
          setState(() => _abaAtual = i);
          _acao('Aba inferior: $i');
        },
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
    required this.onPerfil,
  });

  final String usuario;
  final bool temNotificacao;
  final VoidCallback onNotificacoes;
  final VoidCallback onPerfil;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
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
                style: const TextStyle(
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
          color: Colors.white,
          shape: const CircleBorder(side: BorderSide(color: _Cores.borda)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onNotificacoes,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: _Cores.escuro, size: 22),
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
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onPerfil,
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: _Cores.escuro, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
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
        color: _Cores.escuro,
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
                      _Cores.escuro.withValues(alpha: 0.92),
                      _Cores.escuro.withValues(alpha: 0.55),
                      _Cores.escuro.withValues(alpha: 0.15),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _Cores.destaque,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 14, color: _Cores.escuro),
                        SizedBox(width: 4),
                        Text(
                          'TREINO DE HOJE',
                          style: TextStyle(
                            color: _Cores.escuro,
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
                    style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
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
                      child: const Icon(Icons.play_arrow_rounded, color: _Cores.escuro, size: 16),
                    ),
                    label: const Text(
                      'Começar treino',
                      style: TextStyle(
                        color: _Cores.escuro,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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
        color: _Cores.escuro,
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
                      _Cores.escuro.withValues(alpha: 0.94),
                      _Cores.escuro.withValues(alpha: 0.65),
                      _Cores.escuro.withValues(alpha: 0.25),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _Cores.destaque,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 14, color: _Cores.escuro),
                        SizedBox(width: 4),
                        Text(
                          'TREINO DE HOJE',
                          style: TextStyle(
                            color: _Cores.escuro,
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
                    widthFactor: 0.65,
                    child: const Text(
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
                      style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14, height: 1.4),
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
                      child: const Icon(Icons.play_arrow_rounded, color: _Cores.escuro, size: 16),
                    ),
                    label: const Text(
                      'Treinar mesmo assim',
                      style: TextStyle(
                        color: _Cores.escuro,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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
    final segunda = DateTime(hoje.year, hoje.month, hoje.day - (hoje.weekday - 1));
    final progresso = (semana.percentual / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
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
                style: const TextStyle(
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
            color: Colors.white,
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
                  final data = DateTime(segunda.year, segunda.month, segunda.day + i);
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: _Cores.borda),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF9C9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: _Cores.escuro, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatarKm(semana.km)} km percorridos',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _Cores.escuro,
                          ),
                        ),
                        Text(
                          'Meta semanal: ${_formatarKm(semana.metaKm)} km',
                          style: const TextStyle(color: _Cores.textoSecundario, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${semana.percentual}%',
                    style: const TextStyle(
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
        : (hoje ? _Cores.escuro : _Cores.cinzaClaro);

    final circulo = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: fundo, shape: BoxShape.circle),
      child: Center(
        child: concluido
            ? const Icon(Icons.check, size: 16, color: _Cores.escuro)
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
          style: const TextStyle(
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
            const Text(
              'Próximos treinos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _Cores.escuro),
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
                  color: _Cores.escuro,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_run_rounded, color: _Cores.destaque),
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
                            style: const TextStyle(
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
                            style: const TextStyle(
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _Cores.escuro,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      treino.resumo,
                      style: const TextStyle(fontSize: 12, color: _Cores.textoSecundario),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 22, color: _Cores.escuro),
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
          color: Colors.white,
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
          color: _Cores.escuro,
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: _RotaPainter())),
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
                      child: const Icon(Icons.route_rounded, color: _Cores.escuro, size: 20),
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
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 20,
                bottom: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(Icons.arrow_forward_rounded, color: _Cores.escuro, size: 18),
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
      [Offset(w * 0.58, 0), Offset(w * 0.68, h * 0.28), Offset(w * 0.85, h * 0.40), Offset(w, h * 0.52)],
      [Offset(w * 0.52, h * 0.95), Offset(w * 0.72, h * 0.62), Offset(w * 0.90, h * 0.20), Offset(w, h * 0.08)],
      [Offset(w * 0.75, 0), Offset(w * 0.82, h * 0.22), Offset(w * 0.98, h * 0.30)],
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
                    backgroundColor: _Cores.escuro,
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
                          border: Border.all(color: _Cores.cardTreinador, width: 2),
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
                    const Text(
                      'Seu treinador',
                      style: TextStyle(color: _Cores.textoSecundario, fontSize: 12),
                    ),
                    Text(
                      treinador.nome,
                      style: const TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    treinador.status.toUpperCase(),
                    style: const TextStyle(
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
              style: const TextStyle(color: _Cores.escuro, fontSize: 15, height: 1.4),
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
              backgroundColor: _Cores.escuro,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          border: Border.all(color: _Cores.vermelhoBorda.withValues(alpha: 0.5)),
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
              child: const Icon(Icons.gpp_maybe_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEGURANÇA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
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
                    style: TextStyle(fontSize: 12, color: _Cores.textoSecundario, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 22, color: _Cores.escuro),
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
    _ItemAba(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Treino'),
    _ItemAba(Icons.trending_up_rounded, Icons.trending_up_rounded, 'Evolução'),
    _ItemAba(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(ativo ? item.iconeAtivo : item.icone, color: cor, size: 24),
                            const SizedBox(height: 3),
                            Text(
                              item.rotulo,
                              style: TextStyle(
                                fontSize: 12,
                                color: cor,
                                fontWeight: ativo ? FontWeight.w600 : FontWeight.w500,
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