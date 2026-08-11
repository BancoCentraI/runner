import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:runner/main.dart';

// Mock simples para simular o Firebase nos testes de widgets
class MockFirebasePlatform {
  static void initialize() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }
}

void main() {
  setUpAll(() async {
    MockFirebasePlatform.initialize();
    // Tenta inicializar o core do Firebase para testes (evita o erro de No-App)
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Ignora se já estiver inicializado
    }
  });

  testWidgets('Testa se a tela de login carrega corretamente', (WidgetTester tester) async {
    // Carrega o app principal
    await tester.pumpWidget(const MeuAppPrincipal());

    // Aguarda a renderização inicial
    await tester.pumpAndSettle();

    // Dica: ajuste os textos abaixo para baterem 100% com os textos reais da sua LoginScreen
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}