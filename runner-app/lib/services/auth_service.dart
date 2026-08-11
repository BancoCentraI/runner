import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://sua-api.com/api';

  Future<void> _verificarOuCriarUsuarioNaApi({
    required String uid,
    required String email,
    required String nome,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/usuarios/verificar-ou-criar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'email': email,
          'nome': nome,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erro ao sincronizar usuário com a API backend.');
      }
    } catch (e) {
      log('Aviso de sincronização com API: $e');
    }
  }

  // Traduz os erros do Firebase para mensagens amigáveis
  String _tratarErroFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
      case 'user-not-found':
        return 'E-mail mal formatado ou não cadastrado.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'user-disabled':
        return 'Este usuário foi desativado.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso por outra conta.';
      case 'weak-password':
        return 'A senha é muito fraca. Escolha uma senha mais forte.';
      default:
        return 'Ocorreu um erro na autenticação: ${e.message}';
    }
  }

  Future<User?> loginComEmail(String email, String senha) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      
      if (credential.user != null) {
        await _verificarOuCriarUsuarioNaApi(
          uid: credential.user!.uid,
          email: email.trim(),
          nome: credential.user!.displayName ?? 'Usuário',
        );
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_tratarErroFirebase(e));
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<User?> loginComGoogle() async {
    try {
      // 1. Instancia o GoogleSignIn corretamente para a versão 6.x
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 2. Executa o fluxo de login (retorna nulo se o usuário cancelar)
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // O usuário cancelou o login
        return null;
      }

      // 3. Obtém as credenciais de autenticação (necessário usar await)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. Cria a credencial para o Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _verificarOuCriarUsuarioNaApi(
          uid: user.uid,
          email: user.email ?? '',
          nome: user.displayName ?? 'Usuário Google',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_tratarErroFirebase(e));
    } catch (e) {
      throw Exception('Erro ao logar com o Google: $e');
    }
  }

  // Método para enviar o e-mail de recuperação de senha
  Future<void> enviarEmailRecuperacao(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_tratarErroFirebase(e));
    } catch (e) {
      throw Exception('Erro ao enviar e-mail de recuperação: $e');
    }
  }

  Future<void> salvarEmailLembrado(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email_lembrado', email);
  }

  Future<void> limparEmailLembrado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email_lembrado');
  }

  Future<String?> carregarEmailLembrado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email_lembrado');
  }

  // Método para criar conta com Nome, E-mail e Senha
  Future<User?> cadastrarComEmail(String nome, String email, String senha) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      
      if (credential.user != null) {
        // Atualiza o nome de exibição no Firebase Auth
        await credential.user!.updateDisplayName(nome.trim());

        // Sincroniza o novo usuário com a sua API backend
        await _verificarOuCriarUsuarioNaApi(
          uid: credential.user!.uid,
          email: email.trim(),
          nome: nome.trim(),
        );
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_tratarErroFirebase(e));
    } catch (e) {
      throw Exception('Erro ao cadastrar usuário: $e');
    }
  }
}