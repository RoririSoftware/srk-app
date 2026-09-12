import 'package:flutter/material.dart';

import '../store.dart';
import '../ui.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _user = TextEditingController(text: 'ajay@skrtrader.in');
  final _password = TextEditingController(text: 'demo123');
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Demo auth: any non-empty pair is accepted.
    if (_user.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter both your staff ID and password.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageScroll(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 12),
              const Center(child: BrandMark(large: true)),
              const SizedBox(height: 26),
              SoftPanel(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Staff sign in', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)),
                  const SizedBox(height: 6),
                  const Text('Field team access for farmer records and document verification.',
                      style: TextStyle(color: muted, height: 1.4, fontSize: 13)),
                  const SizedBox(height: 24),
                  SoftFieldWell(child: SoftField(controller: _user, label: 'Staff ID / Email', icon: Icons.person_outline_rounded)),
                  const SizedBox(height: 14),
                  SoftFieldWell(
                    child: SoftField(
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _hide,
                      suffix: IconButton(
                        tooltip: _hide ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _hide = !_hide),
                        icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: muted, size: 20),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.error_outline_rounded, color: danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: danger, fontWeight: FontWeight.w600, fontSize: 12.5))),
                    ]),
                  ],
                  const SizedBox(height: 22),
                  PrimaryButton(label: 'Sign in', icon: Icons.login_rounded, busy: _busy, onPressed: _signIn),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () => toast(context, 'Ask your branch admin to reset the password.'),
                      child: const Text('Forgot password?', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              SoftWell(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: blue, size: 19),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text('Demo build - any password works. Signed in as ${store.staffName}, ${store.branch}.',
                        style: const TextStyle(color: muted, fontSize: 12, height: 1.4)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
