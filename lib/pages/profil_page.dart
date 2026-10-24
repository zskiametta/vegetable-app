import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth_page.dart';
import 'detail_page.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  static (String, int, String?) level(int poin) {
    if (poin < 1000) return ('Tunas', 1000, 'Daun Muda');
    if (poin < 3000) return ('Daun Muda', 3000, 'Pohon Rindang');
    return ('Pohon Rindang', poin, null);
  }

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;
    return ListenableBuilder(
      listenable: AppStore.i,
      builder: (context, _) {
        final s = AppStore.i;
        final (lvl, target, berikut) = level(s.poin);
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
              Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: daun(28, 8),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: bayangan(0.18),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/people.jpg'),
                        fit: BoxFit.cover,
                        alignment: Alignment(0, -0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.25)),
                        Text(s.hp, style: const TextStyle(fontSize: 12, color: C.abu)),
                      ],
                    ),
                  ),
                  TombolKaca(Icons.edit_outlined,
                      label: 'Edit profil',
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const EditProfilPage()))),
                ],
              ),
              const SizedBox(height: 18),

              // kartu member
              Container(
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: C.daun, borderRadius: BorderRadius.circular(26)),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -30,
                      top: -36,
                      child: Icon(Icons.eco_rounded, size: 140, color: C.limeTerang.withValues(alpha: 0.18)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Level member', style: TextStyle(fontSize: 11, color: C.limeTerang)),
                                  Text(lvl,
                                      style: const TextStyle(
                                          fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Poin', style: TextStyle(fontSize: 11, color: Color(0xCCFFFFFF))),
                                Text(rupiah(s.poin).replaceFirst('Rp', ''),
                                    style: const TextStyle(
                                        fontSize: 17, fontWeight: FontWeight.w700, color: C.kuning)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: berikut == null ? 1 : (s.poin / target).clamp(0.0, 1.0).toDouble(),
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(C.kuning),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          berikut == null
                              ? 'Level tertinggi! Gratis ongkir tiap minggu.'
                              : '${target - s.poin} poin lagi jadi $berikut · 1 poin tiap belanja Rp100',
                          style: const TextStyle(fontSize: 11, color: Color(0xD9FFFFFF)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // pintasan
              Row(
                children: [
                  _ubin(context, Icons.location_on_outlined, 'Alamat', Colors.white,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilPage()))),
                  const SizedBox(width: 8),
                  _ubin(context, Icons.credit_card_rounded, 'Pembayaran', Colors.white, () => _metodeBayar(context)),
                  const SizedBox(width: 8),
                  _ubin(context, Icons.confirmation_number_outlined, s.voucherDiklaim ? 'Voucher · 1' : 'Voucher',
                      C.kuningPucat, () => _voucher(context)),
                  const SizedBox(width: 8),
                  _ubin(context, Icons.favorite_border_rounded, 'Favorit · ${s.favorit.length}', Colors.white,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritPage()))),
                ],
              ),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: bayangan()),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _menu(Icons.person_outline_rounded, 'Edit Profil',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilPage()))),
                    _garis(),
                    _menu(Icons.help_outline_rounded, 'FAQ & Bantuan',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqPage()))),
                    _garis(),
                    _menu(Icons.info_outline_rounded, 'Tentang Aplikasi', () => _tentang(context)),
                    _garis(),
                    _menu(Icons.logout_rounded, 'Keluar', () => _keluar(context), bahaya: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Vegetable App v1.0 · TA BTNG 2026',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: C.abu)),
            ],
          ),
        );
      },
    );
  }

  Widget _ubin(BuildContext context, IconData ikon, String label, Color bg, VoidCallback onTap) => Expanded(
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Icon(ikon, color: bg == Colors.white ? C.daun : C.coklatKuning),
                  const SizedBox(height: 6),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _garis() => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEF3E2));

  Widget _menu(IconData ikon, String label, VoidCallback onTap, {bool bahaya = false}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(ikon, size: 20, color: bahaya ? C.merah : C.daunMuda),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: bahaya ? FontWeight.w600 : FontWeight.w500,
                        color: bahaya ? C.merah : C.tinta)),
              ),
              if (!bahaya) const Icon(Icons.chevron_right_rounded, color: C.abuMuda),
            ],
          ),
        ),
      );

  void _lembar(BuildContext context, String judul, List<Widget> isi) => showModalBottomSheet(
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
                Text(judul, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...isi,
              ],
            ),
          ),
        ),
      );

  void _metodeBayar(BuildContext context) => _lembar(context, 'Metode pembayaran', [
        const Text('Semua metode ini bisa dipilih saat checkout:', style: TextStyle(fontSize: 12, color: C.abu)),
        const SizedBox(height: 8),
        for (final m in Metode.semua)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: C.daunMuda),
                const SizedBox(width: 10),
                Text(m.nama, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
      ]);

  void _voucher(BuildContext context) => _lembar(context, 'Voucher saya', [
        ListenableBuilder(
          listenable: AppStore.i,
          builder: (context, _) {
            final s = AppStore.i;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.kuningPucat,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD9BE2E), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, color: C.coklatKuning),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStore.kodeVoucher, style: TextStyle(fontWeight: FontWeight.w700)),
                        Text('Diskon 10% (maks Rp10.000), min. belanja Rp20.000',
                            style: TextStyle(fontSize: 11, color: Color(0xFF4A4200))),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: s.voucherDiklaim ? null : s.klaimVoucher,
                    child: Text(s.voucherDiklaim ? 'Diklaim' : 'Klaim'),
                  ),
                ],
              ),
            );
          },
        ),
      ]);

  void _tentang(BuildContext context) => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Logo(size: 36),
          content: const Text(
            'Vegetable App adalah aplikasi belanja sayur segar dari petani lokal.\n\n'
            'Tugas Akhir BTNG 2026 · Divisi Mobile (Flutter)\n'
            'Dibuat oleh Zaskia Metta Dwi Saputri\n\n'
            'Data sayur dari BTNG Sayur API:\napi-mobile.dnccudinus.org',
            style: TextStyle(height: 1.5, fontSize: 13),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
        ),
      );

  Future<void> _keluar(BuildContext context) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluar dari akun?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text('Keranjang dan riwayatmu tetap tersimpan untuk login berikutnya.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: C.merah)),
          ),
        ],
      ),
    );
    if (ya != true || !context.mounted) return;
    await AppStore.i.keluar();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthPage()), (_) => false);
  }
}

