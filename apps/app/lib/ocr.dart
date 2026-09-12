import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'sample_data.dart';

/// Document OCR via Gemini. On-device ML Kit cannot read Tamil script, which is
/// most of what a Patta or a TN farmer certificate contains, so extraction runs
/// against the Gemini vision API. With no key configured - or on any network or
/// parse failure - we fall back to the bundled sample so a client demo never
/// dies in front of the customer. Fallback results carry `mocked: true` and the
/// UI says so plainly.

/// Bake a key into the APK with:
///   flutter build apk --dart-define=GEMINI_API_KEY=...
const _buildKey = String.fromEnvironment('GEMINI_API_KEY');
const _model = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');

/// Runtime override entered on the Profile screen. Session-only, not persisted.
String runtimeKey = '';

String get geminiKey => runtimeKey.trim().isNotEmpty ? runtimeKey.trim() : _buildKey;
bool get ocrConfigured => geminiKey.isNotEmpty;
String get ocrModel => _model;

/// Last failure reason, surfaced in the UI so a silent fallback is never a mystery.
String lastOcrError = '';

Future<Map<String, dynamic>?> _extract(Uint8List bytes, String mime, String prompt, Map<String, dynamic> schema) async {
  if (!ocrConfigured) {
    lastOcrError = 'No Gemini API key configured';
    return null;
  }
  try {
    final res = await http
        .post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent'),
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': geminiKey},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'inlineData': {'mimeType': mime, 'data': base64Encode(bytes)}
                  },
                  {'text': prompt},
                ]
              }
            ],
            'generationConfig': {'responseMimeType': 'application/json', 'responseSchema': schema, 'temperature': 0},
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      lastOcrError = 'Gemini returned ${res.statusCode}';
      return null;
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (text == null) {
      lastOcrError = 'Gemini returned no content';
      return null;
    }
    lastOcrError = '';
    return jsonDecode(text) as Map<String, dynamic>;
  } catch (e) {
    lastOcrError = '$e';
    return null;
  }
}

const _str = {'type': 'STRING'};

const _pattaSchema = {
  'type': 'OBJECT',
  'properties': {
    'pattaNumber': _str,
    'surveyNumber': _str,
    'subDivision': _str,
    'landType': _str,
    'extent': _str,
    'extentUnit': _str,
    'waterRate': _str,
    'district': _str,
    'taluk': _str,
    'village': _str,
    'ownerName': _str,
    'remarks': _str,
  },
  'required': ['pattaNumber', 'surveyNumber', 'district', 'taluk', 'village'],
};

const _pattaPrompt = '''
This is a Tamil Nadu Patta / Chitta land record (mostly Tamil script).
Read it and return the fields exactly as printed - keep Tamil text in Tamil, do not translate or transliterate.
- pattaNumber: the number after "பட்டா எண்"
- surveyNumber: "புல எண்" (field number), subDivision: "உட்பிரிவு"
- landType: "புன்செய்" (dry) or "நன்செய்" (wet), whichever column carries the extent
- extent: the "பரப்பு" value as printed, e.g. "0 - 87.00"
- extentUnit: "Hectares - Ares" unless the document states acres
- waterRate: the "நீர்வை" value, ownerName: "உரிமையாளர்கள் பெயர்"
- district: "மாவட்டம்", taluk: "வட்டம்", village: "வருவாய் கிராமம்"
- remarks: "குறிப்புரைகள்", or "-" if blank
Use an empty string for anything you cannot read. Never invent a value.''';

const _certSchema = {
  'type': 'OBJECT',
  'properties': {
    'certNo': _str,
    'certDate': _str,
    'farmerName': _str,
    'fatherName': _str,
    'address': _str,
    'district': _str,
    'taluk': _str,
    'village': _str,
    'totalExtentAcres': {'type': 'NUMBER'},
    'rows': {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'district': _str,
          'taluk': _str,
          'village': _str,
          'pattaNo': _str,
          'surveyNo': _str,
          'landType': _str,
          'extentAcres': {'type': 'NUMBER'},
        },
        'required': ['pattaNo', 'surveyNo', 'extentAcres'],
      },
    },
  },
  'required': ['certNo', 'certDate', 'farmerName', 'rows'],
};

const _certPrompt = '''
This is a Tamil Nadu Small / Marginal Farmer Certificate (சிறு / குறு விவசாயி சான்றிதழ்).
Extract:
- certNo (e.g. TN-920260804671) and certDate in DD-MM-YYYY as printed
- farmerName and fatherName in English if the English line is present, otherwise as printed
- address, district, taluk, village
- rows: one entry per line of the land table (S.No / District / Taluk / Village / Patta No / Survey No / Classification / Extent in acres)
- totalExtentAcres: the sum of every row's extent
Keep patta and survey numbers exactly as printed, including slashes. Use an empty string or 0 for anything unreadable. Never invent a value.''';

/// Returns the extracted Patta. [Patta.mocked] is true when the sample was used.
Future<Patta> readPatta(Uint8List bytes, String mime) async {
  final json = await _extract(bytes, mime, _pattaPrompt, _pattaSchema);
  if (json == null) return samplePatta();
  return Patta.fromJson(json);
}

/// Returns the extracted certificate. [Certificate.mocked] flags sample data.
Future<Certificate> readCertificate(Uint8List bytes, String mime) async {
  final json = await _extract(bytes, mime, _certPrompt, _certSchema);
  if (json == null) return sampleCertificate();
  return Certificate.fromJson(json);
}
