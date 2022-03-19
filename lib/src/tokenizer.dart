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

  StartTagToken.fromCodepoint(int codePoint)
      : tagName = String.fromCharCode(codePoint);

  @override
  List toTestJson() {
    return ['StartTag', tagName, attributes];
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
  int? pushedChar;
  final List<int> data;
  int _nextOffset = 0;

  // FIXME: Going through runes here isn't quite correct?
  // I think HTML5 operates on utf16 chunks which may be invalid runes?
  InputManager(String input) : data = input.runes.toList();

  bool get isEndOfFile => _nextOffset >= data.length;

  int? getNextCodePoint() {
    if (isEndOfFile) {
      return null;
    }
    int? maybeChar = pushedChar;
    if (maybeChar != null) {
      pushedChar = null;
      return maybeChar;
    }
    // FIXME: Pre-cache the runes.
    return data[_nextOffset++];
  }

  void push(int char) {
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

bool isAsciiUpperAlpha(int codePoint) {
  return codePoint >= 0x41 && codePoint <= 0x5A;
}

bool isAsciiAlpha(int codePoint) {
  if (isAsciiUpperAlpha(codePoint)) {
    return true;
  }
  if (codePoint >= 0x61 && codePoint <= 0x7A) {
    return true;
  }
  return false;
}

bool isHTMLWhitespace(int codePoint) {
  return codePoint == 0x9 ||
      codePoint == 0xA ||
      codePoint == 0xC ||
      codePoint == 0x20;
}

// Dart does not have character literals yet:
// https://github.com/dart-lang/language/issues/886
// unicodeReplacementCharacterRune
const String replacementCharacter = "\xFFFD";
const int nullChar = 0x00;
const int lessThanSign = 0x3C;
const int greaterThanSign = 0x3E;
const int solidus = 0x2F;

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
    // FIXME: This shoudl be behind a helper function.
    // StringBuffer.write takes an object and is a foot-gun.
    StringBuffer textBuffer = StringBuffer();

    while (!input.isEndOfFile) {
      int char = input.getNextCodePoint()!;
      reconsume:
      switch (state) {
        case TokenizerState.data:
// U+0026 AMPERSAND (&)
// Set the return state to the data state. Switch to the character reference state.
          if (char == lessThanSign) {
            state = TokenizerState.tagOpen;
            return CharacterToken(textBuffer.toString());
          }
// U+0000 NULL
// This is an unexpected-null-character parse error. Emit the current input character as a character token.
          textBuffer.writeCharCode(char);
          continue;

        case TokenizerState.tagOpen:
// U+0021 EXCLAMATION MARK (!)
// Switch to the markup declaration open state.
          if (char == solidus) {
            state = TokenizerState.endTagOpen;
            continue;
          }
          if (isAsciiAlpha(char)) {
            // if (isAsciiUpperAlpha(char)) {
            //   char += 0x20;
            // }
            currentTag = StartTagToken.fromCodepoint(char);
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
          if (char == solidus) {
            state = TokenizerState.selfClosingStartTag;
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitCurrentTag();
          }
          if (isAsciiAlpha(char)) {
            var name = String.fromCharCode(char);
            currentTag!.tagName += name.toLowerCase();
            continue;
          }
          if (char == nullChar) {
            currentTag!.tagName += replacementCharacter;
            continue;
          }
          currentTag!.tagName += String.fromCharCode(char);
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
