// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lendasat_api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthResult {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthResult);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthResult()';
  }
}

/// @nodoc
class $AuthResultCopyWith<$Res> {
  $AuthResultCopyWith(AuthResult _, $Res Function(AuthResult) __);
}

/// Adds pattern-matching-related methods to [AuthResult].
extension AuthResultPatterns on AuthResult {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthResult_Success value)? success,
    TResult Function(AuthResult_NeedsRegistration value)? needsRegistration,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AuthResult_Success() when success != null:
        return success(_that);
      case AuthResult_NeedsRegistration() when needsRegistration != null:
        return needsRegistration(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthResult_Success value) success,
    required TResult Function(AuthResult_NeedsRegistration value)
        needsRegistration,
  }) {
    final _that = this;
    switch (_that) {
      case AuthResult_Success():
        return success(_that);
      case AuthResult_NeedsRegistration():
        return needsRegistration(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthResult_Success value)? success,
    TResult? Function(AuthResult_NeedsRegistration value)? needsRegistration,
  }) {
    final _that = this;
    switch (_that) {
      case AuthResult_Success() when success != null:
        return success(_that);
      case AuthResult_NeedsRegistration() when needsRegistration != null:
        return needsRegistration(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String userId, String userName, String? userEmail)?
        success,
    TResult Function(String pubkey)? needsRegistration,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AuthResult_Success() when success != null:
        return success(_that.userId, _that.userName, _that.userEmail);
      case AuthResult_NeedsRegistration() when needsRegistration != null:
        return needsRegistration(_that.pubkey);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String userId, String userName, String? userEmail)
        success,
    required TResult Function(String pubkey) needsRegistration,
  }) {
    final _that = this;
    switch (_that) {
      case AuthResult_Success():
        return success(_that.userId, _that.userName, _that.userEmail);
      case AuthResult_NeedsRegistration():
        return needsRegistration(_that.pubkey);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String userId, String userName, String? userEmail)?
        success,
    TResult? Function(String pubkey)? needsRegistration,
  }) {
    final _that = this;
    switch (_that) {
      case AuthResult_Success() when success != null:
        return success(_that.userId, _that.userName, _that.userEmail);
      case AuthResult_NeedsRegistration() when needsRegistration != null:
        return needsRegistration(_that.pubkey);
      case _:
        return null;
    }
  }
}

/// @nodoc

class AuthResult_Success extends AuthResult {
  const AuthResult_Success(
      {required this.userId, required this.userName, this.userEmail})
      : super._();

  final String userId;
  final String userName;
  final String? userEmail;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuthResult_SuccessCopyWith<AuthResult_Success> get copyWith =>
      _$AuthResult_SuccessCopyWithImpl<AuthResult_Success>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthResult_Success &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userEmail, userEmail) ||
                other.userEmail == userEmail));
  }

  @override
  int get hashCode => Object.hash(runtimeType, userId, userName, userEmail);

  @override
  String toString() {
    return 'AuthResult.success(userId: $userId, userName: $userName, userEmail: $userEmail)';
  }
}

/// @nodoc
abstract mixin class $AuthResult_SuccessCopyWith<$Res>
    implements $AuthResultCopyWith<$Res> {
  factory $AuthResult_SuccessCopyWith(
          AuthResult_Success value, $Res Function(AuthResult_Success) _then) =
      _$AuthResult_SuccessCopyWithImpl;
  @useResult
  $Res call({String userId, String userName, String? userEmail});
}

/// @nodoc
class _$AuthResult_SuccessCopyWithImpl<$Res>
    implements $AuthResult_SuccessCopyWith<$Res> {
  _$AuthResult_SuccessCopyWithImpl(this._self, this._then);

  final AuthResult_Success _self;
  final $Res Function(AuthResult_Success) _then;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? userEmail = freezed,
  }) {
    return _then(AuthResult_Success(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _self.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      userEmail: freezed == userEmail
          ? _self.userEmail
          : userEmail // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class AuthResult_NeedsRegistration extends AuthResult {
  const AuthResult_NeedsRegistration({required this.pubkey}) : super._();

  final String pubkey;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuthResult_NeedsRegistrationCopyWith<AuthResult_NeedsRegistration>
      get copyWith => _$AuthResult_NeedsRegistrationCopyWithImpl<
          AuthResult_NeedsRegistration>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthResult_NeedsRegistration &&
            (identical(other.pubkey, pubkey) || other.pubkey == pubkey));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pubkey);

  @override
  String toString() {
    return 'AuthResult.needsRegistration(pubkey: $pubkey)';
  }
}

/// @nodoc
abstract mixin class $AuthResult_NeedsRegistrationCopyWith<$Res>
    implements $AuthResultCopyWith<$Res> {
  factory $AuthResult_NeedsRegistrationCopyWith(
          AuthResult_NeedsRegistration value,
          $Res Function(AuthResult_NeedsRegistration) _then) =
      _$AuthResult_NeedsRegistrationCopyWithImpl;
  @useResult
  $Res call({String pubkey});
}

/// @nodoc
class _$AuthResult_NeedsRegistrationCopyWithImpl<$Res>
    implements $AuthResult_NeedsRegistrationCopyWith<$Res> {
  _$AuthResult_NeedsRegistrationCopyWithImpl(this._self, this._then);

  final AuthResult_NeedsRegistration _self;
  final $Res Function(AuthResult_NeedsRegistration) _then;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pubkey = null,
  }) {
    return _then(AuthResult_NeedsRegistration(
      pubkey: null == pubkey
          ? _self.pubkey
          : pubkey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
