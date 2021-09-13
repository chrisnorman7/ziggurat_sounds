/// Provides the [AudioChannel] class.
import 'package:dart_synthizer/dart_synthizer.dart';

/// A channel to play sounds through.
class AudioChannel {
  /// Create the channel.
  AudioChannel(this.id, this.source) : sounds = {};

  /// The id of this channel.
  final int id;

  /// The audio source to use.
  Source source;

  /// The sounds that are playing through this channel.
  final Map<int, BufferGenerator> sounds;

  /// Destroy this channel.
  void destroy() => source.destroy();
}
