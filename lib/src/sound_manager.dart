/// Provides the [SoundManager] class.
import 'package:dart_synthizer/dart_synthizer.dart';
import 'package:ziggurat/ziggurat.dart';

import 'audio_channel.dart';
import 'buffer_cache.dart';
import 'buffer_store.dart';
import 'error.dart';
import 'extensions.dart';
import 'reverb.dart';

/// The sound manager class.
///
/// Instances of this class handle [SoundEvent] instances via the [handleEvent]
/// method.
///
/// Once you have a [Game] instance, you can hook up an instance to listen for
/// events:
///
/// ```
/// game.sounds.listen(soundManager.handleEvent);
/// ```
class SoundManager {
  /// Create a sound manager.
  SoundManager(this.game, this.context,
      {List<BufferStore>? bufferStores, this.bufferCache})
      : bufferStores = bufferStores ?? <BufferStore>[],
        _reverbs = {},
        _channels = {},
        _sounds = {};

  /// The game to use.
  final Game game;

  /// The synthizer context to use.
  final Context context;

  /// The list of buffer stores to use.
  ///
  /// You can add and remove buffer stores from this list, but if the list is
  /// empty, the [getBuffer] method will always fail.
  final List<BufferStore> bufferStores;

  /// The buffer cache to use.
  ///
  /// If [getBuffer] doesn't find any results in any of [bufferStores], then
  /// this cache will be used, assuming it's not `null`.
  final BufferCache? bufferCache;

  /// The reverbs that have been registered.
  ///
  /// You should get reverbs with the [getReverb] method.
  final Map<int, Reverb> _reverbs;

  /// The audio channels that have been registered.
  ///
  /// You should get channels with the [getChannel] method.
  final Map<int, AudioChannel> _channels;

  /// All the sounds that have been kept alive.
  ///
  /// You should get sounds with the [getSound] method.
  final Map<int, BufferGenerator> _sounds;

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

  /// Get a sound with the given ID.
  ///
  /// If no sound is found with the given [id], [NoSuchSoundError] will be
  /// thrown.
  BufferGenerator getSound(int id) {
    final sound = _sounds[id];
    if (sound == null) {
      throw NoSuchSoundError(id);
    }
    return sound;
  }

  /// Get a buffer from the list of [bufferStores].
  ///
  /// This method iterates over the `bufferStores` list, and returns the first
  /// appropriate buffer.
  ///
  /// If no buffer is found with the given [reference], [NoSuchBufferError] is
  /// thrown.
  Buffer getBuffer(AssetReference reference) {
    for (final bufferStore in bufferStores) {
      try {
        return bufferStore.getBuffer(reference);
      } on NoSuchBufferError {
        continue;
      }
    }
    final cache = bufferCache;
    if (cache != null) {
      return cache.getBuffer(reference);
    }
    throw NoSuchBufferError(reference.name, type: reference.type);
  }

