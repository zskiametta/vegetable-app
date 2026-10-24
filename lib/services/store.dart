import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Data lokal aplikasi (akun, keranjang, favorit, pesanan, notifikasi)
/// disimpan dengan shared_preferences supaya tetap ada saat app ditutup.
/// Data sayur sendiri SELALU diambil dari API (lihat api_service.dart).
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore i = AppStore._();

  // Akun demo (sudah terisi di form login)
  static const demoHp = '081234567890';
  static const demoSandi = 'zaskia123';

  static const kodeVoucher = 'PANEN10';
  static const minGratisOngkir = 50000;
  static const tarifOngkir = 5000;
  static const biayaLayanan = 1000;

  late SharedPreferences _p;
  List<Map<String, dynamic>> _akun = [];
  Map<String, dynamic>? user;

  List<ItemKeranjang> keranjang = [];
  Map<int, Sayur> favorit = {};
  List<Pesanan> pesanan = [];
  List<Notif> notif = [];
  bool voucherDiklaim = false;
  bool pakaiVoucher = true;

  /// Daftar sayur terakhir dari API (untuk saran "sering dibeli bersama").
  List<Sayur> katalog = [];

  // ---------------------------------------------------------------- getter
  bool get masuk => user != null;
  String get nama => '${user?['nama'] ?? ''}';
  String get namaDepan => nama.split(' ').first;
  String get hp => '${user?['hp'] ?? ''}';
  String get alamat => '${user?['alamat'] ?? ''}';

  int get jumlahKeranjang => keranjang.fold(0, (a, b) => a + b.qty);
  int get subtotal => keranjang.fold(0, (a, b) => a + b.subtotal);
  int get diskonVoucher {
    if (!voucherDiklaim || !pakaiVoucher || subtotal < 20000) return 0;
    final d = (subtotal * 0.10).round();
    return d > 10000 ? 10000 : d;
  }

  int ongkirUntuk(bool diantar) =>
      !diantar || subtotal == 0 || subtotal >= minGratisOngkir ? 0 : tarifOngkir;

  int get belumDibaca => notif.where((n) => !n.dibaca).length;

  List<Pesanan> get pesananLunas =>
      pesanan.where((p) => p.status == 'dibayar' || p.status == 'selesai').toList();
  int get totalBelanjaBulanIni {
    final now = DateTime.now();
    return pesananLunas
        .where((p) => p.dibuat.month == now.month && p.dibuat.year == now.year)
        .fold(0, (a, b) => a + b.total);
  }

  int get totalHemat => pesananLunas.fold(0, (a, b) => a + b.diskon);
  int get poin => pesananLunas.fold(0, (a, b) => a + b.total) ~/ 100;

  // ---------------------------------------------------------------- init
  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p.getString('akun');
    if (raw != null) {
      _akun = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (_cari(demoHp) == null) {
      _akun.add({
        'nama': 'Zaskia Metta Dwi Saputri',
        'hp': demoHp,
        'alamat': 'Jl. Imam Bonjol No. 207, Semarang Tengah',
        'sandi': demoSandi,
      });
      await _p.setString('akun', jsonEncode(_akun));
    }
    final sesi = _p.getString('sesi');
    if (sesi != null) {
      user = _cari(sesi);
      if (user != null) _muat();
    }
  }

  static String normalHp(String hp) {
    var s = hp.replaceAll(RegExp(r'\D'), '');
    if (s.startsWith('62')) s = '0${s.substring(2)}';
    return s;
  }

  Map<String, dynamic>? _cari(String hp) {
    final n = normalHp(hp);
    for (final a in _akun) {
      if (normalHp('${a['hp']}') == n) return a;
    }
    return null;
  }

  String _k(String nama) => '${nama}_${normalHp(hp)}';

  List<dynamic> _list(String key) {
    final raw = _p.getString(_k(key));
    if (raw == null) return [];
    try {
      return jsonDecode(raw) as List;
    } catch (_) {
      return [];
    }
  }

  void _muat() {
    keranjang = _list('keranjang')
        .map((e) => ItemKeranjang.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    favorit = {};
    for (final e in _list('favorit')) {
      if (e is Map) {
        final s = Sayur.fromJson(Map<String, dynamic>.from(e));
        favorit[s.id] = s;
      }
    }
    pesanan = _list('pesanan')
        .map((e) => Pesanan.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    notif = _list('notif').map((e) => Notif.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    voucherDiklaim = _p.getBool(_k('voucher')) ?? false;

    if (_p.getBool(_k('sambutan')) != true) {
      notif.insertAll(0, [
        Notif(
          judul: 'Voucher $kodeVoucher untukmu',
          isi: 'Diskon 10% (maks Rp10.000). Klaim di banner promo Beranda.',
          tipe: 'promo',
          waktu: DateTime.now(),
        ),
        Notif(
          judul: 'Selamat datang, $namaDepan!',
          isi: 'Sayur segar dari petani lokal siap diantar ke dapurmu.',
          tipe: 'info',
          waktu: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ]);
      _p.setBool(_k('sambutan'), true);
      _simpanNotif();
    }
    _cekKedaluwarsa();
  }

  void _simpanAkun() => _p.setString('akun', jsonEncode(_akun));
  void _simpanKeranjang() =>
      _p.setString(_k('keranjang'), jsonEncode(keranjang.map((e) => e.toJson()).toList()));
  void _simpanFavorit() =>
      _p.setString(_k('favorit'), jsonEncode(favorit.values.map((e) => e.toJson()).toList()));
  void _simpanPesanan() =>
      _p.setString(_k('pesanan'), jsonEncode(pesanan.map((e) => e.toJson()).toList()));
  void _simpanNotif() =>
      _p.setString(_k('notif'), jsonEncode(notif.map((e) => e.toJson()).toList()));

  /// Pesanan yang lewat batas bayar otomatis dibatalkan.
  void _cekKedaluwarsa() {
    var ubah = false;
    for (final p in pesanan) {
      if (p.status == 'menunggu' && DateTime.now().isAfter(p.batasBayar)) {
        p.status = 'batal';
        ubah = true;
      }
    }
    if (ubah) _simpanPesanan();
  }

  void segarkan() {
    _cekKedaluwarsa();
    notifyListeners();
  }

  // ---------------------------------------------------------------- akun
  /// Mengembalikan pesan error, atau null kalau berhasil.
  Future<String?> login(String hp, String sandi) async {
    final a = _cari(hp);
    if (a == null) return 'Nomor HP belum terdaftar. Daftar dulu, ya.';
    if (a['sandi'] != sandi) return 'Kata sandi salah.';
    user = a;
    await _p.setString('sesi', '${a['hp']}');
    _muat();
    notifyListeners();
    return null;
  }

  Future<String?> daftar({required String nama, required String hp, required String sandi}) async {
    if (_cari(hp) != null) return 'Nomor HP ini sudah terdaftar.';
    _akun.add({'nama': nama.trim(), 'hp': normalHp(hp), 'alamat': '', 'sandi': sandi});
    _simpanAkun();
    return login(hp, sandi);
  }

  Future<void> ubahProfil({required String nama, required String hp, required String alamat}) async {
    if (user == null) return;
    user!['nama'] = nama.trim();
    user!['alamat'] = alamat.trim();
    // nomor HP adalah ID akun; disimpan apa adanya tanpa memindah data
    if (normalHp(hp) == normalHp('${user!['hp']}')) user!['hp'] = hp.trim();
    _simpanAkun();
    notifyListeners();
  }

  Future<void> keluar() async {
    await _p.remove('sesi');
    user = null;
    keranjang = [];
    favorit = {};
    pesanan = [];
    notif = [];
    notifyListeners();
  }

  // ---------------------------------------------------------------- keranjang
  void tambahKeranjang(Sayur s, {int ukuran = 1, int qty = 1}) {
    for (final it in keranjang) {
      if (it.sayur.id == s.id && it.ukuran == ukuran) {
        it.qty += qty;
        _simpanKeranjang();
        notifyListeners();
        return;
      }
    }
    keranjang.add(ItemKeranjang(s, ukuran, qty));
    _simpanKeranjang();
    notifyListeners();
  }

  void ubahQty(String kunci, int qty) {
    if (qty <= 0) {
      keranjang.removeWhere((e) => e.kunci == kunci);
    } else {
      for (final it in keranjang) {
        if (it.kunci == kunci) it.qty = qty;
      }
    }
    _simpanKeranjang();
    notifyListeners();
  }

  void klaimVoucher() {
    voucherDiklaim = true;
    pakaiVoucher = true;
    _p.setBool(_k('voucher'), true);
    notifyListeners();
  }

  void setPakaiVoucher(bool v) {
    pakaiVoucher = v;
    notifyListeners();
  }

  // ---------------------------------------------------------------- favorit
  bool isFavorit(int id) => favorit.containsKey(id);

  void toggleFavorit(Sayur s) {
    if (favorit.containsKey(s.id)) {
      favorit.remove(s.id);
    } else {
      favorit[s.id] = s;
    }
    _simpanFavorit();
    notifyListeners();
  }

  // ---------------------------------------------------------------- pesanan
  Pesanan? cariPesanan(String id) {
    for (final p in pesanan) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Membuat pesanan dari isi keranjang lalu mengosongkan keranjang.
  Pesanan buatPesanan({
    required String metode,
    required String alamat,
    required String jadwal,
    required bool diantar,
    required String catatan,
  }) {
    final now = DateTime.now();
    final cod = Metode.cari(metode).grup == 'cod';
    final p = Pesanan(
      id: 'SYR${now.millisecondsSinceEpoch.toString().substring(7)}',
      dibuat: now,
      item: keranjang.map((e) => ItemKeranjang(e.sayur, e.ukuran, e.qty)).toList(),
      ongkir: ongkirUntuk(diantar),
      diskon: diskonVoucher,
      biayaLayanan: biayaLayanan,
      metode: metode,
      alamat: alamat.trim(),
      jadwal: jadwal,
      diantar: diantar,
      catatan: catatan.trim(),
      status: cod ? 'dibayar' : 'menunggu',
      dibayarPada: cod ? now : null,
    );
    pesanan.insert(0, p);
    keranjang = [];
    if (alamat.trim().isNotEmpty && user != null) {
      user!['alamat'] = alamat.trim();
      _simpanAkun();
    }
    notif.insert(
      0,
      cod
          ? Notif(
              judul: 'Pesanan #${p.id} dikemas',
              isi: 'Siapkan uang tunai ${_rp(p.total)} untuk kurir.',
              tipe: 'pesanan',
              waktu: now,
              idPesanan: p.id)
          : Notif(
              judul: 'Menunggu pembayaran',
              isi: 'Bayar ${_rp(p.total)} untuk #${p.id} sebelum ${_jam(p.batasBayar)}.',
              tipe: 'bayar',
              waktu: now,
              idPesanan: p.id),
    );
    _simpanPesanan();
    _simpanKeranjang();
    _simpanNotif();
    notifyListeners();
    return p;
  }

  /// Simulasi pembayaran berhasil (belum memakai payment gateway asli).
  void tandaiLunas(String id) {
    final p = cariPesanan(id);
    if (p == null || p.status != 'menunggu') return;
    p.status = 'dibayar';
    p.dibayarPada = DateTime.now();
    for (final n in notif) {
      if (n.idPesanan == id && n.tipe == 'bayar') n.dibaca = true;
    }
    notif.insert(
        0,
        Notif(
            judul: 'Pembayaran #$id berhasil',
            isi: 'Sayurmu sedang dikemas. Jadwal: ${p.jadwal}.',
            tipe: 'pesanan',
            waktu: DateTime.now(),
            idPesanan: id));
    _simpanPesanan();
    _simpanNotif();
    notifyListeners();
  }

  void batalkan(String id) {
    final p = cariPesanan(id);
    if (p == null || p.status != 'menunggu') return;
    p.status = 'batal';
    // kembalikan barang ke keranjang supaya bisa bayar ulang
    for (final it in p.item) {
      tambahKeranjang(it.sayur, ukuran: it.ukuran, qty: it.qty);
    }
    _simpanPesanan();
    notifyListeners();
  }

  void konfirmasiDiterima(String id) {
    final p = cariPesanan(id);
    if (p == null) return;
    p.status = 'selesai';
    notif.insert(
        0,
        Notif(
            judul: 'Pesanan #$id selesai',
            isi: 'Terima kasih sudah belanja. Kamu dapat ${p.total ~/ 100} poin.',
            tipe: 'pesanan',
            waktu: DateTime.now(),
            idPesanan: id));
    _simpanPesanan();
    _simpanNotif();
    notifyListeners();
  }

  void pesanLagi(Pesanan p) {
    for (final it in p.item) {
      tambahKeranjang(it.sayur, ukuran: it.ukuran, qty: it.qty);
    }
  }

  // ---------------------------------------------------------------- notifikasi
  void bacaNotif(Notif n) {
    n.dibaca = true;
    _simpanNotif();
    notifyListeners();
  }

  void bacaSemua() {
    for (final n in notif) {
      n.dibaca = true;
    }
    _simpanNotif();
    notifyListeners();
  }

  void hapusNotif(Notif n) {
    notif.remove(n);
    _simpanNotif();
    notifyListeners();
  }

  static String _jam(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

  static String _rp(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      b.write(s[i]);
      final sisa = s.length - i;
      if (sisa > 1 && sisa % 3 == 1) b.write('.');
    }
    return 'Rp$b';
  }
}
