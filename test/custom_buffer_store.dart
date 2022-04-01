/// Provides the [CustomBufferStore] class.
import 'dart:io';
import 'dart:math';

import 'package:dart_synthizer/dart_synthizer.dart';
import 'package:ziggurat/ziggurat.dart';
import 'package:ziggurat_sounds/ziggurat_sounds.dart';

/// A custom buffer store that always returns a buffer.
class CustomBufferStore extends BufferStore {
  /// Create an instance.
  CustomBufferStore(final Random random, final Synthizer synthizer)
      : super(random, synthizer);

  @override
  Buffer getBuffer(final AssetReference reference) =>
      Buffer.fromFile(synthizer, File('sound.wav'));
}
