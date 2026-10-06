/// Bilingual copy (English + Arabic shown together, no language switch needed).
class S {
  S._();

  static const String title = 'CHONKY BUN';
  static const String titleAr = 'تشونكي بون';
  static const String tagline = 'Eat. Get chonky. Blame the carrot.';
  static const String taglineAr = 'كُل، اثقل، واللوم على الجزرة.';
  static const String concept = 'CONCEPT';

  static const String play = 'PLAY';
  static const String playAr = 'العب';
  static const String howToPlay = 'HOW TO PLAY';
  static const String howToPlayAr = 'طريقة اللعب';
  static const String best = 'BEST';
  static const String bestAr = 'الأفضل';
  static const String run = 'RUN';

  static const String weight = 'WEIGHT';
  static const String weightAr = 'الوزن';
  static const String zone = 'ZONE';
  static const String zoneAr = 'المرحلة';
  static const String distance = 'DISTANCE';
  static const String distanceAr = 'المسافة';
  static const String carrots = 'CARROTS';
  static const String carrotsAr = 'جزر';

  static const String light = 'LIGHT';
  static const String lightAr = 'خفيف';
  static const String puffy = 'PUFFY';
  static const String puffyAr = 'نفوخ';
  static const String heavy = 'HEAVY';
  static const String heavyAr = 'ثقيل';

  static const String tapToJump = 'TAP ANYWHERE TO JUMP';
  static const String tapToJumpAr = 'اضغط في أي مكان للقفز';
  static const String holdHigher = 'Hold longer for a higher jump';
  static const String holdHigherAr = 'استمر بالضغط للقفز أعلى';

  static const String paused = 'PAUSED';
  static const String pausedAr = 'إيقاف مؤقت';
  static const String resume = 'RESUME';
  static const String resumeAr = 'أكمل';
  static const String restart = 'RESTART';
  static const String restartAr = 'من جديد';
  static const String home = 'HOME';
  static const String homeAr = 'الرئيسية';
  static const String next = 'NEXT';
  static const String nextAr = 'التالي';
  static const String skip = 'SKIP';
  static const String skipAr = 'تخطي';
  static const String gotIt = 'GOT IT';
  static const String gotItAr = 'فهمت';
  static const String again = 'PLAY AGAIN';
  static const String againAr = 'العب مرة أخرى';

  static const String fell = 'FELL OFF THE ROOFTOP';
  static const String fellAr = 'سقطت من فوق السطح';
  static const String bumped = 'TOO CHONKY TO CLEAR IT';
  static const String bumpedAr = 'ثقلك ما خلّاك تعدي';

  static const String newBest = 'NEW BEST';
  static const String newBestAr = 'رقم قياسي جديد';

  static const String onb1Title = 'THE BUN RUNS';
  static const String onb1TitleAr = 'الأرنب يعدو';
  static const String onb1Body = 'Tap to jump across the rooftops. Hold the tap for a bigger leap.';
  static const String onb1BodyAr = 'اضغط لتقفز بين الأسطح. استمر بالضغط لقفزة أكبر.';

  static const String onb2Title = 'CARROTS ADD WEIGHT';
  static const String onb2TitleAr = 'الجزر يضيف وزن';
  static const String onb2Body = 'Every carrot makes the bun rounder and the jump shorter. Skipping is a strategy.';
  static const String onb2BodyAr = 'كل جزرة تصير الأرنب أسمن وقفزة أقصر. ترك الجزر خطة لعب.';

  static const String onb3Title = 'STILL, REACH THE GOAL';
  static const String onb3TitleAr = 'ومع ذلك، وصّل للهدف';
  static const String onb3Body = 'Running burns a little weight. Cross the flag to enter the next zone.';
  static const String onb3BodyAr = 'الجري يحرق قليل من الوزن. اعبر الراية للانتقال للمرحلة التالية.';

  static const String rules = 'RULES';
  static const String rulesAr = 'القوانين';
  static const String rule1 = 'Tap = jump, hold = higher';
  static const String rule1Ar = 'ضغطة = قفزة، ضغط مستمر = أعلى';
  static const String rule2 = 'Carrot = heavier, jump lower';
  static const String rule2Ar = 'الجزرة = أثقل وقفزة أقل';
  static const String rule3 = 'Never touch the gap below';
  static const String rule3Ar = 'لا تلمس الفراغ تحتك';

  static const String builtFor = 'A one-thumb rooftop game';
  static const String builtForAr = 'لعبة سطح بإبهام واحد';

  static String m(int v) => '${v}m';
  static String pct(double w) => '${(w * 100).round()}%';
  static String count(int n) => 'x $n';

  static String stateOf(double w) => w < 0.34 ? light : (w < 0.67 ? puffy : heavy);
  static String stateOfAr(double w) => w < 0.34 ? lightAr : (w < 0.67 ? puffyAr : heavyAr);
}
