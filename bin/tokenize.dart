import 'dart:convert';
import 'package:html6/src/tokenizer.dart';

void main(List<String> arguments) {
  var inputText =
      "<!DOCTYPE html SYSTEM '-//W3C//DTD HTML Transitional 4.01//EN'>";
  var input = InputManager(inputText);
  var tokenizer = Tokenizer(input);
  var tokens = tokenizer.getTokensWithoutEOF();
  var actualJson =
      json.encode(tokens.map((token) => token.toTestJson()).toList());
  print(actualJson);
}
