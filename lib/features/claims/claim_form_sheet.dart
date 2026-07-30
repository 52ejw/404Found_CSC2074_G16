import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/utils/validators.dart';
import '../../models/item_post.dart';
import '../../providers/claims_provider.dart';

/// Ownership-proof form shown from a found-item post.
class ClaimFormSheet extends StatefulWidget {
  const ClaimFormSheet({super.key, required this.post});

  final ItemPost post;

  @override
  State<ClaimFormSheet> createState() => _ClaimFormSheetState();
}

class _ClaimFormSheetState extends State<ClaimFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _proofController = TextEditingController();

  @override
  void dispose() {
    _proofController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claims = context.watch<ClaimsProvider>();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Claim ${widget.post.itemName}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close claim form',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Describe a detail only the owner would know. Do not include passwords or sensitive account information.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('claim-proof'),
                  controller: _proofController,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Proof of ownership',
                    alignLabelWithHint: true,
                    hintText: 'e.g. There is a small sticker under the bottle…',
                  ),
                  validator: (value) {
                    final required = Validators.required(
                      value,
                      fieldName: 'Proof of ownership',
                    );
                    return required ??
                        Validators.minLength(
                          value,
                          20,
                          fieldName: 'Proof of ownership',
                        );
                  },
                ),
                if (claims.error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      claims.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  key: const Key('submit-claim-button'),
                  onPressed: claims.isSubmitting ? null : _submit,
                  icon: claims.isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_user_outlined),
                  label: Text(
                    claims.isSubmitting ? 'Submitting…' : 'Submit claim',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await context.read<ClaimsProvider>().submitClaim(
      post: widget.post,
      proofDescription: _proofController.text,
    );
    if (!mounted || !success) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Claim submitted for review.')),
    );
  }
}
