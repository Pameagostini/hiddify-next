import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'tv_navigation_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuración específica para Android TV
  _configureForAndroidTV();
  
  runApp(
    const ProviderScope(
      child: HiddifyNextTVApp(),
    ),
  );
}

void _configureForAndroidTV() {
  // Forzar orientación horizontal para TV
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Ocultar barras del sistema para experiencia fullscreen
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.leanBack,
    overlays: [],
  );
  
  // Configurar tema para pantallas grandes
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
}

class HiddifyNextTVApp extends ConsumerWidget {
  const HiddifyNextTVApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Hiddify Next TV',
      debugShowCheckedModeBanner: false,
      routerConfig: _createRouter(),
      theme: _createTVTheme(false),
      darkTheme: _createTVTheme(true),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return TVNavigationWrapper(
          isMainScreen: true,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const TVHomePage(),
        ),
        GoRoute(
          path: '/proxies',
          builder: (context, state) => const TVProxiesPage(),
        ),
        GoRoute(
          path: '/logs',
          builder: (context, state) => const TVLogsPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const TVSettingsPage(),
        ),
      ],
    );
  }

  ThemeData _createTVTheme(bool isDark) {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    
    return base.copyWith(
      // Colores optimizados para TV
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF1976D2),
        secondary: const Color(0xFF03DAC6),
        surface: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      ),
      
      // Texto más grande para pantallas de TV
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(fontSize: 32),
        displayMedium: base.textTheme.displayMedium?.copyWith(fontSize: 28),
        displaySmall: base.textTheme.displaySmall?.copyWith(fontSize: 24),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(fontSize: 22),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(fontSize: 20),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontSize: 18),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 18),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 16),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontSize: 14),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12),
      ),
      
      // Botones más grandes con mejor contraste
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(120, 56),
          textStyle: const TextStyle(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // AppBar adaptada para TV
      appBarTheme: base.appBarTheme.copyWith(
        toolbarHeight: 80,
        titleTextStyle: base.textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Cards con mejor espaciado
      cardTheme: base.cardTheme.copyWith(
        margin: const EdgeInsets.all(12),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Focus indicator más visible
      focusColor: const Color(0xFF1976D2).withOpacity(0.3),
    );
  }
}

class TVHomePage extends ConsumerStatefulWidget {
  const TVHomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends ConsumerState<TVHomePage> {
  int _selectedDrawerIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<TVDrawerItem> _drawerItems = [
    const TVDrawerItem(title: 'Inicio', icon: Icons.home),
    const TVDrawerItem(title: 'Proxies', icon: Icons.vpn_lock),
    const TVDrawerItem(title: 'Registros', icon: Icons.list_alt),
    const TVDrawerItem(title: 'Configuración', icon: Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Hiddify Next TV'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: TVFocusableWidget(
          semanticLabel: 'Abrir menú',
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: const Icon(Icons.menu, size: 28),
        ),
        actions: [
          TVFocusableWidget(
            semanticLabel: 'Estado de conexión',
            onTap: _toggleConnection,
            child: Consumer(
              builder: (context
