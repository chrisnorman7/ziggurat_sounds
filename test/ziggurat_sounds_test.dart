import 'dart:async';
import 'dart:math';

import 'package:dart_synthizer/dart_synthizer.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:ziggurat/ziggurat.dart';
import 'package:ziggurat_sounds/src/sound_manager.dart';
import 'package:ziggurat_sounds/ziggurat_sounds.dart';

import 'custom_buffer_store.dart';

void main() {
  final synthizer = Synthizer()..initialize();
  final context = synthizer.createContext();
  final buffers = CustomBufferStore(Random(), synthizer);
  final game = Game('Sounds');
  final soundManager = SoundManager(context, buffers);
  game.sounds.listen(soundManager.handleEvent);
  group('Initialisation', () {
    test('Ensure initialisation', () async {
      final game = Game('Ensure Initialisation');
      final events = <SoundEvent>[];
      game.sounds.listen(events.add);
      await Future<void>.delayed(Duration.zero);
      expect(events.length, equals(2));
      expect(events.first, isA<SoundChannel>());
      expect(events.last, isA<SoundChannel>());
    });
    test('Game Initialisation', () async {
      expect(game.soundsController.hasListener, isTrue);
      expect(soundManager.getChannel(1), isA<AudioChannel>());
      expect(soundManager.getChannel(2), isA<AudioChannel>());
      expect(
          () => soundManager.getReverb(0), throwsA(isA<NoSuchReverbError>()));
    });
  });
  group('Create and destroy stuff', () {
    test('Reverb', () async {
      final preset = ReverbPreset('Test Reverb');
      final reverb = game.createReverb(preset);
      await Future<void>.delayed(Duration.zero);
      expect(
          soundManager.getReverb(SoundEvent.maxEventId),
          predicate((value) =>
              value is Reverb &&
              value.name == preset.name &&
              value.reverb is GlobalFdnReverb));
      reverb.destroy();
      await Future<void>.delayed(Duration.zero);
      expect(() => soundManager.getReverb(reverb.id),
          throwsA(isA<NoSuchReverbError>()));
    });
    test('Channel', () async {
      final channel = game.createSoundChannel();
      await Future<void>.delayed(Duration.zero);
      expect(
          soundManager.getChannel(channel.id),
          predicate(
              (value) => value is AudioChannel && value.id == channel.id));
      channel.destroy();
      await Future<void>.delayed(Duration.zero);
      expect(() => soundManager.getChannel(channel.id),
          throwsA(isA<NoSuchChannelError>()));
    });
    test('Sound', () async {
      final channel = game.createSoundChannel();
      var sound = channel.playSound(SoundReference.file('test.wav'));
      expect(sound.channel, equals(channel.id));
      expect(sound.looping, isFalse);
      expect(sound.keepAlive, isFalse);
      expect(() => sound.destroy(), throwsA(isA<DeadSound>()));
      await Future<void>.delayed(Duration.zero);
      final channelObject = soundManager.getChannel(channel.id);
      expect(channelObject.sounds[sound.id], isNull);
      sound = channel.playSound(SoundReference.file('another.wav'),
          keepAlive: true);
      expect(sound.keepAlive, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(channelObject.sounds[sound.id], isA<BufferGenerator>());
      sound.destroy();
      await Future<void>.delayed(Duration.zero);
      expect(channelObject.sounds[sound.id], isNull);
    });
  });
}
