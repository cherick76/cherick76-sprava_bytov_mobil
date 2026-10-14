import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthSession> signIn(SignInRequest request) async {
    final payload = await _apiClient.postJson(
      '/api/prihlasenie.php',
      request.toJson(),
    );

    final token = payload['token'];
    if (token is! String || token.isEmpty) {
      throw ApiException(
        payload['chyba']?.toString() ??
            payload['sprava']?.toString() ??
            'Prihlásenie sa nepodarilo.',
      );
    }

    final userJson = payload['user'];
    final user = userJson is Map<String, dynamic>
        ? AuthUser.fromJson(userJson)
        : AuthUser(email: request.email.trim());

    return AuthSession(
      user: user,
      token: token,
    );
  }

  Future<String> signUp(SignUpRequest request) async {
    final payload = await _apiClient.postJson(
      '/api/registracia.php',
      request.toJson(),
    );

    return payload['sprava']?.toString() ??
        'Registrácia bola úspešne dokončená.';
  }
}
