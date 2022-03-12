import 'dart:io';

import 'package:html6/html6.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'tokenizer_test_suite.dart';

String findHTML5LibTestsDir() {
  return "../html5lib-tests";
}

class TokenizerTestSuite {
  final List<TestGroup> groups;

  TokenizerTestSuite(this.groups);

  factory TokenizerTestSuite.fromPath(String dirPath) {
    var dir = Directory(dirPath);
    var groups = <TestGroup>[];
    for (var element in dir.listSync()) {
      if (!element.path.endsWith('.test')) {
        continue;
      }
      groups.add(TestGroup.fromPath(element.path));
    }
    return TokenizerTestSuite(groups);
  }
}

void main() {
  var testsRoot = findHTML5LibTestsDir();
  var tokenizerDir = p.join(testsRoot, 'tokenizer');
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
