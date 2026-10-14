import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.token,
  });

  final AuthUser user;
  final String token;
}
