// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VaultFile _$VaultFileFromJson(Map<String, dynamic> json) => VaultFile(
      files: (json['files'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      folders: (json['folders'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$VaultFileToJson(VaultFile instance) => <String, dynamic>{
      'files': instance.files,
      'folders': instance.folders,
    };

VaultFileStub _$VaultFileStubFromJson(Map<String, dynamic> json) =>
    VaultFileStub(
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => DataFileEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      folders: (json['folders'] as List<dynamic>?)
          ?.map((e) => DataFileEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$VaultFileStubToJson(VaultFileStub instance) =>
    <String, dynamic>{
      'comment': instance.comment,
      'files': instance.files,
      'folders': instance.folders,
    };
