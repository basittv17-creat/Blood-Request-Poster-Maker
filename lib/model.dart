import 'dart:math';

enum Language {
  ur('اردو'),
  hi('हिन्दी'),
  en('English');

  const Language(this.label);
  final String label;
  bool get rtl => this == ur;
  String get font => switch (this) {
    ur => 'Naskh',
    hi => 'Devanagari',
    en => 'Roboto',
  };
  String t(String urdu, String hindi, String english) => switch (this) {
    ur => urdu,
    hi => hindi,
    en => english,
  };
}

const groups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const requiredFields = [
  'patient',
  'hospital',
  'address',
  'primary',
  'secondary',
];
const fields = [
  ...requiredFields,
  'units',
  'deadline',
  'ward',
  'note',
  'dial',
  'eligibility',
  'title',
  'footer',
];

String digits(String value) =>
    value.replaceAllMapped(RegExp('[۰-۹٠-٩०-९]'), (m) {
      final code = m[0]!.codeUnitAt(0);
      return (code % 16 - (code >= 0x966 && code <= 0x96f ? 6 : 0)).toString();
    });

bool validPhone(String input) {
  final value = digits(input.trim());
  if (!RegExp(r'^\+?[0-9][0-9 ().-]*$').hasMatch(value)) return false;
  final number = value.replaceAll(RegExp(r'[^0-9]'), '');
  final international = value.startsWith('+') || number.startsWith('00');
  final normalized = number.startsWith('00') ? number.substring(2) : number;
  return normalized.length >= 7 &&
      normalized.length <= 15 &&
      (!international || !normalized.startsWith('0'));
}

class PosterRequest {
  const PosterRequest({
    this.values = const {},
    this.group = 'B+',
    this.demo = false,
    this.emergency = true,
    this.illustration = true,
    this.invite = false,
    this.accent = false,
    this.largeGroup = false,
    this.reverse = false,
  });
  final Map<String, String> values;
  final String group;
  final bool demo, emergency, illustration, invite, accent, largeGroup, reverse;
  String operator [](String key) => values[key]?.trim() ?? '';
  bool get valid =>
      groups.contains(group) &&
      requiredFields.every((key) => this[key].isNotEmpty) &&
      validPhone(this['primary']) &&
      validPhone(this['secondary']);

  Map<String, Object> toJson() => {
    'values': values,
    'group': group,
    'demo': demo,
    'emergency': emergency,
    'illustration': illustration,
    'invite': invite,
    'accent': accent,
    'largeGroup': largeGroup,
    'reverse': reverse,
  };

  factory PosterRequest.fromJson(Map<String, dynamic> json) => PosterRequest(
    values: Map<String, String>.from(json['values'] as Map),
    group: groups.contains(json['group']) ? json['group'] as String : 'B+',
    demo: json['demo'] == true,
    emergency: json['emergency'] != false,
    illustration: json['illustration'] != false,
    invite: json['invite'] == true,
    accent: json['accent'] == true,
    largeGroup: json['largeGroup'] == true,
    reverse: json['reverse'] == true,
  );

  static const sample = PosterRequest(
    demo: true,
    values: {
      'patient': 'محمد عمران خان',
      'hospital': 'سروسز ہسپتال لاہور',
      'address': 'جیل روڈ، لاہور',
      'primary': '0321-4567890',
      'secondary': '0300-1234567',
    },
  );
}

class PosterDraft {
  const PosterDraft(this.id, this.request, this.template);
  final String id;
  final PosterRequest request;
  final int template;
  Map<String, Object> toJson() => {
    'version': 1,
    'id': id,
    'request': request.toJson(),
    'template': template,
  };
  factory PosterDraft.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw const FormatException('Draft version');
    final template = json['template'] as int;
    return PosterDraft(
      json['id'] as String,
      PosterRequest.fromJson(Map<String, dynamic>.from(json['request'] as Map)),
      template.clamp(0, designs.length - 1).toInt(),
    );
  }
}

class DesignTemplate {
  const DesignTemplate(
    this.en,
    this.ur,
    this.hi,
    this.paper,
    this.ink,
    this.red,
    this.gold,
  );
  final String en, ur, hi;
  final int paper, ink, red, gold;
  String name(Language language) => language.t(ur, hi, en);
}

