import 'package:flutter/gestures.dart';
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
  static const _kErroColor = Color(0xFFEF4444);

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
  Color get _corErro => _escuro ? const Color(0xFFF87171) : _kErroColor;

  /// Quadrado do ícone no topo.
  Color get _corLogo => _escuro ? const Color(0xFF262A23) : _kDarkColor;

  // Botão principal: escuro no tema claro, verde-limão no tema escuro.
  Color get _corBotao => _escuro ? _kAccentColor : _kDarkColor;
  Color get _corTextoBotao => _escuro ? _kDarkColor : Colors.white;

  /// Cor do texto clicável ("Termos de Uso") e da caixinha marcada.
  Color get _corLink => _escuro ? _kAccentColor : const Color(0xFF386641);

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  final _authService = AuthService();

  final _focoEmail = FocusNode();
  final _focoSenha = FocusNode();
  final _focoConfirmar = FocusNode();

  late final TapGestureRecognizer _toqueTermos = TapGestureRecognizer()
    ..onTap = () => _mostrarDocumento(_Documento.termos);
  late final TapGestureRecognizer _toquePrivacidade = TapGestureRecognizer()
    ..onTap = () => _mostrarDocumento(_Documento.privacidade);

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmar = true;
  bool _aceitouTermos = false;

  /// Só mostra os erros embaixo dos campos depois da 1ª tentativa,
  /// para não "brigar" com quem ainda está digitando.
  bool _tentouEnviar = false;

  // Erros exibidos embaixo de cada campo (null = sem erro).
  String? _erroNome;
  String? _erroEmail;
  String? _erroSenha;
  String? _erroConfirmar;
  String? _erroTermos;

  @override
  void initState() {
    super.initState();
    // Revalida enquanto digita (só depois da primeira tentativa).
    for (final c in [
      _nomeController,
      _emailController,
      _senhaController,
      _confirmarController,
    ]) {
      c.addListener(_revalidarSePreciso);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    _focoEmail.dispose();
    _focoSenha.dispose();
    _focoConfirmar.dispose();
    _toqueTermos.dispose();
    _toquePrivacidade.dispose();
    super.dispose();
  }

  // ===========================================================================
  // VALIDAÇÃO
  // ===========================================================================

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
  }

  String? _validarNome(String nome) {
    if (nome.isEmpty) return 'Digite seu nome completo.';
    if (nome.replaceAll(RegExp(r'\s'), '').length < 2) {
      return 'O nome está muito curto.';
    }
    return null;
  }

  String? _validarEmail(String email) {
    if (email.isEmpty) return 'Digite seu e-mail.';
    if (!_isValidEmail(email)) return 'Este e-mail não parece válido.';
    return null;
  }

  String? _validarSenha(String senha) {
    if (senha.isEmpty) return 'Crie uma senha.';
    if (senha.length < 6) return 'A senha precisa ter pelo menos 6 caracteres.';
    if (senha.trim().isEmpty) return 'A senha não pode ter só espaços.';
    return null;
  }

  String? _validarConfirmar(String senha, String confirmar) {
    if (confirmar.isEmpty) return 'Digite a senha mais uma vez.';
    if (confirmar != senha) return 'As senhas não são iguais.';
    return null;
  }

  /// Valida tudo e atualiza os erros. Devolve true se estiver tudo certo.
  bool _validarTudo() {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmar = _confirmarController.text;

    setState(() {
      _erroNome = _validarNome(nome);
      _erroEmail = _validarEmail(email);
      _erroSenha = _validarSenha(senha);
      _erroConfirmar = _validarConfirmar(senha, confirmar);
      _erroTermos = _aceitouTermos
          ? null
          : 'Você precisa aceitar os termos para criar a conta.';
    });

    return _erroNome == null &&
        _erroEmail == null &&
        _erroSenha == null &&
        _erroConfirmar == null &&
        _erroTermos == null;
  }

  void _revalidarSePreciso() {
    if (!mounted) return;
    if (_tentouEnviar) {
      _validarTudo();
    } else {
      // Redesenha para atualizar o aviso "As senhas são iguais".
      setState(() {});
    }
  }

  // ===========================================================================
  // CADASTRO
  // ===========================================================================

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
    if (erro.contains('too-many-requests')) {
      return 'Muitas tentativas seguidas. Aguarde alguns minutos e tente de novo.';
    }
    if (erro.contains('operation-not-allowed')) {
      return 'O cadastro por e-mail está desativado no momento.';
    }
    // Fallback amigável genérico para qualquer outra exceção inesperada
    return 'Não foi possível realizar o cadastro no momento. Tente novamente.';
  }

  Future<void> _handleCadastro() async {
    FocusScope.of(context).unfocus();
    setState(() => _tentouEnviar = true);

    if (!_validarTudo()) {
      _mostrarSnack(
        _erroTermos != null &&
                _erroNome == null &&
                _erroEmail == null &&
                _erroSenha == null &&
                _erroConfirmar == null
            ? 'Marque que você aceita os termos para continuar.'
            : 'Confira os campos destacados.',
        isError: true,
      );
      return;
    }

    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final senha = _senhaController.text;

    setState(() => _isLoading = true);

    try {
      await _authService.cadastrarComEmail(nome, email, senha);

      if (!mounted) return;

      _mostrarSnack('Conta criada com sucesso!', isError: false);
      Navigator.pop(context); // Retorna para a tela de login
    } catch (e) {
      if (!mounted) return;
      final texto = e.toString();
      final mensagemAmigavel = _tratarErroCadastro(texto);

      // Erros que são de um campo específico aparecem embaixo dele.
      setState(() {
        if (texto.contains('email-already-in-use') ||
            texto.contains('invalid-email')) {
          _erroEmail = mensagemAmigavel;
        } else if (texto.contains('weak-password')) {
          _erroSenha = mensagemAmigavel;
        }
      });
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

  // ===========================================================================
  // TERMOS
  // ===========================================================================

  void _alternarTermos([bool? valor]) {
    setState(() {
      _aceitouTermos = valor ?? !_aceitouTermos;
      if (_tentouEnviar) {
        _erroTermos = _aceitouTermos
            ? null
            : 'Você precisa aceitar os termos para criar a conta.';
      }
    });
  }

  /// Mostra o texto dos termos/política numa folha que sobe de baixo.
  /// TROQUE os textos de [_Documento] pelos documentos oficiais do app.
  void _mostrarDocumento(_Documento doc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _corCampo,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _corBorda,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(doc.titulo,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _corTexto,
                    )),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(doc.texto,
                      style: TextStyle(
                          fontSize: 14, height: 1.5, color: _corSubtexto)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (!_aceitouTermos) _alternarTermos(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _corBotao,
                      foregroundColor: _corTextoBotao,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Li e aceito',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TELA
  // ===========================================================================

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
        child: AutofillGroup(
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
                _rotulo('Nome completo'),
                TextField(
                  controller: _nomeController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  onSubmitted: (_) => _focoEmail.requestFocus(),
                  decoration: _inputDecoration(
                      'Seu Nome', Icons.person_outline, _erroNome),
                ),
                const SizedBox(height: 16),

                // Campo E-mail
                _rotulo('E-mail'),
                TextField(
                  controller: _emailController,
                  focusNode: _focoEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => _focoSenha.requestFocus(),
                  decoration: _inputDecoration(
                      'seu@email.com', Icons.email_outlined, _erroEmail),
                ),
                const SizedBox(height: 16),

                // Campo Senha
                _rotulo('Senha'),
                TextField(
                  controller: _senhaController,
                  focusNode: _focoSenha,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _focoConfirmar.requestFocus(),
                  decoration: _inputDecoration(
                    'Mínimo 6 caracteres',
                    Icons.lock_outline,
                    _erroSenha,
                  ).copyWith(
                    suffixIcon: _botaoOlho(
                      oculto: _obscurePassword,
                      onTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Confirmar senha
                _rotulo('Confirmar senha'),
                TextField(
                  controller: _confirmarController,
                  focusNode: _focoConfirmar,
                  obscureText: _obscureConfirmar,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: _inputDecoration(
                    'Digite a senha de novo',
                    Icons.lock_reset_outlined,
                    _erroConfirmar,
                  ).copyWith(
                    suffixIcon: _botaoOlho(
                      oculto: _obscureConfirmar,
                      onTap: () => setState(
                          () => _obscureConfirmar = !_obscureConfirmar),
                    ),
                  ),
                ),
                // Confirmação visual quando as senhas batem
                if (_confirmarController.text.isNotEmpty &&
                    _confirmarController.text == _senhaController.text &&
                    _erroConfirmar == null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 15, color: _corLink),
                      const SizedBox(width: 5),
                      Text('As senhas são iguais',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _corLink)),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Aceite dos termos
                _caixaTermos(),
                const SizedBox(height: 24),

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
      ),
    );
  }

  Widget _rotulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _corRotulo)),
      );

  Widget _botaoOlho({required bool oculto, required VoidCallback onTap}) =>
      IconButton(
        tooltip: oculto ? 'Mostrar senha' : 'Esconder senha',
        icon: Icon(
          oculto ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: _corSubtexto,
        ),
        onPressed: onTap,
      );

  /// Caixinha "Li e aceito os Termos de Uso e a Política de Privacidade".
  Widget _caixaTermos() {
    final comErro = _erroTermos != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: BoxDecoration(
            color: _corCampo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  comErro ? _corErro : (_aceitouTermos ? _corLink : _corBorda),
              width: comErro || _aceitouTermos ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _aceitouTermos,
                onChanged: _alternarTermos,
                activeColor: _corLink,
                checkColor: _escuro ? _kDarkColor : Colors.white,
                side: BorderSide(
                    color: comErro ? _corErro : _corSubtexto, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _alternarTermos,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                            fontSize: 13, height: 1.4, color: _corSubtexto),
                        children: [
                          const TextSpan(text: 'Li e aceito os '),
                          TextSpan(
                            text: 'Termos de Uso',
                            style: TextStyle(
                              color: _corLink,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: _corLink,
                            ),
                            recognizer: _toqueTermos,
                          ),
                          const TextSpan(text: ' e a '),
                          TextSpan(
                            text: 'Política de Privacidade',
                            style: TextStyle(
                              color: _corLink,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: _corLink,
                            ),
                            recognizer: _toquePrivacidade,
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (comErro) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 15, color: _corErro),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(_erroTermos!,
                      style: TextStyle(fontSize: 12, color: _corErro)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, [String? erro]) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _corDica),
      prefixIcon: Icon(icon, color: erro != null ? _corErro : _corSubtexto),
      filled: true,
      fillColor: _corCampo,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      errorText: erro,
      errorStyle: TextStyle(color: _corErro, fontSize: 12),
      errorMaxLines: 2,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _corErro),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _corErro, width: 1.5),
      ),
    );
  }
}

