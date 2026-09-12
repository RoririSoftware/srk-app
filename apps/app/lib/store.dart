import 'package:flutter/foundation.dart';

import 'match.dart';
import 'models.dart';
import 'sample_data.dart';

/// In-memory demo store. One global instance, no persistence - restarting the
/// app resets to the seeded records. Replace the bodies with API calls later.
class AppStore extends ChangeNotifier {
  AppStore() {
    // One farmer starts already verified so the dashboard is not empty on
    // first launch and the demo has a matched record to show.
    attachCertificate(farmers.first, sampleCertificate());
  }

  final List<Farmer> farmers = seedFarmers();
  String staffName = 'Ajay Kumar';
  String staffRole = 'Field Staff';
  String branch = 'Tirunelveli Branch';

  int get verifiedCount => farmers.where((f) => f.verified == true).length;
  int get pendingDocs => farmers.where((f) => f.certificate == null).length;
  int get mismatchCount => farmers.where((f) => f.verified == false).length;
  int get convertedCount => farmers.where((f) => f.stage.index >= LeadStage.delivered.index).length;

  String nextLeadId() {
    final now = DateTime.now();
    final seq = (farmers.length + 1).toString().padLeft(3, '0');
    return 'L-${now.year}-${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$seq';
  }

  Farmer add(Map<String, String> fields) {
    final farmer = Farmer(id: nextLeadId(), fields: fields);
    farmers.insert(0, farmer);
    notifyListeners();
    return farmer;
  }

  Farmer? byId(String id) => farmers.where((f) => f.id == id).firstOrNull;

  void attachPatta(Farmer farmer, Patta patta) {
    farmer.pattas.add(patta);
    if (farmer.stage.index < LeadStage.documents.index) farmer.stage = LeadStage.documents;
    _rescore(farmer);
    notifyListeners();
  }

  void attachCertificate(Farmer farmer, Certificate cert) {
    farmer.certificate = cert;
    _rescore(farmer);
    notifyListeners();
  }

  void _rescore(Farmer farmer) {
    final cert = farmer.certificate;
    if (cert == null) return;
    farmer.report = compareCertificate(cert, farmer.pattas);
    if (farmer.report!.allMatch && farmer.stage.index < LeadStage.verified.index) {
      farmer.stage = LeadStage.verified;
    }
  }

  void advance(Farmer farmer, LeadStage stage) {
    farmer.stage = stage;
    notifyListeners();
  }
}

final store = AppStore();
