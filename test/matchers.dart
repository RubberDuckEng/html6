import 'package:test/test.dart';
import 'package:html6/src/tokenizer.dart';

import 'tokenizer_test_suite.dart';

class _MatchesToken extends Matcher {
  final TokenExpectation expectation;

  const _MatchesToken(this.expectation);

  // FIXME: This is redundant with toTestJson implementations
  // Could we just check exepctation.json == token.toTestJson?
  bool nameMatchesType(String name, Token token) {
    if (name == "DOCTYPE") {
      return token is DoctypeToken &&
          token.name == expectation.json[1] &&
          token.publicIdentifier == expectation.json[2] &&
          token.systemIdentifier == expectation.json[3] &&
          token.forceQuirks == !expectation.json[4];
    } else if (name == "Comment") {
      return token is CommentToken && token.data == expectation.json[1];
    } else if (name == "Character") {
      return token is CharacterToken && token.characters == expectation.json[1];
    } else if (name == "StartTag") {
      if (token is! StartTagToken || token.tagName != expectation.json[1]) {
        return false;
      }
      var expectedAttributes = expectation.json[2];
      // FIXME: Actually check attributes contents.
      return token.attributes.length == expectedAttributes.length;
    } else if (name == "EndTag") {
      return token is EndTagToken && token.tagName == expectation.json[1];
    }
    // else throw error?
    // missing: DOCTYPE
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
