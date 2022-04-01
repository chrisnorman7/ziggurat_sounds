/// Provides various common functions used by code in this directory.
import 'dart:convert';
import 'dart:io';

const _jsonEncoder = JsonEncoder.withIndent('  ');

/// A mixin for providing simple dumping and loading.
mixin DumpLoadMixin {
  /// Convert this object to JSON.
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }

  /// Dump an instance to [file].
  void dump(final File file) {
    final data = toJson();
    final json = _jsonEncoder.convert(data);
    file.writeAsStringSync(json);
  }
}
