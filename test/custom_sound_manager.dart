/// Provides the [CustomSoundManager] class.
import 'package:dart_synthizer/dart_synthizer.dart';
import 'package:ziggurat/sound.dart';
import 'package:ziggurat/ziggurat.dart';
import 'package:ziggurat_sounds/ziggurat_sounds.dart';

/// A sound manager that saves all events.
class CustomSoundManager extends SoundManager {
  /// Create an instance.
  CustomSoundManager({
    required final Game game,
    required final Context context,
    required final List<BufferStore> bufferStores,
  })  : events = [],
        super(game: game, context: context, bufferStores: bufferStores);

  /// All the events that have been processed.
  final List<SoundEvent> events;

  @override
  void handleEvent(final SoundEvent event) {
    super.handleEvent(event);
    events.add(event);
  }
}
