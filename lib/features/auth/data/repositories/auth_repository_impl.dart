import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.tokenStorage,
    required this.remoteDataSource,
    required this.apiClient,
  });

  final TokenStorage tokenStorage;
  final AuthRemoteDataSource remoteDataSource;
  final ApiClient apiClient;

  @override
  Future<AuthSession> signIn(SignInRequest request) async {
    final session = await remoteDataSource.signIn(request);
    await tokenStorage.saveToken(session.token);
    apiClient.setToken(session.token);
    return session;
  }

  @override
  Future<String> signUp(SignUpRequest request) async {
    final message = await remoteDataSource.signUp(request);
    return message;
  }

  @override
  Future<String?> readToken() async {
    final token = await tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      apiClient.setToken(token);
    }
    return token;
  }

  @override
  Future<void> signOut() async {
    apiClient.setToken(null);
    await tokenStorage.clearToken();
  }
}
