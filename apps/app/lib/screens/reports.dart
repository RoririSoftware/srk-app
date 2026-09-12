import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../ui.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final total = store.farmers.length;
    double share(int n) => total == 0 ? 0 : n / total;

    final byStage = <LeadStage, int>{
      for (final s in LeadStage.values) s: store.farmers.where((f) => f.stage == s).length,
    };
    final byVillage = <String, int>{};
    for (final f in store.farmers) {
      final v = f.village.isEmpty ? 'Unknown' : f.village;
      byVillage[v] = (byVillage[v] ?? 0) + 1;
    }
    final villages = byVillage.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalAcres = store.farmers.fold<double>(0, (s, f) => s + f.pattas.fold<double>(0, (a, p) => a + p.extentAcres));

    return PageScroll(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageHeading(
          eyebrow: 'WORKSPACE REPORTS',
          title: 'Reports',
          subtitle: 'Verification and lead progress across the branch.',
        ),
        const SizedBox(height: 20),
        SoftPanel(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Verification health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 18),
            _Bar(label: 'Certificate matched', value: share(store.verifiedCount), count: store.verifiedCount, color: accent),
            _Bar(label: 'Needs review', value: share(store.mismatchCount), count: store.mismatchCount, color: warn),
            _Bar(label: 'Awaiting certificate', value: share(store.pendingDocs), count: store.pendingDocs, color: blue),
          ]),
        ),
        const SizedBox(height: 16),
        SoftPanel(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Leads by stage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 14),
            for (final entry in byStage.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(child: Text(stageLabels[entry.key]!, style: const TextStyle(color: muted, fontSize: 12.5))),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: canvas, shape: BoxShape.circle, boxShadow: entry.value == 0 ? pressed(2) : raised(3)),
                    child: Text('${entry.value}',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: entry.value == 0 ? muted : ink)),
                  ),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) => Flex(
            direction: box.maxWidth < 560 ? Axis.vertical : Axis.horizontal,
            children: [
              Expanded(
                flex: box.maxWidth < 560 ? 0 : 1,
                child: _Stat(label: 'Land under record', value: '${totalAcres.toStringAsFixed(2)} acres', icon: Icons.landscape_outlined, color: accent),
              ),
              const SizedBox(width: 14, height: 14),
              Expanded(
                flex: box.maxWidth < 560 ? 0 : 1,
                child: _Stat(
                  label: 'Patta documents scanned',
                  value: '${store.farmers.fold<int>(0, (s, f) => s + f.pattas.length)}',
                  icon: Icons.document_scanner_outlined,
                  color: blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftPanel(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Farmers by village', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 14),
            for (final v in villages) _Bar(label: v.key, value: share(v.value), count: v.value, color: blue),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.count, required this.color});
  final String label;
  final double value;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 13))),
            // Count is spelled out, so the bar is never the only signal.
            Text('$count · ${(value * 100).round()}%', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: value, minHeight: 9, backgroundColor: const Color(0xFFD5DDE6), color: color),
          ),
        ]),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SoftPanel(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: muted, fontSize: 11.5)),
            ]),
          ),
        ]),
      );
}
