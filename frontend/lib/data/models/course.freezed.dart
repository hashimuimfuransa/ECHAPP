// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Course _$CourseFromJson(Map<String, dynamic> json) {
  return _Course.fromJson(json);
}

/// @nodoc
mixin _$Course {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  int get duration => throw _privateConstructorUsedError;
  String get level => throw _privateConstructorUsedError;
  String? get thumbnail => throw _privateConstructorUsedError;
  bool get isPublished => throw _privateConstructorUsedError;
  User get createdBy => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  Map<String, dynamic>? get category => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Course to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Course
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CourseCopyWith<Course> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CourseCopyWith<$Res> {
  factory $CourseCopyWith(Course value, $Res Function(Course) then) =
      _$CourseCopyWithImpl<$Res, Course>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      double price,
      int duration,
      String level,
      String? thumbnail,
      bool isPublished,
      User createdBy,
      String? categoryId,
      Map<String, dynamic>? category,
      DateTime createdAt});
}

/// @nodoc
class _$CourseCopyWithImpl<$Res, $Val extends Course>
    implements $CourseCopyWith<$Res> {
  _$CourseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Course
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? price = null,
    Object? duration = null,
    Object? level = null,
    Object? thumbnail = freezed,
    Object? isPublished = null,
    Object? createdBy = null,
    Object? categoryId = freezed,
    Object? category = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String?,
      isPublished: null == isPublished
          ? _value.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as User,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CourseImplCopyWith<$Res> implements $CourseCopyWith<$Res> {
  factory _$$CourseImplCopyWith(
          _$CourseImpl value, $Res Function(_$CourseImpl) then) =
      __$$CourseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      double price,
      int duration,
      String level,
      String? thumbnail,
      bool isPublished,
      User createdBy,
      String? categoryId,
      Map<String, dynamic>? category,
      DateTime createdAt});
}

/// @nodoc
class __$$CourseImplCopyWithImpl<$Res>
    extends _$CourseCopyWithImpl<$Res, _$CourseImpl>
    implements _$$CourseImplCopyWith<$Res> {
  __$$CourseImplCopyWithImpl(
      _$CourseImpl _value, $Res Function(_$CourseImpl) _then)
      : super(_value, _then);

  /// Create a copy of Course
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? price = null,
    Object? duration = null,
    Object? level = null,
    Object? thumbnail = freezed,
    Object? isPublished = null,
    Object? createdBy = null,
    Object? categoryId = freezed,
    Object? category = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$CourseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String?,
      isPublished: null == isPublished
          ? _value.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as User,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value._category
          : category // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CourseImpl implements _Course {
  const _$CourseImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.price,
      required this.duration,
      required this.level,
      this.thumbnail,
      required this.isPublished,
      required this.createdBy,
      this.categoryId,
      final Map<String, dynamic>? category,
      required this.createdAt})
      : _category = category;

  factory _$CourseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CourseImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final double price;
  @override
  final int duration;
  @override
  final String level;
  @override
  final String? thumbnail;
  @override
  final bool isPublished;
  @override
  final User createdBy;
  @override
  final String? categoryId;
  final Map<String, dynamic>? _category;
  @override
  Map<String, dynamic>? get category {
    final value = _category;
    if (value == null) return null;
    if (_category is EqualUnmodifiableMapView) return _category;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Course(id: $id, title: $title, description: $description, price: $price, duration: $duration, level: $level, thumbnail: $thumbnail, isPublished: $isPublished, createdBy: $createdBy, categoryId: $categoryId, category: $category, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CourseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail) &&
            (identical(other.isPublished, isPublished) ||
                other.isPublished == isPublished) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            const DeepCollectionEquality().equals(other._category, _category) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      price,
      duration,
      level,
      thumbnail,
      isPublished,
      createdBy,
      categoryId,
      const DeepCollectionEquality().hash(_category),
      createdAt);

  /// Create a copy of Course
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CourseImplCopyWith<_$CourseImpl> get copyWith =>
      __$$CourseImplCopyWithImpl<_$CourseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CourseImplToJson(
      this,
    );
  }
}

abstract class _Course implements Course {
  const factory _Course(
      {required final String id,
      required final String title,
      required final String description,
      required final double price,
      required final int duration,
      required final String level,
      final String? thumbnail,
      required final bool isPublished,
      required final User createdBy,
      final String? categoryId,
      final Map<String, dynamic>? category,
      required final DateTime createdAt}) = _$CourseImpl;

  factory _Course.fromJson(Map<String, dynamic> json) = _$CourseImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  double get price;
  @override
  int get duration;
  @override
  String get level;
  @override
  String? get thumbnail;
  @override
  bool get isPublished;
  @override
  User get createdBy;
  @override
  String? get categoryId;
  @override
  Map<String, dynamic>? get category;
  @override
  DateTime get createdAt;

