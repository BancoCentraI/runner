import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Ajuste o caminho relativo se necessário

/// Modelo de aviso exibido em um cartão dentro da tela.
/// Pode ter um botão de ação opcional (ex.: "Esqueci minha senha").
class _Aviso {
  const _Aviso({
    required this.icone,
    required this.titulo,
    required this.mensagem,
    required this.cor,
    required this.fundo,
    this.acaoTexto,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String mensagem;
  final Color cor;
  final Color fundo;
  final String? acaoTexto;
  final VoidCallback? acao;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _kDarkColor = Color(0xFF1A1A1A);
  static const _kAccentColor = Color(0xFFD0FD38);
  static const _kBorderColor = Color(0xFFE5E7EB);
  static const _kSubtextColor = Color(0xFF6B7280);
  static const _kErrorColor = Color(0xFFEF4444);
  static const _kErrorBgColor = Color(0xFFFEF2F2);
  static const _kWarnColor = Color(0xFFD97706);
  static const _kWarnBgColor = Color(0xFFFFFBEB);

  // Cores que mudam com o tema. Lidas de Theme.of(context), então a tela
  // se redesenha sozinha quando o usuário troca entre claro e escuro.
  bool get _escuro => Theme.of(context).brightness == Brightness.dark;
  Color get _corFundo =>
      _escuro ? const Color(0xFF111311) : const Color(0xFFF9FAFB);
  Color get _corTexto => _escuro ? const Color(0xFFF3F4F6) : _kDarkColor;
  Color get _corSubtexto => _escuro ? const Color(0xFF9CA3AF) : _kSubtextColor;
  Color get _corBorda => _escuro ? const Color(0xFF2C302A) : _kBorderColor;
  Color get _corCampo => _escuro ? const Color(0xFF1C1F1B) : Colors.white;
  Color get _corRotulo =>
      _escuro ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
  Color get _corCorpo =>
      _escuro ? const Color(0xFFB0B5BD) : const Color(0xFF4B5563);
  Color get _corDica =>
      _escuro ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
  Color get _corCirculo =>
      _escuro ? const Color(0xFF2E3A12) : const Color(0xFFE2F1A7);
  Color get _corErroFundo => _escuro ? const Color(0xFF2A1616) : _kErrorBgColor;

  // Botão principal: escuro no tema claro, verde-limão no tema escuro.
  Color get _corBotao => _escuro ? _kAccentColor : _kDarkColor;
  Color get _corTextoBotao => _escuro ? _kDarkColor : Colors.white;

  /// Fundo dos cartões de aviso: no escuro vira um tom translúcido da cor.
  Color _fundoAviso(Color cor, Color fundoClaro) =>
      _escuro ? cor.withValues(alpha: 0.12) : fundoClaro;

  // Quantas tentativas erradas antes do bloqueio temporário
  static const int _maxTentativas = 5;

  // Tempo máximo esperando o servidor responder
  static const Duration _tempoLimite = Duration(seconds: 20);

  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  final ValueNotifier<bool> _lembrarDeMimNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _ocultarSenhaNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _carregandoNotifier = ValueNotifier<bool>(false);

  // null = sem erro | '' = campo vermelho sem mensagem | texto = campo vermelho + mensagem
  final ValueNotifier<String?> _emailErroNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<String?> _senhaErroNotifier =
      ValueNotifier<String?>(null);

  // Contadores que disparam a animação de "balançar"
  final ValueNotifier<int> _emailShakeNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _senhaShakeNotifier = ValueNotifier<int>(0);

  // Cartão de aviso geral
  final ValueNotifier<_Aviso?> _avisoNotifier = ValueNotifier<_Aviso?>(null);

  // Proteção contra spam de tentativas
  final ValueNotifier<int> _segundosRestantesNotifier = ValueNotifier<int>(0);
  Timer? _timerBloqueio;
  int _bloqueioTotal = 30;
  int _falhas = 0;
  int _nivelBloqueio = 0;

  @override
  void initState() {
    super.initState();
    _carregarDadosSalvos();

    // Some com o erro assim que o TEXTO muda (mover o cursor não conta)
    var ultimoEmail = _emailController.text;
    _emailController.addListener(() {
      if (_emailController.text == ultimoEmail) return;
      ultimoEmail = _emailController.text;
      _emailErroNotifier.value = null;
      if (_senhaErroNotifier.value == '') _senhaErroNotifier.value = null;
      _avisoNotifier.value = null;
    });

    var ultimaSenha = _senhaController.text;
    _senhaController.addListener(() {
      if (_senhaController.text == ultimaSenha) return;
      ultimaSenha = _senhaController.text;
      _senhaErroNotifier.value = null;
      if (_emailErroNotifier.value == '') _emailErroNotifier.value = null;
      _avisoNotifier.value = null;
    });
  }

  Future<void> _carregarDadosSalvos() async {
    try {
      final emailSalvo = await _authService.carregarEmailLembrado();
      if (emailSalvo != null && emailSalvo.isNotEmpty && mounted) {
        _emailController.text = emailSalvo;
        _lembrarDeMimNotifier.value = true;
      }
    } catch (_) {
      // Se falhar ao ler o e-mail salvo, apenas segue sem preencher.
    }
  }

  @override
  void dispose() {
    _timerBloqueio?.cancel();
    _emailController.dispose();
    _senhaController.dispose();
    _lembrarDeMimNotifier.dispose();
    _ocultarSenhaNotifier.dispose();
    _carregandoNotifier.dispose();
    _emailErroNotifier.dispose();
    _senhaErroNotifier.dispose();
    _emailShakeNotifier.dispose();
    _senhaShakeNotifier.dispose();
    _avisoNotifier.dispose();
    _segundosRestantesNotifier.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navegação
  // ---------------------------------------------------------------------------

  void _irParaHome() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  void _irParaEsqueciSenha() {
    // Leva o e-mail digitado para facilitar (a tela pode ler em arguments).
    Navigator.of(context).pushNamed(
      '/forgot-password',
      arguments: _emailController.text.trim(),
    );
  }

  void _irParaCadastro() {
    Navigator.of(context).pushNamed('/register');
  }

  // ---------------------------------------------------------------------------
  // Validações locais
  // ---------------------------------------------------------------------------

  String? _validarEmail(String email) {
    if (email.isEmpty) return 'Digite seu e-mail para continuar';
    if (email.contains(' ')) return 'O e-mail não pode ter espaços';
    if (!email.contains('@')) return 'Faltou o "@" no e-mail';

    final partes = email.split('@');
    if (partes.length != 2)
      return 'E-mail inválido. Use algo como nome@email.com';
    if (partes[0].isEmpty) return 'Digite o nome antes do "@"';

    final dominio = partes[1];
    if (dominio.isEmpty || !dominio.contains('.') || dominio.endsWith('.')) {
      return 'Faltou o domínio depois do "@" (ex: gmail.com)';
    }

    final regex =
        RegExp(r'^[\w.+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(email))
      return 'E-mail inválido. Use algo como nome@email.com';
    return null;
  }

  String? _validarSenha(String senha) {
    if (senha.isEmpty) return 'Digite sua senha para continuar';
    if (senha.length < 6) return 'A senha precisa ter pelo menos 6 caracteres';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  Future<void> _handleLoginEmail() async {
    if (_segundosRestantesNotifier.value > 0 || _carregandoNotifier.value)
      return;

    FocusScope.of(context).unfocus();
    _avisoNotifier.value = null;

    final email = _emailController.text.trim();
    // Não usamos trim na senha: espaços podem fazer parte dela.
    final senha = _senhaController.text;

    final erroEmail = _validarEmail(email);
    final erroSenha = _validarSenha(senha);

    if (erroEmail != null || erroSenha != null) {
      if (erroEmail != null) _setErroEmail(erroEmail);
      if (erroSenha != null) _setErroSenha(erroSenha);
      return;
    }

    try {
      _carregandoNotifier.value = true;

      await _authService.loginComEmail(email, senha).timeout(_tempoLimite);

      _falhas = 0;
      _nivelBloqueio = 0;

      if (_lembrarDeMimNotifier.value) {
        await _authService.salvarEmailLembrado(email);
      } else {
        await _authService.limparEmailLembrado();
      }

      _irParaHome();
    } catch (e) {
      if (mounted) _tratarErroLoginEmail(e);
    } finally {
      if (mounted) _carregandoNotifier.value = false;
    }
  }

  Future<void> _handleLoginGoogle() async {
    if (_carregandoNotifier.value) return;

    _avisoNotifier.value = null;

    try {
      _carregandoNotifier.value = true;
      final user = await _authService.loginComGoogle().timeout(_tempoLimite);

      // user == null normalmente significa que a pessoa fechou a janela do Google
      if (user != null) _irParaHome();
    } catch (e) {
      if (mounted) _tratarErroGeral(e);
    } finally {
      if (mounted) _carregandoNotifier.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Tratamento de erros
  // ---------------------------------------------------------------------------

  void _setErroEmail(String mensagem) {
    _emailErroNotifier.value = mensagem;
    _emailShakeNotifier.value++;
  }

  void _setErroSenha(String mensagem) {
    _senhaErroNotifier.value = mensagem;
    _senhaShakeNotifier.value++;
  }

  /// Descobre o código do erro sem precisar importar o pacote do Firebase.
  String _extrairCodigo(Object e) {
    if (e is TimeoutException) return 'timeout';

    try {
      final code = (e as dynamic).code;
      if (code is String && code.isNotEmpty) return code;
    } catch (_) {}

    final texto = e.toString().toLowerCase();
    if (texto.contains('socketexception') ||
        texto.contains('failed host lookup')) {
      return 'network-request-failed';
    }

    const conhecidos = [
      'invalid-credential',
      'invalid-login-credentials',
      'wrong-password',
      'user-not-found',
      'invalid-email',
      'user-disabled',
      'too-many-requests',
      'network-request-failed',
      'sign_in_canceled',
      'popup-closed-by-user',
      'cancelled-popup-request',
      'account-exists-with-different-credential',
      'operation-not-allowed',
      'invalid-api-key',
      'app-not-authorized',
      'internal-error',
      'sign_in_failed',
      'timeout',
    ];
    for (final c in conhecidos) {
      if (texto.contains(c)) return c;
    }
    return 'desconhecido';
  }

  String _textoTentativas() {
    final restantes = _maxTentativas - _falhas;
    if (restantes <= 0 || restantes > 2) return '';
    return restantes == 1
        ? ' Resta 1 tentativa.'
        : ' Restam $restantes tentativas.';
  }

  /// Registra uma falha de credencial. Retorna true se isso disparou o bloqueio.
  bool _registrarFalha() {
    _falhas++;
    if (_falhas >= _maxTentativas) {
      _nivelBloqueio++;
      _bloquear(
          math.min(30 * _nivelBloqueio, 300)); // 30s, 60s, 90s... máx. 5 min
      return true;
    }
    return false;
  }

  void _bloquear(int segundos) {
    _timerBloqueio?.cancel();
    _bloqueioTotal = segundos;
    _avisoNotifier.value = null;
    _segundosRestantesNotifier.value = segundos;

    _timerBloqueio = Timer.periodic(const Duration(seconds: 1), (timer) {
      final restante = _segundosRestantesNotifier.value - 1;
      if (restante <= 0) {
        timer.cancel();
        _segundosRestantesNotifier.value = 0;
        _falhas = 0;
      } else {
        _segundosRestantesNotifier.value = restante;
      }
    });
  }

  void _mostrarAviso(_Aviso aviso) {
    _avisoNotifier.value = aviso;
  }

  void _tratarErroLoginEmail(Object e) {
    switch (_extrairCodigo(e)) {
      case 'invalid-email':
        _setErroEmail('E-mail inválido. Use algo como nome@email.com');
        break;

      case 'user-not-found':
        if (_registrarFalha()) return;
        _setErroEmail(
            'Não encontramos uma conta com esse e-mail.${_textoTentativas()}');
        break;

      case 'wrong-password':
        if (_registrarFalha()) return;
        _setErroSenha('Senha incorreta.${_textoTentativas()}');
        _mostrarAviso(_avisoSenhaIncorreta());
        break;

      // O Firebase atual devolve este código para e-mail OU senha errados
      // (de propósito, por segurança), então avisamos nos dois campos.
      case 'invalid-credential':
      case 'invalid-login-credentials':
        if (_registrarFalha()) return;
        _setErroEmail('');
        _setErroSenha('');
        _mostrarAviso(_avisoSenhaIncorreta());
        break;

      default:
        _tratarErroGeral(e);
    }
  }

  _Aviso _avisoSenhaIncorreta() {
    return _Aviso(
      icone: Icons.lock_person_outlined,
      titulo: 'E-mail ou senha incorretos',
      mensagem: 'Confira seus dados e tente novamente.${_textoTentativas()}',
      cor: _kErrorColor,
      fundo: _kErrorBgColor,
      acaoTexto: 'Esqueci minha senha',
      acao: _irParaEsqueciSenha,
    );
  }

  void _tratarErroGeral(Object e) {
    switch (_extrairCodigo(e)) {
      case 'sign_in_canceled':
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return; // pessoa fechou a janela do Google, não é erro

      case 'too-many-requests':
        _bloquear(60);
        break;

      case 'network-request-failed':
        _mostrarAviso(const _Aviso(
          icone: Icons.wifi_off_rounded,
          titulo: 'Sem conexão',
          mensagem: 'Verifique sua internet e tente novamente.',
          cor: _kWarnColor,
          fundo: _kWarnBgColor,
        ));
        break;

      case 'timeout':
        _mostrarAviso(const _Aviso(
          icone: Icons.timer_off_outlined,
          titulo: 'Demorou demais',
          mensagem:
              'O servidor não respondeu a tempo. Verifique sua conexão e tente de novo.',
          cor: _kWarnColor,
          fundo: _kWarnBgColor,
        ));
        break;

      case 'user-disabled':
        _mostrarAviso(const _Aviso(
          icone: Icons.block_rounded,
          titulo: 'Conta desativada',
          mensagem:
              'Essa conta está desativada. Fale com o suporte para reativar.',
          cor: _kErrorColor,
          fundo: _kErrorBgColor,
        ));
        break;

      case 'account-exists-with-different-credential':
        _mostrarAviso(const _Aviso(
          icone: Icons.alternate_email_rounded,
          titulo: 'Esse e-mail já tem cadastro',
          mensagem:
              'Já existe uma conta com esse e-mail usando outro método de login. '
              'Tente entrar com e-mail e senha.',
          cor: _kWarnColor,
          fundo: _kWarnBgColor,
        ));
        break;

      case 'operation-not-allowed':
      case 'invalid-api-key':
      case 'app-not-authorized':
      case 'internal-error':
      case 'sign_in_failed':
        // Erros de configuração/servidor: não é culpa de quem está logando.
        _mostrarAviso(const _Aviso(
          icone: Icons.cloud_off_rounded,
          titulo: 'Problema no nosso servidor',
          mensagem: 'Não conseguimos concluir o login por um erro interno. '
              'Não é problema com seus dados. Tente de novo em alguns minutos.',
          cor: _kErrorColor,
          fundo: _kErrorBgColor,
        ));
        debugPrint('Erro interno de login: $e');
        break;

      default:
        debugPrint('Erro de login não mapeado: $e');
        _mostrarAviso(const _Aviso(
          icone: Icons.error_outline_rounded,
          titulo: 'Algo deu errado',
          mensagem:
              'Não foi possível entrar agora. Tente novamente em instantes.',
          cor: _kErrorColor,
          fundo: _kErrorBgColor,
        ));
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _corFundo,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: RepaintBoundary(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _corCirculo.withValues(alpha: 0.8),
                    width: 50,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E211D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.directions_run_rounded,
                      color: _kAccentColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'SEU RITMO, SUA EVOLUÇÃO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8C8C8C),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bem-vindo de\nvolta.',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: _corTexto,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Entre para acompanhar seus treinos, falar com seu treinador e continuar evoluindo.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _corSubtexto,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildLabel('E-mail'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'seu@email.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    erroNotifier: _emailErroNotifier,
                    shakeNotifier: _emailShakeNotifier,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Senha'),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: _ocultarSenhaNotifier,
                    builder: (context, ocultarSenha, child) {
                      return _buildTextField(
                        controller: _senhaController,
                        hintText: 'Digite sua senha',
                        prefixIcon: Icons.lock_outline,
                        obscureText: ocultarSenha,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLoginEmail(),
                        erroNotifier: _senhaErroNotifier,
                        shakeNotifier: _senhaShakeNotifier,
                        suffixIcon: ExcludeFocus(
                          child: IconButton(
                            icon: Icon(
                              ocultarSenha
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _corSubtexto,
                            ),
                            onPressed: () => _ocultarSenhaNotifier.value =
                                !_ocultarSenhaNotifier.value,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _lembrarDeMimNotifier,
                        builder: (context, lembrarDeMim, child) {
                          return ExcludeFocus(
                            child: InkWell(
                              onTap: () => _lembrarDeMimNotifier.value =
                                  !_lembrarDeMimNotifier.value,
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: lembrarDeMim,
                                      activeColor: _corBotao,
                                      checkColor: _corTextoBotao,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      side: BorderSide(
                                          color: _escuro
                                              ? const Color(0xFF4B5563)
                                              : const Color(0xFFD1D5DB)),
                                      onChanged: (val) => _lembrarDeMimNotifier
                                          .value = val ?? false,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lembrar de mim',
                                    style: TextStyle(
                                        fontSize: 13, color: _corCorpo),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _irParaEsqueciSenha,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Esqueci minha senha',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _corTexto,
                              decoration: TextDecoration.underline,
                              decorationColor: _kAccentColor,
                              decorationThickness: 3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avisos: bloqueio por excesso de tentativas + erros gerais
                  _buildAvisos(),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ListenableBuilder(
                      listenable: Listenable.merge([
                        _carregandoNotifier,
                        _segundosRestantesNotifier,
                      ]),
                      builder: (context, child) {
                        final carregando = _carregandoNotifier.value;
                        final segundos = _segundosRestantesNotifier.value;
                        final bloqueado = segundos > 0;

                        return ElevatedButton(
                          onPressed: (carregando || bloqueado)
                              ? null
                              : _handleLoginEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _corBotao,
                            foregroundColor: _corTextoBotao,
                            disabledBackgroundColor:
                                _corBotao.withValues(alpha: 0.6),
                            disabledForegroundColor: _corTextoBotao,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: carregando
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: _corTextoBotao,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      bloqueado
                                          ? 'Tente de novo em ${segundos}s'
                                          : 'Entrar',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      bloqueado
                                          ? Icons.hourglass_bottom_rounded
                                          : Icons.chevron_right,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(child: Divider(color: _corBorda)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OU CONTINUE COM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _corSubtexto,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: _corBorda)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _carregandoNotifier,
                      builder: (context, carregando, child) {
                        return OutlinedButton(
                          onPressed: carregando ? null : _handleLoginGoogle,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _corCampo,
                            side: BorderSide(color: _corBorda),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _corTexto,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Entrar com Google',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _corTexto,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _irParaCadastro,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: RichText(
                          text: TextSpan(
                            text: 'Ainda não tem uma conta? ',
                            style: TextStyle(color: _corSubtexto, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Criar conta grátis',
                                style: TextStyle(
                                  color: _corTexto,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _corRotulo,
      ),
    );
  }

  /// Cartões de aviso acima do botão "Entrar".
  Widget _buildAvisos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bloqueio temporário por muitas tentativas
        ValueListenableBuilder<int>(
          valueListenable: _segundosRestantesNotifier,
          builder: (context, segundos, _) {
            return AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: segundos > 0
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildBloqueioCard(segundos),
                    )
                  : const SizedBox(width: double.infinity),
            );
          },
        ),

        // Erros gerais (credenciais, sem internet, erro interno etc.)
        ValueListenableBuilder<_Aviso?>(
          valueListenable: _avisoNotifier,
          builder: (context, aviso, _) {
            return AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: aviso == null
                    ? const SizedBox(
                        key: ValueKey('sem-aviso'), width: double.infinity)
                    : Padding(
                        key: ValueKey('${aviso.titulo}|${aviso.mensagem}'),
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildAvisoCard(aviso),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIconeAviso(IconData icone, Color cor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icone, color: cor, size: 20),
    );
  }

  Widget _buildBotaoAcao(String texto, Color cor, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                texto,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cor,
                  decoration: TextDecoration.underline,
                  decorationColor: cor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 16, color: cor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvisoCard(_Aviso aviso) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _fundoAviso(aviso.cor, aviso.fundo),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: aviso.cor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: aviso.cor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconeAviso(aviso.icone, aviso.cor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aviso.titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: aviso.cor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aviso.mensagem,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: _corCorpo,
                  ),
                ),
                if (aviso.acao != null && aviso.acaoTexto != null)
                  _buildBotaoAcao(aviso.acaoTexto!, aviso.cor, aviso.acao!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloqueioCard(int segundos) {
    final progresso = (segundos / _bloqueioTotal).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _fundoAviso(_kWarnColor, _kWarnBgColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kWarnColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: _kWarnColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconeAviso(Icons.shield_outlined, _kWarnColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Muitas tentativas seguidas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kWarnColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Por segurança, pausamos novas tentativas. Tente de novo em ${segundos}s. '
                      'Se esqueceu a senha, você pode recuperá-la agora.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: _corCorpo,
                      ),
                    ),
                    _buildBotaoAcao('Recuperar minha senha', _kWarnColor,
                        _irParaEsqueciSenha),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 6,
              backgroundColor: _kWarnColor.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(_kWarnColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required ValueNotifier<String?> erroNotifier,
    required ValueNotifier<int> shakeNotifier,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    OutlineInputBorder borda(Color cor, [double largura = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cor, width: largura),
      );
    }

    return ValueListenableBuilder<String?>(
      valueListenable: erroNotifier,
      builder: (context, erro, _) {
        final temErro = erro != null;
        final corBorda = temErro ? _kErrorColor : _corBorda;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balança de leve a cada tentativa inválida
            ValueListenableBuilder<int>(
              valueListenable: shakeNotifier,
              builder: (context, shakeCount, child) {
                return TweenAnimationBuilder<double>(
                  key: ValueKey(shakeCount),
                  tween: Tween(begin: shakeCount == 0 ? 0.0 : 1.0, end: 0.0),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, valor, child) {
                    final deslocamento =
                        math.sin(valor * math.pi * 6) * 8 * valor;
                    return Transform.translate(
                      offset: Offset(deslocamento, 0),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: _corDica),
                  prefixIcon: Icon(
                    prefixIcon,
                    color: temErro ? _kErrorColor : _corSubtexto,
                  ),
                  suffixIcon: suffixIcon,
                  filled: true,
                  fillColor: temErro ? _corErroFundo : _corCampo,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: borda(corBorda),
                  enabledBorder: borda(corBorda, temErro ? 1.5 : 1),
                  focusedBorder: borda(temErro ? _kErrorColor : _corTexto, 1.5),
                ),
              ),
            ),

            // Mensagem de aviso animada abaixo do campo
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topLeft,
              child: (erro != null && erro.isNotEmpty)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: _kErrorColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              erro,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kErrorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        );
      },
    );
  }
}
