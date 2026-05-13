import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_step_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonalInfoStep extends ConsumerWidget {
  const PersonalInfoStep({super.key, required this.showValidationErrors});

  final bool showValidationErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(cvBuilderControllerProvider).draft;
    final notifier = ref.read(cvBuilderControllerProvider.notifier);
    final info = draft.personalInfo;
    final autoValidate = showValidationErrors
        ? AutovalidateMode.always
        : AutovalidateMode.disabled;

    return CvStepSection(
      title: 'Personal information',
      description:
          'This section should make it easy for recruiters to contact you quickly.',
      child: Column(
        children: [
          CustomTextField(
            initialValue: draft.title,
            label: 'CV title',
            hintText: 'Software Engineer CV',
            helperText: 'This helps you identify saved CVs later.',
            autovalidateMode: autoValidate,
            validator: (value) =>
                Validators.requiredText(value, fieldName: 'CV title'),
            onChanged: notifier.updateTitle,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            initialValue: info.fullName,
            label: 'Full name',
            hintText: 'Khokan Uzzaman',
            autovalidateMode: autoValidate,
            validator: (value) =>
                Validators.requiredText(value, fieldName: 'Full name'),
            onChanged: (value) =>
                notifier.updatePersonalInfo(info.copyWith(fullName: value)),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            initialValue: info.desiredRole,
            label: 'Target role',
            hintText: 'Flutter Developer',
            autovalidateMode: autoValidate,
            validator: (value) =>
                Validators.requiredText(value, fieldName: 'Target role'),
            onChanged: (value) =>
                notifier.updatePersonalInfo(info.copyWith(desiredRole: value)),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            initialValue: info.email,
            label: 'Email',
            hintText: 'name@email.com',
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            autovalidateMode: autoValidate,
            validator: Validators.email,
            onChanged: (value) =>
                notifier.updatePersonalInfo(info.copyWith(email: value)),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            initialValue: info.phone,
            label: 'Phone',
            hintText: '01XXXXXXXXX',
            keyboardType: TextInputType.phone,
            textCapitalization: TextCapitalization.none,
            autovalidateMode: autoValidate,
            validator: Validators.bangladeshPhone,
            onChanged: (value) =>
                notifier.updatePersonalInfo(info.copyWith(phone: value)),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            initialValue: info.address,
            label: 'Address',
            hintText: 'Dhaka, Bangladesh',
            autovalidateMode: autoValidate,
            validator: (value) =>
                Validators.requiredText(value, fieldName: 'Address'),
            onChanged: (value) =>
                notifier.updatePersonalInfo(info.copyWith(address: value)),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            initialValue: info.linkedInUrl,
            label: 'LinkedIn URL',
            hintText: 'https://linkedin.com/in/username',
            keyboardType: TextInputType.url,
            textCapitalization: TextCapitalization.none,
            autovalidateMode: autoValidate,
            validator: Validators.optionalUrl,
            onChanged: (value) =>
                notifier.updatePersonalInfo(info.copyWith(linkedInUrl: value)),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            initialValue: info.portfolioUrl,
            label: 'Portfolio / GitHub URL',
            hintText: 'https://github.com/username',
            keyboardType: TextInputType.url,
            textCapitalization: TextCapitalization.none,
            autovalidateMode: autoValidate,
            validator: Validators.optionalUrl,
            onChanged: (value) =>
                notifier.updatePersonalInfo(info.copyWith(portfolioUrl: value)),
          ),
        ],
      ),
    );
  }
}
