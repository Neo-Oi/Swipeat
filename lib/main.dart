import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SwipeatApp());
}

class SwipeatApp extends StatelessWidget {
  const SwipeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swipeat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}