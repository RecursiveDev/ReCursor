// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MessagePart _$MessagePartFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'text':
      return TextPart.fromJson(json);
    case 'toolUse':
      return ToolUsePart.fromJson(json);
    case 'toolResult':
      return ToolResultPart.fromJson(json);
    case 'thinking':
      return ThinkingPart.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'MessagePart',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$MessagePart {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String content) text,
    required TResult Function(
            String tool, Map<String, dynamic> params, String? id)
        toolUse,
    required TResult Function(String toolCallId, ToolResult result) toolResult,
    required TResult Function(String content) thinking,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String content)? text,
    TResult? Function(String tool, Map<String, dynamic> params, String? id)?
        toolUse,
    TResult? Function(String toolCallId, ToolResult result)? toolResult,
    TResult? Function(String content)? thinking,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String content)? text,
    TResult Function(String tool, Map<String, dynamic> params, String? id)?
        toolUse,
    TResult Function(String toolCallId, ToolResult result)? toolResult,
    TResult Function(String content)? thinking,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextPart value) text,
    required TResult Function(ToolUsePart value) toolUse,
    required TResult Function(ToolResultPart value) toolResult,
    required TResult Function(ThinkingPart value) thinking,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextPart value)? text,
    TResult? Function(ToolUsePart value)? toolUse,
    TResult? Function(ToolResultPart value)? toolResult,
    TResult? Function(ThinkingPart value)? thinking,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextPart value)? text,
    TResult Function(ToolUsePart value)? toolUse,
    TResult Function(ToolResultPart value)? toolResult,
    TResult Function(ThinkingPart value)? thinking,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this MessagePart to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessagePartCopyWith<$Res> {
  factory $MessagePartCopyWith(
          MessagePart value, $Res Function(MessagePart) then) =
      _$MessagePartCopyWithImpl<$Res, MessagePart>;
}

/// @nodoc
class _$MessagePartCopyWithImpl<$Res, $Val extends MessagePart>
    implements $MessagePartCopyWith<$Res> {
  _$MessagePartCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$TextPartImplCopyWith<$Res> {
  factory _$$TextPartImplCopyWith(
          _$TextPartImpl value, $Res Function(_$TextPartImpl) then) =
      __$$TextPartImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String content});
}

/// @nodoc
class __$$TextPartImplCopyWithImpl<$Res>
    extends _$MessagePartCopyWithImpl<$Res, _$TextPartImpl>
    implements _$$TextPartImplCopyWith<$Res> {
  __$$TextPartImplCopyWithImpl(
      _$TextPartImpl _value, $Res Function(_$TextPartImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
  }) {
    return _then(_$TextPartImpl(
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TextPartImpl implements TextPart {
  const _$TextPartImpl({required this.content, final String? $type})
      : $type = $type ?? 'text';

  factory _$TextPartImpl.fromJson(Map<String, dynamic> json) =>
      _$$TextPartImplFromJson(json);

  @override
  final String content;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'MessagePart.text(content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TextPartImpl &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, content);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TextPartImplCopyWith<_$TextPartImpl> get copyWith =>
      __$$TextPartImplCopyWithImpl<_$TextPartImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String content) text,
    required TResult Function(
            String tool, Map<String, dynamic> params, String? id)
        toolUse,
    required TResult Function(String toolCallId, ToolResult result) toolResult,
    required TResult Function(String content) thinking,
  }) {
    return text(content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String content)? text,
    TResult? Function(String tool, Map<String, dynamic> params, String? id)?
        toolUse,
    TResult? Function(String toolCallId, ToolResult result)? toolResult,
    TResult? Function(String content)? thinking,
  }) {
    return text?.call(content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String content)? text,
    TResult Function(String tool, Map<String, dynamic> params, String? id)?
        toolUse,
    TResult Function(String toolCallId, ToolResult result)? toolResult,
    TResult Function(String content)? thinking,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextPart value) text,
    required TResult Function(ToolUsePart value) toolUse,
    required TResult Function(ToolResultPart value) toolResult,
    required TResult Function(ThinkingPart value) thinking,
  }) {
    return text(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextPart value)? text,
    TResult? Function(ToolUsePart value)? toolUse,
    TResult? Function(ToolResultPart value)? toolResult,
    TResult? Function(ThinkingPart value)? thinking,
  }) {
    return text?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextPart value)? text,
    TResult Function(ToolUsePart value)? toolUse,
    TResult Function(ToolResultPart value)? toolResult,
    TResult Function(ThinkingPart value)? thinking,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$TextPartImplToJson(
      this,
    );
  }
}

