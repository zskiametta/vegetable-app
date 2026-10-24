import 'package:flutter/material.dart';

import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth_page.dart';
import 'main_nav.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => AppStore.i.masuk ? const MainNav() : const AuthPage(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: gradasiSegar),
        child: Stack(
          children: [
            Positioned(
              right: -80,
              bottom: -40,
              child: Pudar(
                gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Colors.black, Colors.transparent]),
                child: Image.asset('assets/images/bg_photo.jpg',
                    width: 360,
                    height: 360,
                    fit: BoxFit.cover,
                    color: const Color(0xFFEFF4A8),
                    colorBlendMode: BlendMode.multiply),
              ),
            ),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Logo(size: 60),
                    SizedBox(height: 12),
                    Text('Sayur segar, langsung ke dapurmu',
                        style: TextStyle(color: C.abu, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: Text('TA BTNG 2026 · Zaskia Metta Dwi Saputri',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: C.tinta, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
