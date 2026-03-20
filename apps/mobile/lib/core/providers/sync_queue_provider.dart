import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/sync_queue.dart';
import 'database_provider.dart';

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final database = ref.watch(databaseProvider);
  return SyncQueueService(database: database);
});
