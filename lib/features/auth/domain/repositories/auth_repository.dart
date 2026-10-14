import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

class SignInRequest {
  const SignInRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'heslo': password,
      };
}

class SignUpRequest {
  const SignUpRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.inviteCode,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String inviteCode;

  Map<String, dynamic> toJson() => {
        'meno': firstName.trim(),
        'priezvisko': lastName.trim(),
        'email': email.trim(),
        'heslo': password,
        'registracny_kod': inviteCode.trim(),
      };
}

abstract class AuthRepository {
  Future<AuthSession> signIn(SignInRequest request);
  Future<String> signUp(SignUpRequest request);
  Future<String?> readToken();
  Future<void> signOut();
}
