import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/enums.dart';
import '../../models/item_post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_editor_provider.dart';
import '../../providers/profile_provider.dart';

/// Shared create/edit post form (FR03, FR04 and FR08).
class PostFormScreen extends StatefulWidget {
  final ItemPost? existingPost;
  final VoidCallback? onSaved;

  const PostFormScreen({super.key, this.existingPost, this.onSaved});

  bool get isEditing => existingPost != null;

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemName = TextEditingController();
  final _description = TextEditingController();
  final _date = TextEditingController();
  final _picker = ImagePicker();

  late PostType _postType;
  late DateTime _eventDate;
  late ContactPreference _contactPreference;
  String? _category;
  String? _location;
  XFile? _pickedImage;
  bool _removeExistingImage = false;

  @override
  void initState() {
    super.initState();
    final post = widget.existingPost;
    _postType = post?.postType ?? PostType.lost;
    _eventDate = post?.eventDate ?? DateTime.now();
    _contactPreference = post?.contactPreference ?? ContactPreference.inAppChat;
    _category = post?.category;
    _location = post?.location;
    _itemName.text = post?.itemName ?? '';
    _description.text = post?.description ?? '';
    _updateDateText();
  }

  @override
  void dispose() {
    _itemName.dispose();
    _description.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;
    setState(() {
      _pickedImage = image;
      _removeExistingImage = false;
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: _postType == PostType.lost
          ? 'When was it lost?'
          : 'When was it found?',
    );
    if (date != null && mounted) {
      setState(() {
        _eventDate = date;
        _updateDateText();
      });
    }
  }

  void _updateDateText() {
    _date.text = '${_eventDate.day}/${_eventDate.month}/${_eventDate.year}';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      _showMessage('Please sign in before publishing a post.');
      return;
    }
    final ownerName =
        context.read<ProfileProvider>().user?.name.trim().isNotEmpty == true
        ? context.read<ProfileProvider>().user!.name
        : widget.existingPost?.ownerName ?? 'Student';

    final editor = context.read<PostEditorProvider>();
    final saved = await editor.save(
      existing: widget.existingPost,
      ownerId: userId,
      ownerName: ownerName,
      postType: _postType,
      itemName: _itemName.text,
      category: _category!,
      description: _description.text,
      location: _location!,
      eventDate: _eventDate,
      contactPreference: _contactPreference,
      selectedImage: _pickedImage == null ? null : File(_pickedImage!.path),
      removeExistingImage: _removeExistingImage,
    );
    if (!mounted) return;
    if (saved == null) {
      _showMessage(editor.error ?? 'The post could not be saved.');
      return;
    }

    _showMessage(widget.isEditing ? 'Post updated.' : 'Post published.');
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<PostEditorProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit post' : 'Create post'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              104,
            ),
            children: [
              Text(
                widget.isEditing
                    ? 'Keep the details accurate so others can identify the item.'
                    : 'Tell the campus what went missing or what you found.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                label: 'Post type',
                child: SegmentedButton<PostType>(
                  segments: const [
                    ButtonSegment(
                      value: PostType.lost,
                      icon: Icon(Icons.search),
                      label: Text('Lost'),
                    ),
                    ButtonSegment(
                      value: PostType.found,
                      icon: Icon(Icons.volunteer_activism_outlined),
                      label: Text('Found'),
                    ),
                  ],
                  selected: {_postType},
                  onSelectionChanged: editor.isSubmitting
                      ? null
                      : (selection) =>
                            setState(() => _postType = selection.first),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ImagePickerCard(
                pickedImage: _pickedImage,
                existingImageUrl: _removeExistingImage
                    ? null
                    : widget.existingPost?.imageUrls.firstOrNull,
                onPick: editor.isSubmitting ? null : _pickImage,
                onRemove:
                    (_pickedImage == null &&
                        widget.existingPost?.imageUrls.isEmpty != false)
                    ? null
                    : () => setState(() {
                        _pickedImage = null;
                        _removeExistingImage = true;
                      }),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _itemName,
                label: 'Item name',
                hint: 'e.g. Blue water bottle',
                icon: Icons.inventory_2_outlined,
                maxLength: 80,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    Validators.required(value, fieldName: 'Item name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final category in AppConstants.categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: editor.isSubmitting
                    ? null
                    : (value) => setState(() => _category = value),
                validator: (value) =>
                    value == null ? 'Category is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _description,
                label: 'Description',
                hint: 'Colour, brand and a detail that helps identify the item',
                icon: Icons.notes,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                keyboardType: TextInputType.multiline,
                validator: (value) =>
                    Validators.minLength(value, 10, fieldName: 'Description'),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _location,
                decoration: const InputDecoration(
                  labelText: 'Campus location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: [
                  for (final location in AppConstants.locations)
                    DropdownMenuItem(value: location, child: Text(location)),
                ],
                onChanged: editor.isSubmitting
                    ? null
                    : (value) => setState(() => _location = value),
                validator: (value) =>
                    value == null ? 'Location is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: _postType == PostType.lost ? 'Date lost' : 'Date found',
                controller: _date,
                icon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: editor.isSubmitting ? null : _pickDate,
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Preferred contact',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              RadioGroup<ContactPreference>(
                groupValue: _contactPreference,
                onChanged: editor.isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _contactPreference = value);
                        }
                      },
                child: const Column(
                  children: [
                    RadioListTile(
                      value: ContactPreference.inAppChat,
                      title: Text('In-app chat'),
                      subtitle: Text('Recommended for privacy'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile(
                      value: ContactPreference.email,
                      title: Text('Email'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile(
                      value: ContactPreference.phone,
                      title: Text('Phone'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              if (editor.error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    editor.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: widget.isEditing ? 'Save changes' : 'Publish post',
                isLoading: editor.isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final XFile? pickedImage;
  final String? existingImageUrl;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  const _ImagePickerCard({
    required this.pickedImage,
    required this.existingImageUrl,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = pickedImage != null || existingImageUrl != null;
    return Semantics(
      button: true,
      label: hasImage ? 'Change item photo' : 'Add item photo',
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.placeholder.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.placeholder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (pickedImage != null)
                Image.file(File(pickedImage!.path), fit: BoxFit.cover)
              else if (existingImageUrl != null)
                Image.network(
                  existingImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _ImagePrompt(),
                )
              else
                const _ImagePrompt(),
              if (hasImage && onRemove != null)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: IconButton.filledTonal(
                    tooltip: 'Remove photo',
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePrompt extends StatelessWidget {
  const _ImagePrompt();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 40),
        SizedBox(height: AppSpacing.sm),
        Text('Add a clear photo (optional)'),
        SizedBox(height: AppSpacing.xs),
        Text('Tap to choose from your gallery'),
      ],
    );
  }
}
