import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/palette.dart';
import 'screens/home_screen.dart';
import 'state/save.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Save.load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Pal.paper,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MunchiBunApp());
}

class MunchiBunApp extends StatelessWidget {
  const MunchiBunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Munchi Bun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: Type.family,
        scaffoldBackgroundColor: Pal.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Pal.accent,
          primary: Pal.black,
          surface: Pal.paper,
        ),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: Pal.black),
      ),
      home: const HomeScreen(),
    );
  }
}
