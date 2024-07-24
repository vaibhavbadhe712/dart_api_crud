import 'dart:io';
import 'package:watcher/watcher.dart';
import 'dart:async';

Process? serverProcess;

Future<void> startServer() async {
  serverProcess = await Process.start(
    'dart',
    ['run', 'main.dart'], // Change 'main.dart' to your server file name
    mode: ProcessStartMode.inheritStdio,
  );
}

void stopServer() {
  serverProcess?.kill();
}

void watchForChanges() {
  final watcher = DirectoryWatcher(Directory.current.path);

  watcher.events.listen((event) {
    print('File changed: ${event.path}');
    stopServer();
    startServer();
  });
}

void main() async {
  await startServer();
  watchForChanges();
}
