import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup(AuthController controller) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final success = await controller.signUpWithEmail(
      email: email,
      password: password,
    );
    if (!success) return;
    if (!mounted) return;
    await showInfoDialog(
      context,
      title: 'Verify your email',
      message: 'We sent a verification email to $email.',
    );
    if (!mounted) return;
    context.pop();
  }

  Future<void> _handleGoogleSignup(AuthController controller) async {
    final success = await controller.signInWithGoogle();
    if (!success) return;
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final authState = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const AppText(
            'Create your account',
            style: AppTextStyle.title,
          ),
          SizedBox(height: spacing.xs),
          const AppText(
            'Verify your email to unlock premium features later.',
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
                  TextFormField(
                    controller: _confirmController,
                    decoration:
                        const InputDecoration(labelText: 'Confirm password'),
                    obscureText: true,
                    onChanged: (_) => controller.clearError(),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
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
                    label: 'Create account',
                    isFullWidth: true,
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading
                        ? null
                        : () => _handleSignup(controller),
                  ),
                  SizedBox(height: spacing.md),
                  AppButton(
                    label: 'Continue with Google',
                    variant: AppButtonVariant.secondary,
                    isFullWidth: true,
                    onPressed: authState.isLoading
                        ? null
                        : () => _handleGoogleSignup(controller),
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
                'Already have an account?',
                style: AppTextStyle.caption,
              ),
              TextButton(
                onPressed: authState.isLoading ? null : () => context.pop(),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
