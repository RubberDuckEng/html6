import 'package:html6/src/tokenizer.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'matchers.dart';

import 'tokenizer_test_suite.dart';

void main() {
  var tokenizerDir = p.join('html5lib-tests', 'tokenizer');
  var suite = TokenizerTestSuite.fromPath(tokenizerDir);
  // Tokenizer tests only for now.
  // Tokenizer tests are json.

  test('matcher', () {
    var token = CharacterToken('<>');
    var expected = matchesToken(TokenExpectation.fromJson(["Character", "<>"]));
    expect(token, expected);
    expect([token], [expected]);
  });

  for (var groupObj in suite.groups) {
    group(groupObj.name, () {
      for (var testObj in groupObj.tests) {
        test(testObj.description, () {
          var input = InputManager(testObj.input);
          var tokenizer = Tokenizer(input);
          var tokens = tokenizer.getTokensWithoutEOF();
          var expectedTokens =
              testObj.output.map((expectation) => matchesToken(expectation));
          expect(tokens, expectedTokens);
        });
      }
    });
  }
}
