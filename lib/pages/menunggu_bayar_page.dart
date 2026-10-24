import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'sukses_page.dart';

/// Halaman menunggu pembayaran: QR / nomor VA + hitung mundur 15 menit.
/// Pembayaran di aplikasi ini disimulasikan (belum memakai payment gateway).
class MenungguBayarPage extends StatefulWidget {
  final String idPesanan;
  const MenungguBayarPage({super.key, required this.idPesanan});

  @override
  State<MenungguBayarPage> createState() => _MenungguBayarPageState();
}

class _MenungguBayarPageState extends State<MenungguBayarPage> {
  Timer? _timer;
  bool _mengecek = false;

  Pesanan? get _p => AppStore.i.cariPesanan(widget.idPesanan);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final p = _p;
      if (p != null && p.status == 'menunggu' && DateTime.now().isAfter(p.batasBayar)) {
        AppStore.i.segarkan(); // otomatis batal
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _nomorVa {
    final p = _p!;
    final kode = p.metode == 'bca' ? '39358' : '88810';
    final hp = AppStore.normalHp(AppStore.i.hp);
    return '$kode${hp.substring(max(0, hp.length - 11))}';
  }

  Future<void> _cekStatus() async {
    setState(() => _mengecek = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    AppStore.i.tandaiLunas(widget.idPesanan);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SuksesPage(idPesanan: widget.idPesanan)),
    );
  }

