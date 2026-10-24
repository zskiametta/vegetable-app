import 'package:flutter/material.dart';

import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'pengiriman_page.dart';

/// Langkah 1 dari alur bayar: Keranjang.
class KeranjangPage extends StatelessWidget {
  const KeranjangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.i,
      builder: (context, _) {
        final s = AppStore.i;
        final kosong = s.keranjang.isEmpty;
        final kurangGratis =
            AppStore.minGratisOngkir - (s.subtotal - s.diskonVoucher);
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
                HeaderHalaman('Keranjang',
                    kanan: Text('${s.jumlahKeranjang} barang',
                        style: const TextStyle(fontSize: 12, color: C.abu))),
                if (!kosong) const LangkahBayar(1),
                Expanded(
                  child: kosong
                      ? Kosong(
                          ikon: Icons.shopping_basket_outlined,
                          judul: 'Keranjang masih kosong',
                          isi: 'Pilih sayur segar dulu, nanti muncul di sini.',
                          aksi: SizedBox(
                            width: 200,
                            child: TombolUtama('Mulai belanja',
                                onTap: () => Navigator.pop(context)),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          children: [
                            for (final it in s.keranjang)
                              Dismissible(
                                key: ValueKey('k-${it.kunci}'),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => s.ubahQty(it.kunci, 0),
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.only(right: 24),
                                  alignment: Alignment.centerRight,
                                  decoration: BoxDecoration(
                                      color: C.merah,
                                      borderRadius: BorderRadius.circular(24)),
                                  child: const Icon(Icons.delete_rounded,
                                      color: Colors.white),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      topRight: Radius.circular(8),
                                      bottomLeft: Radius.circular(24),
                                      bottomRight: Radius.circular(24),
                                    ),
                                    boxShadow: bayangan(),
                                  ),
                                  child: Row(
                                    children: [
                                      NetImg(it.sayur.gambar,
                                          id: it.sayur.id,
                                          width: 66,
                                          height: 66),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(it.sayur.nama,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text(
                                                '${it.labelUkuran} · ${rupiah(it.hargaSatuan)}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: C.abu)),
                                            const SizedBox(height: 2),
                                            Text(rupiah(it.subtotal),
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: C.daun)),
                                          ],
                                        ),
                                      ),
                                      Jumlah(
                                        vertikal: true,
                                        nilai: it.qty,
                                        onUbah: (v) => s.ubahQty(it.kunci, v),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 6),
                              child: Text('Geser ke kiri untuk menghapus',
                                  style: TextStyle(fontSize: 11, color: C.abu)),
                            ),
                            _Voucher(),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: bayangan()),
                              child: Column(
                                children: [
                                  BarisHarga(
                                      'Subtotal (${s.jumlahKeranjang} barang)',
                                      rupiah(s.subtotal)),
                                  if (s.diskonVoucher > 0)
                                    BarisHarga('Diskon voucher',
                                        rupiah(-s.diskonVoucher),
                                        warnaNilai: C.tautan),
                                  const Divider(color: C.garis, height: 18),
                                  BarisHarga('Total belanja',
                                      rupiah(s.subtotal - s.diskonVoucher),
                                      tebal: true),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                        color: C.hijauPucat,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text(
                                      kurangGratis > 0
                                          ? 'Tambah ${rupiah(kurangGratis)} lagi untuk gratis ongkir'
                                          : 'Yeay, kamu dapat gratis ongkir!',
                                      style: const TextStyle(
                                          fontSize: 11, color: C.tautan),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: kosong
              ? null
              : PanelBawah(
                  child: TombolUtama(
                    'Lanjut ke Pengiriman',
                    ikon: Icons.arrow_forward_rounded,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PengirimanPage())),
                  ),
                ),
        );
      },
    );
  }
}

/// Tiket voucher dengan lubang di sisi kiri-kanan.
class _Voucher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppStore.i;
    final dipakai = s.voucherDiklaim && s.pakaiVoucher;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: C.kuningPucat,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD9BE2E), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.confirmation_number_outlined,
                  color: C.coklatKuning),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      !s.voucherDiklaim
                          ? 'Punya voucher?'
                          : (dipakai
                              ? '${AppStore.kodeVoucher} dipakai'
                              : AppStore.kodeVoucher),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      !s.voucherDiklaim
                          ? 'Klaim ${AppStore.kodeVoucher}: diskon 10% (maks Rp10.000)'
                          : (s.subtotal < 20000
                              ? 'Min. belanja Rp20.000'
                              : (dipakai
                                  ? 'Hemat ${rupiah(s.diskonVoucher)}'
                                  : 'Diskon 10%, maks Rp10.000')),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF4A4200)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  if (!s.voucherDiklaim) {
                    s.klaimVoucher();
                  } else {
                    s.setPakaiVoucher(!s.pakaiVoucher);
                  }
                },
                child: Text(
                    !s.voucherDiklaim ? 'Klaim' : (dipakai ? 'Lepas' : 'Pakai'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Color(0xFF4A4200))),
              ),
            ],
          ),
        ),
        for (final kiri in [true, false])
          Positioned(
            left: kiri ? -9 : null,
            right: kiri ? null : -9,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration:
                    const BoxDecoration(color: C.latar, shape: BoxShape.circle),
              ),
            ),
          ),
      ],
    );
  }
}
