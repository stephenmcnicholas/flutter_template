// ignore_for_file: avoid_print
//
// Validates AudioAssemblyService (MP3 byte concat + gap asset) against scripts/sample-clips/.
//
// Run from project root:
//   flutter test test/audio_assembly_validation_test.dart
//
// Requires MP3s under scripts/sample-clips/ (see scripts/sample-clips/README.md).
// Outputs copied to scripts/sample-output/ for listening.

import 'dart:io';

import 'package:fytter/src/services/audio/audio_assembly_service.dart';
import 'package:fytter/src/services/audio/audio_clip_paths.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Resolves modular clips to absolute paths under [sampleClipsBasePath].
class SampleClipPaths extends AudioClipPaths {
  SampleClipPaths({
    required this.sampleClipsBasePath,
    AssetBundle? assetBundle,
  }) : super(assetBundle: assetBundle ?? rootBundle);

  final String sampleClipsBasePath;

  String? resolveModularSync(String category, String clipId) {
    final path = '$sampleClipsBasePath/modular/$category/$clipId.mp3';
    final f = File(path);
    if (f.existsSync()) return f.absolute.path;
    return null;
  }

  @override
  Future<String?> resolveModular(String category, String clipId) async =>
      resolveModularSync(category, clipId);

  @override
  Future<String?> resolveExercise(String exerciseId, String cueType) async =>
      null;

  @override
  Future<String?> resolveSentence(String sentenceId, String variant) async =>
      null;

  @override
  Future<Uint8List?> loadAssetBytes(String path) async {
    if (path.startsWith('assets/')) return super.loadAssetBytes(path);
    try {
      final f = File(path);
      if (f.existsSync()) return f.readAsBytesSync();
    } catch (_) {}
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'audio assembly validation (T4, T5, T9)',
    (tester) async {
    final projectRoot = _findProjectRoot();
    final sampleClipsBase = '${projectRoot.path}/scripts/sample-clips';
    final sampleOutputDir = Directory('${projectRoot.path}/scripts/sample-output');

    expect(
      Directory(sampleClipsBase).existsSync(),
      isTrue,
      reason: 'Create scripts/sample-clips/ with the MP3s listed in README (run from project root).',
    );

    if (!sampleOutputDir.existsSync()) {
      sampleOutputDir.createSync(recursive: true);
    }

    final clipPaths = SampleClipPaths(sampleClipsBasePath: sampleClipsBase);
    final assemblyWorkDir =
        Directory('${projectRoot.path}/build/audio_assembly_validation_tmp');
    assemblyWorkDir.createSync(recursive: true);

    final assembly = AudioAssemblyService(
      clipPaths: clipPaths,
      assemblyWorkDirectory: assemblyWorkDir,
    );

    final gapMs = AudioAssemblyService.silenceMs;
    const silenceInserted =
        'YES — raw MP3 byte concat with bundled silence gap asset between segments.';

    print('');
    print('=== Audio assembly validation ===');
    print('Project root: ${projectRoot.path}');
    print('Sample clips: $sampleClipsBase');
    print('Gap duration (configured): $gapMs ms');
    print('Silence between clips: $silenceInserted');
    print('');

    final t4 = await _runAssembly(
      name: 'T4',
      assembly: assembly,
      clipPaths: clipPaths,
      specs: const [
        _Clip('encouragement', 'encourage_solid_set'),
        _Clip('weight_direction', 'weight_increase'),
        _Clip('connective', 'connective_after_rest'),
        _Clip('set_sequencing', 'its_your_third_set'),
      ],
      outputFile: File('${sampleOutputDir.path}/t4-test.mp3'),
      gapMs: gapMs,
      silenceExplanation: silenceInserted,
    );

    final t5 = await _runAssembly(
      name: 'T5',
      assembly: assembly,
      clipPaths: clipPaths,
      specs: const [
        _Clip('exercise_transitions', 'transition_next_up'),
        _Clip('set_sequencing', 'short_final_set'),
        _Clip('connective', 'connective_lets_go'),
      ],
      outputFile: File('${sampleOutputDir.path}/t5-test.mp3'),
      gapMs: gapMs,
      silenceExplanation: silenceInserted,
    );

    final t9 = await _runAssembly(
      name: 'T9',
      assembly: assembly,
      clipPaths: clipPaths,
      specs: const [
        _Clip('workout_bookends', 'bookend_session_done'),
        _Clip('encouragement', 'encourage_solid_set'),
        _Clip('workout_bookends', 'bookend_see_you'),
      ],
      outputFile: File('${sampleOutputDir.path}/t9-test.mp3'),
      gapMs: gapMs,
      silenceExplanation: silenceInserted,
    );

    expect(t4 && t5 && t9, isTrue, reason: 'All three assemblies must succeed when clips are present.');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 20; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return Directory.current;
}

class _Clip {
  const _Clip(this.category, this.modularId);
  final String category;
  final String modularId;
}

Future<bool> _runAssembly({
  required String name,
  required AudioAssemblyService assembly,
  required SampleClipPaths clipPaths,
  required List<_Clip> specs,
  required File outputFile,
  required int gapMs,
  required String silenceExplanation,
}) async {
  print('--- $name ---');

  final resolved = <String>[];
  final missing = <String>[];
  for (final s in specs) {
    final p = clipPaths.resolveModularSync(s.category, s.modularId);
    if (p != null) {
      resolved.add(p);
    } else {
      missing.add('modular/${s.category}/${s.modularId}.mp3');
    }
  }

  if (missing.isNotEmpty) {
    print('Missing clips:');
    for (final m in missing) {
      print('  - $m');
    }
    print('Result: FAIL\n');
    return false;
  }

  print('Clips combined (in order):');
  for (var i = 0; i < resolved.length; i++) {
    final p = resolved[i];
    final parts = p.split(Platform.pathSeparator);
    final tail = parts.length > 4 ? parts.sublist(parts.length - 4).join('/') : p;
    print('  ${i + 1}. $tail');
  }
  print('Gap duration (ms): $gapMs');
  print('Silence handling: $silenceExplanation');

  final tempPath = await assembly.assembleFromResolvedFilePaths(resolved);

  if (tempPath == null) {
    print('Result: FAIL (assembly returned null)\n');
    return false;
  }

  File(tempPath).copySync(outputFile.path);
  print('Written: ${outputFile.path}');
  print('Result: PASS\n');
  return true;
}
