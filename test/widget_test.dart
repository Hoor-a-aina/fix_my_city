import 'package:flutter_test/flutter_test.dart';

import 'package:fix_my_city/main.dart';

void main() {
  testWidgets('FixMyCity app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const FixMyCityApp());

    expect(find.text('FixMyCity'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('My Reports'), findsOneWidget);
    expect(find.text('Admin View'), findsOneWidget);
  });
}
