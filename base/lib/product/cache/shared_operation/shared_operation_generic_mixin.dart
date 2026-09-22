part of 'base_shared_operation.dart';

mixin SharedOperationGenericMixin on BaseSharedOperation {
  Future<void> saveWithGeneric<T>(SharedKeys key, T value) async {
    if (value is bool) {
      await sharedPreferences.setBool(key.name, value);
      return;
    }
    if (value is int) {
      await sharedPreferences.setInt(key.name, value);
      return;
    }
    if (value is double) {
      await sharedPreferences.setDouble(key.name, value);
      return;
    }
    if (value is String) {
      await sharedPreferences.setString(key.name, value);
      return;
    }
    if (value is List<String>) {
      await sharedPreferences.setStringList(key.name, value);
      return;
    }
    throw Exception('SharedOperation: Type $T is not supported');
  }

  T? readWithGeneric<T>(SharedKeys key) {
    if (T == bool) return sharedPreferences.getBool(key.name) as T?;
    if (T == int) return sharedPreferences.getInt(key.name) as T?;
    if (T == double) return sharedPreferences.getDouble(key.name) as T?;
    if (T == String) return sharedPreferences.getString(key.name) as T?;
    if (T == List<String>) {
      return sharedPreferences.getStringList(key.name) as T?;
    }
    throw Exception('SharedOperation: Type $T is not supported');
  }
}
