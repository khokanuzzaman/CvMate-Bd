import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );
}

void main() {
  group('AppTextField', () {
    testWidgets('renders label and hint and reports typed text', (
      tester,
    ) async {
      String? changed;
      await tester.pumpWidget(
        _wrap(
          AppTextField(
            label: 'Job title',
            hintText: 'Frontend Developer',
            onChanged: (value) => changed = value,
          ),
        ),
      );

      expect(find.text('Job title'), findsOneWidget);
      expect(find.text('Frontend Developer'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Designer');
      expect(changed, 'Designer');
    });

    testWidgets('shows the validator error when its Form validates', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _wrap(
          Form(
            key: formKey,
            child: AppTextField(
              label: 'Email',
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Email is required.' : null,
            ),
          ),
        ),
      );

      expect(find.text('Email is required.'), findsNothing);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Email is required.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'a@b.co');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('renders a suffix icon and a label-row trailing action', (
      tester,
    ) async {
      var forgotTaps = 0;
      await tester.pumpWidget(
        _wrap(
          AppTextField(
            label: 'Password',
            obscureText: true,
            suffixIcon: const Icon(Icons.visibility_outlined),
            labelTrailing: TextButton(
              onPressed: () => forgotTaps++,
              child: const Text('Forgot?'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );

      await tester.tap(find.text('Forgot?'));
      expect(forgotTaps, 1);
    });
  });
}
