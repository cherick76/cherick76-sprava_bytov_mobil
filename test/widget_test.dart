import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samosprava_bytov/features/auth/domain/entities/auth_session.dart';
import 'package:samosprava_bytov/features/auth/domain/entities/auth_user.dart';
import 'package:samosprava_bytov/features/auth/domain/repositories/auth_repository.dart';
import 'package:samosprava_bytov/features/auth/presentation/providers/auth_provider.dart';
import 'package:samosprava_bytov/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:samosprava_bytov/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:samosprava_bytov/main.dart';

void main() {
  testWidgets('Sign-in screen renders and validates required fields',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(home: SignInScreen()),
      ),
    );

    expect(find.text('Prihlásenie'), findsOneWidget);
    expect(find.text('Prihlásiť sa'), findsOneWidget);

    await tester.tap(find.text('Prihlásiť sa'));
    await tester.pump();

    expect(find.text('Zadajte e-mail.'), findsOneWidget);
    expect(find.text('Zadajte heslo.'), findsOneWidget);
  });

  testWidgets('Session restoration displays splash before sign-in',
      (tester) async {
    final tokenCompleter = Completer<String?>();
    final repository = _FakeAuthRepository(tokenCompleter: tokenCompleter);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: const SamospravaBytovAplikacia(),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Načítavam aplikáciu…'), findsOneWidget);

    tokenCompleter.complete(null);
    await tester.pumpAndSettle();

    expect(find.text('Prihlásenie'), findsOneWidget);
  });

  testWidgets('Signing out clears session and returns to sign-in',
      (tester) async {
    final repository = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          dashboardProvider.overrideWith(
            (ref) async => const DashboardData(
              announcements: [],
              nextWasteCollection: null,
            ),
          ),
        ],
        child: const SamospravaBytovAplikacia(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Prihlásiť sa'));
    await tester.pumpAndSettle();

    expect(find.text('Prehľad domu'), findsOneWidget);

    await tester.tap(find.byTooltip('Odhlásiť sa'));
    await tester.pumpAndSettle();

    expect(repository.signOutCalled, isTrue);
    expect(find.text('Prihlásenie'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.tokenCompleter});

  final Completer<String?>? tokenCompleter;
  bool signOutCalled = false;

  @override
  Future<AuthSession> signIn(SignInRequest request) async => AuthSession(
        user: AuthUser(email: request.email),
        token: 'test-token',
      );

  @override
  Future<String> signUp(SignUpRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<String?> readToken() =>
      tokenCompleter?.future ?? Future<String?>.value();

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}
