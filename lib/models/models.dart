/// Model data Vegetable App.
///
/// Bentuk data dari API BTNG (GET https://api-mobile.dnccudinus.org/api/vegetables):
/// { "id": 1, "nama": "Bayam Hijau", "kategori": "Sayuran Daun",
///   "harga": 3500, "gambar": "https://...", "deskripsi": "..." }
library;

int keInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

class Sayur {
  final int id;
  final String nama;
  final String kategori;
  final int harga; // harga per pack dari API
  final String gambar;
  final String deskripsi;
  final Map<String, dynamic> lainnya; // field tambahan dari endpoint detail

  const Sayur({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.harga,
    required this.gambar,
    required this.deskripsi,
    this.lainnya = const {},
  });

  static const _utama = {
    'id', 'nama', 'kategori', 'harga', 'gambar', 'deskripsi',
    'created_at', 'updated_at', 'createdAt', 'updatedAt',
  };

  factory Sayur.fromJson(Map<String, dynamic> j) {
    final lain = <String, dynamic>{};
    j.forEach((k, v) {
      if (!_utama.contains(k) && v != null && v is! Map && v is! List) lain[k] = v;
    });
    return Sayur(
      id: keInt(j['id']),
      nama: '${j['nama'] ?? '-'}',
      kategori: '${j['kategori'] ?? 'Lainnya'}',
      harga: keInt(j['harga']),
      gambar: '${j['gambar'] ?? ''}',
      deskripsi: '${j['deskripsi'] ?? ''}',
      lainnya: lain,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'kategori': kategori,
        'harga': harga,
        'gambar': gambar,
        'deskripsi': deskripsi,
      };
}

/// Pilihan ukuran di halaman detail. Faktor dikalikan harga per pack dari API.
class Ukuran {
  final String label;
  final double faktor;
  const Ukuran(this.label, this.faktor);

  static const semua = [
    Ukuran('½ pack', 0.55),
    Ukuran('1 pack', 1),
    Ukuran('2 pack', 1.85),
  ];

  int harga(int hargaPack) => (hargaPack * faktor / 100).round() * 100;
}

class ItemKeranjang {
  final Sayur sayur;
  final int ukuran; // index Ukuran.semua
  int qty;
  ItemKeranjang(this.sayur, this.ukuran, this.qty);

  String get kunci => '${sayur.id}-$ukuran';
  String get labelUkuran => Ukuran.semua[ukuran].label;
  int get hargaSatuan => Ukuran.semua[ukuran].harga(sayur.harga);
  int get subtotal => hargaSatuan * qty;

  Map<String, dynamic> toJson() => {'sayur': sayur.toJson(), 'ukuran': ukuran, 'qty': qty};

  factory ItemKeranjang.fromJson(Map<String, dynamic> j) => ItemKeranjang(
        Sayur.fromJson(Map<String, dynamic>.from(j['sayur'] as Map)),
        keInt(j['ukuran']).clamp(0, Ukuran.semua.length - 1).toInt(),
        keInt(j['qty']),
      );
}

/// Metode pembayaran.
class Metode {
  final String id;
  final String nama;
  final String grup; // qris, ewallet, va, cod
  final String? info;
  const Metode(this.id, this.nama, this.grup, [this.info]);

  static const semua = [
    Metode('qris', 'QRIS', 'qris', 'Semua e-wallet & m-banking'),
    Metode('gopay', 'GoPay', 'ewallet'),
    Metode('ovo', 'OVO', 'ewallet'),
    Metode('dana', 'DANA', 'ewallet'),
    Metode('bca', 'BCA Virtual Account', 'va', 'Kode bank 014'),
    Metode('bri', 'BRI Virtual Account', 'va', 'Kode bank 002'),
    Metode('cod', 'Bayar di tempat', 'cod', 'Tunai ke kurir'),
  ];

  static Metode cari(String id) =>
      semua.firstWhere((m) => m.id == id, orElse: () => semua.first);
}

class Pesanan {
  final String id;
  final DateTime dibuat;
  final List<ItemKeranjang> item;
  final int ongkir;
  final int diskon;
  final int biayaLayanan;
  final String metode; // id Metode
  final String alamat;
  final String jadwal; // contoh "Sab, 24 Okt · 13.00–15.00"
  final bool diantar;
  final String catatan;
  String status; // menunggu, dibayar, selesai, batal
  DateTime? dibayarPada;

