import 'package:flutter_test/flutter_test.dart';
import 'package:wp2fapp/src/app.dart';

void main() {
  testWidgets('App bootstraps home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const Wp2fApp());
    expect(find.text('Home'), findsOneWidget);
  });
}
