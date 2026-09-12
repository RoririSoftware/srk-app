import 'package:flutter/material.dart';

import '../models.dart';
import '../ocr.dart';
import '../picker.dart';
import '../ui.dart';

/// Upload a Patta / Chitta, extract the fields, let the user correct them,
/// then hand the [Patta] back to the caller via [Navigator.pop].
class PattaOcrPage extends StatefulWidget {
  const PattaOcrPage({super.key, this.farmerName});
  final String? farmerName;

  @override
  State<PattaOcrPage> createState() => _PattaOcrPageState();
}

class _PattaOcrPageState extends State<PattaOcrPage> {
  PickedDoc? _doc;
  Patta? _patta;
  bool _busy = false;

  final _c = <String, TextEditingController>{};
  String _landType = 'புன்செய் (Dry)';
  String _extentUnit = 'Hectares - Ares';

  static const _landTypes = ['புன்செய் (Dry)', 'நன்செய் (Wet)', 'மற்றவை (Other)'];
  static const _units = ['Hectares - Ares', 'Acres', 'Cents'];

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _step => _patta != null ? 2 : (_doc != null ? 1 : 0);

  Future<void> _pick() async {
    final doc = await pickDocument(context);
    if (doc == null) return;
    setState(() {
      _doc = doc;
      _patta = null;
      _busy = true;
    });
    final patta = await readPatta(doc.bytes, doc.mime);
    if (!mounted) return;
    patta.imagePath = doc.path;
    _load(patta);
    setState(() {
      _patta = patta;
      _busy = false;
    });
  }

  void _load(Patta p) {
    void set(String key, String value) => (_c[key] ??= TextEditingController()).text = value;
    set('pattaNumber', p.pattaNumber);
    set('surveyNumber', p.surveyNumber);
    set('subDivision', p.subDivision);
    set('extent', p.extent);
    set('waterRate', p.waterRate);
    set('ownerName', p.ownerName);
    set('district', p.district);
    set('taluk', p.taluk);
    set('village', p.village);
    set('remarks', p.remarks);
    _landType = _landTypes.contains(p.landType) ? p.landType : _landTypes.first;
    _extentUnit = _units.contains(p.extentUnit) ? p.extentUnit : _units.first;
  }

  Patta _collect() {
    String v(String k) => _c[k]?.text.trim() ?? '';
    return Patta(
      pattaNumber: v('pattaNumber'),
      surveyNumber: v('surveyNumber'),
      subDivision: v('subDivision'),
      landType: _landType,
      extent: v('extent'),
      extentUnit: _extentUnit,
      waterRate: v('waterRate'),
      ownerName: v('ownerName'),
      district: v('district'),
      taluk: v('taluk'),
      village: v('village'),
      remarks: v('remarks'),
      imagePath: _doc?.path,
      mocked: _patta?.mocked ?? false,
    );
  }

