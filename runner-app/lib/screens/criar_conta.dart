import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Paleta de cores padrão do app
  static const _kDarkColor = Color(0xFF1A1A1A);
  static const _kAccentColor = Color(0xFFD0FD38);
  static const _kBorderColor = Color(0xFFE5E7EB);
  static const _kSubtextColor = Color(0xFF6B7280);

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
  Color get _corDica =>
      _escuro ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

  /// Quadrado do ícone no topo.
  Color get _corLogo => _escuro ? const Color(0xFF262A23) : _kDarkColor;

  // Botão principal: escuro no tema claro, verde-limão no tema escuro.
  Color get _corBotao => _escuro ? _kAccentColor : _kDarkColor;
  Color get _corTextoBotao => _escuro ? _kDarkColor : Colors.white;

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Traduz e esconde qualquer erro técnico do Firebase do usuário final
  String _tratarErroCadastro(String erro) {
    if (erro.contains('CONFIGURATION_NOT_FOUND') ||
        erro.contains('internal-error')) {
      return 'Estamos passando por uma instabilidade temporária. Tente novamente mais tarde.';
    }
    if (erro.contains('email-already-in-use')) {
      return 'Este e-mail já está cadastrado em outra conta.';
    }
    if (erro.contains('weak-password')) {
      return 'A senha é muito fraca. Escolha uma senha com pelo menos 6 caracteres.';
    }
    if (erro.contains('invalid-email')) {
      return 'O formato do e-mail é inválido.';
    }
    if (erro.contains('network-request-failed')) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    }
    // Fallback amigável genérico para qualquer outra exceção inesperada
    return 'Não foi possível realizar o cadastro no momento. Tente novamente.';
  }

  void _handleCadastro() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (nome.isEmpty) {
      _mostrarSnack('Por favor, digite seu nome completo.', isError: true);
      return;
    }

    if (!_isValidEmail(email)) {
      _mostrarSnack('Por favor, insira um e-mail válido.', isError: true);
      return;
    }

    if (senha.length < 6) {
      _mostrarSnack('A senha deve ter pelo menos 6 caracteres.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.cadastrarComEmail(nome, email, senha);

      if (!mounted) return;

      _mostrarSnack('Conta criada com sucesso!', isError: false);
      Navigator.pop(context); // Retorna para a tela de login
    } catch (e) {
      final mensagemAmigavel = _tratarErroCadastro(e.toString());
      _mostrarSnack(mensagemAmigavel, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarSnack(String mensagem, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _corFundo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: _corTexto),
            style: IconButton.styleFrom(
              backgroundColor: _corCampo,
              side: BorderSide(color: _corBorda),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _corLogo,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_add_rounded,
                    color: _kAccentColor, size: 24),
              ),
              const SizedBox(height: 24),
              Text(
                'Criar sua conta',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: _corTexto),
              ),
              const SizedBox(height: 8),
              Text(
                'Preencha os dados abaixo para começar a usar o Runner App.',
                style:
                    TextStyle(fontSize: 14, color: _corSubtexto, height: 1.4),
              ),
              const SizedBox(height: 32),

              // Campo Nome
              Text('Nome completo',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _corRotulo)),
              const SizedBox(height: 8),
              TextField(
                controller: _nomeController,
                keyboardType: TextInputType.name,
                decoration: _inputDecoration('Seu Nome', Icons.person_outline),
              ),
              const SizedBox(height: 16),

              // Campo E-mail
              Text('E-mail',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _corRotulo)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    _inputDecoration('seu@email.com', Icons.email_outlined),
              ),
              const SizedBox(height: 16),

              // Campo Senha
              Text('Senha',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _corRotulo)),
              const SizedBox(height: 8),
              TextField(
                controller: _senhaController,
                obscureText: _obscurePassword,
                decoration:
                    _inputDecoration('Mínimo 6 caracteres', Icons.lock_outline)
                        .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _corSubtexto,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botão Cadastrar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCadastro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _corBotao,
                    foregroundColor: _corTextoBotao,
                    disabledBackgroundColor: _corBotao.withValues(alpha: 0.6),
                    disabledForegroundColor: _corTextoBotao,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: _corTextoBotao, strokeWidth: 2),
                        )
                      : const Text(
                          'Cadastrar',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _corDica),
      prefixIcon: Icon(icon, color: _corSubtexto),
      filled: true,
      fillColor: _corCampo,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _corBorda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _corBorda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _corTexto, width: 1.5),
      ),
    );
  }
}
