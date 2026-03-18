import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MobistreamApp());
}

class MobistreamApp extends StatelessWidget {
  const MobistreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobistream',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
