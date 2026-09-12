/// Demo data model. Everything is a plain mutable object held in memory -
/// no persistence, no serialisation. Swap [AppStore] for an API client later.
library;

class LandRow {
  LandRow({
    this.district = '',
    this.taluk = '',
    this.village = '',
    this.pattaNo = '',
    this.surveyNo = '',
    this.landType = '',
    this.extentAcres = 0,
  });
  String district, taluk, village, pattaNo, surveyNo, landType;
  double extentAcres;

  factory LandRow.fromJson(Map<String, dynamic> j) => LandRow(
    district: '${j['district'] ?? ''}',
    taluk: '${j['taluk'] ?? ''}',
    village: '${j['village'] ?? ''}',
    pattaNo: '${j['pattaNo'] ?? ''}',
    surveyNo: '${j['surveyNo'] ?? ''}',
    landType: '${j['landType'] ?? ''}',
    extentAcres: double.tryParse('${j['extentAcres'] ?? 0}') ?? 0,
  );
}

class Patta {
  Patta({
    this.pattaNumber = '',
    this.surveyNumber = '',
    this.subDivision = '',
    this.landType = '',
    this.extent = '',
    this.extentUnit = 'Hectares - Ares',
    this.waterRate = '',
    this.district = '',
    this.taluk = '',
    this.village = '',
    this.ownerName = '',
    this.remarks = '',
    this.imagePath,
    this.mocked = false,
  });

  String pattaNumber,
      surveyNumber,
      subDivision,
      landType,
      extent,
      extentUnit,
      waterRate;
  String district, taluk, village, ownerName, remarks;
  String? imagePath;

  /// True when the values came from bundled sample data, not a live OCR call.
  bool mocked;

  /// Acres, derived from [extent]. Patta extents read "0 - 87.00" (hectare - are).
  double get extentAcres {
    final nums = RegExp(r'[\d.]+')
        .allMatches(extent)
        .map((m) => double.tryParse(m.group(0)!) ?? 0)
        .toList();
    if (nums.isEmpty) return 0;
    if (extentUnit.toLowerCase().startsWith('acre')) return nums.first;
    final hectares = nums.length > 1 ? nums[0] + nums[1] / 100 : nums[0];
    return hectares * 2.47105;
  }

  factory Patta.fromJson(Map<String, dynamic> j) => Patta(
    pattaNumber: '${j['pattaNumber'] ?? ''}',
    surveyNumber: '${j['surveyNumber'] ?? ''}',
    subDivision: '${j['subDivision'] ?? ''}',
    landType: '${j['landType'] ?? ''}',
    extent: '${j['extent'] ?? ''}',
    extentUnit: '${j['extentUnit'] ?? 'Hectares - Ares'}',
    waterRate: '${j['waterRate'] ?? ''}',
    district: '${j['district'] ?? ''}',
    taluk: '${j['taluk'] ?? ''}',
    village: '${j['village'] ?? ''}',
    ownerName: '${j['ownerName'] ?? ''}',
    remarks: '${j['remarks'] ?? ''}',
  );
}

class Certificate {
  Certificate({
    this.certNo = '',
    this.certDate = '',
    this.farmerName = '',
    this.fatherName = '',
    this.address = '',
    this.district = '',
    this.taluk = '',
    this.village = '',
    this.totalExtentAcres = 0,
    List<LandRow>? rows,
    this.imagePath,
    this.mocked = false,
  }) : rows = rows ?? [];

  String certNo,
      certDate,
      farmerName,
      fatherName,
      address,
      district,
      taluk,
      village;
  double totalExtentAcres;
  List<LandRow> rows;
  String? imagePath;
  bool mocked;

  factory Certificate.fromJson(Map<String, dynamic> j) => Certificate(
    certNo: '${j['certNo'] ?? ''}',
    certDate: '${j['certDate'] ?? ''}',
    farmerName: '${j['farmerName'] ?? ''}',
    fatherName: '${j['fatherName'] ?? ''}',
    address: '${j['address'] ?? ''}',
    district: '${j['district'] ?? ''}',
    taluk: '${j['taluk'] ?? ''}',
    village: '${j['village'] ?? ''}',
    totalExtentAcres: double.tryParse('${j['totalExtentAcres'] ?? 0}') ?? 0,
    rows: [
      for (final r in (j['rows'] as List? ?? []))
        LandRow.fromJson(Map<String, dynamic>.from(r as Map)),
    ],
  );
}

enum Verdict { match, mismatch, missing }

class MatchRow {
  MatchRow(
    this.label,
    this.certificate,
    this.patta,
    this.verdict, [
    this.note = '',
  ]);
  final String label;
  final String certificate;
  final String patta;
  final Verdict verdict;
  final String note;
}

class MatchReport {
  MatchReport(this.rows);
  final List<MatchRow> rows;

  int get matched => rows.where((r) => r.verdict == Verdict.match).length;
  int get mismatched => rows.where((r) => r.verdict == Verdict.mismatch).length;
  bool get allMatch =>
      mismatched == 0 && rows.any((r) => r.verdict == Verdict.match);
  int get score => rows.isEmpty ? 0 : (matched * 100 / rows.length).round();
}

enum LeadStage { created, documents, verified, confirmed, delivered, closed }

const stageLabels = {
  LeadStage.created: 'Lead created',
  LeadStage.documents: 'Documents uploaded',
  LeadStage.verified: 'Documents verified',
  LeadStage.confirmed: 'Product confirmed',
  LeadStage.delivered: 'Delivery completed',
  LeadStage.closed: 'Closed',
};

class Farmer {
  Farmer({
    required this.id,
    required this.fields,
    List<Patta>? pattas,
    this.certificate,
    this.report,
    this.stage = LeadStage.created,
    DateTime? createdAt,
  }) : pattas = pattas ?? [],
       createdAt = createdAt ?? DateTime.now();

  final String id;

  /// Wizard answers, keyed by the field ids in `lead_form.dart`.
  final Map<String, String> fields;
  final List<Patta> pattas;
  Certificate? certificate;
  MatchReport? report;
  LeadStage stage;
  final DateTime createdAt;

  String get name => fields['name']?.trim().isNotEmpty == true
      ? fields['name']!
      : 'Unnamed farmer';
  String get village => fields['village'] ?? '';
  String get mobile => fields['mobile'] ?? '';
  String get district => fields['district'] ?? '';

  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  /// null until a certificate has been compared.
  bool? get verified => report?.allMatch;
}
