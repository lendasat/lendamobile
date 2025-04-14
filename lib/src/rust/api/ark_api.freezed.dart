// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ark_api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TestEnum {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() test,
    required TResult Function(int test) test2,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? test,
    TResult? Function(int test)? test2,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? test,
    TResult Function(int test)? test2,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TestEnum_Test value) test,
    required TResult Function(TestEnum_Test2 value) test2,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TestEnum_Test value)? test,
    TResult? Function(TestEnum_Test2 value)? test2,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TestEnum_Test value)? test,
    TResult Function(TestEnum_Test2 value)? test2,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TestEnumCopyWith<$Res> {
  factory $TestEnumCopyWith(TestEnum value, $Res Function(TestEnum) then) =
      _$TestEnumCopyWithImpl<$Res, TestEnum>;
}

/// @nodoc
class _$TestEnumCopyWithImpl<$Res, $Val extends TestEnum>
    implements $TestEnumCopyWith<$Res> {
  _$TestEnumCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TestEnum
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$TestEnum_TestImplCopyWith<$Res> {
  factory _$$TestEnum_TestImplCopyWith(
          _$TestEnum_TestImpl value, $Res Function(_$TestEnum_TestImpl) then) =
      __$$TestEnum_TestImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TestEnum_TestImplCopyWithImpl<$Res>
    extends _$TestEnumCopyWithImpl<$Res, _$TestEnum_TestImpl>
    implements _$$TestEnum_TestImplCopyWith<$Res> {
  __$$TestEnum_TestImplCopyWithImpl(
      _$TestEnum_TestImpl _value, $Res Function(_$TestEnum_TestImpl) _then)
      : super(_value, _then);

  /// Create a copy of TestEnum
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$TestEnum_TestImpl extends TestEnum_Test {
  const _$TestEnum_TestImpl() : super._();

  @override
  String toString() {
    return 'TestEnum.test()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$TestEnum_TestImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() test,
    required TResult Function(int test) test2,
  }) {
    return test();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? test,
    TResult? Function(int test)? test2,
  }) {
    return test?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? test,
    TResult Function(int test)? test2,
    required TResult orElse(),
  }) {
    if (test != null) {
      return test();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TestEnum_Test value) test,
    required TResult Function(TestEnum_Test2 value) test2,
  }) {
    return test(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TestEnum_Test value)? test,
    TResult? Function(TestEnum_Test2 value)? test2,
  }) {
    return test?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TestEnum_Test value)? test,
    TResult Function(TestEnum_Test2 value)? test2,
    required TResult orElse(),
  }) {
    if (test != null) {
      return test(this);
    }
    return orElse();
  }
}

abstract class TestEnum_Test extends TestEnum {
  const factory TestEnum_Test() = _$TestEnum_TestImpl;
  const TestEnum_Test._() : super._();
}

/// @nodoc
abstract class _$$TestEnum_Test2ImplCopyWith<$Res> {
  factory _$$TestEnum_Test2ImplCopyWith(_$TestEnum_Test2Impl value,
          $Res Function(_$TestEnum_Test2Impl) then) =
      __$$TestEnum_Test2ImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int test});
}

/// @nodoc
class __$$TestEnum_Test2ImplCopyWithImpl<$Res>
    extends _$TestEnumCopyWithImpl<$Res, _$TestEnum_Test2Impl>
    implements _$$TestEnum_Test2ImplCopyWith<$Res> {
  __$$TestEnum_Test2ImplCopyWithImpl(
      _$TestEnum_Test2Impl _value, $Res Function(_$TestEnum_Test2Impl) _then)
      : super(_value, _then);

  /// Create a copy of TestEnum
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? test = null,
  }) {
    return _then(_$TestEnum_Test2Impl(
      test: null == test
          ? _value.test
          : test // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$TestEnum_Test2Impl extends TestEnum_Test2 {
  const _$TestEnum_Test2Impl({required this.test}) : super._();

  @override
  final int test;

  @override
  String toString() {
    return 'TestEnum.test2(test: $test)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TestEnum_Test2Impl &&
            (identical(other.test, test) || other.test == test));
  }

  @override
  int get hashCode => Object.hash(runtimeType, test);

  /// Create a copy of TestEnum
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TestEnum_Test2ImplCopyWith<_$TestEnum_Test2Impl> get copyWith =>
      __$$TestEnum_Test2ImplCopyWithImpl<_$TestEnum_Test2Impl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() test,
    required TResult Function(int test) test2,
  }) {
    return test2(this.test);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? test,
    TResult? Function(int test)? test2,
  }) {
    return test2?.call(this.test);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? test,
    TResult Function(int test)? test2,
    required TResult orElse(),
  }) {
    if (test2 != null) {
      return test2(this.test);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TestEnum_Test value) test,
    required TResult Function(TestEnum_Test2 value) test2,
  }) {
    return test2(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TestEnum_Test value)? test,
    TResult? Function(TestEnum_Test2 value)? test2,
  }) {
    return test2?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TestEnum_Test value)? test,
    TResult Function(TestEnum_Test2 value)? test2,
    required TResult orElse(),
  }) {
    if (test2 != null) {
      return test2(this);
    }
    return orElse();
  }
}

abstract class TestEnum_Test2 extends TestEnum {
  const factory TestEnum_Test2({required final int test}) =
      _$TestEnum_Test2Impl;
  const TestEnum_Test2._() : super._();

  int get test;

  /// Create a copy of TestEnum
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TestEnum_Test2ImplCopyWith<_$TestEnum_Test2Impl> get copyWith =>
      throw _privateConstructorUsedError;
}
