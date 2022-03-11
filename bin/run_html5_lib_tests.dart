import 'dart:io';

// import 'package:html6/html6.dart';
import 'package:html6/tokenizer_test_suite.dart';
import 'package:path/path.dart' as p;

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

void main(List<String> arguments) {
  var testsRoot = findHTML5LibTestsDir();
  var tokenizerDir = p.join(testsRoot, 'tokenizer');
  var suite = TokenizerTestSuite.fromPath(tokenizerDir);
  // Tokenizer tests only for now.
  // Tokenizer tests are json.

  for (var group in suite.groups) {
    print(group.name);
    for (var test in group.tests) {
      print("  " + test.description);
    }
  }
}
