import 'package:flutter_test/flutter_test.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/section.dart';

void main() {
  group('Lesson Revelation Logic Tests', () {
    late List<Lesson> testLessons;
    late Map<String, bool> completionStatus;

    setUp(() {
      testLessons = [
        Lesson(
          id: 'lesson1',
          sectionId: 'section1',
          courseId: 'course1',
          title: 'Lesson 1: Introduction',
          order: 1,
          duration: 10,
        ),
        Lesson(
          id: 'lesson2',
          sectionId: 'section1',
          courseId: 'course1',
          title: 'Lesson 2: Basics',
          order: 2,
          duration: 15,
        ),
        Lesson(
          id: 'lesson3',
          sectionId: 'section1',
          courseId: 'course1',
          title: 'Lesson 3: Advanced',
          order: 3,
          duration: 20,
        ),
        Lesson(
          id: 'lesson4',
          sectionId: 'section1',
          courseId: 'course1',
          title: 'Lesson 4: Mastery',
          order: 4,
          duration: 25,
        ),
      ];
      
      completionStatus = {};
    }

    test('Should show only first lesson when no lessons are completed', () {
      completionStatus = {};
      
      final visibleLessons = getVisibleLessons(testLessons, completionStatus);
      
      expect(visibleLessons.length, 1);
      expect(visibleLessons[0].id, 'lesson1');
    });

    test('Should show first two lessons when first lesson is completed', () {
      completionStatus = {'lesson1': true};
      
      final visibleLessons = getVisibleLessons(testLessons, completionStatus);
      
      expect(visibleLessons.length, 2);
      expect(visibleLessons[0].id, 'lesson1');
      expect(visibleLessons[1].id, 'lesson2');
    });

    test('Should show first three lessons when first two lessons are completed', () {
      completionStatus = {'lesson1': true, 'lesson2': true};
      
      final visibleLessons = getVisibleLessons(testLessons, completionStatus);
      
      expect(visibleLessons.length, 3);
      expect(visibleLessons[0].id, 'lesson1');
      expect(visibleLessons[1].id, 'lesson2');
      expect(visibleLessons[2].id, 'lesson3');
    });

    test('Should show all lessons when all previous lessons are completed', () {
      completionStatus = {'lesson1': true, 'lesson2': true, 'lesson3': true};
      
      final visibleLessons = getVisibleLessons(testLessons, completionStatus);
      
      expect(visibleLessons.length, 4);
      expect(visibleLessons[0].id, 'lesson1');
      expect(visibleLessons[1].id, 'lesson2');
      expect(visibleLessons[2].id, 'lesson3');
      expect(visibleLessons[3].id, 'lesson4');
    });

    test('Should not show lesson 3 when lesson 2 is not completed, even if lesson 1 is completed', () {
      completionStatus = {'lesson1': true};
      
      final visibleLessons = getVisibleLessons(testLessons, completionStatus);
      
      expect(visibleLessons.length, 2);
      expect(visibleLessons.any((l) => l.id == 'lesson3'), false);
    });

    test('Should show more button when there are hidden lessons', () {
      completionStatus = {'lesson1': true};
      
      final shouldShow = shouldShowMoreButton(testLessons, completionStatus, true);
      final hiddenCount = getHiddenLessonCount(testLessons, completionStatus, true);
      
      expect(shouldShow, true);
      expect(hiddenCount, 2); // lesson3 and lesson4 are hidden
    });

    test('Should not show more button when all lessons are visible', () {
      completionStatus = {'lesson1': true, 'lesson2': true, 'lesson3': true};
      
      final shouldShow = shouldShowMoreButton(testLessons, completionStatus, true);
      final hiddenCount = getHiddenLessonCount(testLessons, completionStatus, true);
      
      expect(shouldShow, false);
      expect(hiddenCount, 0);
    });

    test('Should not show more button in non-compact mode', () {
      completionStatus = {'lesson1': true};
      
      final shouldShow = shouldShowMoreButton(testLessons, completionStatus, false);
      
      expect(shouldShow, false);
    });
  });
}

// Helper functions that mirror the logic in the actual widget
List<Lesson> getVisibleLessons(List<Lesson> lessons, Map<String, bool> lessonCompletionStatus) {
  if (lessons.isEmpty) return lessons;
  
  List<Lesson> visibleLessons = [];
  
  for (int i = 0; i < lessons.length; i++) {
    final lesson = lessons[i];
    
    // Always show the first lesson
    if (i == 0) {
      visibleLessons.add(lesson);
      continue;
    }
    
    // Check if previous lesson is completed
    final previousLesson = lessons[i - 1];
    final isPreviousCompleted = lessonCompletionStatus[previousLesson.id] == true;
    
    if (isPreviousCompleted) {
      visibleLessons.add(lesson);
    } else {
      // Stop at the first incomplete lesson
      break;
    }
  }
  
  return visibleLessons;
}

bool shouldShowMoreButton(List<Lesson> lessons, Map<String, bool> lessonCompletionStatus, bool isCompact) {
  if (!isCompact || lessons.length <= 2) return false;
  
  final visibleLessons = getVisibleLessons(lessons, lessonCompletionStatus);
  final hiddenCount = lessons.length - visibleLessons.length;
  
  return hiddenCount > 0;
}

int getHiddenLessonCount(List<Lesson> lessons, Map<String, bool> lessonCompletionStatus, bool isCompact) {
  if (!isCompact) return 0;
  
  final visibleLessons = getVisibleLessons(lessons, lessonCompletionStatus);
  return lessons.length - visibleLessons.length;
}
