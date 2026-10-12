import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/dashed_border.dart';
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
  group('DashedBorder', () {
    testWidgets('paints around its child without taking taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          DashedBorder(
            child: GestureDetector(
              onTap: () => taps++,
              child: const SizedBox(height: 60, width: 120, child: Text('Add')),
            ),
          ),
        ),
      );

      final painted = find.descendant(
        of: find.byType(DashedBorder),
        matching: find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.foregroundPainter != null,
        ),
      );
      expect(painted, findsOneWidget);

      await tester.tap(find.text('Add'));
      expect(taps, 1, reason: 'the outline must not intercept taps');
    });

    testWidgets('supports a circular outline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Center(
            child: DashedBorder(
              circle: true,
              child: SizedBox(width: 80, height: 80),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(DashedBorder)), const Size(80, 80));
    });
  });

  group('buttons', () {
    testWidgets('a leading icon is shown before the label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrimaryButton(
            label: 'Export PDF',
            leadingIcon: Icons.file_download_outlined,
            onPressed: () {},
          ),
        ),
      );

      final icon = tester.getCenter(find.byIcon(Icons.file_download_outlined));
      final label = tester.getCenter(find.text('Export PDF'));
      expect(icon.dx, lessThan(label.dx));
    });

    testWidgets('SecondaryButton keeps the primary outline unless overridden', (
      tester,
    ) async {
      Color? outline() {
        final box = tester.widget<Container>(
          find.descendant(
            of: find.byType(SecondaryButton),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration! as BoxDecoration).border != null,
            ),
          ),
        );
        return ((box.decoration! as BoxDecoration).border! as Border).top.color;
      }

      await tester.pumpWidget(
        _wrap(SecondaryButton(label: 'Default', onPressed: () {})),
      );
      expect(outline(), AppColors.primary);

      await tester.pumpWidget(
        _wrap(
          SecondaryButton(
            label: 'Quiet',
            outlineColor: AppColors.lineStrong,
            onPressed: () {},
          ),
        ),
      );
      expect(outline(), AppColors.lineStrong);
    });
  });

  group('AppTextField / AppTextArea options', () {
    testWidgets('initialValue pre-fills an uncontrolled field', (tester) async {
      String? changed;
      await tester.pumpWidget(
        _wrap(
          AppTextField(
            initialValue: 'Ayesha',
            label: 'Full name',
            onChanged: (value) => changed = value,
          ),
        ),
      );

      expect(find.widgetWithText(TextField, 'Ayesha'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Ayesha R');
      expect(changed, 'Ayesha R');
    });

    testWidgets('a controller and an initialValue cannot be combined', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      expect(
        () => AppTextField(controller: controller, initialValue: 'x'),
        throwsAssertionError,
      );
      expect(
        () => AppTextArea(controller: controller, initialValue: 'x'),
        throwsAssertionError,
      );
    });

    testWidgets('autovalidate shows the validator error straight away', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AppTextField(
            label: 'Email',
            autovalidateMode: AutovalidateMode.always,
            validator: (value) =>
                (value ?? '').isEmpty ? 'Email is required.' : null,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Email is required.'), findsOneWidget);
    });

    testWidgets('fillColor overrides the theme fill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surfaceAlt,
            ),
          ),
          home: const Scaffold(
            body: AppTextField(fillColor: AppColors.surface),
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.fillColor, AppColors.surface);
    });

    testWidgets('AppTextArea shows a label-row action and validates', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          AppTextArea(
            label: 'What you did',
            labelTrailing: TextButton(
              onPressed: () => taps++,
              child: const Text('Improve with AI'),
            ),
            autovalidateMode: AutovalidateMode.always,
            validator: (value) => 'Needs text',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Needs text'), findsOneWidget);
      await tester.tap(find.text('Improve with AI'));
      expect(taps, 1);
    });
  });
}