abstract class TextPart implements MessagePart {
  const factory TextPart({required final String content}) = _$TextPartImpl;

  factory TextPart.fromJson(Map<String, dynamic> json) =
      _$TextPartImpl.fromJson;

  String get content;

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TextPartImplCopyWith<_$TextPartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ToolUsePartImplCopyWith<$Res> {
  factory _$$ToolUsePartImplCopyWith(
          _$ToolUsePartImpl value, $Res Function(_$ToolUsePartImpl) then) =
      __$$ToolUsePartImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String tool, Map<String, dynamic> params, String? id});
}

/// @nodoc
class __$$ToolUsePartImplCopyWithImpl<$Res>
    extends _$MessagePartCopyWithImpl<$Res, _$ToolUsePartImpl>
    implements _$$ToolUsePartImplCopyWith<$Res> {
  __$$ToolUsePartImplCopyWithImpl(
      _$ToolUsePartImpl _value, $Res Function(_$ToolUsePartImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tool = null,
    Object? params = null,
    Object? id = freezed,
  }) {
    return _then(_$ToolUsePartImpl(
      tool: null == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String,
      params: null == params
          ? _value._params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolUsePartImpl implements ToolUsePart {
  const _$ToolUsePartImpl(
      {required this.tool,
      required final Map<String, dynamic> params,
      this.id,
      final String? $type})
      : _params = params,
        $type = $type ?? 'toolUse';

  factory _$ToolUsePartImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolUsePartImplFromJson(json);

  @override
  final String tool;
  final Map<String, dynamic> _params;
  @override
  Map<String, dynamic> get params {
    if (_params is EqualUnmodifiableMapView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_params);
  }

  @override
  final String? id;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'MessagePart.toolUse(tool: $tool, params: $params, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolUsePartImpl &&
            (identical(other.tool, tool) || other.tool == tool) &&
            const DeepCollectionEquality().equals(other._params, _params) &&
            (identical(other.id, id) || other.id == id));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, tool, const DeepCollectionEquality().hash(_params), id);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolUsePartImplCopyWith<_$ToolUsePartImpl> get copyWith =>
      __$$ToolUsePartImplCopyWithImpl<_$ToolUsePartImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String content) text,
    required TResult Function(
            String tool, Map<String, dynamic> params, String? id)
        toolUse,
    required TResult Function(String toolCallId, ToolResult result) toolResult,
    required TResult Function(String content) thinking,
  }) {
    return toolUse(tool, params, id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String content)? text,
    TResult? Function(String tool, Map<String, dynamic> params, String? id)?
        toolUse,
    TResult? Function(String toolCallId, ToolResult result)? toolResult,
    TResult? Function(String content)? thinking,
  }) {
    return toolUse?.call(tool, params, id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String content)? text,
    TResult Function(String tool, Map<String, dynamic> params, String? id)?
        toolUse,
    TResult Function(String toolCallId, ToolResult result)? toolResult,
    TResult Function(String content)? thinking,
    required TResult orElse(),
  }) {
    if (toolUse != null) {
      return toolUse(tool, params, id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextPart value) text,
    required TResult Function(ToolUsePart value) toolUse,
    required TResult Function(ToolResultPart value) toolResult,
    required TResult Function(ThinkingPart value) thinking,
  }) {
    return toolUse(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextPart value)? text,
    TResult? Function(ToolUsePart value)? toolUse,
    TResult? Function(ToolResultPart value)? toolResult,
    TResult? Function(ThinkingPart value)? thinking,
  }) {
    return toolUse?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextPart value)? text,
    TResult Function(ToolUsePart value)? toolUse,
    TResult Function(ToolResultPart value)? toolResult,
    TResult Function(ThinkingPart value)? thinking,
    required TResult orElse(),
  }) {
    if (toolUse != null) {
      return toolUse(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolUsePartImplToJson(
      this,
    );
  }
}

abstract class ToolUsePart implements MessagePart {
  const factory ToolUsePart(
      {required final String tool,
      required final Map<String, dynamic> params,
      final String? id}) = _$ToolUsePartImpl;

  factory ToolUsePart.fromJson(Map<String, dynamic> json) =
      _$ToolUsePartImpl.fromJson;

  String get tool;
  Map<String, dynamic> get params;
  String? get id;

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ToolUsePartImplCopyWith<_$ToolUsePartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ToolResultPartImplCopyWith<$Res> {
  factory _$$ToolResultPartImplCopyWith(_$ToolResultPartImpl value,
          $Res Function(_$ToolResultPartImpl) then) =
      __$$ToolResultPartImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String toolCallId, ToolResult result});

  $ToolResultCopyWith<$Res> get result;
}

