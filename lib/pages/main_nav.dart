import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../services/store.dart';
import '../theme.dart';
import 'home_page.dart';
import 'keranjang_page.dart';
import 'notifikasi_page.dart';
import 'profil_page.dart';
import 'riwayat_page.dart';

/// Navigasi utama: navbar kaca mengambang + tombol keranjang di tengah.
class MainNav extends StatefulWidget {
  final int tab;
  const MainNav({super.key, this.tab = 0});

  /// Pindah tab dari halaman di dalamnya, contoh: MainNav.pindah(context, 1)
  static void pindah(BuildContext context, int tab) =>
      context.findAncestorStateOfType<MainNavState>()?.pindahTab(tab);

  @override
  State<MainNav> createState() => MainNavState();
}

class MainNavState extends State<MainNav> {
  late int _idx = widget.tab;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // status pesanan (dikemas → dikirim, batas bayar) diperbarui tiap 30 detik
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => AppStore.i.segarkan());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void pindahTab(int i) => setState(() => _idx = i);

  static const _halaman = [HomePage(), NotifikasiPage(), RiwayatPage(), ProfilPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _idx, children: _halaman),
      bottomNavigationBar: ListenableBuilder(
        listenable: AppStore.i,
        builder: (context, _) => _navbar(context),
      ),
    );
  }

  Widget _navbar(BuildContext context) {
    final s = AppStore.i;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        height: 96,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    children: [
                      _item(0, Icons.home_rounded, 'Beranda'),
                      _item(1, Icons.notifications_rounded, 'Notifikasi', badge: s.belumDibaca),
                      const SizedBox(width: 72),
                      _item(2, Icons.receipt_long_rounded, 'Riwayat'),
                      _item(3, Icons.person_rounded, 'Profil'),
                    ],
                  ),
                ),
              ),
            ),
            // bayangan lembut di bawah navbar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 68,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                          color: C.daun.withValues(alpha: 0.10),
                          blurRadius: 30,
                          offset: const Offset(0, 12)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: Semantics(
                button: true,
                label: 'Keranjang, ${s.jumlahKeranjang} barang',
                child: GestureDetector(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const KeranjangPage())),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [C.kuning, C.lime]),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: C.latar, width: 5),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF9CC45A).withValues(alpha: 0.5),
                            blurRadius: 18,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Badge(
                      isLabelVisible: s.jumlahKeranjang > 0,
                      backgroundColor: C.daun,
                      offset: const Offset(10, -10),
                      label: Text('${s.jumlahKeranjang}'),
                      child: const Icon(Icons.shopping_basket_rounded, color: C.tinta),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(int i, IconData ikon, String label, {int badge = 0}) {
    final aktif = _idx == i;
    return Expanded(
      child: Semantics(
        button: true,
        selected: aktif,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _idx = i),
          child: SizedBox(
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Badge(
                  isLabelVisible: badge > 0,
                  backgroundColor: const Color(0xFFE0B400),
                  textColor: C.tinta,
                  label: Text('$badge'),
                  child: Icon(ikon, color: aktif ? C.daun : C.abuMuda),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: aktif ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: aktif ? C.daun : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
