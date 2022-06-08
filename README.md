# ziggurat_sounds

## Description

This package provides sound support for the [ziggurat](https://pub.dev/packages/ziggurat) package.

It works by way of the `SoundManager` class:

```dart
import 'dart:math';

import 'package:dart_sdl/dart_sdl.dart';
import 'package:dart_synthizer/dart_synthizer.dart';
import 'package:ziggurat/ziggurat.dart';
import 'package:ziggurat_sounds/src/buffer_cache.dart';
import 'package:ziggurat_sounds/src/sound_manager.dart';

final synthizer = Synthizer()..initialize();
final context = synthizer.createContext();
final sdl = Sdl()..init();
final game = Game(
  title: 'ziggurat_sounds example',
  sdl: sdl,
);
final bufferCache = BufferCache(
  synthizer: synthizer,
  maxSize: pow(1024, 3).floor(),
  random: game.random,
);
final soundManager = SoundManager(
  game: game,
  context: context,
  bufferCache: bufferCache,
);
```

You can then attach your `SoundManager` instance to your `Game` instance:

```dart
void main() {
  game.sounds.listen(
    (final event) {
      print('Sound: $event');
      soundManager.handleEvent(event);
    },
    onDone: () => print('Sound done.'),
    onError: (e, s) {
      print('Sound error: $e');
      if (s != null) {
        print(s);
      }
    },
  );
}
```
