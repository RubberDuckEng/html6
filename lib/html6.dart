import 'package:html6/src/treebuilder.dart';

import 'src/dom.dart';

class HTMLParser {
  Node parse(String source) {
    var document = Document();
    TreeBuilder builder = TreeBuilder(document, source);
    builder.parse();
    return document;
  }
}
