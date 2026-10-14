import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UloziskoTokena {
  UloziskoTokena({FlutterSecureStorage? ulozisko})
      : _ulozisko = ulozisko ?? const FlutterSecureStorage();

  static const String _klucTokena = 'jwt_token';

  final FlutterSecureStorage _ulozisko;

  Future<void> ulozit(String token) {
    return _ulozisko.write(key: _klucTokena, value: token);
  }

  Future<String?> nacitat() {
    return _ulozisko.read(key: _klucTokena);
  }

  Future<void> odstranit() {
    return _ulozisko.delete(key: _klucTokena);
  }
}
