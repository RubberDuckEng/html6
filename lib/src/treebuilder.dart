import 'package:html6/src/tagnames.dart';
import 'package:html6/src/tokenizer.dart';

import 'dom.dart';

enum InsertionMode {
  initial,
  beforeHtml,
  beforeHead,
  inHead,
  inHeadNoScript,
  afterHead,
  inBody,
  text,
  inTable,
  inTableText,
  inCaption,
  inColumnGroup,
  inTableBody,
  inRow,
  inCell,
  inSelect,
  inSelectInTable,
  inTemplate,
  afterBody,
  inFrameset,
  afterFrameset,
  afterAfterBody,
  afterAfterFrameset,
}

class TreeBuilder {
  Document document;
  InsertionMode mode = InsertionMode.initial;
  InsertionMode originalMode = InsertionMode.initial;
  List<InsertionMode> templateInsertionModes = [];

  // FIXME: Are these actually Nodes?
  List<Element> openElements = [];

  TreeBuilder(this.document);

  void resetInsertionMode() {
    mode = InsertionMode.initial;
// Let last be false.

// Let node be the last node in the stack of open elements.

// Loop: If node is the first node in the stack of open elements, then set last to true, and, if the parser was created as part of the HTML fragment parsing algorithm (fragment case), set node to the context element passed to that algorithm.

// If node is a select element, run these substeps:

// If last is true, jump to the step below labeled done.

// Let ancestor be node.

// Loop: If ancestor is the first node in the stack of open elements, jump to the step below labeled done.

// Let ancestor be the node before ancestor in the stack of open elements.

// If ancestor is a template node, jump to the step below labeled done.

// If ancestor is a table node, switch the insertion mode to "in select in table" and return.

// Jump back to the step labeled loop.

// Done: Switch the insertion mode to "in select" and return.

// If node is a td or th element and last is false, then switch the insertion mode to "in cell" and return.

// If node is a tr element, then switch the insertion mode to "in row" and return.

// If node is a tbody, thead, or tfoot element, then switch the insertion mode to "in table body" and return.

// If node is a caption element, then switch the insertion mode to "in caption" and return.

// If node is a colgroup element, then switch the insertion mode to "in column group" and return.

// If node is a table element, then switch the insertion mode to "in table" and return.

// If node is a template element, then switch the insertion mode to the current template insertion mode and return.

// If node is a head element and last is false, then switch the insertion mode to "in head" and return.

// If node is a body element, then switch the insertion mode to "in body" and return.

// If node is a frameset element, then switch the insertion mode to "in frameset" and return. (fragment case)

// If node is an html element, run these substeps:

// If the head element pointer is null, switch the insertion mode to "before head" and return. (fragment case)

// Otherwise, the head element pointer is not null, switch the insertion mode to "after head" and return.

// If last is true, then switch the insertion mode to "in body" and return. (fragment case)

// Let node now be the node before node in the stack of open elements.

// Return to the step labeled loop.
  }

  void parseInto(Document doc) {
// If the stack of open elements is empty
// If the adjusted current node is an element in the HTML namespace
// If the adjusted current node is a MathML text integration point and the token is a start tag whose tag name is neither "mglyph" nor "malignmark"
// If the adjusted current node is a MathML text integration point and the token is a character token
// If the adjusted current node is a MathML annotation-xml element and the token is a start tag whose tag name is "svg"
// If the adjusted current node is an HTML integration point and the token is a start tag
// If the adjusted current node is an HTML integration point and the token is a character token
// If the token is an end-of-file token
// Process the token according to the rules given in the section corresponding to the current insertion mode in HTML content.
// Otherwise
// Process the token according to the rules given in the section for parsing tokens in foreign content.
  }

  Element createHtmlElement(QName name, {required Node parent}) {
    return Element(name)..parent = parent;
  }

  void processToken(Token token) {
    // If there was an override target specified, then let target be the override target.
    Element target;

    reprocess:
    switch (mode) {
      case InsertionMode.initial:
      // FIXME: Missing.
      case InsertionMode.beforeHtml:
// A DOCTYPE token
// Parse error. Ignore the token.

// A comment token
// Insert a comment as the last child of the Document object.

// A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
// Ignore the token.

        if (token is StartTagToken && token.tagName == htmlTag) {
          var element = createHtmlElement(htmlQName, parent: document);
          document.appendChild(element);
          openElements.add(element);
          mode = InsertionMode.beforeHead;
        }
        if (token is EndTagToken &&
            (token.tagName != headTag &&
                token.tagName != bodyTag &&
                token.tagName != htmlTag &&
                token.tagName != brTag)) {
          // ignore the token;
          break;
        }

// An end tag whose tag name is one of: "head", "body", "html", "br"
// Act as described in the "anything else" entry below.

// Any other end tag
// Parse error. Ignore the token.

// Anything else
// Create an html element whose node document is the Document object. Append it to the Document object. Put this element in the stack of open elements.

        mode = InsertionMode.beforeHead;
        break reprocess;

      case InsertionMode.beforeHead:
      case InsertionMode.inHead:
      case InsertionMode.inHeadNoScript:
      case InsertionMode.afterHead:
      case InsertionMode.inBody:
      case InsertionMode.text:
      case InsertionMode.inTable:
      case InsertionMode.inTableText:
      case InsertionMode.inCaption:
      case InsertionMode.inColumnGroup:
      case InsertionMode.inTableBody:
      case InsertionMode.inRow:
      case InsertionMode.inCell:
      case InsertionMode.inSelect:
      case InsertionMode.inSelectInTable:
      case InsertionMode.inTemplate:
      case InsertionMode.afterBody:
      case InsertionMode.inFrameset:
      case InsertionMode.afterFrameset:
      case InsertionMode.afterAfterBody:
      case InsertionMode.afterAfterFrameset:
    }
  }
}
