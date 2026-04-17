import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:fytter/src/providers/rest_timer_settings_provider.dart';
import 'package:fytter/src/services/audio/rest_timer_audio_scheduler.dart';
import 'package:fytter/src/services/rest_timer_alert_service.dart';
import 'package:fytter/src/utils/format_utils.dart';

// Sentinel for copyWith nullable overrides
const Object _kUnset = Object();

/// State for the rest timer
class RestTimerState {
  final bool isActive;
  final int remainingSeconds;
  final int defaultDuration;
  final bool isPaused;
  /// When non-null, shown instead of 'Rest Timer' in the overlay.
  final String? customTitle;
  /// When non-null, shown below the title in the overlay.
  final String? customSubtitle;
  /// The exercise ID that was just completed before this rest started.
  /// Used by the rest timer overlay to show coaching cues for the recently finished set.
  final String? completedExerciseId;

  const RestTimerState({
    this.isActive = false,
    this.remainingSeconds = 120, // Default 2:00
    this.defaultDuration = 120,
    this.isPaused = false,
    this.customTitle,
    this.customSubtitle,
    this.completedExerciseId,
  });

  RestTimerState copyWith({
    bool? isActive,
    int? remainingSeconds,
    int? defaultDuration,
    bool? isPaused,
    Object? customTitle = _kUnset,
    Object? customSubtitle = _kUnset,
    Object? completedExerciseId = _kUnset,
  }) {
    return RestTimerState(
      isActive: isActive ?? this.isActive,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      isPaused: isPaused ?? this.isPaused,
      customTitle:
          customTitle == _kUnset ? this.customTitle : customTitle as String?,
      customSubtitle: customSubtitle == _kUnset
          ? this.customSubtitle
          : customSubtitle as String?,
      completedExerciseId: completedExerciseId == _kUnset
          ? this.completedExerciseId
          : completedExerciseId as String?,
    );
  }

  /// Check if timer has completed
  bool get isComplete => remainingSeconds <= 0;

  /// Get formatted time string (mm:ss)
  String get formattedTime => formatDuration(remainingSeconds);
}

/// Notifier for managing rest timer state
class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;
  final RestTimerAlertService _alertService;
  final RestTimerAudioSchedulerBase? _audioScheduler;
  static const int _defaultDuration = 120; // 2:00 in seconds
  static const int _adjustmentIncrement = 15; // 15 seconds
  static const int _minSeconds = 5;
  static const int _maxSeconds = 3600;
  bool _playHaptics = true;
  bool _playSound = true;

  RestTimerNotifier(this._alertService, {RestTimerAudioSchedulerBase? audioScheduler})
      : _audioScheduler = audioScheduler,
        super(const RestTimerState(defaultDuration: _defaultDuration));

  void updateAlertPreferences({
    required bool playHaptics,
    required bool playSound,
  }) {
    _playHaptics = playHaptics;
    _playSound = playSound;
  }

  void updateDefaultDuration(int seconds) {
    final clamped = seconds.clamp(_minSeconds, _maxSeconds);
    if (clamped == state.defaultDuration) return;
    if (state.isActive) {
      state = state.copyWith(defaultDuration: clamped);
    } else {
      state = state.copyWith(defaultDuration: clamped, remainingSeconds: clamped);
    }
  }

  /// Start the rest timer. Optionally pass [audioContext] to schedule Template 5
  /// notification at rest end (premium + guided only). In-app haptics/sound unchanged.
  /// Pass [customTitle]/[customSubtitle] to show superset round context in the overlay.
  void start({
    RestTimerAudioContext? audioContext,
    String? customTitle,
    String? customSubtitle,
    String? completedExerciseId,
  }) {
    if (state.isActive && !state.isPaused) {
      return; // Already running
    }

    // If paused, resume; otherwise start fresh
    final duration = state.isPaused ? state.remainingSeconds : state.defaultDuration;

    _cancelTimer();
    state = RestTimerState(
      isActive: true,
      remainingSeconds: duration,
      defaultDuration: state.defaultDuration,
      isPaused: false,
      customTitle: customTitle,
      customSubtitle: customSubtitle,
      completedExerciseId: completedExerciseId,
    );

    _startCountdown();

    if (audioContext != null && _audioScheduler != null) {
      final restEndTime = DateTime.now().add(Duration(seconds: duration));
      _audioScheduler.scheduleWhenRestStarts(
        context: audioContext,
        restEndTime: restEndTime,
      );
    }
  }

  /// Start the countdown timer
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1) {
        _complete();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  /// Pause the timer
  void pause() {
    if (!state.isActive || state.isPaused) return;
    _cancelTimer();
    state = state.copyWith(isPaused: true);
  }

  /// Resume the timer
  void resume() {
    if (!state.isActive || !state.isPaused) return;
    _startCountdown();
    state = state.copyWith(isPaused: false);
  }

  /// Skip the timer (complete immediately)
  void skip() {
    _complete();
  }

  /// Increase timer duration by 15 seconds
  void increaseDuration() {
    final newDuration = state.remainingSeconds + _adjustmentIncrement;
    state = state.copyWith(remainingSeconds: newDuration);
    
    // If timer is running, restart with new duration
    if (state.isActive && !state.isPaused) {
      _cancelTimer();
      _startCountdown();
    }
  }

  /// Decrease timer duration by 15 seconds (minimum 0)
  void decreaseDuration() {
    final newDuration = (state.remainingSeconds - _adjustmentIncrement).clamp(0, double.infinity).toInt();
    state = state.copyWith(remainingSeconds: newDuration);
    
    // If timer reaches 0, complete it
    if (newDuration == 0 && state.isActive) {
      _complete();
      return;
    }
    
    // If timer is running, restart with new duration
    if (state.isActive && !state.isPaused) {
      _cancelTimer();
      _startCountdown();
    }
  }

  /// Complete the timer
  void _complete() {
    _cancelTimer();
    // Fire haptics + sound when rest timer completes
    // ignore: unawaited_futures
    _alertService.notifyComplete(
      playHaptics: _playHaptics,
      playSound: _playSound,
    );
    state = RestTimerState(
      isActive: false,
      remainingSeconds: state.defaultDuration,
      defaultDuration: state.defaultDuration,
      customTitle: null,
      customSubtitle: null,
      completedExerciseId: null,
    );
  }

  /// Stop and reset the timer
  void stop() {
    _cancelTimer();
    state = RestTimerState(
      isActive: false,
      remainingSeconds: state.defaultDuration,
      defaultDuration: state.defaultDuration,
      customTitle: null,
      customSubtitle: null,
      completedExerciseId: null,
    );
  }

  /// Cancel the timer
  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}

/// Provider for rest timer state
final restTimerAlertServiceProvider = Provider<RestTimerAlertService>((ref) {
  return SystemRestTimerAlertService();
});

final restTimerProvider = StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  final alertService = ref.read(restTimerAlertServiceProvider);
  final audioScheduler = ref.read(restTimerAudioSchedulerProvider);
  final notifier = RestTimerNotifier(alertService, audioScheduler: audioScheduler);
  final settings = ref.read(restTimerSettingsProvider);
  notifier.updateDefaultDuration(settings.defaultSeconds);
  notifier.updateAlertPreferences(
    playHaptics: settings.hapticsEnabled,
    playSound: settings.soundEnabled,
  );
  ref.listen<RestTimerSettingsState>(restTimerSettingsProvider, (previous, next) {
    notifier.updateDefaultDuration(next.defaultSeconds);
    notifier.updateAlertPreferences(
      playHaptics: next.hapticsEnabled,
      playSound: next.soundEnabled,
    );
  });
  return notifier;
});
