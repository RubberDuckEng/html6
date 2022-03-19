import 'package:test/test.dart';
import 'package:html6/src/tokenizer.dart';

import 'tokenizer_test_suite.dart';

class _MatchesToken extends Matcher {
  final TokenExpectation expectation;

  const _MatchesToken(this.expectation);

  bool nameMatchesType(String name, Token token) {
    if (name == "Comment") {
      return token is CommentToken;
    } else if (name == "Character") {
      return token is CharacterToken && token.characters == expectation.json[1];
    } else if (name == "StartTag") {
      return token is StartTagToken;
    }
    // else throw error?
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
