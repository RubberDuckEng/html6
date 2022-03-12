// import 'package:html6/html6.dart';
import 'package:path/path.dart' as p;

import '../test/tokenizer_test_suite.dart';

void main(List<String> arguments) {
  var tokenizerDir = p.join('html5lib-tests', 'tokenizer');
  var suite = TokenizerTestSuite.fromPath(tokenizerDir);
  // Tokenizer tests only for now.
  // Tokenizer tests are json.

  for (var group in suite.groups) {
    print(group.name);
    for (var test in group.tests) {
      print("  " + test.description);
      print(test.output[0].name);
    }
    return;
  }
}
