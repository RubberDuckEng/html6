class Node {
  Node? parent;
  Node? firstChild;
  Node? lastChild;
  Node? nextSibling;
  Node? previousSibling;

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

class Doctype extends Node {}

class Comment extends Node {}

class Text extends Node {
  String textContent;

  Text(this.textContent);
}

class Element extends Node {
  // TODO: Qualified names? o_O
  String tagName;
  Map<String, String> attributes = {};

  Element(this.tagName);

  String? getAttribute(String name) => attributes[name];
  void setAttribute(String name, String value) {
    attributes[name] = value;
  }
}
