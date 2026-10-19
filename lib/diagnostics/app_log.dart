import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../core/click_button.dart';
import '../core/hex.dart';

class LogLine {
  const LogLine(this.at, this.tag, this.text);

  final DateTime at;
  final String tag;
  final String text;

  @override
  String toString() => '${at.toIso8601String()} [$tag] $text';
}

/// In-memory ring buffer of timestamped log lines, exportable to a file.
class AppLog {
  AppLog({
    this._capacity = 5000,
    Future<Directory> Function()? documentsDir,
    this._now = DateTime.now,
  }) : _documentsDir = documentsDir ?? getApplicationDocumentsDirectory;

  final int _capacity;
  final Future<Directory> Function() _documentsDir;
  final DateTime Function() _now;
  final _lines = ListQueue<LogLine>();
  final _stream = StreamController<LogLine>.broadcast();

  List<LogLine> get lines => List.unmodifiable(_lines);
  Stream<LogLine> get stream => _stream.stream;

  void info(String tag, String message) => _add(LogLine(_now(), tag, message));

  void raw(ClickSide side, Uint8List bytes) =>
      _add(LogLine(_now(), 'rx-${side.name}', hex(bytes, sep: ' ')));

  void _add(LogLine line) {
    _lines.addLast(line);
    while (_lines.length > _capacity) {
      _lines.removeFirst();
    }
    _stream.add(line);
  }

  /// Writes every line to `<Documents>/ShiftPad/shiftpad-logs-<stamp>.txt`.
  Future<File> export() async {
    final dir = Directory('${(await _documentsDir()).path}/ShiftPad');
    await dir.create(recursive: true);
    final t = _now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
    final file = File('${dir.path}/shiftpad-logs-$stamp.txt');
    await file.writeAsString(_lines.map((l) => '$l\n').join());
    return file;
  }
}
