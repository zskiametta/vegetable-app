import 'package:flutter/material.dart';

import 'pages/splash_page.dart';
import 'services/store.dart';
import 'theme.dart';

/// Vegetable App — belanja sayur segar dari petani lokal.
/// Tugas Akhir BTNG 2026 Divisi Mobile (Flutter)
/// Dibuat oleh Zaskia Metta Dwi Saputri.
/// Data sayur: https://api-mobile.dnccudinus.org
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.i.init();
  runApp(const VegetableApp());
}

class VegetableApp extends StatelessWidget {
  const VegetableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vegetable App',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashPage(),
    );
  }
}
