import 'dart:convert';
import 'package:html6/src/tokenizer.dart';

void main(List<String> arguments) {
  var input = InputManager("foo<bar>baz");
  var tokenizer = Tokenizer(input);
  var tokens = tokenizer.getTokensWithoutEOF();
  var actualJson =
      json.encode(tokens.map((token) => token.toTestJson()).toList());
  print(actualJson);
}
