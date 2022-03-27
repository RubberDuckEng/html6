class Node {
  // FIXME: These all need to be read-only!
  final Document? _document;
  Node? parent;
  Node? firstChild;
  Node? lastChild;
  Node? nextSibling;
  Node? previousSibling;

  Node(Document document) : _document = document;

  Node._documentSuperconstructor() : _document = null;

  Document get document {
    if (_document != null) {
      return _document!;
    }
    return this as Document;
  }

  bool isDecendantOf(Node node) {
    Node? current = node;
    while (current != null) {
      if (current == this) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  void appendChild(Node node) {
    if (node.isDecendantOf(this)) {
      throw Exception("Invalid argument");
    }
    Node? maybeParent = node.parent;
    if (maybeParent != null) {
      maybeParent.removeChild(node);
    }
    node.parent = this;
    firstChild ??= node;
    if (lastChild != null) {
      node.previousSibling = lastChild;
      lastChild!.nextSibling = node;
    }
    lastChild = node;
  }

  Node removeChild(Node node) {
    if (node.parent != this) {
      throw Exception("Invalid argument");
    }
    if (firstChild == node) {
      firstChild = node.nextSibling;
    }
    if (lastChild == node) {
      lastChild = node.previousSibling;
    }
    node.previousSibling?.nextSibling = node.nextSibling;
    node.nextSibling?.previousSibling = node.previousSibling;
    node.nextSibling = null;
    node.previousSibling = null;
    node.parent = null;
    return node;
  }
}

class Doctype extends Node {
  Doctype(Document document) : super(document);
}

class Comment extends Node {
  String textContent;

  Comment(Document document, this.textContent) : super(document);
}

class Text extends Node {
  String textContent;

  Text(Document document, this.textContent) : super(document);
}

const String htmlNamespace = "http://www.w3.org/1999/xhtml";
const String mthmlNamespace = "http://www.w3.org/1998/Math/MathML";
const String svgNamespace = "http://www.w3.org/2000/svg";
const String xlinkNamespace = "http://www.w3.org/1999/xlink";
const String xmlNamespace = "http://www.w3.org/XML/1998/namespace";
const String xmlnsNamespace = "http://www.w3.org/2000/xmlns/";

// QualifiedName
class QName {
  final String namespace;
  final String name;

  const QName({required this.name, required this.namespace});

  const QName.html(this.name) : namespace = htmlNamespace;
}

class Element extends Node {
  QName tagName;
  Map<String, String> attributes = {};

  Element(Document document, this.tagName) : super(document);

  String? getAttribute(String name) => attributes[name];
  void setAttribute(String name, String value) {
    attributes[name] = value;
  }
}

enum QuirksMode {
  limted,
  quirks,
  strict,
}

class Document extends Node {
  QuirksMode quirskMode = QuirksMode.strict;

  Document() : super._documentSuperconstructor();
}
