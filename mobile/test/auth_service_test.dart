import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/data/auth_service.dart';

void main() {
  test('FakeAuthService signUp dan signIn berhasil', () async {
    final auth = FakeAuthService();
    await auth.signUp(
        name: 'Alea',
        email: 'alea.baru@skinsight.id',
        password: 'skinsight123');
    await auth.signIn(
        email: 'alea.baru@skinsight.id', password: 'skinsight123');
    await auth.signIn(email: 'alea@skinsight.id', password: 'skinsight123');
  });

  test('validateRegister menolak nama kosong dan password pendek', () {
    expect(
        () => validateRegister(name: '', email: 'a@b.id', password: '123456'),
        throwsArgumentError);
    expect(
        () => validateRegister(
            name: 'Alea', email: 'tidak-valid', password: '123456'),
        throwsArgumentError);
    expect(
        () => validateRegister(name: 'Alea', email: 'a@b.id', password: '123'),
        throwsArgumentError);
  });

  test('FakeAuthService signOut berhasil tanpa sesi', () async {
    final auth = FakeAuthService();
    await auth.signOut();
  });

  test('FakeAuthService menolak password salah', () async {
    final auth = FakeAuthService();
    expect(
      () => auth.signIn(email: 'alea@skinsight.id', password: 'salah-password'),
      throwsException,
    );
  });

  test('FakeAuthService menolak email tak terdaftar', () async {
    final auth = FakeAuthService();
    expect(
      () => auth.signIn(email: 'asing@skinsight.id', password: 'skinsight123'),
      throwsException,
    );
  });

  test('FakeAuthService menerima akun hasil signUp', () async {
    final auth = FakeAuthService();
    await auth.signUp(
        name: 'Baru', email: 'baru@skinsight.id', password: 'rahasia123');
    await auth.signIn(email: 'baru@skinsight.id', password: 'rahasia123');
  });
}
