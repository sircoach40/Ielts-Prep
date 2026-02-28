import '../models/models.dart';

class MockDataService {
  // ---- TESTS ----
  static List<IELTSTest> getAllTests() {
    return [
      ...getListeningTests(),
      ...getReadingTests(),
      ...getWritingTests(),
      ...getSpeakingTests(),
    ];
  }

  static List<IELTSTest> getListeningTests() {
    return [
      IELTSTest(
        id: 'l001', title: 'IELTS Listening Mock Test 1', skill: TestSkill.listening,
        type: TestType.academic, durationMinutes: 30, rating: 4.5, attempts: 15200,
        description: 'Full IELTS Listening test with 40 questions across 4 sections.',
        sections: [
          TestSection(
            id: 'l001s1', title: 'Section 1 – Everyday Conversation',
            audioUrl: 'assets/audio/listening_s1.mp3',
            questions: _buildMCQQuestions(1, 10, 'Listen and answer:'),
          ),
          TestSection(
            id: 'l001s2', title: 'Section 2 – Monologue',
            audioUrl: 'assets/audio/listening_s2.mp3',
            questions: _buildFillBlankQuestions(11, 10),
          ),
          TestSection(
            id: 'l001s3', title: 'Section 3 – Academic Discussion',
            audioUrl: 'assets/audio/listening_s3.mp3',
            questions: _buildMCQQuestions(21, 10, 'Choose the correct answer:'),
          ),
          TestSection(
            id: 'l001s4', title: 'Section 4 – Academic Lecture',
            audioUrl: 'assets/audio/listening_s4.mp3',
            questions: _buildFillBlankQuestions(31, 10),
          ),
        ],
      ),
      IELTSTest(
        id: 'l002', title: 'IELTS Listening Mock Test 2', skill: TestSkill.listening,
        type: TestType.academic, durationMinutes: 30, rating: 4.3, attempts: 9800,
        description: 'Practice with authentic IELTS-style audio recordings.',
        sections: [
          TestSection(id: 'l002s1', title: 'Section 1 – Travel Booking',
            questions: _buildMCQQuestions(1, 10, 'Listen and choose:')),
          TestSection(id: 'l002s2', title: 'Section 2 – Local Services',
            questions: _buildFillBlankQuestions(11, 10)),
          TestSection(id: 'l002s3', title: 'Section 3 – University Study',
            questions: _buildMCQQuestions(21, 10, 'Select the correct answer:')),
          TestSection(id: 'l002s4', title: 'Section 4 – Environmental Science',
            questions: _buildFillBlankQuestions(31, 10)),
        ],
      ),
    ];
  }

  static List<IELTSTest> getReadingTests() {
    return [
      IELTSTest(
        id: 'r001', title: 'IELTS Academic Reading Test 1', skill: TestSkill.reading,
        type: TestType.academic, durationMinutes: 60, rating: 4.6, attempts: 22000,
        description: '3 passages with 40 questions. Covers True/False/Not Given, Matching Headings, and Short Answer.',
        sections: [
          TestSection(
            id: 'r001s1', title: 'Passage 1 – The History of Tea',
            passage: _getPassage1(),
            questions: [
              ..._buildTFNGQuestions(1, 7),
              ..._buildMatchingQuestions(8, 6),
            ],
          ),
          TestSection(
            id: 'r001s2', title: 'Passage 2 – Urban Heat Islands',
            passage: _getPassage2(),
            questions: [
              ..._buildMCQQuestions(14, 7, 'Choose the best answer:'),
              ..._buildFillBlankQuestions(21, 6),
            ],
          ),
          TestSection(
            id: 'r001s3', title: 'Passage 3 – The Future of Artificial Intelligence',
            passage: _getPassage3(),
            questions: [
              ..._buildTFNGQuestions(27, 7),
              ..._buildMCQQuestions(34, 7, 'According to the passage:'),
            ],
          ),
        ],
      ),
      IELTSTest(
        id: 'r002', title: 'IELTS General Training Reading Test 1', skill: TestSkill.reading,
        type: TestType.generalTraining, durationMinutes: 60, rating: 4.4, attempts: 18500,
        description: 'General Training reading with everyday texts and workplace documents.',
        sections: [
          TestSection(id: 'r002s1', title: 'Section 1 – Everyday Notices',
            passage: 'Various everyday notices and advertisements about local services...',
            questions: _buildMCQQuestions(1, 14, 'Choose the correct answer:')),
          TestSection(id: 'r002s2', title: 'Section 2 – Workplace Documents',
            passage: 'Employee handbook and workplace safety guidelines...',
            questions: _buildFillBlankQuestions(15, 13)),
          TestSection(id: 'r002s3', title: 'Section 3 – General Interest Article',
            passage: _getPassage3(),
            questions: _buildTFNGQuestions(28, 13)),
        ],
      ),
    ];
  }

