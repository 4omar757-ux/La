import '../models/question.dart';

/// بنك أسئلة عامة تجريبي، مصنّف حسب مستوى الصعوبة. يمكن استبداله لاحقاً
/// ببنك أكبر أو تحميله من خدمة خارجية.
const List<Question> sampleQuestions = [
  // ── مبتدئ ──────────────────────────────────────────────
  Question(
    id: 'q1',
    text: 'ما هي عاصمة المملكة العربية السعودية؟',
    options: ['جدة', 'الرياض', 'الدمام', 'مكة المكرمة'],
    correctIndex: 1,
    difficulty: Difficulty.beginner,
  ),
  Question(
    id: 'q2',
    text: 'كم عدد قارات العالم؟',
    options: ['خمسة', 'ستة', 'سبعة', 'ثمانية'],
    correctIndex: 2,
    difficulty: Difficulty.beginner,
  ),
  Question(
    id: 'q4',
    text: 'كم عدد أركان الإسلام؟',
    options: ['ثلاثة', 'أربعة', 'خمسة', 'ستة'],
    correctIndex: 2,
    difficulty: Difficulty.beginner,
  ),
  Question(
    id: 'q6',
    text: 'كم عدد لاعبي الفريق الواحد في كرة القدم؟',
    options: ['٩', '١٠', '١١', '١٢'],
    correctIndex: 2,
    difficulty: Difficulty.beginner,
  ),
  Question(
    id: 'q7',
    text: 'ما هو الكوكب الأقرب إلى الشمس؟',
    options: ['الزهرة', 'عطارد', 'الأرض', 'المريخ'],
    correctIndex: 1,
    difficulty: Difficulty.beginner,
  ),
  Question(
    id: 'q10',
    text: 'كم عدد أيام السنة الكبيسة؟',
    options: ['٣٦٤', '٣٦٥', '٣٦٦', '٣٦٧'],
    correctIndex: 2,
    difficulty: Difficulty.beginner,
  ),
  Question(
    id: 'q17',
    text: 'كم عدد أشهر السنة الهجرية؟',
    options: ['١٠', '١١', '١٢', '١٣'],
    correctIndex: 2,
    difficulty: Difficulty.beginner,
  ),

  // ── متوسط ──────────────────────────────────────────────
  Question(
    id: 'q3',
    text: 'ما هو أكبر محيط في العالم؟',
    options: ['المحيط الأطلسي', 'المحيط الهندي', 'المحيط الهادئ', 'المحيط المتجمد الشمالي'],
    correctIndex: 2,
    difficulty: Difficulty.intermediate,
  ),
  Question(
    id: 'q5',
    text: 'ما هو أطول نهر في العالم؟',
    options: ['نهر النيل', 'نهر الأمازون', 'نهر الفرات', 'نهر دجلة'],
    correctIndex: 0,
    difficulty: Difficulty.intermediate,
  ),
  Question(
    id: 'q8',
    text: 'في أي عام تم توحيد المملكة العربية السعودية؟',
    options: ['١٩٣٢', '١٩٤٥', '١٩٢٥', '١٩٦٠'],
    correctIndex: 0,
    difficulty: Difficulty.intermediate,
  ),
  Question(
    id: 'q9',
    text: 'ما هي أصغر دولة في العالم من حيث المساحة؟',
    options: ['موناكو', 'الفاتيكان', 'سان مارينو', 'ليختنشتاين'],
    correctIndex: 1,
    difficulty: Difficulty.intermediate,
  ),
  Question(
    id: 'q11',
    text: 'ما هو العنصر الكيميائي الذي رمزه O؟',
    options: ['الذهب', 'الأكسجين', 'الأوزون', 'الحديد'],
    correctIndex: 1,
    difficulty: Difficulty.intermediate,
  ),
  Question(
    id: 'q13',
    text: 'ما هي أكبر قارة من حيث المساحة؟',
    options: ['إفريقيا', 'آسيا', 'أمريكا الشمالية', 'أوروبا'],
    correctIndex: 1,
    difficulty: Difficulty.intermediate,
  ),
  Question(
    id: 'q16',
    text: 'ما هو أعلى جبل في العالم؟',
    options: ['كي٢', 'إيفرست', 'كليمنجارو', 'ماكينلي'],
    correctIndex: 1,
    difficulty: Difficulty.intermediate,
  ),

  // ── صعب ────────────────────────────────────────────────
  Question(
    id: 'q12',
    text: 'من هو مخترع المصباح الكهربائي؟',
    options: ['نيكولا تسلا', 'ألبرت أينشتاين', 'توماس إديسون', 'إسحاق نيوتن'],
    correctIndex: 2,
    difficulty: Difficulty.hard,
  ),
  Question(
    id: 'q14',
    text: 'كم عدد عظام جسم الإنسان البالغ تقريباً؟',
    options: ['١٠٦', '١٥٦', '٢٠٦', '٣٠٦'],
    correctIndex: 2,
    difficulty: Difficulty.hard,
  ),
  Question(
    id: 'q15',
    text: 'ما هي اللغة الرسمية في البرازيل؟',
    options: ['الإسبانية', 'البرتغالية', 'الإنجليزية', 'الفرنسية'],
    correctIndex: 1,
    difficulty: Difficulty.hard,
  ),
  Question(
    id: 'q18',
    text: 'ما اسم أصغر عظمة في جسم الإنسان؟',
    options: ['عظمة الترقوة', 'الركاب (في الأذن)', 'عظمة الفخذ', 'عظمة الرسغ'],
    correctIndex: 1,
    difficulty: Difficulty.hard,
  ),
  Question(
    id: 'q19',
    text: 'أي غاز يشكل النسبة الأكبر من الغلاف الجوي للأرض؟',
    options: ['الأكسجين', 'ثاني أكسيد الكربون', 'النيتروجين', 'الهيدروجين'],
    correctIndex: 2,
    difficulty: Difficulty.hard,
  ),
  Question(
    id: 'q20',
    text: 'من مؤلف كتاب "كليلة ودمنة"؟',
    options: ['ابن المقفع', 'الجاحظ', 'المتنبي', 'ابن خلدون'],
    correctIndex: 0,
    difficulty: Difficulty.hard,
  ),
];
