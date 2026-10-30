import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'emergencia.dart';
import '../services/preferencia.dart';

// =============================================================================
// CORES (acompanham o tema claro/escuro)
// =============================================================================

const _destaque = Color(0xFFD0FD38);
const _vermelho = Color(0xFFEF4444);

/// Paleta da tela, calculada a partir do tema atual.
class _Paleta {
  const _Paleta(this.escuro);

  factory _Paleta.of(BuildContext context) =>
      _Paleta(Theme.of(context).brightness == Brightness.dark);

  final bool escuro;

  Color get fundo => escuro ? const Color(0xFF111311) : const Color(0xFFF6F7F4);
  Color get card => escuro ? const Color(0xFF1C1F1B) : Colors.white;
  Color get borda => escuro ? const Color(0xFF2C302A) : const Color(0xFFE5E7EB);
  Color get divisor =>
      escuro ? const Color(0xFF262A24) : const Color(0xFFF0F1F2);
  Color get texto => escuro ? const Color(0xFFF3F4F6) : const Color(0xFF1A1A1A);
  Color get textoSecundario =>
      escuro ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  // Fundo dos ícones
  Color get iconeNeutro =>
      escuro ? const Color(0xFF2A2E28) : const Color(0xFFF3F4F6);
  Color get iconeVerde =>
      escuro ? const Color(0xFF2E3A12) : const Color(0xFFEEF9C9);
  Color get iconeVermelho =>
      escuro ? const Color(0xFF3A1D1D) : const Color(0xFFFEF2F2);
  Color get corIconeVerde => escuro ? _destaque : const Color(0xFF1A1A1A);

  // Seletor segmentado
  Color get segmentoFundo =>
      escuro ? const Color(0xFF252923) : const Color(0xFFF1F2F0);
  Color get segmentoAtivo => escuro ? const Color(0xFF3A3F37) : Colors.white;

  // Interruptor
  Color get trilhoLigado =>
      escuro ? const Color(0xFF2E3A12) : const Color(0xFF1A1A1A);
}

/// Troque pela versão real (ou use o pacote package_info_plus).
const _versaoApp = '1.0.0';

String _iniciais(String nome) {
  final partes =
      nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first[0].toUpperCase();
  return (partes.first[0] + partes.last[0]).toUpperCase();
}

String _dataHora(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(l.day)}/${dois(l.month)}/${l.year} às '
      '${dois(l.hour)}:${dois(l.minute)}';
}

// =============================================================================
// TELA
// =============================================================================