  /// Handle a sound event.
  ///
  /// This method should be used to listen for events from the [Game.sounds]
  /// stream.
  void handleEvent(SoundEvent event) {
    if (event is SoundChannel) {
      final position = event.position;
      final Source source;
      if (position is SoundPosition3d) {
        source = Source3D(context)
          ..position = Double3(position.x, position.y, position.z);
      } else if (position is SoundPositionScalar) {
        source =
            context.createScalarPannedSource(panningScalar: position.scalar);
      } else if (position is SoundPositionAngular) {
        source = context.createAngularPannedSource(
            azimuth: position.azimuth, elevation: position.elevation);
      } else {
        source = DirectSource(context);
      }
      source.gain = event.gain;
      final reverbId = event.reverb;
      final Reverb? reverb;
      if (reverbId != null) {
        reverb = getReverb(reverbId);
        context.ConfigRoute(source, reverb.reverb);
      } else {
        reverb = null;
      }
      _channels[event.id!] = AudioChannel(event.id!, source, reverb);
    } else if (event is SetSoundChannelGain) {
      getChannel(event.id!).source.gain = event.gain;
    } else if (event is SetSoundChannelPosition) {
      final channel = getChannel(event.id!);
      final position = event.position;
      if (position is SoundPosition3d) {
        (channel.source as Source3D).position =
            Double3(position.x, position.y, position.z);
      } else if (position is SoundPositionScalar) {
        (channel.source as ScalarPannedSource).panningScalar = position.scalar;
      } else if (position is SoundPositionAngular) {
        (channel.source as AngularPannedSource)
          ..azimuth = position.azimuth
          ..elevation = position.elevation;
      } else {
        // Nothing to do.
      }
    } else if (event is DestroySoundChannel) {
      final channel = getChannel(event.id!);
      _channels.remove(event.id);
      channel.destroy();
    } else if (event is CreateReverb) {
      final reverb =
          Reverb(event.reverb.name, event.reverb.makeReverb(context));
      _reverbs[event.id!] = reverb;
    } else if (event is DestroyReverb) {
      final reverb = getReverb(event.id!);
      _reverbs.remove(event.id);
      reverb.reverb.destroy();
    } else if (event is PlaySound) {
      final channel = getChannel(event.channel);
      final generator = BufferGenerator(context)
        ..looping = event.looping
        ..gain = event.gain
        ..setBuffer(getBuffer(event.sound));
      if (event.keepAlive) {
        channel.sounds[event.id!] = generator;
        _sounds[event.id!] = generator;
      } else {
        generator.configDeleteBehavior(linger: true);
      }
      channel.source.addGenerator(generator);
    } else if (event is DestroySound) {
      final sound = _sounds.remove(event.id);
      if (sound == null) {
        throw NoSuchSoundError(event.id!);
      }
      for (final channel in _channels.values) {
        channel.sounds.remove(event.id);
      }
      sound.destroy();
    } else if (event is PauseSound) {
      getSound(event.id!).pause();
    } else if (event is UnpauseSound) {
      getSound(event.id!).play();
    } else if (event is SetLoop) {
      getSound(event.id!).looping = event.looping;
    } else if (event is SetSoundGain) {
      getSound(event.id!).gain = event.gain;
    } else if (event is SetSoundPitchBend) {
      getSound(event.id!)..pitchBend = event.pitchBend;
    } else if (event is SoundChannelHighpass) {
      getChannel(event.id!).source.filter = BiquadConfig.designHighpass(
          context.synthizer, event.frequency,
          q: event.q);
    } else if (event is SoundChannelLowpass) {
      getChannel(event.id!).source.filter = BiquadConfig.designLowpass(
          context.synthizer, event.frequency,
          q: event.q);
    } else if (event is SoundChannelBandpass) {
      getChannel(event.id!).source.filter = BiquadConfig.designBandpass(
          context.synthizer, event.frequency, event.bandwidth);
    } else if (event is SoundChannelFilter) {
      getChannel(event.id!).source.filter =
          BiquadConfig.designIdentity(context.synthizer);
    } else if (event is SetSoundChannelReverb) {
      final reverbId = event.reverb;
      final channel = getChannel(event.id!);
      final oldReverb = channel.reverb;
      if (oldReverb != null) {
        context.removeRoute(channel.source, oldReverb.reverb);
      }
      if (reverbId != null) {
        final reverb = getReverb(reverbId);
        context.ConfigRoute(channel.source, reverb.reverb);
      }
    } else if (event is AutomationFade) {
      final sound = getSound(event.id!);
      context.executeAutomation(sound, [
        AutomationAppendPropertyCommand(game.runDurationSeconds + event.preFade,
            Properties.gain, event.startGain),
        AutomationAppendPropertyCommand(
            game.runDurationSeconds + event.fadeLength,
            Properties.gain,
            event.endGain)
      ]).destroy();
    } else if (event is CancelAutomationFade) {
      final sound = getSound(event.id!);
      context.executeAutomation(sound, [
        AutomationClearPropertyCommand(game.runDurationSeconds, Properties.gain)
      ]);
    } else if (event is SetDefaultPannerStrategy) {
      final PannerStrategy strategy;
      switch (event.strategy) {
        case DefaultPannerStrategy.stereo:
          strategy = PannerStrategy.stereo;
          break;
        case DefaultPannerStrategy.hrtf:
          strategy = PannerStrategy.hrtf;
          break;
      }
      context.defaultPannerStrategy = strategy;
    } else if (event is ListenerPositionEvent) {
      context.position = Double3(event.x, event.y, event.z);
    } else if (event is ListenerOrientationEvent) {
      context.orientation =
          Double6(event.x1, event.y1, event.z1, event.x2, event.y2, event.z2);
    } else {
      throw Exception('Cannot handle $event.');
    }
  }
}
