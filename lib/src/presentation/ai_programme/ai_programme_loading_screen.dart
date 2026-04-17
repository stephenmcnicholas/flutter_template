import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/presentation/ai_programme/ai_programme_strings.dart';

/// Full-screen loading with cycling coaching messages. Watches generation state
/// and navigates to preview on success or back on error.
class AiProgrammeLoadingScreen extends ConsumerStatefulWidget {
  const AiProgrammeLoadingScreen({super.key});

  @override
  ConsumerState<AiProgrammeLoadingScreen> createState() => _AiProgrammeLoadingScreenState();
}

class _AiProgrammeLoadingScreenState extends ConsumerState<AiProgrammeLoadingScreen> {
  static const List<String> _messages = [
    AiProgrammeStrings.loadingMessage1,
    AiProgrammeStrings.loadingMessage2,
    AiProgrammeStrings.loadingMessage3,
    AiProgrammeStrings.loadingMessage4,
    AiProgrammeStrings.loadingMessage5,
  ];

  int _messageIndex = 0;
  Timer? _timer;
  bool _handledTerminalState = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showLimitDialog(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Monthly limit reached'),
        content: const Text(
          "You've used your 4 AI programme generations for this month. "
          'Your limit resets on the 1st of next month.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProgrammeGenerationState>(programmeGenerationProvider, (prev, next) {
      if (next is ProgrammeGenerationSuccess) {
        if (mounted) {
          ref.read(pendingProgrammeSummaryProvider.notifier).state = null;
          context.go('/ai-programme/preview');
        }
      } else if (next is ProgrammeGenerationLimitReached) {
        if (mounted) {
          ref.read(pendingProgrammeSummaryProvider.notifier).state = null;
          _showLimitDialog(context);
        }
      } else if (next is ProgrammeGenerationError) {
        if (mounted) {
          ref.read(pendingProgrammeSummaryProvider.notifier).state = null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message)),
          );
          context.pop();
        }
      }
    });

    // If we mounted and state is already terminal (e.g. very fast fallback), navigate once.
    final state = ref.watch(programmeGenerationProvider);
    if (!_handledTerminalState &&
        (state is ProgrammeGenerationSuccess ||
            state is ProgrammeGenerationError ||
            state is ProgrammeGenerationLimitReached)) {
      _handledTerminalState = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(pendingProgrammeSummaryProvider.notifier).state = null;
        final current = ref.read(programmeGenerationProvider);
        if (current is ProgrammeGenerationSuccess) {
          context.go('/ai-programme/preview');
        } else if (current is ProgrammeGenerationLimitReached) {
          _showLimitDialog(context);
        } else if (current is ProgrammeGenerationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(current.message)),
          );
          context.pop();
        }
      });
    }

    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final summary = ref.watch(pendingProgrammeSummaryProvider);
    final firstMessage = summary != null
        ? 'Building your ${summary.days}-day programme…'
        : _messages[0];
    final displayMessages = summary != null
        ? [firstMessage, ..._messages.skip(1)]
        : _messages;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: spacing.lg),
                  SizedBox(
                    width: 280,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: AppText(
                        key: ValueKey(_messageIndex),
                        displayMessages[_messageIndex],
                        style: AppTextStyle.title,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                backgroundColor: colors.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
