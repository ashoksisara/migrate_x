import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';

enum _LineType { context, addition, deletion }

class _DiffLine {
  final _LineType type;
  final String content;
  final int? oldNum;
  final int? newNum;
  const _DiffLine(this.type, this.content, {this.oldNum, this.newNum});
}

class _Hunk {
  final List<_DiffLine> lines;
  final bool isSeparator;
  const _Hunk({required this.lines, this.isSeparator = false});
}

class DiffViewer extends StatefulWidget {
  final String oldText;
  final String newText;

  const DiffViewer({super.key, required this.oldText, required this.newText});

  @override
  State<DiffViewer> createState() => _DiffViewerState();
}

class _DiffViewerState extends State<DiffViewer> {
  static const _contextLines = 3;
  late List<_DiffLine> _allLines;
  late List<_Hunk> _hunks;
  final Set<int> _expandedSeparators = {};

  @override
  void initState() {
    super.initState();
    _computeDiff();
  }

  @override
  void didUpdateWidget(DiffViewer old) {
    super.didUpdateWidget(old);
    if (old.oldText != widget.oldText || old.newText != widget.newText) {
      _expandedSeparators.clear();
      _computeDiff();
    }
  }

  /// Encode lines to single chars for line-level diffing.
  static ({String chars1, String chars2, List<String> lineArray})
      _linesToChars(String text1, String text2) {
    final lineArray = <String>[''];
    final lineHash = <String, int>{};

    String munge(String text) {
      final buf = StringBuffer();
      final lines = text.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = (i < lines.length - 1) ? '${lines[i]}\n' : lines[i];
        if (line.isEmpty) continue;
        if (lineHash.containsKey(line)) {
          buf.writeCharCode(lineHash[line]!);
        } else {
          lineArray.add(line);
          lineHash[line] = lineArray.length - 1;
          buf.writeCharCode(lineArray.length - 1);
        }
      }
      return buf.toString();
    }

