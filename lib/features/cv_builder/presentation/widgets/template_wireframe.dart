import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:flutter/material.dart';

/// A tiny skeleton drawing of a CV template, shown in the template picker.
class TemplateWireframe extends StatelessWidget {
  const TemplateWireframe({super.key, required this.template});

  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 140,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadii.iconTile + 2),
        ),
        child: switch (template) {
          CvTemplate.classic => const _Classic(),
          CvTemplate.modern => const _Modern(),
          CvTemplate.minimal => const _Minimal(),
          CvTemplate.professional => const _Professional(),
          CvTemplate.fresher => const _Fresher(),
        },
      ),
    );
  }
}

class _Classic extends StatelessWidget {
  const _Classic();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s14),
      child: Column(
        children: [
          _Bar(widthFactor: 0.5, height: 7, color: AppColors.ink),
          SizedBox(height: AppSpacing.s6),
          _Bar(widthFactor: 0.28, height: 5, color: AppColors.lineStrong),
          SizedBox(height: AppSpacing.s12),
          _Bar(widthFactor: 1, height: 4, color: AppColors.lineStrong),
          SizedBox(height: AppSpacing.s6),
          _Bar(widthFactor: 0.85, height: 4, color: AppColors.lineStrong),
          SizedBox(height: AppSpacing.s6),
          _Bar(widthFactor: 0.9, height: 4, color: AppColors.lineStrong),
          SizedBox(height: AppSpacing.s12),
          _Bar(widthFactor: 0.4, height: 4, color: AppColors.lineStrong),
          SizedBox(height: AppSpacing.s6),
          _Bar(widthFactor: 0.95, height: 4, color: AppColors.lineStrong),
        ],
      ),
    );
  }
}

class _Modern extends StatelessWidget {
  const _Modern();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          color: AppColors.primary,
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: const Column(
            children: [
              SizedBox(height: AppSpacing.s4),
              CircleAvatar(radius: 11, backgroundColor: AppColors.primarySoft),
              SizedBox(height: AppSpacing.s10),
              _Bar(widthFactor: 1, height: 3, color: AppColors.primarySoft),
              SizedBox(height: AppSpacing.s4),
              _Bar(widthFactor: 0.7, height: 3, color: AppColors.primarySoft),
            ],
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.s10),
            child: Column(
              children: [
                _Bar(widthFactor: 0.7, height: 6, color: AppColors.ink),
                SizedBox(height: AppSpacing.s10),
                _Bar(widthFactor: 1, height: 3, color: AppColors.lineStrong),
                SizedBox(height: AppSpacing.s4),
                _Bar(widthFactor: 0.8, height: 3, color: AppColors.lineStrong),
                SizedBox(height: AppSpacing.s4),
                _Bar(widthFactor: 0.9, height: 3, color: AppColors.lineStrong),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Minimal extends StatelessWidget {
  const _Minimal();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bar(widthFactor: 0.4, height: 7, color: AppColors.ink),
          SizedBox(height: AppSpacing.s14),
          _Bar(widthFactor: 0.9, height: 4, color: AppColors.lineStrong),
          SizedBox(height: AppSpacing.s6),
          _Bar(widthFactor: 0.55, height: 4, color: AppColors.lineStrong),
          SizedBox(height: AppSpacing.s16),
          _Bar(widthFactor: 0.3, height: 4, color: AppColors.lineStrong),
          SizedBox(height: AppSpacing.s6),
          _Bar(widthFactor: 0.8, height: 4, color: AppColors.lineStrong),
        ],
      ),
    );
  }
}

class _Professional extends StatelessWidget {
  const _Professional();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.ink,
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: const Column(
            children: [
              _Bar(widthFactor: 0.55, height: 6, color: AppColors.surface),
              SizedBox(height: AppSpacing.s6),
              _Bar(widthFactor: 0.3, height: 4, color: AppColors.muted2),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(AppSpacing.s12),
          child: Column(
            children: [
              _Bar(widthFactor: 0.9, height: 4, color: AppColors.lineStrong),
              SizedBox(height: AppSpacing.s6),
              _Bar(widthFactor: 0.7, height: 4, color: AppColors.lineStrong),
              SizedBox(height: AppSpacing.s12),
              _Bar(widthFactor: 0.4, height: 4, color: AppColors.lineStrong),
            ],
          ),
        ),
      ],
    );
  }
}

class _Fresher extends StatelessWidget {
  const _Fresher();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Bar(widthFactor: 0.45, height: 7, color: AppColors.ink),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              for (final width in const [30.0, 22.0, 38.0]) ...[
                Container(
                  width: width,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppRadii.pillRadius,
                  ),
                ),
                const SizedBox(width: AppSpacing.s6),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          const _Bar(widthFactor: 0.4, height: 4, color: AppColors.lineStrong),
          const SizedBox(height: AppSpacing.s6),
          const _Bar(widthFactor: 0.95, height: 4, color: AppColors.lineStrong),
          const SizedBox(height: AppSpacing.s6),
          const _Bar(widthFactor: 0.8, height: 4, color: AppColors.lineStrong),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.widthFactor,
    required this.height,
    required this.color,
  });

  final double widthFactor;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadii.pillRadius,
          ),
        ),
      ),
    );
  }
}