/// @nodoc
class __$$ToolResultPartImplCopyWithImpl<$Res>
    extends _$MessagePartCopyWithImpl<$Res, _$ToolResultPartImpl>
    implements _$$ToolResultPartImplCopyWith<$Res> {
  __$$ToolResultPartImplCopyWithImpl(
      _$ToolResultPartImpl _value, $Res Function(_$ToolResultPartImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? toolCallId = null,
    Object? result = null,
  }) {
    return _then(_$ToolResultPartImpl(
      toolCallId: null == toolCallId
          ? _value.toolCallId
          : toolCallId // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as ToolResult,
    ));
  }

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ToolResultCopyWith<$Res> get result {
    return $ToolResultCopyWith<$Res>(_value.result, (value) {
      return _then(_value.copyWith(result: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolResultPartImpl implements ToolResultPart {
  const _$ToolResultPartImpl(
      {required this.toolCallId, required this.result, final String? $type})
      : $type = $type ?? 'toolResult';

  factory _$ToolResultPartImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolResultPartImplFromJson(json);

  @override
  final String toolCallId;
  @override
  final ToolResult result;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'MessagePart.toolResult(toolCallId: $toolCallId, result: $result)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolResultPartImpl &&
            (identical(other.toolCallId, toolCallId) ||
                other.toolCallId == toolCallId) &&
            (identical(other.result, result) || other.result == result));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, toolCallId, result);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolResultPartImplCopyWith<_$ToolResultPartImpl> get copyWith =>
      __$$ToolResultPartImplCopyWithImpl<_$ToolResultPartImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String content) text,
    required TResult Function(
            String tool, Map<String, dynamic> params, String? id)
        toolUse,
    required TResult Function(String toolCallId, ToolResult result) toolResult,
    required TResult Function(String content) thinking,
  }) {
    return toolResult(toolCallId, result);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String content)? text,
    TResult? Function(String tool, Map<String, dynamic> params, String? id)?
        toolUse,
    TResult? Function(String toolCallId, ToolResult result)? toolResult,
    TResult? Function(String content)? thinking,
  }) {
    return toolResult?.call(toolCallId, result);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String content)? text,
    TResult Function(String tool, Map<String, dynamic> params, String? id)?
        toolUse,
    TResult Function(String toolCallId, ToolResult result)? toolResult,
    TResult Function(String content)? thinking,
    required TResult orElse(),
  }) {
    if (toolResult != null) {
      return toolResult(toolCallId, result);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextPart value) text,
    required TResult Function(ToolUsePart value) toolUse,
    required TResult Function(ToolResultPart value) toolResult,
    required TResult Function(ThinkingPart value) thinking,
  }) {
    return toolResult(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextPart value)? text,
    TResult? Function(ToolUsePart value)? toolUse,
    TResult? Function(ToolResultPart value)? toolResult,
    TResult? Function(ThinkingPart value)? thinking,
  }) {
    return toolResult?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextPart value)? text,
    TResult Function(ToolUsePart value)? toolUse,
    TResult Function(ToolResultPart value)? toolResult,
    TResult Function(ThinkingPart value)? thinking,
    required TResult orElse(),
  }) {
    if (toolResult != null) {
      return toolResult(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolResultPartImplToJson(
      this,
    );
  }
}

abstract class ToolResultPart implements MessagePart {
  const factory ToolResultPart(
      {required final String toolCallId,
      required final ToolResult result}) = _$ToolResultPartImpl;

  factory ToolResultPart.fromJson(Map<String, dynamic> json) =
      _$ToolResultPartImpl.fromJson;

  String get toolCallId;
  ToolResult get result;

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ToolResultPartImplCopyWith<_$ToolResultPartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ThinkingPartImplCopyWith<$Res> {
  factory _$$ThinkingPartImplCopyWith(
          _$ThinkingPartImpl value, $Res Function(_$ThinkingPartImpl) then) =
      __$$ThinkingPartImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String content});
}

