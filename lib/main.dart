import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SamospravaBytovAplikacia()));
}

class SamospravaBytovAplikacia extends ConsumerStatefulWidget {
  const SamospravaBytovAplikacia({super.key});

  @override
  ConsumerState<SamospravaBytovAplikacia> createState() =>
      _SamospravaBytovAplikaciaState();
}

class _SamospravaBytovAplikaciaState
    extends ConsumerState<SamospravaBytovAplikacia> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).initializeSession(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Samospráva bytov',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
