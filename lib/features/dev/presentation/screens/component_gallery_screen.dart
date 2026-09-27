import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/bottom_nav_bar.dart';
import 'package:careermatebd/core/widgets/cv_list_tile.dart';
import 'package:careermatebd/core/widgets/progress_bar.dart';
import 'package:careermatebd/core/widgets/quick_action_tile.dart';
import 'package:careermatebd/core/widgets/score_ring.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:flutter/material.dart';

/// DEV-ONLY component gallery to eyeball tokens + widgets against
/// `doc/design/*.png`. Registered only behind a debug route; not in prod nav.
class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({super.key});

  static const List<_Swatch> _swatches = [
    _Swatch('bg', AppColors.bg),
    _Swatch('surface', AppColors.surface),
    _Swatch('surfaceAlt', AppColors.surfaceAlt),
    _Swatch('previewBg', AppColors.previewBg),
    _Swatch('ink', AppColors.ink),
    _Swatch('inkSoft', AppColors.inkSoft),
    _Swatch('muted', AppColors.muted),
    _Swatch('muted2', AppColors.muted2),
    _Swatch('placeholder', AppColors.placeholder),
    _Swatch('line', AppColors.line),
    _Swatch('lineStrong', AppColors.lineStrong),
    _Swatch('primary', AppColors.primary),
    _Swatch('primaryDeep', AppColors.primaryDeep),
    _Swatch('primarySoft', AppColors.primarySoft),
    _Swatch('accent', AppColors.accent),
    _Swatch('accentSoft', AppColors.accentSoft),
    _Swatch('onAccent', AppColors.onAccent),
    _Swatch('accentInk', AppColors.accentInk),
    _Swatch('success', AppColors.success),
    _Swatch('successText', AppColors.successText),
    _Swatch('successSoft', AppColors.successSoft),
    _Swatch('danger', AppColors.danger),
    _Swatch('ringTrack', AppColors.ringTrack),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopBar(
                title: 'Component Gallery',
                onBack: () => Navigator.of(context).maybePop(),
                trailingIcon: Icons.visibility_outlined,
                onTrailingTap: () {},
                stepLabel: 'DEV',
              ),
              const SizedBox(height: AppSpacing.s20),

              _section('Colors', _colorGrid()),
              _section('Type scale', _typeScale()),
              _section('Buttons', _buttons()),
              _section('Cards', _cards()),
              _section('Section label', _sectionLabels()),
              _section('Chips', _chips()),
              _section('Quick actions', _quickActions()),
              _section('CV list tile', _cvListTiles()),
              _section('Text fields', _textFields()),
              _section('Progress + steps', _progress()),
              _section('Score ring', _scoreRing()),
              _section('Bottom nav', _bottomNav()),
              const SizedBox(height: AppSpacing.s22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: AppSpacing.s12),
          child,
        ],
      ),
    );
  }

  Widget _colorGrid() {
    return Wrap(
      spacing: AppSpacing.s10,
      runSpacing: AppSpacing.s10,
      children: [
        for (final swatch in _swatches)
          SizedBox(width: 104, child: _SwatchTile(swatch: swatch)),
      ],
    );
  }

  Widget _typeScale() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('h1 · Sora 700 26', style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.s8),
          Text('h2 · Sora 700 23', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.s8),
          Text('title · Sora 700 20', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.s8),
          Text('appBar · Sora 700 17', style: AppTextStyles.appBar),
          const SizedBox(height: AppSpacing.s8),
          Text('body · Plus Jakarta 500 14', style: AppTextStyles.body),
          Text('bodySm · Plus Jakarta 500 13.5', style: AppTextStyles.bodySm),
          Text('caption · Plus Jakarta 400 12', style: AppTextStyles.caption),
          Text('hint · Plus Jakarta 400 11.5', style: AppTextStyles.hint),
          const SizedBox(height: AppSpacing.s8),
          Text('LABEL · PLUS JAKARTA 700', style: AppTextStyles.label),
        ],
      ),
    );
  }

  Widget _buttons() {
    return Column(
      children: [
        PrimaryButton(
          label: 'Tailor my CV',
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.s12),
        SecondaryButton(label: 'Back', onPressed: () {}),
        const SizedBox(height: AppSpacing.s12),
        AmberCtaButton(
          label: 'Start tailoring',
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.s12),
        const PrimaryButton(label: 'Disabled', onPressed: null),
      ],
    );
  }

  Widget _cards() {
    return Column(
      children: [
        const AppCard(child: Text('Plain AppCard (1px line border)')),
        const SizedBox(height: AppSpacing.s12),
        const AppCard(
          shadow: true,
          child: Text('AppCard with soft shadow'),
        ),
      ],
    );
  }

  Widget _sectionLabels() {
    return const SectionLabel(
      'Matched',
      trailing: AppChip(label: '8', variant: AppChipVariant.matched),
    );
  }

  Widget _chips() {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        const AppChip(label: 'Neutral'),
        const AppChip(label: 'Selected', variant: AppChipVariant.selected),
        const AppChip(label: 'React', variant: AppChipVariant.matched),
        const AppChip(label: 'TypeScript', variant: AppChipVariant.missing),
        AppChip(
          label: 'Removable',
          variant: AppChipVariant.removable,
          onRemove: () {},
        ),
      ],
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: QuickActionTile(
            icon: Icons.note_add_outlined,
            label: 'Create CV',
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: QuickActionTile(
            icon: Icons.verified_user_outlined,
            label: 'ATS Check',
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: QuickActionTile(
            icon: Icons.mail_outline_rounded,
            label: 'Cover Letter',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _cvListTiles() {
    return Column(
      children: [
        CvListTile(
          title: 'Frontend Developer CV',
          subtitle: 'Edited 2 days ago · Modern',
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.s12),
        CvListTile(
          title: 'Product Designer CV',
          subtitle: 'Draft · Professional',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _textFields() {
    return const AppCard(
      child: Column(
        children: [
          AppTextField(label: 'Job title', hintText: 'Frontend Developer'),
          SizedBox(height: AppSpacing.s16),
          AppTextArea(
            label: 'What you did',
            hintText: 'Describe your impact…',
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressBar(value: 0.5),
          SizedBox(height: AppSpacing.s16),
          ProgressBar(value: 1.0),
          SizedBox(height: AppSpacing.s16),
          SegmentedSteps(totalSteps: 3, completedSteps: 2),
        ],
      ),
    );
  }

  Widget _scoreRing() {
    return const AppCard(
      child: Center(child: ScoreRing(percent: 62)),
    );
  }

  Widget _bottomNav() {
    // Extra top room so the raised amber center action is fully visible.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s20),
      child: BottomNavBar(currentIndex: 0, onTap: (_) {}),
    );
  }
}

class _Swatch {
  const _Swatch(this.name, this.color);
  final String name;
  final Color color;
}

class _SwatchTile extends StatelessWidget {
  const _SwatchTile({required this.swatch});

  final _Swatch swatch;

  @override
  Widget build(BuildContext context) {
    final hex = (swatch.color.toARGB32() & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: swatch.color,
            borderRadius: AppRadii.iconTileRadius,
            border: Border.all(color: AppColors.line),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(swatch.name, style: AppTextStyles.caption),
        Text('#$hex', style: AppTextStyles.hint),
      ],
    );
  }
}
