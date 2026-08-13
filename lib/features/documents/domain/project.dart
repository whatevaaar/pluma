import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';

@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    String? description,
    String? color, // hex, e.g. "#5C7AEA"
    required bool isArchived,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Project;

  const Project._();

  String get displayName => name.trim().isEmpty ? 'Sin nombre' : name;
}