    return (
      chars1: munge(text1),
      chars2: munge(text2),
      lineArray: lineArray,
    );
  }

  /// Decode char-level diffs back to line text.
  static void _charsToLines(List<Diff> diffs, List<String> lineArray) {
    for (final d in diffs) {
      final buf = StringBuffer();
      for (var i = 0; i < d.text.length; i++) {
        buf.write(lineArray[d.text.codeUnitAt(i)]);
      }
      d.text = buf.toString();
    }
  }

  void _computeDiff() {
    final encoded = _linesToChars(widget.oldText, widget.newText);
    final diffs = diff(encoded.chars1, encoded.chars2, checklines: false);
    _charsToLines(diffs, encoded.lineArray);
    cleanupSemantic(diffs);

    final lines = <_DiffLine>[];
    var oldNum = 1;
    var newNum = 1;

    for (final d in diffs) {
      final text = d.text;
      var splitLines = text.split('\n');
      if (splitLines.isNotEmpty && splitLines.last.isEmpty) {
        splitLines = splitLines.sublist(0, splitLines.length - 1);
      }

      switch (d.operation) {
        case DIFF_EQUAL:
          for (final l in splitLines) {
            lines.add(_DiffLine(_LineType.context, l,
                oldNum: oldNum, newNum: newNum));
            oldNum++;
            newNum++;
          }
        case DIFF_DELETE:
          for (final l in splitLines) {
            lines.add(_DiffLine(_LineType.deletion, l, oldNum: oldNum));
            oldNum++;
          }
        case DIFF_INSERT:
          for (final l in splitLines) {
            lines.add(_DiffLine(_LineType.addition, l, newNum: newNum));
            newNum++;
          }
      }
    }

    _allLines = lines;
    _hunks = _buildHunks(lines);
  }

  List<_Hunk> _buildHunks(List<_DiffLine> lines) {
    final changeIndices = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].type != _LineType.context) changeIndices.add(i);
    }
    if (changeIndices.isEmpty) {
      return [_Hunk(lines: lines, isSeparator: true)];
    }

    final hunks = <_Hunk>[];
    var rangeStart = 0;

    var i = 0;
    while (i < changeIndices.length) {
      final chunkStart = changeIndices[i];
      var chunkEnd = chunkStart;

      while (i + 1 < changeIndices.length &&
          changeIndices[i + 1] <= chunkEnd + _contextLines * 2 + 1) {
        i++;
        chunkEnd = changeIndices[i];
      }

      final ctxStart = (chunkStart - _contextLines).clamp(0, lines.length);
      final ctxEnd = (chunkEnd + _contextLines + 1).clamp(0, lines.length);

      if (ctxStart > rangeStart) {
        hunks.add(_Hunk(lines: lines.sublist(rangeStart, ctxStart), isSeparator: true));
      }

      hunks.add(_Hunk(lines: lines.sublist(ctxStart, ctxEnd)));
      rangeStart = ctxEnd;
      i++;
    }

    if (rangeStart < lines.length) {
      hunks.add(_Hunk(lines: lines.sublist(rangeStart), isSeparator: true));
    }

    return hunks;
  }

  @override
  Widget build(BuildContext context) {
    if (_allLines.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final addBg = isDark ? const Color(0xFF1a3a1a) : const Color(0xFFe6ffec);
    final delBg = isDark ? const Color(0xFF3a1a1a) : const Color(0xFFffebe9);
    final addFg = isDark ? const Color(0xFF7ee787) : const Color(0xFF1a7f37);
    final delFg = isDark ? const Color(0xFFf85149) : const Color(0xFFcf222e);
    final ctxFg = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final lineNumColor = theme.colorScheme.onSurface.withValues(alpha: 0.35);
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.3);
    final sepBg = isDark ? const Color(0xFF1a2233) : const Color(0xFFf6f8fa);

    final maxNum = _allLines.fold(0, (m, l) {
      final o = l.oldNum ?? 0;
      final n = l.newNum ?? 0;
      return (o > m ? o : m) > n ? (o > m ? o : m) : n;
    });
    final gutterW = '$maxNum'.length.clamp(3, 6);

    const mono =
        TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.5);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var hi = 0; hi < _hunks.length; hi++)
                if (_hunks[hi].isSeparator &&
                    !_expandedSeparators.contains(hi))
                  _separator(hi, _hunks[hi], sepBg, lineNumColor, mono)
                else
                  ..._hunks[hi].lines.map((line) => _row(
                      line, addBg, delBg, addFg, delFg, ctxFg,
                      lineNumColor, borderColor, mono, gutterW)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _separator(
      int idx, _Hunk hunk, Color bg, Color fg, TextStyle style) {
    return GestureDetector(
      onTap: () => setState(() => _expandedSeparators.add(idx)),
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.unfold_more, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              '${hunk.lines.length} unchanged lines',
              style: style.copyWith(
                  color: fg, fontSize: 11.5, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    _DiffLine line,
    Color addBg,
    Color delBg,
    Color addFg,
    Color delFg,
    Color ctxFg,
    Color numColor,
    Color borderColor,
    TextStyle mono,
    int gutterW,
  ) {
    Color? rowBg;
    Color fg = ctxFg;
    String prefix = ' ';

    switch (line.type) {
      case _LineType.addition:
        rowBg = addBg;
        fg = addFg;
        prefix = '+';
      case _LineType.deletion:
        rowBg = delBg;
        fg = delFg;
        prefix = '-';
      case _LineType.context:
        break;
    }

    final oldStr = line.oldNum?.toString().padLeft(gutterW) ?? ''.padLeft(gutterW);
    final newStr = line.newNum?.toString().padLeft(gutterW) ?? ''.padLeft(gutterW);

    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: Text(oldStr, style: mono.copyWith(color: numColor, fontSize: 11)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: Text(newStr, style: mono.copyWith(color: numColor, fontSize: 11)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              prefix,
              style: mono.copyWith(
                color: fg,
                fontWeight:
                    line.type != _LineType.context ? FontWeight.bold : null,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(line.content, style: mono.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}
