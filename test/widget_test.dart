// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:first/main.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const MyApp()); 
    expect(find.byType(MyApp), findsOneWidget);
  });
}
