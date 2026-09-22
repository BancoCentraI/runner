import 'package:akillisletme/product/cache/cache_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_cache_model.g.dart';

@JsonSerializable()
final class AppCacheModel with CacheModel, EquatableMixin {
  const AppCacheModel({
    this.isHomeViewGrid = false,
    this.lastSearchItems = const [],
  });

  factory AppCacheModel.fromJson(Map<String, dynamic> json) {
    return _$AppCacheModelFromJson(json);
  }

  static const String appModelId = 'app_model_cache';

  final bool isHomeViewGrid;
  final List<String> lastSearchItems;

  @override
  List<Object> get props => [isHomeViewGrid, lastSearchItems];

  @override
  AppCacheModel fromDynamicJson(dynamic json) {
    if (json is! Map<String, dynamic>) throw Exception('Invalid json type');
    return AppCacheModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson() => _$AppCacheModelToJson(this);

  @override
  String get id => appModelId;
}
