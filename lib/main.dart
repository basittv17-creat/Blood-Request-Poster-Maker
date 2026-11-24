import 'dart:math';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'groups_page.dart';
import 'model.dart';
import 'platform.dart';
import 'poster.dart';

const _appName = 'Blood Request';
const _site = 'https://basittv17-creat.github.io/Blood-Request-Poster-Maker';

void main() => runApp(const BloodRequestApp());

class BloodRequestApp extends StatefulWidget {
  const BloodRequestApp({super.key});

  @override
  State<BloodRequestApp> createState() => _BloodRequestAppState();
}

class _BloodRequestAppState extends State<BloodRequestApp> {
  final device = Device();
  final drafts = <PosterDraft>[];
  final favorites = <int>{};
  Language? selected;
  bool ready = false;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await device.read();
      selected = Language.values.asNameMap()[data['language']];
      final savedFavorites = data['favorites'];
      if (savedFavorites is List) {
        favorites.addAll(
          savedFavorites.whereType<int>().where(
            (i) => i >= 0 && i < designs.length,
          ),
        );
      }
      final records = data['drafts'];
      if (records is List) {
        for (final record in records.whereType<Map<String, dynamic>>()) {
          try {
            drafts.add(PosterDraft.fromJson(record));
          } on FormatException {
            continue;
          } on TypeError {
            continue;
          }
        }
      }
      if (mounted) {
        setState(() {
          ready = true;
          failed = false;
        });
      }
    } on PlatformException {
      if (mounted) setState(() => failed = true);
    }
  }

  Future<void> persist() =>
      device.write(UserSettings(selected, favorites), drafts);

  @override
  Widget build(BuildContext context) {
    final language = selected ?? Language.ur;
    ThemeData theme(Brightness mode) => ThemeData(
      useMaterial3: true,
      brightness: mode,
      fontFamily: language.font,
      fontFamilyFallback: const ['Naskh', 'Devanagari', 'Roboto'],
      colorSchemeSeed: const Color(0xffa01639),
      scaffoldBackgroundColor: mode == Brightness.light
          ? const Color(0xfffff7f5)
          : const Color(0xff20191d),
      appBarTheme: AppBarTheme(
        backgroundColor: mode == Brightness.light
            ? const Color(0xfffff7f5)
            : const Color(0xff20191d),
        foregroundColor: mode == Brightness.light
            ? const Color(0xff78152a)
            : const Color(0xffffdce3),
        elevation: 0,
        centerTitle: false,
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _appName,
      supportedLocales: const [Locale('ur'), Locale('hi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      locale: Locale(language.name),
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: !ready
          ? Scaffold(
              body: Center(
                child: failed
                    ? FilledButton(
                        onPressed: load,
                        child: const Text('دوبارہ کوشش کریں / Retry'),
                      )
                    : const CircularProgressIndicator(),
              ),
            )
          : Workspace(
              language: language,
              chooseFirst: selected == null,
              drafts: drafts,
              favorites: favorites,
              device: device,
              persist: persist,
              select: (value) async {
                await device.write(UserSettings(value, favorites), drafts);
                if (mounted) setState(() => selected = value);
              },
            ),
    );
  }
}

class Workspace extends StatefulWidget {
  const Workspace({
    super.key,
    required this.language,
    required this.chooseFirst,
    required this.drafts,
    required this.favorites,
    required this.device,
    required this.persist,
    required this.select,
  });
  final Language language;
  final bool chooseFirst;
  final List<PosterDraft> drafts;
  final Set<int> favorites;
  final Device device;
  final Future<void> Function() persist;
  final Future<void> Function(Language) select;

  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  final form = GlobalKey<FormState>();
  final controllers = {
    for (final field in fields) field: TextEditingController(),
  };
  final random = Random();
  final recent = <int>[0];
  String group = 'B+';
  String? draftId;
  bool editing = false, demo = false, emergency = true, illustration = true;
  bool invite = false, accent = false, largeGroup = false, reverse = false;
  bool busy = false, dirty = false;
  int design = 0;

  Language get l => widget.language;
  String t(String ur, String hi, String en) => l.t(ur, hi, en);
  String get cancel => t('منسوخ', 'रद्द करें', 'Cancel');
  String get done => t('تصدیق کریں', 'पुष्टि करें', 'Confirm');

  PosterRequest get request => PosterRequest(
    values: {for (final field in fields) field: controllers[field]!.text},
    group: group,
    demo: demo,
    emergency: emergency,
    illustration: illustration,
    invite: invite,
    accent: accent,
    largeGroup: largeGroup,
    reverse: reverse,
  );

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void open([
    PosterRequest value = const PosterRequest(),
    int template = 0,
    String? id,
  ]) {
    setState(() {
      for (final field in fields) {
        controllers[field]!.text = value[field];
      }
      draftId = id;
      group = value.group;
      demo = value.demo;
      emergency = value.emergency;
      illustration = value.illustration;
      invite = value.invite;
      accent = value.accent;
      largeGroup = value.largeGroup;
      reverse = value.reverse;
      design = template;
      recent
        ..clear()
        ..add(design);
      editing = true;
      dirty = false;
    });
  }

  void mutate(VoidCallback change) => setState(() {
    change();
    dirty = true;
  });
  void setDesign(int number) => mutate(() {
    design = number;
    recent
      ..remove(number)
      ..insert(0, number);
    if (recent.length > 3) recent.removeLast();
  });

  void notice(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), action: action));
  }

  Future<bool> confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(done),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } on Object {
      notice(
        t(
          'کام مکمل نہیں ہوا۔ دوبارہ کوشش کریں۔',
          'कार्य पूरा नहीं हुआ। फिर कोशिश करें।',
          'Could not complete the action. Try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> leave() async {
    if (busy ||
        (dirty &&
            !await confirm(
              t(
                'غیر محفوظ تبدیلیاں چھوڑ دیں؟',
                'बिना सहेजे बदलाव छोड़ें?',
                'Discard unsaved changes?',
              ),
            ))) {
      return;
    }
    if (mounted) setState(() => editing = false);
  }

  Future<void> languagePicker() async {
    final language = await showModalBottomSheet<Language>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final value in Language.values)
              ListTile(
                title: Text(value.label),
                leading: const Icon(Icons.translate),
                trailing: value == l ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (language != null && mounted) await run(() => widget.select(language));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chooseFirst) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.bloodtype_rounded,
                    size: 76,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    'زبان منتخب کریں\nभाषा चुनें\nChoose a language',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  for (final value in Language.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FilledButton.tonal(
                        onPressed: busy
                            ? null
                            : () => run(() => widget.select(value)),
                        child: Text(value.label),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return PopScope(
      canPop: !editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && editing) leave();
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Directionality(
            textDirection: editing || l.rtl == false
                ? Directionality.of(context)
                : TextDirection.ltr,
            child: AppBar(
              leading: editing ? BackButton(onPressed: leave) : null,
              title: editing
                  ? Text(t('پوسٹر بنائیں', 'पोस्टर बनाएँ', 'Create poster'))
                  : const SizedBox.shrink(),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  enabled: !busy,
                  onSelected: (value) {
                    if (value == 'language') languagePicker();
                    if (value == 'privacy') showInfo(true);
                    if (value == 'help') showInfo(false);
                    if (value == 'admin') showGroups(admin: true);
                  },
                  itemBuilder: (_) => [
                    if (!editing)
                      PopupMenuItem(
                        value: 'admin',
                        child: Text(
                          t('ایڈمن', 'एडमिन', 'Admin'),
                          textDirection: l.rtl
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                        ),
                      ),
                    PopupMenuItem(
                      value: 'language',
                      child: Text(t('زبان', 'भाषा', 'Language')),
                    ),
                    PopupMenuItem(
                      value: 'privacy',
                      child: Text(t('رازداری', 'गोपनीयता', 'Privacy')),
                    ),
                    PopupMenuItem(
                      value: 'help',
                      child: Text(t('مدد', 'सहायता', 'Help')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: editing ? editor() : home(),
            ),
          ),
        ),
        bottomNavigationBar: busy ? const LinearProgressIndicator() : null,
      ),
    );
  }

  Future<void> showInfo(bool privacy) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        privacy
            ? t('رازداری', 'गोपनीयता', 'Privacy')
            : t('مدد', 'सहायता', 'Help'),
      ),
      content: Text(
        privacy
            ? t(
                'ڈرافٹس اسی فون پر محفوظ ہیں۔ شیئر کرنے سے پہلے مریض کی اجازت لیں۔',
                'ड्राफ़्ट इसी फ़ोन पर रहते हैं। साझा करने से पहले रोगी की अनुमति लें।',
                'Drafts stay on this phone. Obtain patient consent before sharing.',
              )
            : t(
                'تفصیلات بھریں، ڈیزائن منتخب کریں اور پوسٹر محفوظ یا شیئر کریں۔',
                'जानकारी भरें, डिज़ाइन चुनें और पोस्टर सहेजें या साझा करें।',
                'Enter the details, select a design, then save or share the poster.',
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => openInfoPage(privacy),
          child: Text(
            privacy
                ? t('رازداری کی پالیسی', 'गोपनीयता नीति', 'Privacy Policy')
                : t('رابطہ کریں', 'संपर्क करें', 'Contact Support'),
          ),
        ),
        if (privacy)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              removeDrafts();
            },
            child: Text(
              t(
                'تمام ڈرافٹس حذف کریں',
                'सभी ड्राफ़्ट हटाएँ',
                'Delete all drafts',
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('بند کریں', 'बंद करें', 'Close')),
        ),
      ],
    ),
  );

  Future<void> openInfoPage(bool privacy) async {
    final page = privacy ? 'privacy' : 'support';
    try {
      if (await launchUrl(
        Uri.parse('$_site/$page/'),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } on PlatformException {
      // The device may have no browser available.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t(
            'صفحہ نہیں کھل سکا۔',
            'पेज नहीं खुल सका।',
            'Could not open the page.',
          ),
        ),
      ),
    );
  }

  void showGroups({bool admin = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GroupsPage(l, admin: admin)),
    );
  }

  Widget home() {
    final colors = Theme.of(context).colorScheme;
    return ListView(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.bloodtype_rounded,
              size: 38,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t(
                    'خون کی درخواست • عطیہ دہندگان تلاش کریں • زندگیاں بچائیں',
                    'रक्त अनुरोध • दाता खोजें • जीवन बचाएँ',
                    'Request Blood • Find Donors • Save Lives',
                  ),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      SizedBox(
        height: 66,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary,
                colors.primary.withValues(alpha: .82),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: .18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: colors.onPrimary,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            onPressed: busy ? null : open,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.add, size: 29),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    t(
                      'درخواست کا پوسٹر بنائیں',
                      'अनुरोध का पोस्टर बनाएँ',
                      'Generate Request Poster',
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 25),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 62,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.primary, width: 1.3),
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          onPressed: busy ? null : () => showGroups(),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded, size: 27),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  t(
                    'واٹس ایپ عطیہ گروپس میں شامل ہوں',
                    'व्हाट्सऐप रक्तदान समूहों से जुड़ें',
                    'Join WhatsApp Donation Groups',
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      Card(
        color: colors.surface,
        elevation: 2,
        shadowColor: colors.primary.withValues(alpha: .08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: poster(PosterRequest.sample, 0),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.outline),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: busy ? null : () => open(PosterRequest.sample),
                icon: const Icon(Icons.visibility_outlined),
                label: Text(
                  t('نمونہ کھولیں', 'नमूना खोलें', 'Open example'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Icon(Icons.layers_rounded, color: colors.primary, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t('میرے ڈرافٹس', 'मेरे ड्राफ़्ट', 'My drafts'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (widget.drafts.isEmpty)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(Icons.description_outlined, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t(
                    'آپ کے محفوظ کردہ ڈرافٹس یہاں دکھائی دیں گے۔',
                    'आपके सहेजे गए ड्राफ़्ट यहाँ दिखाई देंगे।',
                    'Your saved drafts will appear here.',
                  ),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      for (final draft in widget.drafts.reversed)
        Card(
          color: colors.surface,
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 5,
            ),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.description_outlined,
                color: colors.primary,
                size: 29,
              ),
            ),
            title: Text(
              draft.request['patient'].isEmpty
                  ? designs[draft.template].name(l)
                  : draft.request['patient'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              draft.request['hospital'].isEmpty
                  ? draft.request['address']
                  : draft.request['hospital'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            onTap: busy
                ? null
                : () => open(draft.request, draft.template, draft.id),
            trailing: IconButton(
              tooltip: t('ڈرافٹ حذف کریں', 'ड्राफ़्ट हटाएँ', 'Delete draft'),
              onPressed: busy ? null : () => removeDrafts(draft.id),
              icon: Icon(Icons.delete_outline, color: colors.primary),
            ),
          ),
        ),
    ],
    );
  }

  Widget poster(PosterRequest data, int index) => Semantics(
    image: true,
    label: '${designs[index].name(l)}. ${data.group}. ${data['patient']}',
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: CustomPaint(painter: PosterPainter(data, l, index)),
    ),
  );

  Widget editor() => Form(
    key: form,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: poster(request, design),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => setDesign(nextDesign(recent, random)),
                icon: const Icon(Icons.shuffle),
                label: Text(t('نیا ڈیزائن', 'नया डिज़ाइन', 'New design')),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : gallery,
                icon: const Icon(Icons.grid_view),
                label: Text(t('تمام ڈیزائن', 'सभी डिज़ाइन', 'Design gallery')),
              ),
            ],
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            key: ValueKey(group),
            initialValue: group,
            decoration: InputDecoration(
              labelText: label(l, 'group'),
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final value in groups)
                DropdownMenuItem(
                  value: value,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(value),
                  ),
                ),
            ],
            onChanged: busy ? null : (value) => mutate(() => group = value!),
          ),
          for (final field in requiredFields) input(field),
          ExpansionTile(
            title: Text(
              t('اختیاری تفصیلات', 'वैकल्पिक जानकारी', 'Optional details'),
            ),
            children: [
              for (final name in fields.skip(requiredFields.length))
                input(name),
            ],
          ),
          ExpansionTile(
            title: Text(
              t('ڈیزائن کی ترتیبات', 'डिज़ाइन सेटिंग', 'Design settings'),
            ),
            children: [
              toggle(
                t('فوری ضرورت', 'तत्काल आवश्यकता', 'Urgent badge'),
                emergency,
                (v) => emergency = v,
              ),
              toggle(
                t('تصویر', 'चित्र', 'Illustration'),
                illustration,
                (v) => illustration = v,
              ),
              toggle(
                t('متبادل رنگ', 'वैकल्पिक रंग', 'Alternate accent'),
                accent,
                (v) => accent = v,
              ),
              toggle(
                t('بڑا بلڈ گروپ', 'बड़ा रक्त समूह', 'Larger blood group'),
                largeGroup,
                (v) => largeGroup = v,
              ),
              toggle(
                t('ترتیب بدلیں', 'क्रम बदलें', 'Reverse columns'),
                reverse,
                (v) => reverse = v,
              ),
              if (appDownloadUrl.isNotEmpty)
                toggle(
                  t(
                    'ڈاؤن لوڈ دعوت',
                    'डाउनलोड आमंत्रण',
                    'Include download invitation',
                  ),
                  invite,
                  (v) => invite = v,
                ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => mutate(() {
                        emergency = true;
                        illustration = true;
                        accent = false;
                        largeGroup = false;
                        reverse = false;
                        invite = false;
                      }),
                child: Text(
                  t('اصل انداز بحال کریں', 'मूल शैली लौटाएँ', 'Reset style'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : exportDialog,
                icon: const Icon(Icons.ios_share),
                label: Text(
                  t(
                    'ایکسپورٹ یا شیئر',
                    'निर्यात या साझा करें',
                    'Export or share',
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => run(saveDraft),
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  t('ڈرافٹ محفوظ کریں', 'ड्राफ़्ट सहेजें', 'Save draft'),
                ),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (await confirm(
                              t(
                                'موجودہ فیلڈز خالی کریں؟',
                                'मौजूदा फ़ील्ड खाली करें?',
                                'Clear the current fields?',
                              ),
                            ) &&
                            mounted) {
                          open(const PosterRequest(), design, draftId);
                          mutate(() {});
                        }
                      },
                child: Text(
                  t('فیلڈز خالی کریں', 'फ़ील्ड खाली करें', 'Clear fields'),
                ),
              ),
              if (widget.drafts.isNotEmpty)
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if ((!dirty ||
                                  await confirm(
                                    t(
                                      'آخری ڈرافٹ بحال کریں؟',
                                      'पिछला ड्राफ़्ट लौटाएँ?',
                                      'Restore the last draft?',
                                    ),
                                  )) &&
                              mounted) {
                            final draft = widget.drafts.last;
                            open(draft.request, draft.template, draft.id);
                          }
                        },
                  child: Text(
                    t(
                      'آخری ڈرافٹ بحال کریں',
                      'पिछला ड्राफ़्ट लौटाएँ',
                      'Restore last draft',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget toggle(String title, bool value, ValueChanged<bool> assign) =>
      SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: busy ? null : (value) => mutate(() => assign(value)),
      );

  Widget input(String field) {
    final phone = ['primary', 'secondary', 'dial'].contains(field);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controllers[field],
        enabled: !busy,
        decoration: InputDecoration(
          labelText: label(l, field),
          border: const OutlineInputBorder(),
        ),
        maxLines: field == 'address' || field == 'note' ? 2 : 1,
        maxLength: phone ? 32 : 180,
        keyboardType: phone ? TextInputType.phone : TextInputType.text,
        textDirection: phone ? TextDirection.ltr : null,
        onChanged: (_) => mutate(() {}),
        validator: (value) {
          if (!requiredFields.contains(field)) return null;
          if (value == null || value.trim().isEmpty) {
            return t(
              'یہ خانہ لازمی ہے',
              'यह जानकारी आवश्यक है',
              'This field is required',
            );
          }
          if (phone && !validPhone(value)) {
            return t(
              'درست فون نمبر درج کریں',
              'सही फ़ोन नंबर डालें',
              'Enter a valid phone number',
            );
          }
          return null;
        },
      ),
    );
  }

  Future<void> gallery() async {
    final selected = await showModalBottomSheet<int>(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .75,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: designs.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 330,
                childAspectRatio: 1.43,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) => Card(
                child: Column(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context, index),
                        child: Center(child: poster(request, index)),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, index),
                            child: Text(
                              designs[index].name(l),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: t('پسندیدہ', 'पसंदीदा', 'Favorite'),
                          icon: Icon(
                            widget.favorites.contains(index)
                                ? Icons.favorite
                                : Icons.favorite_outline,
                          ),
                          onPressed: () async {
                            await run(() async {
                              final wasFavorite = widget.favorites.remove(
                                index,
                              );
                              if (!wasFavorite) widget.favorites.add(index);
                              try {
                                await widget.persist();
                              } on Object {
                                if (wasFavorite) {
                                  widget.favorites.add(index);
                                } else {
                                  widget.favorites.remove(index);
                                }
                                rethrow;
                              }
                            });
                            if (context.mounted) refresh(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) setDesign(selected);
  }

  Future<void> saveDraft() async {
    final id = draftId ?? DateTime.now().microsecondsSinceEpoch.toString();
    final replacement = PosterDraft(id, request, design);
    final original = widget.drafts.toList();
    widget.drafts
      ..removeWhere((draft) => draft.id == id)
      ..add(replacement);
    try {
      await widget.persist();
    } on Object {
      widget.drafts
        ..clear()
        ..addAll(original);
      rethrow;
    }
    if (mounted) {
      setState(() {
        draftId = id;
        dirty = false;
      });
    }
    notice(t('ڈرافٹ محفوظ ہوگیا', 'ड्राफ़्ट सहेजा गया', 'Draft saved'));
  }

  Future<void> removeDrafts([String? id]) async {
    if (!await confirm(
      t(
        'منتخب ڈرافٹس حذف کریں؟',
        'चुने हुए ड्राफ़्ट हटाएँ?',
        'Delete the selected drafts?',
      ),
    )) {
      return;
    }
    if (!mounted) return;
    await run(() async {
      final original = widget.drafts.toList();
      widget.drafts.removeWhere((draft) => id == null || draft.id == id);
      try {
        await widget.persist();
      } on Object {
        widget.drafts
          ..clear()
          ..addAll(original);
        rethrow;
      }
      if (mounted && (id == null || id == draftId)) {
        setState(() => draftId = null);
      }
    });
  }

  Future<void> exportDialog() async {
    if (!(form.currentState?.validate() ?? false)) {
      notice(
        t(
          'تمام لازمی تفصیلات درست کریں۔',
          'सभी आवश्यक जानकारियाँ ठीक करें।',
          'Check all required details.',
        ),
      );
      return;
    }
    if (demo &&
        !await confirm(
          t(
            'یہ فرضی نمونہ ہے۔ جاری رکھیں؟',
            'यह काल्पनिक नमूना है। जारी रखें?',
            'This is a fictional example. Continue?',
          ),
        )) {
      return;
    }
    if (!mounted) return;
    var jpeg = false;
    var quality = 95.0;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(
                    jpeg ? 'JPEG · 1920 × 1080' : 'PNG · 1920 × 1080',
                  ),
                  value: jpeg,
                  onChanged: (value) => update(() => jpeg = value),
                ),
                if (jpeg)
                  Slider(
                    value: quality,
                    min: 60,
                    max: 100,
                    divisions: 40,
                    label: '${quality.round()}%',
                    onChanged: (value) => update(() => quality = value),
                  ),
                ListTile(
                  leading: const Icon(Icons.save_alt),
                  title: Text(
                    t('تصویر محفوظ کریں', 'चित्र सहेजें', 'Save image'),
                  ),
                  onTap: () => Navigator.pop(context, 'save'),
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: Text(
                    t(
                      'صرف پوسٹر شیئر کریں',
                      'केवल पोस्टर साझा करें',
                      'Share poster only',
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'share'),
                ),
                if (appDownloadUrl.isNotEmpty) ...[
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(
                      t(
                        'پوسٹر اور لنک شیئر کریں',
                        'पोस्टर और लिंक साझा करें',
                        'Share poster + app link',
                      ),
                    ),
                    onTap: () => Navigator.pop(context, 'invite'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: Text(
                      t(
                        'ڈاؤن لوڈ پیغام کاپی کریں',
                        'डाउनलोड संदेश कॉपी करें',
                        'Copy download message',
                      ),
                    ),
                    onTap: () => Navigator.pop(context, 'copy'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    await run(() async {
      if (action == 'copy') {
        await Clipboard.setData(ClipboardData(text: inviteMessage(l)));
        notice(t('پیغام کاپی ہوگیا', 'संदेश कॉपी हुआ', 'Message copied'));
        return;
      }
      final image = await PosterPainter(request, l, design).render();
      final options = ExportOptions(jpeg, quality.round());
      final List<int> bytes;
      try {
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
        bytes = !jpeg
            ? png
            : (await Device.channel.invokeMethod<Uint8List>('jpeg', {
                'bytes': png,
                'quality': options.quality,
              }))!;
      } finally {
        image.dispose();
      }
      final payload = SharePayload(
        options,
        bytes,
        action == 'invite' ? inviteMessage(l) : null,
      );
      if (action == 'save') {
        final uri = await widget.device.save(payload);
        if (uri != null) {
          notice(
            t('تصویر محفوظ ہوگئی', 'चित्र सहेजा गया', 'Image saved'),
            action: SnackBarAction(
              label: t('کھولیں', 'खोलें', 'Open'),
              onPressed: () => run(() => widget.device.open(uri, options.mime)),
            ),
          );
        }
      } else {
        await widget.device.share(payload);
      }
    });
  }
}
