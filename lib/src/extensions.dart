/// Provides various extensions used by this package.
import 'package:dart_synthizer/dart_synthizer.dart';
import 'package:ziggurat/ziggurat.dart';

/// An extension for creating a [GlobalFdnReverb] instance from a
/// [ReverbPreset] instance.
extension MakeGlobalFdnReverb on ReverbPreset {
  /// Make a reverb object from this preset.
  GlobalFdnReverb makeReverb(Context context) {
    final r = GlobalFdnReverb(context)
      ..meanFreePath = meanFreePath
      ..t60 = t60
      ..lateReflectionsLfRolloff = lateReflectionsLfRolloff
      ..lateReflectionsLfReference = lateReflectionsLfReference
      ..lateReflectionsHfRolloff = lateReflectionsHfRolloff
      ..lateReflectionsHfReference = lateReflectionsHfReference
      ..lateReflectionsDiffusion = lateReflectionsDiffusion
      ..lateReflectionsModulationDepth = lateReflectionsModulationDepth
      ..lateReflectionsModulationFrequency = lateReflectionsModulationFrequency
      ..lateReflectionsDelay = lateReflectionsDelay
      ..gain = gain;
    return r;
  }
}
