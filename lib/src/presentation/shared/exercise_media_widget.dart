import 'dart:io' show File, Platform;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../theme.dart';

/// Widget for displaying exercise media (thumbnail, image, or video).
/// 
/// For thumbnails: displays a small cached image.
/// For full media: displays image or looping video player.
class ExerciseMediaWidget extends StatefulWidget {
  /// Asset path (e.g., "exercises/thumbnails/squat.jpg" or "exercises/media/squat.mp4").
  final String? assetPath;
  
  /// Whether this is a thumbnail (small) or full media (large).
  final bool isThumbnail;
  
  /// Width for thumbnail display.
  final double? thumbnailWidth;
  
  /// Height for thumbnail display.
  final double? thumbnailHeight;

  const ExerciseMediaWidget({
    super.key,
    this.assetPath,
    this.isThumbnail = false,
    this.thumbnailWidth = 64,
    this.thumbnailHeight = 64,
  });

  @override
  State<ExerciseMediaWidget> createState() => _ExerciseMediaWidgetState();
}

class _ExerciseMediaWidgetState extends State<ExerciseMediaWidget>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String? _resolvedLocalPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolveLocalPath();
    if (widget.assetPath != null &&
        !widget.isThumbnail &&
        widget.assetPath!.endsWith('.mp4') &&
        !_isTestEnvironment()) {
      _initializeVideo();
    }
  }

  /// Check if running in a test environment.
  /// In tests, video player platform is not available, so we skip initialization.
  bool _isTestEnvironment() {
    // Check for test environment - Flutter sets this environment variable during tests
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return true;
      }
    } catch (e) {
      // Platform.environment may not be available on all platforms (e.g., web)
      // Fall through to binding check
    }
    
    // Also check if we're in a test binding (more reliable for widget tests)
    try {
      final binding = WidgetsBinding.instance;
      final bindingType = binding.runtimeType.toString();
      return bindingType.contains('Test') || bindingType.contains('Automated');
    } catch (e) {
      // If binding check fails, assume not in test
    }
    
    return false;
  }

  Future<void> _initializeVideo() async {
    try {
      final rawPath = widget.assetPath!;
      if (_isRelativeLocalPath(rawPath) && _resolvedLocalPath == null) {
        return;
      }
      final controller = _isLocalFilePath(rawPath)
          ? VideoPlayerController.file(
              File(_resolvedLocalPath ?? _normalizeFilePath(rawPath)),
            )
          : VideoPlayerController.asset(_normalizeAssetPath(rawPath));
      await controller.initialize();
      controller.setLooping(true);
      controller.play();
      
      if (mounted) {
        setState(() {
          _videoController = controller;
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      // If video fails to load, will fall back to placeholder
      // debugPrint('Failed to load video asset: ${widget.assetPath}');
      // debugPrint('Error: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _disposeVideo();
    } else if (state == AppLifecycleState.resumed &&
        widget.assetPath != null &&
        !widget.isThumbnail &&
        widget.assetPath!.endsWith('.mp4') &&
        !_isVideoInitialized &&
        !_isTestEnvironment()) {
      _initializeVideo();
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    if (mounted) {
      setState(() => _isVideoInitialized = false);
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _resolvedLocalPath = null;
      _resolveLocalPath();
      if (widget.assetPath != null &&
          !widget.isThumbnail &&
          widget.assetPath!.endsWith('.mp4') &&
          !_isTestEnvironment()) {
        _initializeVideo();
      }
    }
  }

  Future<void> _resolveLocalPath() async {
    final path = widget.assetPath;
    if (path == null || path.isEmpty) {
      return;
    }
    if (_isAbsoluteLocalPath(path)) {
      if (mounted) {
        setState(() => _resolvedLocalPath = _normalizeFilePath(path));
      }
      return;
    }
    if (_isRelativeLocalPath(path)) {
      final dir = await getApplicationDocumentsDirectory();
      final resolved = p.join(dir.path, path);
      if (mounted) {
        setState(() => _resolvedLocalPath = resolved);
        if (!widget.isThumbnail &&
            widget.assetPath != null &&
            widget.assetPath!.endsWith('.mp4') &&
            !_isTestEnvironment()) {
          _initializeVideo();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assetPath == null || widget.assetPath!.isEmpty) {
      // debugPrint('ExerciseMediaWidget: assetPath is null or empty, showing placeholder');
      return _buildPlaceholder();
    }

    // Debug: log the asset path being used
    // debugPrint('ExerciseMediaWidget: loading asset: ${widget.assetPath}, isThumbnail: ${widget.isThumbnail}');

    // Thumbnail display
    if (widget.isThumbnail) {
      if (widget.assetPath!.endsWith('.mp4')) {
        // For video thumbnails, show first frame or placeholder
        // In a real implementation, you'd extract a frame, but for now use placeholder
        return _buildPlaceholder();
      }
      return _buildImage(widget.assetPath!);
    }

    // Full media display
    if (widget.assetPath!.endsWith('.mp4')) {
      if (_isVideoInitialized && _videoController != null) {
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        );
      }
      // Show placeholder while video is loading or if it failed
      return _buildPlaceholder();
    }

    // Image display
    return _buildImage(widget.assetPath!);
  }

  Widget _buildImage(String path) {
    final resolvedPath = _resolvedLocalPath ?? _normalizeFilePath(path);
    final imageWidget = _isLocalFilePath(path)
        ? Image.file(
            File(resolvedPath),
            width: widget.isThumbnail ? widget.thumbnailWidth : null,
            height: widget.isThumbnail ? widget.thumbnailHeight : null,
            fit: widget.isThumbnail ? BoxFit.cover : BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          )
        : Image.asset(
            _normalizeAssetPath(path),
            width: widget.isThumbnail ? widget.thumbnailWidth : null,
            height: widget.isThumbnail ? widget.thumbnailHeight : null,
            fit: widget.isThumbnail ? BoxFit.cover : BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          );
    
    // For thumbnails, wrap in a constrained box to ensure proper sizing in ListTile.leading
    if (widget.isThumbnail) {
      return SizedBox(
        width: widget.thumbnailWidth ?? 64,
        height: widget.thumbnailHeight ?? 64,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: imageWidget,
        ),
      );
    }
    
    return imageWidget;
  }

  Widget _buildPlaceholder() {
    final colors = context.themeExt<AppColors>();
    final radii = context.themeExt<AppRadii>();
    final size = widget.isThumbnail 
        ? Size(widget.thumbnailWidth ?? 64, widget.thumbnailHeight ?? 64)
        : const Size(200, 200);

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.sm),
      ),
      child: Icon(
        Icons.fitness_center,
        color: colors.outline,
        size: widget.isThumbnail ? 24 : 48,
      ),
    );
  }

  bool _isLocalFilePath(String path) {
    return _isAbsoluteLocalPath(path) || _isRelativeLocalPath(path);
  }

  String _normalizeFilePath(String path) {
    return path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;
  }

  bool _isAbsoluteLocalPath(String path) {
    return path.startsWith('/') || path.startsWith('file://');
  }

  bool _isRelativeLocalPath(String path) {
    return path.startsWith('exercise_media/');
  }

  String _normalizeAssetPath(String path) {
    return path.startsWith('assets/') ? path : 'assets/$path';
  }
}

