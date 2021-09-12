/// Provides the [SoundManager] class.
import 'package:dart_synthizer/dart_synthizer.dart';
import 'package:ziggurat/ziggurat.dart';

import 'audio_channel.dart';
import 'buffer_store.dart';
import 'error.dart';
import 'extensions.dart';
import 'reverb.dart';

/// The sound manager class.
class SoundManager {
  /// Create a sound manager.
  SoundManager(this.context)
      : bufferStores = <BufferStore>[],
        _reverbs = {},
        _channels = {};

  /// The synthizer context to use.
  final Context context;

  /// The buffer store to use.
  final List<BufferStore> bufferStores;

  /// The reverbs that have been registered.
  final Map<int, Reverb> _reverbs;

  /// The audio channels that have been registered.
  final Map<int, AudioChannel> _channels;

  /// Get a reverb.
  ///
  /// If no such reverb is found, [NoSuchReverbError] will be thrown.
  Reverb getReverb(int id) {
    final reverb = _reverbs[id];
    if (reverb == null) {
      throw NoSuchReverbError(id);
    }
    return reverb;
  }

  /// Get a channel.
  ///
  /// If no such channel is found, [NoSuchChannelError] will be thrown.
  AudioChannel getChannel(int id) {
    final channel = _channels[id];
    if (channel == null) {
      throw NoSuchChannelError(id);
    }
    return channel;
  }

  /// Get a buffer from the list of [bufferStores].
  Buffer getBuffer(SoundReference reference) {
    for (final bufferStore in bufferStores) {
      try {
        return bufferStore.getBuffer(reference);
      } on NoSuchBufferError {
        continue;
      }
    }
    throw NoSuchBufferError(reference.name, type: reference.type);
  }

  /// Handle a sound event.
  void handleEvent(SoundEvent event) {
    if (event is SoundChannel) {
      final position = event.position;
      final Source source;
      if (position is SoundPosition3d) {
        source = Source3D(context)
          ..position = Double3(position.x, position.y, position.z);
      } else if (position is SoundPositionPanned) {
        source = PannedSource(context)
          ..elevation = position.elevation
          ..panningScalar = position.scalar;
      } else {
        source = DirectSource(context);
      }
      source.gain = event.gain;
      final reverbId = event.reverb;
      if (reverbId != null) {
        final reverb = getReverb(reverbId);
        context.ConfigRoute(source, reverb.reverb);
      }
      _channels[event.id] = AudioChannel(event.id, source);
    } else if (event is DestroySoundChannel) {
      final channel = getChannel(event.id);
      _channels.remove(event.id);
      channel.destroy();
    } else if (event is CreateReverb) {
      final reverb =
          Reverb(event.reverb.name, event.reverb.makeReverb(context));
      _reverbs[event.id] = reverb;
    } else if (event is DestroyReverb) {
      final reverb = getReverb(event.id);
      _reverbs.remove(event.id);
      reverb.reverb.destroy();
    } else if (event is PlaySound) {
      final channel = getChannel(event.channel);
      final generator = BufferGenerator(context)
        ..looping = event.looping
        ..gain = event.gain
        ..setBuffer(getBuffer(event.sound));
      if (event.keepAlive == false) {
        generator.configDeleteBehavior(linger: true);
      } else {
        channel.sounds[event.id] = generator;
      }
      channel.source.addGenerator(generator);
    } else if (event is DestroySound) {
      final channel = getChannel(event.channel);
      final sound = channel.sounds.remove(event.id);
      if (sound == null) {
        throw NoSuchSoundError(event.id, channel);
      }
      sound.destroy();
    } else {
      throw Exception('Cannot handle $event.');
    }
  }
}
