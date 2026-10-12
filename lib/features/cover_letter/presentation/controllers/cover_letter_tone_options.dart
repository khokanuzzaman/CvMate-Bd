import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/widgets/segmented_toggle.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

/// The three tones the cover letter offers, in display order. They are the
/// existing options (formal / simple / confident) under the design's labels:
/// Professional = formal (the default), Friendly = simple, Confident =
/// confident.
const List<SegmentedOption<AiTone>> coverLetterToneOptions = [
  SegmentedOption(
    value: AiTone.formal,
    label: AppStrings.coverLetterToneProfessional,
  ),
  SegmentedOption(
    value: AiTone.simple,
    label: AppStrings.coverLetterToneFriendly,
  ),
  SegmentedOption(
    value: AiTone.confident,
    label: AppStrings.coverLetterToneConfident,
  ),
];
