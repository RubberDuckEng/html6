import 'dart:io';

import 'package:path/path.dart' as p;

class TreeBuilderTest {
  final String data;
  final List<String> errors;
  final String expectedOutput;

  TreeBuilderTest(this.data, this.errors, this.expectedOutput);

  factory TreeBuilderTest.fromString(String string) {
    String? mode;
    StringBuffer data = StringBuffer('');
    List<String> errors = [];
    StringBuffer expectedOutput = StringBuffer('');

    for (var line in string.split('\n')) {
      if (line.startsWith('#')) {
        mode = line;
      } else if (mode == '#data') {
        data.writeln(line);
      } else if (mode == '#errors') {
        errors.add(line);
      } else if (mode == '#document') {
        expectedOutput.writeln(line);
      } else {
        // print unknown mode?
      }
    }
    return TreeBuilderTest(data.toString(), errors, expectedOutput.toString());
  }
}

class TestGroup {
  final String name;
  final List<TreeBuilderTest> tests;

  TestGroup(this.name, this.tests);

  factory TestGroup.fromPath(String path) {
    var groupString = File(path).readAsStringSync();
    var tests = groupString
        .split("\n\n")
        .map<TreeBuilderTest>(
            (testString) => TreeBuilderTest.fromString(testString))
        .toList();
    return TestGroup(p.basenameWithoutExtension(path), tests);
  }
}

class TreeBuilderTestSuite {
  final List<TestGroup> groups;

  TreeBuilderTestSuite(this.groups);

  factory TreeBuilderTestSuite.fromPath(String dirPath) {
    var dir = Directory(dirPath);
    var groups = <TestGroup>[];
    // On Mac, listSync returns the items unordered?
    // https://github.com/dart-lang/sdk/issues/48621
    var paths = dir.listSync().map((e) => e.path).toList();
    paths.sort();

    for (var path in paths) {
      if (!path.endsWith('.dat')) {
        continue;
      }
      groups.add(TestGroup.fromPath(path));
    }
    return TreeBuilderTestSuite(groups);
  }
}

// FIXME: How much of this can be shared with the tokenizer tests?
void main(List<String> arguments) {
  var tokenizerDir = p.join('html5lib-tests', 'tree-construction');
  var suite = TreeBuilderTestSuite.fromPath(tokenizerDir);
  print(suite.groups.first.tests.first.expectedOutput);
}
