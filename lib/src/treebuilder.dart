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
  Element? head;

  InsertionMode mode = InsertionMode.initial;
  InsertionMode originalMode = InsertionMode.initial;
  List<InsertionMode> templateInsertionModes = [];

  // FIXME: Are these actually Nodes?
  List<Element> openElements = [];

  Tokenizer tokenizer;

  // No clue which objects should own what.
  TreeBuilder(this.document, String source)
      : tokenizer = Tokenizer(InputManager(source));

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

  void parse() {
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

    while (true) {
      var token = tokenizer.getNextToken();
      if (token is EofToken) {
        return;
      }
      processToken(token);
    }
  }

  Node? get currentNode {
    if (openElements.isEmpty) {
      return null;
    }
    return openElements.last;
  }

  Element insertForeignElement(StartTagToken token, String namespace) {
    //     Let the adjusted insertion location be the appropriate place for inserting a node.

    // Let element be the result of creating an element for the token in the given namespace, with the intended parent being the element in which the adjusted insertion location finds itself.

    // If it is possible to insert element at the adjusted insertion location, then:

    // If the parser was not created as part of the HTML fragment parsing algorithm, then push a new element queue onto element's relevant agent's custom element reactions stack.

    // Insert element at the adjusted insertion location.

    // If the parser was not created as part of the HTML fragment parsing algorithm, then pop the element queue from element's relevant agent's custom element reactions stack, and invoke custom element reactions in that queue.

    // If the adjusted insertion location cannot accept more elements, e.g. because it's a Document that already has an element child, then element is dropped on the floor.

    var qName = QName(name: token.tagName, namespace: namespace);
    var element = Element(document, qName);
    for (var entry in token.attributes.entries) {
      element.setAttribute(entry.key, entry.value);
    }
    currentNode!.appendChild(element);
    openElements.add(element);
    return element;
  }

  Element insertHtmlElement(StartTagToken token) {
    return insertForeignElement(token, htmlNamespace);
  }

  Element createElementForToken(StartTagToken token) {
    //     If the active speculative HTML parser is not null, then return the result of creating a speculative mock element given given namespace, the tag name of the given token, and the attributes of the given token.

    // Otherwise, optionally create a speculative mock element given given namespace, the tag name of the given token, and the attributes of the given token.

    // The result is not used. This step allows for a speculative fetch to be initiated from non-speculative parsing. The fetch is still speculative at this point, because, for example, by the time the element is inserted, intended parent might have been removed from the document.

    // Let document be intended parent's node document.

    // Let local name be the tag name of the token.

    // Let is be the value of the "is" attribute in the given token, if such an attribute exists, or null otherwise.

    // Let definition be the result of looking up a custom element definition given document, given namespace, local name, and is.

    // If definition is non-null and the parser was not created as part of the HTML fragment parsing algorithm, then let will execute script be true. Otherwise, let it be false.

    // If will execute script is true, then:

    // Increment document's throw-on-dynamic-markup-insertion counter.

    // If the JavaScript execution context stack is empty, then perform a microtask checkpoint.

    // Push a new element queue onto document's relevant agent's custom element reactions stack.

    // Let element be the result of creating an element given document, localName, given namespace, null, and is. If will execute script is true, set the synchronous custom elements flag; otherwise, leave it unset.

    // This will cause custom element constructors to run, if will execute script is true. However, since we incremented the throw-on-dynamic-markup-insertion counter, this cannot cause new characters to be inserted into the tokenizer, or the document to be blown away.

    // Append each attribute in the given token to element.

    // This can enqueue a custom element callback reaction for the attributeChangedCallback, which might run immediately (in the next step).

    // Even though the is attribute governs the creation of a customized built-in element, it is not present during the execution of the relevant custom element constructor; it is appended in this step, along with all other attributes.

    // If will execute script is true, then:

    // Let queue be the result of popping from document's relevant agent's custom element reactions stack. (This will be the same element queue as was pushed above.)

    // Invoke custom element reactions in queue.

    // Decrement document's throw-on-dynamic-markup-insertion counter.

    // If element has an xmlns attribute in the XMLNS namespace whose value is not exactly the same as the element's namespace, that is a parse error. Similarly, if element has an xmlns:xlink attribute in the XMLNS namespace whose value is not the XLink Namespace, that is a parse error.

    // If element is a resettable element, invoke its reset algorithm. (This initializes the element's value and checkedness based on the element's attributes.)

    // If element is a form-associated element and not a form-associated custom element, the form element pointer is not null, there is no template element on the stack of open elements, element is either not listed or doesn't have a form attribute, and the intended parent is in the same tree as the element pointed to by the form element pointer, then associate element with the form element pointed to by the form element pointer and set element's parser inserted flag.

    // Return element.

    // FIXME: This is wrong.
    var element = Element(document, QName.html(token.tagName));
    for (var entry in token.attributes.entries) {
      element.setAttribute(entry.key, entry.value);
    }
    return element;
  }

  void insertText(CharacterToken token) {
//   Let data be the characters passed to the algorithm, or, if no characters were explicitly specified, the character of the character token being processed.

// Let the adjusted insertion location be the appropriate place for inserting a node.

// If the adjusted insertion location is in a Document node, then return.

// The DOM will not let Document nodes have Text node children, so they are dropped on the floor.

// If there is a Text node immediately before the adjusted insertion location, then append data to that Text node's data.

// Otherwise, create a new Text node whose data is data and whose node document is the same as that of the element in which the adjusted insertion location finds itself, and insert the newly created node at the adjusted insertion location.
    currentNode!.appendChild(Text(document, token.characters));
  }

  void insertComment(CommentToken token, Node parent) {
    //     When the steps below require the user agent to insert a comment while processing a comment token, optionally with an explicitly insertion position position, the user agent must run the following steps:

    // Let data be the data given in the comment token being processed.

    // If position was specified, then let the adjusted insertion location be position. Otherwise, let adjusted insertion location be the appropriate place for inserting a node.

    // Create a Comment node whose data attribute is set to data and whose node document is the same as that of the node in which the adjusted insertion location finds itself.

    // Insert the newly created node at the adjusted insertion location.

    parent.appendChild(Comment(document, token.data));
  }

  void processToken(Token token) {
    while (true) {
      switch (mode) {
        case InsertionMode.initial:
// A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
// Ignore the token.

          if (token is CommentToken) {
            insertComment(token, document);
          }

// A DOCTYPE token
// If the DOCTYPE token's name is not "html", or the token's public identifier is not missing, or the token's system identifier is neither missing nor "about:legacy-compat", then there is a parse error.

// Append a DocumentType node to the Document node, with its name set to the name given in the DOCTYPE token, or the empty string if the name was missing; its public ID set to the public identifier given in the DOCTYPE token, or the empty string if the public identifier was missing; and its system ID set to the system identifier given in the DOCTYPE token, or the empty string if the system identifier was missing.

// This also ensures that the DocumentType node is returned as the value of the doctype attribute of the Document object.

// Then, if the document is not an iframe srcdoc document, and the parser cannot change the mode flag is false, and the DOCTYPE token matches one of the conditions in the following list, then set the Document to quirks mode:

// FIXME: Handle quirks mode.

// Then, switch the insertion mode to "before html".

// Anything else
// If the document is not an iframe srcdoc document, then this is a parse error; if the parser cannot change the mode flag is false, set the Document to quirks mode.
          document.quirskMode = QuirksMode.quirks;

          // In any case, switch the insertion mode to "before html", then reprocess the token.
          mode = InsertionMode.beforeHtml;
          continue; // reprocess

        case InsertionMode.beforeHtml:
          if (token is DoctypeToken) {
            // Parse error. Ignore the token.
            break;
          }
          if (token is CommentToken) {
            insertComment(token, document);
          }

// A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
// Ignore the token.

          if (token is StartTagToken && token.tagName == htmlTag) {
            var element = createElementForToken(token);
            document.appendChild(element);
            openElements.add(element);
            mode = InsertionMode.beforeHead;
          }
          if (token is EndTagToken &&
              (token.tagName != headTag &&
                  token.tagName != bodyTag &&
                  token.tagName != htmlTag &&
                  token.tagName != brTag)) {
            // Parse error. Ignore the token.
            break;
          }

          // An end tag whose tag name is one of: "head", "body", "html", "br"
          // Act as described in the "anything else" entry below.
          // Anything else
          var html = Element(document, htmlQName);
          document.appendChild(html);
          openElements.add(html);
          mode = InsertionMode.beforeHead;
          continue; // reprocess

        case InsertionMode.beforeHead:
// A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
// Ignore the token.
          if (token is CommentToken) {
            insertComment(token, document);
          }
          if (token is DoctypeToken) {
            // Parse error. Ignore the token.
            break;
          }

          if (token is StartTagToken) {
            if (token.tagName == htmlTag) {
// A start tag whose tag name is "html"
// Process the token using the rules for the "in body" insertion mode.
            } else if (token.tagName == headTag) {
              head = insertHtmlElement(token);
              mode = InsertionMode.inHead;
            }
          }

          if (token is EndTagToken &&
              (token.tagName != headTag &&
                  token.tagName != bodyTag &&
                  token.tagName != htmlTag &&
                  token.tagName != brTag)) {
            // An end tag whose tag name is one of: "head", "body", "html", "br"
            // Act as described in the "anything else" entry below.
            // Any other end tag
            // Parse error. Ignore the token.
            break;
          }

          head = insertHtmlElement(StartTagToken(headTag));
          mode = InsertionMode.inHead;
          continue; // reprocess

        case InsertionMode.inHead:
          // Anything else
          openElements.removeLast();
          mode = InsertionMode.afterHead;
          continue; // reprocess

        case InsertionMode.inHeadNoScript:
        case InsertionMode.afterHead:
          // anything else
          head = insertHtmlElement(StartTagToken(bodyTag));
          mode = InsertionMode.inBody;
          continue; // reprocess

        case InsertionMode.inBody:
          if (token is CharacterToken) {
            insertText(token);
          }

          if (token is StartTagToken) {
            // Reconstruct the active formatting elements, if any.
            insertHtmlElement(token);
          }
          return; // Done with token.
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
      // This return makes "break" calls above function as "return".
      return; // Done after switch unless explicit "continue" was used.
    }
  }
}
