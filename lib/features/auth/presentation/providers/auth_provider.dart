import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.message,
  });

  final AuthStatus status;
  final AuthSession? session;
  final String? message;

  factory AuthState.initial() => const AuthState();

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated(AuthSession session) => AuthState(
        status: AuthStatus.authenticated,
        session: session,
      );

  factory AuthState.unauthenticated() => const AuthState(
        status: AuthStatus.unauthenticated,
      );

  factory AuthState.error(String message) => AuthState(
        status: AuthStatus.error,
        message: message,
      );
}

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(
    apiClient: ref.read(apiClientProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  final remoteDataSource = ref.read(authRemoteDataSourceProvider);
  final apiClient = ref.read(apiClientProvider);

  return AuthRepositoryImpl(
    tokenStorage: tokenStorage,
    remoteDataSource: remoteDataSource,
    apiClient: apiClient,
  );
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(AuthState.initial());

  final AuthRepository _repository;

  Future<void> initializeSession() async {
    final token = await _repository.readToken();
    if (token == null || token.isEmpty) {
      state = AuthState.unauthenticated();
      return;
    }

    state = AuthState.authenticated(
      AuthSession(
        user: const AuthUser(email: ''),
        token: token,
      ),
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();

    try {
      final session = await _repository.signIn(
        SignInRequest(
          email: email,
          password: password,
        ),
      );

      state = AuthState.authenticated(session);
    } on ApiException catch (error) {
      state = AuthState.error(error.message);
    } catch (_) {
      state = AuthState.error(
        'Prihlásenie sa nepodarilo. Skontrolujte pripojenie a skúste to znova.',
      );
    }
  }

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    state = AuthState.loading();

    try {
      await _repository.signUp(
        SignUpRequest(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          inviteCode: inviteCode,
        ),
      );

      state = AuthState.unauthenticated();
    } on ApiException catch (error) {
      state = AuthState.error(error.message);
    } catch (_) {
      state = AuthState.error(
        'Registráciu sa nepodarilo odoslať. Skúste to znova.',
      );
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = AuthState.unauthenticated();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.read(authRepositoryProvider)),
);