// ====================================================================== EDIT PROFIL
class EditProfilPage extends StatefulWidget {
  const EditProfilPage({super.key});

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController(text: AppStore.i.nama);
  final _alamat = TextEditingController(text: AppStore.i.alamat);

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_form.currentState!.validate()) return;
    await AppStore.i.ubahProfil(nama: _nama.text, hp: AppStore.i.hp, alamat: _alamat.text);
    if (!mounted) return;
    kabari(context, 'Profil berhasil disimpan');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: gradasiHeader),
        child: Column(
          children: [
            const HeaderHalaman('Edit Profil'),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _label('Nomor HP (ID akun, tidak bisa diubah)'),
                    TextFormField(
                      initialValue: AppStore.i.hp,
                      enabled: false,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_iphone_rounded)),
                    ),
                    _label('Nama lengkap'),
                    TextFormField(
                      controller: _nama,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (v) => (v == null || v.trim().length < 3) ? 'Nama minimal 3 huruf' : null,
                    ),
                    _label('Alamat pengiriman'),
                    TextFormField(
                      controller: _alamat,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Nama jalan, nomor rumah, kecamatan, kota'),
                      validator: (v) => (v != null && v.trim().isNotEmpty && v.trim().length < 8)
                          ? 'Tulis alamat lebih lengkap'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PanelBawah(child: TombolUtama('Simpan perubahan', onTap: _simpan)),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6, left: 2),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
}

// ====================================================================== FAVORIT
class FavoritPage extends StatelessWidget {
  const FavoritPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: gradasiHeader),
        child: Column(
          children: [
            const HeaderHalaman('Sayur Favorit'),
            Expanded(
              child: ListenableBuilder(
                listenable: AppStore.i,
                builder: (context, _) {
                  final list = AppStore.i.favorit.values.toList();
                  if (list.isEmpty) {
                    return const Kosong(
                      ikon: Icons.favorite_border_rounded,
                      judul: 'Belum ada favorit',
                      isi: 'Ketuk ikon hati di halaman detail untuk menyimpan sayur.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      for (final s in list)
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => DetailPage(sayur: s))),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.white, borderRadius: daun(24, 8), boxShadow: bayangan()),
                            child: Row(
                              children: [
                                NetImg(s.gambar, id: s.id, width: 66, height: 66),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(s.kategori, style: const TextStyle(fontSize: 11, color: C.abu)),
                                      Text(rupiah(s.harga),
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: C.daun)),
                                    ],
                                  ),
                                ),
                                TombolPlus(onTap: () => tambahDanKabari(context, s)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================== FAQ
class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static const _faq = [
    ('Dari mana data sayurnya?',
        'Daftar, kategori, dan detail sayur diambil langsung dari BTNG Sayur API (api-mobile.dnccudinus.org).'),
    ('Berapa ongkos kirimnya?',
        'Rp5.000 per pesanan. Gratis untuk belanja minimal Rp50.000 atau kalau kamu ambil sendiri di gudang.'),
    ('Bagaimana cara bayar?',
        'Pilih QRIS, e-wallet, transfer Virtual Account, atau bayar di tempat. Batas pembayaran 15 menit.'),
    ('Kenapa pesananku batal?', 'Pesanan otomatis dibatalkan kalau belum dibayar dalam 15 menit.'),
    ('Bagaimana memakai voucher?', 'Klaim voucher di Beranda atau Profil, lalu voucher otomatis terpakai di keranjang.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: gradasiHeader),
          child: Column(
            children: [
              const HeaderHalaman('FAQ & Bantuan'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final (t, j) in _faq)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: bayangan()),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: C.daun,
                            collapsedIconColor: C.abuMuda,
                            title: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            children: [Text(j, style: const TextStyle(fontSize: 12, color: C.abu, height: 1.6))],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
