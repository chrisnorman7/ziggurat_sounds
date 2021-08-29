/// Provides the [Reverb] class.
import 'package:dart_synthizer/dart_synthizer.dart';

/// A reverb object.
class Reverb {
  /// Create an instance.
  Reverb(this.name, this.reverb);

  /// The name of the reverb preset that was used to create this instance.
  final String name;

  /// The reverb instance.
  final GlobalFdnReverb reverb;
}