/// Tela de configurações da conta.
///
/// Ao fechar, devolve `true` se algo do perfil mudou (ex.: o nome),
/// para a tela de perfil se atualizar.
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _prefs = Preferencias.instancia;

  bool _alterou = false;
  bool _ocupado = false;

  User? get _usuario => FirebaseAuth.instance.currentUser;

  String get _nome {
    final n = _usuario?.displayName?.trim();
    return (n == null || n.isEmpty) ? 'Atleta' : n;
  }

  /// A conta foi criada com e-mail e senha (e não Google, Apple...)?
  bool get _temSenha =>
      _usuario?.providerData.any((p) => p.providerId == 'password') ?? false;

  String get _metodoEntrada {
    final ids = _usuario?.providerData.map((p) => p.providerId).toSet() ?? {};
    if (ids.contains('google.com')) return 'Conta Google';
    if (ids.contains('apple.com')) return 'Conta Apple';
    if (ids.contains('password')) return 'E-mail e senha';
    if (ids.contains('phone')) return 'Telefone';
    return '—';
  }

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_atualizar);
  }

  @override
  void dispose() {
    _prefs.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  void _voltar() => Navigator.pop(context, _alterou);

  void _aviso(String texto, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor: erro ? _vermelho : null,
      ));
  }

  // ---------------------------------------------------------------------------
  // CONTA
  // ---------------------------------------------------------------------------

  Future<void> _abrirDadosPessoais() async {
    final paleta = _Paleta.of(context);
    final resultado = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: paleta.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _FolhaDadosPessoais(
        nome: _nome,
        email: _usuario?.email,
        telefone: _prefs.telefone,
      ),
    );
    if (resultado == null || !mounted) return;
    final (nome, telefone) = resultado;

    setState(() => _ocupado = true);
    try {
      if (nome.isNotEmpty && nome != _nome) {
        await _usuario?.updateDisplayName(nome);
        await _usuario?.reload();
        _alterou = true;
      }
      if (telefone != _prefs.telefone) {
        await _prefs.definirTelefone(telefone);
      }
      _aviso('Dados atualizados.');
    } catch (e) {
      debugPrint('[CONFIG] Erro ao salvar dados: $e');
      _aviso('Não foi possível salvar seus dados.', erro: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _abrirSeguranca() async {
    final paleta = _Paleta.of(context);
    final redefinir = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: paleta.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _FolhaSeguranca(
        metodo: _metodoEntrada,
        ultimoAcesso: _dataHora(_usuario?.metadata.lastSignInTime),
        contaCriada: _dataHora(_usuario?.metadata.creationTime),
        podeRedefinirSenha: _temSenha,
      ),
    );
    if (redefinir == true && mounted) await _redefinirSenha();
  }

  Future<void> _redefinirSenha() async {
    final email = _usuario?.email;
    if (email == null) return;

    final confirmar = await _confirmar(
      titulo: 'Redefinir senha?',
      texto: 'Vamos enviar um link para $email com as instruções.',
      acao: 'Enviar link',
    );
    if (!confirmar || !mounted) return;

    setState(() => _ocupado = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _aviso('Link enviado. Confira sua caixa de entrada.');
    } catch (e) {
      debugPrint('[CONFIG] Erro ao enviar redefinição: $e');
      _aviso('Não foi possível enviar o e-mail agora.', erro: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVACIDADE
  // ---------------------------------------------------------------------------

  /// Ao ligar, pede a permissão de localização do celular.
  Future<void> _alternarLocalizacao(bool ligar) async {
    if (!ligar) {
      await _prefs.definirLocalizacaoEmergencia(false);
      return;
    }
    try {
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.deniedForever) {
        _aviso('Localização bloqueada. Libere nas configurações do celular.',
            erro: true);
        await Geolocator.openAppSettings();
        return;
      }
      if (permissao == LocationPermission.denied) {
        _aviso('Sem permissão, não é possível compartilhar a localização.',
            erro: true);
        return;
      }
      await _prefs.definirLocalizacaoEmergencia(true);
    } catch (e) {
      debugPrint('[CONFIG] Erro de permissão: $e');
      _aviso('Não foi possível verificar a permissão.', erro: true);
    }
  }

  void _abrirContatoEmergencia() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergenciaScreen()),
    );
  }

  // ---------------------------------------------------------------------------
  // OUTROS
  // ---------------------------------------------------------------------------

  void _sobre() {
    showAboutDialog(
      context: context,
      applicationName: 'Runner',
      applicationVersion: _versaoApp,
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.directions_run_rounded, color: _destaque),
      ),
    );
  }

  Future<void> _sair() async {
    final confirmar = await _confirmar(
      titulo: 'Sair da conta?',
      texto: 'Você precisará entrar novamente para usar o app.',
      acao: 'Sair',
      perigo: true,
    );
    if (!confirmar || !mounted) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    // Volta para a primeira tela do app (login / verificação de sessão).
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (rota) => false);
  }

  Future<bool> _confirmar({
    required String titulo,
    required String texto,
    required String acao,
    bool perigo = false,
  }) async {
    final paleta = _Paleta.of(context);
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: paleta.card,
        title: Text(titulo, style: TextStyle(color: paleta.texto)),
        content: Text(texto, style: TextStyle(color: paleta.textoSecundario)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: paleta.texto)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: perigo ? _vermelho : const Color(0xFF1A1A1A),
              foregroundColor: perigo ? Colors.white : _destaque,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(acao),
          ),
        ],
      ),
    );
    return r == true;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final paleta = _Paleta.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltar();
      },
      child: Scaffold(
        backgroundColor: paleta.fundo,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _Topo(onVoltar: _voltar),
                  Divider(height: 1, color: paleta.borda),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      children: [
                        _CardConta(nome: _nome, email: _usuario?.email),
                        const SizedBox(height: 24),

                        // ---------------- CONTA ----------------
                        _Secao(
                          titulo: 'CONTA',
                          filhos: [
                            _Linha(
                              icone: Icons.person_outline_rounded,
                              tom: _Tom.neutro,
                              titulo: 'Dados pessoais',
                              subtitulo: 'Nome, e-mail e telefone',
                              onTap: _abrirDadosPessoais,
                            ),
                            _Linha(
                              icone: Icons.lock_outline_rounded,
                              tom: _Tom.neutro,
                              titulo: 'Senha e segurança',
                              subtitulo: 'Senha e acessos ativos',
                              onTap: _abrirSeguranca,
                            ),
                          ],
                        ),

                        // ---------------- APARÊNCIA ----------------
                        _Secao(
                          titulo: 'APARÊNCIA',
                          filhos: [
                            _BlocoEscolha<ThemeMode>(
                              titulo: 'Tema do app',
                              subtitulo: 'Claro, escuro ou igual ao celular',
                              valor: _prefs.tema,
                              opcoes: const [
                                (
                                  ThemeMode.light,
                                  'Claro',
                                  Icons.light_mode_outlined
                                ),
                                (
                                  ThemeMode.dark,
                                  'Escuro',
                                  Icons.dark_mode_outlined
                                ),
                                (
                                  ThemeMode.system,
                                  'Sistema',
                                  Icons.phone_android_rounded
                                ),
                              ],
                              onChanged: (m) {
                                HapticFeedback.selectionClick();
                                _prefs.definirTema(m);
                              },
                            ),
                          ],
                        ),

                        // ---------------- NOTIFICAÇÕES ----------------
                        _Secao(
                          titulo: 'NOTIFICAÇÕES',
                          filhos: [
                            _Linha(
                              icone: Icons.calendar_today_outlined,
                              tom: _Tom.verde,
                              titulo: 'Lembretes de treino',
                              subtitulo: 'Avisos antes de cada atividade',
                              interruptor: _prefs.lembretesTreino,
                              onInterruptor: _prefs.definirLembretesTreino,
                            ),
                            _Linha(
                              icone: Icons.chat_bubble_outline_rounded,
                              tom: _Tom.verde,
                              titulo: 'Mensagens do treinador',
                              subtitulo: 'Orientações e ajustes no plano',
                              interruptor: _prefs.mensagensTreinador,
                              onInterruptor: _prefs.definirMensagensTreinador,
                            ),
                          ],
                        ),

                        // ---------------- TREINOS ----------------
                        _Secao(
                          titulo: 'TREINOS',
                          filhos: [
                            _BlocoEscolha<UnidadeDistancia>(
                              titulo: 'Unidade de distância',
                              subtitulo: 'Usada nos treinos e relatórios',
                              valor: _prefs.unidade,
                              opcoes: const [
                                (UnidadeDistancia.km, 'Quilômetros', null),
                                (UnidadeDistancia.milhas, 'Milhas', null),
                              ],
                              onChanged: (u) {
                                HapticFeedback.selectionClick();
                                _prefs.definirUnidade(u);
                              },
                            ),
                          ],
                        ),

                        // ---------------- PRIVACIDADE ----------------
                        _Secao(
                          titulo: 'PRIVACIDADE E SEGURANÇA',
                          filhos: [
                            _Linha(
                              icone: Icons.gpp_maybe_outlined,
                              tom: _Tom.vermelho,
                              titulo: 'Localização de emergência',
                              subtitulo: 'Compartilhar durante alertas',
                              interruptor: _prefs.localizacaoEmergencia,
                              onInterruptor: _alternarLocalizacao,
                            ),
                            _Linha(
                              icone: Icons.contact_phone_outlined,
                              tom: _Tom.vermelho,
                              titulo: 'Contato de emergência',
                              subtitulo: 'Quem recebe o alerta',
                              onTap: _abrirContatoEmergencia,
                            ),
                          ],
                        ),

                        // ---------------- SOBRE ----------------
                        _Secao(
                          titulo: 'SOBRE',
                          filhos: [
                            _Linha(
                              icone: Icons.info_outline_rounded,
                              tom: _Tom.neutro,
                              titulo: 'Sobre o Runner',
                              subtitulo: 'Versão $_versaoApp',
                              onTap: _sobre,
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),
                        _BotaoSair(onTap: _sair),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_ocupado)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x55000000),
                  child: Center(
                      child: CircularProgressIndicator(color: _destaque)),
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

enum _Tom { neutro, verde, vermelho }

class _Topo extends StatelessWidget {
  const _Topo({required this.onVoltar});

  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          Material(
            color: p.card,
            shape: CircleBorder(side: BorderSide(color: p.borda)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onVoltar,
              child: SizedBox(
                width: 44,
                height: 44,
                child:
                    Icon(Icons.chevron_left_rounded, color: p.texto, size: 26),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Configurações',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.texto,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _CardConta extends StatelessWidget {
  const _CardConta({required this.nome, required this.email});

  final String nome;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _destaque,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _iniciais(nome),
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    )),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Título da seção + card branco com as linhas separadas por divisores.
class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.filhos});

  final String titulo;
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(titulo,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: p.textoSecundario,
                  letterSpacing: 1.3,
                )),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: p.borda),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < filhos.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: p.divisor),
                  filhos[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha com ícone, título, subtítulo e uma seta OU um interruptor.
class _Linha extends StatelessWidget {
  const _Linha({
    required this.icone,
    required this.tom,
    required this.titulo,
    required this.subtitulo,
    this.onTap,
    this.interruptor,
    this.onInterruptor,
  });

  final IconData icone;
  final _Tom tom;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;

  /// Se não for nulo, mostra um interruptor no lugar da seta.
  final bool? interruptor;
  final ValueChanged<bool>? onInterruptor;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final (fundoIcone, corIcone) = switch (tom) {
      _Tom.neutro => (p.iconeNeutro, p.texto),
      _Tom.verde => (p.iconeVerde, p.corIconeVerde),
      _Tom.vermelho => (p.iconeVermelho, _vermelho),
    };
    final temInterruptor = interruptor != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            temInterruptor ? () => onInterruptor?.call(!interruptor!) : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: fundoIcone,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icone, size: 20, color: corIcone),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: p.texto,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5, color: p.textoSecundario)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (temInterruptor)
                _Interruptor(
                  ligado: interruptor!,
                  onChanged: (v) => onInterruptor?.call(v),
                )
              else
                Icon(Icons.chevron_right_rounded, size: 22, color: p.texto),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interruptor no estilo do app: trilho escuro e bolinha verde-limão.
