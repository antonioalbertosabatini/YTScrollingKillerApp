import 'package:flutter_test/flutter_test.dart';
import 'package:ytscrolling_killer/app.dart';

void main() {
  testWidgets('Setup screen shows title', (tester) async {
    await tester.pumpWidget(const YtScrollingKillerApp());
    expect(find.text('YTScrollingKiller'), findsOneWidget);
    expect(find.text('Stop Shorts scrolling'), findsOneWidget);
  });
}
