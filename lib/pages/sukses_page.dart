import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_nav.dart';

class SuksesPage extends StatelessWidget {
  final String idPesanan;
  const SuksesPage({super.key, required this.idPesanan});

  void _ke(BuildContext context, int tab) => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainNav(tab: tab)),
        (_) => false,
      );

  @override
  Widget build(BuildContext context) {
    final p = AppStore.i.cariPesanan(idPesanan);
    if (p == null) {
      return const Scaffold(body: Kosong(ikon: Icons.receipt_long_rounded, judul: 'Pesanan tidak ditemukan', isi: ''));
    }
    final cod = p.metodeBayar.grup == 'cod';
    final atas = MediaQuery.of(context).padding.top;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _ke(context, 0);
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [C.limeTerang, Color(0xFFF7EDA4), C.latar],
              stops: [0, 0.35, 0.55],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, atas + 40, 20, 24),
            children: [
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: C.daun,
                      borderRadius: daun(40, 12),
                      boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.55), spreadRadius: 12)],
                    ),
                    child: const Icon(Icons.check_rounded, size: 56, color: C.kuning),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(cod ? 'Pesanan berhasil dibuat!' : 'Pembayaran berhasil!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                cod
                    ? 'Siapkan uang tunai ${rupiah(p.total)} untuk kurir.\n${p.jadwal}'
                    : 'Sayurmu sedang dikemas oleh petani.\n${p.jadwal}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: C.abu, height: 1.5),
              ),
              const SizedBox(height: 22),
              _Struk(p: p),
              const SizedBox(height: 14),
              StatusPesanan(p: p),
            ],
          ),
        ),
        bottomNavigationBar: PanelBawah(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TombolUtama('Lacak pesanan', onTap: () => _ke(context, 2)),
              const SizedBox(height: 10),
              TombolKedua('Kembali belanja', onTap: () => _ke(context, 0)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Struk berbentuk tiket dengan garis sobek.
class _Struk extends StatelessWidget {
  final Pesanan p;
  const _Struk({required this.p});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: bayangan(0.12)),
        child: Column(
          children: [
            BarisHarga('No. pesanan', '#${p.id}'),
            BarisHarga('Waktu', tanggalIndo(p.dibayarPada ?? p.dibuat)),
            BarisHarga('Metode', p.metodeBayar.nama),
            BarisHarga('Barang', '${p.jumlahBarang} item'),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: _GarisPutus(),
                ),
                for (final kiri in [true, false])
                  Positioned(
                    left: kiri ? -28 : null,
                    right: kiri ? null : -28,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(color: C.latar, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            BarisHarga('Total dibayar', rupiah(p.total), tebal: true),
          ],
        ),
      );
}

class _GarisPutus extends StatelessWidget {
  const _GarisPutus();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) => Row(
          children: List.generate(
            (c.maxWidth / 10).floor(),
            (_) => Container(width: 5, height: 2, margin: const EdgeInsets.only(right: 5), color: C.garis),
          ),
        ),
      );
}

/// Timeline status: Dibayar → Dikemas → Dikirim → Sampai. Dipakai juga di Riwayat.
class StatusPesanan extends StatelessWidget {
  final Pesanan p;
  const StatusPesanan({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    final tahap = p.tahap;
    final label = [
      p.metodeBayar.grup == 'cod' ? 'Dipesan' : 'Dibayar',
      'Dikemas',
      p.diantar ? 'Dikirim' : 'Siap ambil',
      'Selesai',
    ];
    const ikon = [
      Icons.check_rounded,
      Icons.inventory_2_outlined,
      Icons.local_shipping_outlined,
      Icons.home_outlined,
    ];
    // tahap 0 = menunggu bayar → belum ada yang selesai
    final sampai = tahap <= 0 ? -1 : tahap;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: bayangan()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status pesanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 4; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.only(top: 13),
                      decoration: BoxDecoration(
                        color: i <= sampai ? C.daun : C.garis,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < sampai || (i == 3 && sampai == 3)
                              ? C.daun
                              : (i == sampai ? C.kuning : C.hijauPucat),
                          boxShadow: i == sampai && sampai < 3
                              ? [BoxShadow(color: C.kuning.withValues(alpha: 0.4), spreadRadius: 5)]
                              : null,
                        ),
                        child: Icon(
                          i < sampai || (i == 3 && sampai == 3) ? Icons.check_rounded : ikon[i],
                          size: 15,
                          color: i < sampai || (i == 3 && sampai == 3)
                              ? C.kuning
                              : (i == sampai ? C.tinta : C.abuMuda),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(label[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i <= sampai ? FontWeight.w600 : FontWeight.w400,
                            color: i <= sampai ? C.tinta : C.abu,
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
