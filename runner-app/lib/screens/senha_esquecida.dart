import 'dart:async';

import 'package:flutter/material.dart';
import '../services/recuperacao_senha.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Paleta de cores padrão do app (mesma da tela de login)
  static const _kDarkColor = Color(0xFF1A1A1A);
  static const _kAccentColor = Color(0xFFD0FD38);
  static const _kBorderColor = Color(0xFFE5E7EB);
  static const _kSubtextColor = Color(0xFF6B7280);
  static const _kErrorColor = Color(0xFFEF4444);
  static const _kErrorBgColor = Color(0xFFFEF2F2);
  static const _kWarnColor = Color(0xFFD97706);
  static const _kWarnBgColor = Color(0xFFFFFBEB);

  static const int _segundosReenvio = 60;

  final _emailController = TextEditingController();
  final RecuperacaoSenhaService _service = RecuperacaoSenhaService();

  bool _isLoading = false;
  bool _emailEnviado = false;
  bool _argumentosLidos = false;

  // Erro de campo (borda vermelha + mensagem) e erro geral (cartão)
  String? _erroCampo;
  RecuperacaoSenhaException? _erroGeral;

  // Controle de reenvio
  Timer? _timerReenvio;
  int _segundosRestantes = 0;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (_erroCampo != null || _erroGeral != null) {
        setState(() {
          _erroCampo = null;
          _erroGeral = null;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se a tela de login enviou o e-mail digitado, já preenche o campo.
    if (_argumentosLidos) return;
    _argumentosLidos = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) {
      _emailController.text = args.trim();
    }
  }

  @override
  void dispose() {
    _timerReenvio?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarInstrucoes() async {
    if (_isLoading || _segundosRestantes > 0) return;

    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    final erroFormato = RecuperacaoSenhaService.validarEmail(email);
    if (erroFormato != null) {
      setState(() {
        _erroCampo = erroFormato;
        _erroGeral = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _erroCampo = null;
      _erroGeral = null;
    });

    try {
      await _service.enviarEmail(email);
      if (!mounted) return;
      setState(() => _emailEnviado = true);
      _iniciarContagemReenvio();
    } on RecuperacaoSenhaException catch (e) {
      debugPrint('Erro ao enviar e-mail de recuperação: ${e.original ?? e}');
      if (!mounted) return;
      setState(() {
        if (e.tipo == RecuperacaoSenhaErro.emailInvalido ||
            e.tipo == RecuperacaoSenhaErro.usuarioNaoEncontrado) {
          _erroCampo = e.mensagem;
        } else {
          _erroGeral = e;
        }
      });
    } catch (e) {
      debugPrint('Erro inesperado na recuperação de senha: $e');
      if (!mounted) return;
      setState(() {
        _erroGeral = const RecuperacaoSenhaException(
          RecuperacaoSenhaErro.desconhecido,
          'Não foi possível enviar o e-mail agora. Tente novamente.',
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _iniciarContagemReenvio() {
    _timerReenvio?.cancel();
    setState(() => _segundosRestantes = _segundosReenvio);
    _timerReenvio = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segundosRestantes <= 1) {
        timer.cancel();
        setState(() => _segundosRestantes = 0);
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  Future<void> _reenviar() async {
    if (_segundosRestantes > 0 || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _service.enviarEmail(_emailController.text.trim());
      _iniciarContagemReenvio();
      _mostrarSnack('E-mail reenviado!');
    } on RecuperacaoSenhaException catch (e) {
      _mostrarSnack(e.mensagem, isError: true);
    } catch (_) {
      _mostrarSnack('Não foi possível reenviar agora. Tente novamente.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarSnack(String mensagem, {bool isError = false}) {
    if (!mounted) return;
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

  void _voltarParaLogin() {
    // Volta para a tela anterior; se não houver, vai para /login.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            onPressed: _voltarParaLogin,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _kDarkColor),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: _kBorderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _emailEnviado
                ? KeyedSubtree(key: const ValueKey('ok'), child: _buildTelaSucesso())
                : KeyedSubtree(key: const ValueKey('form'), child: _buildTelaFormulario()),
          ),
        ),
      ),
    );
  }

  // Tela exibida após o envio bem-sucedido
  Widget _buildTelaSucesso() {
    final bloqueado = _segundosRestantes > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 2),
          ),
          child: const Icon(Icons.mark_email_read_outlined, color: Colors.green, size: 36),
        ),
        const SizedBox(height: 24),
        const Text(
          'Confira seu e-mail',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kDarkColor),
        ),
        const SizedBox(height: 12),
        Text(
          'Se existir uma conta para\n${_emailController.text.trim()}\n'
          'você receberá um link para definir uma nova senha.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: _kSubtextColor, height: 1.4),
        ),
        const SizedBox(height: 8),
        const Text(
          'Não chegou? Olhe também a caixa de spam.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: _kSubtextColor),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _voltarParaLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDarkColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Voltar para o Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: (bloqueado || _isLoading) ? null : _reenviar,
          child: Text(
            bloqueado ? 'Reenviar e-mail em ${_segundosRestantes}s' : 'Reenviar e-mail',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            _emailEnviado = false;
            _timerReenvio?.cancel();
            _segundosRestantes = 0;
          }),
          child: const Text('Usar outro e-mail', style: TextStyle(color: _kSubtextColor)),
        ),
      ],
    );
  }

  // Formulário principal de recuperação
  Widget _buildTelaFormulario() {
    final temErroCampo = _erroCampo != null;
    final corBorda = temErroCampo ? _kErrorColor : _kBorderColor;

    OutlineInputBorder borda(Color cor, [double largura = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cor, width: largura),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _kDarkColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.lock_reset_rounded, color: _kAccentColor, size: 24),
        ),
        const SizedBox(height: 24),
        const Text(
          'Esqueceu sua senha?',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _kDarkColor),
        ),
        const SizedBox(height: 8),
        const Text(
          'Digite seu e-mail abaixo e enviaremos um link para você redefinir sua senha com segurança.',
          style: TextStyle(fontSize: 14, color: _kSubtextColor, height: 1.4),
        ),
        const SizedBox(height: 32),
        const Text(
          'E-mail cadastrado',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _enviarInstrucoes(),
          decoration: InputDecoration(
            hintText: 'seu@email.com',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: temErroCampo ? _kErrorColor : _kSubtextColor,
            ),
            filled: true,
            fillColor: temErroCampo ? _kErrorBgColor : Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: borda(corBorda),
            enabledBorder: borda(corBorda, temErroCampo ? 1.5 : 1),
            focusedBorder: borda(temErroCampo ? _kErrorColor : _kDarkColor, 1.5),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: temErroCampo
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.error_outline_rounded, size: 16, color: _kErrorColor),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _erroCampo!,
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
        const SizedBox(height: 24),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _erroGeral == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCartaoErro(_erroGeral!),
                ),
        ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _enviarInstrucoes,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDarkColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _kDarkColor.withValues(alpha: 0.6),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Enviar instruções',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartaoErro(RecuperacaoSenhaException erro) {
    // Problemas de rede/limite = amarelo; erro interno/desconhecido = vermelho
    final aviso = erro.tipo == RecuperacaoSenhaErro.semConexao ||
        erro.tipo == RecuperacaoSenhaErro.tempoEsgotado ||
        erro.tipo == RecuperacaoSenhaErro.muitasTentativas;
    final cor = aviso ? _kWarnColor : _kErrorColor;
    final fundo = aviso ? _kWarnBgColor : _kErrorBgColor;

    final (icone, titulo) = switch (erro.tipo) {
      RecuperacaoSenhaErro.semConexao => (Icons.wifi_off_rounded, 'Sem conexão'),
      RecuperacaoSenhaErro.tempoEsgotado => (Icons.timer_off_outlined, 'Demorou demais'),
      RecuperacaoSenhaErro.muitasTentativas => (Icons.shield_outlined, 'Muitos pedidos seguidos'),
      RecuperacaoSenhaErro.erroInterno => (Icons.cloud_off_rounded, 'Problema no nosso servidor'),
      _ => (Icons.error_outline_rounded, 'Algo deu errado'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: cor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cor),
                ),
                const SizedBox(height: 2),
                Text(
                  erro.mensagem,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}