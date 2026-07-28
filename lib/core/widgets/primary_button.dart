import 'package:flutter/material.dart';

/// Full-width primary action button with a built-in loading spinner.
///
/// Used for Log in / Register / submit actions. Pass [isLoading] while the
/// backing provider is working so the button disables and shows progress
/// (blueprint 9.2 — loading states).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
