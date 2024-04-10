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
      home: Scaffold(
        backgroundColor: Colors.grey,
        body: Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: const Column(
            children: [
              Text('To draw shape:\n'
                  '1: Tap on image\n'
                  '2: To complete shape do double click'),
              SizedBox(height: 20),
              Expanded(child: ZoneFloorPlan()),
            ],
          ),
        ),
      ),
    );
  }
}
