import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Tipos de erro que a tela precisa diferenciar.
enum RecuperacaoSenhaErro {
  emailInvalido,
  usuarioNaoEncontrado,
  muitasTentativas,
  semConexao,
  tempoEsgotado,
  erroInterno,
  desconhecido,
}

/// Exceção já "traduzida": a tela só precisa ler [tipo] e [mensagem].
class RecuperacaoSenhaException implements Exception {
  const RecuperacaoSenhaException(this.tipo, this.mensagem, [this.original]);

  final RecuperacaoSenhaErro tipo;
  final String mensagem;

  /// Erro original (útil para debugPrint/logs, nunca mostrar ao usuário).
  final Object? original;

  @override
  String toString() => 'RecuperacaoSenhaException($tipo): $mensagem';
}

/// Serviço responsável apenas por enviar o e-mail de definição/redefinição de senha.
///
/// Uso:
/// ```dart
/// final service = RecuperacaoSenhaService();
/// try {
///   await service.enviarEmail('pessoa@email.com');
/// } on RecuperacaoSenhaException catch (e) {
///   print(e.mensagem);
/// }
/// ```
class RecuperacaoSenhaService {
  RecuperacaoSenhaService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  static const Duration _tempoLimite = Duration(seconds: 20);

  static final RegExp _regexEmail =
      RegExp(r'^[\w.+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,}$');

  /// Valida o formato do e-mail. Retorna a mensagem de erro ou null se estiver ok.
  static String? validarEmail(String email) {
    final e = email.trim();
    if (e.isEmpty) return 'Digite seu e-mail para continuar';
    if (e.contains(' ')) return 'O e-mail não pode ter espaços';
    if (!e.contains('@')) return 'Faltou o "@" no e-mail';
    if (!_regexEmail.hasMatch(e)) {
      return 'E-mail inválido. Use algo como nome@email.com';
    }
    return null;
  }

  /// Envia o e-mail com o link para definir uma nova senha.
  ///
  /// Lança [RecuperacaoSenhaException] em qualquer falha.
  Future<void> enviarEmail(String email) async {
    final emailLimpo = email.trim();

    final erroFormato = validarEmail(emailLimpo);
    if (erroFormato != null) {
      throw RecuperacaoSenhaException(
        RecuperacaoSenhaErro.emailInvalido,
        erroFormato,
      );
    }

    try {
      // O e-mail do Firebase sai em português.
      await _auth.setLanguageCode('pt');
      await _auth.sendPasswordResetEmail(email: emailLimpo).timeout(_tempoLimite);
    } on RecuperacaoSenhaException {
      rethrow;
    } catch (e) {
      throw _traduzir(e);
    }
  }

  RecuperacaoSenhaException _traduzir(Object e) {
    if (e is TimeoutException) {
      return RecuperacaoSenhaException(
        RecuperacaoSenhaErro.tempoEsgotado,
        'O servidor demorou para responder. Verifique sua conexão e tente de novo.',
        e,
      );
    }

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return RecuperacaoSenhaException(
            RecuperacaoSenhaErro.emailInvalido,
            'E-mail inválido. Use algo como nome@email.com',
            e,
          );
        case 'user-not-found':
          return RecuperacaoSenhaException(
            RecuperacaoSenhaErro.usuarioNaoEncontrado,
            'Não encontramos uma conta cadastrada com este e-mail.',
            e,
          );
        case 'too-many-requests':
          return RecuperacaoSenhaException(
            RecuperacaoSenhaErro.muitasTentativas,
            'Muitos pedidos seguidos. Aguarde alguns minutos e tente novamente.',
            e,
          );
        case 'network-request-failed':
          return RecuperacaoSenhaException(
            RecuperacaoSenhaErro.semConexao,
            'Sem conexão com a internet. Verifique sua rede e tente novamente.',
            e,
          );
        case 'internal-error':
        case 'invalid-api-key':
        case 'app-not-authorized':
        case 'operation-not-allowed':
        case 'unauthorized-continue-uri':
        case 'invalid-continue-uri':
        case 'missing-continue-uri':
          return RecuperacaoSenhaException(
            RecuperacaoSenhaErro.erroInterno,
            'Estamos com uma instabilidade temporária. Tente novamente mais tarde.',
            e,
          );
      }
    }

    final texto = e.toString().toLowerCase();
    if (texto.contains('socketexception') ||
        texto.contains('failed host lookup') ||
        texto.contains('network-request-failed')) {
      return RecuperacaoSenhaException(
        RecuperacaoSenhaErro.semConexao,
        'Sem conexão com a internet. Verifique sua rede e tente novamente.',
        e,
      );
    }
    if (texto.contains('configuration_not_found') ||
        texto.contains('internal-error')) {
      return RecuperacaoSenhaException(
        RecuperacaoSenhaErro.erroInterno,
        'Estamos com uma instabilidade temporária. Tente novamente mais tarde.',
        e,
      );
    }

    return RecuperacaoSenhaException(
      RecuperacaoSenhaErro.desconhecido,
      'Não foi possível enviar o e-mail agora. Tente novamente.',
      e,
    );
  }
}