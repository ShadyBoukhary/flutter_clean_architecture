import 'dart:io';

const packageName = 'example';

void main() async {
  final cwd = Directory.current.uri;
  final libDir = Directory.fromUri(cwd.resolve('lib'));
  final buffer = StringBuffer();

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) =>
          file.path.endsWith('.dart') &&
          !file.path.contains('.freezed.') &&
          !file.path.contains('.g.') &&
          !file.path.endsWith('generated_plugin_registrant.dart') &&
          !file.readAsLinesSync().any((line) => line.startsWith('part of')))
      .toList();

  buffer.writeln('// ignore_for_file: unused_import');
  buffer.writeln();

  for (final file in files) {
    final fileLibPath =
        file.uri.toFilePath().substring(libDir.uri.toFilePath().length);
    buffer.writeln('import \'package:$packageName/$fileLibPath\';');
  }

  buffer.writeln();
  buffer.writeln('void main() {}');
  buffer.writeln();

  final output =
      File(cwd.resolve('test/coverage_helper_test.dart').toFilePath());
  await output.writeAsString(buffer.toString());
}
