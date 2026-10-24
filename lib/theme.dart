import 'package:flutter/material.dart';

/// Palet "segar": hijau daun + kuning lime.
class C {
  static const daun = Color(0xFF2E5E2A); // warna utama
  static const daunMuda = Color(0xFF5C8A3A);
  static const tinta = Color(0xFF1F3A1C); // teks utama
  static const abu = Color(0xFF5E6B55); // teks sekunder
  static const abuMuda = Color(0xFF8A9680);
  static const lime = Color(0xFFC8E66A);
  static const limeTerang = Color(0xFFDDF07A);
  static const kuning = Color(0xFFF6DE5B);
  static const kuningPucat = Color(0xFFFCF3C4);
  static const hijauPucat = Color(0xFFEAF4D3);
  static const latar = Color(0xFFF4F9E8);
  static const garis = Color(0xFFE3EDCF);
  static const tautan = Color(0xFF4F7A1F);
  static const coklatKuning = Color(0xFF6B5A00);
  static const merah = Color(0xFFB42318);
}

/// Gradasi header lime → kuning.
const gradasiHeader = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFE6F5A3), C.latar],
);

const gradasiSegar = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [C.limeTerang, Color(0xFFF7EDA4)],
);

/// Sudut "daun": dua sudut bulat besar, dua sudut kecil.
BorderRadius daun([double besar = 28, double kecil = 8, bool balik = false]) => balik
    ? BorderRadius.only(
        topLeft: Radius.circular(kecil),
        topRight: Radius.circular(besar),
        bottomLeft: Radius.circular(besar),
        bottomRight: Radius.circular(kecil),
      )
    : BorderRadius.only(
        topLeft: Radius.circular(besar),
        topRight: Radius.circular(kecil),
        bottomLeft: Radius.circular(kecil),
        bottomRight: Radius.circular(besar),
      );

List<BoxShadow> bayangan([double a = 0.08]) => [
      BoxShadow(
        color: C.daun.withValues(alpha: a),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.daun,
      primary: C.daun,
      secondary: C.kuning,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: C.latar,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.tinta, displayColor: C.tinta),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: C.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF9CC45A), width: 1.6)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: C.merah)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: C.merah, width: 1.6)),
      prefixIconColor: C.daunMuda,
      hintStyle: const TextStyle(color: C.abuMuda, fontSize: 13),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.daun,
    ),
  );
}

// ---------------------------------------------------------------- format

/// 3500 -> "Rp3.500"
String rupiah(num n) {
  final neg = n < 0;
  final s = n.abs().round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final sisa = s.length - i;
    buf.write(s[i]);
    if (sisa > 1 && sisa % 3 == 1) buf.write('.');
  }
  return '${neg ? '−' : ''}Rp$buf';
}

const bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];
const hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String dua(int x) => x.toString().padLeft(2, '0');
String jam(DateTime d) => '${dua(d.hour)}.${dua(d.minute)}';
String tanggalPendek(DateTime d) => '${d.day} ${bulanPendek[d.month - 1]}';
String tanggalIndo(DateTime d) => '${d.day} ${bulanPendek[d.month - 1]} ${d.year}, ${jam(d)}';

String waktuLalu(DateTime d) {
  final s = DateTime.now().difference(d);
  if (s.inMinutes < 1) return 'Baru saja';
  if (s.inMinutes < 60) return '${s.inMinutes} menit lalu';
  if (s.inHours < 24) return '${s.inHours} jam lalu';
  if (s.inDays == 1) return 'Kemarin, ${jam(d)}';
  return tanggalIndo(d);
}

String sapaan() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat pagi,';
  if (h < 15) return 'Selamat siang,';
  if (h < 18) return 'Selamat sore,';
  return 'Selamat malam,';
}
