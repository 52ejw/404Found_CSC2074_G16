import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late PostType _postType;
  String? _category;
  String? _location;
  late DateTime _eventDate;
  late ContactPreference _contactPreference;

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
