import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/tela_de_login.dart';
import 'screens/senha_esquecida.dart';
import 'screens/criar_conta.dart';
import 'screens/tela_inicial.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Protege o carregamento do .env para não crashar caso o arquivo falhe
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Aviso: Erro ao carregar o .env: $e");
  }

  // Inicializa o Firebase com tratamento de erro para evitar travamentos caso falte alguma chave
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? 'dummy_api_key',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? 'dummy_app_id',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? 'dummy_sender_id',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'dummy_project_id',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      ),
    );
  } catch (e) {
    debugPrint("Erro ao inicializar o Firebase: $e");
  }

  runApp(const MeuAppPrincipal());
}

class MeuAppPrincipal extends StatelessWidget {
  const MeuAppPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Runner App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1A1A)),
        useMaterial3: true,
      ),
      // Usar 'home' garante que a tela de login seja carregada imediatamente de forma segura
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}