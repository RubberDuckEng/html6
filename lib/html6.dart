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

class Token {}

class CharacterToken extends Token {
  final String characters;

  CharacterToken(this.characters);
}

class EofToken extends Token {}

class InputManager {
  final String data;
  int _nextOffset = 0;

  InputManager(this.data);

  bool get isEndOfFile => _nextOffset >= data.length;

  String? getNextCharacter() {
    if (isEndOfFile) {
      return null;
    }
    return data[_nextOffset++];
  }
}

enum TokenizerState { data }

class Tokenizer {
  final InputManager input;
  TokenizerState state = TokenizerState.data;

  Tokenizer(this.input);

  Token getNextToken() {
    StringBuffer textBuffer = StringBuffer();

    while (!input.isEndOfFile) {
      switch (state) {
        case TokenizerState.data:
          String? char = input.getNextCharacter();
          if (char == null) {
            if (textBuffer.isNotEmpty) {
              return CharacterToken(textBuffer.toString());
            }
            return EofToken();
          }
          textBuffer.write(char);
          continue;
      }
    }
    if (textBuffer.isNotEmpty) {
      return CharacterToken(textBuffer.toString());
    }
    return EofToken();
  }

  Iterable<Token> getTokens() sync* {
    while (true) {
      var token = getNextToken();
      yield token;
      if (token is EofToken) {
        return;
      }
    }
  }
}

Node parse(String data) {
  Node document = Node();
  return document;
}
