enum PlotThreadStatus {
  introduced, // Thread just started
  developing, // Thread is actively being developed
  resolved,   // Thread has been concluded
  abandoned,  // Thread hasn't been mentioned in a while
}

enum PlotThreadType {
  mainPlot,      // Primary story arc
  subplot,       // Secondary story arc
  characterArc,  // Character development/transformation
  mystery,       // Question/mystery to be answered
  conflict,      // Ongoing conflict/tension
  relationship,  // Relationship development
  other,         // Miscellaneous threads
}

class PlotThread {
  final String id;
  final String title;
  final String description;
  final PlotThreadType type;
  final PlotThreadStatus status;
  final int introducedAtScene; // Scene number where introduced
  final int lastMentionedAtScene; // Last scene where this thread appeared
  final List<int> sceneAppearances; // All scenes where this thread appears
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? aiSummary; // AI-generated narrative summary of how this thread develops

  const PlotThread({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.introducedAtScene,
    required this.lastMentionedAtScene,
    required this.sceneAppearances,
    required this.createdAt,
    required this.updatedAt,
    this.aiSummary,
  });

  PlotThread copyWith({
    String? id,
    String? title,
    String? description,
    PlotThreadType? type,
    PlotThreadStatus? status,
    int? introducedAtScene,
    int? lastMentionedAtScene,
    List<int>? sceneAppearances,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? aiSummary,
  }) {
    return PlotThread(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      introducedAtScene: introducedAtScene ?? this.introducedAtScene,
      lastMentionedAtScene: lastMentionedAtScene ?? this.lastMentionedAtScene,
      sceneAppearances: sceneAppearances ?? this.sceneAppearances,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'introducedAtScene': introducedAtScene,
      'lastMentionedAtScene': lastMentionedAtScene,
      'sceneAppearances': sceneAppearances,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'aiSummary': aiSummary,
    };
  }

  factory PlotThread.fromJson(Map<String, dynamic> json) {
    return PlotThread(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: PlotThreadType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PlotThreadType.other,
      ),
      status: PlotThreadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PlotThreadStatus.developing,
      ),
      introducedAtScene: json['introducedAtScene'],
      lastMentionedAtScene: json['lastMentionedAtScene'],
      sceneAppearances: List<int>.from(json['sceneAppearances']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      aiSummary: json['aiSummary'] as String?,
    );
  }

  /// Calculate how many scenes since this thread was last mentioned
  int scenesSinceLastMention(int currentScene) {
    return currentScene - lastMentionedAtScene;
  }

  /// Check if thread is potentially abandoned (not mentioned in 10+ scenes)
  bool isPotentiallyAbandoned(int currentScene) {
    return status != PlotThreadStatus.resolved &&
           status != PlotThreadStatus.abandoned &&
           scenesSinceLastMention(currentScene) >= 10;
  }
}

/// Represents a thread mention/update in a specific scene
class ThreadMention {
  final String threadId;
  final int sceneNumber;
  final String action; // 'introduced', 'advanced', 'resolved'
  final String? note; // Optional note about what happened

  const ThreadMention({
    required this.threadId,
    required this.sceneNumber,
    required this.action,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'threadId': threadId,
      'sceneNumber': sceneNumber,
      'action': action,
      'note': note,
    };
  }

  factory ThreadMention.fromJson(Map<String, dynamic> json) {
    return ThreadMention(
      threadId: json['threadId'],
      sceneNumber: json['sceneNumber'],
      action: json['action'],
      note: json['note'],
    );
  }
}
