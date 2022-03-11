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

@JsonSerializable()
class TokenizerError {
  final String code;
  final int line;
  final int col;

  TokenizerError(this.code, this.line, this.col);

  factory TokenizerError.fromJson(Map<String, dynamic> json) =>
      _$TokenizerErrorFromJson(json);
}

class TokenOutput {
  final String type;

  TokenOutput.fromJson(List<dynamic> json) : type = json[0];
}

@JsonSerializable()
class TokenizerTest {
  final String description;
  final String input;
  // @JsonKey(
  //     readValue: (map, key) =>
  //         map[key].map((output) => TokenOutput.fromJson(output)))
  // final List<TokenOutput> output;
  @JsonKey(defaultValue: [])
  final List<TokenizerError> errors;

  TokenizerTest(this.description, this.input, this.errors);

  factory TokenizerTest.fromJson(Map<String, dynamic> json) =>
      _$TokenizerTestFromJson(json);
}
