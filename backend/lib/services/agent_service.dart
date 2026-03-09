import 'dart:convert';
import 'dart:io';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/process_run.dart';

class AgentResult {
  final bool success;
  final int analyzeRuns;
  final int errorsRemaining;
  final String log;

  AgentResult({
    required this.success,
    required this.analyzeRuns,
    required this.errorsRemaining,
    required this.log,
  });
}

class AgentService {
  final String apiKey;
  final int maxAnalyzeRuns;

  AgentService({required this.apiKey, this.maxAnalyzeRuns = 5});

  List<ToolDefinition> _buildTools() {
    return [
      ToolDefinition.custom(const Tool(
        name: 'read_file',
        description: 'Read the full contents of a file at the given relative path.',
        inputSchema: InputSchema(
          properties: {
            'path': {
              'type': 'string',
              'description':
                  'Relative path from project root, e.g. lib/main.dart',
            },
          },
          required: ['path'],
        ),
      )),
      ToolDefinition.custom(const Tool(
        name: 'write_file',
        description:
            'Write content to a file at the given relative path. Creates parent directories if needed. '
            'You MUST write the COMPLETE file content, not just a snippet.',
        inputSchema: InputSchema(
          properties: {
            'path': {
              'type': 'string',
              'description': 'Relative path from project root',
            },
            'content': {
              'type': 'string',
              'description': 'The FULL file content to write',
            },
          },
          required: ['path', 'content'],
        ),
      )),
      ToolDefinition.custom(const Tool(
        name: 'list_files',
        description:
            'List all .dart files in the project (relative paths).',
        inputSchema: InputSchema(
          properties: {},
        ),
      )),
      ToolDefinition.custom(const Tool(
        name: 'run_analyze',
        description:
            'Run dart analyze on the project. Returns machine-format output. '
            'Call this ONLY after you have finished writing all fixes for the current round.',
        inputSchema: InputSchema(
          properties: {},
        ),
      )),
    ];
  }

