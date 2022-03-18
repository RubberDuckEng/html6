abstract class Token {
  List toTestJson();
}

class CommentToken extends Token {
  @override
  List toTestJson() => ['Comment'];
}

class StartTagToken extends Token {
  String tagName;
  Map<String, String> attributes = {};

  StartTagToken(this.tagName);

  @override
  List toTestJson() {
    // FIXME: Add Attributes
    return ['StartTag', tagName];
  }
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
  String? pushedChar;
  final String data;
  int _nextOffset = 0;

  InputManager(this.data);

  bool get isEndOfFile => _nextOffset >= data.length;

  // TODO: We probably need to work in terms of runes.
  String? getNextCharacter() {
    if (isEndOfFile) {
      return null;
    }
    if (pushedChar != null) {
      var char = pushedChar;
      pushedChar = null;
      return char;
    }
    return data[_nextOffset++];
  }

  void push(String char) {
    assert(pushedChar == null);
    pushedChar = char;
  }
}

enum TokenizerState {
  data,
  rcdata,
  rawtext,
  scriptData,
  plaintext,
  tagOpen,
  endTagOpen,
  tagName,
  rcdataLessThanSign,
  rcdataEndTagOpen,
  rcdataEndTagName,
// RAWTEXT less-than sign,
// RAWTEXT end tag open,
// RAWTEXT end tag name,
// Script data less-than sign,
// Script data end tag open,
// Script data end tag name,
// Script data escape start,
// Script data escape start dash,
// Script data escaped,
// Script data escaped dash,
// Script data escaped dash dash,
// Script data escaped less-than sign,
// Script data escaped end tag open,
// Script data escaped end tag name,
// Script data double escape start,
// Script data double escaped,
// Script data double escaped dash,
// Script data double escaped dash dash,
// Script data double escaped less-than sign,
// Script data double escape end,
  beforeAttributeName,
  attributeName,
  afterAttributeName,
  beforeAttributeValue,
  attributeValueDoubleQuoted,
  attributeValueSingleQuoted,
  attributeValueUnquoted,
  afterAttributeValueQuoted,
  selfClosingStartTag,
  bogusComment,
  markupDeclarationOpen,
  commentStart,
  commentStartDash,
  comment,
  commentLessThanSign,
  commentLessThanSignBang,
  commentLessThanSignBangDash,
  commentLessThanSignBangDashDash,
  commentEndDash,
  commentEnd,
  commentEndBang,
// DOCTYPE,
// Before DOCTYPE name,
// DOCTYPE name,
// After DOCTYPE name,
// After DOCTYPE public keyword,
// Before DOCTYPE public identifier,
// DOCTYPE public identifier (double-quoted),
// DOCTYPE public identifier (single-quoted),
// After DOCTYPE public identifier,
// Between DOCTYPE public and system identifiers,
// After DOCTYPE system keyword,
// Before DOCTYPE system identifier,
// DOCTYPE system identifier (double-quoted),
// DOCTYPE system identifier (single-quoted),
// After DOCTYPE system identifier,
// Bogus DOCTYPE,
// CDATA section,
// CDATA section bracket,
// CDATA section end,
// Character reference,
// Named character reference,
// Ambiguous ampersand,
// Numeric character reference,
// Hexadecimal character reference start,
// Decimal character reference start,
// Hexadecimal character reference,
// Decimal character reference,
// Numeric character reference end,
}

bool isAsciiAlpha(String char) {
  assert(char.length == 1);
  int codePoint = char.runes.first;
  if (codePoint >= 0x41 && codePoint <= 0x5A) {
    return true;
  }
  if (codePoint >= 0x61 && codePoint <= 0x7A) {
    return true;
  }
  return false;
}

bool isHTMLWhitespace(String char) {
  assert(char.length == 1);
  int codePoint = char.runes.first;
  return codePoint == 0x9 ||
      codePoint == 0xA ||
      codePoint == 0xC ||
      codePoint == 0x20;
}

const String replacementCharacter = "\xFFFD";

// https://html.spec.whatwg.org/multipage/parsing.html#data-state

class Tokenizer {
  final InputManager input;
  TokenizerState state = TokenizerState.data;
  StartTagToken? currentTag;

  Tokenizer(this.input);

  Token emitCurrentTag() {
    assert(currentTag != null);
    var tag = currentTag!;
    currentTag = null;
    return tag;
  }

  Token getNextToken() {
    StringBuffer textBuffer = StringBuffer();

    while (!input.isEndOfFile) {
      // FIXME: Should use runes.
      String char = input.getNextCharacter()!;
      reconsume:
      switch (state) {
        case TokenizerState.data:
// U+0026 AMPERSAND (&)
// Set the return state to the data state. Switch to the character reference state.
          if (char == "<") {
            state = TokenizerState.tagOpen;
            return CharacterToken(textBuffer.toString());
          }
// U+0000 NULL
// This is an unexpected-null-character parse error. Emit the current input character as a character token.
          textBuffer.write(char);
          continue;
        case TokenizerState.tagOpen:
// U+0021 EXCLAMATION MARK (!)
// Switch to the markup declaration open state.
          if (char == "/") {
            state = TokenizerState.endTagOpen;
            continue;
          }
          if (isAsciiAlpha(char)) {
            currentTag = StartTagToken(char);
            state = TokenizerState.tagName;
            break reconsume;
          }
// U+003F QUESTION MARK (?)
// This is an unexpected-question-mark-instead-of-tag-name parse error. Create a comment token whose data is the empty string. Reconsume in the bogus comment state.
// EOF
// This is an eof-before-tag-name parse error. Emit a U+003C LESS-THAN SIGN character token and an end-of-file token.

// Anything else
// This is an invalid-first-character-of-tag-name parse error.
// Emit a U+003C LESS-THAN SIGN character token.
// Reconsume in the data state.
          state = TokenizerState.data;
          input.push(char);
          return CharacterToken("<");
        case TokenizerState.tagName:
          if (isHTMLWhitespace(char)) {
            state = TokenizerState.beforeAttributeName;
            continue;
          }
          if (char == "/") {
            state = TokenizerState.selfClosingStartTag;
            continue;
          }
          if (char == ">") {
            state = TokenizerState.data;
            return emitCurrentTag();
          }
          if (isAsciiAlpha(char)) {
            currentTag!.tagName += char.toLowerCase();
            continue;
          }
          if (char == "\u0000") {
            currentTag!.tagName += replacementCharacter;
            continue;
          }
          currentTag!.tagName += char;
          continue;
        case TokenizerState.beforeAttributeName:
        case TokenizerState.selfClosingStartTag:
        case TokenizerState.endTagOpen:
          // TODO: Implement.
          state = TokenizerState.data;
          continue;
        default:
          throw Exception("Reached invalid tokenizer state: $state");
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
