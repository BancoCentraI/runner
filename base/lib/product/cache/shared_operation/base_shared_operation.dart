import 'package:akillisletme/product/cache/shared_operation/shared_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_operation_generic_mixin.dart';

abstract class BaseSharedOperation {
  SharedPreferences get sharedPreferences;
  Future<void> init();
  Future<void> setValue<T>(SharedKeys key, T value);
  Future<bool> setStringList(SharedKeys key, List<String> value);
  List<String>? getStringList(SharedKeys key);
  T? getValue<T>(SharedKeys key);
  Future<void> delete(SharedKeys key);
  Future<void> clear();
}

final class SharedOperation extends BaseSharedOperation
    with SharedOperationGenericMixin {
  @override
  late SharedPreferences sharedPreferences;

  @override
  Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  @override
  Future<void> setValue<T>(SharedKeys key, T value) async {
    await saveWithGeneric<T>(key, value);
  }

  @override
  T? getValue<T>(SharedKeys key) => readWithGeneric<T>(key);

  @override
  Future<void> delete(SharedKeys key) async {
    await sharedPreferences.remove(key.name);
  }

  @override
  Future<void> clear() async {
    await sharedPreferences.clear();
  }

  @override
  Future<bool> setStringList(SharedKeys key, List<String> value) {
    return sharedPreferences.setStringList(key.name, value);
  }

  @override
  List<String>? getStringList(SharedKeys key) {
    return sharedPreferences.getStringList(key.name);
  }
}