  /// Create a copy of Course
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CourseImplCopyWith<_$CourseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CourseListResponse _$CourseListResponseFromJson(Map<String, dynamic> json) {
  return _CourseListResponse.fromJson(json);
}

/// @nodoc
mixin _$CourseListResponse {
  List<Course> get courses => throw _privateConstructorUsedError;
  int get totalPages => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;

  /// Serializes this CourseListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CourseListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CourseListResponseCopyWith<CourseListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CourseListResponseCopyWith<$Res> {
  factory $CourseListResponseCopyWith(
          CourseListResponse value, $Res Function(CourseListResponse) then) =
      _$CourseListResponseCopyWithImpl<$Res, CourseListResponse>;
  @useResult
  $Res call({List<Course> courses, int totalPages, int currentPage, int total});
}

/// @nodoc
class _$CourseListResponseCopyWithImpl<$Res, $Val extends CourseListResponse>
    implements $CourseListResponseCopyWith<$Res> {
  _$CourseListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CourseListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? courses = null,
    Object? totalPages = null,
    Object? currentPage = null,
    Object? total = null,
  }) {
    return _then(_value.copyWith(
      courses: null == courses
          ? _value.courses
          : courses // ignore: cast_nullable_to_non_nullable
              as List<Course>,
      totalPages: null == totalPages
          ? _value.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CourseListResponseImplCopyWith<$Res>
    implements $CourseListResponseCopyWith<$Res> {
  factory _$$CourseListResponseImplCopyWith(_$CourseListResponseImpl value,
          $Res Function(_$CourseListResponseImpl) then) =
      __$$CourseListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Course> courses, int totalPages, int currentPage, int total});
}

/// @nodoc
class __$$CourseListResponseImplCopyWithImpl<$Res>
    extends _$CourseListResponseCopyWithImpl<$Res, _$CourseListResponseImpl>
    implements _$$CourseListResponseImplCopyWith<$Res> {
  __$$CourseListResponseImplCopyWithImpl(_$CourseListResponseImpl _value,
      $Res Function(_$CourseListResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of CourseListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? courses = null,
    Object? totalPages = null,
    Object? currentPage = null,
    Object? total = null,
  }) {
    return _then(_$CourseListResponseImpl(
      courses: null == courses
          ? _value._courses
          : courses // ignore: cast_nullable_to_non_nullable
              as List<Course>,
      totalPages: null == totalPages
          ? _value.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CourseListResponseImpl implements _CourseListResponse {
  const _$CourseListResponseImpl(
      {required final List<Course> courses,
      required this.totalPages,
      required this.currentPage,
      required this.total})
      : _courses = courses;

  factory _$CourseListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CourseListResponseImplFromJson(json);

  final List<Course> _courses;
  @override
  List<Course> get courses {
    if (_courses is EqualUnmodifiableListView) return _courses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_courses);
  }

  @override
  final int totalPages;
  @override
  final int currentPage;
  @override
  final int total;

  @override
  String toString() {
    return 'CourseListResponse(courses: $courses, totalPages: $totalPages, currentPage: $currentPage, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CourseListResponseImpl &&
            const DeepCollectionEquality().equals(other._courses, _courses) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.total, total) || other.total == total));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_courses),
      totalPages,
      currentPage,
      total);

  /// Create a copy of CourseListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CourseListResponseImplCopyWith<_$CourseListResponseImpl> get copyWith =>
      __$$CourseListResponseImplCopyWithImpl<_$CourseListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CourseListResponseImplToJson(
      this,
    );
  }
}

abstract class _CourseListResponse implements CourseListResponse {
  const factory _CourseListResponse(
      {required final List<Course> courses,
      required final int totalPages,
      required final int currentPage,
      required final int total}) = _$CourseListResponseImpl;

  factory _CourseListResponse.fromJson(Map<String, dynamic> json) =
      _$CourseListResponseImpl.fromJson;

  @override
  List<Course> get courses;
  @override
  int get totalPages;
  @override
  int get currentPage;
  @override
  int get total;

  /// Create a copy of CourseListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CourseListResponseImplCopyWith<_$CourseListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Enrollment _$EnrollmentFromJson(Map<String, dynamic> json) {
  return _Enrollment.fromJson(json);
}

/// @nodoc
mixin _$Enrollment {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get courseId => throw _privateConstructorUsedError;
  DateTime get enrollmentDate => throw _privateConstructorUsedError;
  String get completionStatus => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;
  List<String> get completedLessons => throw _privateConstructorUsedError;
  bool get certificateEligible => throw _privateConstructorUsedError;

  /// Serializes this Enrollment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Enrollment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EnrollmentCopyWith<Enrollment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnrollmentCopyWith<$Res> {
  factory $EnrollmentCopyWith(
          Enrollment value, $Res Function(Enrollment) then) =
      _$EnrollmentCopyWithImpl<$Res, Enrollment>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String courseId,
      DateTime enrollmentDate,
      String completionStatus,
      double progress,
      List<String> completedLessons,
      bool certificateEligible});
}

