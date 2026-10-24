import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/store.dart';
import '../theme.dart';

/// Gambar cadangan dari folder assets (dipakai kalau gambar API gagal dimuat).
String asetCadangan(int id) => 'assets/images/product_${(id.abs() % 4) + 1}.jpg';

/// Gambar sayur dari URL API.
/// [blend] = warna latar yang "dicampur" ke foto (efek menyatu dengan kartu).
class NetImg extends StatelessWidget {
  final String url;
  final int id;
  final double? width, height;
  final double radius;
  final BorderRadius? borderRadius;
  final Color? blend;
  final Alignment alignment;

  const NetImg(
    this.url, {
    super.key,
    this.id = 0,
    this.width,
    this.height,
    this.radius = 18,
    this.borderRadius,
    this.blend,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    Widget cadangan() => Image.asset(
          asetCadangan(id),
          width: width,
          height: height,
          fit: BoxFit.cover,
          color: blend,
          colorBlendMode: blend == null ? null : BlendMode.multiply,
        );

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      child: url.isEmpty
          ? cadangan()
          : Image.network(
              url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              alignment: alignment,
              color: blend,
              colorBlendMode: blend == null ? null : BlendMode.multiply,
              loadingBuilder: (c, child, p) => p == null
                  ? child
                  : Container(
                      width: width,
                      height: height,
                      color: blend ?? C.hijauPucat,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: C.daun),
                      ),
                    ),
              errorBuilder: (c, e, s) => cadangan(),
            ),
    );
  }
}

/// Memudarkan tepi sebuah widget (foto menyatu ke latar).
class Pudar extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  const Pudar({super.key, required this.child, required this.gradient});

  /// Pudar melingkar dari tengah.
  const Pudar.bulat({super.key, required this.child})
      : gradient = const RadialGradient(
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.62, 0.72],
        );

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => gradient.createShader(r),
        child: child,
      );
}

class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: C.daun, borderRadius: BorderRadius.circular(size * .35)),
            child: Icon(Icons.eco_rounded, color: C.kuning, size: size * .58),
          ),
          SizedBox(width: size * .25),
          Text('Vegetable App',
              style: TextStyle(fontSize: size * .5, fontWeight: FontWeight.w700, color: C.tinta)),
        ],
      );
}

/// Tombol kotak kaca (kembali, notifikasi, favorit).
class TombolKaca extends StatelessWidget {
  final IconData ikon;
  final VoidCallback? onTap;
  final Color warnaIkon;
  final String label;
  final Widget? badge;
  const TombolKaca(this.ikon,
      {super.key, this.onTap, this.warnaIkon = C.tinta, required this.label, this.badge});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(ikon, color: warnaIkon, size: 22),
                  if (badge != null) Positioned(top: 9, right: 10, child: badge!),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Tombol utama hijau. [harga] tampil sebagai pil kuning di kanan.
class TombolUtama extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? harga;
  final IconData? ikon;
  final bool loading;
  const TombolUtama(this.label,
      {super.key, this.onTap, this.harga, this.ikon, this.loading = false});

  @override
  Widget build(BuildContext context) => Material(
        color: onTap == null ? C.abuMuda : C.daun,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: loading ? null : onTap,
          child: Container(
            height: 56,
            padding: EdgeInsets.only(left: 20, right: harga == null ? 20 : 8),
            child: loading
                ? const Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)))
                : Row(
                    mainAxisAlignment:
                        harga == null ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      if (harga != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: C.kuning, borderRadius: BorderRadius.circular(14)),
                          child: Text(harga!,
                              style: const TextStyle(
                                  color: C.tinta, fontWeight: FontWeight.w700, fontSize: 13)),
                        )
                      else if (ikon != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(color: C.kuning, shape: BoxShape.circle),
                          child: Icon(ikon, size: 16, color: C.tinta),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      );
}

/// Tombol kedua (latar hijau pucat).
class TombolKedua extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? ikon;
  final Color warna;
  const TombolKedua(this.label, {super.key, this.onTap, this.ikon, this.warna = C.hijauPucat});

  @override
  Widget build(BuildContext context) => Material(
        color: warna,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ikon != null) ...[Icon(ikon, size: 18, color: C.daun), const SizedBox(width: 6)],
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13, color: C.tinta)),
              ],
            ),
          ),
        ),
      );
}

/// Panel putih menempel di bawah layar (untuk tombol aksi).
class PanelBawah extends StatelessWidget {
  final Widget child;
  const PanelBawah({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: C.daun.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -8)),
          ],
        ),
        child: child,
      );
}

/// Header halaman alur bayar: tombol kembali + judul.
class HeaderHalaman extends StatelessWidget {
  final String judul;
  final Widget? kanan;
  final VoidCallback? onKembali;
  const HeaderHalaman(this.judul, {super.key, this.kanan, this.onKembali});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 0),
        child: Row(
          children: [
            TombolKaca(Icons.arrow_back_rounded,
                label: 'Kembali', onTap: onKembali ?? () => Navigator.maybePop(context)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(judul,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
            if (kanan != null) kanan!,
          ],
        ),
      );
}

/// Stepper 1 Keranjang — 2 Kirim — 3 Bayar.
class LangkahBayar extends StatelessWidget {
  final int aktif; // 1, 2, 3
  const LangkahBayar(this.aktif, {super.key});

