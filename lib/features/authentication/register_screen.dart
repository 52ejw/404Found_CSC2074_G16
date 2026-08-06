import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agreed = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      _showMessage('Please accept the community guidelines to continue.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      _showMessage(auth.error ?? 'Registration failed. Try again.');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return AuthScaffold(
      title: 'Get started',
      subtitle: 'Create your CampusFind account',
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _name,
              label: 'Full name',
              hint: 'Enter full name',
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.required(v, fieldName: 'Name'),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _email,
              label: 'Email',
              hint: 'name@imail.sunway.edu.my',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _password,
              label: 'Password',
              hint: 'At least 8 characters',
              icon: Icons.lock_outline,
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.password(v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _confirm,
              label: 'Confirm password',
              icon: Icons.lock_outline,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) => Validators.confirmPassword(v, _password.text),
            ),
            const SizedBox(height: AppSpacing.md),

            // Consent
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall,
                        children: const [
                          TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'community guidelines',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' for posting lost and found items'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            PrimaryButton(
              label: 'Sign up',
              isLoading: auth.isSubmitting,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: theme.textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: auth.isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
