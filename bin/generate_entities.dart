import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:path/path.dart' as p;

part 'generate_entities.g.dart';

// FIXME: Should probably just check-in?
var jsonUrl = "https://html.spec.whatwg.org/entities.json";

@JsonSerializable(createToJson: false)
class EntityEntry {
  final List<int> codepoints;
  final String characters;

  EntityEntry(this.codepoints, this.characters);

  factory EntityEntry.fromJson(Map<String, dynamic> json) =>
      _$EntityEntryFromJson(json);
}

String generateEntitiesCode(String scriptName, Map<String, EntityEntry> map) {
  StringBuffer output = StringBuffer();
  int longestName = 0;

  var sortedNames = map.keys.toList();
  sortedNames.sort();

  output.writeln("""
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from $jsonUrl
// Generated by $scriptName

part of 'entities.dart';
""");

  output.writeln("var entities = const [");
  for (var name in sortedNames) {
    longestName = max(longestName, name.length);
    EntityEntry entry = map[name]!;
    var runes = name.runes.toList();
    output.writeln("  Entity(\"$name\", $runes, ${entry.codepoints}),");
  }
  output.writeln("];");
  output.writeln("");
  output.writeln("var maxEntityLength = $longestName;");
  return output.toString();
}

void main() async {
  var scriptPath = p.canonicalize(Platform.script.toFilePath());
  var scriptName = p.basename(scriptPath);
  var inputDir = p.dirname(scriptPath);
  var entitiesFile = File(p.join(inputDir, 'entities.json'));

  var map = json
      .decode(entitiesFile.readAsStringSync())
      .map<String, EntityEntry>(
          (String key, value) => MapEntry(key, EntityEntry.fromJson(value)));

  var rootPath = p.dirname(p.dirname(scriptPath));
  var outputPath = p.join(rootPath, 'lib', 'src', 'entities.g.dart');
  var output = File(outputPath);

  output.writeAsString(generateEntitiesCode(scriptName, map));
}
