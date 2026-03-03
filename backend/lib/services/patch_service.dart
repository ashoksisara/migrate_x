class FileDiff {
  final String filename;
  final String oldText;
  final String newText;

  FileDiff({
    required this.filename,
    required this.oldText,
    required this.newText,
  });

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'oldText': oldText,
        'newText': newText,
      };
}

class PatchService {
  // TODO: Replace dummy diffs with actual migration diffs from LLM service
  List<FileDiff> generateDiffs(String id) {
    return [
      FileDiff(
        filename: 'lib/main.dart',
        oldText: '''
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: Text('Old App')),
        body: Center(child: Text('Hello World')),
      ),
    );
  }
}
''',
        newText: '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Migrated App')),
        body: const Center(child: Text('Hello World')),
      ),
    );
  }
}
''',
      ),
      FileDiff(
        filename: 'lib/widgets/counter.dart',
        oldText: '''
import 'package:flutter/material.dart';

class CounterWidget extends StatefulWidget {
  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: \$_count'),
        RaisedButton(
          onPressed: () => setState(() => _count++),
          child: Text('Increment'),
        ),
      ],
    );
  }
}
''',
        newText: '''
import 'package:flutter/material.dart';

class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: \$_count'),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
''',
      ),
      FileDiff(
        filename: 'lib/theme.dart',
        oldText: '''
import 'package:flutter/material.dart';

final appTheme = ThemeData(
  primarySwatch: Colors.blue,
  accentColor: Colors.blueAccent,
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blue,
    textTheme: ButtonTextTheme.primary,
  ),
);
''',
        newText: '''
import 'package:flutter/material.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.blue,
);
''',
      ),
    ];
  }
}
