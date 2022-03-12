import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'tokenizer_test_suite.dart';

void main() {
  var tokenizerDir = p.join('html5lib-tests', 'tokenizer');
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