/// @nodoc
class __$$ThinkingPartImplCopyWithImpl<$Res>
    extends _$MessagePartCopyWithImpl<$Res, _$ThinkingPartImpl>
    implements _$$ThinkingPartImplCopyWith<$Res> {
  __$$ThinkingPartImplCopyWithImpl(
      _$ThinkingPartImpl _value, $Res Function(_$ThinkingPartImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
  }) {
    return _then(_$ThinkingPartImpl(
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThinkingPartImpl implements ThinkingPart {
  const _$ThinkingPartImpl({required this.content, final String? $type})
      : $type = $type ?? 'thinking';

  factory _$ThinkingPartImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThinkingPartImplFromJson(json);

  @override
  final String content;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'MessagePart.thinking(content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThinkingPartImpl &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, content);

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThinkingPartImplCopyWith<_$ThinkingPartImpl> get copyWith =>
      __$$ThinkingPartImplCopyWithImpl<_$ThinkingPartImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String content) text,
    required TResult Function(
            String tool, Map<String, dynamic> params, String? id)
        toolUse,
    required TResult Function(String toolCallId, ToolResult result) toolResult,
    required TResult Function(String content) thinking,
  }) {
    return thinking(content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String content)? text,
    TResult? Function(String tool, Map<String, dynamic> params, String? id)?
        toolUse,
    TResult? Function(String toolCallId, ToolResult result)? toolResult,
    TResult? Function(String content)? thinking,
  }) {
    return thinking?.call(content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String content)? text,
    TResult Function(String tool, Map<String, dynamic> params, String? id)?
        toolUse,
    TResult Function(String toolCallId, ToolResult result)? toolResult,
    TResult Function(String content)? thinking,
    required TResult orElse(),
  }) {
    if (thinking != null) {
      return thinking(content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextPart value) text,
    required TResult Function(ToolUsePart value) toolUse,
    required TResult Function(ToolResultPart value) toolResult,
    required TResult Function(ThinkingPart value) thinking,
  }) {
    return thinking(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextPart value)? text,
    TResult? Function(ToolUsePart value)? toolUse,
    TResult? Function(ToolResultPart value)? toolResult,
    TResult? Function(ThinkingPart value)? thinking,
  }) {
    return thinking?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextPart value)? text,
    TResult Function(ToolUsePart value)? toolUse,
    TResult Function(ToolResultPart value)? toolResult,
    TResult Function(ThinkingPart value)? thinking,
    required TResult orElse(),
  }) {
    if (thinking != null) {
      return thinking(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ThinkingPartImplToJson(
      this,
    );
  }
}

abstract class ThinkingPart implements MessagePart {
  const factory ThinkingPart({required final String content}) =
      _$ThinkingPartImpl;

  factory ThinkingPart.fromJson(Map<String, dynamic> json) =
      _$ThinkingPartImpl.fromJson;

  String get content;

  /// Create a copy of MessagePart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThinkingPartImplCopyWith<_$ThinkingPartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ToolResult _$ToolResultFromJson(Map<String, dynamic> json) {
  return _ToolResult.fromJson(json);
}

/// @nodoc
mixin _$ToolResult {
  bool get success => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  int? get durationMs => throw _privateConstructorUsedError;

  /// Serializes this ToolResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ToolResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ToolResultCopyWith<ToolResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolResultCopyWith<$Res> {
  factory $ToolResultCopyWith(
          ToolResult value, $Res Function(ToolResult) then) =
      _$ToolResultCopyWithImpl<$Res, ToolResult>;
  @useResult
  $Res call(
      {bool success,
      String content,
      Map<String, dynamic>? metadata,
      String? error,
      int? durationMs});
}

/// @nodoc
class _$ToolResultCopyWithImpl<$Res, $Val extends ToolResult>
    implements $ToolResultCopyWith<$Res> {
  _$ToolResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ToolResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? content = null,
    Object? metadata = freezed,
    Object? error = freezed,
    Object? durationMs = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMs: freezed == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ToolResultImplCopyWith<$Res>
    implements $ToolResultCopyWith<$Res> {
  factory _$$ToolResultImplCopyWith(
          _$ToolResultImpl value, $Res Function(_$ToolResultImpl) then) =
      __$$ToolResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool success,
      String content,
      Map<String, dynamic>? metadata,
      String? error,
      int? durationMs});
}

