class Question {
  final String id;
  final String examId;
  final String question;
  final String type;
  final String? questionImage;
  final String? questionAudio;
  final String? questionVideo;
  final List<Option>? options;
  final List<DragDropItem>? dragDropItems;
  final List<DropZone>? dropZones;
  final List<MatchingPair>? matchingPairs;
  final List<OrderItem>? correctOrder;
  final List<Hotspot>? hotspots;
  final String? hotspotImage;
  final dynamic correctAnswer;
  final int points;
  final bool partialCredit;
  final String? explanation;
  final String? difficulty;
  final String? category;
  final List<String>? tags;
  final int timeLimit;
  final int maxAttempts;
  final bool randomizeOptions;
  final String? section;

  Question({
    required this.id,
    required this.examId,
    required this.question,
    required this.type,
    this.questionImage,
    this.questionAudio,
    this.questionVideo,
    this.options,
    this.dragDropItems,
    this.dropZones,
    this.matchingPairs,
    this.correctOrder,
    this.hotspots,
    this.hotspotImage,
    this.correctAnswer,
    this.points = 1,
    this.partialCredit = false,
    this.explanation,
    this.difficulty,
    this.category,
    this.tags,
    this.timeLimit = 0,
    this.maxAttempts = 1,
    this.randomizeOptions = false,
    this.section,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? json['id'] ?? '',
      examId: json['examId'] ?? '',
      question: json['question'] ?? '',
      type: json['type'] ?? 'mcq',
      questionImage: json['questionImage'],
      questionAudio: json['questionAudio'],
      questionVideo: json['questionVideo'],
      options: json['options'] != null 
        ? (json['options'] as List).map((e) => Option.fromJson(e)).toList()
        : null,
      dragDropItems: json['dragDropItems'] != null
        ? (json['dragDropItems'] as List).map((e) => DragDropItem.fromJson(e)).toList()
        : null,
      dropZones: json['dropZones'] != null
        ? (json['dropZones'] as List).map((e) => DropZone.fromJson(e)).toList()
        : null,
      matchingPairs: json['matchingPairs'] != null
        ? (json['matchingPairs'] as List).map((e) => MatchingPair.fromJson(e)).toList()
        : null,
      correctOrder: json['correctOrder'] != null
        ? (json['correctOrder'] as List).map((e) => OrderItem.fromJson(e)).toList()
        : null,
      hotspots: json['hotspots'] != null
        ? (json['hotspots'] as List).map((e) => Hotspot.fromJson(e)).toList()
        : null,
      hotspotImage: json['hotspotImage'],
      correctAnswer: json['correctAnswer'],
      points: json['points'] ?? 1,
      partialCredit: json['partialCredit'] ?? false,
      explanation: json['explanation'],
      difficulty: json['difficulty'],
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      timeLimit: json['timeLimit'] ?? 0,
      maxAttempts: json['maxAttempts'] ?? 1,
      randomizeOptions: json['randomizeOptions'] ?? false,
      section: json['section'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examId': examId,
      'question': question,
      'type': type,
      'questionImage': questionImage,
      'questionAudio': questionAudio,
      'questionVideo': questionVideo,
      'options': options?.map((e) => e.toJson()).toList(),
      'dragDropItems': dragDropItems?.map((e) => e.toJson()).toList(),
      'dropZones': dropZones?.map((e) => e.toJson()).toList(),
      'matchingPairs': matchingPairs?.map((e) => e.toJson()).toList(),
      'correctOrder': correctOrder?.map((e) => e.toJson()).toList(),
      'hotspots': hotspots?.map((e) => e.toJson()).toList(),
      'hotspotImage': hotspotImage,
      'correctAnswer': correctAnswer,
      'points': points,
      'partialCredit': partialCredit,
      'explanation': explanation,
      'difficulty': difficulty,
      'category': category,
      'tags': tags,
      'timeLimit': timeLimit,
      'maxAttempts': maxAttempts,
      'randomizeOptions': randomizeOptions,
      'section': section,
    };
  }

  Question copyWith({
    String? id,
    String? examId,
    String? question,
    String? type,
    String? questionImage,
    String? questionAudio,
    String? questionVideo,
    List<Option>? options,
    List<DragDropItem>? dragDropItems,
    List<DropZone>? dropZones,
    List<MatchingPair>? matchingPairs,
    List<OrderItem>? correctOrder,
    List<Hotspot>? hotspots,
    String? hotspotImage,
    dynamic correctAnswer,
    int? points,
    bool? partialCredit,
    String? explanation,
    String? difficulty,
    String? category,
    List<String>? tags,
    int? timeLimit,
    int? maxAttempts,
    bool? randomizeOptions,
    String? section,
  }) {
    return Question(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      question: question ?? this.question,
      type: type ?? this.type,
      questionImage: questionImage ?? this.questionImage,
      questionAudio: questionAudio ?? this.questionAudio,
      questionVideo: questionVideo ?? this.questionVideo,
      options: options ?? this.options,
      dragDropItems: dragDropItems ?? this.dragDropItems,
      dropZones: dropZones ?? this.dropZones,
      matchingPairs: matchingPairs ?? this.matchingPairs,
      correctOrder: correctOrder ?? this.correctOrder,
      hotspots: hotspots ?? this.hotspots,
      hotspotImage: hotspotImage ?? this.hotspotImage,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      points: points ?? this.points,
      partialCredit: partialCredit ?? this.partialCredit,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      timeLimit: timeLimit ?? this.timeLimit,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      randomizeOptions: randomizeOptions ?? this.randomizeOptions,
      section: section ?? this.section,
    );
  }
}

class Option {
  final String? id;
  final String text;
  final String? image;
  final bool isCorrect;

