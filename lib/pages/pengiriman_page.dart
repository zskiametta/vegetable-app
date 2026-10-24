import 'package:flutter/material.dart';

import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'pembayaran_page.dart';

/// Langkah 2 dari alur bayar: alamat, jadwal antar, cara terima.
class PengirimanPage extends StatefulWidget {
  const PengirimanPage({super.key});

  @override
  State<PengirimanPage> createState() => _PengirimanPageState();
}

class _PengirimanPageState extends State<PengirimanPage> {
  final _catatan = TextEditingController();
  int _hari = 0;
  int? _slot;
  bool _diantar = true;

  static const _slotJam = [(7, 9), (10, 12), (13, 15), (16, 18)];

  DateTime get _tanggal => DateTime.now().add(Duration(days: _hari));

  /// Slot hari ini yang sudah lewat (kurang dari 1 jam lagi) tidak bisa dipilih.
  bool _tersedia(int i) => _hari > 0 || DateTime.now().hour + 1 < _slotJam[i].$1;

  @override
  void initState() {
    super.initState();
    _slot = _slotPertama();
    if (_slot == null) {
      _hari = 1;
      _slot = 0;
    }
  }

  int? _slotPertama() {
    for (int i = 0; i < _slotJam.length; i++) {
      if (_tersedia(i)) return i;
    }
    return null;
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  String get _jadwal {
    final d = _tanggal;
    final (a, b) = _slotJam[_slot ?? 0];
    return '${hariPendek[d.weekday - 1]}, ${tanggalPendek(d)} · ${dua(a)}.00–${dua(b)}.00';
  }

  Future<void> _ubahAlamat() async {
    final ctrl = TextEditingController(text: AppStore.i.alamat);
    final hasil = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Alamat pengiriman', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama jalan, nomor rumah, kecamatan, kota',
            fillColor: C.latar,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Simpan')),
        ],
      ),
    );
    if (hasil != null && hasil.trim().isNotEmpty) {
      await AppStore.i.ubahProfil(nama: AppStore.i.nama, hp: AppStore.i.hp, alamat: hasil);
    }
  }

  void _lanjut() {
    if (_diantar && AppStore.i.alamat.trim().length < 8) {
      kabari(context, 'Isi alamat pengiriman dulu, ya.');
      _ubahAlamat();
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PembayaranPage(
        diantar: _diantar,
        jadwal: _diantar ? _jadwal : 'Ambil sendiri · $_jadwal',
        catatan: _catatan.text,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.i,
      builder: (context, _) {
        final s = AppStore.i;
        final ongkir = s.ongkirUntuk(true);
        final totalBelanja = s.subtotal - s.diskonVoucher;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE6F5A3), C.latar],
                stops: [0, 0.25],
              ),
            ),
            child: Column(
              children: [
                const HeaderHalaman('Pengiriman'),
                const LangkahBayar(2),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      _kartuAlamat(),
                      const SizedBox(height: 18),
                      const Text('Jadwal antar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (int i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(child: _pilihHari(i)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (int i = 0; i < _slotJam.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(child: _pilihSlot(i)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text('Cara terima', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _caraTerima(
                        true,
                        Icons.local_shipping_outlined,
                        'Diantar kurir Vegetable App',
                        'Tiba sesuai jadwal di atas',
                        ongkir == 0 ? 'Gratis' : rupiah(ongkir),
                      ),
                      const SizedBox(height: 8),
                      _caraTerima(false, Icons.storefront_outlined, 'Ambil sendiri',
                          'Gudang Vegetable App, Jl. Pandanaran 12', 'Gratis'),
                      const SizedBox(height: 18),
                      const Text('Catatan untuk kurir',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: bayangan(0.07)),
                        child: TextField(
                          controller: _catatan,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                              hintText: 'Contoh: pagar hijau, titip ke satpam kalau tidak ada orang'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: PanelBawah(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Belanja + ongkir', style: TextStyle(fontSize: 11, color: C.abu)),
                    Text(rupiah(totalBelanja + s.ongkirUntuk(_diantar)),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(child: TombolUtama('Pilih Pembayaran', ikon: Icons.arrow_forward_rounded, onTap: _lanjut)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kartuAlamat() {
    final s = AppStore.i;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: bayangan()),
      child: Column(
        children: [
          // mini peta dekoratif
          SizedBox(
            height: 84,
            child: CustomPaint(
              painter: _PetaMini(),
              child: const Center(child: Icon(Icons.location_on_rounded, size: 38, color: C.daun)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Rumah', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: C.hijauPucat, borderRadius: BorderRadius.circular(10)),
                            child: const Text('Utama',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: C.daun)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${s.namaDepan} · ${s.hp}', style: const TextStyle(fontSize: 12, color: C.abu)),
                      Text(s.alamat.isEmpty ? 'Alamat belum diisi' : s.alamat,
                          style: TextStyle(fontSize: 12, color: s.alamat.isEmpty ? C.merah : C.abu)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _ubahAlamat,
                  child: const Text('Ubah', style: TextStyle(fontWeight: FontWeight.w600, color: C.tautan)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pilihHari(int i) {
    final d = DateTime.now().add(Duration(days: i));
    final aktif = _hari == i;
    return GestureDetector(
      onTap: () => setState(() {
        _hari = i;
        if (_slot == null || !_tersedia(_slot!)) _slot = _slotPertama();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: aktif ? C.daun : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: aktif ? null : bayangan(0.07),
        ),
        child: Column(
          children: [
            Text(['Hari ini', 'Besok', 'Lusa'][i],
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: aktif ? Colors.white : C.tinta)),
            Text('${hariPendek[d.weekday - 1]}, ${tanggalPendek(d)}',
                style: TextStyle(fontSize: 10, color: aktif ? C.limeTerang : C.abu)),
          ],
        ),
      ),
    );
  }

  Widget _pilihSlot(int i) {
    final bisa = _tersedia(i);
    final aktif = _slot == i && bisa;
    final (a, b) = _slotJam[i];
    return GestureDetector(
      onTap: bisa ? () => setState(() => _slot = i) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: !bisa ? C.hijauPucat : (aktif ? C.kuning : Colors.white),
          borderRadius: BorderRadius.circular(14),
          boxShadow: bisa && !aktif ? bayangan(0.07) : null,
        ),
        child: Text('${dua(a)}–${dua(b)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
              color: bisa ? C.tinta : C.abuMuda,
              decoration: bisa ? null : TextDecoration.lineThrough,
            )),
      ),
    );
  }

  Widget _caraTerima(bool diantar, IconData ikon, String judul, String sub, String harga) {
    final aktif = _diantar == diantar;
    return GestureDetector(
      onTap: () => setState(() => _diantar = diantar),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: aktif ? const Color(0xFF9CC45A) : Colors.transparent, width: 1.6),
          boxShadow: aktif ? null : bayangan(0.07),
        ),
        child: Row(
          children: [
            Icon(ikon, color: aktif ? C.daun : C.abu),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(sub, style: const TextStyle(fontSize: 11, color: C.abu)),
                ],
              ),
            ),
            Text(harga,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: harga == 'Gratis' ? C.tautan : C.tinta)),
          ],
        ),
      ),
    );
  }
}

/// Garis-garis peta dekoratif untuk kartu alamat.
class _PetaMini extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = C.hijauPucat);
    final strip = Paint()..color = C.latar;
    for (double x = -size.height; x < size.width; x += 28) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + 14, size.height)
        ..lineTo(x + 14 + size.height * 0.7, 0)
        ..lineTo(x + size.height * 0.7, 0)
        ..close();
      canvas.drawPath(path, strip);
    }
    final jalan = Paint()
      ..color = Colors.white
      ..strokeWidth = 7;
    canvas.drawLine(Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.45), jalan);
    canvas.drawLine(Offset(size.width * 0.55, 0), Offset(size.width * 0.48, size.height), jalan);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
