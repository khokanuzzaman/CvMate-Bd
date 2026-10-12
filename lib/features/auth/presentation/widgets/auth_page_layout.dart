import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shared scaffold for login / register: scrollable [child] content on the soft
/// indigo ground, with an optional [footer] pinned to the bottom edge on tall
/// screens (and following the content on short ones or with the keyboard up).
class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({super.key, required this.child, this.footer});

  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppConstants.contentMaxWidth,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s22,
                      AppSpacing.s16,
                      AppSpacing.s22,
                      AppSpacing.s8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        child,
                        if (footer != null) ...[
                          const SizedBox(height: AppSpacing.s22),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
