import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/item_post.dart';
import 'type_badge.dart';

class PostGridCard extends StatelessWidget {
  final ItemPost post;
  final VoidCallback? onTap;

  const PostGridCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: onTap != null,
      excludeSemantics: true,
      label:
          '${post.postType.name} item, ${post.itemName}, ${post.category}, ${post.location}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.placeholder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ExcludeSemantics(child: _thumbnail()),
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: TypeBadge(type: post.postType),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      post.itemName.isEmpty ? 'Untitled item' : post.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _meta(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final hasImage = post.imageUrls.isNotEmpty;
    return hasImage
        ? Image.network(
            post.imageUrls.first,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(),
          )
        : _placeholder();
  }

  Widget _placeholder() => Container(
    color: AppColors.placeholder,
    child: const Icon(Icons.image_outlined, color: Colors.white, size: 28),
  );

  String _meta() {
    final parts = <String>[];
    if (post.category.isNotEmpty) parts.add(post.category);
    if (post.location.isNotEmpty) parts.add(post.location);
    parts.add(_timeAgo(post.createdAt));
    return parts.join(' · ');
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
