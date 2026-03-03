import 'dart:typed_data';

import '../models/analysis_result.dart';
import '../models/dry_run_result.dart';
import '../models/migration_plan.dart';
import 'api_service.dart';

class MockApiService extends ApiService {
  MockApiService() : super(baseUrl: 'http://mock');

  @override
  Future<String> uploadZip(Uint8List bytes, String filename) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return 'mock-workspace-abc123';
  }

  @override
  Future<void> resolveDependencies(String id) async {
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  @override
  Future<List<AnalysisResult>> getAnalysis(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    return [
      AnalysisResult(
        severity: 'WARNING',
        file: 'lib/main.dart',
        line: 7,
        column: 3,
        message:
            "Use of deprecated member 'primarySwatch'. Use colorSchemeSeed instead.",
      ),
      AnalysisResult(
        severity: 'INFO',
        file: 'lib/main.dart',
        line: 12,
        column: 25,
        message: "Prefer const with constant constructors.",
      ),
      AnalysisResult(
        severity: 'WARNING',
        file: 'lib/widgets/counter.dart',
        line: 3,
        column: 1,
        message:
            "Use of deprecated member 'RaisedButton'. Use ElevatedButton instead.",
      ),
      AnalysisResult(
        severity: 'ERROR',
        file: 'lib/theme.dart',
        line: 5,
        column: 3,
        message:
            "Use of deprecated member 'accentColor'. Use colorScheme instead.",
      ),
      AnalysisResult(
        severity: 'INFO',
        file: 'lib/widgets/counter.dart',
        line: 4,
        column: 3,
        message:
            "The member '_CounterWidgetState' is private. Use 'State<CounterWidget>' as return type.",
      ),
    ];
  }

  @override
  Future<DryRunResult> getMigrationDryRun(String id) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return DryRunResult(
      totalFixes: 6,
      totalFiles: 3,
      suggestions: [
        FixSuggestion(
            file: 'lib/main.dart',
            fixName: 'prefer_const_constructors',
            count: 3),
        FixSuggestion(
            file: 'lib/main.dart', fixName: 'use_super_parameters', count: 1),
        FixSuggestion(
            file: 'lib/widgets/counter.dart',
            fixName: 'use_super_parameters',
            count: 1),
        FixSuggestion(
            file: 'lib/theme.dart',
            fixName: 'prefer_const_declarations',
            count: 1),
      ],
    );
  }

  @override
  Future<MigrationPlan> applyMigration(String id) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return MigrationPlan(
      summary: 'Migration plan for workspace $id:\n'
          '1. Add const constructors where possible\n'
          '2. Migrate to Material 3 theming (useMaterial3: true)\n'
          '3. Replace primarySwatch with colorSchemeSeed\n'
          '4. Replace deprecated widgets (RaisedButton -> ElevatedButton)\n'
          '5. Add super.key to widget constructors\n'
          '6. Add const to immutable widget instantiations',
      fileDiffs: [
        FileDiff(
          filename: 'lib/main.dart',
          oldText: "import 'package:flutter/material.dart';\n"
              "\n"
              "void main() {\n"
              "  runApp(MyApp());\n"
              "}\n"
              "\n"
              "class MyApp extends StatelessWidget {\n"
              "  @override\n"
              "  Widget build(BuildContext context) {\n"
              "    return MaterialApp(\n"
              "      theme: ThemeData(primarySwatch: Colors.blue),\n"
              "      home: Scaffold(\n"
              "        appBar: AppBar(title: Text('Old App')),\n"
              "        body: Center(child: Text('Hello World')),\n"
              "      ),\n"
              "    );\n"
              "  }\n"
              "}\n",
          newText: "import 'package:flutter/material.dart';\n"
              "\n"
              "void main() {\n"
              "  runApp(const MyApp());\n"
              "}\n"
              "\n"
              "class MyApp extends StatelessWidget {\n"
              "  const MyApp({super.key});\n"
              "\n"
              "  @override\n"
              "  Widget build(BuildContext context) {\n"
              "    return MaterialApp(\n"
              "      theme: ThemeData(\n"
              "        useMaterial3: true,\n"
              "        colorSchemeSeed: Colors.blue,\n"
              "      ),\n"
              "      home: Scaffold(\n"
              "        appBar: AppBar(title: const Text('Migrated App')),\n"
              "        body: const Center(child: Text('Hello World')),\n"
              "      ),\n"
              "    );\n"
              "  }\n"
              "}\n",
        ),
        FileDiff(
          filename: 'lib/widgets/counter.dart',
          oldText: "import 'package:flutter/material.dart';\n"
              "\n"
              "class CounterWidget extends StatefulWidget {\n"
              "  @override\n"
              "  _CounterWidgetState createState() => _CounterWidgetState();\n"
              "}\n"
              "\n"
              "class _CounterWidgetState extends State<CounterWidget> {\n"
              "  int _count = 0;\n"
              "\n"
              "  @override\n"
              "  Widget build(BuildContext context) {\n"
              "    return Column(\n"
              "      children: [\n"
              "        Text('Count: \$_count'),\n"
              "        RaisedButton(\n"
              "          onPressed: () => setState(() => _count++),\n"
              "          child: Text('Increment'),\n"
              "        ),\n"
              "      ],\n"
              "    );\n"
              "  }\n"
              "}\n",
          newText: "import 'package:flutter/material.dart';\n"
              "\n"
              "class CounterWidget extends StatefulWidget {\n"
              "  const CounterWidget({super.key});\n"
              "\n"
              "  @override\n"
              "  State<CounterWidget> createState() => _CounterWidgetState();\n"
              "}\n"
              "\n"
              "class _CounterWidgetState extends State<CounterWidget> {\n"
              "  int _count = 0;\n"
              "\n"
              "  @override\n"
              "  Widget build(BuildContext context) {\n"
              "    return Column(\n"
              "      children: [\n"
              "        Text('Count: \$_count'),\n"
              "        ElevatedButton(\n"
              "          onPressed: () => setState(() => _count++),\n"
              "          child: const Text('Increment'),\n"
              "        ),\n"
              "      ],\n"
              "    );\n"
              "  }\n"
              "}\n",
        ),
        FileDiff(
          filename: 'lib/theme.dart',
          oldText: "import 'package:flutter/material.dart';\n"
              "\n"
              "final appTheme = ThemeData(\n"
              "  primarySwatch: Colors.blue,\n"
              "  accentColor: Colors.blueAccent,\n"
              "  buttonTheme: ButtonThemeData(\n"
              "    buttonColor: Colors.blue,\n"
              "    textTheme: ButtonTextTheme.primary,\n"
              "  ),\n"
              ");\n",
          newText: "import 'package:flutter/material.dart';\n"
              "\n"
              "final appTheme = ThemeData(\n"
              "  useMaterial3: true,\n"
              "  colorSchemeSeed: Colors.blue,\n"
              ");\n",
        ),
      ],
    );
  }

  @override
  Future<Uint8List> downloadZip(String id) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return Uint8List.fromList(List.filled(1024, 0));
  }
}
