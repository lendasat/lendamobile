// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lendasat_api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AuthResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String userId, String userName, String? userEmail)
        success,
    required TResult Function(String pubkey) needsRegistration,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String userId, String userName, String? userEmail)?
        success,
    TResult? Function(String pubkey)? needsRegistration,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String userId, String userName, String? userEmail)?
        success,
    TResult Function(String pubkey)? needsRegistration,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthResult_Success value) success,
    required TResult Function(AuthResult_NeedsRegistration value)
        needsRegistration,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthResult_Success value)? success,
    TResult? Function(AuthResult_NeedsRegistration value)? needsRegistration,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthResult_Success value)? success,
    TResult Function(AuthResult_NeedsRegistration value)? needsRegistration,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResultCopyWith<$Res> {
  factory $AuthResultCopyWith(
          AuthResult value, $Res Function(AuthResult) then) =
      _$AuthResultCopyWithImpl<$Res, AuthResult>;
}

/// @nodoc
class _$AuthResultCopyWithImpl<$Res, $Val extends AuthResult>
    implements $AuthResultCopyWith<$Res> {
  _$AuthResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AuthResult_SuccessImplCopyWith<$Res> {
  factory _$$AuthResult_SuccessImplCopyWith(_$AuthResult_SuccessImpl value,
          $Res Function(_$AuthResult_SuccessImpl) then) =
      __$$AuthResult_SuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String userId, String userName, String? userEmail});
}

/// @nodoc
class __$$AuthResult_SuccessImplCopyWithImpl<$Res>
    extends _$AuthResultCopyWithImpl<$Res, _$AuthResult_SuccessImpl>
    implements _$$AuthResult_SuccessImplCopyWith<$Res> {
  __$$AuthResult_SuccessImplCopyWithImpl(_$AuthResult_SuccessImpl _value,
      $Res Function(_$AuthResult_SuccessImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? userEmail = freezed,
  }) {
    return _then(_$AuthResult_SuccessImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      userEmail: freezed == userEmail
          ? _value.userEmail
          : userEmail // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$AuthResult_SuccessImpl extends AuthResult_Success {
  const _$AuthResult_SuccessImpl(
      {required this.userId, required this.userName, this.userEmail})
      : super._();

  @override
  final String userId;
  @override
  final String userName;
  @override
  final String? userEmail;

  @override
  String toString() {
    return 'AuthResult.success(userId: $userId, userName: $userName, userEmail: $userEmail)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResult_SuccessImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userEmail, userEmail) ||
                other.userEmail == userEmail));
  }

  @override
  int get hashCode => Object.hash(runtimeType, userId, userName, userEmail);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResult_SuccessImplCopyWith<_$AuthResult_SuccessImpl> get copyWith =>
      __$$AuthResult_SuccessImplCopyWithImpl<_$AuthResult_SuccessImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String userId, String userName, String? userEmail)
        success,
    required TResult Function(String pubkey) needsRegistration,
  }) {
    return success(userId, userName, userEmail);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String userId, String userName, String? userEmail)?
        success,
    TResult? Function(String pubkey)? needsRegistration,
  }) {
    return success?.call(userId, userName, userEmail);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String userId, String userName, String? userEmail)?
        success,
    TResult Function(String pubkey)? needsRegistration,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(userId, userName, userEmail);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthResult_Success value) success,
    required TResult Function(AuthResult_NeedsRegistration value)
        needsRegistration,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthResult_Success value)? success,
    TResult? Function(AuthResult_NeedsRegistration value)? needsRegistration,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthResult_Success value)? success,
    TResult Function(AuthResult_NeedsRegistration value)? needsRegistration,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class AuthResult_Success extends AuthResult {
  const factory AuthResult_Success(
      {required final String userId,
      required final String userName,
      final String? userEmail}) = _$AuthResult_SuccessImpl;
  const AuthResult_Success._() : super._();

  String get userId;
  String get userName;
  String? get userEmail;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthResult_SuccessImplCopyWith<_$AuthResult_SuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AuthResult_NeedsRegistrationImplCopyWith<$Res> {
  factory _$$AuthResult_NeedsRegistrationImplCopyWith(
          _$AuthResult_NeedsRegistrationImpl value,
          $Res Function(_$AuthResult_NeedsRegistrationImpl) then) =
      __$$AuthResult_NeedsRegistrationImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String pubkey});
}

/// @nodoc
class __$$AuthResult_NeedsRegistrationImplCopyWithImpl<$Res>
    extends _$AuthResultCopyWithImpl<$Res, _$AuthResult_NeedsRegistrationImpl>
    implements _$$AuthResult_NeedsRegistrationImplCopyWith<$Res> {
  __$$AuthResult_NeedsRegistrationImplCopyWithImpl(
      _$AuthResult_NeedsRegistrationImpl _value,
      $Res Function(_$AuthResult_NeedsRegistrationImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pubkey = null,
  }) {
    return _then(_$AuthResult_NeedsRegistrationImpl(
      pubkey: null == pubkey
          ? _value.pubkey
          : pubkey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$AuthResult_NeedsRegistrationImpl extends AuthResult_NeedsRegistration {
  const _$AuthResult_NeedsRegistrationImpl({required this.pubkey}) : super._();

  @override
  final String pubkey;

  @override
  String toString() {
    return 'AuthResult.needsRegistration(pubkey: $pubkey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResult_NeedsRegistrationImpl &&
            (identical(other.pubkey, pubkey) || other.pubkey == pubkey));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pubkey);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResult_NeedsRegistrationImplCopyWith<
          _$AuthResult_NeedsRegistrationImpl>
      get copyWith => __$$AuthResult_NeedsRegistrationImplCopyWithImpl<
          _$AuthResult_NeedsRegistrationImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String userId, String userName, String? userEmail)
        success,
    required TResult Function(String pubkey) needsRegistration,
  }) {
    return needsRegistration(pubkey);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String userId, String userName, String? userEmail)?
        success,
    TResult? Function(String pubkey)? needsRegistration,
  }) {
    return needsRegistration?.call(pubkey);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String userId, String userName, String? userEmail)?
        success,
    TResult Function(String pubkey)? needsRegistration,
    required TResult orElse(),
  }) {
    if (needsRegistration != null) {
      return needsRegistration(pubkey);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthResult_Success value) success,
    required TResult Function(AuthResult_NeedsRegistration value)
        needsRegistration,
  }) {
    return needsRegistration(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthResult_Success value)? success,
    TResult? Function(AuthResult_NeedsRegistration value)? needsRegistration,
  }) {
    return needsRegistration?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthResult_Success value)? success,
    TResult Function(AuthResult_NeedsRegistration value)? needsRegistration,
    required TResult orElse(),
  }) {
    if (needsRegistration != null) {
      return needsRegistration(this);
    }
    return orElse();
  }
}

abstract class AuthResult_NeedsRegistration extends AuthResult {
  const factory AuthResult_NeedsRegistration({required final String pubkey}) =
      _$AuthResult_NeedsRegistrationImpl;
  const AuthResult_NeedsRegistration._() : super._();

  String get pubkey;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthResult_NeedsRegistrationImplCopyWith<
          _$AuthResult_NeedsRegistrationImpl>
      get copyWith => throw _privateConstructorUsedError;
}