class _Interruptor extends StatelessWidget {
  const _Interruptor({required this.ligado, required this.onChanged});

  final bool ligado;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Semantics(
      toggled: ligado,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!ligado);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 52,
          height: 30,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ligado ? p.trilhoLigado : p.borda,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: ligado ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: ligado ? _destaque : Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloco com título + seletor segmentado (Tema, Unidade de distância).
class _BlocoEscolha<T> extends StatelessWidget {
  const _BlocoEscolha({
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.opcoes,
    required this.onChanged,
  });

  final String titulo;
  final String subtitulo;
  final T valor;
  final List<(T, String, IconData?)> opcoes;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final achado = opcoes.indexWhere((o) => o.$1 == valor);
    final indice = achado < 0 ? 0 : achado;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: p.texto,
              )),
          const SizedBox(height: 2),
          Text(subtitulo,
              style: TextStyle(fontSize: 12.5, color: p.textoSecundario)),
          const SizedBox(height: 14),
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.segmentoFundo,
              borderRadius: BorderRadius.circular(14),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final largura = c.maxWidth / opcoes.length;
                return Stack(
                  children: [
                    // "Pílula" que desliza até a opção escolhida
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: largura * indice,
                      top: 0,
                      bottom: 0,
                      width: largura,
                      child: Container(
                        decoration: BoxDecoration(
                          color: p.segmentoAtivo,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: p.escuro
                              ? null
                              : const [
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final (v, rotulo, icone) in opcoes)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onChanged(v),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (icone != null) ...[
                                      Icon(icone,
                                          size: 16,
                                          color: v == valor
                                              ? p.texto
                                              : p.textoSecundario),
                                      const SizedBox(width: 6),
                                    ],
                                    Flexible(
                                      child: Text(
                                        rotulo,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: v == valor
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: v == valor
                                              ? p.texto
                                              : p.textoSecundario,
                                        ),
                                      ),
                                    ),
                                  ],
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
          ),
        ],
      ),
    );
  }
}

