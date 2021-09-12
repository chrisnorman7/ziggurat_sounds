/// Provides the [VaultFile] class.
import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:json_annotation/json_annotation.dart';

import 'common.dart';
import 'data_file.dart';

part 'vault_file.g.dart';

/// The type for [VaultFile.files].
typedef FilesType = Map<String, String>;

/// The type for [VaultFile.folders].
typedef FoldersType = Map<String, List<String>>;

/// The type for [VaultFileStub] entries.
typedef VaultFileStubEntriesType = List<DataFileEntry>;

/// A collection of files and folders stored as strings.
@JsonSerializable()
class VaultFile {
  /// Create an instance.
  VaultFile({FilesType? files, FoldersType? folders})
      : files = files ?? {},
        folders = folders ?? {};

  /// Create an instance from a JSON object.
  factory VaultFile.fromJson(Map<String, dynamic> json) =>
      _$VaultFileFromJson(json);

  /// Create an instance from an encrypted string.
  factory VaultFile.fromEncryptedString(
      {required String contents, required String encryptionKey}) {
    final encrypter = Encrypter(AES(Key.fromBase64(encryptionKey)));
    final iv = IV.fromLength(16);
    final encrypted = Encrypted.fromBase64(contents);
    final data = encrypter.decrypt(encrypted, iv: iv);
    final Map<String, dynamic> json = jsonDecode(data) as Map<String, dynamic>;
    return VaultFile.fromJson(json);
  }

  /// Create an instance from a file synchronously.
  factory VaultFile.fromFileSync(File file, String encryptionKey) =>
      VaultFile.fromEncryptedString(
          contents: file.readAsStringSync(), encryptionKey: encryptionKey);

  /// Return an instance loaded from [file].
  static Future<VaultFile> fromFile(File file, String encryptionKey) async {
    final buffer = StringBuffer();
    final reader = file.openRead();
    await for (final chunk in reader) {
      buffer.write(String.fromCharCodes(chunk));
    }
    return VaultFile.fromEncryptedString(
        contents: buffer.toString(), encryptionKey: encryptionKey);
  }

  /// A map of filenames to contents.
  final FilesType files;

  /// A map of folder names to lists of file contents.
  final FoldersType folders;

  /// Convert an instance to JSON.
  Map<String, dynamic> toJson() => _$VaultFileToJson(this);

  /// Convert this instance to an encrypted string.
  String toEncryptedString({required String encryptionKey}) {
    final key = Key.fromBase64(encryptionKey);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final json = jsonEncode(toJson());
    final encrypted = encrypter.encrypt(json, iv: iv);
    return encrypted.base64;
  }

  /// Write an encrypted version of this file to disk.
  void write(File file, String encryptionKey) =>
      file.writeAsStringSync(toEncryptedString(encryptionKey: encryptionKey));
}

/// A class for making [VaultFile] instances, and writing Dart code.
///
/// We use [DataFileEntry] instances because they already provide all the
/// metadata we need.
@JsonSerializable()
class VaultFileStub with DumpLoadMixin {
  /// Create an instance.
  VaultFileStub(
      {VaultFileStubEntriesType? files,
      VaultFileStubEntriesType? folders,
      this.comment})
      : files = files ?? [],
        folders = folders ?? [];

  /// Create an instance from a JSON object.
  factory VaultFileStub.fromJson(Map<String, dynamic> json) =>
      _$VaultFileStubFromJson(json);

  /// Create an instance from a file.
  factory VaultFileStub.fromFile(File file) => VaultFileStub.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);

  /// The comment to place at the top of the resulting Dart file.
  final String? comment;

  /// The files which should be included in the resulting [VaultFile].
  final List<DataFileEntry> files;

  /// The directories (or collections) that will be included in the resulting
  /// [VaultFile] and Dart code.
  final List<DataFileEntry> folders;

  /// Convert an instance to JSON.
  @override
  Map<String, dynamic> toJson() => _$VaultFileStubToJson(this);
}
