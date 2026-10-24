import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_nav.dart';
import 'menunggu_bayar_page.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  String _filter = 'semua';

  bool _cocok(Notif n) => switch (_filter) {
        'pesanan' => n.tipe == 'pesanan' || n.tipe == 'bayar',
        'promo' => n.tipe == 'promo',
        _ => true,
      };

  String _grup(DateTime d) {
    final now = DateTime.now();
    final hari = DateTime(now.year, now.month, now.day);
    final tgl = DateTime(d.year, d.month, d.day);
    final selisih = hari.difference(tgl).inDays;
    if (selisih == 0) return 'Hari ini';
    if (selisih == 1) return 'Kemarin';
    return 'Sebelumnya';
  }

  void _buka(Notif n) {
    final s = AppStore.i;
    s.bacaNotif(n);
    if (n.idPesanan == null) return;
    final p = s.cariPesanan(n.idPesanan!);
    if (p != null && p.status == 'menunggu') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenungguBayarPage(idPesanan: p.id)));
    } else {
      MainNav.pindah(context, 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;
    return ListenableBuilder(
      listenable: AppStore.i,
      builder: (context, _) {
        final s = AppStore.i;
        final list = s.notif.where(_cocok).toList();
        final jPesanan = s.notif.where((n) => !n.dibaca && (n.tipe == 'pesanan' || n.tipe == 'bayar')).length;
        final jPromo = s.notif.where((n) => !n.dibaca && n.tipe == 'promo').length;

        final isi = <Widget>[];
        String? grupLalu;
        for (final n in list) {
          final g = _grup(n.waktu);
          if (g != grupLalu) {
            isi.add(Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(g, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.abu)),
            ));
            grupLalu = g;
          }
          isi.add(_kartu(n));
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE6F5A3), C.latar],
              stops: [0, 0.28],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, atas + 16, 20, 130),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notifikasi', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                        Text(s.belumDibaca == 0 ? 'Semua sudah dibaca' : '${s.belumDibaca} belum dibaca',
                            style: const TextStyle(fontSize: 12, color: C.abu)),
                      ],
                    ),
                  ),
                  if (s.belumDibaca > 0)
                    Material(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: s.bacaSemua,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: Text('Tandai dibaca',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.tautan)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  _chip('semua', 'Semua'),
                  _chip('pesanan', jPesanan > 0 ? 'Pesanan · $jPesanan' : 'Pesanan'),
                  _chip('promo', jPromo > 0 ? 'Promo · $jPromo' : 'Promo'),
                ],
              ),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Kosong(
                    ikon: Icons.notifications_off_outlined,
                    judul: 'Belum ada notifikasi',
                    isi: 'Info promo dan status pesanan akan muncul di sini.',
                  ),
                )
              else
                ...isi,
              const SizedBox(height: 16),
              _kartuVoucher(),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String id, String label) {
    final aktif = _filter == id;
    return GestureDetector(
      onTap: () => setState(() => _filter = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: aktif ? C.daun : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: aktif ? FontWeight.w600 : FontWeight.w400, color: aktif ? Colors.white : C.tinta)),
      ),
    );
  }

  Widget _kartu(Notif n) {
    final (ikon, bg, fg) = switch (n.tipe) {
      'bayar' => (Icons.schedule_rounded, C.kuningPucat, C.coklatKuning),
      'promo' => (Icons.local_offer_outlined, C.kuningPucat, C.coklatKuning),
      'pesanan' => (Icons.local_shipping_outlined, C.hijauPucat, C.daun),
      _ => (Icons.eco_rounded, C.hijauPucat, C.daun),
    };
    final p = n.idPesanan == null ? null : AppStore.i.cariPesanan(n.idPesanan!);
    final bisaBayar = n.tipe == 'bayar' && p != null && p.status == 'menunggu';
    return Dismissible(
      key: ObjectKey(n),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => AppStore.i.hapusNotif(n),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: C.merah, borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _buka(n),
        child: Opacity(
          opacity: n.dibaca ? 0.8 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: n.dibaca ? Colors.white.withValues(alpha: 0.6) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: n.dibaca ? null : bayangan(),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                  child: Icon(ikon, size: 20, color: fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.judul, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(n.isi, style: const TextStyle(fontSize: 12, color: C.abu, height: 1.4)),
                      if (bisaBayar)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: C.daun, borderRadius: BorderRadius.circular(10)),
                          child: const Text('Bayar sekarang',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(waktuLalu(n.waktu), style: const TextStyle(fontSize: 11, color: C.tautan)),
                        ),
                    ],
                  ),
                ),
                if (!n.dibaca)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 6, top: 4),
                    decoration: const BoxDecoration(color: Color(0xFFE0B400), shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kartuVoucher() {
    final s = AppStore.i;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: daun(26, 8),
        gradient: const LinearGradient(colors: [C.daun, Color(0xFF4E8A34)]),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -14,
            child: Pudar.bulat(
              child: Image.asset('assets/images/product_1.jpg', width: 130, height: 130, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KHUSUS KAMU',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.limeTerang)),
                const Text('Voucher ${AppStore.kodeVoucher}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const Text('Diskon 10%, maks Rp10.000',
                    style: TextStyle(fontSize: 11, color: Color(0xD9FFFFFF))),
                const SizedBox(height: 10),
                Material(
                  color: s.voucherDiklaim ? Colors.white24 : C.kuning,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: s.voucherDiklaim ? null : s.klaimVoucher,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: Text(s.voucherDiklaim ? 'Sudah diklaim' : 'Klaim sekarang',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: s.voucherDiklaim ? Colors.white : C.tinta)),
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
}
