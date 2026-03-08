import 'package:flutter/material.dart';
import 'get_started_screen.dart';
import 'session_data.dart';      
import 'package:provider/provider.dart';



Future<void> main() async {
  // Initialize Flutter bindings (required for secure storage and native channels)
  WidgetsFlutterBinding.ensureInitialized();
  
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => SessionData(), // สร้างตัวเก็บข้อมูลชั่วคราว
      child: const MyApp(), // เริ่มแอป
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GetStartedScreen(), // หน้าแรก
      debugShowCheckedModeBanner: false,
    );
  }
}