/// Provides the [CustomSoundManager] class.
import 'package:dart_synthizer/context.dart';
import 'package:ziggurat/ziggurat.dart';
import 'package:ziggurat_sounds/ziggurat_sounds.dart';

/// A sound manager that saves all events.
class CustomSoundManager extends SoundManager {
  /// Create an instance.
  CustomSoundManager(Context context)
      : events = [],
        super(context);

  /// All the events that have been processed.
  final List<SoundEvent> events;

  @override
  void handleEvent(SoundEvent event) {
    super.handleEvent(event);
    events.add(event);
  }
}
