import 'package:flutter_test/flutter_test.dart';
import 'package:vegetable_app/models/models.dart';
import 'package:vegetable_app/theme.dart';

void main() {
  test('format rupiah', () {
    expect(rupiah(3500), 'Rp3.500');
    expect(rupiah(125000), 'Rp125.000');
    expect(rupiah(0), 'Rp0');
  });

  test('parsing data sayur dari API', () {
    final s = Sayur.fromJson({
      'id': 1,
      'nama': 'Bayam Hijau',
      'kategori': 'Sayuran Daun',
      'harga': 3500,
      'gambar': 'https://example.com/bayam.jpg',
      'deskripsi': 'Bayam segar',
    });
    expect(s.nama, 'Bayam Hijau');
    expect(s.harga, 3500);
  });

  test('harga per ukuran', () {
    expect(Ukuran.semua[1].harga(10000), 10000);
    expect(Ukuran.semua[0].harga(10000), 5500);
    expect(Ukuran.semua[2].harga(10000), 18500);
  });
}
