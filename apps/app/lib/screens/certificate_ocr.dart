import 'package:flutter/material.dart';

import '../match.dart';
import '../models.dart';
import '../ocr.dart';
import '../picker.dart';
import '../store.dart';
import '../ui.dart';
import 'patta_ocr.dart';

/// The core flow: read a Small/Marginal Farmer Certificate and check it against
/// the Patta records already on file for this farmer.
class CertificateOcrPage extends StatefulWidget {
  const CertificateOcrPage({super.key, required this.farmer});
  final Farmer farmer;

  @override
  State<CertificateOcrPage> createState() => _CertificateOcrPageState();
}

class _CertificateOcrPageState extends State<CertificateOcrPage> {
  PickedDoc? _doc;
  Certificate? _cert;
  MatchReport? _report;
  bool _busy = false;

  Farmer get farmer => widget.farmer;

  int get _step => _report != null ? 3 : (_cert != null ? 2 : (_doc != null ? 1 : 0));

  Future<void> _pick() async {
    final doc = await pickDocument(context);
    if (doc == null) return;
    setState(() {
      _doc = doc;
      _cert = null;
      _report = null;
      _busy = true;
    });
    final cert = await readCertificate(doc.bytes, doc.mime);
    if (!mounted) return;
    cert.imagePath = doc.path;
    setState(() {
      _cert = cert;
      _busy = false;
    });
  }

  void _compare() {
    if (_cert == null) return;
    if (farmer.pattas.isEmpty) {
      toast(context, 'Add at least one Patta record for this farmer first.', color: danger);
      return;
    }
    setState(() => _report = compareCertificate(_cert!, farmer.pattas));
  }

  Future<void> _addPatta() async {
    final patta = await Navigator.of(context).push<Patta>(
      MaterialPageRoute(builder: (_) => PattaOcrPage(farmerName: farmer.name)),
    );
    if (patta == null || !mounted) return;
    store.attachPatta(farmer, patta);
    setState(() => _report = null);
    toast(context, 'Patta ${patta.pattaNumber} added to ${farmer.name}.');
  }

  void _save() {
    store.attachCertificate(farmer, _cert!);
    Navigator.pop(context, true);
    toast(context, 'Verification saved for ${farmer.name}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer Certificate OCR')),
      body: PageScroll(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Extract the certificate details and verify them against ${farmer.name}\'s patta records.',
              style: const TextStyle(color: muted, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          StepBar(labels: const ['Upload', 'Extract', 'Compare', 'Result'], current: _step),
          const SizedBox(height: 18),
          SoftPanel(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const Icon(Icons.badge_outlined, color: accent),
                const SizedBox(width: 10),
                const Expanded(child: Text('Farmer certificate', style: TextStyle(fontWeight: FontWeight.w800, color: ink))),
                if (_doc != null)
                  TextButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.edit_outlined, size: 17, color: blue),
                    label: const Text('Change', style: TextStyle(color: blue, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
              ]),
              const SizedBox(height: 12),
              if (_doc == null)
                SoftTap(
                  onTap: _pick,
                  padding: const EdgeInsets.symmetric(vertical: 34),
                  semanticLabel: 'Upload farmer certificate',
                  child: const Column(children: [
                    Icon(Icons.cloud_upload_outlined, color: blue, size: 30),
                    SizedBox(height: 9),
                    Text('Upload the certificate', style: TextStyle(color: blue, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Small / Marginal Farmer Certificate', style: TextStyle(color: muted, fontSize: 11.5)),
                  ]),
                )
              else
                DocPreview(path: _doc!.path, height: 240),
            ]),
          ),
          const SizedBox(height: 16),
          if (_busy)
            SoftPanel(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: accent)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(ocrConfigured ? 'Reading the certificate with $ocrModel...' : 'Loading the bundled sample...',
                      style: const TextStyle(color: muted, fontSize: 12.5)),
                ),
              ]),
            ),
          if (_cert != null) ...[
            CertDetails(cert: _cert!),
            const SizedBox(height: 14),
            LandRows(rows: _cert!.rows),
            const SizedBox(height: 14),
            PattaOnFile(farmer: farmer, onAdd: _addPatta),
            const SizedBox(height: 16),
            if (_report == null)
              PrimaryButton(label: 'Compare with patta records', icon: Icons.compare_arrows_rounded, onPressed: _compare),
            if (_report != null) ...[
              ReportPanel(report: _report!),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: GhostButton(label: 'Re-compare', icon: Icons.refresh_rounded, onPressed: _compare)),
                const SizedBox(width: 12),
                Expanded(child: PrimaryButton(label: 'Save result', icon: Icons.check_rounded, onPressed: _save)),
              ]),
            ],
          ],
        ]),
      ),
    );
  }
}

class CertDetails extends StatelessWidget {
  const CertDetails({super.key, required this.cert});
  final Certificate cert;

