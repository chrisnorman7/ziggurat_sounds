// ignore_for_file: avoid_print
/// A script for manipulating vault files.
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:encrypt/encrypt.dart';
import 'package:ziggurat/ziggurat.dart' show SoundType;
import 'package:ziggurat_sounds/ziggurat_sounds.dart'
    show VaultFileStub, DataFileEntry, VaultFile;

/// A command for creating vault files.
class CreateCommand extends Command<void> {
  /// Create an instance.
  CreateCommand() {
    argParser.addOption('comment',
        abbr: 'c', help: 'The comment to use for the resulting vault file.');
  }
  @override
  final String name = 'create';
  @override
  final String description = 'Create a new vault file.';
  @override
  void run() {
    final results = argResults;
    if (results == null) {
      return;
    }
    if (results.rest.length != 1) {
      return print('Usage: ${runner?.executableName} $name <filename>');
    }
    final file = File(results.rest.first);
    if (file.existsSync()) {
      return print('File ${file.path} already exists.');
    }
    VaultFileStub(comment: results['comment'] as String?).dump(file);
    print('Created ${file.path}.');
  }
}

/// A command for adding a file to a [VaultFileStub].
class AddFileCommand extends Command<void> {
  AddFileCommand() {
    argParser
      ..addOption('variable',
          abbr: 'v',
          help: 'The name of the resulting dart variable',
          mandatory: true)
      ..addOption('comment',
          abbr: 'c',
          help: 'The comment to show above the variable declaration');
  }
  @override
  final String name = 'file';
  @override
  final String description = 'Add a file.';
  @override
  void run() {
    final results = argResults;
    if (results == null) {
      return;
    }
    if (results.rest.length != 2) {
      return print('Usage: $name ${runner?.executableName} {vault-file-name> '
          '<data-file-name>');
    }
    final file = File(results.rest.first);
    if (file.existsSync() == false) {
      return print('File ${file.path} does not exist.');
    }
    final vaultFile = VaultFileStub.fromFile(file);
    final filename = results.rest.last;
    final variableName = results['variable'] as String;
    final comment = results['comment'] as String?;
    for (final entry in vaultFile.files) {
      if (entry.variableName == variableName) {
        return print(
            'The variable name $variableName is already used for the file '
            '${entry.fileName}.');
      }
    }
    for (final entry in vaultFile.folders) {
      if (entry.variableName == variableName) {
        return print(
            'The variable name $variableName is already used for the folder '
            '${entry.fileName}.');
      }
    }
    final entry = DataFileEntry(variableName, filename, comment: comment);
    vaultFile
      ..files.add(entry)
      ..dump(file);
    print('Done.');
  }
}

/// A command for adding a folder to a [VaultFileStub].
class AddFolderCommand extends Command<void> {
  AddFolderCommand() {
    argParser
      ..addOption('variable',
          abbr: 'v',
          help: 'The name of the resulting dart variable',
          mandatory: true)
      ..addOption('comment',
          abbr: 'c',
          help: 'The comment to show above the variable declaration');
  }
  @override
  final String name = 'folder';
  @override
  final String description = 'Add a folder.';
  @override
  void run() {
    final results = argResults;
    if (results == null) {
      return;
    }
    if (results.rest.length != 2) {
      return print('Usage: $name ${runner?.executableName} {vault-file-name> '
          '<data-file-name>');
    }
    final file = File(results.rest.first);
    if (file.existsSync() == false) {
      return print('File ${file.path} does not exist.');
    }
    final vaultFile = VaultFileStub.fromFile(file);
    final folder = results.rest.last;
    final variableName = results['variable'] as String;
    final comment = results['comment'] as String?;
    for (final entry in vaultFile.files) {
      if (entry.variableName == variableName) {
        return print(
            'The variable name $variableName is already used for the file '
            '${entry.fileName}.');
      }
    }
    for (final entry in vaultFile.folders) {
      if (entry.variableName == variableName) {
        return print(
            'The variable name $variableName is already used for the folder '
            '${entry.fileName}.');
      }
    }
    final entry = DataFileEntry(variableName, folder, comment: comment);
    vaultFile
      ..folders.add(entry)
      ..dump(file);
    print('Done.');
  }
}

