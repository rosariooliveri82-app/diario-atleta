import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'safety.dart';
import 'screens_agenda.dart';
import 'screens_more.dart';
import 'screens_profile.dart';
import 'screens_results.dart';
import 'screens_training.dart';
import 'store.dart';
import 'web_helpers_stub.dart' if (dart.library.js_interop) 'web_helpers_web.dart';

// Colori pista: rosso tartan + verde prato, linee bianche.
const tartan = Color(0xFFC8352B);
const grass = Color(0xFF2E7D32);

ThemeData _theme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: tartan, brightness: b)
      .copyWith(secondary: grass, primary: b == Brightness.light ? tartan : null);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: b == Brightness.light ? tartan : scheme.surface,
      foregroundColor: b == Brightness.light ? Colors.white : scheme.onSurface,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: grass, foregroundColor: Colors.white),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  if (kIsWeb) requestPersistentStorage();
  runApp(const DiarioApp());
}

class DiarioApp extends StatelessWidget {
  const DiarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diario Atletica',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: const Locale('it'),
      supportedLocales: const [Locale('it')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  static const pages = <Widget>[
    ProfileScreen(),
    ResultsScreen(),
    TrainingScreen(),
    AgendaScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profilo'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Gare'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Allenam.'),
          NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Agenda'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Altro'),
        ],
      ),
    );
  }
}