/// @nodoc
class _$EnrollmentCopyWithImpl<$Res, $Val extends Enrollment>
    implements $EnrollmentCopyWith<$Res> {
  _$EnrollmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Enrollment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? courseId = null,
    Object? enrollmentDate = null,
    Object? completionStatus = null,
    Object? progress = null,
    Object? completedLessons = null,
    Object? certificateEligible = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      courseId: null == courseId
          ? _value.courseId
          : courseId // ignore: cast_nullable_to_non_nullable
              as String,
      enrollmentDate: null == enrollmentDate
          ? _value.enrollmentDate
          : enrollmentDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      completionStatus: null == completionStatus
          ? _value.completionStatus
          : completionStatus // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      completedLessons: null == completedLessons
          ? _value.completedLessons
          : completedLessons // ignore: cast_nullable_to_non_nullable
              as List<String>,
      certificateEligible: null == certificateEligible
          ? _value.certificateEligible
          : certificateEligible // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EnrollmentImplCopyWith<$Res>
    implements $EnrollmentCopyWith<$Res> {
  factory _$$EnrollmentImplCopyWith(
          _$EnrollmentImpl value, $Res Function(_$EnrollmentImpl) then) =
      __$$EnrollmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String courseId,
      DateTime enrollmentDate,
      String completionStatus,
      double progress,
      List<String> completedLessons,
      bool certificateEligible});
}

/// @nodoc
class __$$EnrollmentImplCopyWithImpl<$Res>
    extends _$EnrollmentCopyWithImpl<$Res, _$EnrollmentImpl>
    implements _$$EnrollmentImplCopyWith<$Res> {
  __$$EnrollmentImplCopyWithImpl(
      _$EnrollmentImpl _value, $Res Function(_$EnrollmentImpl) _then)
      : super(_value, _then);

  /// Create a copy of Enrollment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? courseId = null,
    Object? enrollmentDate = null,
    Object? completionStatus = null,
    Object? progress = null,
    Object? completedLessons = null,
    Object? certificateEligible = null,
  }) {
    return _then(_$EnrollmentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      courseId: null == courseId
          ? _value.courseId
          : courseId // ignore: cast_nullable_to_non_nullable
              as String,
      enrollmentDate: null == enrollmentDate
          ? _value.enrollmentDate
          : enrollmentDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      completionStatus: null == completionStatus
          ? _value.completionStatus
          : completionStatus // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      completedLessons: null == completedLessons
          ? _value._completedLessons
          : completedLessons // ignore: cast_nullable_to_non_nullable
              as List<String>,
      certificateEligible: null == certificateEligible
          ? _value.certificateEligible
          : certificateEligible // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EnrollmentImpl implements _Enrollment {
  const _$EnrollmentImpl(
      {required this.id,
      required this.userId,
      required this.courseId,
      required this.enrollmentDate,
      required this.completionStatus,
      required this.progress,
      required final List<String> completedLessons,
      required this.certificateEligible})
      : _completedLessons = completedLessons;

  factory _$EnrollmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnrollmentImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String courseId;
  @override
  final DateTime enrollmentDate;
  @override
  final String completionStatus;
  @override
  final double progress;
  final List<String> _completedLessons;
  @override
  List<String> get completedLessons {
    if (_completedLessons is EqualUnmodifiableListView)
      return _completedLessons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedLessons);
  }

  @override
  final bool certificateEligible;

  @override
  String toString() {
    return 'Enrollment(id: $id, userId: $userId, courseId: $courseId, enrollmentDate: $enrollmentDate, completionStatus: $completionStatus, progress: $progress, completedLessons: $completedLessons, certificateEligible: $certificateEligible)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnrollmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.courseId, courseId) ||
                other.courseId == courseId) &&
            (identical(other.enrollmentDate, enrollmentDate) ||
                other.enrollmentDate == enrollmentDate) &&
            (identical(other.completionStatus, completionStatus) ||
                other.completionStatus == completionStatus) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            const DeepCollectionEquality()
                .equals(other._completedLessons, _completedLessons) &&
            (identical(other.certificateEligible, certificateEligible) ||
                other.certificateEligible == certificateEligible));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      courseId,
      enrollmentDate,
      completionStatus,
      progress,
      const DeepCollectionEquality().hash(_completedLessons),
      certificateEligible);

  /// Create a copy of Enrollment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EnrollmentImplCopyWith<_$EnrollmentImpl> get copyWith =>
      __$$EnrollmentImplCopyWithImpl<_$EnrollmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EnrollmentImplToJson(
      this,
    );
  }
}

abstract class _Enrollment implements Enrollment {
  const factory _Enrollment(
      {required final String id,
      required final String userId,
      required final String courseId,
      required final DateTime enrollmentDate,
      required final String completionStatus,
      required final double progress,
      required final List<String> completedLessons,
      required final bool certificateEligible}) = _$EnrollmentImpl;

  factory _Enrollment.fromJson(Map<String, dynamic> json) =
      _$EnrollmentImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get courseId;
  @override
  DateTime get enrollmentDate;
  @override
  String get completionStatus;
  @override
  double get progress;
  @override
  List<String> get completedLessons;
  @override
  bool get certificateEligible;

  /// Create a copy of Enrollment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EnrollmentImplCopyWith<_$EnrollmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
