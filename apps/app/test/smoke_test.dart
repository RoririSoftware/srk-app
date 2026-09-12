import 'package:app/main.dart';
import 'package:app/screens/add_farmer.dart';
import 'package:app/screens/certificate_ocr.dart';
import 'package:app/screens/farmer_detail.dart';
import 'package:app/match.dart';
import 'package:app/models.dart';
import 'package:app/sample_data.dart';
import 'package:app/screens/home.dart';
import 'package:app/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Walks the demo path a client would be shown at phone size. Any layout
/// overflow or null error on these screens fails here rather than in the
/// meeting - flutter_test turns a RenderFlex overflow into a test failure.
void main() {
  /// Scroll the control into view first: tapping an off-screen widget lands on
  /// whatever happens to be at those coordinates instead.
  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('sign in and move through every tab', (tester) async {
    phone(tester);
    await tester.pumpWidget(const SrkApp());
    expect(find.text('Staff sign in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hi, '), findsOneWidget);
    expect(find.text('Total farmers'), findsOneWidget);

    for (final tab in ['Farmers', 'Reports', 'Profile', 'Home']) {
      await tester.tap(find.text(tab), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(find.text('Recent activity'), findsOneWidget);

    // The bottom bar must stay a bar: a greedy Column here once grew to the
    // full screen height and collapsed the page body to nothing.
    final bar = tester.getRect(find.ancestor(of: find.text('Profile'), matching: find.byType(SafeArea)).last);
    expect(bar.height, lessThan(120));
    expect(bar.bottom, closeTo(tester.view.physicalSize.height / tester.view.devicePixelRatio, 1));
  });

  testWidgets('farmer detail shows the patta records and the match report', (tester) async {
    phone(tester);
    final farmer = store.farmers.first;
    await tester.pumpWidget(MaterialApp(home: FarmerDetailPage(farmer: farmer)));
    await tester.pumpAndSettle();

    expect(find.text('Patta records (${farmer.pattas.length})'), findsOneWidget);
    expect(find.text('Certificate matched'), findsOneWidget);
    expect(find.text('Lead status'), findsOneWidget);

    // Every comparison row renders.
    for (final row in farmer.report!.rows) {
      expect(find.text(row.label), findsWidgets, reason: 'missing row ${row.label}');
    }
  });

  testWidgets('certificate page renders its empty state', (tester) async {
    phone(tester);
    await tester.pumpWidget(MaterialApp(home: CertificateOcrPage(farmer: store.farmers.last)));
    await tester.pumpAndSettle();
    expect(find.text('Upload the certificate'), findsOneWidget);
    expect(find.text('Compare'), findsOneWidget);
  });

  testWidgets('the lead wizard blocks on required fields and walks every step', (tester) async {
    phone(tester);
    await tester.pumpWidget(const MaterialApp(home: AddFarmerPage()));
    await tester.pumpAndSettle();
    expect(find.text('Attachments'), findsOneWidget);

    await tapButton(tester, 'Next'); // documents are optional
    expect(find.text('Basic Information'), findsOneWidget);

    await tapButton(tester, 'Next'); // required fields still empty
    expect(find.textContaining('Fill in'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Farmer Name *'), 'Test Farmer');
    await tester.enterText(find.widgetWithText(TextField, 'S / O · W / O *'), 'Test Father');
    await tester.enterText(find.widgetWithText(TextField, 'Mobile Number *'), '9000000000');
    await tester.pumpAndSettle();

    await tapButton(tester, 'Next');
    expect(find.text('Land Information'), findsOneWidget);
  });

  // The comparison result is what the whole demo builds up to, so render it on
  // its own with both a clean match and a broken one.
  testWidgets('the comparison result renders matched and mismatched rows', (tester) async {
    phone(tester);
    final pattas = [
      Patta(pattaNumber: '2719', surveyNumber: '230', subDivision: '3', extent: '0.4448', extentUnit: 'Acres', district: 'Tirunelveli', taluk: 'Palayamkottai', village: 'Tharuval', ownerName: 'Thiru Ayyakutty'),
    ];
    final cert = sampleCertificate();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            CertDetails(cert: cert),
            const SizedBox(height: 12),
            LandRows(rows: cert.rows),
            const SizedBox(height: 12),
            ReportPanel(report: compareCertificate(cert, pattas, now: DateTime(2026, 9, 12))),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sample certificate loaded'), findsOneWidget);
    expect(find.textContaining('Land details from certificate'), findsOneWidget);
    expect(find.text('Match'), findsWidgets);
    expect(find.text('Mismatch'), findsWidgets);
    expect(find.textContaining('need review'), findsOneWidget);
  });

  testWidgets('shell lays out as a sidebar on a wide screen', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();
    expect(find.text('SKR TRADER'), findsWidgets);
    expect(find.text('Recent activity'), findsOneWidget);
  });
}
