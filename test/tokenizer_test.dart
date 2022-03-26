import 'package:html6/src/tokenizer.dart';
import 'package:test/test.dart';

void main() {
  test('amperstand', () {
    var input = InputManager("&");
    var tokenizer = Tokenizer(input);
    expect(tokenizer.getNextToken(), isA<CharacterToken>());
    expect(tokenizer.getNextToken(), isA<EofToken>());
  });

  test('normalizeNewlines', () {
    expect(normalizeNewlines("a"), [97]);
    expect(normalizeNewlines("\r\n"), [0xA]);
    expect(normalizeNewlines("\r\n\n"), [0xA, 0xA]);
    expect(normalizeNewlines("\r\r\n\n"), [0xA, 0xA, 0xA]);
  });
}
