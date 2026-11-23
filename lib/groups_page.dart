import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'groups_data.dart';
import 'model.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage(this.language, {super.key, this.admin = false});

  final Language language;
  final bool admin;

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  late var connection = DonationGroups.connect(admin: widget.admin);
  bool signedIn = false;
  bool busy = false;
  bool pending = true;
  String t(String ur, String hi, String en) => widget.language.t(ur, hi, en);

  Future<void> run(Future<void> Function() action, {String? success}) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted && success != null) notify(success);
    } catch (_) {
      if (mounted) {
        notify(
          t(
            'کارروائی مکمل نہیں ہوئی۔ کنکشن اور اجازت چیک کریں۔',
            'कार्रवाई पूरी नहीं हुई। कनेक्शन और अनुमति जाँचें।',
            'Could not complete the action. Check your connection and access.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void notify(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: connection,
    builder: (context, snapshot) {
      final store = snapshot.data;
      return PopScope(
        canPop: !busy && !signedIn,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && signedIn && !busy && store != null) {
            run(() async {
              await store.auth.signOut();
              if (mounted) setState(() => signedIn = false);
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.admin
                  ? t('ایڈمن', 'एडमिन', 'Admin')
                  : t(
                      'واٹس ایپ عطیہ گروپس',
                      'व्हाट्सऐप रक्तदान समूह',
                      'WhatsApp Donation Groups',
                    ),
            ),
            actions: [
              if (signedIn && store != null)
                IconButton(
                  tooltip: t('لاگ آؤٹ', 'लॉग आउट', 'Sign out'),
                  icon: const Icon(Icons.logout),
                  onPressed: busy
                      ? null
                      : () => run(() async {
                          await store.auth.signOut();
                          if (mounted) setState(() => signedIn = false);
                        }),
                ),
            ],
          ),
          floatingActionButton: store != null && (!widget.admin || signedIn)
              ? FloatingActionButton(
                  tooltip: widget.admin
                      ? t('گروپ شامل کریں', 'समूह जोड़ें', 'Add group')
                      : t('گروپ تجویز کریں', 'समूह सुझाएँ', 'Suggest group'),
                  onPressed: busy ? null : () => editGroup(store),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: busy ? const LinearProgressIndicator() : null,
          body: SafeArea(
            child: store == null
                ? Center(
                    child: snapshot.hasError
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t(
                                  'گروپس دستیاب نہیں ہیں۔',
                                  'समूह उपलब्ध नहीं हैं।',
                                  'Groups are unavailable.',
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(
                                  () => connection = DonationGroups.connect(
                                    admin: widget.admin,
                                  ),
                                ),
                                child: Text(
                                  t('دوبارہ کوشش', 'फिर कोशिश करें', 'Retry'),
                                ),
                              ),
                            ],
                          )
                        : const CircularProgressIndicator(),
                  )
                : widget.admin && !signedIn
                ? loginForm(store)
                : groupList(store),
          ),
        ),
      );
    },
  );

  Widget loginForm(DonationGroups store) {
    return _EntryForm(
      firstLabel: t('ای میل', 'ईमेल', 'Email'),
      secondLabel: t('پاس ورڈ', 'पासवर्ड', 'Password'),
      button: t('لاگ اِن', 'लॉग इन', 'Log in'),
      password: true,
      busy: busy,
      onSubmit: (email, password) => run(() async {
        await store.login(email.trim(), password);
        if (mounted) setState(() => signedIn = true);
      }),
    );
  }

  Widget groupList(DonationGroups store) {
    final reviewing = widget.admin && pending;
    final collection = reviewing ? store.pending : store.approved;
    return Column(
      children: [
        if (widget.admin)
          Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(
                    t(
                      'زیرِ التوا درخواستیں',
                      'लंबित अनुरोध',
                      'Pending Requests',
                    ),
                  ),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(
                    t('منظور شدہ گروپس', 'स्वीकृत समूह', 'Approved groups'),
                  ),
                ),
              ],
              selected: {pending},
              onSelectionChanged: busy
                  ? null
                  : (values) => setState(() => pending = values.single),
            ),
          ),
        Expanded(
          child: StreamBuilder(
            key: ValueKey(collection.path),
            stream: reviewing ? store.pendingStream : store.approvedStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    t(
                      'فہرست نہیں کھل سکی۔',
                      'सूची खुल नहीं सकी।',
                      'Could not load the list.',
                    ),
                  ),
                );
              }
              final documents = snapshot.data?.docs;
              if (documents == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (documents.isEmpty) {
                return Center(
                  child: Text(
                    reviewing
                        ? t(
                            'کوئی زیرِ التوا درخواست نہیں۔',
                            'कोई लंबित अनुरोध नहीं है।',
                            'No pending requests.',
                          )
                        : t(
                            'ابھی کوئی منظور شدہ گروپ نہیں۔',
                            'अभी कोई स्वीकृत समूह नहीं है।',
                            'No approved groups yet.',
                          ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final document = documents[index];
                  final data = document.data();
                  final name = data['name'] as String? ?? '';
                  final invite = canonicalInvite(
                    data['invite'] as String? ?? '',
                  );
                  return ListTile(
                    title: Text(name),
                    subtitle: widget.admin && invite != null
                        ? Text(invite, textDirection: TextDirection.ltr)
                        : null,
                    trailing: widget.admin
                        ? PopupMenuButton<String>(
                            enabled: !busy,
                            onSelected: (action) async {
                              switch (action) {
                                case 'approve':
                                  await run(
                                    () => store.approve(document.reference),
                                  );
                                case 'edit':
                                  await editGroup(store, document);
                                case 'remove':
                                  await removeGroup(
                                    document.reference,
                                    reviewing,
                                  );
                              }
                            },
                            itemBuilder: (_) => [
                              if (reviewing)
                                PopupMenuItem(
                                  value: 'approve',
                                  child: Text(
                                    t('منظور کریں', 'स्वीकार करें', 'Approve'),
                                  ),
                                )
                              else
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(
                                    t('ترمیم', 'संपादित करें', 'Edit'),
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'remove',
                                child: Text(
                                  reviewing
                                      ? t(
                                          'مسترد کریں',
                                          'अस्वीकार करें',
                                          'Reject',
                                        )
                                      : t('حذف کریں', 'हटाएँ', 'Delete'),
                                ),
                              ),
                            ],
                          )
                        : FilledButton(
                            onPressed: invite == null || busy
                                ? null
                                : () => run(() async {
                                    if (!await launchUrl(
                                      Uri.parse(invite),
                                      mode: LaunchMode.externalApplication,
                                    )) {
                                      throw StateError(
                                        'No application opened the invite',
                                      );
                                    }
                                  }),
                            child: Text(t('شامل ہوں', 'जुड़ें', 'Join')),
                          ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> removeGroup(
    DocumentReference<Map<String, dynamic>> document,
    bool reviewing,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          reviewing
              ? t(
                  'درخواست مسترد کریں؟',
                  'अनुरोध अस्वीकार करें?',
                  'Reject this request?',
                )
              : t('گروپ حذف کریں؟', 'समूह हटाएँ?', 'Delete this group?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('منسوخ', 'रद्द करें', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('تصدیق', 'पुष्टि करें', 'Confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await run(document.delete);
  }

  Future<void> editGroup(
    DonationGroups store, [
    DocumentSnapshot<Map<String, dynamic>>? document,
  ]) async {
    final data = document?.data();
    final group = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => Dialog(
        child: _EntryForm(
          firstLabel: t('گروپ کا نام', 'समूह का नाम', 'Group name'),
          secondLabel: t(
            'واٹس ایپ دعوتی لنک',
            'व्हाट्सऐप आमंत्रण लिंक',
            'WhatsApp invite link',
          ),
          button: widget.admin
              ? t('محفوظ کریں', 'सहेजें', 'Save')
              : t('درخواست بھیجیں', 'अनुरोध भेजें', 'Submit for review'),
          busy: false,
          initialName: data?['name'] as String? ?? '',
          initialLink: data?['invite'] as String? ?? '',
          invalid: t(
            'درست نام اور واٹس ایپ لنک دیں۔',
            'सही नाम और व्हाट्सऐप लिंक दें।',
            'Enter a valid name and WhatsApp invite link.',
          ),
          onSubmit: (name, invite) => Navigator.pop(context, {
            'name': name.trim(),
            'invite': canonicalInvite(invite)!,
          }),
        ),
      ),
    );
    if (group == null || !mounted) return;
    await run(
      () async {
        if (document != null) {
          await document.reference.update(group);
        } else if (widget.admin) {
          await store.approved.add(group);
        } else {
          await store.submit(group);
        }
      },
      success: widget.admin
          ? null
          : t(
              'درخواست بھیج دی گئی۔',
              'अनुरोध भेज दिया गया।',
              'Request submitted for review.',
            ),
    );
  }
}

class _EntryForm extends StatefulWidget {
  const _EntryForm({
    required this.firstLabel,
    required this.secondLabel,
    required this.button,
    required this.onSubmit,
    required this.busy,
    this.password = false,
    this.initialName = '',
    this.initialLink = '',
    this.invalid,
  });

  final String firstLabel, secondLabel, button, initialName, initialLink;
  final String? invalid;
  final bool password, busy;
  final void Function(String, String) onSubmit;

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  late final first = TextEditingController(text: widget.initialName);
  late final second = TextEditingController(text: widget.initialLink);
  final form = GlobalKey<FormState>();

  @override
  void dispose() {
    first.dispose();
    second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: first,
            decoration: InputDecoration(labelText: widget.firstLabel),
            maxLength: widget.password ? null : 80,
            keyboardType: widget.password
                ? TextInputType.emailAddress
                : TextInputType.text,
            validator: (value) => value!.trim().isEmpty
                ? widget.invalid ?? widget.firstLabel
                : null,
          ),
          TextFormField(
            controller: second,
            decoration: InputDecoration(labelText: widget.secondLabel),
            obscureText: widget.password,
            autocorrect: false,
            enableSuggestions: false,
            textDirection: TextDirection.ltr,
            keyboardType: widget.password
                ? TextInputType.visiblePassword
                : TextInputType.url,
            validator: (value) =>
                (widget.password
                    ? value!.isEmpty
                    : canonicalInvite(value!) == null)
                ? widget.invalid ?? widget.secondLabel
                : null,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.busy
                ? null
                : () {
                    if (form.currentState!.validate()) {
                      widget.onSubmit(first.text, second.text);
                    }
                  },
            child: Text(widget.button),
          ),
        ],
      ),
    ),
  );
}
