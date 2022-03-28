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

TokenizerState parseInitialState(String state) {
  switch (state) {
    case 'RCDATA state':
      return TokenizerState.rcdata;
    case 'RAWTEXT state':
      return TokenizerState.rawtext;
    case 'CDATA section state':
      return TokenizerState.cdataSection;
    case 'PLAINTEXT state':
      return TokenizerState.plaintext;
    case 'Script data state':
      return TokenizerState.scriptData;
    case 'Data state':
      return TokenizerState.data;
  }
  throw Exception('Unknown state: $state');
}

void main(List<String> arguments) {
  var tokenizerDir = p.join('html5lib-tests', 'tokenizer');
  var suite = TokenizerTestSuite.fromPath(tokenizerDir);

  String? testFilter;
  // var testFilter = "Uppercase start tag name";

  var resultsString = "";
  var testCount = 0;
  var passCount = 0;

  // Tokenizer tests only for now.
  // Tokenizer tests are json.

  for (var group in suite.groups) {
    for (var test in group.tests) {
      // Hacky test filter system.
      if (testFilter != null && testFilter != test.description) {
        continue;
      }
      for (var initialState in test.initialStates) {
        // FIXME: This does not yet handle "doubleEscaped"

        // print(test.description);
        var input = InputManager(test.input);
        var tokenizer = Tokenizer(input);
        tokenizer.setState(parseInitialState(initialState));
        if (test.lastStartTag != null) {
          tokenizer.setLastStartTag(test.lastStartTag!);
        }
        testCount += 1;
        // NOTE: This toList is important or we'll try to iterate
        // the tokens iterable twice and get confused.
        List<Token> tokens;
        try {
          tokens = tokenizer.getTokensWithoutEOF().toList();
        } catch (e) {
          resultsString += 'FAIL: $e\n';
          continue;
        }
        var expectedTokens =
            test.output.map((expectation) => matchesToken(expectation));
        var matcher = orderedEquals(expectedTokens);
        var result = matcher.matches(tokens, {});
        if (result) {
          // resultsString += "PASS: ${test.description}\n";
          passCount += 1;
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
    }
  }
  resultsString = "Passed $passCount of $testCount tests\n\n" + resultsString;

  var testExpectations = File("tokenizer_expectations.txt");
  // Hacky to prevent test_expectations being treated as binary.
  var bytes = utf8.encode(resultsString);
  removeBytesGitThinksAreBinary(bytes, unicodeReplacementCharacterRune);
  testExpectations.writeAsBytesSync(bytes);
}
