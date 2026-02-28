enum TestSkill { listening, reading, writing, speaking }
enum TestType { academic, generalTraining }
enum QuestionType { multipleChoice, trueFalseNotGiven, fillInBlank, matchingHeadings, shortAnswer, essay }

class IELTSTest {
  final String id;
  final String title;
  final TestSkill skill;
  final TestType type;
  final int durationMinutes;
  final List<TestSection> sections;
  final bool isFree;
  final String description;
  final double rating;
  final int attempts;

  IELTSTest({
    required this.id, required this.title, required this.skill,
    required this.type, required this.durationMinutes, required this.sections,
    this.isFree = true, this.description = '', this.rating = 4.0, this.attempts = 0,
  });
}

class TestSection {
  final String id;
  final String title;
  final String? audioUrl;
  final String? passage;
  final List<Question> questions;

  TestSection({required this.id, required this.title, this.audioUrl, this.passage, required this.questions});
}

class Question {
  final String id;
  final int number;
  final QuestionType type;
  final String text;
  final List<String>? options;
  final String correctAnswer;
  final String? explanation;

  Question({
    required this.id, required this.number, required this.type,
    required this.text, this.options, required this.correctAnswer, this.explanation,
  });
}

class TestResult {
  final String id;
  final String testId;
  final String testTitle;
  final TestSkill skill;
  final double bandScore;
  final int correctAnswers;
  final int totalQuestions;
  final int timeTakenSeconds;
  final DateTime completedAt;
  final Map<String, String> userAnswers;
  AIFeedback? aiFeedback;

  TestResult({
    required this.id, required this.testId, required this.testTitle,
    required this.skill, required this.bandScore, required this.correctAnswers,
    required this.totalQuestions, required this.timeTakenSeconds,
    required this.completedAt, required this.userAnswers, this.aiFeedback,
  });

  double get accuracy => totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;
}

class AIFeedback {
  final double taskAchievementScore;
  final double coherenceCohesionScore;
  final double lexicalResourceScore;
  final double grammaticalRangeScore;
  final double overallBand;
  final String overallFeedback;
  final List<String> strengths;
  final List<String> improvements;
  final String? improvedVersion;

  AIFeedback({
    required this.taskAchievementScore, required this.coherenceCohesionScore,
    required this.lexicalResourceScore, required this.grammaticalRangeScore,
    required this.overallBand, required this.overallFeedback,
    required this.strengths, required this.improvements, this.improvedVersion,
  });

  factory AIFeedback.fromText(String rawText, double band) {
    return AIFeedback(
      taskAchievementScore: band, coherenceCohesionScore: band,
      lexicalResourceScore: band, grammaticalRangeScore: band,
      overallBand: band, overallFeedback: rawText,
      strengths: ['Clear structure', 'Good use of examples'],
      improvements: ['Expand vocabulary range', 'Work on complex sentences'],
      improvedVersion: null,
    );
  }
}

class LiveLesson {
  final String id;
  final String title;
  final String instructor;
  final String instructorTitle;
  final TestSkill skill;
  final DateTime scheduledAt;
  final int durationMinutes;
  final int attendees;
  final bool isFree;
  final String description;
  final String? thumbnailUrl;

  LiveLesson({
    required this.id, required this.title, required this.instructor,
    required this.instructorTitle, required this.skill, required this.scheduledAt,
    required this.durationMinutes, required this.attendees, required this.isFree,
    required this.description, this.thumbnailUrl,
  });

  bool get isLive => scheduledAt.isBefore(DateTime.now()) &&
      DateTime.now().isBefore(scheduledAt.add(Duration(minutes: durationMinutes)));
  bool get isUpcoming => scheduledAt.isAfter(DateTime.now());
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final double targetBandScore;
  final DateTime? examDate;
  int totalPoints;

  AppUser({
    required this.id, required this.name, required this.email,
    required this.targetBandScore, this.examDate, this.totalPoints = 0,
  });
}
