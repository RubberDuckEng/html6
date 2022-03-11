import 'dart:io';
import 'dart:convert';

import 'package:html6/html6.dart';
import 'package:path/path.dart' as p;

String findHTML5LibTestsDir() {
  return "../html5lib-tests";
}

class TestGroup {
  String name;
  late List<TokenizerTest> tests;

  TestGroup.fromPath(String path) : name = p.basenameWithoutExtension(path) {
    var rootJson = json.decode(File(path).readAsStringSync());
    tests = rootJson['tests']
        .map((testJson) => TokenizerTest.fromJson(testJson))
        .toList();
  }
}

class TokenizerError {
  String code;
  int line;
  int col;

  TokenizerError.fromJson(Map<String, dynamic> testJson)
      : code = testJson['code'],
        line = testJson['line'],
        col = testJson['col'];
}

class TokenizerTest {
  String description;
  String input;
  List<List<String>> output;
  List<TokenizerError> errors;

  TokenizerTest.fromJson(Map<String, dynamic> testJson)
      : description = testJson['description'],
        input = testJson['input'],
        output = testJson['output'],
        errors = testJson['errors']
            .map((element) => TokenizerError.fromJson(element));
}

class TokenizerTestSuite {
  late List<TestGroup> groups;

  // Factory constructor?
  TokenizerTestSuite.fromPath(String dirPath) {
    var dir = Directory(dirPath);
    groups = [];
    dir.list().forEach((element) {
      if (!element.path.endsWith('.test')) {
        return;
      }

      groups.add(TestGroup.fromPath(element.path));
    });
  }
}

void main(List<String> arguments) {
  var testsRoot = findHTML5LibTestsDir();
  var tokenizerDir = p.join(testsRoot, 'tokenizer');
  var suite = TokenizerTestSuite.fromPath(tokenizerDir);
  // Tokenizer tests only for now.
  // Tokenizer tests are json.

  print('Hello tests.');
  for (var group in suite.groups) {
    print(group.name);
  }
}
