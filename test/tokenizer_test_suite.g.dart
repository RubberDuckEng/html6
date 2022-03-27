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

TokenizerTest _$TokenizerTestFromJson(Map<String, dynamic> json) =>
    TokenizerTest(
      json['description'] as String,
      (json['initialStates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      json['lastStartTag'] as String?,
      json['input'] as String,
      outputFromJson(json['output'] as List),
      (json['errors'] as List<dynamic>?)
              ?.map((e) => TokenizerError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
