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

class DoctypeToken extends Token {
  @override
  List toTestJson() =>
      ['DOCTYPE', name, publicIdentifier, systemIdentifier, !forceQuirks];

  final String? name;
  final String? publicIdentifier;
  final String? systemIdentifier;
  final bool forceQuirks;

  DoctypeToken({
    this.name,
    this.publicIdentifier,
    this.systemIdentifier,
    required this.forceQuirks,
  });
}

class EofToken extends Token {
  @override
  List toTestJson() => ['EOF'];
}

List<int> normalizeNewlines(String input) {
  var data = List<int>.empty(growable: true);
  var iterator = input.runes.iterator;
  while (iterator.moveNext()) {
    if (iterator.current == 0x0D) {
      if (!iterator.moveNext()) {
        data.add(0xA);
        break;
      }
      data.add(0x0A);
      if (iterator.current == 0x0A) {
        // This was a \r\n, skip the \n.
        continue;
      } else {
        // This was \r followed by X, output \n
        // and then consider X again. This coveres the
        // \r\r\n case should produce \n\n.
        iterator.movePrevious();
        continue;
      }
    }
    data.add(iterator.current);
  }
  return data;
}

class InputManager {
  int? pushedChar;
  final List<int> data;
  int _nextOffset = 0;

  // FIXME: Going through runes here isn't quite correct?
  // I think HTML5 operates on utf16 chunks which may be invalid runes?
  InputManager(String input) : data = normalizeNewlines(input);

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

  bool lookAheadAndConsumeCaseInsensitive(String value) {
    int offset = 0;
    for (var codePoint in value.runes) {
      if (_toLowerAscii(peek(offset++)) != _toLowerAscii(codePoint)) {
        return false;
      }
    }
    while (offset-- > 0) {
      getNextCodePoint();
    }
    return true;
  }

