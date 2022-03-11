import 'package:html6/html6.dart';
import 'package:test/test.dart';

void main() {
  test('amperstand', () {
    var input = InputManager("&");
    var tokenizer = Tokenizer(input);
    expect(tokenizer.getNextToken(), isA<CharacterToken>());
    expect(tokenizer.getNextToken(), isA<EofToken>());
  });
}
