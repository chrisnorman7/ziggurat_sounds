/// Provides classes relating to assets.
import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:ziggurat/ziggurat.dart';

import 'common.dart';

part 'asset_store.g.dart';

/// A class to hold an [AssetReference], as well as other meta data required to
/// generate Dart code.
@JsonSerializable()
class AssetReferenceReference {
  /// Create an instance.
  AssetReferenceReference(
      {required this.variableName, required this.reference, this.comment});

  /// Create an instance from a JSON object.
  factory AssetReferenceReference.fromJson(Map<String, dynamic> json) =>
      _$AssetReferenceReferenceFromJson(json);

  /// The name of the resulting variable.
  final String variableName;

  /// The comment to write above the variable declaration.
  final String? comment;

  /// The asset reference to use.
  final AssetReference reference;

  /// Convert an instance to JSON.
  ///
  /// /// resulting
  Map<String, dynamic> toJson() => _$AssetReferenceReferenceToJson(this);
}

/// A class for storing references to encrypted assets.
@JsonSerializable()
class AssetStore with DumpLoadMixin {
  /// Create an instance.
  AssetStore(this.filename,
      {this.comment, List<AssetReferenceReference>? assets})
      : assets = assets ?? [];

  /// Create an instance from a JSON object.
  factory AssetStore.fromJson(Map<String, dynamic> json) =>
      _$AssetStoreFromJson(json);

  /// Create an instance from [file].
  factory AssetStore.fromFile(File file) {
    final dynamic json = jsonDecode(file.readAsStringSync());
    return AssetStore.fromJson(json as Map<String, dynamic>);
  }

  /// The dart filename for this store.
  final String filename;

  /// The comment at the top of the resulting dart file.
  final String? comment;

  /// All the assets in this store.
  final List<AssetReferenceReference> assets;

  /// Convert an instance to JSON.
  @override
  Map<String, dynamic> toJson() => _$AssetStoreToJson(this);

  /// Import a single file.
  ///
  /// This method will encrypt [file], and place it in [directory].
  AssetReferenceReference importFile(
      {required File file,
      required Directory directory,
      required String variableName,
      String? comment}) {
    final filename = path.basename(file.path) + '.encrypted';
    final encryptionKey = SecureRandom(32).base64;
    final key = Key.fromBase64(encryptionKey);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final data = encrypter.encryptBytes(file.readAsBytesSync(), iv: iv).bytes;
    final destination = File(path.join(directory.path, filename))
      ..writeAsBytesSync(data);
    final reference =
        AssetReference.file(destination.path, encryptionKey: encryptionKey);
    final assetReferenceReference = AssetReferenceReference(
        variableName: variableName, reference: reference, comment: comment);
    assets.add(assetReferenceReference);
    return assetReferenceReference;
  }

  /// Import a directory.
  ///
  /// This method will copy an encrypted version of every file from [directory]
  /// to [destination].
  AssetReferenceReference importDirectory(
      {required Directory directory,
      required Directory destination,
      required String variableName,
      String? comment}) {
    final encryptionKey = SecureRandom(32).base64;
    final key = Key.fromBase64(encryptionKey);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    for (final entity in directory.listSync()) {
      if (entity is File) {
        final filename = path.basename(entity.path) + '.encrypted';
        final data =
            encrypter.encryptBytes(entity.readAsBytesSync(), iv: iv).bytes;
        File(path.join(destination.path, filename)).writeAsBytesSync(data);
      }
    }
    final reference = AssetReference.collection(destination.path,
        encryptionKey: encryptionKey);
    final assetReferenceReference = AssetReferenceReference(
        variableName: variableName, reference: reference, comment: comment);
    assets.add(assetReferenceReference);
    return assetReferenceReference;
  }
}
