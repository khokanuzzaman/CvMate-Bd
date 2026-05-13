import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:flutter/material.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.highlights,
    this.icon = Icons.construction_outlined,
  });

  final String title;
  final String description;
  final List<String> highlights;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomCard(
                    child: CustomEmptyState(
                      title: title,
                      message: description,
                      icon: icon,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planned in this milestone',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        for (final item in highlights)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
