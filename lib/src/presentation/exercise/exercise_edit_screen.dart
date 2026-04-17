import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/providers/data_providers.dart';
import '../shared/exercise_media_widget.dart';

/// Screen to create or edit an Exercise.
class ExerciseEditScreen extends ConsumerStatefulWidget {
  final String? exerciseId;
  const ExerciseEditScreen({super.key, this.exerciseId});

  @override
  ConsumerState<ExerciseEditScreen> createState() => _ExerciseEditScreenState();
}

class _ExerciseEditScreenState extends ConsumerState<ExerciseEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _isNew = true;
  bool _canSave = false;
  Exercise? _currentExercise;
  String? _selectedImagePath;
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();

    // Enable Save button only when the name field is non-empty
    _nameCtrl.addListener(() {
      final hasText = _nameCtrl.text.trim().isNotEmpty;
      if (hasText != _canSave) {
        setState(() => _canSave = hasText);
      }
    });

    // If an ID was passed in, load the existing exercise
    final id = widget.exerciseId;
    if (id != null) {
      _isNew = false;
      ref.read(exerciseRepositoryProvider).findById(id).then((e) {
        if (mounted) {
          setState(() {
            _currentExercise = e;
            _nameCtrl.text = e.name;
            _descCtrl.text = e.description;
          });
          debugPrint(
            '[ExerciseEdit] loaded id=${e.id} '
            'thumbnailPath=${e.thumbnailPath} mediaPath=${e.mediaPath}',
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(exerciseRepositoryProvider);
    final existingPath = _currentExercise?.mediaPath;
    String? imagePath;
    if (_removeImage) {
      imagePath = null;
    } else if (_selectedImagePath != null) {
      imagePath = _selectedImagePath;
    } else {
      imagePath = existingPath;
    }

    if (_removeImage && existingPath != null) {
      await _deleteLocalImage(existingPath);
    } else if (_selectedImagePath != null &&
        existingPath != null &&
        existingPath != _selectedImagePath) {
      await _deleteLocalImage(existingPath);
    }

    final e = Exercise(
      id: widget.exerciseId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      thumbnailPath: imagePath,
      mediaPath: imagePath,
    );
    await repo.save(e);
    debugPrint(
      '[ExerciseEdit] saved id=${e.id} imagePath=$imagePath '
      'existingPath=$existingPath removeImage=$_removeImage',
    );

    try {
      final saved = await repo.findById(e.id);
      debugPrint(
        '[ExerciseEdit] db after save id=${saved.id} '
        'thumbnailPath=${saved.thumbnailPath} mediaPath=${saved.mediaPath}',
      );
    } catch (e) {
      debugPrint('[ExerciseEdit] db read after save failed: $e');
    }

    if (mounted) GoRouter.of(context).pop();
    ref.invalidate(exercisesFutureProvider);
  }

  Future<void> _deleteLocalImage(String path) async {
    if (!_isLocalFilePath(path)) {
      return;
    }
    final file = File(await _normalizeFilePath(path));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }
    final savedPath = await _saveImageToLocal(picked.path);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedImagePath = savedPath;
      _removeImage = false;
    });
  }

  Future<String> _saveImageToLocal(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    const relativeDir = 'exercise_media';
    final mediaDir = Directory(p.join(dir.path, relativeDir));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final fileName = 'exercise_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = p.join(mediaDir.path, fileName);
    final relativePath = p.join(relativeDir, fileName);

    final compressed = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: 80,
      minWidth: 1024,
      minHeight: 1024,
      format: CompressFormat.jpeg,
    );

    if (compressed != null) {
      if (compressed.path != targetPath) {
        await File(compressed.path).copy(targetPath);
      }
      return relativePath;
    }

    await File(sourcePath).copy(targetPath);
    return relativePath;
  }

  void _removeImageSelection() {
    setState(() {
      _selectedImagePath = null;
      _removeImage = true;
    });
  }

  bool _isLocalFilePath(String path) {
    return path.startsWith('/') ||
        path.startsWith('file://') ||
        path.startsWith('exercise_media/');
  }

  Future<String> _normalizeFilePath(String path) async {
    if (path.startsWith('file://')) {
      return Uri.parse(path).toFilePath();
    }
    if (path.startsWith('exercise_media/')) {
      final dir = await getApplicationDocumentsDirectory();
      return p.join(dir.path, path);
    }
    return path;
  }

  Future<void> _delete() async {
    final id = widget.exerciseId!;
    final existingPath = _currentExercise?.mediaPath;
    if (existingPath != null) {
      await _deleteLocalImage(existingPath);
    }
    await ref.read(exerciseRepositoryProvider).delete(id);
    if (mounted) GoRouter.of(context).pop();
    ref.invalidate(exercisesFutureProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Exercise' : 'Edit Exercise'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete exercise',
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise media display (if available)
            if (_selectedImagePath != null ||
                (!_removeImage && _currentExercise?.mediaPath != null))
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ExerciseMediaWidget(
                    assetPath: _selectedImagePath ?? _currentExercise!.mediaPath,
                    isThumbnail: false,
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_selectedImagePath != null ||
                      (!_removeImage && _currentExercise?.mediaPath != null)
                  ? 'Change image'
                  : 'Add image'),
            ),
            if (_selectedImagePath != null ||
                (!_removeImage && _currentExercise?.mediaPath != null))
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextButton(
                  onPressed: _removeImageSelection,
                  child: const Text('Remove image'),
                ),
              )
            else
              const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: _canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  elevation: 2,
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}