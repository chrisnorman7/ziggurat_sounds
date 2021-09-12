/// Provides various error types used by this package.
import 'package:ziggurat/ziggurat.dart';

import 'buffer_store.dart';

/// The base class for all errors in this package.
class ZigguratSoundsError extends Error {}

/// No such buffer was found in a [BufferStore] instance.
class NoSuchBufferError extends ZigguratSoundsError {
  /// Create the error.
  NoSuchBufferError(this.name, {this.type});

  /// The name that was used.
  final String name;

  /// The type of the sound.
  final SoundType? type;

  /// Make it a string.
  @override
  String toString() => 'No such buffer "$name" of type $type.';
}

/// A duplicate entry was added to a [BufferStore] instance.
class DuplicateEntryError extends ZigguratSoundsError {
  /// Create an instance.
  DuplicateEntryError(this.bufferStore, this.name, this.type);

  /// The buffer store instance.
  final BufferStore bufferStore;

  /// The name that has been duplicated.
  final String name;

  /// The type of the entry that was supposed to be added.
  final SoundType type;
}

/// No such channel was found.
class NoSuchChannelError extends ZigguratSoundsError {
  /// Create an instance.
  NoSuchChannelError(this.id);

  /// The ID of the channel.
  final int id;

  @override
  String toString() => 'No such channel: $id.';
}

/// No such reverb was found.
class NoSuchReverbError extends ZigguratSoundsError {
  /// Create an instance.
  NoSuchReverbError(this.id);

  /// The ID of the reverb.
  final int id;

  @override
  String toString() => 'No such reverb: $id.';
}

/// No such sound was found.
class NoSuchSoundError extends ZigguratSoundsError {
  /// Create an instance.
  NoSuchSoundError(this.id);

  /// The ID of the sound.
  final int id;

  @override
  String toString() => 'No sound found with ID $id.';
}
