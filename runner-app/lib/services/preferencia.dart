
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline.dart';

// =============================================================================
// PREFERÊNCIAS DO APP
// =============================================================================

enum UnidadeDistancia { km, milhas }

/// Guarda as preferências do usuário no celular (shared_preferences) e avisa
/// o app quando algo muda — o MaterialApp escuta isso para trocar o tema.
///
/// Uso: `Preferencias.instancia.tema`, `Preferencias.instancia.definirTema(...)`
class Preferencias extends ChangeNotifier {
  Preferencias._();

  static final Preferencias instancia = Preferencias._();

  SharedPreferences? _sp;

  ThemeMode _tema = ThemeMode.light;
  UnidadeDistancia _unidade = UnidadeDistancia.km;
  bool _lembretesTreino = true;
  bool _mensagensTreinador = true;
  bool _localizacaoEmergencia = true;
  String _telefone = '';

  ThemeMode get tema => _tema;

  /// O app está escuro agora? (considera "Sistema" pelo tema do celular)
  bool get modoEscuro {
    if (_tema == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _tema == ThemeMode.dark;
  }
  UnidadeDistancia get unidade => _unidade;
  bool get lembretesTreino => _lembretesTreino;
  bool get mensagensTreinador => _mensagensTreinador;
  bool get localizacaoEmergencia => _localizacaoEmergencia;
  String get telefone => _telefone;

  /// Chame uma vez no main(), antes do runApp.
  Future<void> carregar() async {
    _sp = await SharedPreferences.getInstance();
    final sp = _sp!;
    _tema = ThemeMode.values.firstWhere(
      (m) => m.name == sp.getString('tema'),
      orElse: () => ThemeMode.light,
    );
    _unidade = UnidadeDistancia.values.firstWhere(
      (u) => u.name == sp.getString('unidade'),
      orElse: () => UnidadeDistancia.km,
    );
    _lembretesTreino = sp.getBool('lembretesTreino') ?? true;
    _mensagensTreinador = sp.getBool('mensagensTreinador') ?? true;
    _localizacaoEmergencia = sp.getBool('localizacaoEmergencia') ?? true;
    _telefone = sp.getString('telefone') ?? '';
    notifyListeners();
  }

  Future<void> definirTema(ThemeMode valor) async {
    if (valor == _tema) return;
    _tema = valor;
    notifyListeners();
    await _sp?.setString('tema', valor.name);
  }

  Future<void> definirUnidade(UnidadeDistancia valor) async {
    if (valor == _unidade) return;
    _unidade = valor;
    notifyListeners();
    await _sp?.setString('unidade', valor.name);
    _sincronizar();
  }

  Future<void> definirLembretesTreino(bool valor) async {
    _lembretesTreino = valor;
    notifyListeners();
    await _sp?.setBool('lembretesTreino', valor);
    _sincronizar();
  }

  Future<void> definirMensagensTreinador(bool valor) async {
    _mensagensTreinador = valor;
    notifyListeners();
    await _sp?.setBool('mensagensTreinador', valor);
    _sincronizar();
  }

  Future<void> definirLocalizacaoEmergencia(bool valor) async {
    _localizacaoEmergencia = valor;
    notifyListeners();
    await _sp?.setBool('localizacaoEmergencia', valor);
    _sincronizar();
  }

  Future<void> definirTelefone(String valor) async {
    _telefone = valor;
    notifyListeners();
    await _sp?.setString('telefone', valor);
    _sincronizar();
  }

  /// Envia as preferências para a API (PUT /preferencias) pela fila offline:
  /// sem internet, fica salvo no aparelho e é enviado quando a conexão
  /// voltar. Só a versão mais nova é enviada (substitui as anteriores).
  Future<void> _sincronizar() async {
    final r = await ApiOffline.enviar(
      'PUT',
      '/preferencias',
      corpo: {
        'unidade': _unidade.name,
        'lembretesTreino': _lembretesTreino,
        'mensagensTreinador': _mensagensTreinador,
        'localizacaoEmergencia': _localizacaoEmergencia,
        'telefone': _telefone,
      },
      substitui: 'preferencias',
    );
    debugPrint('[PREFS] Sincronização: ${r.name}');
  }
}

// =============================================================================
// RECONSTRUÇÃO AO TROCAR O TEMA
// =============================================================================

/// Coloque no `builder` do MaterialApp. Quando o tema muda (nas
/// Configurações ou no celular, se estiver em "Sistema"), reconstrói todas as
/// telas abertas — inclusive as abas que estão em segundo plano — sem perder
/// a navegação nem o estado delas. Também ajusta os ícones da barra de status.
class TemaDinamico extends StatefulWidget {
  const TemaDinamico({super.key, required this.child});

  final Widget child;

  @override
  State<TemaDinamico> createState() => _TemaDinamicoState();
}

class _TemaDinamicoState extends State<TemaDinamico>
    with WidgetsBindingObserver {
  late bool _escuro = Preferencias.instancia.modoEscuro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Preferencias.instancia.addListener(_verificar);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Preferencias.instancia.removeListener(_verificar);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _verificar();

  void _verificar() {
    final agora = Preferencias.instancia.modoEscuro;
    if (agora == _escuro || !mounted) return;
    _escuro = agora;
    setState(() {});
    // Widgets `const` não se reconstroem sozinhos: marca todos.
    void marcar(Element e) {
      e.markNeedsBuild();
      e.visitChildren(marcar);
    }

    (context as Element).visitChildren(marcar);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _escuro ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: widget.child,
    );
  }
}

// =============================================================================
// TEMAS CLARO E ESCURO
// =============================================================================

class AppTemas {
  AppTemas._();

  static const _destaque = Color(0xFFD0FD38);

  static ThemeData get claro => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F7F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _destaque,
          brightness: Brightness.light,
          primary: const Color(0xFF1A1A1A),
          surface: Colors.white,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );

  static ThemeData get escuro => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111311),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _destaque,
          brightness: Brightness.dark,
          primary: _destaque,
          surface: const Color(0xFF1C1F1B),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF2A2E28),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
