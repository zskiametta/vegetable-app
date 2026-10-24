import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'keranjang_page.dart';
import 'menunggu_bayar_page.dart';
import 'sukses_page.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  bool _selesai = false;

  /// Total belanja 4 minggu terakhir (minggu ini paling kanan).
  List<int> _perMinggu(List<Pesanan> lunas) {
    final hasil = List.filled(4, 0);
    final now = DateTime.now();
    for (final p in lunas) {
      final minggu = now.difference(p.dibuat).inDays ~/ 7;
      if (minggu < 4) hasil[3 - minggu] += p.total;
    }
    return hasil;
  }

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;
    return ListenableBuilder(
      listenable: AppStore.i,
      builder: (context, _) {
        final s = AppStore.i;
        final berlangsung = s.pesanan.where((p) => p.berlangsung).toList();
        final lalu = s.pesanan.where((p) => !p.berlangsung).toList();
        final daftar = _selesai ? lalu : berlangsung;
        Pesanan? terakhirSelesai;
        for (final p in s.pesanan) {
          if (p.status == 'selesai') {
            terakhirSelesai = p;
            break;
          }
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE6F5A3), C.latar],
              stops: [0, 0.3],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, atas + 16, 20, 130),
            children: [
              const Text('Riwayat', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _ringkasan(s),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: [
                    _tab('Berlangsung · ${berlangsung.length}', !_selesai, () => setState(() => _selesai = false)),
                    _tab('Selesai · ${lalu.length}', _selesai, () => setState(() => _selesai = true)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (daftar.isEmpty)
                Kosong(
                  ikon: _selesai ? Icons.inventory_2_outlined : Icons.local_shipping_outlined,
                  judul: _selesai ? 'Belum ada pesanan selesai' : 'Tidak ada pesanan berjalan',
                  isi: _selesai
                      ? 'Pesanan yang sudah diterima akan tampil di sini.'
                      : 'Yuk belanja sayur segar dari Beranda.',
                )
              else
                for (final p in daftar) _KartuPesanan(p: p, onTap: () => _detail(p)),
              if (terakhirSelesai != null) ...[
                const JudulBagian('Beli lagi yang kemarin'),
                Row(
                  children: [
                    for (int i = 0; i < terakhirSelesai.item.length && i < 2; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: _beliLagi(terakhirSelesai.item[i])),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _ringkasan(AppStore s) {
    final minggu = _perMinggu(s.pesananLunas);
    final maks = minggu.fold(1, (a, b) => b > a ? b : a);
    return SizedBox(
      height: 126,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: C.daun, borderRadius: daun(24, 8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Belanja ${bulanPanjang[DateTime.now().month - 1]}',
                      style: const TextStyle(fontSize: 11, color: C.limeTerang)),
                  Text(rupiah(s.totalBelanjaBulanIni),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  SizedBox(
                    height: 30,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(width: 5),
                          Expanded(
                            child: FractionallySizedBox(
                              heightFactor: (0.15 + 0.85 * minggu[i] / maks).clamp(0.15, 1.0).toDouble(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: i == 3 ? C.kuning : Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 10,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: C.kuningPucat, borderRadius: daun(20, 8, true)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${s.pesanan.length}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        const Text('pesanan', style: TextStyle(fontSize: 10, color: Color(0xFF4A4200))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration:
                        BoxDecoration(color: Colors.white, borderRadius: daun(20, 8), boxShadow: bayangan(0.07)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          child: Text(rupiah(s.totalHemat),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.tautan)),
                        ),
                        const Text('dihemat', style: TextStyle(fontSize: 10, color: C.abu)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String t, bool aktif, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: aktif ? C.daun : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Text(t,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                    color: aktif ? Colors.white : C.daun)),
          ),
        ),
      );

  Widget _beliLagi(ItemKeranjang it) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            NetImg(it.sayur.gambar, id: it.sayur.id, width: 38, height: 38, radius: 12),
            const SizedBox(width: 8),
            Expanded(
              child: Text(it.sayur.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            TombolPlus(ukuran: 28, onTap: () => tambahDanKabari(context, it.sayur, ukuran: it.ukuran)),
          ],
        ),
      );

  void _detail(Pesanan p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.latar,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.94,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: C.garis, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text('Pesanan #${p.id}',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                ),
                LabelStatus(p),
              ],
            ),
            Text(tanggalIndo(p.dibuat), style: const TextStyle(fontSize: 12, color: C.abu)),
            const SizedBox(height: 14),
            if (p.tahap >= 1) ...[StatusPesanan(p: p), const SizedBox(height: 14)],
            for (final it in p.item)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    NetImg(it.sayur.gambar, id: it.sayur.id, width: 50, height: 50, radius: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.sayur.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${it.qty} × ${it.labelUkuran} · ${rupiah(it.hargaSatuan)}',
                              style: const TextStyle(fontSize: 11, color: C.abu)),
                        ],
                      ),
                    ),
                    Text(rupiah(it.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const Divider(color: C.garis, height: 20),
            _info(Icons.home_outlined, p.diantar ? 'Alamat' : 'Ambil di', p.diantar ? p.alamat : 'Gudang Vegetable App, Jl. Pandanaran 12'),
            _info(Icons.schedule_rounded, 'Jadwal', p.jadwal),
            _info(Icons.payments_outlined, 'Pembayaran', p.metodeBayar.nama),
            if (p.catatan.isNotEmpty) _info(Icons.sticky_note_2_outlined, 'Catatan', p.catatan),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: bayangan()),
              child: Column(
                children: [
                  BarisHarga('Subtotal', rupiah(p.subtotal)),
                  if (p.diskon > 0) BarisHarga('Diskon voucher', rupiah(-p.diskon), warnaNilai: C.tautan),
                  BarisHarga('Ongkos kirim', p.ongkir == 0 ? 'Gratis' : rupiah(p.ongkir)),
                  BarisHarga('Biaya layanan', rupiah(p.biayaLayanan)),
                  const Divider(color: C.garis, height: 16),
                  BarisHarga('Total', rupiah(p.total), tebal: true),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ..._aksi(ctx, p),
          ],
        ),
      ),
    );
  }

  List<Widget> _aksi(BuildContext ctx, Pesanan p) {
    switch (p.status) {
      case 'menunggu':
        return [
          TombolUtama('Bayar sekarang', harga: rupiah(p.total), onTap: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenungguBayarPage(idPesanan: p.id)));
          }),
        ];
      case 'dibayar':
        return [
          TombolUtama('Pesanan sudah diterima', ikon: Icons.check_rounded, onTap: () {
            AppStore.i.konfirmasiDiterima(p.id);
            Navigator.pop(ctx);
            kabari(context, 'Pesanan selesai. Terima kasih!');
          }),
          const SizedBox(height: 10),
          TombolKedua('Lihat struk', onTap: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => SuksesPage(idPesanan: p.id)));
          }),
        ];
      default:
        return [
          TombolUtama('Pesan lagi', ikon: Icons.replay_rounded, onTap: () {
            AppStore.i.pesanLagi(p);
            Navigator.pop(ctx);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KeranjangPage()));
          }),
        ];
    }
  }

  Widget _info(IconData i, String a, String b) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(i, size: 18, color: C.daunMuda),
            const SizedBox(width: 10),
            SizedBox(width: 88, child: Text(a, style: const TextStyle(fontSize: 12, color: C.abu))),
            Expanded(child: Text(b, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class LabelStatus extends StatelessWidget {
  final Pesanan p;
  const LabelStatus(this.p, {super.key});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (p.tahap) {
      0 => (C.kuningPucat, C.coklatKuning),
      3 => (C.lime, C.tinta),
      -1 => (const Color(0xFFFDE8E7), C.merah),
      _ => (C.hijauPucat, C.daun),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(p.labelStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _KartuPesanan extends StatelessWidget {
  final Pesanan p;
  final VoidCallback onTap;
  const _KartuPesanan({required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tahap = p.tahap;
    final keterangan = switch (tahap) {
      0 => 'bayar sebelum ${jam(p.batasBayar)}',
      1 => p.jadwal,
      2 => p.diantar ? 'kurir dalam perjalanan' : 'siap diambil di gudang',
      3 => tanggalIndo(p.dibuat),
      _ => 'tidak dibayar tepat waktu',
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: bayangan()),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 36.0 + (p.item.length.clamp(1, 3).toInt() - 1) * 26,
                  height: 36,
                  child: Stack(
                    children: [
                      for (int i = 0; i < p.item.length && i < 3; i++)
                        Positioned(
                          left: i * 26.0,
                          child: Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: NetImg(p.item[i].sayur.gambar,
                                id: p.item[i].sayur.id, width: 32, height: 32, radius: 16),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${p.id}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${p.jumlahBarang} barang · ${p.metodeBayar.nama}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: C.abu)),
                    ],
                  ),
                ),
                Text(rupiah(p.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.daun)),
              ],
            ),
            if (tahap >= 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: i < tahap || tahap == 3 ? C.daun : (i == tahap ? C.kuning : C.garis),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                LabelStatus(p),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(keterangan,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: C.abu)),
                ),
                const Text('Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.tautan)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
