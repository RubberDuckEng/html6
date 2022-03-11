// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tokenizer_test_suite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenizerError _$TokenizerErrorFromJson(Map<String, dynamic> json) =>
    TokenizerError(
      json['code'] as String,
      json['line'] as int,
      json['col'] as int,
    );

Map<String, dynamic> _$TokenizerErrorToJson(TokenizerError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'line': instance.line,
      'col': instance.col,
    };

TokenizerTest _$TokenizerTestFromJson(Map<String, dynamic> json) =>
    TokenizerTest(
      json['description'] as String,
      json['input'] as String,
      (json['errors'] as List<dynamic>?)
              ?.map((e) => TokenizerError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TokenizerTestToJson(TokenizerTest instance) =>
    <String, dynamic>{
      'description': instance.description,
      'input': instance.input,
      'errors': instance.errors,
    };