  @override
  Widget build(BuildContext context) {
    Widget titik(int n, String label) {
      final selesai = n < aktif;
      final sekarang = n == aktif;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selesai ? C.lime : (sekarang ? C.daun : C.garis),
            ),
            child: selesai
                ? const Icon(Icons.check_rounded, size: 14, color: C.tinta)
                : Text('$n',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sekarang ? C.kuning : C.abu)),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: n <= aktif ? FontWeight.w600 : FontWeight.w400,
                color: selesai ? C.tautan : (sekarang ? C.tinta : C.abu),
              )),
        ],
      );
    }

    Widget garis(bool hidup) => Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: hidup ? C.lime : C.garis,
          ),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        titik(1, 'Keranjang'),
        garis(aktif > 1),
        titik(2, 'Kirim'),
        garis(aktif > 2),
        titik(3, 'Bayar'),
      ]),
    );
  }
}

class JudulBagian extends StatelessWidget {
  final String judul;
  final String? kanan;
  final VoidCallback? onKanan;
  const JudulBagian(this.judul, {super.key, this.kanan, this.onKanan});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(
          children: [
            Expanded(
                child: Text(judul,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            if (kanan != null)
              GestureDetector(
                onTap: onKanan,
                child: Text(kanan!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: onKanan == null ? FontWeight.w400 : FontWeight.w600,
                      color: onKanan == null ? C.abu : C.tautan,
                    )),
              ),
          ],
        ),
      );
}

/// Kontrol jumlah [-] n [+].
class Jumlah extends StatelessWidget {
  final int nilai;
  final ValueChanged<int> onUbah;
  final int minimal;
  final bool vertikal;
  const Jumlah(
      {super.key, required this.nilai, required this.onUbah, this.minimal = 0, this.vertikal = false});

  @override
  Widget build(BuildContext context) {
    Widget tombol(String t, bool tambah, VoidCallback? f) => Material(
          color: tambah ? C.daun : Colors.white,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: f,
            child: SizedBox(
              width: vertikal ? 30 : 36,
              height: vertikal ? 28 : 36,
              child: Center(
                child: Text(t,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: tambah ? C.kuning : (f == null ? C.abuMuda : C.daun))),
              ),
            ),
          ),
        );
    final angka = SizedBox(
      width: 28,
      child: Text('$nilai',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    );
    final kurang = tombol('−', false, nilai > minimal ? () => onUbah(nilai - 1) : null);
    final tambah = tombol('+', true, () => onUbah(nilai + 1));
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: C.hijauPucat, borderRadius: BorderRadius.circular(15)),
      child: vertikal
          ? Column(mainAxisSize: MainAxisSize.min, children: [tambah, const SizedBox(height: 2), angka, const SizedBox(height: 2), kurang])
          : Row(mainAxisSize: MainAxisSize.min, children: [kurang, angka, tambah]),
    );
  }
}

/// Tombol tambah kecil (+) di kartu produk.
class TombolPlus extends StatelessWidget {
  final VoidCallback onTap;
  final double ukuran;
  const TombolPlus({super.key, required this.onTap, this.ukuran = 34});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Tambah ke keranjang',
        child: Material(
          color: C.daun,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
                width: ukuran,
                height: ukuran,
                child: const Icon(Icons.add_rounded, color: C.kuning, size: 20)),
          ),
        ),
      );
}

void tambahDanKabari(BuildContext context, Sayur s, {int ukuran = 1, int qty = 1}) {
  AppStore.i.tambahKeranjang(s, ukuran: ukuran, qty: qty);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('$qty × ${s.nama} masuk keranjang'),
      duration: const Duration(milliseconds: 1400),
    ));
}

void kabari(BuildContext context, String pesan) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(pesan)));
}

class Kosong extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String isi;
  final Widget? aksi;
  const Kosong({super.key, required this.ikon, required this.judul, required this.isi, this.aksi});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: C.hijauPucat, borderRadius: daun(36, 12)),
                child: Icon(ikon, size: 44, color: C.daun),
              ),
              const SizedBox(height: 16),
              Text(judul,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(isi, textAlign: TextAlign.center, style: const TextStyle(color: C.abu)),
              if (aksi != null) ...[const SizedBox(height: 20), aksi!],
            ],
          ),
        ),
      );
}

class GagalMuat extends StatelessWidget {
  final VoidCallback onUlang;
  const GagalMuat({super.key, required this.onUlang});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(20),
        decoration:
            BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: bayangan()),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: C.daunMuda),
            const SizedBox(height: 8),
            const Text('Gagal memuat data sayur',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Cek koneksi internet, lalu coba lagi.',
                textAlign: TextAlign.center, style: TextStyle(color: C.abu, fontSize: 12)),
            const SizedBox(height: 14),
            TombolKedua('Coba lagi', ikon: Icons.refresh_rounded, onTap: onUlang),
          ],
        ),
      );
}

/// Baris rincian harga "label ...... nilai".
class BarisHarga extends StatelessWidget {
  final String label;
  final String nilai;
  final bool tebal;
  final Color? warnaNilai;
  const BarisHarga(this.label, this.nilai, {super.key, this.tebal = false, this.warnaNilai});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: tebal ? 14 : 13,
                      color: tebal ? C.tinta : C.abu,
                      fontWeight: tebal ? FontWeight.w600 : FontWeight.w400)),
            ),
            Text(nilai,
                style: TextStyle(
                    fontSize: tebal ? 18 : 13,
                    fontWeight: tebal ? FontWeight.w700 : FontWeight.w500,
                    color: warnaNilai ?? (tebal ? C.daun : C.tinta))),
          ],
        ),
      );
}
