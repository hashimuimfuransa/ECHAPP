import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../lib/models/lesson.dart';
import '../lib/models/section.dart';
import '../lib/data/repositories/lesson_repository.dart';
import '../lib/services/api/section_service.dart';

@GenerateMocks([SectionService])
void main() {
  group('Professional Learning Flow Tests', () {
    late MockSectionService mockSectionService;
    late LessonRepository lessonRepository;

    setUp(() {
      mockSectionService = MockSectionService();
      lessonRepository = LessonRepository(sectionService: mockSectionService);
    });

    test('Lesson model supports new fields', () {
      // Test that Lesson model can handle new professional structure
      final lesson = Lesson(
        id: '1',
        sectionId: 'section1',
        courseId: 'course1',
        title: 'Test Lesson',
        description: 'Test Description',
        videoId: 'video1',
        notes: 'Test notes',
        notesPdfUrl: 'pdf1',
        order: 1,
        duration: 30,
        quizId: 'quiz1', // New field
        materials: ['material1', 'material2'], // New field
        lessonType: 'Mixed', // New field
        isPublished: true, // New field
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test helper methods
      expect(lesson.hasVideo, isTrue);
      expect(lesson.hasNotes, isTrue);
      expect(lesson.hasQuiz, isTrue);
      expect(lesson.hasMaterials, isTrue);
      expect(lesson.displayType, equals('Mixed'));
      expect(lesson.availableMaterials, contains('Video'));
      expect(lesson.availableMaterials, contains('Notes'));
      expect(lesson.availableMaterials, contains('Quiz'));
    });

    test('Section model supports chapter features', () {
      // Test that Section model can handle chapter-like features
      final section = Section(
        id: '1',
        courseId: 'course1',
        title: 'Chapter 1',
        order: 1,
        description: 'Chapter description', // New field
        isPublished: true, // New field
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        objectives: ['Objective 1', 'Objective 2'], // New field
      );

      expect(section.displayName, equals('Chapter 1: Chapter 1'));
      expect(section.isChapter, isTrue);
    });

    test('Lesson repository supports new fields in createLesson', () async {
      // Test that repository passes new fields to service
      when(mockSectionService.createLesson(
        courseId: anyNamed('courseId'),
        sectionId: anyNamed('sectionId'),
        title: anyNamed('title'),
        description: anyNamed('description'),
        videoId: anyNamed('videoId'),
        notes: anyNamed('notes'),
        notesPdfUrl: anyNamed('notesPdfUrl'),
        processNotes: anyNamed('processNotes'),
        order: anyNamed('order'),
        duration: anyNamed('duration'),
        quizId: anyNamed('quizId'), // Verify new field is passed
        materials: anyNamed('materials'), // Verify new field is passed
        lessonType: anyNamed('lessonType'), // Verify new field is passed
        isPublished: anyNamed('isPublished'), // Verify new field is passed
      )).thenAnswer((_) async => Lesson(
        id: '1',
        sectionId: 'section1',
        courseId: 'course1',
        title: 'Test Lesson',
        order: 1,
        duration: 30,
      ));

      await lessonRepository.createLesson(
        courseId: 'course1',
        sectionId: 'section1',
        title: 'Test Lesson',
        quizId: 'quiz1',
        materials: ['material1'],
        lessonType: 'Mixed',
        isPublished: true,
        order: 1,
        duration: 30,
      );

      verify(mockSectionService.createLesson(
        courseId: 'course1',
        sectionId: 'section1',
        title: 'Test Lesson',
        quizId: 'quiz1',
        materials: ['material1'],
        lessonType: 'Mixed',
        isPublished: true,
        order: 1,
        duration: 30,
      )).called(1);
    });

    test('Lesson repository supports getLessonById', () async {
      // Test that repository can get lesson by ID
      final mockLesson = Lesson(
        id: '1',
        sectionId: 'section1',
        courseId: 'course1',
        title: 'Test Lesson',
        order: 1,
        duration: 30,
        quizId: 'quiz1',
      );

      when(mockSectionService.getLessonById('1')).thenAnswer((_) async => {
        'success': true,
        'data': mockLesson.toJson(),
      });

      final result = await lessonRepository.getLessonById('1');

      expect(result, isNotNull);
      expect(result!.id, equals('1'));
      expect(result.quizId, equals('quiz1'));

      verify(mockSectionService.getLessonById('1')).called(1);
    });
  });
}