// =============================================================================
// TEXTOS DOS TERMOS (provisórios — troque pelos documentos oficiais)
// =============================================================================

enum _Documento {
  termos(
    'Termos de Uso',
    'Texto provisório. Substitua pelos Termos de Uso oficiais do Runner App.\n\n'
        '1. O Runner App oferece treinos, acompanhamento de atividades e '
        'contato com treinadores.\n\n'
        '2. Os treinos são orientações gerais e não substituem avaliação '
        'médica. Consulte um profissional de saúde antes de começar.\n\n'
        '3. Você é responsável pelas informações da sua conta e por manter '
        'sua senha em segurança.\n\n'
        '4. Podemos atualizar estes termos. Avisaremos sobre mudanças '
        'importantes pelo app.',
  ),
  privacidade(
    'Política de Privacidade',
    'Texto provisório. Substitua pela Política de Privacidade oficial do '
        'Runner App.\n\n'
        '1. Coletamos nome, e-mail e os dados das atividades que você '
        'registra (como distância, tempo e localização durante a corrida).\n\n'
        '2. Usamos esses dados para mostrar sua evolução e permitir o '
        'acompanhamento pelo seu treinador.\n\n'
        '3. Não vendemos seus dados. Você pode pedir a exclusão da sua conta '
        'a qualquer momento.',
  );

  const _Documento(this.titulo, this.texto);

  final String titulo;
  final String texto;
}
