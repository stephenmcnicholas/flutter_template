import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignIn(AuthController controller) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await controller.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (success && mounted) {
      context.pop();
    }
  }

  Future<void> _handleGoogleSignIn(AuthController controller) async {
    final success = await controller.signInWithGoogle();
    if (success && mounted) {
      context.pop();
    }
  }

  Future<void> _handlePasswordReset(AuthController controller) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      await showInfoDialog(
        context,
        title: 'Enter your email',
        message: 'Add a valid email address to reset your password.',
      );
      return;
    }
    final success = await controller.sendPasswordReset(email: email);
    if (success && mounted) {
      await showInfoDialog(
        context,
        title: 'Check your inbox',
        message: 'Password reset instructions have been sent to $email.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final authState = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const AppText(
            'Welcome back',
            style: AppTextStyle.title,
          ),
          SizedBox(height: spacing.xs),
          const AppText(
            'Sign in to back up workouts and sync across devices.',
            style: AppTextStyle.caption,
          ),
          SizedBox(height: spacing.lg),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => controller.clearError(),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty || !email.contains('@')) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing.md),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onChanged: (_) => controller.clearError(),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () => _handlePasswordReset(controller),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  if (authState.errorMessage != null) ...[
                    SizedBox(height: spacing.sm),
                    AppText(
                      authState.errorMessage!,
                      style: AppTextStyle.caption,
                      color: colors.error,
                    ),
                  ],
                  SizedBox(height: spacing.lg),
                  AppButton(
                    label: 'Sign in',
                    isFullWidth: true,
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading
                        ? null
                        : () => _handleEmailSignIn(controller),
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
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppText(
                'New here?',
                style: AppTextStyle.caption,
              ),
              TextButton(
                onPressed: authState.isLoading
                    ? null
                    : () => context.push('/auth/signup'),
                child: const Text('Create account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
