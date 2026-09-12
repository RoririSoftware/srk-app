import 'package:flutter/material.dart';

import '../ocr.dart';
import '../store.dart';
import '../ui.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final _key = TextEditingController(text: runtimeKey);
  bool _hide = true;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageHeading(eyebrow: 'ACCOUNT', title: 'Profile', subtitle: 'Staff details and OCR configuration.'),
        const SizedBox(height: 20),
        SoftPanel(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: canvas, shape: BoxShape.circle, boxShadow: raised(4)),
              child: const Icon(Icons.person_rounded, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(store.staffName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 3),
                Text('${store.staffRole} · ${store.branch}', style: const TextStyle(color: muted, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SoftPanel(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Expanded(child: Text('Document OCR', style: TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 15))),
              StatusChip(
                label: ocrConfigured ? 'Live' : 'Sample mode',
                color: ocrConfigured ? accent : warn,
                icon: ocrConfigured ? Icons.bolt_rounded : Icons.science_outlined,
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              ocrConfigured
                  ? 'Documents are read by Gemini ($ocrModel). Values still need a human check before saving.'
                  : 'No key set, so uploads fall back to the bundled sample documents. Paste a Gemini API key to run live extraction.',
              style: const TextStyle(color: muted, fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 16),
            SoftFieldWell(
              child: SoftField(
                controller: _key,
                label: 'Gemini API key',
                icon: Icons.key_outlined,
                obscureText: _hide,
                suffix: IconButton(
                  tooltip: _hide ? 'Show key' : 'Hide key',
                  onPressed: () => setState(() => _hide = !_hide),
                  icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: muted, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Save key for this session',
              icon: Icons.save_outlined,
              onPressed: () {
                setState(() => runtimeKey = _key.text.trim());
                toast(context, runtimeKey.isEmpty ? 'Key cleared - sample mode.' : 'Live OCR enabled.');
              },
            ),
            const SizedBox(height: 10),
            const Text('The key is held in memory only and is cleared when the app closes. For a shared build, pass it at build time with --dart-define=GEMINI_API_KEY=...',
                style: TextStyle(color: muted, fontSize: 11, height: 1.45)),
            if (lastOcrError.isNotEmpty) ...[
              const SizedBox(height: 12),
              SoftWell(
                padding: const EdgeInsets.all(13),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: danger, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Last OCR error: $lastOcrError', style: const TextStyle(color: muted, fontSize: 11.5))),
                ]),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        GhostButton(
          label: 'Sign out',
          icon: Icons.logout_rounded,
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}
