import 'dart:convert';
import 'dart:io';

import 'package:html6/src/tokenizer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test/tokenizer_test_suite.dart';
import '../test/matchers.dart';

void main(List<String> arguments) {
  var tokenizerDir = p.join('html5lib-tests', 'tokenizer');
  var suite = TokenizerTestSuite.fromPath(tokenizerDir);

  var resultsString = "";

  // Tokenizer tests only for now.
  // Tokenizer tests are json.

  for (var group in suite.groups) {
    for (var test in group.tests) {
      var input = InputManager(test.input);
      var tokenizer = Tokenizer(input);
      var tokens = tokenizer.getTokensWithoutEOF();
      var expectedTokens =
          test.output.map((expectation) => matchesToken(expectation));
      var matcher = orderedEquals(expectedTokens);
      var result = matcher.matches(tokens, {});
      if (result) {
        resultsString += "PASS: ${test.description}\n";
      } else {
        // FIXME: Hack around incorrect toJson implementation?
        var actualJson =
            json.encode(tokens.map((token) => token.toTestJson()).toList());
        var expectedJson = json.encode(test.output);
        resultsString += "FAIL: actual: $actualJson expected: $expectedJson\n";
      }
    }

    var testExpectations = File("test_expectations.txt");
    testExpectations.writeAsStringSync(resultsString);
  }
}
