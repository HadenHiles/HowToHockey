import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/app_page.dart';

void main() {
  testWidgets('the page action stays above the on-screen keyboard', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AppPage(
          title: 'Form',
          action: FilledButton(onPressed: () {}, child: const Text('Save')),
          children: const [TextField()],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final keyboardTop = (1600 - 600) / 2;
    expect(tester.getBottomLeft(find.text('Save')).dy, lessThanOrEqualTo(keyboardTop));
  });

  testWidgets('the title sits close under the top of the page and folds away when scrolled', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AppPage(title: 'Kids', children: [for (var i = 0; i < 30; i++) Text('Row $i')]),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Row 0')).dy, lessThan(150), reason: 'content starts near the top, not below a tall empty header');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Kids'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
