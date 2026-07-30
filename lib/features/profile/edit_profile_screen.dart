import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

/// Editable Firestore-backed profile fields.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _facultyController;
  late final TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name);
    _facultyController = TextEditingController(text: user?.faculty);
    _contactController = TextEditingController(text: user?.contact);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _facultyController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TextFormField(
                key: const Key('profile-name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    Validators.required(value, fieldName: 'Display name'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _facultyController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Faculty or department',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Contact number (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  helperText:
                      'Only share this when you choose phone as a contact method.',
                ),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    auth.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                key: const Key('save-profile-button'),
                onPressed: auth.isSubmitting ? null : _save,
                icon: auth.isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(auth.isSubmitting ? 'Saving…' : 'Save profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final saved = await context.read<AuthProvider>().updateProfile(
      name: _nameController.text,
      faculty: _facultyController.text,
      contact: _contactController.text,
    );
    if (!mounted || !saved) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
  }
}