/// @nodoc
class __$$ToolResultImplCopyWithImpl<$Res>
    extends _$ToolResultCopyWithImpl<$Res, _$ToolResultImpl>
    implements _$$ToolResultImplCopyWith<$Res> {
  __$$ToolResultImplCopyWithImpl(
      _$ToolResultImpl _value, $Res Function(_$ToolResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of ToolResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? content = null,
    Object? metadata = freezed,
    Object? error = freezed,
    Object? durationMs = freezed,
  }) {
    return _then(_$ToolResultImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMs: freezed == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolResultImpl implements _ToolResult {
  const _$ToolResultImpl(
      {required this.success,
      required this.content,
      final Map<String, dynamic>? metadata,
      this.error,
      this.durationMs})
      : _metadata = metadata;

  factory _$ToolResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolResultImplFromJson(json);

  @override
  final bool success;
  @override
  final String content;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? error;
  @override
  final int? durationMs;

  @override
  String toString() {
    return 'ToolResult(success: $success, content: $content, metadata: $metadata, error: $error, durationMs: $durationMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolResultImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, content,
      const DeepCollectionEquality().hash(_metadata), error, durationMs);

  /// Create a copy of ToolResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolResultImplCopyWith<_$ToolResultImpl> get copyWith =>
      __$$ToolResultImplCopyWithImpl<_$ToolResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolResultImplToJson(
      this,
    );
  }
}

abstract class _ToolResult implements ToolResult {
  const factory _ToolResult(
      {required final bool success,
      required final String content,
      final Map<String, dynamic>? metadata,
      final String? error,
      final int? durationMs}) = _$ToolResultImpl;

  factory _ToolResult.fromJson(Map<String, dynamic> json) =
      _$ToolResultImpl.fromJson;

  @override
  bool get success;
  @override
  String get content;
  @override
  Map<String, dynamic>? get metadata;
  @override
  String? get error;
  @override
  int? get durationMs;

  /// Create a copy of ToolResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ToolResultImplCopyWith<_$ToolResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ToolCall _$ToolCallFromJson(Map<String, dynamic> json) {
  return _ToolCall.fromJson(json);
}

/// @nodoc
mixin _$ToolCall {
  String get id => throw _privateConstructorUsedError;
  String get sessionId => throw _privateConstructorUsedError;
  String get tool => throw _privateConstructorUsedError;
  Map<String, dynamic> get params => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get reasoning => throw _privateConstructorUsedError;
  RiskLevel get riskLevel => throw _privateConstructorUsedError;
  ApprovalDecision get decision => throw _privateConstructorUsedError;
  String? get modifications => throw _privateConstructorUsedError;
  Map<String, dynamic>? get result => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get decidedAt => throw _privateConstructorUsedError;

  /// Serializes this ToolCall to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ToolCall
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ToolCallCopyWith<ToolCall> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolCallCopyWith<$Res> {
  factory $ToolCallCopyWith(ToolCall value, $Res Function(ToolCall) then) =
      _$ToolCallCopyWithImpl<$Res, ToolCall>;
  @useResult
  $Res call(
      {String id,
      String sessionId,
      String tool,
      Map<String, dynamic> params,
      String? description,
      String? reasoning,
      RiskLevel riskLevel,
      ApprovalDecision decision,
      String? modifications,
      Map<String, dynamic>? result,
      DateTime createdAt,
      DateTime? decidedAt});
}

/// @nodoc
class _$ToolCallCopyWithImpl<$Res, $Val extends ToolCall>
    implements $ToolCallCopyWith<$Res> {
  _$ToolCallCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ToolCall
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? tool = null,
    Object? params = null,
    Object? description = freezed,
    Object? reasoning = freezed,
    Object? riskLevel = null,
    Object? decision = null,
    Object? modifications = freezed,
    Object? result = freezed,
    Object? createdAt = null,
    Object? decidedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      tool: null == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String,
      params: null == params
          ? _value.params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      reasoning: freezed == reasoning
          ? _value.reasoning
          : reasoning // ignore: cast_nullable_to_non_nullable
              as String?,
      riskLevel: null == riskLevel
          ? _value.riskLevel
          : riskLevel // ignore: cast_nullable_to_non_nullable
              as RiskLevel,
      decision: null == decision
          ? _value.decision
          : decision // ignore: cast_nullable_to_non_nullable
              as ApprovalDecision,
      modifications: freezed == modifications
          ? _value.modifications
          : modifications // ignore: cast_nullable_to_non_nullable
              as String?,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      decidedAt: freezed == decidedAt
          ? _value.decidedAt
          : decidedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ToolCallImplCopyWith<$Res>
    implements $ToolCallCopyWith<$Res> {
  factory _$$ToolCallImplCopyWith(
          _$ToolCallImpl value, $Res Function(_$ToolCallImpl) then) =
      __$$ToolCallImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String sessionId,
      String tool,
      Map<String, dynamic> params,
      String? description,
      String? reasoning,
      RiskLevel riskLevel,
      ApprovalDecision decision,
      String? modifications,
      Map<String, dynamic>? result,
      DateTime createdAt,
      DateTime? decidedAt});
}

/// @nodoc
class __$$ToolCallImplCopyWithImpl<$Res>
    extends _$ToolCallCopyWithImpl<$Res, _$ToolCallImpl>
    implements _$$ToolCallImplCopyWith<$Res> {
  __$$ToolCallImplCopyWithImpl(
      _$ToolCallImpl _value, $Res Function(_$ToolCallImpl) _then)
      : super(_value, _then);

  /// Create a copy of ToolCall
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? tool = null,
    Object? params = null,
    Object? description = freezed,
    Object? reasoning = freezed,
    Object? riskLevel = null,
    Object? decision = null,
    Object? modifications = freezed,
    Object? result = freezed,
    Object? createdAt = null,
    Object? decidedAt = freezed,
  }) {
    return _then(_$ToolCallImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      tool: null == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String,
      params: null == params
          ? _value._params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      reasoning: freezed == reasoning
          ? _value.reasoning
          : reasoning // ignore: cast_nullable_to_non_nullable
              as String?,
      riskLevel: null == riskLevel
          ? _value.riskLevel
          : riskLevel // ignore: cast_nullable_to_non_nullable
              as RiskLevel,
      decision: null == decision
          ? _value.decision
          : decision // ignore: cast_nullable_to_non_nullable
              as ApprovalDecision,
      modifications: freezed == modifications
          ? _value.modifications
          : modifications // ignore: cast_nullable_to_non_nullable
              as String?,
      result: freezed == result
          ? _value._result
          : result // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      decidedAt: freezed == decidedAt
          ? _value.decidedAt
          : decidedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolCallImpl implements _ToolCall {
  const _$ToolCallImpl(
      {required this.id,
      required this.sessionId,
      required this.tool,
      required final Map<String, dynamic> params,
      this.description,
      this.reasoning,
      this.riskLevel = RiskLevel.low,
      this.decision = ApprovalDecision.pending,
      this.modifications,
      final Map<String, dynamic>? result,
      required this.createdAt,
      this.decidedAt})
      : _params = params,
        _result = result;

  factory _$ToolCallImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolCallImplFromJson(json);

  @override
  final String id;
  @override
  final String sessionId;
  @override
  final String tool;
  final Map<String, dynamic> _params;
  @override
  Map<String, dynamic> get params {
    if (_params is EqualUnmodifiableMapView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_params);
  }

  @override
  final String? description;
  @override
  final String? reasoning;
  @override
  @JsonKey()
  final RiskLevel riskLevel;
  @override
  @JsonKey()
  final ApprovalDecision decision;
  @override
  final String? modifications;
  final Map<String, dynamic>? _result;
  @override
  Map<String, dynamic>? get result {
    final value = _result;
    if (value == null) return null;
    if (_result is EqualUnmodifiableMapView) return _result;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime? decidedAt;

  @override
  String toString() {
    return 'ToolCall(id: $id, sessionId: $sessionId, tool: $tool, params: $params, description: $description, reasoning: $reasoning, riskLevel: $riskLevel, decision: $decision, modifications: $modifications, result: $result, createdAt: $createdAt, decidedAt: $decidedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolCallImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.tool, tool) || other.tool == tool) &&
            const DeepCollectionEquality().equals(other._params, _params) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.reasoning, reasoning) ||
                other.reasoning == reasoning) &&
            (identical(other.riskLevel, riskLevel) ||
                other.riskLevel == riskLevel) &&
            (identical(other.decision, decision) ||
                other.decision == decision) &&
            (identical(other.modifications, modifications) ||
                other.modifications == modifications) &&
            const DeepCollectionEquality().equals(other._result, _result) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.decidedAt, decidedAt) ||
                other.decidedAt == decidedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      sessionId,
      tool,
      const DeepCollectionEquality().hash(_params),
      description,
      reasoning,
      riskLevel,
      decision,
      modifications,
      const DeepCollectionEquality().hash(_result),
      createdAt,
      decidedAt);

  /// Create a copy of ToolCall
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolCallImplCopyWith<_$ToolCallImpl> get copyWith =>
      __$$ToolCallImplCopyWithImpl<_$ToolCallImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolCallImplToJson(
      this,
    );
  }
}

