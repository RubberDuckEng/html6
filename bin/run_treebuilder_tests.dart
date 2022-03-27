import 'dart:io';

import 'package:html6/html6.dart';
import 'package:html6/src/dom.dart';
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

String treeToString(Node root) {
  int depth = 0;

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
    var prefix = "|" + ("  " * depth);
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
    }
  }
  return buffer.toString();
}

// FIXME: How much of this can be shared with the tokenizer tests?
void main(List<String> arguments) {
  var tokenizerDir = p.join('html5lib-tests', 'tree-construction');
  var suite = TreeBuilderTestSuite.fromPath(tokenizerDir);

  var resultsString = "";
  var testCount = 0;
  var passCount = 0;

  for (var group in suite.groups) {
    for (var test in group.tests) {
      testCount += 1;
      print(test.data);
      var tree = HTMLParser().parse(test.data);
      var actual = treeToString(tree);
      if (actual == test.expectedOutput) {
        passCount += 1;
      }
    }
  }
  print("Passed $passCount of $testCount tree-construction tests.");
}
