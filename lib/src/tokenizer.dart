import 'entities.dart';

abstract class Token {
  List toTestJson();
}

class CommentToken extends Token {
  final String data;

  CommentToken(this.data);

  @override
  List toTestJson() => ['Comment', data];
}

class StartTagToken extends Token {
  final String tagName;
  final bool isSelfClosing;
  final Map<String, String> attributes;

  StartTagToken(this.tagName,
      {this.attributes = const {}, this.isSelfClosing = false});

  @override
  List toTestJson() {
    return ['StartTag', tagName, attributes];
  }
}

class EndTagToken extends Token {
  final String tagName;

  EndTagToken(this.tagName);

  @override
  List toTestJson() {
    return ['EndTag', tagName];
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

  bool get isEndOfFile => pushedChar == null && _nextOffset >= data.length;

  int getNextCodePoint() {
    if (isEndOfFile) {
      return endOfFile;
    }
    int? maybeChar = pushedChar;
    if (maybeChar != null) {
      pushedChar = null;
      return maybeChar;
    }
    return data[_nextOffset++];
  }

  int peek(int relativeOffset) {
    if (pushedChar != null) {
      if (relativeOffset == 0) {
        return pushedChar!;
      }
      relativeOffset -= 1;
    }
    final index = _nextOffset + relativeOffset;
    if (index >= data.length) {
      return endOfFile;
    }
    return data[index];
  }

  bool lookAheadAndConsume(String value) {
    int offset = 0;
    for (var codePoint in value.runes) {
      if (peek(offset++) != codePoint) {
        return false;
      }
    }
    while (offset-- > 0) {
      getNextCodePoint();
    }
    return true;
  }

  bool lookAheadForEntityAndConsume(int char, StringBuffer buffer) {
    push(char);
    var entity = findMatchingEntity(this, buffer);
    if (entity != null) {
      buffer.clear();
      buffer.writeCharCode(entity.value);
      return true;
    }

    // // Hack in a single entity to test the 'true' codepaths.
    // if (char == latinSmallLetterA &&
    //     peek(0) == latinSmallLetterC &&
    //     peek(1) == semicolon) {
    //   getNextCodePoint();
    //   getNextCodePoint();
    //   buffer.clear();
    //   buffer.writeCharCode(0x223E);
    //   return true;
    // }
    return false;
  }

  void push(int char) {
    assert(pushedChar == null);
    if (char == endOfFile) {
      assert(_nextOffset == data.length);
      return;
    }
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
  rawtextLessThanSign,
  rawtextEndTagOpen,
  rawtextEndTagName,
  scriptDataLessThanSign,
  scriptDataEndTagOpen,
  scriptDataendTagName,
  scriptDataEscapeStart,
  scriptDataEscapeStartDash,
  scriptDataEscaped,
  scriptDataEscapedDash,
  scriptDataEscapedDashDash,
  scriptDataEscapedLessThanSign,
  scriptDataEscapedEndTagPpen,
  scriptDataEscapedEndTagName,
  scriptDataDoubleEscapeStart,
  scriptDataDoubleEscaped,
  scriptDataDoubleEscapedDash,
  scriptDataDoubleEscapedDashDash,
  scriptDataDoubleEscapedLessThanSign,
  scriptDataDoubleEscapeEnd,
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
  doctype,
  beforeDoctypeName,
  doctypeName,
  afterDoctypeName,
  afterDoctypePublicKeyword,
  beforeDoctypePublicIdentifier,
  doctypePublicIdentifierDoubleQuoted,
  doctypePublicIdentifierSingleQuoted,
  afterDoctypePublicIdentifier,
  betweenDoctypePublicAndSystemIdentifiers,
  afterDoctypeSystemKeyword,
  beforeDoctypeSystemIdentifier,
  doctypeSystemIdentifierDoubleQuoted,
  doctypeSystemIdentifierSingleQuoted,
  afterDoctypeSystemIdentifier,
  bogusDoctype,
  cdataSection,
  cdataSectionBracket,
  cdataSectionEnd,
  characterReference,
  namedCharacterReference,
  ambiguousAmpersand,
  numericCharacterReference,
  hexadecimalCharacterReferenceStart,
  decimalCharacterReferenceStart,
  hexadecimalCharacterReference,
  decimalCharacterReference,
  numericCharacterReferenceEnd,
}

bool _isAsciiUpperAlpha(int codePoint) {
  return codePoint >= 0x41 && codePoint <= 0x5A;
}

int _toLowerAscii(int codePoint) {
  if (_isAsciiUpperAlpha(codePoint)) {
    return codePoint + 0x20;
  }
  return codePoint;
}

bool _isAsciiAlpha(int codePoint) {
  if (_isAsciiUpperAlpha(codePoint)) {
    return true;
  }
  if (codePoint >= 0x61 && codePoint <= 0x7A) {
    return true;
  }
  return false;
}

bool _isAsciiDigit(int codePoint) {
  return codePoint >= 0x30 && codePoint <= 0x39;
}

bool _isAsciiAlphanumeric(int codePoint) {
  return _isAsciiDigit(codePoint) || _isAsciiAlpha(codePoint);
}

bool _isAsciiUpperHexDigit(int codePoint) {
  return codePoint >= 0x41 && codePoint <= 0x46;
}

bool _isAsciiLowerHexDigit(int codePoint) {
  return codePoint >= 0x61 && codePoint <= 0x66;
}

bool _isAsciiHexDigit(int codePoint) {
  return _isAsciiUpperHexDigit(codePoint) || _isAsciiLowerHexDigit(codePoint);
}

bool _isSurogate(int codePoint) {
  return codePoint >= 0xD800 && codePoint <= 0xDFFF;
}

bool _isScalarValue(int codePoint) => !_isSurogate(codePoint);

bool _isAsciiCodePoint(int codePoint) {
  return codePoint >= 0x0000 && codePoint <= 0x007F;
}

bool _isAsciiTabOrNewline(int codePoint) {
  return codePoint == 0x9 || codePoint == 0xA || codePoint == 0xD;
}

bool _isAsciiWhitespace(int codePoint) {
  return codePoint == 0x9 ||
      codePoint == 0xA ||
      codePoint == 0xC ||
      codePoint == 0xD ||
      codePoint == 0x20;
}

bool _isHTMLWhitespace(int codePoint) {
  return codePoint == 0x9 ||
      codePoint == 0xA ||
      codePoint == 0xC ||
      codePoint == 0x20;
}

// Dart does not have character literals yet:
// https://github.com/dart-lang/language/issues/886
// unicodeReplacementCharacterRune
const int replacementCharacter = 0xFFFD;
const int nullChar = 0x00;
const int exclaimationMark = 0x21;
const int numberSign = 0x23;
const int amperstand = 0x26;
const int solidus = 0x2F;
const int hyphenMinus = 0x2D;
const int semicolon = 0x3B;
const int lessThanSign = 0x3C;
const int equalsSign = 0x3D;
const int greaterThanSign = 0x3E;
const int latinCapitalLetterX = 0x58;
const int latinSmallLetterA = 0x61;
const int latinSmallLetterC = 0x63;
const int latinSmallLetterX = 0x78;
const int endOfFile = -1;

// https://html.spec.whatwg.org/multipage/parsing.html#data-state

class AttributeBuilder {
  final StringBuffer _name;
  final StringBuffer _value;

  AttributeBuilder({String name = "", String value = ""})
      : _name = StringBuffer(name),
        _value = StringBuffer(value);

  void appendToName(int charCode) {
    _name.writeCharCode(charCode);
  }

  void appendToValue(int charCode) {
    _value.writeCharCode(charCode);
  }
}

enum TagTokenType {
  startTag,
  endTag,
}

class TagTokenBuilder {
  TagTokenType tagTokenType;
  bool isSelfClosing;
  StringBuffer tagName;
  // Could just be a list of AttributeBuilders?
  Map<String, String> attributes;
  AttributeBuilder? currentAttribute;

  TagTokenBuilder.startTag()
      : tagTokenType = TagTokenType.startTag,
        isSelfClosing = false,
        tagName = StringBuffer(),
        attributes = {};

  TagTokenBuilder.endTag()
      : tagTokenType = TagTokenType.endTag,
        isSelfClosing = false,
        tagName = StringBuffer(),
        attributes = {};

  void startAttributeName(String name) {
    assert(currentAttribute == null);
    currentAttribute = AttributeBuilder(name: name);
  }

  Token buildToken() {
    if (tagTokenType == TagTokenType.startTag) {
      if (currentAttribute != null) {
        finishAttribute();
      }
      return StartTagToken(tagName.toString(),
          attributes: attributes, isSelfClosing: isSelfClosing);
    } else {
      return EndTagToken(tagName.toString());
    }
  }

  void finishAttribute() {
    AttributeBuilder attribute = currentAttribute!;
    currentAttribute = null;
    var name = attribute._name.toString();
    if (attributes.containsKey(name)) {
      return;
    }
    var value = attribute._value.toString();
    attributes[name] = value;
  }
}

class Tokenizer {
  final InputManager input;
  TokenizerState state = TokenizerState.data;
  TokenizerState? returnState;
  TagTokenBuilder? currentTag;
  // TODO: Should this be a CommentTokenBuilder or maybe a generalized
  // TokenBuilder?
  StringBuffer? textBuffer;
  StringBuffer? temporaryBuffer;
  int? characterReferenceCode;

  Tokenizer(this.input);

  bool get hasPendingCharacterToken => textBuffer != null;

// FIXME: the implicit StringBuffer creation seems dangerous?
  void bufferCharCode(int codePoint) {
    textBuffer ??= StringBuffer();
    textBuffer!.writeCharCode(codePoint);
  }

  // Alias to match spec language.
  int consumeNextInputCharacter() => input.getNextCodePoint();

  CharacterToken emitCharacterToken() {
    final characters = textBuffer.toString();
    textBuffer = null;
    return CharacterToken(characters);
  }

  Token emitCurrentTag() {
    assert(currentTag != null);
    var tag = currentTag!;
    currentTag = null;
    return tag.buildToken();
  }

  CommentToken emitCommentToken() {
    final data = textBuffer.toString();
    textBuffer = null;
    return CommentToken(data);
  }

  EofToken emitEofToken() {
    return EofToken();
  }

  // This shouldn't need to take a char?
  void reconsumeIn(int char, TokenizerState newState) {
    state = newState;
    input.push(char);
  }

  TokenizerState takeReturnState() {
    var state = returnState!;
    returnState = null;
    return state;
  }

  void reconsumeInReturnState(int char) {
    state = takeReturnState();
    input.push(char);
  }

  void flushCodePointsAsCharacterReference() {
    textBuffer ??= StringBuffer(); // FIXME: Is this needed?
    textBuffer!.write(temporaryBuffer!.toString());
    temporaryBuffer = null;
  }

  bool referenceIsPartOfAnAttribute() {
    assert(returnState != null);
    return returnState == TokenizerState.attributeValueDoubleQuoted ||
        returnState == TokenizerState.attributeValueSingleQuoted ||
        returnState == TokenizerState.attributeValueUnquoted;
  }

  Token getNextToken() {
    while (true) {
      int char = consumeNextInputCharacter();
      switch (state) {
        case TokenizerState.data:
          if (char == amperstand) {
            returnState = TokenizerState.data;
            state = TokenizerState.characterReference;
            continue;
          }
          if (char == lessThanSign) {
            state = TokenizerState.tagOpen;
            continue;
          }
          if (char == endOfFile) {
            if (hasPendingCharacterToken) {
              return emitCharacterToken();
            }
            return emitEofToken();
          }
// U+0000 NULL
// This is an unexpected-null-character parse error. Emit the current input character as a character token.
          bufferCharCode(char);
          continue;

        case TokenizerState.tagOpen:
          if (char == exclaimationMark) {
            state = TokenizerState.markupDeclarationOpen;
            continue;
          }
          if (char == solidus) {
            state = TokenizerState.endTagOpen;
            continue;
          }
          if (_isAsciiAlpha(char)) {
            currentTag = TagTokenBuilder.startTag();
            reconsumeIn(char, TokenizerState.tagName);
            if (hasPendingCharacterToken) {
              return emitCharacterToken();
            }
            continue;
          }
// U+003F QUESTION MARK (?)
// This is an unexpected-question-mark-instead-of-tag-name parse error. Create a comment token whose data is the empty string. Reconsume in the bogus comment state.

// EOF
// This is an eof-before-tag-name parse error.

// Anything else
// This is an invalid-first-character-of-tag-name parse error.
          reconsumeIn(char, TokenizerState.data);
          bufferCharCode(lessThanSign);
          return emitCharacterToken();

        case TokenizerState.tagName:
          if (_isHTMLWhitespace(char)) {
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
          if (_isAsciiAlpha(char)) {
            currentTag!.tagName.writeCharCode(_toLowerAscii(char));
            continue;
          }
          if (char == nullChar) {
            currentTag!.tagName.writeCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-tag parse error.
            return emitEofToken();
          }
          currentTag!.tagName.writeCharCode(char);
          continue;

        case TokenizerState.selfClosingStartTag:
          if (char == greaterThanSign) {
            currentTag!.isSelfClosing = true;
            state = TokenizerState.data;
            return emitCurrentTag();
          }
          if (char == endOfFile) {
            // This is an eof-in-tag parse error.
            return emitEofToken();
          }
          reconsumeIn(char, TokenizerState.beforeAttributeName);
          continue;

        case TokenizerState.beforeAttributeName:
          if (_isHTMLWhitespace(char)) {
            continue;
          }
          if (char == solidus || char == greaterThanSign) {
            reconsumeIn(char, TokenizerState.afterAttributeName);
            continue;
          }
          if (char == endOfFile) {
            reconsumeIn(char, TokenizerState.attributeName);
            continue;
          }
// U+003D EQUALS SIGN (=)
// This is an unexpected-equals-sign-before-attribute-name parse error.
// Start a new attribute in the current tag token.
// Set that attribute's name to the current input character, and its value to the empty string.
// Switch to the attribute name state.

          // Would like to be able to assert currentAttribute=null
          // but </xmp</xmp</xmp> will hit that here.
          currentTag!.currentAttribute = null;
          currentTag!.startAttributeName("");
          reconsumeIn(char, TokenizerState.attributeName);
          continue;

        case TokenizerState.attributeName:
          if (_isHTMLWhitespace(char) ||
              char == solidus ||
              char == greaterThanSign) {
            reconsumeIn(char, TokenizerState.afterAttributeName);
            continue;
          }
          if (char == endOfFile) {
            reconsumeIn(char, TokenizerState.afterAttributeName);
            continue;
          }
          if (char == equalsSign) {
            state = TokenizerState.beforeAttributeValue;
            continue;
          }
// ASCII upper alpha
// Append the lowercase version of the current input character (add 0x0020 to the character's code point) to the current attribute's name.
// U+0000 NULL
// This is an unexpected-null-character parse error. Append a U+FFFD REPLACEMENT CHARACTER character to the current attribute's name.
          currentTag!.currentAttribute!.appendToName(char);
          continue;

        case TokenizerState.afterAttributeName:
          if (_isHTMLWhitespace(char)) {
            continue;
          }
          if (char == solidus) {
            state = TokenizerState.selfClosingStartTag;
            continue;
          }
          if (char == equalsSign) {
            state = TokenizerState.beforeAttributeValue;
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitCurrentTag();
          }
          if (char == endOfFile) {
            // This is an eof-in-tag parse error.
            return emitEofToken();
          }
          // FIXME: This is wrong, should be handled earlier.
          // This is hit by "<h a B=''>"
          if (currentTag!.currentAttribute != null) {
            currentTag!.finishAttribute();
          }
          currentTag!.startAttributeName("");
          reconsumeIn(char, TokenizerState.attributeName);
          continue;

        case TokenizerState.beforeAttributeValue:
          if (_isHTMLWhitespace(char)) {
            continue;
          }
// U+0022 QUOTATION MARK (")
// Switch to the attribute value (double-quoted) state.
// U+0027 APOSTROPHE (')
// Switch to the attribute value (single-quoted) state.
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitCurrentTag();
          }
          reconsumeIn(char, TokenizerState.attributeValueUnquoted);
          continue;

        case TokenizerState.attributeValueUnquoted:
          if (_isHTMLWhitespace(char)) {
            state = TokenizerState.beforeAttributeName;
            continue;
          }
//           U+0026 AMPERSAND (&)
// Set the return state to the attribute value (unquoted) state. Switch to the character reference state.
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitCurrentTag();
          }
          if (char == endOfFile) {
            // This is an eof-in-tag parse error.
            return emitEofToken();
          }
// U+0000 NULL
// This is an unexpected-null-character parse error. Append a U+FFFD REPLACEMENT CHARACTER character to the current attribute's value.
          currentTag!.currentAttribute!.appendToValue(char);
          continue;

        case TokenizerState.endTagOpen:
          if (_isAsciiAlpha(char)) {
            currentTag = TagTokenBuilder.endTag();
            reconsumeIn(char, TokenizerState.tagName);
            if (hasPendingCharacterToken) {
              return emitCharacterToken();
            }
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            continue;
          }
          if (char == endOfFile) {
            bufferCharCode(lessThanSign);
            bufferCharCode(solidus);
            reconsumeIn(char, TokenizerState.data);
            continue;
          }
          // This is an invalid-first-character-of-tag-name parse error.
          assert(textBuffer == null);
          textBuffer = StringBuffer();
          reconsumeIn(char, TokenizerState.bogusComment);
          continue;

        case TokenizerState.markupDeclarationOpen:
          // FIXME: This push isn't quite to spec.
          input.push(char);

          if (input.lookAheadAndConsume("--")) {
            // Something is not quite right here.
            // Try input: "foo<!--</xmp>--></xmp>"
            var token;
            if (hasPendingCharacterToken) {
              token = emitCharacterToken();
            }
            assert(textBuffer == null);
            textBuffer = StringBuffer();
            state = TokenizerState.commentStart;
            if (token != null) {
              return token;
            }
            continue;
          }

// If the next few characters are:

// ASCII case-insensitive match for the word "DOCTYPE"
// Consume those characters and switch to the DOCTYPE state.
// The string "[CDATA[" (the five uppercase letters "CDATA" with a U+005B LEFT SQUARE BRACKET character before and after)
// Consume those characters. If there is an adjusted current node and it is not an element in the HTML namespace, then switch to the CDATA section state. Otherwise, this is a cdata-in-html-content parse error. Create a comment token whose data is the "[CDATA[" string. Switch to the bogus comment state.
// Anything else
// This is an incorrectly-opened-comment parse error. Create a comment token whose data is the empty string. Switch to the bogus comment state (don't
// consume anything in the current state).
// TODO: Implement the rest.
          assert(textBuffer == null);
          textBuffer = StringBuffer();
          state = TokenizerState.bogusComment;
          continue;

        case TokenizerState.commentStart:
          if (char == hyphenMinus) {
            state = TokenizerState.commentStartDash;
            continue;
          }
          if (char == greaterThanSign) {
            // This is an abrupt-closing-of-empty-comment parse error.
            state = TokenizerState.data;
            return emitCommentToken();
          }
          reconsumeIn(char, TokenizerState.comment);
          continue;

        case TokenizerState.commentStartDash:
          if (char == hyphenMinus) {
            state = TokenizerState.commentEnd;
            continue;
          }
          if (char == greaterThanSign) {
            // This is an abrupt-closing-of-empty-comment parse error.
            state = TokenizerState.data;
            return emitCommentToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-comment parse error.
            reconsumeIn(char, TokenizerState.data);
            return emitCommentToken();
          }
          textBuffer!.writeCharCode(hyphenMinus);
          reconsumeIn(char, TokenizerState.comment);
          continue;
        case TokenizerState.comment:
          if (char == lessThanSign) {
            textBuffer!.writeCharCode(char);
            state = TokenizerState.commentLessThanSign;
            continue;
          }
          if (char == hyphenMinus) {
            state = TokenizerState.commentEndDash;
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            textBuffer!.writeCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-comment parse error.
            reconsumeIn(char, TokenizerState.data);
            return emitCommentToken();
          }
          textBuffer!.writeCharCode(char);
          continue;

        case TokenizerState.commentLessThanSign:
          if (char == exclaimationMark) {
            textBuffer!.writeCharCode(char);
            state = TokenizerState.commentLessThanSignBang;
            continue;
          }
          if (char == lessThanSign) {
            textBuffer!.writeCharCode(char);
            continue;
          }
          reconsumeIn(char, TokenizerState.comment);
          continue;

        case TokenizerState.commentLessThanSignBang:
          if (char == hyphenMinus) {
            state = TokenizerState.commentLessThanSignBangDash;
            continue;
          }
          reconsumeIn(char, TokenizerState.comment);
          continue;

        case TokenizerState.commentLessThanSignBangDash:
          if (char == hyphenMinus) {
            state = TokenizerState.commentLessThanSignBangDashDash;
            continue;
          }
          reconsumeIn(char, TokenizerState.commentEndDash);
          continue;

        case TokenizerState.commentLessThanSignBangDashDash:
          if (char == greaterThanSign || char == endOfFile) {
            reconsumeIn(char, TokenizerState.commentEnd);
            continue;
          }
          // This is a nested-comment parse error.
          reconsumeIn(char, TokenizerState.commentEnd);
          continue;

        case TokenizerState.commentEndDash:
          if (char == hyphenMinus) {
            state = TokenizerState.commentEnd;
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-comment parse error.
            reconsumeIn(char, TokenizerState.data);
            return emitCommentToken();
          }
          textBuffer!.writeCharCode(hyphenMinus);
          reconsumeIn(char, TokenizerState.comment);
          continue;

        case TokenizerState.commentEnd:
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitCommentToken();
          }
          if (char == exclaimationMark) {
            state = TokenizerState.commentEndBang;
            continue;
          }
          if (char == hyphenMinus) {
            textBuffer!.writeCharCode(hyphenMinus);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-comment parse error.
            reconsumeIn(char, TokenizerState.data);
            return emitCommentToken();
          }
          textBuffer!.writeCharCode(hyphenMinus);
          textBuffer!.writeCharCode(hyphenMinus);
          reconsumeIn(char, TokenizerState.comment);
          continue;

        case TokenizerState.commentEndBang:
          if (char == hyphenMinus) {
            textBuffer!.writeCharCode(hyphenMinus);
            textBuffer!.writeCharCode(hyphenMinus);
            textBuffer!.writeCharCode(exclaimationMark);
            state = TokenizerState.commentEndDash;
            continue;
          }
          if (char == greaterThanSign) {
            // This is an incorrectly-closed-comment parse error.
            state = TokenizerState.data;
            return emitCommentToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-comment parse error.
            reconsumeIn(char, TokenizerState.data);
            return emitCommentToken();
          }
          textBuffer!.writeCharCode(hyphenMinus);
          textBuffer!.writeCharCode(hyphenMinus);
          textBuffer!.writeCharCode(exclaimationMark);
          state = TokenizerState.comment;
          continue;

        case TokenizerState.bogusComment:
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitCommentToken();
          }
          if (char == endOfFile) {
            reconsumeIn(char, TokenizerState.data);
            return emitCommentToken();
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            textBuffer!.writeCharCode(replacementCharacter);
            continue;
          }
          textBuffer!.writeCharCode(char);
          continue;

        case TokenizerState.characterReference:
          temporaryBuffer = StringBuffer("");
          temporaryBuffer!.writeCharCode(amperstand);
          if (_isAsciiAlphanumeric(char)) {
            reconsumeIn(char, TokenizerState.namedCharacterReference);
            continue;
          }
          if (char == numberSign) {
            temporaryBuffer!.writeCharCode(char);
            state = TokenizerState.numericCharacterReference;
            continue;
          }
          flushCodePointsAsCharacterReference();
          reconsumeInReturnState(char);
          continue;

        case TokenizerState.namedCharacterReference:
          // Has the side-effect of consuming and filling temporary buffer
          // with consumed codepoints or entity value.
          bool foundEntity =
              input.lookAheadForEntityAndConsume(char, temporaryBuffer!);
          if (foundEntity) {
            //  If the character reference was consumed as part of an attribute, and the last character matched is not a U+003B SEMICOLON character (;), and the next input character is either a U+003D EQUALS SIGN character (=) or an ASCII alphanumeric, then, for historical reasons, flush code points consumed as a character reference and switch to the return state.
            state = takeReturnState();
            return CharacterToken(temporaryBuffer.toString());
          }
          state = TokenizerState.ambiguousAmpersand;
          flushCodePointsAsCharacterReference();
          continue;

        case TokenizerState.ambiguousAmpersand:
          if (_isAsciiAlphanumeric(char)) {
            if (referenceIsPartOfAnAttribute()) {
              currentTag!.currentAttribute!.appendToValue(char);
            } else {
              bufferCharCode(char);
            }
            continue;
          }
          if (char == semicolon) {
            // This is an unknown-named-character-reference parse error.
            reconsumeInReturnState(char);
            continue;
          }
          reconsumeInReturnState(char);
          continue;

        case TokenizerState.numericCharacterReference:
          characterReferenceCode = 0;
          if (char == latinSmallLetterX || char == latinCapitalLetterX) {
            temporaryBuffer!.writeCharCode(char);
            state = TokenizerState.hexadecimalCharacterReferenceStart;
            continue;
          }
          reconsumeIn(char, TokenizerState.decimalCharacterReference);
          continue;

        case TokenizerState.hexadecimalCharacterReferenceStart:
          if (_isAsciiDigit(char)) {
            reconsumeIn(char, TokenizerState.decimalCharacterReference);
            continue;
          }
          // This is an absence-of-digits-in-numeric-character-reference parse error.
          flushCodePointsAsCharacterReference();
          reconsumeInReturnState(char);
          continue;

        case TokenizerState.decimalCharacterReferenceStart:
          if (_isAsciiDigit(char)) {
            reconsumeIn(char, TokenizerState.decimalCharacterReference);
            continue;
          }
          // This is an absence-of-digits-in-numeric-character-reference parse error.
          flushCodePointsAsCharacterReference();
          reconsumeInReturnState(char);
          continue;

        case TokenizerState.hexadecimalCharacterReference:
          if (_isAsciiDigit(char)) {
            int numeric = char - 0x30;
            characterReferenceCode = characterReferenceCode! * 16 + numeric;
            continue;
          }
          if (_isAsciiUpperHexDigit(char)) {
            int numeric = char - 0x37;
            characterReferenceCode = characterReferenceCode! * 16 + numeric;
            continue;
          }
          if (_isAsciiLowerHexDigit(char)) {
            int numeric = char - 0x57;
            characterReferenceCode = characterReferenceCode! * 16 + numeric;
            continue;
          }
          if (char == semicolon) {
            state = TokenizerState.numericCharacterReferenceEnd;
            continue;
          }
          // This is a missing-semicolon-after-character-reference parse error.
          reconsumeIn(char, TokenizerState.numericCharacterReferenceEnd);
          continue;

        case TokenizerState.decimalCharacterReference:
          if (_isAsciiDigit(char)) {
            int numeric = char - 0x30;
            characterReferenceCode = characterReferenceCode! * 10 + numeric;
            continue;
          }
          if (char == semicolon) {
            state = TokenizerState.numericCharacterReferenceEnd;
            continue;
          }
          // This is a missing-semicolon-after-character-reference parse error.
          reconsumeIn(char, TokenizerState.numericCharacterReferenceEnd);
          continue;

        case TokenizerState.numericCharacterReferenceEnd:
          int refCode = characterReferenceCode!;
          if (refCode == 0x00) {
            // This is a null-character-reference parse error.
            refCode = replacementCharacter;
          }
          if (refCode > 0x10FFF) {
            // This is a character-reference-outside-unicode-range parse error.
            refCode = replacementCharacter;
          }
          state = returnState!;
          continue;

        default:
          throw Exception("Reached invalid tokenizer state: $state");
      }
    }
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
