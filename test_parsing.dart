void main() {
  // Simulate the backend response
  final response = {
    "success": true,
    "message": "Course content retrieved successfully",
    "data": {
      "course": {
        "_id": "6981c9c71554ca1462412076",
        "title": "artificial intelligent",
        "description": "ai",
        "price": 2000,
        "duration": 20,
        "level": "beginner",
        "thumbnail":
            "https://echcoahing.s3.amazonaws.com/images/scaled_33-1770285898412-8d7646b2b3f247bd.jpg",
        "isPublished": true,
        "createdBy": "6980a8c54345355ff5998aa6",
        "category": "6980c9eaf99bce4cc1776282",
        "createdAt": "2026-02-03T10:11:19.446Z",
        "updatedAt": "2026-02-05T10:05:37.110Z",
        "__v": 0,
        "learningObjectives": ["none"],
        "requirements": ["none"]
      },
      "sections": [
        {
          "_id": "69847c52c67e9182f0a7a446",
          "courseId": "6981c9c71554ca1462412076",
          "title": "introduction to ai",
          "order": 1,
          "createdAt": "2026-02-05T11:17:38.238Z",
          "updatedAt": "2026-02-05T11:17:38.238Z",
          "__v": 0,
          "lessons": [
            {
              "_id": "6984979c56f7fbedd7642ec6",
              "sectionId": "69847c52c67e9182f0a7a446",
              "courseId": "6981c9c71554ca1462412076",
              "title": "Untitled Video",
              "videoId": "videos/34-1770297227498-3566aa5d2cbd1a36.mp4",
              "notes": null,
              "order": 1,
              "duration": 0,
              "createdAt": "2026-02-05T13:14:04.948Z",
              "updatedAt": "2026-02-05T13:14:04.948Z",
              "__v": 0
            },
            {
              "_id": "698497a456f7fbedd7642ecd",
              "sectionId": "69847c52c67e9182f0a7a446",
              "courseId": "6981c9c71554ca1462412076",
              "title": "ai first video",
              "description": "learn ai",
              "videoId": "videos/34-1770297227498-3566aa5d2cbd1a36.mp4",
              "notes": "",
              "order": 2,
              "duration": 10,
              "createdAt": "2026-02-05T13:14:12.676Z",
              "updatedAt": "2026-02-05T13:14:12.676Z",
              "__v": 0
            }
          ]
        },
        {
          "_id": "698588331fc3c32024904701",
          "courseId": "6981c9c71554ca1462412076",
          "title": "ai",
          "order": 1,
          "createdAt": "2026-02-06T06:20:35.924Z",
          "updatedAt": "2026-02-06T06:20:35.924Z",
          "__v": 0,
          "lessons": []
        }
      ]
    }
  };

  // Simulate _parseCourseContent function
  Map<String, dynamic> parseCourseContent(dynamic json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        // Return the entire data object which contains both 'course' and 'sections'
        return data;
      }
    }
    return {'sections': []}; // Return empty sections array instead of empty map
  }

  // Test the parsing
  final courseContent = parseCourseContent(response);
  print('Parsed courseContent: $courseContent');
  
  final sectionsData = courseContent['sections'] as List? ?? [];
  print('Sections data: $sectionsData');
  print('Sections length: ${sectionsData.length}');
  
  // Parse sections
  final sections = <Map<String, dynamic>>[];
  for (var sectionData in sectionsData) {
    if (sectionData is Map<String, dynamic>) {
      sections.add({
        'id': sectionData['_id']?.toString() ?? sectionData['id']?.toString() ?? '',
        'title': sectionData['title']?.toString() ?? '',
        'lessonsCount': (sectionData['lessons'] as List? ?? []).length,
      });
    }
  }
  
  print('Parsed sections: $sections');
}