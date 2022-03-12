import 'package:html6/html6.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'tokenizer_test_suite.dart';

class _MatchesToken extends Matcher {
  final TokenExpectation expectation;

  const _MatchesToken(this.expectation);

  bool nameMatchesType(String name, Token token) {
    if (name == "Comment") {
      return Token is CommentToken;
    } else if (name == "Character") {
      return Token is CharacterToken;
    } // else throw error?
    // DOCTYPE, StartTag, EndTag
    return false;
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! Token) {
      return false;
    }
    return nameMatchesType(expectation.name, item);
  }

  @override
  Description describe(Description description) =>
      description.add('matches token');
}

Matcher matchesToken(TokenExpectation expectation) =>
    _MatchesToken(expectation);

void main() {
  var tokenizerDir = p.join('html5lib-tests', 'tokenizer');
  var suite = TokenizerTestSuite.fromPath(tokenizerDir);
  // Tokenizer tests only for now.
  // Tokenizer tests are json.

  for (var groupObj in suite.groups) {
    group(groupObj.name, () {
      for (var testObj in groupObj.tests) {
        test(testObj.description, () {
          expect(true, isTrue);
        });
      }
    });
  }
}