  Pesanan({
    required this.id,
    required this.dibuat,
    required this.item,
    required this.ongkir,
    required this.diskon,
    required this.biayaLayanan,
    required this.metode,
    required this.alamat,
    required this.jadwal,
    required this.diantar,
    required this.catatan,
    required this.status,
    this.dibayarPada,
  });

  int get subtotal => item.fold(0, (a, b) => a + b.subtotal);
  int get total => subtotal - diskon + ongkir + biayaLayanan;
  int get jumlahBarang => item.fold(0, (a, b) => a + b.qty);
  Metode get metodeBayar => Metode.cari(metode);

  /// Batas bayar 15 menit setelah pesanan dibuat.
  DateTime get batasBayar => dibuat.add(const Duration(minutes: 15));

  bool get berlangsung => status == 'menunggu' || status == 'dibayar';

  /// 0 = menunggu bayar, 1 = dikemas, 2 = dikirim, 3 = selesai, -1 = batal.
  /// Setelah dibayar, pesanan dianggap "dikemas" 3 menit lalu "dikirim".
  int get tahap {
    switch (status) {
      case 'menunggu':
        return 0;
      case 'selesai':
        return 3;
      case 'batal':
        return -1;
      default:
        final sejak = DateTime.now().difference(dibayarPada ?? dibuat);
        return sejak.inMinutes < 3 ? 1 : 2;
    }
  }

  String get labelStatus => switch (tahap) {
        0 => 'Menunggu Bayar',
        1 => 'Dikemas',
        2 => diantar ? 'Dikirim' : 'Siap diambil',
        3 => 'Selesai',
        _ => 'Dibatalkan',
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'dibuat': dibuat.toIso8601String(),
        'item': item.map((e) => e.toJson()).toList(),
        'ongkir': ongkir,
        'diskon': diskon,
        'biayaLayanan': biayaLayanan,
        'metode': metode,
        'alamat': alamat,
        'jadwal': jadwal,
        'diantar': diantar,
        'catatan': catatan,
        'status': status,
        'dibayarPada': dibayarPada?.toIso8601String(),
      };

  factory Pesanan.fromJson(Map<String, dynamic> j) => Pesanan(
        id: '${j['id']}',
        dibuat: DateTime.tryParse('${j['dibuat']}') ?? DateTime.now(),
        item: (j['item'] as List)
            .map((e) => ItemKeranjang.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        ongkir: keInt(j['ongkir']),
        diskon: keInt(j['diskon']),
        biayaLayanan: keInt(j['biayaLayanan']),
        metode: '${j['metode']}',
        alamat: '${j['alamat']}',
        jadwal: '${j['jadwal'] ?? ''}',
        diantar: j['diantar'] != false,
        catatan: '${j['catatan'] ?? ''}',
        status: '${j['status']}',
        dibayarPada: j['dibayarPada'] == null ? null : DateTime.tryParse('${j['dibayarPada']}'),
      );
}

class Notif {
  final String judul;
  final String isi;
  final String tipe; // promo, pesanan, bayar, info
  final DateTime waktu;
  final String? idPesanan;
  bool dibaca;

  Notif({
    required this.judul,
    required this.isi,
    required this.tipe,
    required this.waktu,
    this.idPesanan,
    this.dibaca = false,
  });

  Map<String, dynamic> toJson() => {
        'judul': judul,
        'isi': isi,
        'tipe': tipe,
        'waktu': waktu.toIso8601String(),
        'idPesanan': idPesanan,
        'dibaca': dibaca,
      };

  factory Notif.fromJson(Map<String, dynamic> j) => Notif(
        judul: '${j['judul']}',
        isi: '${j['isi']}',
        tipe: '${j['tipe']}',
        waktu: DateTime.tryParse('${j['waktu']}') ?? DateTime.now(),
        idPesanan: j['idPesanan'] as String?,
        dibaca: j['dibaca'] == true,
      );
}
