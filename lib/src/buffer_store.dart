/// Provides the [BufferStore] class, and other related machinery.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_synthizer/dart_synthizer.dart';
import 'package:ziggurat/ziggurat.dart';

import 'error.dart';
import 'json/vault_file.dart';
import 'sound_manager.dart';

/// A class for storing [Buffer] instances.
///
/// Instances of this class should be added to the
/// [SoundManager.bufferStores] list.
///
/// If you are using the [ziggurat_utils](https://pub.dev/packages/ziggurat_utils)
/// package, you can use the `vault` script to create subclasses with files
/// ready to go.
class BufferStore {
  /// Create an instance.
  BufferStore(this.random, this.synthizer)
      : _bufferFiles = {},
        _bufferCollections = {},
        _protectedBufferFiles = [],
        _protectedBufferCollections = [];

  /// The random number generator to be used by [getBuffer].
  ///
  /// This value is used when picking a random sound from a buffer collection.
  final Random random;

  /// The synthizer instance to use.
  ///
  ///This value is used to create [Buffer] instances.
  final Synthizer synthizer;

  /// The single buffer entries.
  final Map<String, Buffer> _bufferFiles;

  /// A list of all file entries in this store.
  List<String> get bufferFiles => _bufferFiles.keys.toList();

  /// The buffer collections.
  final Map<String, List<Buffer>> _bufferCollections;

  /// A list of buffer collections in this store.
  List<String> get bufferCollections => _bufferCollections.keys.toList();

  /// A list of buffer files that should be protected from the [clear] method.
  final List<String> _protectedBufferFiles;

  /// A list of collections which should be protected from [clear].
  final List<String> _protectedBufferCollections;

  /// add a buffer from a file.
  Future<AssetReference> addFile(File file,
      {String? name, bool protected = false}) async {
    final buffer = Buffer.fromBytes(synthizer, await file.readAsBytes());
    name ??= file.path;
    _bufferFiles[name] = buffer;
    if (protected) {
      _protectedBufferFiles.add(name);
    }
    return AssetReference.file(name);
  }

  /// Add a directory of files as a collection.
  Future<AssetReference> addDirectory(Directory directory,
      {String? name, bool protected = false}) async {
    final buffers = <Buffer>[];
    for (final file in directory.listSync()) {
      if (file is File) {
        buffers.add(Buffer.fromBytes(synthizer, await file.readAsBytes()));
      }
    }
    name ??= directory.path;
    _bufferCollections[name] = buffers;
    if (protected) {
      _protectedBufferCollections.add(name);
    }
    return AssetReference.collection(name);
  }

  /// Add the contents of a vault file.
  ///
  /// If [protected] is `true`, then each entry will be protected from the
  /// [clear] method.
  void addVaultFile(VaultFile vaultFile, {bool protected = false}) {
    for (final entry in vaultFile.files.entries) {
      final name = entry.key;
      if (_bufferFiles.containsKey(name)) {
        throw DuplicateEntryError(this, name, AssetType.file);
      }
      _bufferFiles[name] =
          Buffer.fromBytes(synthizer, base64Decode(entry.value));
      if (protected) {
        _protectedBufferFiles.add(name);
      }
    }
    for (final entry in vaultFile.folders.entries) {
      final name = entry.key;
      if (_bufferCollections.containsKey(name)) {
        throw DuplicateEntryError(this, name, AssetType.collection);
      }
      final buffers = <Buffer>[];
      for (final data in entry.value) {
        buffers.add(Buffer.fromBytes(synthizer, base64Decode(data)));
      }
      _bufferCollections[name] = buffers;
      if (protected) {
        _protectedBufferCollections.add(name);
      }
    }
  }

  /// Remove a buffer file.
  ///
  /// This method does not care if [name] is protected.
  void removeBufferFile(String name) {
    final buffer = _bufferFiles.remove(name);
    if (buffer != null) {
      buffer.destroy();
    }
    if (_protectedBufferFiles.contains(name)) {
      _protectedBufferFiles.remove(name);
    }
  }

  /// Remove a buffer collection.
  ///
  /// This method does not care if [name] is protected.
  void removeBufferCollection(String name) {
    final buffers = _bufferCollections.remove(name);
    if (buffers != null) {
      for (final buffer in buffers) {
        buffer.destroy();
      }
      if (_protectedBufferCollections.contains(name)) {
        _protectedBufferCollections.remove(name);
      }
    }
  }

  /// Clear buffers from this instance.
  ///
  /// If [includeProtected] is `true`, then all buffers will be cleared.
  ///
  /// Otherwise, those buffers that are protected will be skipped.
  void clear({bool includeProtected = false}) {
    for (final name in _bufferFiles.keys.toList()) {
      if (includeProtected == true ||
          _protectedBufferFiles.contains(name) == false) {
        removeBufferFile(name);
      }
    }
    for (final name in _bufferCollections.keys.toList()) {
      if (includeProtected == true ||
          _protectedBufferCollections.contains(name) == false) {
        removeBufferCollection(name);
      }
    }
  }

  /// Get a buffer.
  ///
  /// If the resulting buffer is a file, then that exact buffer will be
  /// returned. Otherwise, a random buffer from the collection will be
  /// returned.
  ///
  /// If no buffer is found by the given [reference], [NoSuchBufferError] will
  /// be thrown.
  Buffer getBuffer(AssetReference reference) {
    switch (reference.type) {
      case AssetType.file:
        final buffer = _bufferFiles[reference.name];
        if (buffer != null) {
          return buffer;
        }
        break;
      case AssetType.collection:
        final buffers = _bufferCollections[reference.name];
        if (buffers != null) {
          return buffers[random.nextInt(buffers.length)];
        }
        break;
    }
    throw NoSuchBufferError(reference.name, type: reference.type);
  }

  /// Get a sound reference you can use with various objects in the library.
  ///
  /// This method will run through all files and collections to find a
  /// valid reference.
  ///
  /// If nothing is found, [NoSuchBufferError] will be thrown.
  AssetReference getSoundReference(String name) {
    if (_bufferFiles.containsKey(name)) {
      return AssetReference.file(name);
    } else if (_bufferCollections.containsKey(name)) {
      return AssetReference.collection(name);
    } else {
      throw NoSuchBufferError(name);
    }
  }
}
