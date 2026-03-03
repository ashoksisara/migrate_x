import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analysis_result.dart';
import '../../models/migration_plan.dart';
import '../../providers/api_provider.dart';

enum PipelineStage {
  idle,
  uploading,
  analyzing,
  migrating,
  reviewing,
  downloadReady,
}

class PipelineState {
  final PipelineStage stage;
  final String? workspaceId;
  final List<AnalysisResult>? analysisResults;
  final MigrationPlan? migrationPlan;
  final Map<String, bool> fileDecisions;
  final String? error;

  const PipelineState({
    this.stage = PipelineStage.idle,
    this.workspaceId,
    this.analysisResults,
    this.migrationPlan,
    this.fileDecisions = const {},
    this.error,
  });

  PipelineState copyWith({
    PipelineStage? stage,
    String? workspaceId,
    List<AnalysisResult>? analysisResults,
    MigrationPlan? migrationPlan,
    Map<String, bool>? fileDecisions,
    String? error,
  }) {
    return PipelineState(
      stage: stage ?? this.stage,
      workspaceId: workspaceId ?? this.workspaceId,
      analysisResults: analysisResults ?? this.analysisResults,
      migrationPlan: migrationPlan ?? this.migrationPlan,
      fileDecisions: fileDecisions ?? this.fileDecisions,
      error: error,
    );
  }

  bool get allFilesReviewed {
    if (migrationPlan == null) return false;
    return migrationPlan!.fileDiffs.every(
      (d) => fileDecisions.containsKey(d.filename),
    );
  }

  List<String> get acceptedFiles => fileDecisions.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toList();
}

class PipelineNotifier extends Notifier<PipelineState> {
  @override
  PipelineState build() => const PipelineState();

  Future<void> upload(Uint8List bytes, String filename) async {
    state = const PipelineState(stage: PipelineStage.uploading);

    try {
      final api = ref.read(apiProvider);
      final id = await api.uploadZip(bytes, filename);
      state = state.copyWith(
        stage: PipelineStage.analyzing,
        workspaceId: id,
      );
      await _runAnalysis(id);
    } catch (e) {
      state = state.copyWith(
        stage: PipelineStage.idle,
        error: e.toString(),
      );
    }
  }

  Future<void> _runAnalysis(String id) async {
    try {
      final api = ref.read(apiProvider);
      final results = await api.getAnalysis(id);
      state = state.copyWith(
        stage: PipelineStage.migrating,
        analysisResults: results,
      );
      await _runMigration(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _runMigration(String id) async {
    try {
      final api = ref.read(apiProvider);
      final plan = await api.getMigrationPlan(id);
      state = state.copyWith(
        stage: PipelineStage.reviewing,
        migrationPlan: plan,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void acceptFile(String filename) {
    final updated = Map<String, bool>.from(state.fileDecisions);
    updated[filename] = true;
    state = state.copyWith(fileDecisions: updated);
    _checkAllReviewed();
  }

  void declineFile(String filename) {
    final updated = Map<String, bool>.from(state.fileDecisions);
    updated[filename] = false;
    state = state.copyWith(fileDecisions: updated);
    _checkAllReviewed();
  }

  void _checkAllReviewed() {
    if (state.allFilesReviewed) {
      state = state.copyWith(stage: PipelineStage.downloadReady);
    }
  }

  void reset() {
    state = const PipelineState();
  }
}

final pipelineProvider =
    NotifierProvider<PipelineNotifier, PipelineState>(PipelineNotifier.new);
