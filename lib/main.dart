import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens_athletes.dart';
import 'screens_club.dart';
import 'screens_data.dart';
import 'screens_results.dart';
import 'screens_training.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  runApp(const DiarioApp());
}

class DiarioApp extends StatelessWidget {
  const DiarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diario Atletica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFD84315),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFFD84315),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
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
    AthletesScreen(),
    ResultsScreen(),
    TrainingScreen(),
    ClubScreen(),
    DataScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Atleti'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Gare'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Allenam.'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'Società'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Dati'),
        ],
      ),
    );
  }
}
