import 'package:flutter/material.dart';

import '../lead_form.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';
import 'certificate_ocr.dart';
import 'patta_ocr.dart';

class FarmerDetailPage extends StatefulWidget {
  const FarmerDetailPage({super.key, required this.farmer});
  final Farmer farmer;

  @override
  State<FarmerDetailPage> createState() => _FarmerDetailPageState();
}

class _FarmerDetailPageState extends State<FarmerDetailPage> {
  Farmer get farmer => widget.farmer;

  Future<void> _addPatta() async {
    final patta = await Navigator.of(context).push<Patta>(
      MaterialPageRoute(builder: (_) => PattaOcrPage(farmerName: farmer.name)),
    );
    if (patta == null || !mounted) return;
    store.attachPatta(farmer, patta);
    setState(() {});
    toast(context, 'Patta ${patta.pattaNumber} added.');
  }

  Future<void> _verify() async {
    await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CertificateOcrPage(farmer: farmer)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final report = farmer.report;
    return Scaffold(
      appBar: AppBar(title: Text(farmer.name)),
      body: PageScroll(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SoftPanel(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: canvas, shape: BoxShape.circle, boxShadow: raised(4)),
                  child: Text(farmer.initial, style: const TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(farmer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
                    const SizedBox(height: 3),
                    Text('${farmer.id} · ${farmer.village}', style: const TextStyle(color: muted, fontSize: 12)),
                  ]),
                ),
                VerificationChip(farmer: farmer),
              ]),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 6),
              FieldRow(label: 'Mobile', value: farmer.mobile, icon: Icons.phone_outlined),
              FieldRow(label: 'District / Taluk', value: [farmer.district, farmer.fields['taluk'] ?? ''].where((v) => v.isNotEmpty).join(' · '), icon: Icons.location_on_outlined),
              FieldRow(label: 'Land extent', value: '${farmer.fields['landExtent'] ?? '-'} ${farmer.fields['landUnit'] ?? ''}', icon: Icons.straighten_rounded),
              FieldRow(label: 'Product', value: farmer.fields['productName'] ?? '', icon: Icons.agriculture_outlined),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: GhostButton(label: 'Add patta', icon: Icons.add_rounded, onPressed: _addPatta)),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: report == null ? 'Verify' : 'Re-verify',
                icon: Icons.verified_outlined,
                onPressed: _verify,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          if (report != null) ...[
            SoftPanel(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Icon(report.allMatch ? Icons.verified_rounded : Icons.report_problem_outlined, color: report.allMatch ? accent : warn),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(report.allMatch ? 'Certificate matched' : '${report.mismatched} field(s) need review',
                        style: TextStyle(fontWeight: FontWeight.w800, color: report.allMatch ? accent : warn)),
                  ),
                  Text('${report.score}%', style: const TextStyle(color: muted, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 6),
                for (final row in report.rows)
                  FieldRow(
                    label: row.label,
                    value: row.certificate,
                    trailing: Icon(
                      switch (row.verdict) {
                        Verdict.match => Icons.check_circle_rounded,
                        Verdict.mismatch => Icons.cancel_rounded,
                        Verdict.missing => Icons.help_outline_rounded,
                      },
                      size: 17,
                      color: switch (row.verdict) { Verdict.match => accent, Verdict.mismatch => danger, Verdict.missing => warn },
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          SoftPanel(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Patta records (${farmer.pattas.length})', style: const TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 14)),
              if (farmer.pattas.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('None on file yet.', style: TextStyle(color: muted, fontSize: 12.5)))
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
                            Text('Survey ${p.surveyNumber}${p.subDivision.isEmpty ? '' : '/${p.subDivision}'} · ${p.landType}',
                                style: const TextStyle(color: muted, fontSize: 11.5)),
                          ]),
                        ),
                        Text('${p.extentAcres.toStringAsFixed(4)} ac',
                            style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
            ]),
          ),
          const SizedBox(height: 16),
          _Timeline(farmer: farmer, onTap: (stage) => setState(() => store.advance(farmer, stage))),
          const SizedBox(height: 16),
          SoftPanel(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Lead details', style: TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 14)),
              for (final step in leadSteps)
                if (step.fields.any((f) => (farmer.fields[f.id] ?? '').trim().isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  Text(step.title.toUpperCase(),
                      style: const TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  for (final f in step.fields)
                    if ((farmer.fields[f.id] ?? '').trim().isNotEmpty) FieldRow(label: f.label, value: farmer.fields[f.id]!),
                ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class VerificationChip extends StatelessWidget {
  const VerificationChip({super.key, required this.farmer});
  final Farmer farmer;

  @override
  Widget build(BuildContext context) => switch (farmer.verified) {
        true => const StatusChip(label: 'Verified', color: accent, icon: Icons.check_rounded),
        false => const StatusChip(label: 'Review', color: warn, icon: Icons.priority_high_rounded),
        _ => const StatusChip(label: 'Pending', color: muted, icon: Icons.schedule_rounded),
      };
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.farmer, required this.onTap});
  final Farmer farmer;
  final ValueChanged<LeadStage> onTap;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Lead status', style: TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Tap a stage to move the lead forward.', style: TextStyle(color: muted, fontSize: 11.5)),
        const SizedBox(height: 14),
        for (final stage in LeadStage.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SoftTap(
              onTap: () => onTap(stage),
              padding: const EdgeInsets.all(12),
              radius: 14,
              child: Row(children: [
                Icon(
                  stage.index <= farmer.stage.index ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: stage.index <= farmer.stage.index ? accent : muted,
                  size: 20,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(stageLabels[stage]!,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: stage.index <= farmer.stage.index ? ink : muted)),
                ),
                if (stage == farmer.stage) const StatusChip(label: 'Current', color: blue),
              ]),
            ),
          ),
      ]),
    );
  }
}
