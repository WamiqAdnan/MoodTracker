import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MoodTrackerApp());
    expect(find.byType(MoodTrackerApp), findsOneWidget);
  });
}