/// The command runner for listing files in a [VaultFileStub].
class LsCommand extends Command<void> {
  @override
  final String name = 'ls';
  @override
  final String description = 'List files.';
  @override
  void run() {
    final results = argResults;
    if (results == null) {
      return;
    }
    final rest = results.rest;
    if (rest.isEmpty) {
      print('You must provide at least one filename.\n');
      return print('Usage: ${runner?.executableName} <filename>');
    }
    for (final filename in rest) {
      final file = File(filename);
      if (file.existsSync()) {
        print('--- $filename ---');
        final vaultFile = VaultFileStub.fromFile(file);
        if (vaultFile.folders.isEmpty) {
          print('No folders to show.');
        } else {
          for (final entry in vaultFile.folders) {
            print('${entry.variableName}: ${entry.comment}');
            print('Folder: ${entry.fileName}');
          }
        }
        if (vaultFile.files.isEmpty) {
          print('No files to show.');
        } else {
          for (final entry in vaultFile.files) {
            print('${entry.variableName}: ${entry.comment}');
            print('Filename: ${entry.fileName}');
          }
        }
      } else {
        print('Could not show the contents of $filename: '
            'File does not exist.');
      }
    }
  }
}

/// A command for adding a comment to a [VaultFileStub].
class CommentCommand extends Command<void> {
  /// Create an instance.
  CommentCommand() {
    argParser.addOption('comment',
        abbr: 'c', help: 'The new comment for the entry');
  }
  @override
  final String name = 'comment';
  @override
  final String description =
      'Change or clear the comment for a file or folder.';

  @override
  void run() {
    final results = argResults;
    if (results == null) {
      return;
    }
    if (results.rest.length != 2) {
      return print('Usage: ${runner?.executableName} $name <json-filename> '
          '<variableName>');
    }
    final filename = results.rest.first;
    final variableName = results.rest.last;
    final file = File(filename);
    if (file.existsSync() == false) {
      return print('File $filename does not exist.');
    }
    final vaultFile = VaultFileStub.fromFile(file);
    for (final entry in vaultFile.files + vaultFile.folders) {
      if (entry.variableName == variableName) {
        entry.comment = results['comment'] as String?;
        vaultFile.dump(file);
        return print(
            'Comment ${entry.comment == null ? "cleared" : "changed"}.');
      }
    }
    print('Variable $variableName not found.');
  }
}

/// A command for removing a file from a [VaultFileStub].
class RemoveCommand extends Command<void> {
  @override
  final String name = 'remove';
  @override
  final String description = 'Remove a file or folder.';
  @override
  void run() {
    final results = argResults;
    if (results == null) {
      return;
    }
    if (results.rest.length != 2) {
      return print('Usage: ${runner?.executableName} $name <json-filename> '
          '<variable-name>');
    }
    final file = File(results.rest.first);
    if (file.existsSync() == false) {
      return print('Json file ${file.path} does not exist.');
    }
    final vaultFile = VaultFileStub.fromFile(file);
    DataFileEntry? toRemove;
    for (final entry in vaultFile.folders + vaultFile.files) {
      if (entry.variableName == results.rest.last) {
        toRemove = entry;
      }
    }
    if (toRemove == null) {
      return print('No variable named ${results.rest.last} found.');
    }
    if (vaultFile.folders.contains(toRemove)) {
      vaultFile.folders.remove(toRemove);
    } else {
      vaultFile.files.remove(toRemove);
    }
    vaultFile.dump(file);
    print('Done.');
  }
}

/// A command for converting a [VaultFileStub] to dart code.
class CompileCommand extends Command<void> {
  /// Create the command.
  CompileCommand() {
    argParser.addOption('vault-file-name',
        abbr: 'f', help: 'The name to use for the resulting vault file.');
  }
  @override
  final String name = 'compile';
  @override
  final String description =
      'Create an encrypted vault file and corresponding Dart code.';

  /// Write a comment to [buffer].
  void writeComment(String comment, StringBuffer buffer) {
    for (final line in comment.split('\n')) {
      buffer.writeln('/// $line');
    }
  }

