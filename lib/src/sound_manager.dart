/// Provides the [SoundManager] class.
import 'package:dart_synthizer/dart_synthizer.dart';
import 'package:ziggurat/sound.dart';
import 'package:ziggurat/wave_types.dart';
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
  SoundManager({
    required this.game,
    required this.context,
    List<BufferStore>? bufferStores,
    this.bufferCache,
  })  : bufferStores = bufferStores ?? [],
        _reverbs = {},
        _channels = {},
        _sounds = {},
        _waves = {};

  /// The game to use.
  final Game game;

  /// The synthizer context to use.
  final Context context;

  /// The list of buffer stores to use.
  ///
  /// You can add and remove buffer stores from this list, but if the list is
  /// empty, and [bufferCache] is `null`, the [getBuffer] method will always
  /// fail.
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

  /// All the waves that have been created.
  ///
  /// You should get waves with the [getWave] method.
  final Map<int, FastSineBankGenerator> _waves;

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

  /// Get a sound with the given [id].
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

  /// Get a wave with the given [id].
  ///
  /// If no wave is found then [NoSuchWaveError] will be thrown.
  FastSineBankGenerator getWave(int id) {
    final wave = _waves[id];
    if (wave == null) {
      throw NoSuchWaveError(id);
    }
    return wave;
  }

  /// Get a buffer from the list of [bufferStores].
  ///
  /// This method iterates over the `bufferStores` list, and returns the first
  /// appropriate buffer.
  ///
  /// If no buffer is found with the given [reference], then the [bufferCache]
  /// is consulted. If this comes up empty, then [NoSuchBufferError] is
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
      handleSoundChannel(event);
    } else if (event is SetSoundChannelGain) {
      handleSetSoundChannelGain(event);
    } else if (event is SetSoundChannelPosition) {
      handleSetSoundChannelPosition(event);
    } else if (event is DestroySoundChannel) {
      handleDestroySoundChannel(event);
    } else if (event is CreateReverb) {
      handleCreateReverb(event);
    } else if (event is DestroyReverb) {
      handleDestroyReverb(event);
    } else if (event is PlaySound) {
      handlePlaySound(event);
    } else if (event is DestroySound) {
      handleDestroySound(event);
    } else if (event is PauseWave) {
      handlePauseWave(event);
    } else if (event is UnpauseWave) {
      handleUnpauseWave(event);
    } else if (event is PauseSound) {
      handlePauseSound(event);
    } else if (event is UnpauseSound) {
      handleUnpauseSound(event);
    } else if (event is SetSoundLooping) {
      handleSetSoundLooping(event);
    } else if (event is SetSoundGain) {
      handleSetSoundGain(event);
    } else if (event is SetSoundPitchBend) {
      handleSetSoundPitchBend(event);
    } else if (event is SoundChannelHighpass) {
      handleSoundChannelHighpass(event);
    } else if (event is SoundChannelLowpass) {
      handleSoundChannelLowpass(event);
    } else if (event is SoundChannelBandpass) {
      handleSoundChannelBandpass(event);
    } else if (event is SoundChannelFilter) {
      handleSoundChannelFilter(event);
    } else if (event is SetSoundChannelReverb) {
      handleSetSoundChannelReverb(event);
    } else if (event is AutomationFade) {
      handleAutomationFade(event);
    } else if (event is CancelAutomationFade) {
      handleCancelAutomationFade(event);
    } else if (event is SetDefaultPannerStrategy) {
      handleSetDefaultPannerStrategy(event);
    } else if (event is ListenerPositionEvent) {
      handleListenerPositionEvent(event);
    } else if (event is ListenerOrientationEvent) {
      handleListenerOrientationEvent(event);
    } else if (event is PlayWave) {
      handlePlayWave(event);
    } else if (event is SetWaveGain) {
      handleSetWaveGain(event);
    } else if (event is SetWaveFrequency) {
      handleSetWaveFrequency(event);
    } else if (event is AutomateWaveFrequency) {
      handleAutomateWaveFrequency(event);
    } else if (event is DestroyWave) {
      handleDestroyWave(event);
    } else {
      throw UnimplementedError('Cannot handle $event.');
    }
  }

  /// Set the listener orientation.
  void handleListenerOrientationEvent(ListenerOrientationEvent event) {
    context.orientation.value = Double6(
      event.x1,
      event.y1,
      event.z1,
      event.x2,
      event.y2,
      event.z2,
    );
  }

  /// Set the listener position.
  void handleListenerPositionEvent(ListenerPositionEvent event) {
    context.position.value = Double3(event.x, event.y, event.z);
  }

  /// Set the default panner strategy.
  void handleSetDefaultPannerStrategy(SetDefaultPannerStrategy event) {
    final PannerStrategy strategy;
    switch (event.strategy) {
      case DefaultPannerStrategy.stereo:
        strategy = PannerStrategy.stereo;
        break;
      case DefaultPannerStrategy.hrtf:
        strategy = PannerStrategy.hrtf;
        break;
    }
    context.defaultPannerStrategy.value = strategy;
  }

  /// Cancel a fade.
  void handleCancelAutomationFade(CancelAutomationFade event) {
    final id = event.id!;
    switch (event.fadeType) {
      case FadeType.sound:
        getSound(id).gain.clear(context);
        break;
      case FadeType.wave:
        getWave(id).gain.clear(context);
        break;
    }
  }

  /// Fade something.
  void handleAutomationFade(AutomationFade event) {
    final timebase = context.suggestedAutomationTime.value;
    final id = event.id!;
    final Generator generator;
    switch (event.fadeType) {
      case FadeType.sound:
        generator = getSound(id);
        break;
      case FadeType.wave:
        generator = getWave(id);
        break;
    }
    generator.gain.automate(
      context,
      startTime: timebase + event.preFade,
      startValue: event.startGain,
      endTime: timebase + event.fadeLength,
      endValue: event.endGain,
    );
  }

  /// Set the reverb for a sound channel.
  void handleSetSoundChannelReverb(SetSoundChannelReverb event) {
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
  }

  /// Remove filtering from a sound channel.
  void handleSoundChannelFilter(SoundChannelFilter event) {
    getChannel(event.id!).source.filter.value = BiquadConfig.designIdentity(
      context.synthizer,
    );
  }

  /// Apply a bandpass to a sound channel.
  void handleSoundChannelBandpass(SoundChannelBandpass event) {
    getChannel(event.id!).source.filter.value = BiquadConfig.designBandpass(
      context.synthizer,
      event.frequency,
      event.bandwidth,
    );
  }

  /// Apply a low pass to a sound channel.
  void handleSoundChannelLowpass(SoundChannelLowpass event) {
    getChannel(event.id!).source.filter.value = BiquadConfig.designLowpass(
      context.synthizer,
      event.frequency,
      q: event.q,
    );
  }

  /// Apply a high pass to a sound channel.
  void handleSoundChannelHighpass(SoundChannelHighpass event) {
    getChannel(event.id!).source.filter.value = BiquadConfig.designHighpass(
      context.synthizer,
      event.frequency,
      q: event.q,
    );
  }

  /// Apply pitch bend to a sound.
  void handleSetSoundPitchBend(SetSoundPitchBend event) {
    getSound(event.id!)..pitchBend.value = event.pitchBend;
  }

  /// Set the gain for a sound.
  void handleSetSoundGain(SetSoundGain event) {
    getSound(event.id!).gain.value = event.gain;
  }

  /// Set whether or not a sound should loop.
  void handleSetSoundLooping(SetSoundLooping event) {
    getSound(event.id!).looping.value = event.looping;
  }

  /// Unpause a sound.
  void handleUnpauseSound(UnpauseSound event) {
    getSound(event.id!).play();
  }

  /// Pause a sound.
  void handlePauseSound(PauseSound event) {
    getSound(event.id!).pause();
  }

  /// Destroy a sound.
  void handleDestroySound(DestroySound event) {
    final sound = _sounds.remove(event.id);
    if (sound == null) {
      throw NoSuchSoundError(event.id!);
    }
    for (final channel in _channels.values) {
      channel.sounds.remove(event.id);
    }
    sound.destroy();
  }

  /// Play a sound.
  void handlePlaySound(PlaySound event) {
    final channel = getChannel(event.channel);
    final generator = BufferGenerator(context)
      ..looping.value = event.looping
      ..gain.value = event.gain
      ..buffer.value = getBuffer(event.sound);
    channel.source.addGenerator(generator);
    if (event.keepAlive) {
      channel.sounds[event.id!] = generator;
      _sounds[event.id!] = generator;
    } else {
      generator
        ..configDeleteBehavior(linger: true)
        ..destroy();
    }
  }

  /// Destroy a reverb.
  void handleDestroyReverb(DestroyReverb event) {
    final reverb = getReverb(event.id!);
    _reverbs.remove(event.id);
    reverb.reverb.destroy();
  }

  /// Create a new reverb.
  void handleCreateReverb(CreateReverb event) {
    final reverb = Reverb(
      event.reverb.name,
      event.reverb.makeReverb(context),
    );
    _reverbs[event.id!] = reverb;
  }

  /// Destroy a sound channel.
  void handleDestroySoundChannel(DestroySoundChannel event) {
    final channel = getChannel(event.id!);
    _channels.remove(event.id);
    channel.destroy();
  }

  /// Set the position of a sound channel.
  void handleSetSoundChannelPosition(SetSoundChannelPosition event) {
    final channel = getChannel(event.id!);
    final position = event.position;
    if (position is SoundPosition3d) {
      (channel.source as Source3D).position.value =
          Double3(position.x, position.y, position.z);
    } else if (position is SoundPositionScalar) {
      (channel.source as ScalarPannedSource).panningScalar.value =
          position.scalar;
    } else if (position is SoundPositionAngular) {
      (channel.source as AngularPannedSource)
        ..azimuth.value = position.azimuth
        ..elevation.value = position.elevation;
    } else {
      // Nothing to do.
    }
  }

  /// Handle setting sound channel gain.
  void handleSetSoundChannelGain(SetSoundChannelGain event) {
    getChannel(event.id!).source.gain.value = event.gain;
  }

  /// Handle a sound channel event.
  void handleSoundChannel(SoundChannel event) {
    final position = event.position;
    final Source source;
    if (position is SoundPosition3d) {
      source = Source3D(context)
        ..position.value = Double3(position.x, position.y, position.z);
    } else if (position is SoundPositionScalar) {
      source = context.createScalarPannedSource(panningScalar: position.scalar);
    } else if (position is SoundPositionAngular) {
      source = context.createAngularPannedSource(
          azimuth: position.azimuth, elevation: position.elevation);
    } else {
      source = DirectSource(context);
    }
    source.gain.value = event.gain;
    final reverbId = event.reverb;
    final Reverb? reverb;
    if (reverbId != null) {
      reverb = getReverb(reverbId);
      context.ConfigRoute(source, reverb.reverb);
    } else {
      reverb = null;
    }
    final soundChannelId = event.id!;
    _channels[soundChannelId] = AudioChannel(soundChannelId, source, reverb);
  }

  /// Play a wave.
  void handlePlayWave(PlayWave event) {
    final channel = getChannel(event.channel);
    final FastSineBankGenerator generator;
    switch (event.waveType) {
      case WaveType.sine:
        generator = FastSineBankGenerator.sine(context, event.frequency);
        break;
      case WaveType.triangle:
        generator = FastSineBankGenerator.triangle(
          context,
          event.frequency,
          event.partials,
        );
        break;
      case WaveType.square:
        generator = FastSineBankGenerator.square(
          context,
          event.frequency,
          event.partials,
        );
        break;
      case WaveType.saw:
        generator = FastSineBankGenerator.saw(
          context,
          event.frequency,
          event.partials,
        );
        break;
    }
    generator.gain.value = event.gain;
    final id = event.id!;
    channel
      ..source.addGenerator(generator)
      ..waves[id] = generator;
    _waves[id] = generator;
  }

  /// Set the gain for a wave.
  void handleSetWaveGain(SetWaveGain event) {
    getWave(event.id!).gain.value = event.gain;
  }

  /// Set the frequency of a wave.
  void handleSetWaveFrequency(SetWaveFrequency event) {
    getWave(event.id!).frequency.value = event.frequency;
  }

  /// Automate the frequency of a wave.
  void handleAutomateWaveFrequency(AutomateWaveFrequency event) {
    final timebase = context.suggestedAutomationTime.value;
    getWave(event.id!).frequency.automate(
          context,
          startTime: timebase,
          startValue: event.startFrequency,
          endTime: timebase + event.length,
          endValue: event.endFrequency,
        );
  }

  /// Pause a wave.
  void handlePauseWave(PauseWave event) {
    getWave(event.id!).pause();
  }

  /// Unpause a wave.
  void handleUnpauseWave(UnpauseWave event) {
    getWave(event.id!).play();
  }

  /// Destroy a wave.
  void handleDestroyWave(DestroyWave event) {
    final id = event.id!;
    final generator = _waves.remove(id);
    if (generator == null) {
      throw NoSuchWaveError(id);
    }
    for (final channel in _channels.values) {
      channel.waves.remove(id);
    }
    generator.destroy();
  }
}
