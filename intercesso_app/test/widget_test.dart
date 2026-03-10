// Intercesso 앱 기본 위젯 테스트
import 'package:flutter_test/flutter_test.dart';
import 'package:intercesso/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const IntercessoApp());
    expect(find.byType(IntercessoApp), findsOneWidget);
  });
}
