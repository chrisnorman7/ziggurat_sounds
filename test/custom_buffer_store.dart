/// Provides the [CustomBufferStore] class.
import 'dart:math';

import 'package:dart_synthizer/buffer.dart';
import 'package:dart_synthizer/synthizer.dart';
import 'package:ziggurat/ziggurat.dart';
import 'package:ziggurat_sounds/ziggurat_sounds.dart';

/// A custom buffer store that always returns a buffer.
class CustomBufferStore extends BufferStore {
  /// Create an instance.
  CustomBufferStore(Random random, Synthizer synthizer)
      : super(random, synthizer);

  @override
  Buffer getBuffer(SoundReference reference) => Buffer(synthizer);
}
