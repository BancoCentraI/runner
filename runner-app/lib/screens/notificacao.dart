import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/offline.dart';

// =============================================================================
// CORES
// =============================================================================

/// Paleta lida do tema atual (`Theme.of(context)`): quando o usuário troca
/// entre claro e escuro, o Flutter redesenha a tela sozinho.
class _Cores {
  const _Cores._(this.modoEscuro);

  factory _Cores.of(BuildContext context) =>
      _Cores._(Theme.of(context).brightness == Brightness.dark);

  final bool modoEscuro;

  // Fixas (iguais nos dois temas)
  static const destaque = Color(0xFFD0FD38);
  static const tinta = Color(0xFF1A1A1A); // texto/ícone sobre verde-limão
  static const vermelho = Color(0xFFEF4444);

  Color get escuro =>
      modoEscuro ? const Color(0xFFF3F4F6) : const Color(0xFF1A1A1A);
  Color get textoSecundario =>
      modoEscuro ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get fundo =>
      modoEscuro ? const Color(0xFF111311) : const Color(0xFFF9FAFB);
  Color get card => modoEscuro ? const Color(0xFF1C1F1B) : Colors.white;
  Color get cinzaClaro =>
      modoEscuro ? const Color(0xFF252923) : const Color(0xFFF3F4F6);
  Color get borda =>
      modoEscuro ? const Color(0xFF2C302A) : const Color(0xFFE5E7EB);
  Color get destaqueSuave =>
      modoEscuro ? const Color(0xFF232B12) : const Color(0xFFF7FDE0);
  Color get verde =>
      modoEscuro ? const Color(0xFF9BC27A) : const Color(0xFF386641);
  Color get cardTreinador =>
      modoEscuro ? const Color(0xFF1E2620) : const Color(0xFFE8EDE9);
  Color get amareloFundo =>
      modoEscuro ? const Color(0xFF3A2E12) : const Color(0xFFFEF3C7);
  Color get amarelo =>
      modoEscuro ? const Color(0xFFFBBF24) : const Color(0xFFB45309);

  /// Superfícies escuras (card de resumo, ícone de treino).
  Color get superficie =>
      modoEscuro ? const Color(0xFF262A23) : const Color(0xFF1A1A1A);

  /// Botão claro dentro do card escuro de resumo.
  Color get botaoResumo => modoEscuro ? const Color(0xFF353A31) : Colors.white;
}

// =============================================================================
// MODELO
// =============================================================================

String? _toStr(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

enum TipoNotificacao { treino, treinador, conquista, lembrete, sistema }

TipoNotificacao _tipoDe(String? valor) {
  switch (valor?.toLowerCase()) {
    case 'treino':
      return TipoNotificacao.treino;
    case 'treinador':
      return TipoNotificacao.treinador;
    case 'conquista':
      return TipoNotificacao.conquista;
    case 'lembrete':
      return TipoNotificacao.lembrete;
    default:
      return TipoNotificacao.sistema;
  }
}

class Notificacao {
  const Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    required this.data,
    required this.lida,
  });

  final String id;
  final TipoNotificacao tipo;
  final String titulo;
  final String mensagem;
  final DateTime data;
  final bool lida;

  Notificacao copyWith({bool? lida}) => Notificacao(
        id: id,
        tipo: tipo,
        titulo: titulo,
        mensagem: mensagem,
        data: data,
        lida: lida ?? this.lida,
      );

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    final titulo = _toStr(json['titulo']) ?? 'Notificação';
    final data =
        DateTime.tryParse(_toStr(json['data'] ?? json['criadaEm']) ?? '')
                ?.toLocal() ??
            DateTime.now();

    return Notificacao(
      id: _toStr(json['id']) ?? '${titulo}_${data.millisecondsSinceEpoch}',
      tipo: _tipoDe(_toStr(json['tipo'])),
      titulo: titulo,
      mensagem: _toStr(json['mensagem']) ?? '',
      data: data,
      lida: json['lida'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.name,
        'titulo': titulo,
        'mensagem': mensagem,
        'data': data.toUtc().toIso8601String(),
        'lida': lida,
      };
}

// =============================================================================
// CACHE (salvo no aparelho)
// =============================================================================

class NotificacoesCache {
  /// Separado por usuário: quem entrar depois não vê as notificações de outro.
  static String get _chave =>
      'notificacoes_cache_v1_${FirebaseAuth.instance.currentUser?.uid ?? 'anonimo'}';