abstract class _ToolCall implements ToolCall {
  const factory _ToolCall(
      {required final String id,
      required final String sessionId,
      required final String tool,
      required final Map<String, dynamic> params,
      final String? description,
      final String? reasoning,
      final RiskLevel riskLevel,
      final ApprovalDecision decision,
      final String? modifications,
      final Map<String, dynamic>? result,
      required final DateTime createdAt,
      final DateTime? decidedAt}) = _$ToolCallImpl;

  factory _ToolCall.fromJson(Map<String, dynamic> json) =
      _$ToolCallImpl.fromJson;

  @override
  String get id;
  @override
  String get sessionId;
  @override
  String get tool;
  @override
  Map<String, dynamic> get params;
  @override
  String? get description;
  @override
  String? get reasoning;
  @override
  RiskLevel get riskLevel;
  @override
  ApprovalDecision get decision;
  @override
  String? get modifications;
  @override
  Map<String, dynamic>? get result;
  @override
  DateTime get createdAt;
  @override
  DateTime? get decidedAt;

  /// Create a copy of ToolCall
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ToolCallImplCopyWith<_$ToolCallImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Message _$MessageFromJson(Map<String, dynamic> json) {
  return _Message.fromJson(json);
}

/// @nodoc
mixin _$Message {
  String get id => throw _privateConstructorUsedError;
  String get sessionId => throw _privateConstructorUsedError;
  MessageRole get role => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  MessageType get type => throw _privateConstructorUsedError;
  List<MessagePart> get parts => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  bool get synced => throw _privateConstructorUsedError;

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call(
      {String id,
      String sessionId,
      MessageRole role,
      String content,
      MessageType type,
      List<MessagePart> parts,
      Map<String, dynamic>? metadata,
      DateTime createdAt,
      DateTime? updatedAt,
      bool synced});
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? role = null,
    Object? content = null,
    Object? type = null,
    Object? parts = null,
    Object? metadata = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? synced = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MessageRole,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MessageType,
      parts: null == parts
          ? _value.parts
          : parts // ignore: cast_nullable_to_non_nullable
              as List<MessagePart>,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      synced: null == synced
          ? _value.synced
          : synced // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
          _$MessageImpl value, $Res Function(_$MessageImpl) then) =
      __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String sessionId,
      MessageRole role,
      String content,
      MessageType type,
      List<MessagePart> parts,
      Map<String, dynamic>? metadata,
      DateTime createdAt,
      DateTime? updatedAt,
      bool synced});
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
      _$MessageImpl _value, $Res Function(_$MessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? role = null,
    Object? content = null,
    Object? type = null,
    Object? parts = null,
    Object? metadata = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? synced = null,
  }) {
    return _then(_$MessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MessageRole,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MessageType,
      parts: null == parts
          ? _value._parts
          : parts // ignore: cast_nullable_to_non_nullable
              as List<MessagePart>,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      synced: null == synced
          ? _value.synced
          : synced // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageImpl implements _Message {
  const _$MessageImpl(
      {required this.id,
      required this.sessionId,
      required this.role,
      required this.content,
      required this.type,
      required final List<MessagePart> parts,
      final Map<String, dynamic>? metadata,
      required this.createdAt,
      this.updatedAt,
      this.synced = true})
      : _parts = parts,
        _metadata = metadata;

  factory _$MessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageImplFromJson(json);

  @override
  final String id;
  @override
  final String sessionId;
  @override
  final MessageRole role;
  @override
  final String content;
  @override
  final MessageType type;
  final List<MessagePart> _parts;
  @override
  List<MessagePart> get parts {
    if (_parts is EqualUnmodifiableListView) return _parts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parts);
  }

  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  @JsonKey()
  final bool synced;

  @override
  String toString() {
    return 'Message(id: $id, sessionId: $sessionId, role: $role, content: $content, type: $type, parts: $parts, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt, synced: $synced)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._parts, _parts) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.synced, synced) || other.synced == synced));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      sessionId,
      role,
      content,
      type,
      const DeepCollectionEquality().hash(_parts),
      const DeepCollectionEquality().hash(_metadata),
      createdAt,
      updatedAt,
      synced);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageImplToJson(
      this,
    );
  }
}

abstract class _Message implements Message {
  const factory _Message(
      {required final String id,
      required final String sessionId,
      required final MessageRole role,
      required final String content,
      required final MessageType type,
      required final List<MessagePart> parts,
      final Map<String, dynamic>? metadata,
      required final DateTime createdAt,
      final DateTime? updatedAt,
      final bool synced}) = _$MessageImpl;

  factory _Message.fromJson(Map<String, dynamic> json) = _$MessageImpl.fromJson;

  @override
  String get id;
  @override
  String get sessionId;
  @override
  MessageRole get role;
  @override
  String get content;
  @override
  MessageType get type;
  @override
  List<MessagePart> get parts;
  @override
  Map<String, dynamic>? get metadata;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  bool get synced;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
