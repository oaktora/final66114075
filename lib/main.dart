import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_options.dart';
import 'helpers/firebase_helper.dart';
import 'helpers/database_helper.dart';
import 'constants/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase: $e');
  }
  await DatabaseHelper.instance.database;
  runApp(const ElectionApp());
}

class ElectionApp extends StatefulWidget {
  const ElectionApp({super.key});

  @override
  State<ElectionApp> createState() => _ElectionAppState();
}

class _ElectionAppState extends State<ElectionApp> {
  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        FirebaseHelper.instance.syncPendingReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'รายงานทุจริตเลือกตั้ง',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