  static Future<void> salvar(List<Notificacao> itens) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _chave,
        json.encode({'itens': itens.map((n) => n.toJson()).toList()}),
      );
    } catch (e) {
      debugPrint('[CACHE] Erro ao salvar: $e');
    }
  }

  static Future<List<Notificacao>> ler() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_chave);
      if (texto == null) return [];

      final corpo = json.decode(texto);
      final lista = corpo is Map<String, dynamic> ? corpo['itens'] : null;
      if (lista is! List) return [];

      return lista
          .whereType<Map<String, dynamic>>()
          .map(Notificacao.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[CACHE] Erro ao ler: $e');
      return [];
    }
  }

  /// Chame ao fazer logout, para o próximo usuário não ver notificações antigas.
  static Future<void> limpar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chave);
    } catch (e) {
      debugPrint('[CACHE] Erro ao limpar: $e');
    }
  }
}

// =============================================================================
// SERVIÇO DE API
// =============================================================================

class _NotificacoesApi {
  /// GET /notificacoes  ->  lista direta OU { "notificacoes": [...] }
  /// Lança exceção se a API falhar (a tela continua com o que tem salvo).
  static Future<List<Notificacao>> listar() async {
    final r = await ApiOffline.buscar('/notificacoes',
        cache: 'notificacoes', timeout: const Duration(seconds: 8));
    if (r.erro != null) throw Exception(r.erro);

    final corpo = r.dados;
    final lista = corpo is List
        ? corpo
        : (corpo is Map ? (corpo['notificacoes'] ?? corpo['itens']) : null);
    if (lista is! List) throw const FormatException('Formato inesperado');

    return lista
        .whereType<Map<String, dynamic>>()
        .map(Notificacao.fromJson)
        .toList();
  }

  static String _caminhoLida(String id) => '/notificacoes/$id/lida';
  static String _caminhoExcluir(String id) => '/notificacoes/$id';

  /// Coloca na fila offline (salva no aparelho) sem esperar o envio.
  static Future<void> marcarLida(String id) => FilaOffline.instancia.adicionar(
      metodo: 'PATCH', caminho: _caminhoLida(id), substitui: 'notif-lida-$id');

  static Future<void> excluir(String id) => FilaOffline.instancia.adicionar(
      metodo: 'DELETE',
      caminho: _caminhoExcluir(id),
      substitui: 'notif-excluir-$id');

  /// Envia o que estiver na fila (respeitando o limite de ritmo).
  static void enviarAgora() =>
      Sincronizador.instancia.sincronizar(imediato: true);

  /// Ids marcados como lidos / excluídos que ainda não chegaram na API.
  static Set<String> lidasPendentes() => FilaOffline.instancia
      .caminhos('PATCH')
      .map((c) => RegExp(r'^/notificacoes/(.+)/lida$').firstMatch(c)?.group(1))
      .whereType<String>()
      .toSet();

  static Set<String> excluidasPendentes() => FilaOffline.instancia
      .caminhos('DELETE')
      .map((c) => RegExp(r'^/notificacoes/([^/]+)$').firstMatch(c)?.group(1))
      .whereType<String>()
      .toSet();
}

// =============================================================================
// AUXILIARES
// =============================================================================

String _tempoRelativo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  if (diff.inDays < 7) return 'há ${diff.inDays} d';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