  void _save() {
    final patta = _collect();
    if (patta.pattaNumber.isEmpty) {
      toast(context, 'A patta number is required before saving.', color: danger);
      return;
    }
    Navigator.pop(context, patta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patta OCR'),
        actions: [
          IconButton(
            tooltip: 'How this works',
            onPressed: () => _help(context),
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: PageScroll(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            widget.farmerName == null
                ? 'Upload a Patta document to extract the land details automatically.'
                : 'Patta for ${widget.farmerName}',
            style: const TextStyle(color: muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          StepBar(labels: const ['Upload', 'Extract', 'Verify', 'Save'], current: _step),
          const SizedBox(height: 18),
          SoftPanel(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const Icon(Icons.description_outlined, color: accent),
                const SizedBox(width: 10),
                const Expanded(child: Text('Patta document', style: TextStyle(fontWeight: FontWeight.w800, color: ink))),
                if (_doc != null)
                  TextButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.edit_outlined, size: 17, color: blue),
                    label: const Text('Change photo', style: TextStyle(color: blue, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
              ]),
              const SizedBox(height: 12),
              if (_doc == null)
                SoftTap(
                  onTap: _pick,
                  padding: const EdgeInsets.symmetric(vertical: 34),
                  semanticLabel: 'Upload patta document',
                  child: const Column(children: [
                    Icon(Icons.cloud_upload_outlined, color: blue, size: 30),
                    SizedBox(height: 9),
                    Text('Upload a document', style: TextStyle(color: blue, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('JPG or PNG photo of the full page', style: TextStyle(color: muted, fontSize: 11.5)),
                  ]),
                )
              else
                DocPreview(path: _doc!.path, height: 250),
            ]),
          ),
          const SizedBox(height: 16),
          if (_busy) const _Extracting(),
          if (_patta != null) ...[
            _ResultBanner(mocked: _patta!.mocked),
            const SizedBox(height: 14),
            SoftPanel(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _field('Patta Number', 'pattaNumber', Icons.tag_rounded),
                _pair(_field('Survey Number', 'surveyNumber', Icons.map_outlined), _field('Sub Division', 'subDivision', null)),
                SoftDropdown<String>(
                  label: 'Land Type',
                  value: _landType,
                  items: _landTypes,
                  onChanged: (v) => setState(() => _landType = v ?? _landType),
                ),
                const SizedBox(height: 12),
                _pair(
                  _field('Area (Extent)', 'extent', Icons.crop_square_rounded),
                  SoftDropdown<String>(label: 'Unit', value: _extentUnit, items: _units, onChanged: (v) => setState(() => _extentUnit = v ?? _extentUnit)),
                ),
                _field('Water Rate / Nanjai', 'waterRate', Icons.water_drop_outlined),
                _field('Owner Name', 'ownerName', Icons.person_outline_rounded),
                _field('District', 'district', Icons.location_on_outlined),
                _field('Taluk', 'taluk', Icons.account_balance_outlined),
                _field('Village', 'village', Icons.holiday_village_outlined),
                _field('Remarks', 'remarks', Icons.notes_rounded),
                const SizedBox(height: 4),
                SoftWell(
                  padding: const EdgeInsets.all(13),
                  child: Row(children: [
                    const Icon(Icons.straighten_rounded, size: 17, color: muted),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text('Converted extent: ${_collect().extentAcres.toStringAsFixed(4)} acres',
                          style: const TextStyle(color: muted, fontSize: 12)),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: GhostButton(label: 'Retake', icon: Icons.refresh_rounded, onPressed: _pick)),
              const SizedBox(width: 12),
              Expanded(child: PrimaryButton(label: 'Save patta', icon: Icons.check_rounded, onPressed: _save)),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _pair(Widget a, Widget b) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: LayoutBuilder(
          builder: (context, box) => box.maxWidth < 380
              ? Column(children: [a, b])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: a),
                  const SizedBox(width: 12),
                  Expanded(child: b),
                ]),
        ),
      );

  Widget _field(String label, String key, IconData? icon) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SoftFieldWell(
          child: SoftField(
            controller: _c[key] ??= TextEditingController(),
            label: label,
            icon: icon,
            onChanged: (_) => setState(() {}),
          ),
        ),
      );

  void _help(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: canvas,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('How Patta OCR works', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
          content: Text(
            ocrConfigured
                ? 'The photo is sent to Gemini ($ocrModel), which reads the Tamil fields and returns them as structured data. Always check the values before saving - OCR is a first draft, not the truth.'
                : 'No OCR key is configured in this build, so the bundled sample document is filled in instead. Add a key on the Profile screen to run live extraction.',
            style: const TextStyle(color: muted, height: 1.5, fontSize: 13),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
        ),
      );
}

class _Extracting extends StatelessWidget {
  const _Extracting();

  @override
  Widget build(BuildContext context) => SoftPanel(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: accent)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Reading the document', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 3),
              Text(ocrConfigured ? 'Extracting fields with $ocrModel...' : 'Loading the bundled sample...',
                  style: const TextStyle(color: muted, fontSize: 12)),
            ]),
          ),
        ]),
      );
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.mocked});
  final bool mocked;

  @override
  Widget build(BuildContext context) {
    final color = mocked ? warn : accent;
    return SoftPanel(
      padding: const EdgeInsets.all(15),
      child: Row(children: [
        Icon(mocked ? Icons.science_outlined : Icons.check_circle_rounded, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mocked ? 'Sample data loaded' : 'Details extracted successfully using OCR',
                style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13.5)),
            const SizedBox(height: 3),
            Text(
              mocked
                  ? (lastOcrError.isEmpty ? 'Add an OCR key on Profile for live extraction.' : 'Live OCR unavailable: $lastOcrError')
                  : 'Check every field before saving.',
              style: const TextStyle(color: muted, fontSize: 11.5, height: 1.35),
            ),
          ]),
        ),
      ]),
    );
  }
}
