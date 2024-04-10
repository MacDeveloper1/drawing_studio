import 'package:flutter/material.dart';

import 'floor_plan.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: false),
      home: const Scaffold(
        body: Center(
          child: ZoneFloorPlan(),
        ),
      ),
    );
  }
}
