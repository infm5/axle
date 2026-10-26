// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Person {

 String get name; int? get age; String get role;@JsonKey(name: 'e_mail') String? get email; List<String> get tags;
/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonCopyWith<Person> get copyWith => _$PersonCopyWithImpl<Person>(this as Person, _$identity);

  /// Serializes this Person to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Person&&(identical(other.name, name) || other.name == name)&&(identical(other.age, age) || other.age == age)&&(identical(other.role, role) || other.role == role)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,age,role,email,const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'Person(name: $name, age: $age, role: $role, email: $email, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $PersonCopyWith<$Res>  {
  factory $PersonCopyWith(Person value, $Res Function(Person) _then) = _$PersonCopyWithImpl;
@useResult
$Res call({
 String name, int? age, String role,@JsonKey(name: 'e_mail') String? email, List<String> tags
});




}
/// @nodoc
class _$PersonCopyWithImpl<$Res>
    implements $PersonCopyWith<$Res> {
  _$PersonCopyWithImpl(this._self, this._then);

  final Person _self;
  final $Res Function(Person) _then;

/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? age = freezed,Object? role = null,Object? email = freezed,Object? tags = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Person].
extension PersonPatterns on Person {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Person value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Person() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Person value)  $default,){
final _that = this;
switch (_that) {
case _Person():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Person value)?  $default,){
final _that = this;
switch (_that) {
case _Person() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int? age,  String role, @JsonKey(name: 'e_mail')  String? email,  List<String> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Person() when $default != null:
return $default(_that.name,_that.age,_that.role,_that.email,_that.tags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int? age,  String role, @JsonKey(name: 'e_mail')  String? email,  List<String> tags)  $default,) {final _that = this;
switch (_that) {
case _Person():
return $default(_that.name,_that.age,_that.role,_that.email,_that.tags);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int? age,  String role, @JsonKey(name: 'e_mail')  String? email,  List<String> tags)?  $default,) {final _that = this;
switch (_that) {
case _Person() when $default != null:
return $default(_that.name,_that.age,_that.role,_that.email,_that.tags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Person implements Person {
  const _Person({required this.name, this.age, this.role = 'guest', @JsonKey(name: 'e_mail') this.email, final  List<String> tags = const <String>[]}): _tags = tags;
  factory _Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

@override final  String name;
@override final  int? age;
@override@JsonKey() final  String role;
@override@JsonKey(name: 'e_mail') final  String? email;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonCopyWith<_Person> get copyWith => __$PersonCopyWithImpl<_Person>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Person&&(identical(other.name, name) || other.name == name)&&(identical(other.age, age) || other.age == age)&&(identical(other.role, role) || other.role == role)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,age,role,email,const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'Person(name: $name, age: $age, role: $role, email: $email, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$PersonCopyWith<$Res> implements $PersonCopyWith<$Res> {
  factory _$PersonCopyWith(_Person value, $Res Function(_Person) _then) = __$PersonCopyWithImpl;
@override @useResult
$Res call({
 String name, int? age, String role,@JsonKey(name: 'e_mail') String? email, List<String> tags
});




}
/// @nodoc
class __$PersonCopyWithImpl<$Res>
    implements _$PersonCopyWith<$Res> {
  __$PersonCopyWithImpl(this._self, this._then);

  final _Person _self;
  final $Res Function(_Person) _then;

/// Create a copy of Person
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? age = freezed,Object? role = null,Object? email = freezed,Object? tags = null,}) {
  return _then(_Person(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

Shape _$ShapeFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'circle':
          return Circle.fromJson(
            json
          );
                case 'sq':
          return Square.fromJson(
            json
          );
                case 'polygon':
          return Polygon.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'Shape',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$Shape {



  /// Serializes this Shape to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shape);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Shape()';
}


}

/// @nodoc
class $ShapeCopyWith<$Res>  {
$ShapeCopyWith(Shape _, $Res Function(Shape) __);
}


/// Adds pattern-matching-related methods to [Shape].
extension ShapePatterns on Shape {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Circle value)?  circle,TResult Function( Square value)?  square,TResult Function( Polygon value)?  polygon,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Circle() when circle != null:
return circle(_that);case Square() when square != null:
return square(_that);case Polygon() when polygon != null:
return polygon(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Circle value)  circle,required TResult Function( Square value)  square,required TResult Function( Polygon value)  polygon,}){
final _that = this;
switch (_that) {
case Circle():
return circle(_that);case Square():
return square(_that);case Polygon():
return polygon(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Circle value)?  circle,TResult? Function( Square value)?  square,TResult? Function( Polygon value)?  polygon,}){
final _that = this;
switch (_that) {
case Circle() when circle != null:
return circle(_that);case Square() when square != null:
return square(_that);case Polygon() when polygon != null:
return polygon(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( double radius)?  circle,TResult Function( double side)?  square,TResult Function( int sides,  bool regular)?  polygon,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Circle() when circle != null:
return circle(_that.radius);case Square() when square != null:
return square(_that.side);case Polygon() when polygon != null:
return polygon(_that.sides,_that.regular);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( double radius)  circle,required TResult Function( double side)  square,required TResult Function( int sides,  bool regular)  polygon,}) {final _that = this;
switch (_that) {
case Circle():
return circle(_that.radius);case Square():
return square(_that.side);case Polygon():
return polygon(_that.sides,_that.regular);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( double radius)?  circle,TResult? Function( double side)?  square,TResult? Function( int sides,  bool regular)?  polygon,}) {final _that = this;
switch (_that) {
case Circle() when circle != null:
return circle(_that.radius);case Square() when square != null:
return square(_that.side);case Polygon() when polygon != null:
return polygon(_that.sides,_that.regular);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class Circle implements Shape {
  const Circle(this.radius, {final  String? $type}): $type = $type ?? 'circle';
  factory Circle.fromJson(Map<String, dynamic> json) => _$CircleFromJson(json);

 final  double radius;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Shape
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CircleCopyWith<Circle> get copyWith => _$CircleCopyWithImpl<Circle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CircleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Circle&&(identical(other.radius, radius) || other.radius == radius));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,radius);

@override
String toString() {
  return 'Shape.circle(radius: $radius)';
}


}

/// @nodoc
abstract mixin class $CircleCopyWith<$Res> implements $ShapeCopyWith<$Res> {
  factory $CircleCopyWith(Circle value, $Res Function(Circle) _then) = _$CircleCopyWithImpl;
@useResult
$Res call({
 double radius
});




}
/// @nodoc
class _$CircleCopyWithImpl<$Res>
    implements $CircleCopyWith<$Res> {
  _$CircleCopyWithImpl(this._self, this._then);

  final Circle _self;
  final $Res Function(Circle) _then;

/// Create a copy of Shape
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? radius = null,}) {
  return _then(Circle(
null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Square implements Shape {
  const Square({required this.side, final  String? $type}): $type = $type ?? 'sq';
  factory Square.fromJson(Map<String, dynamic> json) => _$SquareFromJson(json);

 final  double side;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Shape
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SquareCopyWith<Square> get copyWith => _$SquareCopyWithImpl<Square>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SquareToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Square&&(identical(other.side, side) || other.side == side));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,side);

@override
String toString() {
  return 'Shape.square(side: $side)';
}


}

/// @nodoc
abstract mixin class $SquareCopyWith<$Res> implements $ShapeCopyWith<$Res> {
  factory $SquareCopyWith(Square value, $Res Function(Square) _then) = _$SquareCopyWithImpl;
@useResult
$Res call({
 double side
});




}
/// @nodoc
class _$SquareCopyWithImpl<$Res>
    implements $SquareCopyWith<$Res> {
  _$SquareCopyWithImpl(this._self, this._then);

  final Square _self;
  final $Res Function(Square) _then;

/// Create a copy of Shape
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? side = null,}) {
  return _then(Square(
side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Polygon implements Shape {
  const Polygon({required this.sides, this.regular = false, final  String? $type}): $type = $type ?? 'polygon';
  factory Polygon.fromJson(Map<String, dynamic> json) => _$PolygonFromJson(json);

 final  int sides;
@JsonKey() final  bool regular;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Shape
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PolygonCopyWith<Polygon> get copyWith => _$PolygonCopyWithImpl<Polygon>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PolygonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Polygon&&(identical(other.sides, sides) || other.sides == sides)&&(identical(other.regular, regular) || other.regular == regular));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sides,regular);

@override
String toString() {
  return 'Shape.polygon(sides: $sides, regular: $regular)';
}


}

/// @nodoc
abstract mixin class $PolygonCopyWith<$Res> implements $ShapeCopyWith<$Res> {
  factory $PolygonCopyWith(Polygon value, $Res Function(Polygon) _then) = _$PolygonCopyWithImpl;
@useResult
$Res call({
 int sides, bool regular
});




}
/// @nodoc
class _$PolygonCopyWithImpl<$Res>
    implements $PolygonCopyWith<$Res> {
  _$PolygonCopyWithImpl(this._self, this._then);

  final Polygon _self;
  final $Res Function(Polygon) _then;

/// Create a copy of Shape
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sides = null,Object? regular = null,}) {
  return _then(Polygon(
sides: null == sides ? _self.sides : sides // ignore: cast_nullable_to_non_nullable
as int,regular: null == regular ? _self.regular : regular // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
