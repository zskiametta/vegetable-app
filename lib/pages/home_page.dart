import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail_page.dart';
import 'main_nav.dart';

/// Resep "Paket masak hari ini": bahan dicocokkan dengan nama sayur dari API.
class _Resep {
  final String nama;
  final List<String> kunci;
  final int porsi;
  const _Resep(this.nama, this.kunci, this.porsi);
}

const _daftarResep = [
  _Resep('Sayur Sop', ['wortel', 'kubis', 'kol', 'kentang', 'buncis', 'seledri', 'daun bawang'], 3),
  _Resep('Salad Segar', ['selada', 'tomat', 'timun', 'mentimun', 'wortel', 'jagung'], 2),
  _Resep('Capcay', ['sawi', 'brokoli', 'kembang kol', 'wortel', 'jamur', 'kubis'], 3),
  _Resep('Tumis Kangkung', ['kangkung', 'cabai', 'cabe', 'bawang', 'tomat'], 2),
  _Resep('Sayur Asem', ['labu', 'kacang panjang', 'jagung', 'melinjo', 'terong', 'kacang'], 4),
  _Resep('Gado-gado', ['bayam', 'kangkung', 'tauge', 'kentang', 'kacang panjang', 'kol', 'timun'], 3),
];

enum _Urut { rekomendasi, termurah, termahal, nama }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _cariCtrl = TextEditingController();
  late Future<List<Sayur>> _semua; // GET /api/vegetables
  late Future<List<String>> _kategori; // GET /api/vegetables/categories
  Future<List<Sayur>>? _tersaring; // GET /api/vegetables?kategori=&cari=
  String _pilih = 'Semua';
  String _cari = '';
  _Urut _urut = _Urut.rekomendasi;

  @override
  void initState() {
    super.initState();
    _muatSemua();
  }

  @override
  void dispose() {
    _cariCtrl.dispose();
    super.dispose();
  }

  void _muatSemua() {
    _semua = ApiService.getSayur().then((l) {
      AppStore.i.katalog = l;
      return l;
    });
    _kategori = ApiService.getKategori();
    _saring();
  }

  void _saring() {
    _tersaring = (_pilih == 'Semua' && _cari.isEmpty)
        ? null
        : ApiService.getSayur(kategori: _pilih == 'Semua' ? null : _pilih, cari: _cari);
  }

  bool get _modeCari => _pilih != 'Semua' || _cari.isNotEmpty;

  void _buka(Sayur s) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailPage(sayur: s)));

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6F5A3), C.latar],
          stops: [0, 0.35],
        ),
      ),
      child: RefreshIndicator(
        color: C.daun,
        onRefresh: () async {
          setState(_muatSemua);
          await _semua.catchError((_) => <Sayur>[]);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, atas + 12, 20, 130),
          children: [
            _sapaan(),
            const SizedBox(height: 20),
            const Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Mau masak\n'),
                TextSpan(text: 'apa hari ini?', style: TextStyle(color: C.tautan)),
              ]),
              style: TextStyle(fontSize: 30, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            _alamat(),
            const SizedBox(height: 16),
            _pencarian(),
            if (!_modeCari) ...[const SizedBox(height: 18), _bento()],
            JudulBagian('Kategori'),
            _kategoriBubble(),
            FutureBuilder<List<Sayur>>(
              future: _semua,
              builder: (context, snap) {
                if (_modeCari || !snap.hasData) return const SizedBox();
                return _paketMasak(snap.data!);
              },
            ),
            _daftarProduk(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _sapaan() => ListenableBuilder(
        listenable: AppStore.i,
        builder: (context, _) => Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 3),
                image: const DecorationImage(
                  image: AssetImage('assets/images/people.jpg'),
                  fit: BoxFit.cover,
                  alignment: Alignment(0, -0.6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sapaan(), style: const TextStyle(fontSize: 12, color: C.abu)),
                  Text(AppStore.i.namaDepan,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            TombolKaca(
              Icons.notifications_none_rounded,
              label: 'Notifikasi',
              onTap: () => MainNav.pindah(context, 1),
              badge: AppStore.i.belumDibaca > 0
                  ? Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0B400),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      );

  Widget _alamat() => ListenableBuilder(
        listenable: AppStore.i,
        builder: (context, _) => Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 15, color: C.tautan),
            const SizedBox(width: 4),
            const Text('Antar ke ', style: TextStyle(fontSize: 12, color: C.abu)),
            Expanded(
              child: Text(
                AppStore.i.alamat.isEmpty ? 'Atur alamat di Profil' : AppStore.i.alamat,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _pencarian() => Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: bayangan(0.10)),
              child: TextField(
                controller: _cariCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (v) => setState(() {
                  _cari = v.trim();
                  _saring();
                }),
                decoration: InputDecoration(
                  hintText: 'Cari bayam, wortel, cabai...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _cari.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _cariCtrl.clear();
                            _cari = '';
                            _saring();
                          }),
                        ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: 'Urutkan',
            child: Material(
              color: C.daun,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _pilihUrutan,
                child: const SizedBox(
                    width: 54, height: 54, child: Icon(Icons.tune_rounded, color: C.kuning)),
              ),
            ),
          ),
        ],
      );

  void _pilihUrutan() {
    const label = {
      _Urut.rekomendasi: 'Rekomendasi',
      _Urut.termurah: 'Harga termurah',
      _Urut.termahal: 'Harga termahal',
      _Urut.nama: 'Nama A–Z',
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: C.latar,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Urutkan produk', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final e in label.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.value),
                  trailing: Icon(
                    _urut == e.key ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: _urut == e.key ? C.daun : C.abuMuda,
                  ),
                  onTap: () {
                    setState(() => _urut = e.key);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- bento promo
  Widget _bento() => SizedBox(
        height: 218,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: AppStore.i,
                builder: (context, _) {
                  final klaim = AppStore.i.voucherDiklaim;
                  return Container(
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: daun(),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [C.daun, Color(0xFF4E8A34)],
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: -50,
                          bottom: -46,
                          child: Pudar.bulat(
                            child: Image.asset('assets/images/product_4.jpg',
                                width: 160, height: 160, fit: BoxFit.cover),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _chip('PROMO', C.kuning, C.tinta),
                            const SizedBox(height: 8),
                            const Text('Hemat 10%\npakai\n${AppStore.kodeVoucher}',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    height: 1.15,
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: klaim
                                    ? null
                                    : () {
                                        AppStore.i.klaimVoucher();
                                        kabari(context,
                                            'Voucher ${AppStore.kodeVoucher} siap dipakai di keranjang');
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Text(klaim ? 'Sudah diklaim ✓' : 'Klaim voucher',
                                      style: const TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w600, color: C.tinta)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: C.kuning, borderRadius: daun(28, 8, true)),
                      child: const Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gratis\nOngkir',
                                  style: TextStyle(fontSize: 15, height: 1.2, fontWeight: FontWeight.w700)),
                              Text('min. Rp50.000', style: TextStyle(fontSize: 10, color: Color(0xFF4A4200))),
                            ],
                          ),
                          Positioned(
                              right: 0,
                              bottom: 0,
                              child: Icon(Icons.local_shipping_outlined, size: 36, color: C.tinta)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: C.hijauPucat, borderRadius: daun()),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            right: -26,
                            bottom: -26,
                            child: Image.asset('assets/images/product_3.jpg',
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                color: C.hijauPucat,
                                colorBlendMode: BlendMode.multiply),
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Panen\nPagi',
                                  style: TextStyle(fontSize: 15, height: 1.2, fontWeight: FontWeight.w700)),
                              Text('dipetik subuh', style: TextStyle(fontSize: 10, color: C.abu)),
                            ],
                          ),
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

  Widget _chip(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
      );

  // ---------------------------------------------------------------- kategori
  Widget _kategoriBubble() => FutureBuilder<List<String>>(
        future: _kategori,
        builder: (context, snapKat) => FutureBuilder<List<Sayur>>(
          future: _semua,
          builder: (context, snapSayur) {
            final daftar = ['Semua', ...(snapKat.data ?? const <String>[])];
            final semua = snapSayur.data ?? const <Sayur>[];
            return SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: daftar.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final k = daftar[i];
                  final aktif = k == _pilih;
                  Sayur? contoh;
                  for (final s in semua) {
                    if (s.kategori == k) {
                      contoh = s;
                      break;
                    }
                  }
                  return Semantics(
                    button: true,
                    selected: aktif,
                    label: 'Kategori $k',
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _pilih = k;
                        _saring();
                      }),
                      child: SizedBox(
                        width: 66,
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 62,
                              height: 62,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: k == 'Semua' ? C.daun : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: aktif ? C.daun : Colors.transparent, width: 2.5),
                                boxShadow: bayangan(0.07),
                              ),
                              child: k == 'Semua'
                                  ? const Icon(Icons.grid_view_rounded, color: C.kuning)
                                  : NetImg(contoh?.gambar ?? '',
                                      id: contoh?.id ?? i, radius: 19, width: 62, height: 62),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              k.replaceFirst('Sayuran ', ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: aktif ? FontWeight.w700 : FontWeight.w400,
                                color: aktif ? C.tinta : C.abu,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

  // ---------------------------------------------------------------- paket masak
  Widget _paketMasak(List<Sayur> semua) {
    final paket = <(_Resep, List<Sayur>)>[];
    for (final r in _daftarResep) {
      final bahan = <Sayur>[];
      for (final s in semua) {
        final n = s.nama.toLowerCase();
        if (r.kunci.any(n.contains) && bahan.length < 4) bahan.add(s);
      }
      if (bahan.length >= 2) paket.add((r, bahan));
    }
    if (paket.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const JudulBagian('Paket masak hari ini', kanan: 'bahan sudah dipilihkan'),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: paket.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final (resep, bahan) = paket[i];
              final total = bahan.fold(0, (a, b) => a + b.harga);
              final kuning = i.isOdd;
              return GestureDetector(
                onTap: () => _lihatPaket(resep, bahan),
                child: Container(
                  width: 236,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kuning ? C.kuningPucat : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: kuning ? null : bayangan(),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        height: 64,
                        child: Stack(
                          children: [
                            for (int j = 0; j < bahan.length && j < 3; j++)
                              Positioned(
                                left: [0.0, 28.0, 12.0][j],
                                top: [0.0, 6.0, 26.0][j],
                                child: Container(
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2)),
                                  child: NetImg(bahan[j].gambar,
                                      id: bahan[j].id, width: 38, height: 38, radius: 19),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(resep.nama,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            Text('${bahan.length} bahan · ${resep.porsi} porsi',
                                style: TextStyle(
                                    fontSize: 11, color: kuning ? const Color(0xFF4A4200) : C.abu)),
                            const SizedBox(height: 2),
                            Text(rupiah(total),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: C.daun)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _lihatPaket(_Resep r, List<Sayur> bahan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.latar,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Paket ${r.nama}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('Untuk ${r.porsi} porsi', style: const TextStyle(color: C.abu, fontSize: 12)),
              const SizedBox(height: 12),
              for (final s in bahan)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      NetImg(s.gambar, id: s.id, width: 44, height: 44, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s.nama, style: const TextStyle(fontWeight: FontWeight.w500))),
                      Text(rupiah(s.harga), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              TombolUtama(
                'Tambah semua',
                harga: rupiah(bahan.fold(0, (a, b) => a + b.harga)),
                onTap: () {
                  for (final s in bahan) {
                    AppStore.i.tambahKeranjang(s);
                  }
                  Navigator.pop(ctx);
                  kabari(context, 'Paket ${r.nama} masuk keranjang');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- produk
  Widget _daftarProduk() => FutureBuilder<List<Sayur>>(
        future: _tersaring ?? _semua,
        builder: (context, snap) {
          final judul = _cari.isNotEmpty
              ? 'Hasil "$_cari"'
              : (_pilih == 'Semua' ? 'Pilihan segar' : _pilih);
          if (snap.connectionState != ConnectionState.done) {
            return Column(children: [
              JudulBagian(judul),
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: C.daun),
              ),
            ]);
          }
          if (snap.hasError) {
            return GagalMuat(onUlang: () => setState(_muatSemua));
          }
          final list = [...?snap.data];
          switch (_urut) {
            case _Urut.termurah:
              list.sort((a, b) => a.harga.compareTo(b.harga));
            case _Urut.termahal:
              list.sort((a, b) => b.harga.compareTo(a.harga));
            case _Urut.nama:
              list.sort((a, b) => a.nama.compareTo(b.nama));
            case _Urut.rekomendasi:
              break;
          }
          if (list.isEmpty) {
            return const Kosong(
                ikon: Icons.search_off_rounded,
                judul: 'Sayur tidak ditemukan',
                isi: 'Coba kata kunci atau kategori lain.');
          }
          final kiri = <Widget>[];
          final kanan = <Widget>[];
          for (int i = 0; i < list.length; i++) {
            final kartu = _KartuSayur(sayur: list[i], gaya: i % 4, onTap: () => _buka(list[i]));
            (i.isEven ? kiri : kanan).add(kartu);
          }
          return Column(
            children: [
              JudulBagian(judul, kanan: '${list.length} produk'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: kiri)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(children: kanan)),
                ],
              ),
            ],
          );
        },
      );
}

/// Kartu produk masonry. [gaya] 0..3 mengatur tinggi foto, warna & bentuk daun.
class _KartuSayur extends StatelessWidget {
  final Sayur sayur;
  final int gaya;
  final VoidCallback onTap;
  const _KartuSayur({required this.sayur, required this.gaya, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tinggi = gaya == 0 || gaya == 3;
    final warna = switch (gaya) {
      1 => C.kuningPucat,
      2 => C.hijauPucat,
      _ => Colors.white,
    };
    final bentuk = switch (gaya) {
      0 => const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28)),
      1 => const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28)),
      2 => const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(28)),
      _ => const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(8)),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: warna,
          borderRadius: bentuk,
          boxShadow: warna == Colors.white ? bayangan() : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'sayur-${sayur.id}',
                  child: NetImg(
                    sayur.gambar,
                    id: sayur.id,
                    width: double.infinity,
                    height: tinggi ? 150 : 100,
                    radius: 20,
                    blend: warna == Colors.white ? null : warna,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(sayur.kategori.replaceFirst('Sayuran ', ''),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(sayur.nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (tinggi)
              Text(sayur.deskripsi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: C.abu)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(rupiah(sayur.harga),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.daun)),
                ),
                TombolPlus(onTap: () => tambahDanKabari(context, sayur)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
