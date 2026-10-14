import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
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

  final announcementsPayload = announcementsResponse is Map
      ? announcementsResponse['data'] ?? announcementsResponse['oznamy']
      : announcementsResponse;
  if (announcementsPayload is! List) {
    throw const ApiException('Server vrátil neplatný zoznam oznamov.');
  }
  final announcements = announcementsPayload
      .whereType<Map>()
      .map((announcement) => Map<String, dynamic>.from(
            announcement.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ))
      .toList(growable: false);

  final wastePayload = wasteResponse is Map
      ? wasteResponse['data'] ?? wasteResponse['odvoz'] ?? wasteResponse
      : wasteResponse;
  final nextWasteCollection = wastePayload is Map
      ? Map<String, dynamic>.from(
          wastePayload.map((key, value) => MapEntry(key.toString(), value)),
        )
      : null;

  return DashboardData(
    announcements: announcements,
    nextWasteCollection: nextWasteCollection,
  );
});
