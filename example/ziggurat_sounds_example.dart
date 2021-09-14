// ignore_for_file: avoid_print
/// A quick example for using ziggurat_sounds.
import 'dart:io';
import 'dart:math';

import 'package:dart_synthizer/dart_synthizer.dart';
import 'package:ziggurat/ziggurat.dart';
import 'package:ziggurat_sounds/ziggurat_sounds.dart';

Future<void> main() async {
  final synthizer = Synthizer()..initialize();
  final ctx = synthizer.createContext();
  print('Created audio context.');
  final bufferStore = BufferStore(Random(), synthizer);
  print('Created a buffer store.');
  await bufferStore.addFile(File('aim.wav'));
  print('Added aim.wav.');
  await bufferStore.addFile(File('shot.wav'));
  print('Added shot.wav.');
  final soundManager = SoundManager(ctx)..bufferStores.add(bufferStore);
  print('Created a sound manager.');
  final game = Game('Sounds Example')..sounds.listen(soundManager.handleEvent);
  print(
      'Created a game and registered the sound manager to listen for events.');
  game.interfaceSounds.playSound(bufferStore.getSoundReference('aim.wav'));
  ctx.destroy();
  print('Destroyed context.');
  synthizer.shutdown();
  print('Done.');
}
