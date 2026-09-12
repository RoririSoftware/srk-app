import 'models.dart';

/// Compares a Small/Marginal Farmer Certificate against the Patta records already
/// on file for that farmer. This is the core of the product, so it is pure,
/// dependency-free and covered by `test/match_test.dart`.

const _honorifics = ['thiru', 'thirumathi', 'tmt', 'selvi', 'mr', 'mrs', 'ms', 'shri', 'sri', 'திரு', 'திருமதி', 'செல்வி'];

/// Lowercase, strip honorifics, punctuation and repeated whitespace.
String normalise(String raw) {
  var s = raw.toLowerCase().trim();
  s = s.replaceAll(RegExp(r'[.,/\\\-_()]+'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  for (final h in _honorifics) {
    if (s.startsWith('$h ')) s = s.substring(h.length + 1).trim();
  }
  return s;
}

/// Names are compared on their word set so "Ramesh Kumar" == "Kumar Ramesh"
/// and "Ayyakutty S" == "S Ayyakutty". Initials (single letters) are ignored.
bool namesMatch(String a, String b) {
  Set<String> parts(String s) => normalise(s).split(' ').where((w) => w.length > 1).toSet();
  final x = parts(a), y = parts(b);
  if (x.isEmpty || y.isEmpty) return false;
  return x.difference(y).isEmpty || y.difference(x).isEmpty;
}

/// "230/3, 229/1" and "229/1 230/3" are the same set of survey numbers.
Set<String> splitIds(String raw) =>
    raw.split(RegExp(r'[,;&]|\s+and\s+')).map(normalise).map((s) => s.replaceAll(' ', '')).where((s) => s.isNotEmpty).toSet();

/// Certificates are accepted for 10 months from their issue date (TN rule of
/// thumb used by the field team). Parses "10-08-2026" / "2026-08-10".
bool certificateCurrent(String certDate, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final issued = parseDate(certDate);
  if (issued == null) return false;
  final expiry = DateTime(issued.year, issued.month + 10, issued.day);
  return !today.isAfter(expiry) && !today.isBefore(issued);
}

DateTime? parseDate(String raw) {
  final m = RegExp(r'(\d{1,4})[-/.](\d{1,2})[-/.](\d{1,4})').firstMatch(raw.trim());
  if (m == null) return null;
  final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!), c = int.parse(m.group(3)!);
  // Four-digit component tells us which end the year is on.
  if (a > 31) return DateTime(a, b, c);
  if (c > 31) return DateTime(c, b, a);
  return DateTime(2000 + c, b, a);
}

bool _closeEnough(double a, double b) => (a - b).abs() <= 0.01 + a.abs() * 0.02;

String _acres(double v) => '${v.toStringAsFixed(4)} Acres';

MatchReport compareCertificate(Certificate cert, List<Patta> pattas, {DateTime? now}) {
  final rows = <MatchRow>[];

  void text(String label, String c, String p, {bool Function(String, String)? eq}) {
    final compare = eq ?? (x, y) => normalise(x) == normalise(y) && normalise(x).isNotEmpty;
    if (c.trim().isEmpty && p.trim().isEmpty) return;
    if (p.trim().isEmpty) {
      rows.add(MatchRow(label, c, '-', Verdict.missing, 'Not on the patta record'));
      return;
    }
    rows.add(MatchRow(label, c, p, compare(c, p) ? Verdict.match : Verdict.mismatch));
  }

  final pattaOwner = pattas.map((p) => p.ownerName).firstWhere((n) => n.trim().isNotEmpty, orElse: () => '');
  text('Farmer Name', cert.farmerName, pattaOwner, eq: namesMatch);

  String firstOf(String Function(Patta) pick) => pattas.map(pick).firstWhere((v) => v.trim().isNotEmpty, orElse: () => '');
  text('District', cert.district, firstOf((p) => p.district));
  text('Taluk', cert.taluk, firstOf((p) => p.taluk));
  text('Village', cert.village, firstOf((p) => p.village));

  final certPattas = cert.rows.map((r) => r.pattaNo).where((v) => v.trim().isNotEmpty).toSet();
  final filePattas = pattas.map((p) => p.pattaNumber).where((v) => v.trim().isNotEmpty).toSet();
  if (certPattas.isNotEmpty || filePattas.isNotEmpty) {
    rows.add(MatchRow(
      'Patta Numbers',
      certPattas.join(', '),
      filePattas.isEmpty ? '-' : filePattas.join(', '),
      filePattas.isEmpty
          ? Verdict.missing
          : (splitIds(certPattas.join(',')).difference(splitIds(filePattas.join(','))).isEmpty ? Verdict.match : Verdict.mismatch),
    ));
  }

  final certSurveys = cert.rows.map((r) => r.surveyNo).where((v) => v.trim().isNotEmpty).toSet();
  final fileSurveys = pattas
      .map((p) => [p.surveyNumber, p.subDivision].where((v) => v.trim().isNotEmpty).join('/'))
      .where((v) => v.trim().isNotEmpty)
      .toSet();
  if (certSurveys.isNotEmpty || fileSurveys.isNotEmpty) {
    rows.add(MatchRow(
      'Survey Numbers',
      certSurveys.join(', '),
      fileSurveys.isEmpty ? '-' : fileSurveys.join(', '),
      fileSurveys.isEmpty
          ? Verdict.missing
          : (splitIds(certSurveys.join(',')).difference(splitIds(fileSurveys.join(','))).isEmpty ? Verdict.match : Verdict.mismatch),
    ));
  }

  final certExtent = cert.totalExtentAcres > 0
      ? cert.totalExtentAcres
      : cert.rows.fold<double>(0, (sum, r) => sum + r.extentAcres);
  final pattaExtent = pattas.fold<double>(0, (sum, p) => sum + p.extentAcres);
  if (certExtent > 0 || pattaExtent > 0) {
    rows.add(MatchRow(
      'Land Extent (Total)',
      _acres(certExtent),
      pattaExtent == 0 ? '-' : _acres(pattaExtent),
      pattaExtent == 0 ? Verdict.missing : (_closeEnough(certExtent, pattaExtent) ? Verdict.match : Verdict.mismatch),
      pattaExtent == 0 ? '' : 'Tolerance 2%',
    ));
  }

  final current = certificateCurrent(cert.certDate, now: now);
  rows.add(MatchRow(
    'Certificate Date',
    cert.certDate.isEmpty ? '-' : cert.certDate,
    '-',
    current ? Verdict.match : Verdict.mismatch,
    current ? 'Valid, within 10 months' : 'Expired or unreadable date',
  ));

  return MatchReport(rows);
}
