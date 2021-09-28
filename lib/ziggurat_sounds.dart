/// Add sound support to ziggurat.
///
/// To use this package, you will need a [Game] instance:
///
/// ```
/// final game = Game('Ziggurat Sounds');
/// ```
///
/// The game will emit sound events. These events must be handled by a
/// [SoundManager]
///
/// ```
/// final soundManager = SoundManager(synthizerContext);
/// ```
///
/// By default, the sound manager has no sounds loaded. For that, you need an
/// instance of [BufferStore]:
///
/// ```
/// final bufferStore = BufferStore(random, synthizer);
/// ```
///
/// Add the buffer store to the sound manager:
///
/// ```
/// soundManager.bufferStores.add(bufferStore);
/// ```
///
/// Now you can add sounds to the buffer store using the methods on that class.
///
/// If you are using the
/// [ziggurat_utils](https://pub.dev/packages/ziggurat_utils) package, you can
/// create buffer stores from encrypted assets using the `vault` command.
library ziggurat_sounds;

import 'package:ziggurat/ziggurat.dart';

import 'src/sound_manager.dart';

export 'src/audio_channel.dart';
export 'src/buffer_cache.dart';
export 'src/buffer_store.dart';
export 'src/error.dart';
export 'src/extensions.dart';
export 'src/json/data_file.dart';
export 'src/json/vault_file.dart';
export 'src/reverb.dart';
export 'src/sound_manager.dart';
