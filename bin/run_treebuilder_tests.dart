import 'dart:io';
import 'dart:convert';

import 'package:html6/html6.dart';
import 'package:html6/src/dom.dart';
import 'package:path/path.dart' as p;

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
    return TreeBuilderTest(
      data.toString().trimRight(),
      errors,
      expectedOutput.toString().trimRight(),
    );
  }
}

class TestGroup {
  final String name;
  final List<TreeBuilderTest> tests;

  TestGroup(this.name, this.tests);

  factory TestGroup.fromPath(String path) {
    var name = p.basenameWithoutExtension(path);
    var groupString = File(path).readAsStringSync();
    var testStrings = groupString.split("#data");
    var tests = <TreeBuilderTest>[];
    // Skip first empty string.
    for (var testString in testStrings.sublist(1)) {
      var test = TreeBuilderTest.fromString("#data" + testString);
      if (test.data.isEmpty && test.expectedOutput.isEmpty) {
        print("Parse error in $name: $testString");
      }
      tests.add(test);
    }
    return TestGroup(name, tests);
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

String treeToString(Node root) {
  int depth = -1;

  Node node = root;

  Node? nextNode() {
    if (node.firstChild != null) {
      depth += 1;
      node = node.firstChild!;
      return node;
    } else if (node.nextSibling != null) {
      node = node.nextSibling!;
      return node;
    } else {
      Node candidate = node;
      while (candidate != root) {
        if (candidate.nextSibling != null) {
          node = candidate.nextSibling!;
          return node;
        }
        depth -= 1;
        candidate = candidate.parent!;
      }
    }
    return null;
  }

  var buffer = StringBuffer("");
  while (nextNode() != null) {
    var prefix = "| " + ("  " * depth);
    if (node is Element) {
      Element element = node as Element;
      buffer.writeln(prefix + "<${element.tagName.name}>");
      if (element.attributes.isNotEmpty) {
        var names = element.attributes.keys.toList();
        names.sort();
        for (var name in names) {
          var value = element.attributes[name];
          buffer.writeln(prefix + "  $name=$value");
        }
      }
    } else if (node is Text) {
      var text = node as Text;
      buffer.writeln(prefix + '"${text.textContent}"');
    } else if (node is Comment) {
      var comment = node as Comment;
      buffer.writeln(prefix + '<!-- ${comment.textContent} -->');
    } else if (node is Doctype) {
      var doctype = node as Doctype;
      buffer.write(prefix + "<!DOCTYPE ${doctype.name}");
      if (doctype.publicId.isNotEmpty) {
        buffer.write(' "${doctype.publicId}"');
      }
      if (doctype.systemId.isNotEmpty) {
        buffer.write(' "${doctype.systemId}"');
      }
      buffer.writeln(">");
    }
  }
  return buffer.toString();
}

// FIXME: How much of this can be shared with the tokenizer tests?
void main(List<String> arguments) {
  var tokenizerDir = p.join('html5lib-tests', 'tree-construction');
  var suite = TreeBuilderTestSuite.fromPath(tokenizerDir);

  var results = StringBuffer("");
  var testCount = 0;
  var passCount = 0;

  for (var group in suite.groups) {
    for (var test in group.tests) {
      testCount += 1;
      var tree = HTMLParser().parse(test.data);
      var expected = test.expectedOutput.trim();
      var actual = treeToString(tree).trim();
      if (actual == expected) {
        results.writeln("PASS: ${test.data}");
        passCount += 1;
      } else {
        results.writeln("FAIL: ${test.data}");
        results.writeln("Expected:");
        results.writeln(expected);
        results.writeln("Actual:");
        results.writeln(actual);
      }
    }
  }
  results.writeln("Passed $passCount of $testCount tree-construction tests.");

  var testExpectations = File("treebuilder_expectations.txt");
  // Hacky to prevent test_expectations being treated as binary.
  var bytes = utf8.encode(results.toString());
  removeBytesGitThinksAreBinary(bytes, unicodeReplacementCharacterRune);
  testExpectations.writeAsBytesSync(bytes);
}