  Future<void> _batalkan() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Ganti metode bayar?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text('Pesanan ini dibatalkan dan barangnya kembali ke keranjang, '
            'jadi kamu bisa checkout lagi dengan metode lain.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, ganti')),
        ],
      ),
    );
    if (ya != true || !mounted) return;
    AppStore.i.batalkan(widget.idPesanan);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    if (p == null) {
      return const Scaffold(body: Kosong(ikon: Icons.receipt_long_rounded, judul: 'Pesanan tidak ditemukan', isi: ''));
    }
    final sisa = p.batasBayar.difference(DateTime.now());
    final habis = p.status == 'batal' || sisa.isNegative;
    final m = p.metodeBayar;
    final pakaiQr = m.grup == 'qris' || m.grup == 'ewallet';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [C.limeTerang, Color(0xFFF7EDA4), C.latar],
            stops: [0, 0.3, 0.5],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const HeaderHalaman('Selesaikan pembayaran'),
            const SizedBox(height: 14),
            if (habis)
              const Center(
                child: Text('Waktu pembayaran habis, pesanan dibatalkan.',
                    style: TextStyle(fontSize: 12, color: C.merah, fontWeight: FontWeight.w600)),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bayar sebelum ', style: TextStyle(fontSize: 12, color: C.abu)),
                  _angka(dua(sisa.inMinutes)),
                  const Text(' : ', style: TextStyle(fontWeight: FontWeight.w700)),
                  _angka(dua(sisa.inSeconds % 60)),
                  Text('  (${jam(p.batasBayar)})', style: const TextStyle(fontSize: 12, color: C.abu)),
                ],
              ),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: bayangan(0.12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(pakaiQr ? 'QRIS · ${m.nama}' : m.nama,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      Text('#${p.id}', style: const TextStyle(fontSize: 11, color: C.abu)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (pakaiQr)
                    Opacity(
                      opacity: habis ? 0.25 : 1,
                      child: SizedBox(
                        width: 196,
                        height: 196,
                        child: CustomPaint(
                          painter: _QrPainter(p.id),
                          child: Center(
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: C.daun,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white, width: 5),
                              ),
                              child: const Icon(Icons.eco_rounded, size: 18, color: C.kuning),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: C.hijauPucat, borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        children: [
                          const Text('Nomor Virtual Account', style: TextStyle(fontSize: 11, color: C.abu)),
                          const SizedBox(height: 4),
                          Text(_nomorVa,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  const Text('Total yang harus dibayar', style: TextStyle(fontSize: 11, color: C.abu)),
                  Text(rupiah(p.total),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: C.daun)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TombolKedua(
                          pakaiQr ? 'Salin ID' : 'Salin nomor',
                          ikon: Icons.copy_rounded,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: pakaiQr ? p.id : _nomorVa));
                            kabari(context, 'Disalin ke clipboard');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TombolKedua(
                          'Salin nominal',
                          ikon: Icons.payments_outlined,
                          warna: C.kuningPucat,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: '${p.total}'));
                            kabari(context, 'Nominal ${rupiah(p.total)} disalin');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cara bayar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ..._langkah(pakaiQr, m, p.total),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Text(
                'Mode demo: tombol "Cek status bayar" mensimulasikan pembayaran berhasil.',
                style: TextStyle(fontSize: 11, color: C.abuMuda),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PanelBawah(
        child: habis
            ? TombolUtama('Kembali ke beranda', onTap: () => Navigator.of(context).pop())
            : Row(
                children: [
                  SizedBox(width: 120, child: TombolKedua('Ganti metode', onTap: _batalkan)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TombolUtama('Cek status bayar',
                        ikon: Icons.refresh_rounded, loading: _mengecek, onTap: _cekStatus),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _angka(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
      );

  List<Widget> _langkah(bool qr, Metode m, int total) {
    final daftar = qr
        ? [
            ('Buka aplikasi ${m.grup == 'ewallet' ? m.nama : 'e-wallet atau m-banking'}',
                'GoPay, OVO, DANA, BCA mobile, dan lainnya'),
            ('Pilih Scan / Bayar, arahkan ke QR', 'Pastikan nama merchant "Vegetable App"'),
            ('Konfirmasi ${rupiah(total)} lalu masukkan PIN', 'Status pesanan berubah otomatis'),
          ]
        : [
            ('Buka m-banking atau ATM ${m.nama.split(' ').first}', 'Pilih menu Transfer › Virtual Account'),
            ('Masukkan nomor VA di atas', 'Nama penerima tampil "VEGETABLE APP"'),
            ('Pastikan nominal ${rupiah(total)} lalu kirim', 'Status pesanan berubah otomatis'),
          ];
    return [
      for (int i = 0; i < daftar.length; i++)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: C.daun, shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.kuning)),
                  ),
                  if (i < daftar.length - 1) Expanded(child: Container(width: 2, color: C.lime)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14, top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(daftar[i].$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(daftar[i].$2, style: const TextStyle(fontSize: 12, color: C.abu)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

/// Gambar QR dekoratif (pola acak berdasar ID pesanan, untuk simulasi).
class _QrPainter extends CustomPainter {
  final String seed;
  _QrPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 25;
    final kotak = size.width / n;
    final cat = Paint()..color = C.tinta;
    final acak = Random(seed.hashCode);
    bool diFinder(int x, int y) =>
        (x < 8 && y < 8) || (x >= n - 8 && y < 8) || (x < 8 && y >= n - 8);
    for (int x = 0; x < n; x++) {
      for (int y = 0; y < n; y++) {
        if (!diFinder(x, y) && acak.nextDouble() < 0.48) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x * kotak, y * kotak, kotak, kotak), Radius.circular(kotak * 0.25)),
            cat,
          );
        }
      }
    }
    void finder(double ox, double oy) {
      final s = kotak * 7;
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(ox, oy, s, s), Radius.circular(kotak * 1.5)), cat);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(ox + kotak, oy + kotak, s - 2 * kotak, s - 2 * kotak),
              Radius.circular(kotak)),
          Paint()..color = Colors.white);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(ox + 2 * kotak, oy + 2 * kotak, s - 4 * kotak, s - 4 * kotak),
              Radius.circular(kotak * 0.8)),
          cat);
    }

    finder(0, 0);
    finder(size.width - kotak * 7, 0);
    finder(0, size.height - kotak * 7);
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.seed != seed;
}
