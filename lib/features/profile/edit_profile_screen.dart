import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/app_user.dart';
import '../../providers/profile_provider.dart';

/// Editable account details backed by [UserRepository] via ProfileProvider.
class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _faculty;
  late final TextEditingController _contact;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _email = TextEditingController(text: widget.user.email);
    _faculty = TextEditingController(text: widget.user.faculty);
    _contact = TextEditingController(text: widget.user.contact);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _faculty.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final profile = context.read<ProfileProvider>();
    final saved = await profile.updateProfile(
      name: _name.text,
      faculty: _faculty.text,
      contact: _contact.text,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(profile.error ?? 'Profile could not be saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.accentSoft,
                  foregroundColor: AppColors.primary,
                  backgroundImage: widget.user.profileImageUrl == null
                      ? null
                      : NetworkImage(widget.user.profileImageUrl!),
                  child: widget.user.profileImageUrl == null
                      ? const Icon(Icons.person, size: 44)
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _name,
                label: 'Full name',
                icon: Icons.person_outline,
                maxLength: 80,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    Validators.required(value, fieldName: 'Name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _faculty,
                label: 'Faculty or school (optional)',
                icon: Icons.school_outlined,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    Validators.maxLength(value, 100, fieldName: 'Faculty'),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _contact,
                label: 'Contact number (optional)',
                hint: 'Only shown when you choose phone contact',
                icon: Icons.phone_outlined,
                maxLength: 24,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    Validators.maxLength(value, 24, fieldName: 'Contact'),
                onFieldSubmitted: (_) => _save(),
              ),
              if (profile.error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  profile.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save profile',
                isLoading: profile.isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
