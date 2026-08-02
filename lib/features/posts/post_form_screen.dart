import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../core/utils/validators.dart';
import '../../models/enums.dart';
import '../../models/item_post.dart';
import '../../providers/post_provider.dart';

/// Create/edit form for lost and found reports.
class PostFormScreen extends StatefulWidget {
  const PostFormScreen({super.key, this.existingPost, this.onSaved});

  final ItemPost? existingPost;
  final ValueChanged<ItemPost>? onSaved;

  bool get isEditing => existingPost != null;

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  static const _maxPhotos = 5;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late PostType _postType;
  String? _category;
  String? _location;
  late DateTime _eventDate;
  late ContactPreference _contactPreference;
  late List<String> _existingImageUrls;
  final List<XFile> _newImages = [];

  @override
  void initState() {
    super.initState();
    final post = widget.existingPost;
    _nameController = TextEditingController(text: post?.itemName);
    _descriptionController = TextEditingController(text: post?.description);
    _postType = post?.postType ?? PostType.lost;
    _category = post?.category;
    _location = post?.location;
    _eventDate = post?.eventDate ?? DateTime.now();
    _contactPreference = post?.contactPreference ?? ContactPreference.inAppChat;
    _existingImageUrls = List<String>.from(post?.imageUrls ?? const []);
  }

  int get _photoCount => _existingImageUrls.length + _newImages.length;

  Future<void> _pickImage() async {
    if (_photoCount >= _maxPhotos) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) setState(() => _newImages.add(picked));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit post' : 'Create post'),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl + 80 + bottomInset,
            ),
            children: [
              Text(
                widget.isEditing
                    ? 'Keep the report accurate so people can help.'
                    : 'Tell the campus what happened.',
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
                  onSelectionChanged: widget.isEditing
                      ? null
                      : (selection) =>
                            setState(() => _postType = selection.first),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Photos', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 84,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final url in _existingImageUrls)
                      _PhotoThumb(
                        key: ValueKey(url),
                        image: Image.network(url, fit: BoxFit.cover),
                        onRemove: () => setState(() => _existingImageUrls.remove(url)),
                      ),
                    for (final file in _newImages)
                      _PhotoThumb(
                        key: ValueKey(file.path),
                        image: kIsWeb
                            ? Image.network(file.path, fit: BoxFit.cover)
                            : Image.file(File(file.path), fit: BoxFit.cover),
                        onRemove: () => setState(() => _newImages.remove(file)),
                      ),
                    if (_photoCount < _maxPhotos) _AddPhotoTile(onTap: _pickImage),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('post-item-name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g. Blue water bottle',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) =>
                    Validators.required(value, fieldName: 'Item name'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('post-category'),
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value),
                validator: (value) =>
                    Validators.required(value, fieldName: 'Category'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('post-location'),
                initialValue: _location,
                decoration: const InputDecoration(
                  labelText: 'Campus location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: AppConstants.locations
                    .map(
                      (location) => DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _location = value),
                validator: (value) =>
                    Validators.required(value, fieldName: 'Location'),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                button: true,
                label: 'Event date, ${_formatDate(_eventDate)}',
                child: InkWell(
                  key: const Key('post-event-date'),
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date lost or found',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.expand_more),
                    ),
                    child: Text(_formatDate(_eventDate)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('post-description'),
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  hintText:
                      'Add colour, brand, identifying marks and where you last saw it.',
                ),
                validator: (value) {
                  final required = Validators.required(
                    value,
                    fieldName: 'Description',
                  );
                  return required ??
                      Validators.minLength(value, 10, fieldName: 'Description');
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ContactPreference>(
                initialValue: _contactPreference,
                decoration: const InputDecoration(
                  labelText: 'Preferred contact',
                  prefixIcon: Icon(Icons.contact_mail_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ContactPreference.inAppChat,
                    child: Text('In-app chat'),
                  ),
                  DropdownMenuItem(
                    value: ContactPreference.email,
                    child: Text('Email'),
                  ),
                  DropdownMenuItem(
                    value: ContactPreference.phone,
                    child: Text('Phone'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _contactPreference = value);
                  }
                },
              ),
              if (postProvider.error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    postProvider.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                key: const Key('save-post-button'),
                onPressed: postProvider.isSubmitting ? null : _save,
                icon: postProvider.isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish_outlined),
                label: Text(
                  postProvider.isSubmitting
                      ? 'Saving…'
                      : widget.isEditing
                      ? 'Save changes'
                      : 'Publish post',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'When was the item lost or found?',
    );
    if (picked != null && mounted) setState(() => _eventDate = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = await context.read<PostProvider>().savePost(
      existingPost: widget.existingPost,
      postType: _postType,
      itemName: _nameController.text,
      category: _category!,
      description: _descriptionController.text,
      location: _location!,
      eventDate: _eventDate,
      contactPreference: _contactPreference,
      newImages: _newImages,
      keepImageUrls: _existingImageUrls,
    );
    if (!mounted || result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEditing ? 'Post updated.' : 'Post published.'),
      ),
    );
    if (widget.onSaved != null) {
      widget.onSaved!(result);
      if (!widget.isEditing) _reset();
    } else {
      Navigator.of(context).pop(result);
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _postType = PostType.lost;
      _category = null;
      _location = null;
      _eventDate = DateTime.now();
      _contactPreference = ContactPreference.inAppChat;
      _existingImageUrls = [];
      _newImages.clear();
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// A picked/existing photo preview with a remove button, used in the
/// horizontal photo strip.
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({super.key, required this.image, required this.onRemove});

  final Widget image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: SizedBox(width: 76, height: 76, child: image),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Semantics(
              button: true,
              label: 'Remove photo',
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "+" tile that opens the image picker, shown at the end of the photo strip.
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add photo',
      child: Material(
        color: AppColors.placeholder.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: const SizedBox(
            width: 76,
            height: 76,
            child: Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
