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
  tearDownAll(synthizer.shutdown);
  final context = synthizer.createContext();
  final buffers = CustomBufferStore(Random(), synthizer);
  final game = Game('Sounds');
  final soundManager = SoundManager(context)..bufferStores.add(buffers);
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
      var channelEvent = game.createSoundChannel();
      await Future<void>.delayed(Duration(milliseconds: 200));
      var channel = soundManager.getChannel(channelEvent.id);
      expect(channel.id, equals(channelEvent.id));
      expect(channel.sounds, isEmpty);
      var source = channel.source;
      expect(source, isA<DirectSource>());
      expect(source.gain, equals(0.70));
      channelEvent.gain *= 2;
      await Future<void>.delayed(Duration(milliseconds: 200));
      expect(source.gain, equals(1.4));
      channelEvent = game.createSoundChannel(position: SoundPositionPanned());
      await Future<void>.delayed(Duration(milliseconds: 200));
      channel = soundManager.getChannel(channelEvent.id);
      source = channel.source;
      if (source is PannedSource) {
        expect(source.elevation, isZero);
        expect(source.panningScalar, isZero);
        channelEvent.position =
            SoundPositionPanned(elevation: 1.0, scalar: -1.0);
        await Future<void>.delayed(Duration(milliseconds: 200));
        expect(source.panningScalar, equals(-1.0));
        expect(source.elevation, equals(1.0));
        expect(source.gain, equals(channelEvent.gain));
      } else {
        throw Exception('Source is not `PannedSource`.');
      }
      channelEvent = game.createSoundChannel(position: SoundPosition3d());
      await Future<void>.delayed(Duration(milliseconds: 200));
      channel = soundManager.getChannel(channelEvent.id);
      source = channel.source;
      if (source is Source3D) {
        final position = source.position;
        expect(position.x, isZero);
        expect(position.y, isZero);
        expect(position.z, isZero);
        channelEvent.position = SoundPosition3d(x: 1.0, y: 2.0, z: 3.0);
        await Future<void>.delayed(Duration(milliseconds: 200));
        expect(source.position, equals(Double3(1.0, 2.0, 3.0)));
        expect(source.gain, equals(channelEvent.gain));
      } else {
        throw Exception('Source is not of type `Source3D`.');
      }
      channelEvent.destroy();
      await Future<void>.delayed(Duration.zero);
      expect(() => soundManager.getChannel(channelEvent.id),
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
      sound = channel.playSound(SoundReference.file('looping.wav'),
          looping: true, keepAlive: true);
      expect(sound.looping, isTrue);
      await Future<void>.delayed(Duration(milliseconds: 200));
      expect(
          channelObject.sounds[sound.id],
          predicate(
              (value) => value is BufferGenerator && value.looping == true));
    });
  });
}