  static List<IELTSTest> getWritingTests() {
    return [
      IELTSTest(
        id: 'w001', title: 'IELTS Academic Writing Test 1', skill: TestSkill.writing,
        type: TestType.academic, durationMinutes: 60, rating: 4.7, attempts: 31000,
        description: 'Task 1 (Graph/Chart Description) + Task 2 (Essay). AI feedback available.',
        sections: [
          TestSection(
            id: 'w001s1', title: 'Task 1 – Bar Chart Description',
            questions: [
              Question(
                id: 'w001q1', number: 1, type: QuestionType.essay,
                text: 'The chart below shows the percentage of households in owned and rented accommodation in England and Wales between 1918 and 2011.\n\nSummarise the information by selecting and reporting the main features, and make comparisons where relevant.\n\nWrite at least 150 words.',
                correctAnswer: '',
              ),
            ],
          ),
          TestSection(
            id: 'w001s2', title: 'Task 2 – Opinion Essay',
            questions: [
              Question(
                id: 'w001q2', number: 2, type: QuestionType.essay,
                text: 'Some people believe that it is best to accept a bad situation, such as an unsatisfactory job or shortage of money. Others argue that it is better to try and improve such situations.\n\nDiscuss both views and give your own opinion.\n\nGive reasons for your answer and include any relevant examples from your own knowledge or experience.\n\nWrite at least 250 words.',
                correctAnswer: '',
              ),
            ],
          ),
        ],
      ),
      IELTSTest(
        id: 'w002', title: 'IELTS Academic Writing Test 2', skill: TestSkill.writing,
        type: TestType.academic, durationMinutes: 60, rating: 4.5, attempts: 24000,
        description: 'Practice with line graphs, pie charts and argument essays.',
        sections: [
          TestSection(
            id: 'w002s1', title: 'Task 1 – Line Graph',
            questions: [
              Question(
                id: 'w002q1', number: 1, type: QuestionType.essay,
                text: 'The graph below shows the number of tourists visiting a particular Caribbean island between 2010 and 2017.\n\nSummarise the information by selecting and reporting the main features, and make comparisons where relevant.\n\nWrite at least 150 words.',
                correctAnswer: '',
              ),
            ],
          ),
          TestSection(
            id: 'w002s2', title: 'Task 2 – Advantages/Disadvantages Essay',
            questions: [
              Question(
                id: 'w002q2', number: 2, type: QuestionType.essay,
                text: 'In many countries, people are choosing to live and work abroad. What are the advantages and disadvantages of this trend?\n\nGive reasons for your answer and include any relevant examples from your knowledge or experience.\n\nWrite at least 250 words.',
                correctAnswer: '',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static List<IELTSTest> getSpeakingTests() {
    return [
      IELTSTest(
        id: 's001', title: 'IELTS Speaking Mock Test 1', skill: TestSkill.speaking,
        type: TestType.academic, durationMinutes: 15, rating: 4.8, attempts: 19000,
        description: 'Full 3-part speaking test. Record your answers and get AI examiner feedback.',
        sections: [
          TestSection(
            id: 's001s1', title: 'Part 1 – Introduction & Interview',
            questions: [
              Question(id: 's001q1', number: 1, type: QuestionType.shortAnswer,
                text: 'Can you tell me your full name please?', correctAnswer: ''),
              Question(id: 's001q2', number: 2, type: QuestionType.shortAnswer,
                text: 'Where are you from originally?', correctAnswer: ''),
              Question(id: 's001q3', number: 3, type: QuestionType.shortAnswer,
                text: 'Do you work or are you a student?', correctAnswer: ''),
              Question(id: 's001q4', number: 4, type: QuestionType.shortAnswer,
                text: 'What do you enjoy most about your work/studies?', correctAnswer: ''),
              Question(id: 's001q5', number: 5, type: QuestionType.shortAnswer,
                text: 'Let\'s talk about your hometown. What do you like about living there?', correctAnswer: ''),
            ],
          ),
          TestSection(
            id: 's001s2', title: 'Part 2 – Long Turn (Cue Card)',
            questions: [
              Question(
                id: 's001q6', number: 6, type: QuestionType.essay,
                text: 'Describe a skill you would like to learn.\n\nYou should say:\n• What the skill is\n• Why you want to learn it\n• How you would learn it\n• And explain how this skill would be useful to you\n\n(You will have 1 minute to prepare. Speak for 1-2 minutes)',
                correctAnswer: '',
              ),
            ],
          ),
          TestSection(
            id: 's001s3', title: 'Part 3 – Two-Way Discussion',
            questions: [
              Question(id: 's001q7', number: 7, type: QuestionType.shortAnswer,
                text: 'Why do you think some people find it difficult to learn new skills as they get older?', correctAnswer: ''),
              Question(id: 's001q8', number: 8, type: QuestionType.shortAnswer,
                text: 'How important do you think it is for schools to teach practical skills alongside academic subjects?', correctAnswer: ''),
              Question(id: 's001q9', number: 9, type: QuestionType.shortAnswer,
                text: 'Do you think online learning is as effective as face-to-face learning for developing skills?', correctAnswer: ''),
            ],
          ),
        ],
      ),
    ];
  }

  // ---- LIVE LESSONS ----
  static List<LiveLesson> getLiveLessons() {
    final now = DateTime.now();
    return [
      LiveLesson(
        id: 'll001', title: 'Vocabulary for IELTS – Register & Idioms',
        instructor: 'Soheila A.', instructorTitle: 'IELTS Expert, Band 8.5',
        skill: TestSkill.reading,
        scheduledAt: now.add(const Duration(hours: 2)),
        durationMinutes: 60, attendees: 520, isFree: true,
        description: 'Learn advanced vocabulary strategies including register, connotation, and idioms to boost your band score.',
      ),
      LiveLesson(
        id: 'll002', title: 'Writing Task 1 – Describing Maps',
        instructor: 'Mary T.', instructorTitle: 'IELTS Examiner, Band 9',
        skill: TestSkill.writing,
        scheduledAt: now.add(const Duration(days: 3)),
        durationMinutes: 60, attendees: 310, isFree: true,
        description: 'Master the art of describing map changes with the correct vocabulary and grammar structures.',
      ),
      LiveLesson(
        id: 'll003', title: 'Reading – Matching Headings Strategy',
        instructor: 'James K.', instructorTitle: 'IELTS Coach, Band 8.0',
        skill: TestSkill.reading,
        scheduledAt: now.add(const Duration(days: 7)),
        durationMinutes: 60, attendees: 380, isFree: true,
        description: 'Step-by-step strategies for tackling the most challenging reading question type.',
      ),
      LiveLesson(
        id: 'll004', title: 'Speaking – Part 2 Cue Card Masterclass',
        instructor: 'Priya S.', instructorTitle: 'IELTS Trainer, Band 8.5',
        skill: TestSkill.speaking,
        scheduledAt: now.subtract(const Duration(minutes: 30)),
        durationMinutes: 60, attendees: 890, isFree: false,
        description: 'LIVE NOW: Learn how to structure your Part 2 answer for maximum marks.',
      ),
      LiveLesson(
        id: 'll005', title: 'Listening – Section 3 & 4 Tactics',
        instructor: 'David L.', instructorTitle: 'IELTS Specialist, Band 8.0',
        skill: TestSkill.listening,
        scheduledAt: now.subtract(const Duration(days: 1)),
        durationMinutes: 90, attendees: 1200, isFree: true,
        description: 'Recorded session: Master the hardest IELTS Listening sections with expert strategies.',
      ),
    ];
  }

  // ---- HELPERS ----
  static List<Question> _buildMCQQuestions(int start, int count, String prefix) {
    return List.generate(count, (i) => Question(
      id: 'q${start + i}', number: start + i, type: QuestionType.multipleChoice,
      text: '$prefix Question ${start + i}: Which statement best describes the information presented?',
      options: ['A. The first option presented', 'B. The second option presented', 'C. The third option presented', 'D. The fourth option presented'],
      correctAnswer: 'A',
      explanation: 'The answer is A because it directly matches the information in the source material.',
    ));
  }

  static List<Question> _buildFillBlankQuestions(int start, int count) {
    return List.generate(count, (i) => Question(
      id: 'q${start + i}', number: start + i, type: QuestionType.fillInBlank,
      text: 'Question ${start + i}: Complete the sentence: The researchers found that __________ was the most significant factor.',
      correctAnswer: 'climate change',
      explanation: 'The passage clearly states that climate change was the most significant factor in section 2.',
    ));
  }

  static List<Question> _buildTFNGQuestions(int start, int count) {
    return List.generate(count, (i) => Question(
      id: 'q${start + i}', number: start + i, type: QuestionType.trueFalseNotGiven,
      text: 'Question ${start + i}: The study found a direct correlation between urban development and temperature increases.',
      options: ['TRUE', 'FALSE', 'NOT GIVEN'],
      correctAnswer: 'TRUE',
      explanation: 'The passage states in paragraph 3 that urban development directly correlates with rising temperatures.',
    ));
  }

  static List<Question> _buildMatchingQuestions(int start, int count) {
    return List.generate(count, (i) => Question(
      id: 'q${start + i}', number: start + i, type: QuestionType.matchingHeadings,
      text: 'Question ${start + i}: Match the paragraph to the correct heading.',
      options: ['i. Historical background', 'ii. Economic impact', 'iii. Future predictions', 'iv. Current challenges', 'v. Proposed solutions', 'vi. Statistical analysis'],
      correctAnswer: 'i',
    ));
  }

  static String _getPassage1() => '''
THE HISTORY OF TEA

Tea is the most widely consumed beverage in the world after water. Its history stretches back thousands of years, with origins that are as rich and complex as the drink itself. The story of tea begins in ancient China, where, according to legend, the Chinese emperor Shen Nong discovered the drink in 2737 BCE when tea leaves accidentally fell into boiling water he was drinking.

For centuries, tea was used primarily as a medicinal herb in China before it became a popular beverage. Buddhist monks played a crucial role in spreading the cultivation of tea throughout Asia, as they used it to stay awake during long hours of meditation. By the Tang Dynasty (618–907 CE), tea had become China's national drink, with a complex culture of preparation and appreciation surrounding it.

Tea reached Europe through Portuguese traders in the 16th century, with the Netherlands being one of the first countries to import it on a large scale. Britain, now famous for its tea culture, was actually one of the last major European nations to adopt the beverage. When tea did arrive in Britain in the mid-17th century, it quickly became extremely popular, leading to the establishment of famous tea houses across London.

The British East India Company recognized the commercial potential of tea and began importing massive quantities. To reduce dependence on Chinese tea, the British began cultivating tea in India and Ceylon (now Sri Lanka) in the 19th century, forever changing global tea production dynamics.

Today, tea is grown in over 30 countries, with China and India being the world's largest producers. The global tea market is worth billions of dollars annually, and tea remains an integral part of cultural traditions in countries ranging from Japan and Morocco to Argentina and the United Kingdom.
''';

  static String _getPassage2() => '''
URBAN HEAT ISLANDS

Urban areas around the world are experiencing temperatures that are significantly higher than surrounding rural areas – a phenomenon known as the Urban Heat Island (UHI) effect. This temperature difference, which can range from 1°C to as much as 7°C, has profound implications for human health, energy consumption, and environmental sustainability.

The primary cause of UHIs is the replacement of natural land cover with impervious surfaces such as asphalt, concrete, and buildings. These materials absorb and retain heat more efficiently than natural vegetation, releasing it slowly throughout the night rather than allowing temperatures to fall. Additionally, the concentration of human activities in urban areas – including transportation, industry, and air conditioning – generates substantial amounts of waste heat.

Research has shown that UHIs significantly increase the risk of heat-related illness and death, particularly among vulnerable populations such as the elderly and those with pre-existing health conditions. A study of European cities found that during the 2003 heat wave, which was intensified by UHI effects, an estimated 70,000 excess deaths occurred across the continent.

Urban planners and environmental scientists are developing various strategies to combat UHIs. Green infrastructure, including parks, street trees, green roofs, and living walls, can substantially reduce urban temperatures through evapotranspiration and shading. Cool pavements and roofs, which reflect rather than absorb solar radiation, are another promising solution. Some cities are also redesigning their layouts to improve airflow and reduce heat accumulation.

Cities that have implemented comprehensive UHI mitigation strategies have reported temperature reductions of up to 3°C, along with significant improvements in air quality and biodiversity. As climate change continues to intensify heat events globally, addressing UHIs has become an increasingly urgent priority for urban authorities.
''';

  static String _getPassage3() => '''
THE FUTURE OF ARTIFICIAL INTELLIGENCE

Artificial Intelligence (AI) is no longer the stuff of science fiction. From the algorithms that curate your social media feed to the natural language models that power virtual assistants, AI has already become deeply embedded in daily life. As we look to the future, the question is not whether AI will transform society, but how profound and how fast that transformation will be.

Current AI systems, despite their impressive capabilities, operate within narrow domains. A chess-playing AI cannot write poetry; a medical diagnostic system cannot drive a car. This limitation is known as "narrow" or "weak" AI. However, researchers are making rapid progress toward systems that can transfer learning across domains – a critical step toward what some call "general" AI.

The economic implications of advanced AI are staggering. The McKinsey Global Institute estimates that AI could contribute up to $13 trillion to the global economy by 2030. However, this growth is expected to come with significant disruption to labor markets. Jobs involving routine, predictable tasks – whether manual or cognitive – are most at risk of automation, while roles requiring creativity, emotional intelligence, and complex reasoning are likely to be more resilient.

The ethical dimensions of AI present some of the most complex challenges. Issues of algorithmic bias, privacy, accountability, and the potential concentration of power in the hands of those who control advanced AI systems require urgent attention from governments, researchers, and civil society. Several countries and international bodies are now developing AI governance frameworks to address these concerns.

Looking further ahead, some researchers believe we may eventually develop Artificial General Intelligence (AGI) – systems that can match or exceed human cognitive capabilities across all domains. The timeline for such development is highly uncertain, with estimates ranging from decades to centuries. What is clear is that the decisions we make today about how to develop, deploy, and regulate AI will shape the trajectory of this transformative technology for generations to come.
''';
}
