import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardData {
  const DashboardData({
    required this.announcements,
    required this.nextWasteCollection,
  });

  final List<Map<String, dynamic>> announcements;
  final Map<String, dynamic>? nextWasteCollection;
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final tokenStorage = ref.read(tokenStorageProvider);
  final apiClient = ref.read(apiClientProvider);

  final token = await tokenStorage.readToken();
  if (token == null || token.isEmpty) {
    throw ApiException('Používateľ nie je prihlásený.');
  }

  apiClient.setToken(token);

  final announcementsResponse = await apiClient.getJson(
    '/api/oznamy.php',
    requireAuth: true,
  );

  final wasteResponse = await apiClient.getJson(
    '/api/smeti_najblizsie.php',
    requireAuth: true,
  );

  final announcements = (announcementsResponse['data'] is List)
      ? List<Map<String, dynamic>>.from(
          (announcementsResponse['data'] as List).whereType<Map>(),
        )
      : (announcementsResponse is List)
          ? List<Map<String, dynamic>>.from(
              (announcementsResponse as List).whereType<Map>(),
            )
          : <Map<String, dynamic>>[];

  final nextWasteCollection = wasteResponse['data'] is Map
      ? Map<String, dynamic>.from(wasteResponse['data'] as Map)
      : wasteResponse is Map
          ? Map<String, dynamic>.from(wasteResponse as Map)
          : null;

  return DashboardData(
    announcements: announcements,
    nextWasteCollection: nextWasteCollection,
  );
});
