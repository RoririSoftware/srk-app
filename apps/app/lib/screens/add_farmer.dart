import 'package:flutter/material.dart';

import '../lead_form.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';
import 'farmer_detail.dart';
import 'patta_ocr.dart';

/// Documents-first lead wizard. Step 0 is the Patta OCR hand-off, which
/// pre-fills the land step; the remaining steps come from [leadSteps].
class AddFarmerPage extends StatefulWidget {
  const AddFarmerPage({super.key});

  @override
  State<AddFarmerPage> createState() => _AddFarmerPageState();
}

class _AddFarmerPageState extends State<AddFarmerPage> {
  final _values = <String, String>{'state': 'Tamil Nadu', 'landUnit': 'Acres', 'gender': 'Male', 'community': 'General'};
  final _controllers = <String, TextEditingController>{};
  final _pattas = <Patta>[];
  int _index = 0;
  String? _error;

  /// Step 0 is documents; steps 1..n map to leadSteps[step - 1].
  int get _last => leadSteps.length;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String id) =>
      _controllers[id] ??= TextEditingController(text: _values[id] ?? '')
        ..addListener(() => _values[id] = _controllers[id]!.text);

  Future<void> _addPatta() async {
    final patta = await Navigator.of(context).push<Patta>(MaterialPageRoute(builder: (_) => const PattaOcrPage()));
    if (patta == null || !mounted) return;
    setState(() {
      _pattas.add(patta);
      // First patta seeds the land step; later ones only add to the record.
      _prefill('district', patta.district);
      _prefill('taluk', patta.taluk);
      _prefill('village', patta.village);
      _prefill('pattaNumber', patta.pattaNumber);
      _prefill('surveyNumbers', [patta.surveyNumber, patta.subDivision].where((v) => v.isNotEmpty).join('/'));
      _prefill('name', patta.ownerName);
      _values['landExtent'] = _pattas.fold<double>(0, (s, p) => s + p.extentAcres).toStringAsFixed(4);
      _values['landUnit'] = 'Acres';
      _controllers['landExtent']?.text = _values['landExtent']!;
    });
    toast(context, 'Patta ${patta.pattaNumber} attached. Land details pre-filled.');
  }

  void _prefill(String id, String value) {
    if (value.trim().isEmpty || (_values[id] ?? '').trim().isNotEmpty) return;
    _values[id] = value;
    _controllers[id]?.text = value;
  }

  void _next() {
    if (_index > 0) {
      final missing = leadSteps[_index - 1].fields.where((f) => f.required && (_values[f.id] ?? '').trim().isEmpty).toList();
      if (missing.isNotEmpty) {
        setState(() => _error = 'Fill in ${missing.map((f) => f.label).join(', ')}.');
        return;
      }
    }
    if (_index == _last) {
      _save();
      return;
    }
    setState(() {
      _error = null;
      _index++;
    });
  }

  void _save() {
    final farmer = store.add(Map.of(_values));
    for (final p in _pattas) {
      store.attachPatta(farmer, p);
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => FarmerDetailPage(farmer: farmer)));
    toast(context, '${farmer.name} saved as ${farmer.id}.');
  }

  @override
  Widget build(BuildContext context) {
    final title = _index == 0 ? 'Attachments' : (_index == _last ? 'Review & save' : leadSteps[_index - 1].title);
    return Scaffold(
      appBar: AppBar(title: const Text('New farmer lead')),
      body: PageScroll(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SoftPanel(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Step ${_index + 1} of ${_last + 1}',
                    style: const TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 0.8)),
                const Spacer(),
                Text('${((_index + 1) * 100 / (_last + 1)).round()}%', style: const TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11.5)),
              ]),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_index + 1) / (_last + 1),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFD5DDE6),
                  color: accent,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (_index == 0) _documentsStep(),
          if (_index > 0 && _index <= leadSteps.length) _formStep(leadSteps[_index - 1]),
          if (_index == _last && _last == leadSteps.length) const SizedBox.shrink(),
          if (_index == _last) ...[const SizedBox(height: 16), _reviewStep()],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.error_outline_rounded, color: danger, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(color: danger, fontWeight: FontWeight.w600, fontSize: 12.5))),
            ]),
          ],
          const SizedBox(height: 20),
          Row(children: [
            if (_index > 0) ...[
              Expanded(child: GhostButton(label: 'Back', icon: Icons.arrow_back_rounded, onPressed: () => setState(() => _index--))),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: _index == _last ? 'Save farmer' : 'Next',
                icon: _index == _last ? Icons.check_rounded : Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _documentsStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SoftPanel(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Patta (Chitta)', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 4),
          const Text('Scan the patta first - the land and owner fields fill in automatically.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
          const SizedBox(height: 14),
          for (final p in _pattas)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftWell(
                padding: const EdgeInsets.all(13),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: accent, size: 19),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text('Patta ${p.pattaNumber} · ${p.village}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: ink, fontSize: 13)),
                  ),
                  Text('${p.extentAcres.toStringAsFixed(2)} ac', style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          SoftTap(
            onTap: _addPatta,
            padding: const EdgeInsets.symmetric(vertical: 24),
            semanticLabel: 'Scan patta with OCR',
            child: const Column(children: [
              Icon(Icons.document_scanner_outlined, color: blue, size: 28),
              SizedBox(height: 8),
              Text('Scan patta with OCR', style: TextStyle(color: blue, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      SoftWell(
        padding: const EdgeInsets.all(15),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: blue, size: 19),
          const SizedBox(width: 11),
          const Expanded(
            child: Text('The farmer certificate is uploaded and matched after the lead is saved, from the farmer\'s page.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
          ),
        ]),
      ),
    ]);
  }

  Widget _formStep(StepSpec step) {
    return SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(step.icon, color: accent, size: 19),
          const SizedBox(width: 9),
          Expanded(child: Text(step.subtitle, style: const TextStyle(color: muted, fontSize: 12.5))),
        ]),
        const SizedBox(height: 16),
        for (final f in step.fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: f.options != null
                ? SoftDropdown<String>(
                    label: f.label,
                    value: f.options!.contains(_values[f.id]) ? _values[f.id]! : f.options!.first,
                    items: f.options!,
                    onChanged: (v) => setState(() => _values[f.id] = v ?? ''),
                  )
                : SoftFieldWell(
                    child: SoftField(
                      controller: _controller(f.id),
                      label: f.required ? '${f.label} *' : f.label,
                      icon: f.icon,
                      keyboardType: f.keyboard,
                      maxLines: f.lines,
                    ),
                  ),
          ),
      ]),
    );
  }

  Widget _reviewStep() {
    return SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Review before saving', style: TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 15)),
        const SizedBox(height: 4),
        Text('${_pattas.length} patta record(s) attached.', style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 10),
        const Divider(),
        for (final step in leadSteps) ...[
          const SizedBox(height: 12),
          Text(step.title.toUpperCase(),
              style: const TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 4),
          for (final f in step.fields)
            if ((_values[f.id] ?? '').trim().isNotEmpty) FieldRow(label: f.label, value: _values[f.id]!),
        ],
      ]),
    );
  }
}
