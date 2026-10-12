import 'package:careermatebd/core/widgets/placeholder_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const style = TextStyle(fontSize: 14);

  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

  testWidgets('plain text without placeholders is unchanged', (tester) async {
    await pump(
      tester,
      const PlaceholderText('No brackets here.', style: style),
    );

    expect(find.text('No brackets here.'), findsOneWidget);
  });

  testWidgets('highlight mode puts each [placeholder] in its own pill', (
    tester,
  ) async {
    await pump(
      tester,
      const PlaceholderText(
        'Improved load time by [add %] and cut [add number] bugs.',
        style: style,
        highlight: true,
      ),
    );

    expect(find.text('[add %]'), findsOneWidget);
    expect(find.text('[add number]'), findsOneWidget);
  });

  testWidgets('without highlight a placeholder is just bold', (tester) async {
    await pump(
      tester,
      const PlaceholderText('Sincerely,\n[Your name]', style: style),
    );

    final text = tester.widget<RichText>(find.byType(RichText).first);
    final spans = <TextSpan>[];
    text.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) {
        spans.add(span);
      }
      return true;
    });
    final placeholder = spans.singleWhere((s) => s.text == '[Your name]');
    expect(placeholder.style?.fontWeight, FontWeight.w700);
    expect(find.byType(WidgetSpan), findsNothing);
  });
}
