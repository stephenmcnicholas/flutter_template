import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/auth_user.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/auth_providers.dart';
import 'package:fytter/src/providers/profile_provider.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  ProfileState? _initialProfile;
  bool _canSave = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _nameCtrl.addListener(_updateCanSave);
    _emailCtrl.addListener(_updateCanSave);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _updateCanSave() {
    final profile = _initialProfile;
    if (profile == null) return;
    final hasChanges = _nameCtrl.text.trim() != profile.displayName ||
        _emailCtrl.text.trim() != profile.email;
    if (hasChanges != _canSave) {
      setState(() {
        _canSave = hasChanges;
      });
    }
  }

  Future<void> _save(ProfileNotifier notifier) async {
    final displayName = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    await notifier.setProfile(displayName: displayName, email: email);
    setState(() {
      _initialProfile = ProfileState(displayName: displayName, email: email, isLoading: false);
      _canSave = false;
    });
  }

  Future<void> _handleGoogleSignIn(AuthController controller) async {
    await controller.signInWithGoogle();
  }

  Widget _buildAccountSection({
    required BuildContext context,
    required AuthUser? user,
    required AuthStatus status,
    required AuthController controller,
    required AuthControllerState authState,
  }) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Account',
          style: AppTextStyle.title,
        ),
        SizedBox(height: spacing.md),
        if (status == AuthStatus.signedInUnverified)
          Container(
            padding: EdgeInsets.all(spacing.md),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.themeExt<AppRadii>().md),
              border: Border.all(
                color: colors.warning.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Verify your email',
                  style: AppTextStyle.body,
                ),
                SizedBox(height: spacing.xs),
                const AppText(
                  'Check your inbox to verify this account. Verification will be required for premium features.',
                  style: AppTextStyle.caption,
                ),
                SizedBox(height: spacing.md),
                Wrap(
                  spacing: spacing.sm,
                  runSpacing: spacing.sm,
                  children: [
                    AppButton(
                      label: 'Resend email',
                      variant: AppButtonVariant.secondary,
                      onPressed: authState.isLoading
                          ? null
                          : () => controller.resendEmailVerification(),
                    ),
                    AppButton(
                      label: 'Refresh status',
                      variant: AppButtonVariant.secondary,
                      onPressed: authState.isLoading
                          ? null
                          : () => controller.refreshUser(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        SizedBox(height: spacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user == null) ...[
                const AppText(
                  'Sign in to back up workouts and sync across devices.',
                  style: AppTextStyle.body,
                ),
                SizedBox(height: spacing.md),
                AppButton(
                  label: 'Sign in',
                  isFullWidth: true,
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading
                      ? null
                      : () => context.push('/auth/login'),
                ),
                SizedBox(height: spacing.md),
                AppButton(
                  label: 'Create account',
                  variant: AppButtonVariant.secondary,
                  isFullWidth: true,
                  onPressed: authState.isLoading
                      ? null
                      : () => context.push('/auth/signup'),
                ),
                SizedBox(height: spacing.md),
                AppButton(
                  label: 'Continue with Google',
                  variant: AppButtonVariant.secondary,
                  isFullWidth: true,
                  onPressed: authState.isLoading
                      ? null
                      : () => _handleGoogleSignIn(controller),
                ),
              ] else ...[
                AppText(
                  user.email ?? 'Signed in',
                  style: AppTextStyle.body,
                ),
                SizedBox(height: spacing.xs),
                AppText(
                  user.displayName ?? 'Account connected',
                  style: AppTextStyle.caption,
                ),
                SizedBox(height: spacing.md),
                AppButton(
                  label: 'Sign out',
                  variant: AppButtonVariant.secondary,
                  isFullWidth: true,
                  onPressed: authState.isLoading ? null : () => controller.signOut(),
                ),
              ],
              if (authState.errorMessage != null) ...[
                SizedBox(height: spacing.sm),
                AppText(
                  authState.errorMessage!,
                  style: AppTextStyle.caption,
                  color: colors.error,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final authUser = ref.watch(authUserProvider).maybeWhen(
          data: (user) => user,
          orElse: () => null,
        );
    final authStatus = ref.watch(authStatusProvider);
    final authController = ref.read(authControllerProvider.notifier);
    final authState = ref.watch(authControllerProvider);

    if (!_initialized && !profile.isLoading) {
      _initialized = true;
      _initialProfile = profile;
      _nameCtrl.text = profile.displayName;
      _emailCtrl.text = profile.email;
      _canSave = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: _canSave ? () => _save(notifier) : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: profile.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(spacing.lg),
              children: [
                _buildAccountSection(
                  context: context,
                  user: authUser,
                  status: authStatus,
                  controller: authController,
                  authState: authState,
                ),
                SizedBox(height: spacing.xl),
                const AppText(
                  'Local profile (device only)',
                  style: AppTextStyle.title,
                ),
                SizedBox(height: spacing.md),
                AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Display name'),
                          textInputAction: TextInputAction.next,
                        ),
                        SizedBox(height: spacing.md),
                        TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacing.md),
                const AppText(
                  'Local profile details stay on this device.',
                  style: AppTextStyle.caption,
                ),
              ],
            ),
    );
  }
}
