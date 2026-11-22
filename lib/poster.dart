import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'model.dart';

const posterSize = Size(1920, 1080);

class PosterPainter extends CustomPainter {
  const PosterPainter(this.request, this.language, this.template);
  final PosterRequest request;
  final Language language;
  final int template;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 960, size.height / 540);
    final design = designs[template];
    final paper = Color(design.paper);
    final ink = Color(design.ink);
    final red = Color(design.red);
    final gold = Color(request.accent ? 0xffb8f2e6 : design.gold);
    final rtl = language.rtl;
    final flip = rtl != request.reverse;
    final fog = Color.lerp(paper, red, .16)!;
    const full = Rect.fromLTWH(0, 0, 960, 540);
    canvas.drawRect(
      full,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(960, 540), [
          paper,
          fog,
        ]),
    );

    void box(Rect rect, Color color, [double radius = 0]) => canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
    void dot(Offset position, double radius, Color color) =>
        canvas.drawCircle(position, radius, Paint()..color = color);
    void path(List<Offset> points, Color color, {double? stroke}) {
      final line = Path()..addPolygon(points, stroke == null);
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = stroke == null ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = stroke ?? 0
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    final rail = <int>{1, 3, 6, 7, 10}.contains(template);
    final center = <int>{2, 5, 9}.contains(template);
    final low = <int>{4, 8, 11}.contains(template);
    switch (template) {
      case 0:
        path(const [
          Offset(0, 0),
          Offset(960, 0),
          Offset(960, 96),
          Offset(710, 149),
          Offset(0, 113),
        ], red);
      case 1:
        box(const Rect.fromLTWH(0, 0, 960, 96), red);
        for (var i = 0; i < 14; i++) {
          path(
            [Offset(i * 80.0, 0), Offset(i * 80.0 - 360, 540)],
            gold.withValues(alpha: .09),
            stroke: 2,
          );
        }
      case 2:
        dot(const Offset(480, 275), 242, fog);
        dot(const Offset(480, 275), 213, paper);
        box(const Rect.fromLTWH(37, 32, 886, 104), red, 52);
      case 3:
        box(const Rect.fromLTWH(0, 0, 960, 128), red);
        box(const Rect.fromLTWH(32, 140, 896, 265), paper, 24);
      case 4:
        path(
          const [
            Offset(0, 155),
            Offset(155, 155),
            Offset(183, 105),
            Offset(212, 190),
            Offset(252, 135),
            Offset(286, 155),
            Offset(960, 155),
          ],
          red.withValues(alpha: .3),
          stroke: 5,
        );
      case 5:
        dot(const Offset(480, 288), 245, red.withValues(alpha: .23));
        dot(const Offset(480, 288), 185, red.withValues(alpha: .27));
      case 6:
        box(const Rect.fromLTWH(34, 116, 892, 4), red);
        box(const Rect.fromLTWH(34, 127, 892, 1), red);
        box(const Rect.fromLTWH(34, 400, 892, 4), red);
      case 7:
        path(const [
          Offset(0, 0),
          Offset(960, 0),
          Offset(960, 88),
          Offset(0, 159),
        ], red);
        path(const [
          Offset(0, 432),
          Offset(960, 342),
          Offset(960, 540),
          Offset(0, 540),
        ], fog);
      case 8:
        box(const Rect.fromLTWH(31, 28, 898, 484), paper, 32);
        box(const Rect.fromLTWH(54, 46, 852, 104), fog, 21);
      case 9:
        box(const Rect.fromLTWH(0, 0, 960, 111), red);
        box(const Rect.fromLTWH(0, 406, 960, 134), fog);
        for (var i = 0; i < 16; i++) {
          dot(Offset(50 + i * 57, 117), 2.5, red);
        }
      case 10:
        for (var i = 0; i < 13; i++) {
          for (var j = 0; j < 7; j++) {
            dot(
              Offset(40 + i * 73, 32 + j * 78),
              2,
              gold.withValues(alpha: .28),
            );
          }
        }
        box(const Rect.fromLTWH(36, 102, 888, 3), gold);
      case 11:
        path(const [Offset(0, 0), Offset(214, 0), Offset(0, 210)], fog);
        path(const [Offset(960, 540), Offset(745, 540), Offset(960, 326)], fog);
        box(const Rect.fromLTWH(35, 137, 890, 3), red);
    }

    void text(
      String value,
      Rect rect,
      double fontSize,
      Color color, {
      int lines = 1,
      bool ltr = false,
      bool title = false,
      bool bold = false,
      TextAlign align = TextAlign.center,
    }) {
      if (value.isEmpty) return;
      final painter = TextPainter(
        textAlign: align,
        textDirection: ltr || !rtl ? TextDirection.ltr : TextDirection.rtl,
        maxLines: lines,
        ellipsis: '…',
        textScaler: TextScaler.noScaling,
      );
      for (var current = fontSize; current >= 8; current -= 2) {
        painter.text = TextSpan(
          text: value,
          style: TextStyle(
            color: color,
            fontSize: current,
            fontFamily: title && rtl ? 'Nastaliq' : language.font,
            fontFamilyFallback: const ['Naskh', 'Devanagari', 'Roboto'],
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        );
        painter.layout(minWidth: rect.width, maxWidth: rect.width);
        if (!painter.didExceedMaxLines && painter.height <= rect.height) break;
      }
      canvas.save();
      canvas.clipRect(rect);
      painter.paint(
        canvas,
        Offset(rect.left, rect.top + (rect.height - painter.height) / 2),
      );
      canvas.restore();
      painter.dispose();
    }

    final redHeader = {0, 1, 2, 3, 7, 9}.contains(template);
    final heading = request['title'].isEmpty
        ? language.t(
            'ضرورت برائے خون',
            'रक्त की आवश्यकता',
            'Blood urgently needed',
          )
        : request['title'];
    text(
      heading,
      const Rect.fromLTWH(105, 22, 750, 101),
      58,
      redHeader ? gold : ink,
      title: true,
      bold: true,
    );
    if (request.emergency && !request.demo) {
      text(
        language.t('فوری', 'तत्काल', 'URGENT'),
        const Rect.fromLTWH(38, 32, 78, 25),
        15,
        redHeader ? Colors.white : ink,
        bold: true,
      );
    }
    if (request.demo) {
      box(const Rect.fromLTWH(734, 110, 193, 26), gold, 13);
      text(
        language.t(
          'نمونہ · حقیقی درخواست نہیں',
          'नमूना · वास्तविक अनुरोध नहीं',
          'DEMO · NOT A REAL REQUEST',
        ),
        const Rect.fromLTWH(740, 110, 181, 26),
        12,
        const Color(0xff271824),
        bold: true,
      );
    }

    final badgeX = center
        ? 480.0
        : flip
        ? 170.0
        : 790.0;
    final badgeY = center
        ? 211.0
        : low
        ? 300.0
        : 268.0;
    final badgeWidth = request.largeGroup ? 220.0 : 180.0;
    final badge = Rect.fromCenter(
      center: Offset(badgeX, badgeY),
      width: badgeWidth,
      height: center ? 105 : 137,
    );
    box(badge.inflate(5), gold, template.isEven ? 26 : 75);
    box(badge, red, template.isEven ? 22 : 70);
    text(
      request.group,
      Rect.fromLTWH(
        badge.left + 10,
        badge.top + 3,
        badge.width - 20,
        badge.height - 33,
      ),
      center ? 60 : 76,
      Colors.white,
      ltr: true,
      bold: true,
    );
    text(
      label(language, 'group'),
      Rect.fromLTWH(badge.left + 9, badge.bottom - 34, badge.width - 18, 29),
      17,
      gold,
    );
    if (request.illustration && !center) {
      final x = badgeX;
      final y = badge.top - 31;
      final drop = Path()
        ..moveTo(x, y - 27)
        ..cubicTo(x - 9, y - 10, x - 30, y + 8, x - 17, y + 21)
        ..cubicTo(x - 7, y + 35, x + 14, y + 32, x + 20, y + 17)
        ..cubicTo(x + 27, y + 5, x + 10, y - 12, x, y - 27)
        ..close();
      canvas.drawPath(drop, Paint()..color = red);
      path(
        [
          Offset(x - 13, y + 10),
          Offset(x - 4, y + 10),
          Offset(x, y + 2),
          Offset(x + 5, y + 17),
          Offset(x + 9, y + 10),
          Offset(x + 15, y + 10),
        ],
        Colors.white,
        stroke: 2,
      );
    }

    const keys = ['patient', 'hospital', 'address'];
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final x = center
          ? 37 + i * 301.0
          : flip
          ? 309.0
          : 38.0;
      final y = center ? 287.0 : 155 + i * 74.0;
      final width = center ? 284.0 : 613.0;
      if (center) {
        box(Rect.fromLTWH(x, y, width, 100), paper, 16);
        text(
          label(language, key),
          Rect.fromLTWH(x + 8, y + 3, width - 16, 29),
          16,
          ink,
          bold: true,
        );
        text(
          request[key],
          Rect.fromLTWH(x + 13, y + 32, width - 26, 65),
          27,
          ink,
          lines: 2,
        );
      } else {
        final labelX = rtl ? x + width - 149 : x;
        final bodyX = rtl ? x : x + 157;
        if (!rail) box(Rect.fromLTWH(x, y, width, 64), fog, 13);
        box(Rect.fromLTWH(labelX, y + 4, 149, 56), red, rail ? 4 : 12);
        text(
          label(language, key),
          Rect.fromLTWH(labelX + 6, y + 5, 137, 54),
          20,
          Colors.white,
          bold: true,
        );
        text(
          request[key],
          Rect.fromLTWH(bodyX + 9, y + 3, width - 174, 58),
          32,
          ink,
          lines: 2,
        );
      }
    }

    final detail = ['units', 'deadline', 'ward', 'note', 'eligibility']
        .where((key) => request[key].isNotEmpty)
        .map((key) => '${label(language, key)}: ${request[key]}')
        .join('  •  ');
    text(detail, const Rect.fromLTWH(38, 380, 884, 40), 15, ink, lines: 2);

    final contact = language.t(
      'براہِ کرم رابطہ کریں',
      'कृपया संपर्क करें',
      'Please contact',
    );
    text(contact, const Rect.fromLTWH(277, 417, 406, 27), 20, ink, bold: true);
    for (var i = 0; i < 2; i++) {
      final x = 61 + i * 426.0;
      final number = request[i == 0 ? 'primary' : 'secondary'];
      final dial = request['dial'];
      final display =
          dial.isEmpty ||
              number.startsWith('+') ||
              number.startsWith('00') ||
              number.isEmpty
          ? number
          : '$dial ${number.replaceFirst(RegExp(r'^0'), '')}';
      box(Rect.fromLTWH(x, 447, 412, 45), red, rail ? 8 : 23);
      text(
        display,
        Rect.fromLTWH(x + 9, 449, 394, 41),
        28,
        Colors.white,
        bold: true,
        ltr: true,
      );
    }
    final footer = request['footer'].isNotEmpty
        ? request['footer']
        : language.t(
            'آپ کا عطیہ کسی کی زندگی بچا سکتا ہے',
            'आपका रक्तदान किसी की जान बचा सकता है',
            'Your donation could save a life',
          );
    text(
      footer,
      Rect.fromLTWH(
        38,
        495,
        884,
        request.invite && appDownloadUrl.isNotEmpty ? 19 : 27,
      ),
      17,
      ink,
      bold: true,
    );
    if (request.invite && appDownloadUrl.isNotEmpty) {
      text(
        inviteMessage(language),
        const Rect.fromLTWH(39, 514, 882, 20),
        12,
        ink,
      );
    }
    canvas.restore();
  }

  Future<ui.Image> render() async {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), posterSize);
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(
        posterSize.width.toInt(),
        posterSize.height.toInt(),
      );
    } finally {
      picture.dispose();
    }
  }

  @override
  bool shouldRepaint(PosterPainter oldDelegate) =>
      oldDelegate.request != request ||
      oldDelegate.language != language ||
      oldDelegate.template != template;
}
