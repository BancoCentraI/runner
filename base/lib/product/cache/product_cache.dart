import 'package:akillisletme/product/cache/cache_manager.dart';
import 'package:akillisletme/product/cache/hive_v2/hive_operation_manager.dart';
import 'package:akillisletme/product/cache/hive_v2/model/app_cache_model.dart';

final class ProductCache {
  ProductCache({required CacheManager cacheManager})
    : _cacheManager = cacheManager;

  final CacheManager _cacheManager;

  Future<void> init() async {
    await _cacheManager.init([const AppCacheModel()]);
  }

  late final CacheOperation<AppCacheModel> appModelCache =
      HiveOperationManager<AppCacheModel>();
}
