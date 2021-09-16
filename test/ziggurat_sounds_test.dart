import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_synthizer/dart_synthizer.dart';
import 'package:test/test.dart';
import 'package:ziggurat/ziggurat.dart';
import 'package:ziggurat_sounds/src/sound_manager.dart';
import 'package:ziggurat_sounds/ziggurat_sounds.dart';

import 'custom_buffer_store.dart';
import 'custom_sound_manager.dart';

void main() {
  final synthizer = Synthizer()..initialize();
  tearDownAll(synthizer.shutdown);
  final context = synthizer.createContext();
  final buffers = CustomBufferStore(Random(), synthizer);
  final game = Game('Sounds');
  final soundManager = CustomSoundManager(context)..bufferStores.add(buffers);
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
      expect(soundManager.events.length, equals(2));
      expect(soundManager.events.first, equals(game.interfaceSounds));
      expect(soundManager.events.last, equals(game.ambianceSounds));
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
      expect(soundManager.events.length, equals(3));
      expect(soundManager.events.last, equals(reverb));
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
      expect(soundManager.events.length, equals(4));
      expect(
          soundManager.events.last,
          predicate(
              (value) => value is DestroyReverb && value.id == reverb.id));
    });
    test('Channel', () async {
      var length = soundManager.events.length;
      var channelEvent = game.createSoundChannel();
      await Future<void>.delayed(Duration(milliseconds: 200));
      var channel = soundManager.getChannel(channelEvent.id);
      expect(soundManager.events.length, equals(length + 1));
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
      // There is no real way to test these filters work, since the `filter`
      // property is read-only in Synthizer land.
      //
      // The best we can do is to make sure there are no crashes when we set
      // filters
      length = soundManager.events.length;
      channelEvent.filterBandpass(440.0, 200.0);
      await Future<void>.delayed(Duration(milliseconds: 200));
      expect(soundManager.events.length, equals(++length));
      var event = soundManager.events.last;
      expect(event, isA<SoundChannelBandpass>());
      expect((event as SoundChannelBandpass).frequency, equals(440.0));
      expect(event.bandwidth, equals(200.0));
      expect(event.id, equals(channel.id));
      channelEvent.filterHighpass(
        440.0,
      );
      await Future<void>.delayed(Duration(milliseconds: 200));
      expect(soundManager.events.length, equals(++length));
      event = soundManager.events.last;
      expect(event, isA<SoundChannelHighpass>());
      expect(event.id, equals(channel.id));
      expect((event as SoundChannelHighpass).frequency, equals(440.0));
      channelEvent.filterLowpass(440.0);
      await Future<void>.delayed(Duration(milliseconds: 200));
      expect(soundManager.events.length, equals(++length));
      event = soundManager.events.last;
      expect(event, isA<SoundChannelLowpass>());
      expect(event.id, equals(channel.id));
      expect((event as SoundChannelLowpass).frequency, equals(440.0));
      channelEvent.clearFilter();
      await Future<void>.delayed(Duration(milliseconds: 200));
      expect(soundManager.events.length, equals(++length));
      event = soundManager.events.last;
      expect(event, isA<SoundChannelFilter>());
      expect(event.id, equals(channel.id));
      expect(event, isNot(isA<SoundChannelHighpass>()));
      expect(event, isNot(isA<SoundChannelLowpass>()));
      expect(event, isNot(isA<SoundChannelBandpass>()));
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
      await Future<void>.delayed(Duration(milliseconds: 200));
      final generator = channelObject.sounds[sound.id];
      expect(generator, isA<BufferGenerator>());
      expect(soundManager.getSound(sound.id), isA<BufferGenerator>());
      if (generator != null) {
        // We know it is, but now Dart does too.
        expect(generator.gain, equals(sound.gain));
        sound.looping = true;
        await Future<void>.delayed(Duration(milliseconds: 200));
        expect(generator.looping, isTrue);
        sound.looping = false;
        await Future<void>.delayed(Duration(milliseconds: 200));
        expect(generator.looping, isFalse);
        sound.gain = 1.5;
        await Future<void>.delayed(Duration(milliseconds: 200));
        expect(generator.gain, equals(1.5));
        sound.gain = 1.0;
        await Future<void>.delayed(Duration(milliseconds: 200));
        expect(generator.gain, equals(1.0));
        final fade = sound.fade(length: 1.0, startGain: 1.0);
        await Future<void>.delayed(Duration(milliseconds: 200));
        expect(generator.gain, lessThan(1.0));
        fade.cancel();
        await Future<void>.delayed(Duration(milliseconds: 200));
        final gain = generator.gain;
        await Future<void>.delayed(Duration(milliseconds: 200));
        expect(generator.gain, equals(gain));
      } else {
        throw Exception('The world has gone mad.');
      }
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
  group('SoundManager', () {
    final soundManager = SoundManager(context);
    final bufferStore = BufferStore(Random(), synthizer);
    test('.bufferStores', () {
      expect(soundManager.bufferStores, isEmpty);
      soundManager.bufferStores.add(bufferStore);
      expect(soundManager.bufferStores.length, equals(1));
      soundManager.bufferStores.clear();
      expect(soundManager.bufferStores, isEmpty);
    });
    test('.getBuffer', () async {
      expect(() => soundManager.getBuffer(SoundReference.file('silence.wav')),
          throwsA(isA<NoSuchBufferError>()));
      await bufferStore.addFile(File('silence.wav'));
      soundManager.bufferStores.add(bufferStore);
      expect(soundManager.getBuffer(SoundReference.file('silence.wav')),
          isA<Buffer>());
    });
    test('.getChannel', () {
      expect(
          () => soundManager.getChannel(1), throwsA(isA<NoSuchChannelError>()));
      soundManager.handleEvent(SoundChannel(game: game, id: 1));
      final channel = soundManager.getChannel(1);
      expect(channel, isA<AudioChannel>());
      expect(channel.id, equals(1));
      expect(channel.source, isA<DirectSource>());
      expect(channel.sounds, isEmpty);
    });
    test('.getReverb', () {
      expect(
          () => soundManager.getReverb(2), throwsA(isA<NoSuchReverbError>()));
      soundManager.handleEvent(
          CreateReverb(game: game, id: 2, reverb: ReverbPreset('Test Reverb')));
      final reverb = soundManager.getReverb(2);
      expect(reverb, isA<Reverb>());
      expect(reverb.name, equals('Test Reverb'));
      expect(reverb.reverb, isA<GlobalFdnReverb>());
    });
    test('.getSound', () {
      expect(() => soundManager.getSound(3), throwsA(isA<NoSuchSoundError>()));
      expect(bufferStore.getBuffer(SoundReference.file('silence.wav')),
          isA<Buffer>());
      soundManager.bufferStores.add(bufferStore);
      final soundEvent = PlaySound(
          game: game,
          sound: SoundReference.file('silence.wav'),
          channel: game.interfaceSounds.id,
          keepAlive: true);
      soundManager.handleEvent(soundEvent);
      final sound = soundManager.getSound(soundEvent.id);
      expect(sound, isA<BufferGenerator>());
    });
  });
  group('BufferStore', () {
    final bufferStore = BufferStore(Random(), synthizer);
    setUp(() => bufferStore.clear(includeProtected: true));
    test('Initialisation', () {
      expect(bufferStore.bufferCollections, isEmpty);
      expect(bufferStore.bufferFiles, isEmpty);
    });
    test('addFile', () async {
      await bufferStore.addFile(File('silence.wav'));
      expect(bufferStore.bufferFiles.length, equals(1));
      expect(bufferStore.bufferFiles.first, equals('silence.wav'));
      expect(bufferStore.bufferCollections, isEmpty);
    });
    test('addDirectory', () async {
      await bufferStore.addDirectory(Directory('silences'));
      expect(bufferStore.bufferCollections.length, equals(1));
      expect(bufferStore.bufferCollections.first, equals('silences'));
      expect(bufferStore.bufferFiles, isEmpty);
    });
    test('removeBufferFile', () async {
      await bufferStore.addFile(File('silence.wav'));
      bufferStore.removeBufferFile('silence.wav');
      expect(bufferStore.bufferFiles, isEmpty);
      expect(bufferStore.bufferCollections, isEmpty);
    });
    test('removeBufferCollection', () async {
      await bufferStore.addDirectory(Directory('silences'));
      bufferStore.removeBufferCollection('silences');
      expect(bufferStore.bufferCollections, isEmpty);
      expect(bufferStore.bufferFiles, isEmpty);
    });
    test('clear', () async {
      await bufferStore.addDirectory(Directory('silences'));
      await bufferStore.addFile(File('silence.wav'));
      bufferStore.clear();
      expect(bufferStore.bufferCollections, isEmpty);
      expect(bufferStore.bufferFiles, isEmpty);
      await bufferStore.addDirectory(Directory('silences'), protected: true);
      await bufferStore.addFile(File('silence.wav'), protected: true);
      bufferStore.clear();
      expect(bufferStore.bufferCollections.length, equals(1));
      expect(bufferStore.bufferFiles.length, equals(1));
      bufferStore.clear(includeProtected: true);
      expect(bufferStore.bufferCollections, isEmpty);
      expect(bufferStore.bufferFiles, isEmpty);
    });
    test('addVaultFile', () {
      final silence = base64Encode(File('silence.wav').readAsBytesSync());
      final vaultFile = VaultFile(files: {
        'silence.wav': silence
      }, folders: {
        'silence': [silence]
      });
      bufferStore.addVaultFile(vaultFile);
      expect(bufferStore.bufferCollections.length, equals(1));
      expect(bufferStore.bufferFiles.length, equals(1));
      bufferStore
        ..clear()
        ..addVaultFile(vaultFile, protected: true);
      expect(bufferStore.bufferCollections.length, equals(1));
      expect(bufferStore.bufferFiles.length, equals(1));
      bufferStore.clear();
      expect(bufferStore.bufferCollections.length, equals(1));
      expect(bufferStore.bufferFiles.length, equals(1));
      bufferStore.clear(includeProtected: true);
      expect(bufferStore.bufferCollections, isEmpty);
      expect(bufferStore.bufferFiles, isEmpty);
    });
  });
}
