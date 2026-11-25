import 'package:flutter_test/flutter_test.dart';
import 'package:aerion_store/main.dart';

void main() {
  testWidgets('mostra a loja Aerion', (tester) async {
    await tester.pumpWidget(const AerionApp());
    await tester.pump();
    expect(find.text('Aerion'), findsWidgets);
    expect(find.text('Carrinho'), findsOneWidget);
  });
}