  bool lookAheadForEntityAndConsume(int char, StringBuffer buffer) {
    // Push the first letter of the entity back into the InputManager.
    push(char);
    var entity = peekForMatchingEntity(this);
    if (entity != null) {
      // -1 for the amperstand which is in the entity.nameCodepoints
      // but has already been consumed when entering this.
      for (int i = 0; i < entity.nameCodepoints.length - 1; i++) {
        getNextCodePoint();
      }
      buffer.clear();
      for (int charCode in entity.values) {
        buffer.writeCharCode(charCode);
      }
      return true;
    }
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
  scriptDataEndTagName,
  scriptDataEscapeStart,
  scriptDataEscapeStartDash,
  scriptDataEscaped,
  scriptDataEscapedDash,
  scriptDataEscapedDashDash,
  scriptDataEscapedLessThanSign,
  scriptDataEscapedEndTagOpen,
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
  return _isAsciiDigit(codePoint) || (codePoint >= 0x41 && codePoint <= 0x46);
}

bool _isAsciiLowerHexDigit(int codePoint) {
  return _isAsciiDigit(codePoint) || (codePoint >= 0x61 && codePoint <= 0x66);
}

bool _isAsciiHexDigit(int codePoint) {
  return _isAsciiUpperHexDigit(codePoint) || _isAsciiLowerHexDigit(codePoint);
}

bool _isSurogate(int codePoint) {
  return codePoint >= 0xD800 && codePoint <= 0xDFFF;
}

bool _isNoncharacter(int codePoint) {
  return (codePoint >= 0xD800 && codePoint <= 0xDFFF ||
      [
        0xFFFE,
        0xFFFF,
        0x1FFFE,
        0x1FFFF,
        0x2FFFE,
        0x2FFFF,
        0x3FFFE,
        0x3FFFF,
        0x4FFFE,
        0x4FFFF,
        0x5FFFE,
        0x5FFFF,
        0x6FFFE,
        0x6FFFF,
        0x7FFFE,
        0x7FFFF,
        0x8FFFE,
        0x8FFFF,
        0x9FFFE,
        0x9FFFF,
        0xAFFFE,
        0xAFFFF,
        0xBFFFE,
        0xBFFFF,
        0xCFFFE,
        0xCFFFF,
        0xDFFFE,
        0xDFFFF,
        0xEFFFE,
        0xEFFFF,
        0xFFFFE,
        0xFFFFF,
        0x10FFFE,
        0x10FFFF
      ].contains(codePoint));
}

bool _isC0Control(int codePoint) {
  return codePoint >= 0x0000 && codePoint <= 0x001F;
}

bool _isControl(int codePoint) {
  return _isC0Control(codePoint) ||
      (codePoint >= 0x007F && codePoint <= 0x009F);
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
const int quotationMark = 0x22;
const int exclaimationMark = 0x21;
const int numberSign = 0x23;
const int amperstand = 0x26;
const int apostrophe = 0x27;
const int hyphenMinus = 0x2D;
const int solidus = 0x2F;
const int semicolon = 0x3B;
const int lessThanSign = 0x3C;
const int equalsSign = 0x3D;
const int greaterThanSign = 0x3E;
const int questionMark = 0x3F;
const int latinCapitalLetterX = 0x58;
const int rightSquareBracket = 0x5D;
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

class DoctypeTokenBuilder {
  StringBuffer? name;
  StringBuffer? publicIdentifier;
  StringBuffer? systemIdentifier;
  bool forceQuirks = false;

  DoctypeToken buildToken() {
    return DoctypeToken(
      name: name?.toString(),
      publicIdentifier: publicIdentifier?.toString(),
      systemIdentifier: systemIdentifier?.toString(),
      forceQuirks: forceQuirks,
    );
  }
}

class CharacterReferenceCode {
  int value = 0;
  bool overflowed = false;

  void _checkedAdd(int rhs) {
    assert(rhs > 0);
    var oldValue = value;
    value += rhs;
    if (oldValue > value) {
      overflowed = true;
    }
  }

  void _checkedMultiply(int rhs) {
    var oldValue = value;
    value *= rhs;
    if (oldValue > value) {
      overflowed = true;
    }
  }

  void addHexDigit(int digit) {
    _checkedMultiply(16);
    _checkedAdd(digit);
  }

  void addDecimalDigit(int digit) {
    _checkedMultiply(10);
    _checkedAdd(digit);
  }
}

class Tokenizer {
  final InputManager input;
  TokenizerState state = TokenizerState.data;
  TokenizerState? returnState;
  TagTokenBuilder? currentTag;
  DoctypeTokenBuilder? currentDoctype;
  // TODO: Should this be a CommentTokenBuilder or maybe a generalized
  // TokenBuilder?
  StringBuffer? textBuffer;
  StringBuffer? temporaryBuffer;
  CharacterReferenceCode? characterReferenceCode;
  String? lastStartTag;

  Tokenizer(this.input);

  void setState(TokenizerState requestedState) {
    state = requestedState;
  }

  void setLastStartTag(String tagName) {
    lastStartTag = tagName;
  }

  bool _currentTagIsAppropriate() {
    if (temporaryBuffer == null || lastStartTag == null) {
      return false;
    }
    final bufferedRunes = temporaryBuffer!.toString().runes;
    final expectedRunes = lastStartTag!.runes;
    if (bufferedRunes.length != expectedRunes.length) {
      return false;
    }
    final bufferedIterator = bufferedRunes.iterator;
    final expectedIterator = expectedRunes.iterator;
    while (bufferedIterator.moveNext() && expectedIterator.moveNext()) {
      if (_toLowerAscii(bufferedIterator.current) !=
          _toLowerAscii(expectedIterator.current)) {
        return false;
      }
    }
    temporaryBuffer = null;
    return true;
  }

  bool get hasPendingCharacterToken => textBuffer != null;

// FIXME: the implicit StringBuffer creation seems dangerous?
  void bufferCharCode(int codePoint) {
    textBuffer ??= StringBuffer();
    textBuffer!.writeCharCode(codePoint);
  }

  void bufferCharacters(String characters) {
    textBuffer ??= StringBuffer();
    textBuffer!.write(characters);
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
    final tag = currentTag!;
    currentTag = null;
    final token = tag.buildToken();
    if (token is StartTagToken) {
      lastStartTag = token.tagName;
    }
    return token;
  }

  void beginDoctypeToken() {
    assert(currentDoctype == null);
    currentDoctype = DoctypeTokenBuilder();
  }

  DoctypeToken emitDoctypeToken() {
    assert(currentDoctype != null);
    final doctype = currentDoctype!;
    currentDoctype = null;
    return doctype.buildToken();
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

        case TokenizerState.rcdata:
          if (char == amperstand) {
            returnState = TokenizerState.rcdata;
            state = TokenizerState.characterReference;
            continue;
          }
          if (char == lessThanSign) {
            state = TokenizerState.rcdataLessThanSign;
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            bufferCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            if (hasPendingCharacterToken) {
              return emitCharacterToken();
            }
            return emitEofToken();
          }
          bufferCharCode(char);
          continue;

        case TokenizerState.rawtext:
          if (char == lessThanSign) {
            state = TokenizerState.rawtextLessThanSign;
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            bufferCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            if (hasPendingCharacterToken) {
              return emitCharacterToken();
            }
            return emitEofToken();
          }
          bufferCharCode(char);
          continue;

        case TokenizerState.scriptData:
          if (char == lessThanSign) {
            state = TokenizerState.scriptDataLessThanSign;
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            bufferCharCode(replacementCharacter);
          }
          if (char == endOfFile) {
            if (hasPendingCharacterToken) {
              return emitCharacterToken();
            }
            return emitEofToken();
          }
          bufferCharCode(char);
          continue;

        case TokenizerState.plaintext:
          if (char == nullChar) {
            bufferCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            if (hasPendingCharacterToken) {
              return emitCharacterToken();
            }
            return emitEofToken();
          }
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
          if (char == questionMark) {
            // This is an unexpected-question-mark-instead-of-tag-name parse error.
            // Is this needed?
            // if (hasPendingCharacterToken) {
            //   return emitCharacterToken();
            // }
            textBuffer = StringBuffer();
            reconsumeIn(char, TokenizerState.bogusComment);
            continue;
          }

          // EOF
          // This is an eof-before-tag-name parse error.

          // Anything else
          // This is an invalid-first-character-of-tag-name parse error.
          reconsumeIn(char, TokenizerState.data);
          bufferCharCode(lessThanSign);
          continue;

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

        case TokenizerState.rcdataLessThanSign:
          if (char == solidus) {
            temporaryBuffer = StringBuffer();
            state = TokenizerState.rcdataEndTagOpen;
            continue;
          }
          bufferCharCode(lessThanSign);
          reconsumeIn(char, TokenizerState.rcdata);
          continue;

        case TokenizerState.rcdataEndTagOpen:
          if (_isAsciiAlpha(char)) {
            currentTag = TagTokenBuilder.endTag();
            reconsumeIn(char, TokenizerState.rcdataEndTagName);
            continue;
          }
          bufferCharCode(lessThanSign);
          bufferCharCode(solidus);
          reconsumeIn(char, TokenizerState.rcdata);
          continue;

        case TokenizerState.rcdataEndTagName:
          if (_isHTMLWhitespace(char)) {
            if (_currentTagIsAppropriate()) {
              state = TokenizerState.beforeAttributeName;
              if (hasPendingCharacterToken) {
                return emitCharacterToken();
              }
              continue;
            }
          } else if (char == solidus) {
            if (_currentTagIsAppropriate()) {
              state = TokenizerState.selfClosingStartTag;
              if (hasPendingCharacterToken) {
                return emitCharacterToken();
              }
              continue;
            }
          } else if (char == greaterThanSign) {
            if (_currentTagIsAppropriate()) {
              if (hasPendingCharacterToken) {
                // Put the greaterThanSign back into the input and move to the
                // afterAttributeName state so that we'll emitCurrentTag() when
                // we come back.
                reconsumeIn(char, TokenizerState.afterAttributeName);
                return emitCharacterToken();
              }
              state = TokenizerState.data;
              return emitCurrentTag();
            }
          } else if (_isAsciiAlpha(char)) {
            currentTag!.tagName.writeCharCode(_toLowerAscii(char));
            temporaryBuffer ??= StringBuffer();
            temporaryBuffer!.writeCharCode(char);
            continue;
          }
          bufferCharCode(lessThanSign);
          bufferCharCode(solidus);
          if (temporaryBuffer != null) {
            bufferCharacters(temporaryBuffer!.toString());
            temporaryBuffer = null;
          }
          reconsumeIn(char, TokenizerState.rcdata);
          continue;

        case TokenizerState.rawtextLessThanSign:
          if (char == solidus) {
            temporaryBuffer = StringBuffer();
            state = TokenizerState.rawtextEndTagOpen;
            continue;
          }
          bufferCharCode(lessThanSign);
          reconsumeIn(char, TokenizerState.rawtext);
          continue;

        case TokenizerState.rawtextEndTagOpen:
          if (_isAsciiAlpha(char)) {
            currentTag = TagTokenBuilder.endTag();
            reconsumeIn(char, TokenizerState.rawtextEndTagName);
            continue;
          }
          bufferCharCode(lessThanSign);
          bufferCharCode(solidus);
          reconsumeIn(char, TokenizerState.rcdata);
          continue;

        case TokenizerState.rawtextEndTagName:
          if (_isHTMLWhitespace(char)) {
            if (_currentTagIsAppropriate()) {
              state = TokenizerState.beforeAttributeName;
              if (hasPendingCharacterToken) {
                return emitCharacterToken();
              }
              continue;
            }
          } else if (char == solidus) {
            if (_currentTagIsAppropriate()) {
              state = TokenizerState.selfClosingStartTag;
              if (hasPendingCharacterToken) {
                return emitCharacterToken();
              }
              continue;
            }
          } else if (char == greaterThanSign) {
            if (_currentTagIsAppropriate()) {
              if (hasPendingCharacterToken) {
                // Put the greaterThanSign back into the input and move to the
                // afterAttributeName state so that we'll emitCurrentTag() when
                // we come back.
                reconsumeIn(char, TokenizerState.afterAttributeName);
                return emitCharacterToken();
              }
              state = TokenizerState.data;
              return emitCurrentTag();
            }
          } else if (_isAsciiAlpha(char)) {
            currentTag!.tagName.writeCharCode(_toLowerAscii(char));
            temporaryBuffer ??= StringBuffer();
            temporaryBuffer!.writeCharCode(char);
            continue;
          }
          bufferCharCode(lessThanSign);
          bufferCharCode(solidus);
          if (temporaryBuffer != null) {
            bufferCharacters(temporaryBuffer!.toString());
            temporaryBuffer = null;
          }
          reconsumeIn(char, TokenizerState.rawtext);
          continue;

        case TokenizerState.scriptDataLessThanSign:
          if (char == solidus) {
            temporaryBuffer = StringBuffer();
            state = TokenizerState.scriptDataEndTagOpen;
            continue;
          }
          if (char == exclaimationMark) {
            state = TokenizerState.scriptDataEscapeStart;
            bufferCharCode(lessThanSign);
            bufferCharCode(exclaimationMark);
            continue;
          }
          bufferCharCode(lessThanSign);
          reconsumeIn(char, TokenizerState.scriptData);
          continue;

        case TokenizerState.scriptDataEndTagOpen:
          if (_isAsciiAlpha(char)) {
            currentTag = TagTokenBuilder.endTag();
            reconsumeIn(char, TokenizerState.scriptDataEndTagName);
            continue;
          }
          bufferCharCode(lessThanSign);
          bufferCharCode(solidus);
          reconsumeIn(char, TokenizerState.scriptData);
          continue;

        case TokenizerState.scriptDataEndTagName:
          if (_isHTMLWhitespace(char)) {
            if (_currentTagIsAppropriate()) {
              state = TokenizerState.beforeAttributeName;
              if (hasPendingCharacterToken) {
                return emitCharacterToken();
              }
              continue;
            }
          } else if (char == solidus) {
            if (_currentTagIsAppropriate()) {
              state = TokenizerState.selfClosingStartTag;
              if (hasPendingCharacterToken) {
                return emitCharacterToken();
              }
              continue;
            }
          } else if (char == greaterThanSign) {
            if (_currentTagIsAppropriate()) {
              if (hasPendingCharacterToken) {
                // Put the greaterThanSign back into the input and move to the
                // afterAttributeName state so that we'll emitCurrentTag() when
                // we come back.
                reconsumeIn(char, TokenizerState.afterAttributeName);
                return emitCharacterToken();
              }
              state = TokenizerState.data;
              return emitCurrentTag();
            }
          } else if (_isAsciiAlpha(char)) {
            currentTag!.tagName.writeCharCode(_toLowerAscii(char));
            temporaryBuffer ??= StringBuffer();
            temporaryBuffer!.writeCharCode(char);
            continue;
          }
          bufferCharCode(lessThanSign);
          bufferCharCode(solidus);
          if (temporaryBuffer != null) {
            bufferCharacters(temporaryBuffer!.toString());
            temporaryBuffer = null;
          }
          reconsumeIn(char, TokenizerState.scriptData);
          continue;

        case TokenizerState.scriptDataEscapeStart:
          if (char == hyphenMinus) {
            state = TokenizerState.scriptDataEscapeStartDash;
            bufferCharCode(hyphenMinus);
            continue;
          }
          reconsumeIn(char, TokenizerState.scriptData);
          continue;

        case TokenizerState.scriptDataEscapeStartDash:
          if (char == hyphenMinus) {
            state = TokenizerState.scriptDataEscapedDashDash;
            bufferCharCode(hyphenMinus);
            continue;
          }
          reconsumeIn(char, TokenizerState.scriptData);
          continue;

        case TokenizerState.scriptDataEscaped:
          if (char == hyphenMinus) {
            state = TokenizerState.scriptDataEscapedDash;
            bufferCharCode(hyphenMinus);
            continue;
          }
          if (char == lessThanSign) {
            state = TokenizerState.scriptDataEscapedLessThanSign;
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            bufferCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-script-html-comment-like-text parse error.
            reconsumeIn(char, TokenizerState.scriptData);
            continue;
          }
          bufferCharCode(char);
          continue;

        case TokenizerState.scriptDataEscapedDash:
          if (char == hyphenMinus) {
            state = TokenizerState.scriptDataEscapedDashDash;
            bufferCharCode(hyphenMinus);
            continue;
          }
          if (char == lessThanSign) {
            state = TokenizerState.scriptDataEscapedLessThanSign;
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            state = TokenizerState.scriptDataEscaped;
            bufferCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-script-html-comment-like-text parse error.
            reconsumeIn(char, TokenizerState.scriptData);
            continue;
          }
          state = TokenizerState.scriptDataEscaped;
          bufferCharCode(char);
          continue;

        case TokenizerState.scriptDataEscapedDashDash:
          if (char == hyphenMinus) {
            bufferCharCode(hyphenMinus);
            continue;
          }
          if (char == lessThanSign) {
            state = TokenizerState.scriptDataEscapedLessThanSign;
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.scriptData;
            bufferCharCode(greaterThanSign);
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            state = TokenizerState.scriptDataEscaped;
            bufferCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-script-html-comment-like-text parse error.
            reconsumeIn(char, TokenizerState.scriptData);
            continue;
          }
          state = TokenizerState.scriptDataEscaped;
          bufferCharCode(char);
          continue;

        case TokenizerState.scriptDataEscapedLessThanSign:
          if (char == solidus) {
            temporaryBuffer = StringBuffer();
            state = TokenizerState.scriptDataEscapedEndTagOpen;
            continue;
          }
          if (_isAsciiAlpha(char)) {
            temporaryBuffer = StringBuffer();
            bufferCharCode(lessThanSign);
            reconsumeIn(char, TokenizerState.scriptDataDoubleEscapeStart);
            continue;
          }
          bufferCharCode(lessThanSign);
          reconsumeIn(char, TokenizerState.scriptDataEscaped);
          continue;

        case TokenizerState.scriptDataEscapedEndTagOpen:
          if (_isAsciiAlpha(char)) {
            currentTag = TagTokenBuilder.endTag();
            reconsumeIn(char, TokenizerState.scriptDataEscapedEndTagName);
            continue;
          }
          bufferCharCode(lessThanSign);
          bufferCharCode(solidus);
          reconsumeIn(char, TokenizerState.scriptDataEscaped);
          continue;
        case TokenizerState.scriptDataEscapedEndTagName:
          if (_isHTMLWhitespace(char)) {
            if (_currentTagIsAppropriate()) {
              state = TokenizerState.beforeAttributeName;
              if (hasPendingCharacterToken) {
                return emitCharacterToken();
              }
              continue;
            }
          } else if (char == solidus) {
            if (_currentTagIsAppropriate()) {
              state = TokenizerState.selfClosingStartTag;
              if (hasPendingCharacterToken) {
                return emitCharacterToken();
              }
              continue;
            }
          } else if (char == greaterThanSign) {
            if (_currentTagIsAppropriate()) {
              if (hasPendingCharacterToken) {
                // Put the greaterThanSign back into the input and move to the
                // afterAttributeName state so that we'll emitCurrentTag() when
                // we come back.
                reconsumeIn(char, TokenizerState.afterAttributeName);
                return emitCharacterToken();
              }
              state = TokenizerState.data;
              return emitCurrentTag();
            }
          } else if (_isAsciiAlpha(char)) {
            currentTag!.tagName.writeCharCode(_toLowerAscii(char));
            temporaryBuffer ??= StringBuffer();
            temporaryBuffer!.writeCharCode(char);
            continue;
          }
          bufferCharCode(lessThanSign);
          bufferCharCode(solidus);
          if (temporaryBuffer != null) {
            bufferCharacters(temporaryBuffer!.toString());
            temporaryBuffer = null;
          }
          reconsumeIn(char, TokenizerState.scriptDataEscaped);
          continue;

        case TokenizerState.scriptDataDoubleEscapeStart:
          if (_isHTMLWhitespace(char) ||
              char == solidus ||
              char == greaterThanSign) {
            if (temporaryBuffer.toString() == 'script') {
              state = TokenizerState.scriptDataDoubleEscaped;
            } else {
              state = TokenizerState.scriptDataEscaped;
            }
            bufferCharCode(char);
            continue;
          }
          if (_isAsciiAlpha(char)) {
            temporaryBuffer!.writeCharCode(_toLowerAscii(char));
            bufferCharCode(char);
            continue;
          }
          reconsumeIn(char, TokenizerState.scriptDataEscaped);
          continue;

        case TokenizerState.scriptDataDoubleEscaped:
          if (char == hyphenMinus) {
            state = TokenizerState.scriptDataDoubleEscapedDash;
            bufferCharCode(hyphenMinus);
            continue;
          }
          if (char == lessThanSign) {
            state = TokenizerState.scriptDataDoubleEscapedLessThanSign;
            bufferCharCode(lessThanSign);
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            bufferCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-script-html-comment-like-text parse error.
            reconsumeIn(char, TokenizerState.scriptData);
            continue;
          }
          bufferCharCode(char);
          continue;

        case TokenizerState.scriptDataDoubleEscapedDash:
          if (char == hyphenMinus) {
            state = TokenizerState.scriptDataDoubleEscapedDashDash;
            bufferCharCode(hyphenMinus);
            continue;
          }
          if (char == lessThanSign) {
            state = TokenizerState.scriptDataDoubleEscapedLessThanSign;
            bufferCharCode(lessThanSign);
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            state = TokenizerState.scriptDataDoubleEscaped;
            bufferCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-script-html-comment-like-text parse error.
            reconsumeIn(char, TokenizerState.scriptData);
            continue;
          }
          state = TokenizerState.scriptDataDoubleEscaped;
          bufferCharCode(char);
          continue;

        case TokenizerState.scriptDataDoubleEscapedDashDash:
          if (char == hyphenMinus) {
            bufferCharCode(hyphenMinus);
            continue;
          }
          if (char == lessThanSign) {
            state = TokenizerState.scriptDataDoubleEscapedLessThanSign;
            bufferCharCode(lessThanSign);
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.scriptData;
            bufferCharCode(greaterThanSign);
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            state = TokenizerState.scriptDataDoubleEscaped;
            bufferCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-script-html-comment-like-text parse error.
            reconsumeIn(char, TokenizerState.scriptData);
            continue;
          }
          state = TokenizerState.scriptDataDoubleEscaped;
          bufferCharCode(char);
          continue;

        case TokenizerState.scriptDataDoubleEscapedLessThanSign:
          if (char == solidus) {
            temporaryBuffer = StringBuffer();
            state = TokenizerState.scriptDataDoubleEscapeEnd;
            bufferCharCode(solidus);
            continue;
          }
          reconsumeIn(char, TokenizerState.scriptDataDoubleEscaped);
          continue;

        case TokenizerState.scriptDataDoubleEscapeEnd:
          if (_isHTMLWhitespace(char) ||
              char == solidus ||
              char == greaterThanSign) {
            if (temporaryBuffer.toString() == 'script') {
              state = TokenizerState.scriptDataEscaped;
            } else {
              state = TokenizerState.scriptDataDoubleEscaped;
            }
            bufferCharCode(char);
            continue;
          }
          if (_isAsciiAlpha(char)) {
            temporaryBuffer!.writeCharCode(_toLowerAscii(char));
            bufferCharCode(char);
            continue;
          }
          reconsumeIn(char, TokenizerState.scriptDataDoubleEscaped);
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
          if (_isAsciiUpperAlpha(char)) {
            currentTag!.currentAttribute!.appendToName(_toLowerAscii(char));
            continue;
          }
          if (char == nullChar) {
            currentTag!.currentAttribute!.appendToName(replacementCharacter);
            continue;
          }
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
          if (char == quotationMark) {
            state = TokenizerState.attributeValueDoubleQuoted;
            continue;
          }
          if (char == apostrophe) {
            state = TokenizerState.attributeValueSingleQuoted;
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitCurrentTag();
          }
          reconsumeIn(char, TokenizerState.attributeValueUnquoted);
          continue;
        case TokenizerState.attributeValueDoubleQuoted:
          if (char == quotationMark) {
            currentTag!.finishAttribute();
            state = TokenizerState.afterAttributeValueQuoted;
            continue;
          }
// U+0026 AMPERSAND (&)
// Set the return state to the attribute value (double-quoted) state. Switch to the character reference state.
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            currentTag!.currentAttribute!.appendToValue(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-tag parse error.
            return emitEofToken();
          }
          currentTag!.currentAttribute!.appendToValue(char);
          continue;

        case TokenizerState.attributeValueSingleQuoted:
          if (char == apostrophe) {
            currentTag!.finishAttribute();
            state = TokenizerState.afterAttributeValueQuoted;
            continue;
          }
// U+0026 AMPERSAND (&)
// Set the return state to the attribute value (single-quoted) state. Switch to the character reference state.
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            currentTag!.currentAttribute!.appendToValue(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-tag parse error.
            return emitEofToken();
          }
          currentTag!.currentAttribute!.appendToValue(char);
          continue;

        case TokenizerState.attributeValueUnquoted:
          if (_isHTMLWhitespace(char)) {
            state = TokenizerState.beforeAttributeName;
            continue;
          }
// U+0026 AMPERSAND (&)
// Set the return state to the attribute value (unquoted) state. Switch to the character reference state.
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitCurrentTag();
          }
          if (char == endOfFile) {
            // This is an eof-in-tag parse error.
            return emitEofToken();
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            currentTag!.currentAttribute!.appendToValue(replacementCharacter);
            continue;
          }
          currentTag!.currentAttribute!.appendToValue(char);
          continue;

        case TokenizerState.afterAttributeValueQuoted:
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
          if (char == endOfFile) {
            // This is an eof-in-tag parse error.
            return emitEofToken();
          }
          // This is a missing-whitespace-between-attributes parse error.
          reconsumeIn(char, TokenizerState.beforeAttributeName);
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
          if (input.lookAheadAndConsumeCaseInsensitive("doctype")) {
            state = TokenizerState.doctype;
            if (hasPendingCharacterToken) {
              return emitCharacterToken();
            }
            continue;
          }

// If the next few characters are:

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
          reconsumeIn(char, TokenizerState.comment);
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

        case TokenizerState.doctype:
          if (_isHTMLWhitespace(char)) {
            state = TokenizerState.beforeDoctypeName;
            continue;
          }
          if (char == greaterThanSign) {
            reconsumeIn(char, TokenizerState.beforeDoctypeName);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            beginDoctypeToken();
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          // This is a missing-whitespace-before-doctype-name parse error.
          reconsumeIn(char, TokenizerState.beforeDoctypeName);
          continue;

        case TokenizerState.beforeDoctypeName:
          if (_isHTMLWhitespace(char)) {
            continue;
          }
          if (_isAsciiUpperAlpha(char)) {
            beginDoctypeToken();
            currentDoctype!.name = StringBuffer();
            currentDoctype!.name!.writeCharCode(_toLowerAscii(char));
            state = TokenizerState.doctypeName;
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            beginDoctypeToken();
            currentDoctype!.name = StringBuffer();
            currentDoctype!.name!.writeCharCode(replacementCharacter);
            state = TokenizerState.doctypeName;
            continue;
          }
          if (char == greaterThanSign) {
            // This is a missing-doctype-name parse error.
            beginDoctypeToken();
            currentDoctype!.forceQuirks = true;
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            beginDoctypeToken();
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          beginDoctypeToken();
          currentDoctype!.name = StringBuffer();
          currentDoctype!.name!.writeCharCode(_toLowerAscii(char));
          state = TokenizerState.doctypeName;
          continue;

        case TokenizerState.doctypeName:
          if (_isHTMLWhitespace(char)) {
            state = TokenizerState.afterDoctypeName;
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (_isAsciiUpperAlpha(char)) {
            currentDoctype!.name!.writeCharCode(_toLowerAscii(char));
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            currentDoctype!.name!.writeCharCode(replacementCharacter);
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          currentDoctype!.name!.writeCharCode(char);
          continue;

        case TokenizerState.afterDoctypeName:
          if (_isHTMLWhitespace(char)) {
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          input.push(char);
          if (input.lookAheadAndConsumeCaseInsensitive('public')) {
            state = TokenizerState.afterDoctypePublicKeyword;
            continue;
          }
          if (input.lookAheadAndConsumeCaseInsensitive('system')) {
            state = TokenizerState.afterDoctypeSystemKeyword;
            continue;
          }
          // This is an invalid-character-sequence-after-doctype-name parse error.
          currentDoctype!.forceQuirks = true;
          state = TokenizerState.bogusDoctype;
          continue;

        case TokenizerState.afterDoctypePublicKeyword:
          if (_isHTMLWhitespace(char)) {
            state = TokenizerState.beforeDoctypePublicIdentifier;
            continue;
          }
          if (char == quotationMark) {
            // This is a missing-whitespace-after-doctype-public-keyword parse error.
            currentDoctype!.publicIdentifier = StringBuffer();
            state = TokenizerState.doctypePublicIdentifierDoubleQuoted;
            continue;
          }
          if (char == apostrophe) {
            // This is a missing-whitespace-after-doctype-public-keyword parse error.
            currentDoctype!.publicIdentifier = StringBuffer();
            state = TokenizerState.doctypePublicIdentifierSingleQuoted;
            continue;
          }
          if (char == greaterThanSign) {
            // This is a missing-doctype-public-identifier parse error.
            currentDoctype!.forceQuirks = true;
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          // This is a missing-quote-before-doctype-public-identifier parse error.
          currentDoctype!.forceQuirks = true;
          reconsumeIn(char, TokenizerState.bogusDoctype);
          continue;

        case TokenizerState.beforeDoctypePublicIdentifier:
          if (_isHTMLWhitespace(char)) {
            continue;
          }
          if (char == quotationMark) {
            currentDoctype!.publicIdentifier = StringBuffer();
            state = TokenizerState.doctypePublicIdentifierDoubleQuoted;
            continue;
          }
          if (char == apostrophe) {
            currentDoctype!.publicIdentifier = StringBuffer();
            state = TokenizerState.doctypePublicIdentifierSingleQuoted;
            continue;
          }
          if (char == greaterThanSign) {
            // This is a missing-doctype-public-identifier parse error.
            currentDoctype!.forceQuirks = true;
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          // This is a missing-quote-before-doctype-public-identifier parse error.
          currentDoctype!.forceQuirks = true;
          reconsumeIn(char, TokenizerState.bogusDoctype);
          continue;

        case TokenizerState.doctypePublicIdentifierDoubleQuoted:
          if (char == quotationMark) {
            state = TokenizerState.afterDoctypePublicIdentifier;
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            currentDoctype!.publicIdentifier!
                .writeCharCode(replacementCharacter);
            continue;
          }
          if (char == greaterThanSign) {
            // This is an abrupt-doctype-public-identifier parse error.
            currentDoctype!.forceQuirks = true;
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          currentDoctype!.publicIdentifier!.writeCharCode(char);
          continue;

        case TokenizerState.doctypePublicIdentifierSingleQuoted:
          if (char == apostrophe) {
            state = TokenizerState.afterDoctypePublicIdentifier;
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            currentDoctype!.publicIdentifier!
                .writeCharCode(replacementCharacter);
            continue;
          }
          if (char == greaterThanSign) {
            // This is an abrupt-doctype-public-identifier parse error.
            currentDoctype!.forceQuirks = true;
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          currentDoctype!.publicIdentifier!.writeCharCode(char);
          continue;

        case TokenizerState.afterDoctypePublicIdentifier:
          if (_isHTMLWhitespace(char)) {
            state = TokenizerState.betweenDoctypePublicAndSystemIdentifiers;
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == quotationMark) {
            // This is a missing-whitespace-between-doctype-public-and-system-identifiers parse error.
            currentDoctype!.systemIdentifier = StringBuffer();
            state = TokenizerState.doctypeSystemIdentifierDoubleQuoted;
            continue;
          }
          if (char == apostrophe) {
            // This is a missing-whitespace-between-doctype-public-and-system-identifiers parse error.
            currentDoctype!.systemIdentifier = StringBuffer();
            state = TokenizerState.doctypeSystemIdentifierSingleQuoted;
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          // This is a missing-quote-before-doctype-system-identifier parse error.
          currentDoctype!.forceQuirks = true;
          reconsumeIn(char, TokenizerState.bogusDoctype);
          continue;

        case TokenizerState.betweenDoctypePublicAndSystemIdentifiers:
          if (_isHTMLWhitespace(char)) {
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == quotationMark) {
            currentDoctype!.systemIdentifier = StringBuffer();
            state = TokenizerState.doctypeSystemIdentifierDoubleQuoted;
            continue;
          }
          if (char == apostrophe) {
            currentDoctype!.systemIdentifier = StringBuffer();
            state = TokenizerState.doctypeSystemIdentifierSingleQuoted;
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          // This is a missing-quote-before-doctype-system-identifier parse error.
          currentDoctype!.forceQuirks = true;
          reconsumeIn(char, TokenizerState.bogusDoctype);
          continue;

        case TokenizerState.afterDoctypeSystemKeyword:
          if (_isHTMLWhitespace(char)) {
            state = TokenizerState.beforeDoctypeSystemIdentifier;
            continue;
          }
          if (char == quotationMark) {
            // This is a missing-whitespace-after-doctype-system-keyword parse error.
            currentDoctype!.systemIdentifier = StringBuffer();
            state = TokenizerState.doctypeSystemIdentifierDoubleQuoted;
            continue;
          }
          if (char == apostrophe) {
            // This is a missing-whitespace-after-doctype-system-keyword parse error.
            currentDoctype!.systemIdentifier = StringBuffer();
            state = TokenizerState.doctypeSystemIdentifierSingleQuoted;
            continue;
          }
          if (char == greaterThanSign) {
            // This is a missing-doctype-system-identifier parse error.
            currentDoctype!.forceQuirks = true;
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          // This is a missing-quote-before-doctype-system-identifier parse error.
          currentDoctype!.forceQuirks = true;
          reconsumeIn(char, TokenizerState.bogusDoctype);
          continue;

        case TokenizerState.beforeDoctypeSystemIdentifier:
          if (_isHTMLWhitespace(char)) {
            continue;
          }
          if (char == quotationMark) {
            currentDoctype!.systemIdentifier = StringBuffer();
            state = TokenizerState.doctypeSystemIdentifierDoubleQuoted;
            continue;
          }
          if (char == apostrophe) {
            currentDoctype!.systemIdentifier = StringBuffer();
            state = TokenizerState.doctypeSystemIdentifierSingleQuoted;
            continue;
          }
          if (char == greaterThanSign) {
            // This is a missing-doctype-system-identifier parse error.
            currentDoctype!.forceQuirks = true;
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }

          // This is a missing-quote-before-doctype-system-identifier parse error.
          currentDoctype!.forceQuirks = true;
          reconsumeIn(char, TokenizerState.bogusDoctype);
          continue;

        case TokenizerState.doctypeSystemIdentifierDoubleQuoted:
          if (char == quotationMark) {
            state = TokenizerState.afterDoctypeSystemIdentifier;
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            currentDoctype!.systemIdentifier!
                .writeCharCode(replacementCharacter);
            continue;
          }
          if (char == greaterThanSign) {
            // This is an abrupt-doctype-system-identifier parse error.
            currentDoctype!.forceQuirks = true;
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          currentDoctype!.systemIdentifier!.writeCharCode(char);
          continue;

        case TokenizerState.doctypeSystemIdentifierSingleQuoted:
          if (char == apostrophe) {
            state = TokenizerState.afterDoctypeSystemIdentifier;
            continue;
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            currentDoctype!.systemIdentifier!
                .writeCharCode(replacementCharacter);
            continue;
          }
          if (char == greaterThanSign) {
            // This is an abrupt-doctype-system-identifier parse error.
            currentDoctype!.forceQuirks = true;
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          currentDoctype!.systemIdentifier!.writeCharCode(char);
          continue;

        case TokenizerState.afterDoctypeSystemIdentifier:
          if (_isHTMLWhitespace(char)) {
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == endOfFile) {
            // This is an eof-in-doctype parse error.
            currentDoctype!.forceQuirks = true;
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          // This is an unexpected-character-after-doctype-system-identifier parse error.
          // (This does not set the current DOCTYPE token's force-quirks flag to on.)
          reconsumeIn(char, TokenizerState.bogusDoctype);
          continue;

        case TokenizerState.bogusDoctype:
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            return emitDoctypeToken();
          }
          if (char == nullChar) {
            // This is an unexpected-null-character parse error.
            continue;
          }
          if (char == endOfFile) {
            reconsumeIn(char, TokenizerState.data);
            return emitDoctypeToken();
          }
          continue;

        case TokenizerState.cdataSection:
          if (char == rightSquareBracket) {
            state = TokenizerState.cdataSectionBracket;
            continue;
          }
          if (char == endOfFile) {
            // This is an eof-in-cdata parse error.
            reconsumeIn(char, TokenizerState.data);
            continue;
          }
          bufferCharCode(char);
          continue;

        case TokenizerState.cdataSectionBracket:
          if (char == rightSquareBracket) {
            state = TokenizerState.cdataSectionEnd;
            continue;
          }
          bufferCharCode(rightSquareBracket);
          reconsumeIn(char, TokenizerState.cdataSection);
          continue;

        case TokenizerState.cdataSectionEnd:
          if (char == rightSquareBracket) {
            bufferCharCode(rightSquareBracket);
            continue;
          }
          if (char == greaterThanSign) {
            state = TokenizerState.data;
            continue;
          }
          bufferCharCode(rightSquareBracket);
          bufferCharCode(rightSquareBracket);
          reconsumeIn(char, TokenizerState.cdataSection);
          continue;

        case TokenizerState.characterReference:
          temporaryBuffer = StringBuffer();
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
            bufferCharacters(temporaryBuffer.toString());
            continue;
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
          characterReferenceCode = CharacterReferenceCode();
          if (char == latinSmallLetterX || char == latinCapitalLetterX) {
            temporaryBuffer!.writeCharCode(char);
            state = TokenizerState.hexadecimalCharacterReferenceStart;
            continue;
          }
          reconsumeIn(char, TokenizerState.decimalCharacterReferenceStart);
          continue;

        case TokenizerState.hexadecimalCharacterReferenceStart:
          if (_isAsciiHexDigit(char)) {
            reconsumeIn(char, TokenizerState.hexadecimalCharacterReference);
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
            characterReferenceCode!.addHexDigit(char - 0x30);
            continue;
          }
          if (_isAsciiUpperHexDigit(char)) {
            characterReferenceCode!.addHexDigit(char - 0x37);
            continue;
          }
          if (_isAsciiLowerHexDigit(char)) {
            characterReferenceCode!.addHexDigit(char - 0x57);
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
            characterReferenceCode!.addDecimalDigit(char - 0x30);
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
          int refCode = characterReferenceCode!.value;
          if (refCode == 0x00) {
            // This is a null-character-reference parse error.
            refCode = replacementCharacter;
          }
          if (refCode > 0x10FFFF || characterReferenceCode!.overflowed) {
            // This is a character-reference-outside-unicode-range parse error.
            refCode = replacementCharacter;
          }
          if (_isSurogate(refCode)) {
            //  this is a surrogate-character-reference parse error.
            refCode = replacementCharacter;
          }
          if (_isNoncharacter(refCode)) {
            // then this is a noncharacter-character-reference parse error.
          }
          if (refCode == 0x0D ||
              (_isControl(refCode) && !_isAsciiWhitespace(refCode))) {
            // this is a control-character-reference parse error.
            refCode = const <int, int>{
                  0x80: 0x20AC, // EURO SIGN (€)
                  0x82: 0x201A, // SINGLE LOW-9 QUOTATION MARK (‚)
                  0x83: 0x0192, // LATIN SMALL LETTER F WITH HOOK (ƒ)
                  0x84: 0x201E, // DOUBLE LOW-9 QUOTATION MARK („)
                  0x85: 0x2026, // HORIZONTAL ELLIPSIS (…)
                  0x86: 0x2020, // DAGGER (†)
                  0x87: 0x2021, // DOUBLE DAGGER (‡)
                  0x88: 0x02C6, // MODIFIER LETTER CIRCUMFLEX ACCENT (ˆ)
                  0x89: 0x2030, // PER MILLE SIGN (‰)
                  0x8A: 0x0160, // LATIN CAPITAL LETTER S WITH CARON (Š)
                  0x8B: 0x2039, // SINGLE LEFT-POINTING ANGLE QUOTATION MARK (‹)
                  0x8C: 0x0152, // LATIN CAPITAL LIGATURE OE (Œ)
                  0x8E: 0x017D, // LATIN CAPITAL LETTER Z WITH CARON (Ž)
                  0x91: 0x2018, // LEFT SINGLE QUOTATION MARK (‘)
                  0x92: 0x2019, // RIGHT SINGLE QUOTATION MARK (’)
                  0x93: 0x201C, // LEFT DOUBLE QUOTATION MARK (“)
                  0x94: 0x201D, // RIGHT DOUBLE QUOTATION MARK (”)
                  0x95: 0x2022, // BULLET (•)
                  0x96: 0x2013, // EN DASH (–)
                  0x97: 0x2014, // EM DASH (—)
                  0x98: 0x02DC, // SMALL TILDE (˜)
                  0x99: 0x2122, // TRADE MARK SIGN (™)
                  0x9A: 0x0161, // LATIN SMALL LETTER S WITH CARON (š)
                  0x9B:
                      0x203A, // SINGLE RIGHT-POINTING ANGLE QUOTATION MARK (›)
                  0x9C: 0x0153, // LATIN SMALL LIGATURE OE (œ)
                  0x9E: 0x017E, // LATIN SMALL LETTER Z WITH CARON (ž)
                  0x9F: 0x0178, // LATIN CAPITAL LETTER Y WITH DIAERESIS (Ÿ)
                }[refCode] ??
                refCode;
          }
          temporaryBuffer = StringBuffer();
          temporaryBuffer!.writeCharCode(refCode);
          flushCodePointsAsCharacterReference();
          // FIXME: spec says "switch to" but tests assume "reconsume in"?
          reconsumeInReturnState(char);
          // state = returnState!;
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
