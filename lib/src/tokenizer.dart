abstract class Token {
  List toTestJson();
}

class CommentToken extends Token {
  @override
  List toTestJson() => ['Comment'];
}

class CharacterToken extends Token {
  @override
  List toTestJson() => ['Character', characters];

  final String characters;

  CharacterToken(this.characters);
}

class EofToken extends Token {
  @override
  List toTestJson() => ['EOF'];
}

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

  Iterable<Token> getTokensWithoutEOF() sync* {
    while (true) {
      var token = getNextToken();
      if (token is EofToken) {
        return;
      }
      yield token;
    }
  }
}