  @override
  Widget build(BuildContext context) {
    final current = certificateCurrent(cert.certDate);
    return SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(cert.mocked ? Icons.science_outlined : Icons.auto_awesome_rounded, color: cert.mocked ? warn : accent, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(cert.mocked ? 'Sample certificate loaded' : 'OCR extracted details',
                style: TextStyle(fontWeight: FontWeight.w800, color: cert.mocked ? warn : ink, fontSize: 14)),
          ),
        ]),
        if (cert.mocked && lastOcrError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text('Live OCR unavailable: $lastOcrError', style: const TextStyle(color: muted, fontSize: 11.5)),
          ),
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 6),
        FieldRow(label: 'Certificate No.', value: cert.certNo, icon: Icons.numbers_rounded),
        FieldRow(
          label: 'Certificate Date',
          value: cert.certDate,
          icon: Icons.event_outlined,
          trailing: StatusChip(
            label: current ? 'Within 10 months' : 'Expired',
            color: current ? accent : danger,
            icon: current ? Icons.check_rounded : Icons.close_rounded,
          ),
        ),
        FieldRow(label: 'Farmer Name', value: cert.farmerName, icon: Icons.person_outline_rounded),
        FieldRow(label: "Father's Name", value: cert.fatherName, icon: Icons.people_outline_rounded),
        FieldRow(label: 'Address', value: cert.address, icon: Icons.home_outlined),
        FieldRow(label: 'District', value: cert.district, icon: Icons.location_on_outlined),
        FieldRow(label: 'Taluk', value: cert.taluk, icon: Icons.account_balance_outlined),
        FieldRow(label: 'Village', value: cert.village, icon: Icons.holiday_village_outlined),
        FieldRow(label: 'Total Land Extent', value: '${cert.totalExtentAcres.toStringAsFixed(4)} Acres', icon: Icons.straighten_rounded),
      ]),
    );
  }
}

class LandRows extends StatelessWidget {
  const LandRows({super.key, required this.rows});
  final List<LandRow> rows;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Land details from certificate (${rows.length} records)',
            style: const TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 14)),
        const SizedBox(height: 12),
        // Tables are the one thing allowed to scroll sideways on a phone.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 48,
            columnSpacing: 22,
            headingTextStyle: const TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
            dataTextStyle: const TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 12.5),
            columns: const [
              DataColumn(label: Text('Village')),
              DataColumn(label: Text('Patta No')),
              DataColumn(label: Text('Survey No')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Extent (Acres)')),
            ],
            rows: [
              for (final r in rows)
                DataRow(cells: [
                  DataCell(Text(r.village)),
                  DataCell(Text(r.pattaNo)),
                  DataCell(Text(r.surveyNo)),
                  DataCell(Text(r.landType)),
                  DataCell(Text(r.extentAcres.toStringAsFixed(4))),
                ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class PattaOnFile extends StatelessWidget {
  const PattaOnFile({super.key, required this.farmer, required this.onAdd});
  final Farmer farmer;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(child: Text('Patta records on file', style: TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 14))),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18, color: blue),
            label: const Text('Add patta', style: TextStyle(color: blue, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ]),
        if (farmer.pattas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('No patta on file yet. Add one to run the comparison.', style: TextStyle(color: muted, fontSize: 12.5)),
          )
        else
          for (final p in farmer.pattas)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SoftWell(
                padding: const EdgeInsets.all(13),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Patta ${p.pattaNumber}', style: const TextStyle(fontWeight: FontWeight.w700, color: ink, fontSize: 13)),
                      const SizedBox(height: 3),
                      Text('Survey ${p.surveyNumber}${p.subDivision.isEmpty ? '' : '/${p.subDivision}'} · ${p.village}',
                          style: const TextStyle(color: muted, fontSize: 11.5)),
                    ]),
                  ),
                  Text('${p.extentAcres.toStringAsFixed(4)} ac', style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
      ]),
    );
  }
}

class ReportPanel extends StatelessWidget {
  const ReportPanel({super.key, required this.report});
  final MatchReport report;

  @override
  Widget build(BuildContext context) {
    final ok = report.allMatch;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SoftPanel(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Expanded(child: Text('Compare with existing patta details', style: TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 14))),
            Text('${report.score}%', style: TextStyle(color: ok ? accent : warn, fontWeight: FontWeight.w900, fontSize: 18)),
          ]),
          const SizedBox(height: 12),
          for (final row in report.rows) ComparisonRow(row: row),
        ]),
      ),
      const SizedBox(height: 14),
      SoftPanel(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(ok ? Icons.verified_rounded : Icons.report_problem_outlined, color: ok ? accent : warn, size: 26),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ok ? 'All details matched' : '${report.mismatched} field(s) need review',
                  style: TextStyle(fontWeight: FontWeight.w800, color: ok ? accent : warn, fontSize: 15)),
              const SizedBox(height: 4),
              Text(
                ok
                    ? 'The certificate is valid and matches the patta records on file.'
                    : 'Check the highlighted rows against the original documents before approving.',
                style: const TextStyle(color: muted, fontSize: 12, height: 1.4),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

class ComparisonRow extends StatelessWidget {
  const ComparisonRow({super.key, required this.row});
  final MatchRow row;

  static const _meta = {
    Verdict.match: (accent, Icons.check_circle_rounded, 'Match'),
    Verdict.mismatch: (danger, Icons.cancel_rounded, 'Mismatch'),
    Verdict.missing: (warn, Icons.help_outline_rounded, 'Not on file'),
  };

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _meta[row.verdict]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftWell(
        padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(row.label, style: const TextStyle(color: muted, fontSize: 11.5, fontWeight: FontWeight.w700))),
            StatusChip(label: label, color: color, icon: icon),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _value('Certificate', row.certificate)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Icon(Icons.sync_alt_rounded, size: 15, color: muted),
            ),
            Expanded(child: _value('Patta', row.patta)),
          ]),
          if (row.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(row.note, style: const TextStyle(color: muted, fontSize: 10.5)),
          ],
        ]),
      ),
    );
  }

  Widget _value(String caption, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(caption, style: const TextStyle(color: muted, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        const SizedBox(height: 2),
        Text(value.isEmpty ? '-' : value, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ]);
}
