import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';
import '../../models/analysis_result.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/download_button.dart';
import '../../widgets/file_diff_card.dart';
import '../../widgets/loading_card.dart';
import '../../widgets/pipeline_card.dart';
import '../../widgets/proceed_arrow_button.dart';
import '../../widgets/section_page.dart';
import 'pipeline_provider.dart';
import 'upload_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  bool _pastHero = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    final page = _pageController.page ?? 0;
    final show = page > 0.5;
    if (show != _pastHero) setState(() => _pastHero = show);
  }

  int _pageForStage(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.idle:
      case PipelineStage.uploading:
        return 1;
      case PipelineStage.analyzing:
      case PipelineStage.analysisComplete:
        return 2;
      case PipelineStage.migrating:
      case PipelineStage.reviewing:
        return 3;
      case PipelineStage.downloadReady:
        return 4;
    }
  }

  static const _pageDuration = Duration(milliseconds: 800);
  static const _pageCurve = Curves.easeInOutCubic;

  void _goToStage(PipelineStage stage) {
    final target = _pageForStage(stage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) return;
      _pageController.animateToPage(
        target,
        duration: _pageDuration,
        curve: _pageCurve,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pipeline = ref.watch(pipelineProvider);

    ref.listen(pipelineProvider, (prev, next) {
      if (prev?.stage != next.stage) _goToStage(next.stage);
    });

    return Scaffold(
      appBar: AppBar(
        title: AnimatedOpacity(
          opacity: _pastHero ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: const Text('Migrate X'),
        ),
        centerTitle: true,
        actions: [
          if (pipeline.stage != PipelineStage.idle)
            IconButton(
              onPressed: () {
                ref.read(pipelineProvider.notifier).reset();
                _pageController.animateToPage(
                  1,
                  duration: _pageDuration,
                  curve: _pageCurve,
                );
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Start Over',
            ),
          IconButton(
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            tooltip: ref.watch(themeModeProvider) == ThemeMode.light
                ? 'Dark mode'
                : 'Light mode',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _HeroPage(
            onGetStarted: () => _pageController.animateToPage(
              1,
              duration: _pageDuration,
              curve: _pageCurve,
            ),
          ),
          _UploadPage(pipeline: pipeline),
          _AnalysisPage(pipeline: pipeline),
          _ReviewPage(pipeline: pipeline),
          _DownloadPage(
            pipeline: pipeline,
            onStartOver: () {
              ref.read(pipelineProvider.notifier).reset();
              _pageController.animateToPage(
                1,
                duration: _pageDuration,
                curve: _pageCurve,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UploadPage extends StatelessWidget {
  final PipelineState pipeline;
  const _UploadPage({required this.pipeline});

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      maxWidth: kPipelineCardWidth,
      child: PipelineCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Upload a Flutter Project',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a .zip file of your Flutter/Dart project to analyze '
              'and generate a migration plan.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            const UploadButton(),
            if (pipeline.stage == PipelineStage.uploading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Uploading project...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (pipeline.error != null &&
                pipeline.stage == PipelineStage.idle) ...[
              const SizedBox(height: 16),
              Text(
                pipeline.error!.replaceFirst(RegExp(r'^Exception:\s*'), ''),
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalysisPage extends ConsumerWidget {
  final PipelineState pipeline;
  const _AnalysisPage({required this.pipeline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = pipeline.stage == PipelineStage.analyzing;
    final isDone = pipeline.stage == PipelineStage.analysisComplete;

    if (isLoading) {
      return SectionPage(
        maxWidth: kPipelineCardWidth,
        child: LoadingCard(
          icon: Icons.analytics_outlined,
          title: 'Analyzing Project',
          subtitle: pipeline.statusMessage ?? 'Preparing...',
        ),
      );
    }

    if (pipeline.error != null && pipeline.analysisResults == null) {
      return SectionPage(
        maxWidth: kPipelineCardWidth,
        child: PipelineCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Analysis Failed',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                pipeline.error!.replaceFirst(RegExp(r'^Exception:\s*'), ''),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(pipelineProvider.notifier).reset();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Start Over'),
              ),
            ],
          ),
        ),
      );
    }

    final results = pipeline.analysisResults;
    if (results == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            children: [
              _AnalysisSummaryCard(results: results),
              if (results.isNotEmpty) ...[
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) =>
                        AnalysisCard(result: results[index]),
                  ),
                ),
              ],
              if (isDone) ...[
                const SizedBox(height: 12),
                ProceedArrowButton(
                  onPressed: () =>
                      ref.read(pipelineProvider.notifier).startMigration(),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewPage extends ConsumerWidget {
  final PipelineState pipeline;
  const _ReviewPage({required this.pipeline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pipeline.stage == PipelineStage.migrating) {
      return SectionPage(
        maxWidth: kPipelineCardWidth,
        child: LoadingCard(
          icon: Icons.auto_fix_high,
          title: 'Applying Fixes',
          subtitle: pipeline.statusMessage ?? 'Running migration...',
        ),
      );
    }

    final plan = pipeline.migrationPlan;
    if (plan == null) return const SizedBox.shrink();

    return SectionPage(
      maxWidth: 780,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(plan.summary,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: 16),
          ...plan.fileDiffs.asMap().entries.map((entry) {
            final diff = entry.value;
            final decision = pipeline.fileDecisions[diff.filename];
            return FileDiffCard(
              diff: diff,
              decision: decision,
              index: entry.key,
              onAccept: () => ref
                  .read(pipelineProvider.notifier)
                  .acceptFile(diff.filename),
              onDecline: () => ref
                  .read(pipelineProvider.notifier)
                  .declineFile(diff.filename),
            );
          }),
          const SizedBox(height: 24),
          Center(
            child: ProceedArrowButton(
              onPressed: () =>
                  ref.read(pipelineProvider.notifier).proceedToDownload(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DownloadPage extends StatelessWidget {
  final PipelineState pipeline;
  final VoidCallback onStartOver;
  const _DownloadPage({required this.pipeline, required this.onStartOver});

  @override
  Widget build(BuildContext context) {
    final accepted = pipeline.acceptedFiles;
    final fileCount = pipeline.migrationPlan?.fileDiffs.length ?? 0;
    final canDownload = accepted.isNotEmpty ||
        (fileCount > 0 && pipeline.fileDecisions.isEmpty);

    return SectionPage(
      maxWidth: kPipelineCardWidth,
      child: PipelineCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Migration Complete',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              canDownload
                  ? '${accepted.isNotEmpty ? accepted.length : fileCount} file(s) ready for download.'
                  : 'No files to download.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            if (!canDownload) ...[
              OutlinedButton.icon(
                onPressed: onStartOver,
                icon: const Icon(Icons.refresh),
                label: const Text('Start Over'),
              ),
            ] else
              DownloadButton(
                workspaceId: pipeline.workspaceId!,
                declinedFiles: pipeline.fileDecisions.entries
                    .where((e) => !e.value)
                    .map((e) => e.key)
                    .toList(),
                onStartOver: onStartOver,
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroPage extends StatelessWidget {
  final VoidCallback onGetStarted;
  const _HeroPage({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SectionPage(
      maxWidth: 600,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Migrate X',
            style: text.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Upload your Flutter or Dart project as a zip, get an instant '
            'analysis of deprecated APIs and lint issues, review auto-generated '
            'per-file migration diffs, and download the updated project \u2014 '
            'all in one seamless flow.',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          ProceedArrowButton(onPressed: onGetStarted),
        ],
      ),
    );
  }
}

class _AnalysisSummaryCard extends StatelessWidget {
  final List<AnalysisResult> results;
  const _AnalysisSummaryCard({required this.results});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (results.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, size: 32, color: colors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Analysis Complete', style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'No issues found in your project.',
                      style: text.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final errors =
        results.where((r) => r.severity.toUpperCase() == 'ERROR').length;
    final warnings =
        results.where((r) => r.severity.toUpperCase() == 'WARNING').length;
    final infos = results.length - errors - warnings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.analytics_outlined, size: 32, color: colors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Analysis Complete', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${results.length} issue${results.length == 1 ? '' : 's'} found',
                    style: text.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (errors > 0)
              _IssueBadge(
                  icon: Icons.error, color: Colors.red, count: errors),
            if (warnings > 0) ...[
              const SizedBox(width: 12),
              _IssueBadge(
                  icon: Icons.warning_amber,
                  color: Colors.orange,
                  count: warnings),
            ],
            if (infos > 0) ...[
              const SizedBox(width: 12),
              _IssueBadge(
                  icon: Icons.info_outline,
                  color: Colors.blue,
                  count: infos),
            ],
          ],
        ),
      ),
    );
  }
}

class _IssueBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;

  const _IssueBadge({
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