  Option({
    this.id,
    required this.text,
    this.image,
    this.isCorrect = false,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['_id'] ?? json['id'],
      text: json['text'] ?? '',
      image: json['image'],
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'image': image,
      'isCorrect': isCorrect,
    };
  }
}

class DragDropItem {
  final String id;
  final String content;
  final String? image;
  final String targetZone;

  DragDropItem({
    required this.id,
    required this.content,
    this.image,
    required this.targetZone,
  });

  factory DragDropItem.fromJson(Map<String, dynamic> json) {
    return DragDropItem(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      image: json['image'],
      targetZone: json['targetZone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'image': image,
      'targetZone': targetZone,
    };
  }
}

class DropZone {
  final String id;
  final String label;
  final List<String> correctItems;

  DropZone({
    required this.id,
    required this.label,
    required this.correctItems,
  });

  factory DropZone.fromJson(Map<String, dynamic> json) {
    return DropZone(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      correctItems: json['correctItems'] != null 
        ? List<String>.from(json['correctItems'])
        : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'correctItems': correctItems,
    };
  }
}

class MatchingPair {
  final ItemData leftItem;
  final ItemData rightItem;

  MatchingPair({
    required this.leftItem,
    required this.rightItem,
  });

  factory MatchingPair.fromJson(Map<String, dynamic> json) {
    return MatchingPair(
      leftItem: ItemData.fromJson(json['leftItem'] ?? {}),
      rightItem: ItemData.fromJson(json['rightItem'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leftItem': leftItem.toJson(),
      'rightItem': rightItem.toJson(),
    };
  }
}

class OrderItem {
  final String id;
  final String content;
  final String? image;

  OrderItem({
    required this.id,
    required this.content,
    this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'image': image,
    };
  }
}

class Hotspot {
  final double x;
  final double y;
  final double width;
  final double height;
  final String label;

  Hotspot({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
  });

  factory Hotspot.fromJson(Map<String, dynamic> json) {
    return Hotspot(
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      label: json['label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'label': label,
    };
  }
}

class ItemData {
  final String? text;
  final String? image;
  final String? id;

  ItemData({
    this.text,
    this.image,
    this.id,
  });

  factory ItemData.fromJson(Map<String, dynamic> json) {
    return ItemData(
      text: json['text'],
      image: json['image'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'image': image,
      'id': id,
    };
  }
}
