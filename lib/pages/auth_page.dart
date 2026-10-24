import 'package:flutter/material.dart';

import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_nav.dart';

/// Halaman Masuk & Daftar dalam satu layar (toggle pil di header).
class AuthPage extends StatefulWidget {
  final bool daftar;
  const AuthPage({super.key, this.daftar = false});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late bool _daftar = widget.daftar;
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _hp = TextEditingController(text: AppStore.demoHp);
  final _sandi = TextEditingController(text: AppStore.demoSandi);
  bool _sembunyi = true;
  bool _ingat = true;
  bool _loading = false;

  @override
  void dispose() {
    _nama.dispose();
    _hp.dispose();
    _sandi.dispose();
    super.dispose();
  }

  void _ganti(bool daftar) {
    setState(() {
      _daftar = daftar;
      _form.currentState?.reset();
      if (daftar) {
        _hp.clear();
        _sandi.clear();
      } else {
        _hp.text = AppStore.demoHp;
        _sandi.text = AppStore.demoSandi;
      }
    });
  }

  Future<void> _kirim() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final s = AppStore.i;
    final err = _daftar
        ? await s.daftar(nama: _nama.text, hp: _hp.text, sandi: _sandi.text)
        : await s.login(_hp.text, _sandi.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      kabari(context, err);
      return;
    }
    _masukBeranda();
  }

  /// Login Google versi demo: tanpa konfigurasi Firebase/Google Cloud,
  /// tombol ini masuk ke akun demo supaya alur aplikasi tetap bisa dicoba.
  Future<void> _google() async {
    setState(() => _loading = true);
    await AppStore.i.login(AppStore.demoHp, AppStore.demoSandi);
    if (!mounted) return;
    setState(() => _loading = false);
    kabari(context, 'Masuk dengan akun Google (mode demo)');
    _masukBeranda();
  }

  void _masukBeranda() => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNav()),
        (_) => false,
      );

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------------------------------------------- header
            Container(
              height: (_daftar ? 280 : 320) + atas,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [C.limeTerang, Color(0xFFEEF4A6), Color(0xFFF7EDA4)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(44)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    right: -60,
                    top: -10,
                    bottom: 0,
                    width: 300,
                    child: Pudar(
                      gradient: const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [Colors.black, Colors.black, Colors.transparent],
                        stops: [0, 0.45, 0.95],
                      ),
                      child: Image.asset(
                        'assets/images/bg_photo.jpg',
                        fit: BoxFit.cover,
                        color: const Color(0xFFEFF4A8),
                        colorBlendMode: BlendMode.multiply,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, atas + 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Logo(size: 40),
                        const Spacer(),
                        Text(_daftar ? 'Gabung bareng kami' : 'Selamat datang di Vegetable App',
                            style: const TextStyle(
                                color: C.tautan, fontSize: 13, fontWeight: FontWeight.w500)),
                        SizedBox(
                          width: 220,
                          child: Text(_daftar ? 'Buat akun baru' : 'Masuk ke akunmu',
                              style: const TextStyle(
                                  fontSize: 28, height: 1.2, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _pil('Masuk', !_daftar, () => _ganti(false)),
                              _pil('Daftar', _daftar, () => _ganti(true)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------------------------------------------------- form
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_daftar) ...[
                      _label('Nama lengkap'),
                      _kotak(TextFormField(
                        controller: _nama,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Zaskia Metta',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? 'Nama minimal 3 huruf' : null,
                      )),
                    ],
                    _label('Nomor HP'),
                    _kotak(TextFormField(
                      controller: _hp,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '08xxxxxxxxxx',
                        prefixIcon: Icon(Icons.phone_iphone_rounded),
                      ),
                      validator: (v) {
                        final s = AppStore.normalHp(v ?? '');
                        if (!s.startsWith('08') || s.length < 10 || s.length > 14) {
                          return 'Nomor HP diawali 08, 10–14 digit';
                        }
                        return null;
                      },
                    )),
                    _label(_daftar ? 'Buat kata sandi' : 'Kata sandi'),
                    _kotak(TextFormField(
                      controller: _sandi,
                      obscureText: _sembunyi,
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) => _kirim(),
                      decoration: InputDecoration(
                        hintText: 'Minimal 6 karakter',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _sembunyi ? 'Tampilkan sandi' : 'Sembunyikan sandi',
                          onPressed: () => setState(() => _sembunyi = !_sembunyi),
                          icon: Icon(_sembunyi
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          color: C.abuMuda,
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                    )),
                    const SizedBox(height: 10),
                    if (_daftar)
                      _kekuatanSandi()
                    else
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _ingat,
                              activeColor: C.daun,
                              onChanged: (v) => setState(() => _ingat = v ?? true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Ingat saya', style: TextStyle(fontSize: 12, color: C.abu)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => kabari(context,
                                'Untuk akun demo, sandinya ${AppStore.demoSandi}'),
                            child: const Text('Lupa sandi?',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: C.tautan)),
                          ),
                        ],
                      ),
                    const SizedBox(height: 18),
                    TombolUtama(_daftar ? 'Daftar Sekarang' : 'Masuk',
                        ikon: Icons.arrow_forward_rounded, loading: _loading, onTap: _kirim),
                    const SizedBox(height: 16),
                    const Row(children: [
                      Expanded(child: Divider(color: C.garis)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('atau', style: TextStyle(fontSize: 12, color: C.abu)),
                      ),
                      Expanded(child: Divider(color: C.garis)),
                    ]),
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _loading ? null : _google,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18), boxShadow: bayangan(0.10)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LogoGoogle(),
                              SizedBox(width: 10),
                              Text('Lanjut dengan Google',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _daftar
                          ? 'Dengan mendaftar, kamu setuju dengan Syarat Layanan dan Kebijakan Privasi'
                          : 'Dengan masuk, kamu setuju dengan Syarat Layanan dan Kebijakan Privasi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: C.abu, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pil(String t, bool aktif, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          decoration: BoxDecoration(
            color: aktif ? C.daun : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(t,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: aktif ? FontWeight.w600 : FontWeight.w500,
                  color: aktif ? Colors.white : C.tinta)),
        ),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6, left: 2),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _kotak(Widget field) => DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: bayangan(0.07)),
        child: field,
      );

  Widget _kekuatanSandi() {
    final p = _sandi.text;
    var skor = 0;
    if (p.length >= 6) skor++;
    if (p.length >= 8 && RegExp(r'\d').hasMatch(p)) skor++;
    if (RegExp(r'[A-Z]').hasMatch(p) || RegExp(r'[^A-Za-z0-9]').hasMatch(p)) skor++;
    const label = ['Belum cukup', 'Sandi lemah', 'Sandi cukup kuat', 'Sandi kuat'];
    return Row(
      children: [
        for (int i = 0; i < 3; i++)
          Expanded(
            child: Container(
              height: 5,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: i < skor ? C.kuning : C.garis,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        const SizedBox(width: 4),
        Text(label[skor], style: const TextStyle(fontSize: 11, color: C.abu)),
      ],
    );
  }
}

/// Logo "G" Google sederhana.
class _LogoGoogle extends StatelessWidget {
  const _LogoGoogle();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 22,
        height: 22,
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
          ]),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2),
        ),
      );
}
