import 'package:app/match.dart';
import 'package:app/models.dart';
import 'package:app/sample_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// The certificate/patta comparison is the product. Everything else is forms.
void main() {
  final today = DateTime(2026, 9, 12);

  Patta acres(String patta, String survey, String sub, String extent) => Patta(
        pattaNumber: patta,
        surveyNumber: survey,
        subDivision: sub,
        extent: extent,
        extentUnit: 'Acres',
        district: 'Tirunelveli',
        taluk: 'Palayamkottai',
        village: 'Tharuval',
        ownerName: 'Thiru Ayyakutty',
      );

  List<Patta> matchingPattas() => [
        acres('2719', '230', '3', '0.4448'),
        acres('4163', '229', '1', '0.2718'),
        acres('3497', '233', '', '0.7907'),
      ];

  test('sample certificate matches the sample patta records', () {
    final report = compareCertificate(sampleCertificate(), matchingPattas(), now: today);
    expect(report.mismatched, 0, reason: report.rows.where((r) => r.verdict != Verdict.match).map((r) => '${r.label}: ${r.certificate} vs ${r.patta}').join('; '));
    expect(report.allMatch, isTrue);
    expect(report.score, 100);
  });

  test('a wrong patta number is reported as a mismatch, not a match', () {
    final pattas = matchingPattas();
    pattas[0] = acres('9999', '230', '3', '0.4448');
    final report = compareCertificate(sampleCertificate(), pattas, now: today);
    expect(report.allMatch, isFalse);
    expect(report.rows.firstWhere((r) => r.label == 'Patta Numbers').verdict, Verdict.mismatch);
  });

  test('extent is compared with a 2% tolerance, not exactly', () {
    final pattas = matchingPattas();
    pattas[2] = acres('3497', '233', '', '0.7950'); // +0.5%
    final within = compareCertificate(sampleCertificate(), pattas, now: today);
    expect(within.rows.firstWhere((r) => r.label == 'Land Extent (Total)').verdict, Verdict.match);

    pattas[2] = acres('3497', '233', '', '0.9500'); // +10%
    final outside = compareCertificate(sampleCertificate(), pattas, now: today);
    expect(outside.rows.firstWhere((r) => r.label == 'Land Extent (Total)').verdict, Verdict.mismatch);
  });

  test('certificates expire 10 months after issue', () {
    expect(certificateCurrent('10-08-2026', now: DateTime(2026, 9, 12)), isTrue);
    expect(certificateCurrent('10-08-2026', now: DateTime(2027, 6, 10)), isTrue);
    expect(certificateCurrent('10-08-2026', now: DateTime(2027, 6, 11)), isFalse);
    expect(certificateCurrent('', now: today), isFalse);
    expect(certificateCurrent('2026-08-10', now: DateTime(2026, 9, 12)), isTrue);
  });

  test('names ignore honorifics, initials and word order', () {
    expect(namesMatch('Thiru Ayyakutty', 'Ayyakutty'), isTrue);
    expect(namesMatch('Ramesh Kumar', 'Kumar Ramesh'), isTrue);
    expect(namesMatch('S. Arumugam', 'Arumugam'), isTrue);
    expect(namesMatch('Ramesh Kumar', 'Meena Selvi'), isFalse);
    expect(namesMatch('', 'Ramesh'), isFalse);
  });

  test('survey numbers compare as a set, ignoring order and spacing', () {
    expect(splitIds('230/3, 229/1'), splitIds('229/1,230/3'));
    expect(splitIds('230/3').difference(splitIds('230/3, 229/1')), isEmpty);
  });

  test('hectare-are patta extents convert to acres', () {
    // 0 hectare 87 are = 0.87 ha = 2.1498 acres.
    final p = Patta(extent: '0 - 87.00', extentUnit: 'Hectares - Ares');
    expect(p.extentAcres, closeTo(2.1498, 0.001));
    expect(Patta(extent: '2.50', extentUnit: 'Acres').extentAcres, 2.5);
  });

  test('a missing patta record reads as "not on file" rather than a mismatch', () {
    final report = compareCertificate(sampleCertificate(), [Patta(pattaNumber: '2719')], now: today);
    expect(report.rows.firstWhere((r) => r.label == 'District').verdict, Verdict.missing);
  });
}