const designs = [
  DesignTemplate(
    'Crimson ribbon',
    'سرخ ربن',
    'लाल रिबन',
    0xfffff3ec,
    0xff321322,
    0xffa01639,
    0xffffd16b,
  ),
  DesignTemplate(
    'Dispatch',
    'فوری اطلاع',
    'तत्काल सूचना',
    0xff171926,
    0xfffff4ec,
    0xffa32649,
    0xffffbf6b,
  ),
  DesignTemplate(
    'Gold seal',
    'سنہری مہر',
    'सुनहरी मुहर',
    0xfffff5db,
    0xff482b25,
    0xff822847,
    0xffecc477,
  ),
  DesignTemplate(
    'Two columns',
    'دو کالم',
    'दो कॉलम',
    0xfff9e1e8,
    0xff361526,
    0xffa72058,
    0xffffd7a8,
  ),
  DesignTemplate(
    'Heartbeat',
    'دھڑکن',
    'धड़कन',
    0xffebf4f3,
    0xff142d35,
    0xff901d46,
    0xfff7c77f,
  ),
  DesignTemplate(
    'Spotlight',
    'روشنی',
    'रोशनी',
    0xff302030,
    0xfffff3ed,
    0xffa72e4b,
    0xffffca7f,
  ),
  DesignTemplate(
    'Editorial',
    'اخباری انداز',
    'संपादकीय',
    0xfffcf6ed,
    0xff27222a,
    0xff963b39,
    0xffecc581,
  ),
  DesignTemplate(
    'Red diagonal',
    'سرخ ترچھی لکیر',
    'लाल तिरछी रेखा',
    0xfffbebee,
    0xff331628,
    0xff9c1238,
    0xffffcd71,
  ),
  DesignTemplate(
    'Mission card',
    'عطیہ کارڈ',
    'दान कार्ड',
    0xffe8ecf7,
    0xff251d37,
    0xff7e285e,
    0xfff4c67c,
  ),
  DesignTemplate(
    'Broadside',
    'اعلان',
    'घोषणा',
    0xffffe9d5,
    0xff3b2023,
    0xff963025,
    0xffffd781,
  ),
  DesignTemplate(
    'Signal',
    'اشارہ',
    'संकेत',
    0xff17282e,
    0xfff1fff9,
    0xffa42450,
    0xff8be2cc,
  ),
  DesignTemplate(
    'Corner fold',
    'خم دار کونا',
    'मुड़ा हुआ कोना',
    0xfffff8ec,
    0xff362328,
    0xff942445,
    0xffffc475,
  ),
];

int nextDesign(List<int> recent, Random random) {
  final options = List.generate(
    designs.length,
    (i) => i,
  ).where((i) => !recent.take(3).contains(i)).toList();
  return options[random.nextInt(options.length)];
}

const appDownloadUrl = String.fromEnvironment('APP_DOWNLOAD_URL');

String inviteMessage(Language language) => language.t(
  'اگر آپ کو بھی خون کی ضرورت کے لیے خوبصورت پوسٹر بنانا ہو تو یہ مفت ایپ ڈاؤن لوڈ کریں: $appDownloadUrl',
  'रक्त की ज़रूरत का सुंदर पोस्टर बनाने के लिए यह मुफ़्त ऐप डाउनलोड करें: $appDownloadUrl',
  'Download this free app to create beautiful blood request posters: $appDownloadUrl',
);

class ExportOptions {
  const ExportOptions(this.jpeg, this.quality);
  final bool jpeg;
  final int quality;
  String get mime => jpeg ? 'image/jpeg' : 'image/png';
  String get name => 'blood-request.${jpeg ? 'jpg' : 'png'}';
}

class SharePayload {
  const SharePayload(this.options, this.bytes, this.caption);
  final ExportOptions options;
  final List<int> bytes;
  final String? caption;
}

class UserSettings {
  const UserSettings(this.language, this.favorites);
  final Language? language;
  final Set<int> favorites;
}

String label(Language l, String key) => switch (key) {
  'patient' => l.t('مریض کا نام', 'मरीज़ का नाम', 'Patient name'),
  'hospital' => l.t('ہسپتال کا نام', 'अस्पताल का नाम', 'Hospital name'),
  'address' => l.t('مقام', 'पता', 'Location'),
  'primary' => l.t('پہلا موبائل نمبر', 'पहला मोबाइल नंबर', 'Primary mobile'),
  'secondary' => l.t(
    'دوسرا موبائل نمبر',
    'दूसरा मोबाइल नंबर',
    'Secondary mobile',
  ),
  'group' => l.t('ضروری بلڈ گروپ', 'आवश्यक रक्त समूह', 'Blood group needed'),
  'units' => l.t('خون کی یونٹس', 'रक्त की यूनिट', 'Blood units'),
  'deadline' => l.t('مطلوبہ تاریخ اور وقت', 'आवश्यक तारीख और समय', 'Needed by'),
  'ward' => l.t('وارڈ', 'वार्ड', 'Ward'),
  'note' => l.t('مختصر نوٹ', 'छोटा नोट', 'Short note'),
  'dial' => l.t(
    'ملکی ڈائلنگ کوڈ',
    'देश का डायलिंग कोड',
    'Country dialing code',
  ),
  'eligibility' => l.t(
    'عطیہ دہندگان کے لیے ہدایت',
    'रक्तदाताओं के लिए सूचना',
    'Donor instruction',
  ),
  'title' => l.t('پوسٹر کا عنوان', 'पोस्टर का शीर्षक', 'Poster title'),
  'footer' => l.t('اختتامی پیغام', 'अंतिम संदेश', 'Footer slogan'),
  _ => key,
};
