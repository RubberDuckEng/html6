import 'package:html6/html6.dart';
import 'run_treebuilder_tests.dart';

void main(List<String> arguments) {
  var inputText = "<a><p></a></p>";
  var doc = HTMLParser().parse(inputText);
  print(treeToString(doc));
}
