import 'dart:convert';
import 'dart:io';

import 'package:html6/src/tokenizer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test/tokenizer_test_suite.dart';
import '../test/matchers.dart';

// This must exist somewhere in Dart?
void removeBytesGitThinksAreBinary(List<int> bytes, int replacement) {
  for (var i = 0; i < bytes.length; i++) {
    var byte = bytes[i];
    // Control characters other than \n or \m?
    if (byte < 0x20 && !(byte == 0xA || byte == 0xD)) {
      bytes[i] = replacement;
    }
  }
}

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
        // Spacing to make actual/expected align.
        resultsString += "FAIL: ${test.description}\n";
        resultsString += " input: \"${test.input}\"\n";
        resultsString += " actual:   $actualJson\n";
        resultsString += " expected: $expectedJson\n";
      }
    }

    var testExpectations = File("test_expectations.txt");
    // Hacky to prevent test_expectations being treated as binary.
    var bytes = utf8.encode(resultsString);
    removeBytesGitThinksAreBinary(bytes, unicodeReplacementCharacterRune);
    testExpectations.writeAsBytesSync(bytes);
  }
}
