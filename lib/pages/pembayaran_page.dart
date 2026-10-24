import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'menunggu_bayar_page.dart';
import 'sukses_page.dart';

/// Langkah 3 dari alur bayar: pilih metode pembayaran.
class PembayaranPage extends StatefulWidget {
  final bool diantar;
  final String jadwal;
  final String catatan;
  const PembayaranPage({super.key, required this.diantar, required this.jadwal, required this.catatan});

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  String _metode = 'qris';

  static const _warnaMerek = {
    'gopay': Color(0xFF00AED6),
    'ovo': Color(0xFF4C2A86),
    'dana': Color(0xFF118EEA),
    'bca': Color(0xFF0060AF),
    'bri': Color(0xFF00529C),
  };

  void _bayar() {
    final s = AppStore.i;
    if (s.keranjang.isEmpty) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    final p = s.buatPesanan(
      metode: _metode,
      alamat: s.alamat,
      jadwal: widget.jadwal,
      diantar: widget.diantar,
      catatan: widget.catatan,
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => p.status == 'menunggu' ? MenungguBayarPage(idPesanan: p.id) : SuksesPage(idPesanan: p.id),
      ),
      (r) => r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStore.i;
    final totalBelanja = s.subtotal - s.diskonVoucher;
    final ongkir = s.ongkirUntuk(widget.diantar);
    final total = totalBelanja + ongkir + AppStore.biayaLayanan;
    final m = Metode.cari(_metode);
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
            const HeaderHalaman('Pembayaran'),
            const LangkahBayar(3),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _grup('REKOMENDASI'),
                  _kartu([Metode.cari('qris')], disorot: true),
                  _grup('E-WALLET'),
                  _kartu(Metode.semua.where((x) => x.grup == 'ewallet').toList()),
                  _grup('TRANSFER VIRTUAL ACCOUNT'),
                  _kartu(Metode.semua.where((x) => x.grup == 'va').toList()),
                  _grup('LAINNYA'),
                  _kartu([Metode.cari('cod')]),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 14, color: C.abu),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Jadwal: ${widget.jadwal}',
                          style: const TextStyle(fontSize: 11, color: C.abu),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PanelBawah(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BarisHarga('Total belanja', rupiah(totalBelanja)),
            BarisHarga('Ongkos kirim', ongkir == 0 ? 'Gratis' : rupiah(ongkir),
                warnaNilai: ongkir == 0 ? C.tautan : null),
            BarisHarga('Biaya layanan', rupiah(AppStore.biayaLayanan)),
            const SizedBox(height: 10),
            TombolUtama(m.grup == 'cod' ? 'Pesan, bayar di tempat' : 'Bayar dengan ${m.grup == 'va' ? m.nama.split(' ').first + ' VA' : m.nama}',
                harga: rupiah(total), onTap: _bayar),
          ],
        ),
      ),
    );
  }

  Widget _grup(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8, left: 2),
        child: Text(t,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.abu, letterSpacing: 0.6)),
      );

  Widget _kartu(List<Metode> daftar, {bool disorot = false}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: bayangan(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (int i = 0; i < daftar.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFEEF3E2)),
              _baris(daftar[i], disorot),
            ],
          ],
        ),
      );

  Widget _baris(Metode m, bool disorot) {
    final aktif = _metode == m.id;
    Widget logo;
    if (_warnaMerek.containsKey(m.id)) {
      logo = Container(
        width: 46,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _warnaMerek[m.id], borderRadius: BorderRadius.circular(8)),
        child: Text(m.id.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
      );
    } else {
      logo = Container(
        width: 46,
        height: 42,
        decoration: BoxDecoration(color: C.hijauPucat, borderRadius: BorderRadius.circular(14)),
        child: Icon(m.grup == 'qris' ? Icons.qr_code_2_rounded : Icons.payments_outlined, color: C.daun),
      );
    }
    return Material(
      color: aktif ? C.hijauPucat.withValues(alpha: 0.6) : Colors.white,
      child: InkWell(
        onTap: () => setState(() => _metode = m.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              logo,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.nama, style: TextStyle(fontSize: 13, fontWeight: disorot ? FontWeight.w600 : FontWeight.w500)),
                    if (m.info != null) Text(m.info!, style: const TextStyle(fontSize: 11, color: C.abu)),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: aktif ? C.daun : const Color(0xFFC9D6B8), width: aktif ? 6 : 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
