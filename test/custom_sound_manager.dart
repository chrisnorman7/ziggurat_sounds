// ignore_for_file: prefer_final_parameters
/// Provides the [CustomSoundManager] class.
import 'package:ziggurat/sound.dart';
import 'package:ziggurat_sounds/ziggurat_sounds.dart';

/// A sound manager that saves all events.
class CustomSoundManager extends SoundManager {
  /// Create an instance.
  CustomSoundManager({
    required super.game,
    required super.context,
    required List<BufferStore> super.bufferStores,
  }) : events = [];

  /// All the events that have been processed.
  final List<SoundEvent> events;

  @override
  void handleEvent(final SoundEvent event) {
    super.handleEvent(event);
    events.add(event);
  }
}
