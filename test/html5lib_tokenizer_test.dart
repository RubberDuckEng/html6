import 'package:html6/src/tokenizer.dart';
import 'package:test/test.dart';
import 'matchers.dart';

import 'tokenizer_test_suite.dart';

void main() {
  // Tokenizer tests only for now.
  // Tokenizer tests are json.

  test('character token matcher', () {
    var token = CharacterToken('<>');
    var expected = matchesToken(TokenExpectation.fromJson(["Character", "<>"]));
    expect(token, expected);
    expect([token], [expected]);
  });

  test('start tag token matcher', () {
    var token = StartTagToken('foo');
    var expected = matchesToken(TokenExpectation.fromJson(["StartTag", "foo"]));
    expect(token, expected);
    expect([token], [expected]);
  });

  test('multiple tokens', () {
    var tokens = [CharacterToken('a'), StartTagToken('b')];
    var expectedJson = outputFromJson([
      ["Character", "a"],
      ["StartTag", "b"]
    ]);

    var expectedTokens =
        expectedJson.map((expectation) => matchesToken(expectation));
    expect(tokens, expectedTokens);
    expect(orderedEquals(expectedTokens).matches(tokens, {}), isTrue);
  });

  // var tokenizerDir = p.join('html5lib-tests', 'tokenizer');
  // var suite = TokenizerTestSuite.fromPath(tokenizerDir);
  // for (var groupObj in suite.groups) {
  //   group(groupObj.name, () {
  //     for (var testObj in groupObj.tests) {
  //       test(testObj.description, () {
  //         var input = InputManager(testObj.input);
  //         var tokenizer = Tokenizer(input);
  //         var tokens = tokenizer.getTokensWithoutEOF();
  //         var expectedTokens =
  //             testObj.output.map((expectation) => matchesToken(expectation));
  //         expect(tokens, expectedTokens);
  //       });
  //     }
  //   });
  // }
}
