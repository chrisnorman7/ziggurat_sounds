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
  AssetStore(
      {required this.filename,
      required this.destination,
      this.comment,
      List<AssetReferenceReference>? assets})
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

  /// The directory where all files will end up.
  final String destination;

  /// The directory where assets will reside.
  Directory get directory => Directory(destination);

  /// The comment at the top of the resulting dart file.
  final String? comment;

  /// All the assets in this store.
  final List<AssetReferenceReference> assets;

  /// Convert an instance to JSON.
  @override
  Map<String, dynamic> toJson() => _$AssetStoreToJson(this);

  /// Get an unused filename.
  String getNextFilename({String suffix = ''}) {
    var i = 0;
    while (true) {
      final fname = '${destination}/$i$suffix';
      if (File(fname).existsSync() == false &&
          Directory(fname).existsSync() == false) {
        return fname;
      }
      i++;
    }
  }

  /// Import a single file.
  ///
  /// This method will encrypt [source], and place it in [destination].
  AssetReferenceReference importFile(
      {required File source, required String variableName, String? comment}) {
    if (directory.existsSync() == false) {
      directory.createSync();
    }
    final fname = getNextFilename(suffix: '.encrypted');
    final encryptionKey = SecureRandom(32).base64;
    final key = Key.fromBase64(encryptionKey);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final data = encrypter.encryptBytes(source.readAsBytesSync(), iv: iv).bytes;
    File(fname).writeAsBytesSync(data);
    final reference = AssetReference.file(fname, encryptionKey: encryptionKey);
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
      {required Directory source,
      required String variableName,
      String? comment}) {
    if (directory.existsSync() == false) {
      directory.createSync();
    }
    final directoryName = getNextFilename();
    Directory(directoryName).createSync();
    final encryptionKey = SecureRandom(32).base64;
    final key = Key.fromBase64(encryptionKey);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    for (final entity in source.listSync()) {
      if (entity is File) {
        final filename = path.basename(entity.path) + '.encrypted';
        final data =
            encrypter.encryptBytes(entity.readAsBytesSync(), iv: iv).bytes;
        File(path.join(directoryName, filename)).writeAsBytesSync(data);
      }
    }
    final reference =
        AssetReference.collection(directoryName, encryptionKey: encryptionKey);
    final assetReferenceReference = AssetReferenceReference(
        variableName: variableName, reference: reference, comment: comment);
    assets.add(assetReferenceReference);
    return assetReferenceReference;
  }
}
