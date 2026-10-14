import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);

    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) {
        context.go('/sign-in');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Odhlásenie sa nepodarilo: $error'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prehľad domu'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(dashboardProvider),
            tooltip: 'Obnoviť prehľad',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _isSigningOut ? null : _signOut,
            tooltip: 'Odhlásiť sa',
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: dashboardState.when(
        data: (dashboard) {
          final announcements = dashboard.announcements;
          final waste = dashboard.nextWasteCollection;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(dashboardProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.delete_outline, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Najbližší odvoz smetí',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                waste == null
                                    ? 'Momentálne nie je naplánovaný žiadny odvoz.'
                                    : (waste['typ_odpadu'] ?? 'Odvoz odpadu').toString(),
                              ),
                              if (waste != null && waste['datum_vyvozu'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    waste['datum_vyvozu'].toString(),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Dôležité oznamy',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (announcements.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Zatiaľ nie sú zverejnené žiadne oznamy.'),
                    ),
                  )
                else
                  ...announcements.map((announcement) {
                    final title = announcement['nadpis']?.toString() ?? 'Oznam';
                    final description = announcement['obsah']?.toString() ?? '';
                    final timestamp = announcement['datum_vytvorenia']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (timestamp.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                timestamp,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(description),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42),
                const SizedBox(height: 16),
                Text(error.toString()),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.refresh(dashboardProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Skúsiť znova'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