String _rotuloGrupo(DateTime d) {
  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(d.year, d.month, d.day);
  final diff = hoje.difference(dia).inDays;
  if (diff <= 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  if (diff < 7) return 'Esta semana';
  return 'Anteriores';
}

// =============================================================================
// TELA
// =============================================================================

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  bool _carregando = true;
  bool _atualizando = false;
  List<Notificacao> _lista = [];

  int get _naoLidas => _lista.where((n) => !n.lida).length;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  /// Mostra o que está salvo no aparelho na hora e atualiza em seguida.
  Future<void> _iniciar() async {
    final cache = await NotificacoesCache.ler();
    if (!mounted) return;

    if (cache.isNotEmpty) {
      setState(() {
        _lista = cache;
        _carregando = false;
      });
    }
    await _carregar();
  }

  /// Qualquer falha aqui é silenciosa: o usuário continua vendo o que já tem.
  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() {
      if (_lista.isEmpty) {
        _carregando = true;
      } else {
        _atualizando = true;
      }
    });

    try {
      final dados = await _NotificacoesApi.listar();
      if (!mounted) return;

      // Ações feitas sem internet (ainda na fila) continuam valendo.
      final lidas = _NotificacoesApi.lidasPendentes();
      final excluidas = _NotificacoesApi.excluidasPendentes();
      final atualizada = dados
          .where((n) => !excluidas.contains(n.id))
          .map((n) => lidas.contains(n.id) ? n.copyWith(lida: true) : n)
          .toList();

      setState(() => _lista = atualizada);
      NotificacoesCache.salvar(atualizada);
    } catch (e) {
      debugPrint('[API] Notificações indisponíveis agora: $e');
    }

    if (!mounted) return;
    setState(() {
      _carregando = false;
      _atualizando = false;
    });
  }

  void _persistir() => NotificacoesCache.salvar(_lista);

  Future<void> _marcarLida(Notificacao n) async {
    if (n.lida) return;
    final i = _lista.indexWhere((e) => e.id == n.id);
    if (i < 0) return;

    setState(() => _lista[i] = n.copyWith(lida: true));
    _persistir();

    await _NotificacoesApi.marcarLida(n.id);
    _NotificacoesApi.enviarAgora();
  }

  Future<void> _marcarTodasLidas() async {
    final naoLidas = _lista.where((n) => !n.lida).map((n) => n.id).toList();
    if (naoLidas.isEmpty) return;

    setState(() => _lista = _lista.map((n) => n.copyWith(lida: true)).toList());
    _persistir();

    for (final id in naoLidas) {
      await _NotificacoesApi.marcarLida(id);
    }
    _NotificacoesApi.enviarAgora();
  }

  Future<void> _excluir(Notificacao n) async {
    setState(() => _lista.removeWhere((e) => e.id == n.id));
    _persistir();

    await _NotificacoesApi.excluir(n.id);
    _NotificacoesApi.enviarAgora();
  }

  List<Object> _itensVisiveis() {
    final filtradas = List<Notificacao>.of(_lista)
      ..sort((a, b) => b.data.compareTo(a.data));

    final itens = <Object>[];
    String? ultimo;
    for (final n in filtradas) {
      final grupo = _rotuloGrupo(n.data);
      if (grupo != ultimo) {
        itens.add(grupo);
        ultimo = grupo;
      }
      itens.add(n);
    }
    return itens;
  }

  @override
  Widget build(BuildContext context) {
    final c = _Cores.of(context);
    return Scaffold(
      backgroundColor: c.fundo,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child:
                  _Cabecalho(onVoltar: () => Navigator.of(context).maybePop()),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: _atualizando ? 15 : 0,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _atualizando
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: c.escuro,
                        backgroundColor: c.cinzaClaro,
                      ),
                    )
                  : null,
            ),
            if (!_carregando) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _ResumoCard(
                    naoLidas: _naoLidas, onMarcarTodas: _marcarTodasLidas),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(child: _conteudo()),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) return const _Esqueleto();

    final c = _Cores.of(context);
    final itens = _itensVisiveis();

    return RefreshIndicator(
      color: c.escuro,
      backgroundColor: c.card,
      onRefresh: _carregar,
      child: itens.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  20, 40, 20, MediaQuery.of(context).padding.bottom + 8),
              children: const [_EstadoVazio()],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(context).padding.bottom + 8),
              itemCount: itens.length,
              itemBuilder: (context, i) {
                final item = itens[i];

                if (item is String) {
                  return Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 12, bottom: 12),
                    child: Text(
                      item.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.textoSecundario,
                        letterSpacing: 1,
                      ),
                    ),
                  );
                }

                final n = item as Notificacao;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _Entrada(
                    key: ValueKey('entrada_${n.id}'),
                    child: Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: _Cores.vermelho,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => _excluir(n),
                      child: _NotificacaoCard(
                          notificacao: n, onTap: () => _marcarLida(n)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Pequena animação de entrada (fade + leve subida) para os cards.
class _Entrada extends StatelessWidget {
  const _Entrada({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child:
            Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
      ),
      child: child,
    );
  }
}

// =============================================================================
// CABEÇALHO
// =============================================================================

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.onVoltar});

  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    final c = _Cores.of(context);
    return Row(
      children: [
        Material(
          color: c.card,
          shape: CircleBorder(side: BorderSide(color: c.borda)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onVoltar,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: c.escuro, size: 18),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CENTRAL',
                style: TextStyle(
                  color: c.verde,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Notificações',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: c.escuro,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// CARD DE RESUMO
// =============================================================================

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({required this.naoLidas, required this.onMarcarTodas});

  final int naoLidas;
  final VoidCallback onMarcarTodas;

  @override
  Widget build(BuildContext context) {
    final c = _Cores.of(context);
    final temNovas = naoLidas > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          color: c.superficie,
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _Cores.destaque.withValues(alpha: 0.18),
                        width: 2),
                  ),
                ),
              ),
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _Cores.destaque.withValues(alpha: 0.28),
                        width: 2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _Cores.destaque,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            temNovas
                                ? Icons.notifications_active_rounded
                                : Icons.check_rounded,
                            size: 14,
                            color: _Cores.tinta,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            temNovas ? 'NOVAS' : 'EM DIA',
                            style: const TextStyle(
                              color: _Cores.tinta,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      temNovas
                          ? (naoLidas == 1
                              ? '1 notificação\nnão lida'
                              : '$naoLidas notificações\nnão lidas')
                          : 'Tudo em dia',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (temNovas) ...[
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: onMarcarTodas,
                        icon: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: _Cores.destaque,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.done_all_rounded,
                              color: _Cores.tinta, size: 14),
                        ),
                        label: Text(
                          'Marcar todas como lidas',
                          style: TextStyle(
                            color: c.escuro,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.botaoResumo,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                      ),
                    ],
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
// CARD DE NOTIFICAÇÃO
// =============================================================================

class _NotificacaoCard extends StatelessWidget {
  const _NotificacaoCard({required this.notificacao, required this.onTap});

  final Notificacao notificacao;
  final VoidCallback onTap;

  ({IconData icone, Color fundo, Color cor, String rotulo}) _estilo(_Cores c) {
    switch (notificacao.tipo) {
      case TipoNotificacao.treino:
        return (
          icone: Icons.directions_run_rounded,
          fundo: c.superficie,
          cor: _Cores.destaque,
          rotulo: 'TREINO',
        );
      case TipoNotificacao.treinador:
        return (
          icone: Icons.chat_bubble_outline_rounded,
          fundo: c.cardTreinador,
          cor: c.escuro,
          rotulo: 'TREINADOR',
        );
      case TipoNotificacao.conquista:
        return (
          icone: Icons.emoji_events_outlined,
          fundo: _Cores.destaque,
          cor: _Cores.tinta,
          rotulo: 'CONQUISTA',
        );
      case TipoNotificacao.lembrete:
        return (
          icone: Icons.alarm_rounded,
          fundo: c.amareloFundo,
          cor: c.amarelo,
          rotulo: 'LEMBRETE',
        );
      case TipoNotificacao.sistema:
        return (
          icone: Icons.info_outline_rounded,
          fundo: c.cinzaClaro,
          cor: c.textoSecundario,
          rotulo: 'SISTEMA',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _Cores.of(context);
    final estilo = _estilo(c);
    final lida = notificacao.lida;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: lida ? c.card : c.destaqueSuave,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lida ? c.borda : _Cores.destaque, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: estilo.fundo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(estilo.icone, color: estilo.cor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _tempoRelativo(notificacao.data),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: c.textoSecundario,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!lida) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: c.superficie,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _Cores.destaque, width: 1.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notificacao.titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: lida ? FontWeight.w600 : FontWeight.bold,
                          color: c.escuro,
                        ),
                      ),
                      if (notificacao.mensagem.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          notificacao.mensagem,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textoSecundario,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ESTADO VAZIO E CARREGANDO
// =============================================================================

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    final c = _Cores.of(context);
    return Column(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _Cores.destaque.withValues(alpha: 0.5), width: 2),
                ),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: c.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.borda),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration:
                    BoxDecoration(color: c.superficie, shape: BoxShape.circle),
                child: const Icon(Icons.notifications_none_rounded,
                    color: _Cores.destaque, size: 28),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Tudo tranquilo por aqui',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: c.escuro),
        ),
        const SizedBox(height: 6),
        Text(
          'Quando houver novidades, elas aparecem aqui.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: c.textoSecundario, height: 1.4),
        ),
      ],
    );
  }
}

/// Esqueleto pulsante exibido só no primeiro carregamento, sem nada salvo.
class _Esqueleto extends StatefulWidget {
  const _Esqueleto();

  @override
  State<_Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<_Esqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacidade = Tween<double>(begin: 0.45, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _barra(_Cores c, double largura, double altura) => Container(
        width: largura,
        height: altura,
        decoration: BoxDecoration(
          color: c.cinzaClaro,
          borderRadius: BorderRadius.circular(8),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = _Cores.of(context);
    return FadeTransition(
      opacity: _opacidade,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        itemCount: 5,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.borda),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.cinzaClaro,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _barra(c, 70, 10),
                    const SizedBox(height: 8),
                    _barra(c, double.infinity, 14),
                    const SizedBox(height: 6),
                    _barra(c, 160, 12),
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