  @override
  Future<void> run() async {
    final results = argResults;
    if (results == null) {
      return;
    }
    if (results.rest.length != 3) {
      return print('Usage: ${runner?.executableName} $name <json-filename> '
          '<dart-filename> <ClassName>');
    }
    final jsonFilename = results.rest.first;
    final dartFilename = results.rest[1];
    final className = results.rest.last;
    final jsonFile = File(jsonFilename);
    final vaultFileName = (results['vault-file-name'] as String?) ??
        '${jsonFilename.substring(0, jsonFilename.indexOf("."))}.dat';
    final encryptionKey = SecureRandom(32).base64;
    if (jsonFile.existsSync() == false) {
      print('JSON file $jsonFilename does not exist.');
    }
    final dartFile = File(dartFilename);
    if (dartFile.existsSync()) {
      return print('Dart file $dartFilename already exists.');
    }
    final stub = VaultFileStub.fromFile(jsonFile);
    final vaultFile = VaultFile();
    var comment = stub.comment;
    final stringBuffer = StringBuffer()
      ..writeln('/// Automatically generated from $jsonFilename, do not edit.');
    if (comment != null) {
      writeComment(comment, stringBuffer);
    }
    stringBuffer
      ..writeln("import 'dart:io';")
      ..writeln("import 'dart:math';")
      ..writeln()
      ..writeln("import 'package:dart_synthizer/dart_synthizer.dart';")
      ..writeln("import 'package:ziggurat/ziggurat.dart';")
      ..writeln("import 'package:ziggurat_sounds/ziggurat_sounds.dart';")
      ..writeln()
      ..writeln('class $className extends BufferStore {')
      ..writeln('  /// Create an instance.')
      ..writeln('  $className(Random random, Synthizer synthizer, {'
          "this.vaultFileName = '$vaultFileName', "
          "this.encryptionKey = '$encryptionKey'})"
          ' : super(random, synthizer);')
      ..writeln('  /// The name of the vault file to load.')
      ..writeln('  final String vaultFileName;')
      ..writeln('  /// The encryption key to use to decrypt the vault file.')
      ..writeln('  final String encryptionKey;');
    for (final entry in stub.folders) {
      final path = entry.fileName.replaceAll(r'\', '/');
      final folder = Directory(path);
      if (folder.existsSync()) {
        comment = entry.comment;
        if (comment != null) {
          writeComment(comment, stringBuffer);
        }
        final variableName = entry.variableName;
        stringBuffer
          ..writeln("final $variableName = SoundReference('$variableName', "
              '${SoundType.collection});');
        final files = <String>[];
        for (final entity in folder.listSync()) {
          if (entity is File) {
            files.add(base64.encode(entity.readAsBytesSync()));
          }
        }
        vaultFile.folders[variableName] = files;
      } else {
        print('Directory $path does not exist.');
      }
    }
    for (final entry in stub.files) {
      final path = entry.fileName.replaceAll(r'\', '/');
      final file = File(path);
      if (file.existsSync()) {
        stringBuffer.writeln();
        final comment = entry.comment;
        if (comment != null) {
          writeComment(comment, stringBuffer);
        }
        final variableName = entry.variableName;
        stringBuffer
          ..writeln("final $variableName = SoundReference('$variableName', "
              '${SoundType.file});')
          ..writeln();
        vaultFile.files[variableName] = base64Encode(file.readAsBytesSync());
      } else {
        print('File $path does not exist.');
      }
    }
    stringBuffer
      ..writeln('  /// Load the vault file.')
      ..writeln('  Future<void> load() async {')
      ..writeln(
          '    final vaultFile = await VaultFile.fromFile(File(vaultFileName), '
          'encryptionKey);')
      ..writeln('    addVaultFile(vaultFile);')
      ..writeln('  }')
      ..writeln('}');
    dartFile.writeAsStringSync(stringBuffer.toString());
    print('Wrote file $dartFilename.');
    vaultFile.write(File(vaultFileName), encryptionKey);
    print('Wrote $vaultFileName.');
    final result = await Process.run('dart', <String>['format', dartFilename]);
    print(result.stdout);
    if (result.exitCode != 0) {
      print(result.stderr);
    }
  }
}

Future<void> main(List<String> args) async {
  final command = CommandRunner<void>(
      'vault',
      'Create and edit vault files.\n\n'
          'You must first create a vault file with the `create` command:\n'
          '  `vault create vault.json -c "Sounds for the game."`')
    ..addCommand(CreateCommand())
    ..addCommand(AddFileCommand())
    ..addCommand(AddFolderCommand())
    ..addCommand(LsCommand())
    ..addCommand(CommentCommand())
    ..addCommand(RemoveCommand())
    ..addCommand(CompileCommand());
  try {
    await command.run(args);
  } on UsageException catch (e) {
    print(e);
  }
}
