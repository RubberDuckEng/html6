import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

part 'tokenizer_test_suite.g.dart';

class TestGroup {
  final String name;
  final List<TokenizerTest> tests;

  TestGroup(this.name, this.tests);

  factory TestGroup.fromPath(String path) {
    var rootJson = json.decode(File(path).readAsStringSync());
    // xmlViolation uses 'xmlViolationTests' as testing key.
    var testsJson = rootJson['tests'] ?? [];
    var tests = testsJson
        .map<TokenizerTest>((testJson) => TokenizerTest.fromJson(testJson))
        .toList();
    return TestGroup(p.basenameWithoutExtension(path), tests);
  }
}

@JsonSerializable(createToJson: false)
class TokenizerError {
  final String code;
  final int line;
  final int col;

  TokenizerError(this.code, this.line, this.col);

  factory TokenizerError.fromJson(Map<String, dynamic> json) =>
      _$TokenizerErrorFromJson(json);
}

class TokenExpectation {
  final List<dynamic> json;

  String get name => json[0];

  TokenExpectation.fromJson(this.json);

  List toJson() => json;
}

//   'output': [['element', 'a', {'href': 'boo'}], ['character']];
List<TokenExpectation> outputFromJson(List json) {
  return json.map((item) => TokenExpectation.fromJson(item)).toList();
}

@JsonSerializable(createToJson: false)
class TokenizerTest {
  final String description;
  final String input;

  @JsonKey(fromJson: outputFromJson)
  final List<TokenExpectation> output;
  @JsonKey(defaultValue: [])
  final List<TokenizerError> errors;

  TokenizerTest(this.description, this.input, this.output, this.errors);

  factory TokenizerTest.fromJson(Map<String, dynamic> json) =>
      _$TokenizerTestFromJson(json);
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