  Future<String> _executeTool(
      String name, Map<String, dynamic> input, String projectDir) async {
    switch (name) {
      case 'read_file':
        final filePath = p.join(projectDir, input['path'] as String);
        final file = File(filePath);
        if (!await file.exists()) {
          return 'Error: File not found: ${input['path']}';
        }
        return await file.readAsString();

      case 'write_file':
        final filePath = p.join(projectDir, input['path'] as String);
        final file = File(filePath);
        await file.parent.create(recursive: true);
        await file.writeAsString(input['content'] as String);
        return 'File written: ${input['path']}';

      case 'list_files':
        final files = <String>[];
        await for (final entity in Directory(projectDir)
            .list(recursive: true, followLinks: false)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            final rel = p.relative(entity.path, from: projectDir);
            if (!rel.startsWith('.dart_tool') && !rel.startsWith('build')) {
              files.add(rel);
            }
          }
        }
        files.sort();
        return files.join('\n');

      case 'run_analyze':
        final result = await runExecutableArguments(
          'dart',
          ['analyze', '--format=machine'],
          workingDirectory: projectDir,
        );
        final stdout = result.stdout.toString().trim();
        final stderr = result.stderr.toString().trim();
        if (result.exitCode == 0 && stdout.isEmpty) {
          return 'No issues found.';
        }
        return stdout.isNotEmpty ? stdout : stderr;

      default:
        return 'Unknown tool: $name';
    }
  }

  String _stripAbsolutePaths(String analyzerOutput, String projectDir) {
    return analyzerOutput.replaceAll(projectDir, '.');
  }

  Future<AgentResult> fixErrors(
    String projectDir,
    String rawAnalyzerOutput, {
    void Function(String)? onProgress,
  }) async {
    final client = AnthropicClient(
      config: AnthropicConfig(
        authProvider: ApiKeyProvider(apiKey),
        timeout: const Duration(minutes: 10),
      ),
    );

    final analyzerOutput = _stripAbsolutePaths(rawAnalyzerOutput, projectDir);
    final tools = _buildTools();
    final logBuffer = StringBuffer();
    void progress(String line) {
      logBuffer.writeln(line);
      onProgress?.call(line);
    }

    final errorsAndWarnings = _filterErrorsAndWarnings(analyzerOutput);

    final messages = <InputMessage>[
      InputMessage.user(
        'This Flutter/Dart project has analyzer errors and warnings after running `dart fix --apply`. '
        'Your job:\n'
        '1. Read ALL files that have errors or warnings (the full file, not just the error lines)\n'
        '2. Fix ALL errors and warnings in each file, then write the corrected file\n'
        '3. After fixing ALL files, run run_analyze once to verify\n'
        '4. If errors/warnings remain, read the new ones, fix them, and run run_analyze again\n\n'
        'IMPORTANT:\n'
        '- Only fix ERROR and WARNING severity issues. Ignore INFO.\n'
        '- Read files first, fix ALL issues, write ALL fixed files, THEN run run_analyze.\n'
        '- Do NOT make cosmetic or style changes beyond what is needed to fix errors/warnings.\n'
        '- Do NOT reformat code, reorder imports, or change anything that is not an error/warning.\n\n'
        'Analyzer output (ERROR and WARNING only):\n```\n$errorsAndWarnings\n```',
      ),
    ];

    var analyzeRuns = 0;
    var errorsRemaining = _countErrors(analyzerOutput);
    var totalInputTokens = 0;
    var totalOutputTokens = 0;
    var turn = 0;

    print('  [agent] starting with $errorsRemaining errors');
    progress('Analyzing $errorsRemaining error(s)...');

    try {
      while (analyzeRuns < maxAnalyzeRuns && errorsRemaining > 0) {
        turn++;
        print(
            '  [agent] --- turn $turn (analyze runs: $analyzeRuns/$maxAnalyzeRuns, errors: $errorsRemaining) ---');
        logBuffer.writeln(
            '--- Turn $turn (analyze $analyzeRuns/$maxAnalyzeRuns, $errorsRemaining errors) ---');

        final response = await client.messages.create(
          MessageCreateRequest(
            model: 'claude-sonnet-4-20250514',
            maxTokens: 16000,
            thinking: ThinkingEnabled(budgetTokens: 10000),
            system: SystemPrompt.text(
              'You are a Flutter/Dart migration specialist. You fix analyzer errors and warnings '
              'in projects being migrated to the latest Flutter/Dart SDK.\n\n'
              'Rules:\n'
              '- Only fix ERROR and WARNING severity issues. Ignore INFO completely.\n'
              '- Read the FULL file before modifying it\n'
              '- Write the COMPLETE corrected file content (not snippets)\n'
              '- Fix ALL errors and warnings in a file at once, not one at a time\n'
              '- After writing ALL fixed files, call run_analyze to check\n'
              '- Do NOT add comments explaining your changes\n'
              '- Do NOT reformat code, reorder imports, or make cosmetic changes\n'
              '- ONLY change the exact lines that cause errors or warnings\n'
              '- Preserve all original formatting, spacing, and style',
            ),
            tools: tools,
            messages: messages,
          ),
        );

        totalInputTokens += response.usage.inputTokens;
        totalOutputTokens += response.usage.outputTokens;
        print(
            '  [agent] tokens: ${response.usage.inputTokens} in / ${response.usage.outputTokens} out '
            '(stop: ${response.stopReason})');

        for (final block in response.content) {
          if (block is ThinkingBlock) {
            final preview = block.thinking.length > 200
                ? '${block.thinking.substring(0, 200)}...'
                : block.thinking;
            print('  [agent] thinking: $preview');
            progress(preview);
          }
          if (block is TextBlock) {
            print('  [agent] text: ${block.text}');
            progress(block.text);
          }
        }

        if (!response.hasToolUse) {
          print('  [agent] no tool calls, stopping');
          logBuffer.writeln('No tool calls, stopping.');
          break;
        }

        final assistantInputBlocks = response.content
            .where((b) => b is TextBlock || b is ToolUseBlock)
            .map(
              (b) => switch (b) {
                TextBlock(:final text) => TextInputBlock(text),
                ToolUseBlock(:final id, :final name, :final input) =>
                  ToolUseInputBlock(id: id, name: name, input: input),
                _ => throw StateError('Unexpected block type'),
              },
            )
            .toList();

        final toolResultBlocks = <ToolResultInputBlock>[];

        for (final block in response.content) {
          if (block is ToolUseBlock) {
            final inputPreview = block.name == 'write_file'
                ? '{"path":"${block.input['path']}", "content":"...(${(block.input['content'] as String?)?.length ?? 0} chars)"}'
                : jsonEncode(block.input);
            print('  [agent] -> ${block.name}($inputPreview)');

            final toolLabel = switch (block.name) {
              'read_file' => 'Reading ${block.input['path']}',
              'write_file' => 'Writing ${block.input['path']}',
              'list_files' => 'Listing project files',
              'run_analyze' => 'Running dart analyze...',
              _ => '${block.name}',
            };
            progress(toolLabel);

            final rawResult = await _executeTool(
              block.name,
              block.input,
              projectDir,
            );

            var result = rawResult;
            if (block.name == 'run_analyze') {
              result = _stripAbsolutePaths(result, projectDir);
              result = _filterErrorsAndWarnings(result);
            }

            final logPreview = result.length > 300
                ? '${result.substring(0, 300)}...(${result.length} chars total)'
                : result;
            print('  [agent] <- ${block.name}: $logPreview');

            toolResultBlocks.add(ToolResultInputBlock(
              toolUseId: block.id,
              content: [ToolResultTextContent(result)],
            ));

            if (block.name == 'run_analyze') {
              analyzeRuns++;
              errorsRemaining = _countErrors(result);
              print(
                  '  [agent] *** analyze #$analyzeRuns: $errorsRemaining errors remaining ***');
              final analyzeMsg = errorsRemaining == 0
                  ? 'All errors fixed!'
                  : '$errorsRemaining error(s) remaining, fixing...';
              progress(analyzeMsg);
            }
          }
        }

        messages.add(InputMessage.assistantBlocks(assistantInputBlocks));
        messages.add(InputMessage(
          role: MessageRole.user,
          content: MessageContent.blocks(toolResultBlocks),
        ));
      }
    } catch (e, st) {
      print('  [agent] ERROR: $e');
      print('  [agent] stack: $st');
      progress('Error occurred during fixing');
    } finally {
      client.close();
    }

    final summary = errorsRemaining == 0
        ? 'SUCCESS: all errors fixed ($analyzeRuns analyze runs, $turn turns)'
        : 'PARTIAL: $errorsRemaining errors remain ($analyzeRuns analyze runs, $turn turns)';
    print('  [agent] $summary');
    print(
        '  [agent] total tokens: $totalInputTokens in / $totalOutputTokens out');
    progress(errorsRemaining == 0
        ? 'All errors fixed successfully'
        : '$errorsRemaining error(s) could not be fixed');

    return AgentResult(
      success: errorsRemaining == 0,
      analyzeRuns: analyzeRuns,
      errorsRemaining: errorsRemaining,
      log: logBuffer.toString(),
    );
  }

  bool _isErrorOrWarning(String line) {
    if (!line.contains('|')) return false;
    final lower = line.toLowerCase();
    return lower.startsWith('error|') ||
        lower.startsWith('warning|') ||
        lower.contains('|error|') ||
        lower.contains('|warning|');
  }

  String _filterErrorsAndWarnings(String analyzerOutput) {
    if (analyzerOutput.contains('No issues found')) return analyzerOutput;
    final filtered =
        analyzerOutput.split('\n').where(_isErrorOrWarning).toList();
    return filtered.isEmpty ? 'No issues found' : filtered.join('\n');
  }

  int _countErrors(String analyzerOutput) {
    if (analyzerOutput.contains('No issues found')) return 0;
    return analyzerOutput.split('\n').where(_isErrorOrWarning).length;
  }
}