class _BotaoSair extends StatelessWidget {
  const _BotaoSair({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    return Material(
      color: p.iconeVermelho,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: const SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: _vermelho, size: 20),
              SizedBox(width: 8),
              Text('Sair da conta',
                  style: TextStyle(
                    color: _vermelho,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// FOLHAS (cada uma é dona dos seus controllers — evita usá-los após dispose)
// =============================================================================

class _AlcaFolha extends StatelessWidget {
  const _AlcaFolha();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: _Paleta.of(context).borda,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

InputDecoration _decoracaoCampo(BuildContext context, String rotulo,
    {String? dica}) {
  final p = _Paleta.of(context);
  OutlineInputBorder borda(Color cor, [double largura = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cor, width: largura),
      );
  return InputDecoration(
    labelText: rotulo,
    hintText: dica,
    labelStyle: TextStyle(color: p.textoSecundario),
    hintStyle: TextStyle(color: p.textoSecundario),
    filled: true,
    fillColor: p.fundo,
    border: borda(p.borda),
    enabledBorder: borda(p.borda),
    focusedBorder: borda(p.escuro ? _destaque : const Color(0xFF1A1A1A), 1.5),
  );
}

/// Folha "Dados pessoais": devolve (nome, telefone) ao salvar.
class _FolhaDadosPessoais extends StatefulWidget {
  const _FolhaDadosPessoais({
    required this.nome,
    required this.email,
    required this.telefone,
  });

  final String nome;
  final String? email;
  final String telefone;

  @override
  State<_FolhaDadosPessoais> createState() => _FolhaDadosPessoaisState();
}

class _FolhaDadosPessoaisState extends State<_FolhaDadosPessoais> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.nome);
  late final _telefone = TextEditingController(text: widget.telefone);

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, (_nome.text.trim(), _telefone.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);
    final estiloCampo = TextStyle(color: p.texto);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AlcaFolha(),
            const SizedBox(height: 18),
            Text('Dados pessoais',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: p.texto)),
            const SizedBox(height: 4),
            Text('É assim que você aparece no app e para o treinador.',
                style: TextStyle(fontSize: 13, color: p.textoSecundario)),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nome,
              style: estiloCampo,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _decoracaoCampo(context, 'Nome'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefone,
              style: estiloCampo,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _salvar(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d+()\-\s]')),
              ],
              decoration: _decoracaoCampo(context, 'Telefone (opcional)',
                  dica: '(81) 99999-9999'),
              validator: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return d.isNotEmpty && d.length < 10
                    ? 'Telefone inválido'
                    : null;
              },
            ),
            if (widget.email != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: p.fundo,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.borda),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('E-mail',
                              style: TextStyle(
                                  fontSize: 12, color: p.textoSecundario)),
                          const SizedBox(height: 2),
                          Text(widget.email!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, color: p.texto)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copiar e-mail',
                      icon: Icon(Icons.copy_rounded,
                          size: 18, color: p.textoSecundario),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.email!));
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('E-mail copiado.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                  'O e-mail é o da sua conta de acesso e não pode ser '
                  'alterado aqui.',
                  style: TextStyle(fontSize: 12, color: p.textoSecundario)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: _destaque,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Salvar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Folha "Senha e segurança". Devolve `true` se o usuário pedir para
/// redefinir a senha.
class _FolhaSeguranca extends StatelessWidget {
  const _FolhaSeguranca({
    required this.metodo,
    required this.ultimoAcesso,
    required this.contaCriada,
    required this.podeRedefinirSenha,
  });

  final String metodo;
  final String ultimoAcesso;
  final String contaCriada;
  final bool podeRedefinirSenha;

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.of(context);

    Widget info(IconData icone, String rotulo, String valor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.iconeNeutro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, size: 19, color: p.texto),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rotulo,
                        style:
                            TextStyle(fontSize: 12, color: p.textoSecundario)),
                    const SizedBox(height: 2),
                    Text(valor,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: p.texto)),
                  ],
                ),
              ),
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
            const _AlcaFolha(),
            const SizedBox(height: 18),
            Text('Senha e segurança',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: p.texto)),
            const SizedBox(height: 12),
            info(Icons.key_outlined, 'Forma de entrada', metodo),
            info(Icons.history_rounded, 'Último acesso neste aparelho',
                ultimoAcesso),
            info(
                Icons.event_available_outlined, 'Conta criada em', contaCriada),
            const SizedBox(height: 16),
            if (podeRedefinirSenha)
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.lock_reset_rounded, size: 20),
                label: const Text('Redefinir senha',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: _destaque,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              )
            else
              Text(
                'Você entra com $metodo, então a senha é gerenciada por ele.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.textoSecundario),
              ),
          ],
        ),
      ),
    );
  }
}
