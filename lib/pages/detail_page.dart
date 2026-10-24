import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'keranjang_page.dart';

class DetailPage extends StatefulWidget {
  final Sayur sayur;
  const DetailPage({super.key, required this.sayur});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late final Future<Sayur> _detail = ApiService.getDetail(widget.sayur.id); // GET /api/vegetables/:id
  int _ukuran = 1;
  int _qty = 1;
  int _foto = 0;
  bool _lengkap = false;

  static const _sudutFoto = [Alignment.center, Alignment(-0.7, -0.6), Alignment(0.7, 0.6)];

  List<String> _ideMasak(String kategori) {
    final k = kategori.toLowerCase();
    if (k.contains('daun')) return ['Tumis', 'Sup bening', 'Lalapan', 'Pecel'];
    if (k.contains('buah')) return ['Sambal', 'Balado', 'Sayur asem', 'Salad'];
    if (k.contains('umbi')) return ['Sayur sop', 'Perkedel', 'Kari', 'Gorengan'];
    if (k.contains('bumbu') || k.contains('rempah')) return ['Bumbu dasar', 'Sambal', 'Wedang'];
    return ['Tumis', 'Sup', 'Salad'];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Sayur>(
      future: _detail,
      builder: (context, snap) {
        final s = snap.data ?? widget.sayur;
        final memuat = snap.connectionState != ConnectionState.done;
        final harga = Ukuran.semua[_ukuran].harga(s.harga);
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _atas(s),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _lembar(s, memuat, harga),
                ),
              ],
            ),
          ),
          bottomNavigationBar: PanelBawah(
            child: Row(
              children: [
                Jumlah(nilai: _qty, minimal: 1, onUbah: (v) => setState(() => _qty = v)),
                const SizedBox(width: 12),
                Expanded(
                  child: TombolUtama(
                    'Tambah',
                    harga: rupiah(harga * _qty),
                    onTap: () {
                      tambahDanKabari(context, s, ukuran: _ukuran, qty: _qty);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------- foto
  Widget _atas(Sayur s) {
    final atas = MediaQuery.of(context).padding.top;
    return Container(
      height: 420 + atas,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE4F4A0), Color(0xFFF6EFB0)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: atas + 10,
            left: 20,
            right: 20,
            child: Row(
              children: [
                TombolKaca(Icons.arrow_back_rounded, label: 'Kembali', onTap: () => Navigator.pop(context)),
                const Expanded(
                  child: Text('Detail Produk',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                ListenableBuilder(
                  listenable: AppStore.i,
                  builder: (context, _) {
                    final fav = AppStore.i.isFavorit(s.id);
                    return TombolKaca(
                      fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      label: fav ? 'Hapus dari favorit' : 'Tambah ke favorit',
                      warnaIkon: fav ? const Color(0xFFD4A900) : C.tinta,
                      onTap: () => AppStore.i.toggleFavorit(s),
                    );
                  },
                ),
              ],
            ),
          ),
          // cahaya lembut di belakang foto
          Positioned(
            left: 70,
            right: -10,
            top: atas + 80,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0xCCFFFFFF), Color(0x00FFFFFF)]),
              ),
            ),
          ),
          Positioned(
            left: 80,
            right: 0,
            top: atas + 84,
            height: 290,
            child: Hero(
              tag: 'sayur-${s.id}',
              child: Pudar.bulat(
                child: NetImg(s.gambar,
                    id: s.id,
                    radius: 0,
                    alignment: _sudutFoto[_foto],
                    blend: const Color(0xFFF1F3B0)),
              ),
            ),
          ),
          // bayangan di bawah sayur
          Positioned(
            left: 160,
            right: 80,
            top: atas + 366,
            height: 14,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: C.daun.withValues(alpha: 0.18), blurRadius: 12)],
              ),
            ),
          ),
          // thumbnail vertikal
          Positioned(
            left: 20,
            top: atas + 100,
            child: Column(
              children: [
                for (int i = 0; i < _sudutFoto.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Semantics(
                      button: true,
                      label: 'Foto ${i + 1}',
                      child: GestureDetector(
                        onTap: () => setState(() => _foto = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _foto == i ? C.daun : Colors.white, width: 2),
                          ),
                          child: NetImg(s.gambar,
                              id: s.id, radius: 14, width: 52, height: 52, alignment: _sudutFoto[i]),
                        ),
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

  // ---------------------------------------------------------------- isi
  Widget _lembar(Sayur s, bool memuat, int harga) {
    final hemat = (s.harga * 2) - Ukuran.semua[2].harga(s.harga);
    final saran = AppStore.i.katalog.where((x) => x.id != s.id).toList()
      ..sort((a, b) => (a.kategori == s.kategori ? 1 : 0).compareTo(b.kategori == s.kategori ? 1 : 0));
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
      decoration: BoxDecoration(
        color: C.latar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [BoxShadow(color: C.daun.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, -10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 6, children: [
            _chip(s.kategori, C.lime),
            _chip('Petani lokal', C.kuningPucat),
          ]),
          const SizedBox(height: 10),
          Text(s.nama, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
          if (memuat)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Memuat detail terbaru dari API...', style: TextStyle(fontSize: 11, color: C.abu)),
            ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rupiah(harga),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: C.daun)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('/ ${Ukuran.semua[_ukuran].label}',
                    style: const TextStyle(fontSize: 12, color: C.abu)),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text('Pilih ukuran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < Ukuran.semua.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _pilihanUkuran(i, s, i == 2 && hemat > 0 ? 'hemat ${rupiah(hemat)}' : null)),
              ],
            ],
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              _info(Icons.eco_rounded, '100%', 'Segar', C.hijauPucat, daun(18, 6)),
              const SizedBox(width: 8),
              _info(Icons.agriculture_rounded, 'Petani', 'Lokal', C.kuningPucat, daun(18, 6, true)),
              const SizedBox(width: 8),
              _info(Icons.local_shipping_rounded, 'Kirim', 'Hari ini', C.hijauPucat, daun(18, 6)),
            ],
          ),

          if (s.lainnya.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: bayangan(0.06)),
              child: Column(
                children: [
                  for (final e in s.lainnya.entries)
                    BarisHarga(_rapikan(e.key), '${e.value}'),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),
          const Text('Deskripsi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _lengkap = !_lengkap),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: s.deskripsi.isEmpty ? 'Belum ada deskripsi.' : s.deskripsi),
                if (s.deskripsi.length > 90)
                  TextSpan(
                    text: _lengkap ? '  Ringkas' : '  Selengkapnya',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: C.tautan),
                  ),
              ]),
              maxLines: _lengkap ? null : 3,
              overflow: _lengkap ? null : TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.7, color: C.abu),
            ),
          ),

          const SizedBox(height: 16),
          const Text('Cocok dimasak jadi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ide in _ideMasak(s.kategori))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: bayangan(0.06)),
                  child: Text(ide, style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),

          if (saran.length >= 2) ...[
            const SizedBox(height: 16),
            const Text('Sering dibeli bersama', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _saran(saran[0])),
                const SizedBox(width: 10),
                Expanded(child: _saran(saran[1])),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const KeranjangPage())),
              icon: const Icon(Icons.shopping_basket_outlined, size: 18, color: C.tautan),
              label: const Text('Lihat keranjang', style: TextStyle(color: C.tautan)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String t, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _pilihanUkuran(int i, Sayur s, String? catatan) {
    final aktif = _ukuran == i;
    return Semantics(
      button: true,
      selected: aktif,
      child: GestureDetector(
        onTap: () => setState(() => _ukuran = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: aktif ? C.daun : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: aktif ? null : bayangan(0.07),
          ),
          child: Column(
            children: [
              Text(Ukuran.semua[i].label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: aktif ? Colors.white : C.tinta)),
              Text(rupiah(Ukuran.semua[i].harga(s.harga)),
                  style: TextStyle(fontSize: 11, color: aktif ? C.limeTerang : C.abu)),
              if (catatan != null)
                Text(catatan,
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600, color: aktif ? C.kuning : C.tautan)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(IconData ikon, String a, String b, Color bg, BorderRadius r) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: r),
          child: Column(
            children: [
              Icon(ikon, size: 20, color: C.daunMuda),
              const SizedBox(height: 2),
              Text(a, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(b, style: const TextStyle(fontSize: 10, color: C.abu)),
            ],
          ),
        ),
      );

  Widget _saran(Sayur x) => GestureDetector(
        onTap: () => Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => DetailPage(sayur: x))),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration:
              BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: bayangan(0.06)),
          child: Row(
            children: [
              NetImg(x.gambar, id: x.id, width: 44, height: 44, radius: 12),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(x.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(rupiah(x.harga),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.daun)),
                  ],
                ),
              ),
              TombolPlus(ukuran: 28, onTap: () => tambahDanKabari(context, x)),
            ],
          ),
        ),
      );

  String _rapikan(String k) {
    final t = k.replaceAll('_', ' ');
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }
}
