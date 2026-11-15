import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'settings.dart';

const Color _bg = Color(0xFF121212);
const Color _fieldBg = Color(0xFF232129);
const Color _accent = Color(0xFFD0BCFF);
const Color _onAccent = Color(0xFF381E72);
const Color _muted = Color(0xFFCAC4D0);
const Color _text = Color(0xFFE6E1E5);
Color _danger = Color(0xFFF2B8B5);

String _ut(SettingsController sc, String hi, String en) =>
    sc.value.hindi ? hi : en;

final RegExp _usernameShape = RegExp(r'^[a-z0-9_]+(\.[a-z0-9_]+)*$');

/// यूज़रनेम की जाँच। सही हो तो null, वरना संदेश।
String? usernameError(String raw) {
  final v = raw.trim().toLowerCase();
  if (v.length < 3 || v.length > 20) return '3 से 20 अक्षर लिखें';
  if (!_usernameShape.hasMatch(v)) {
    return 'सिर्फ़ a-z, 0-9, _ और डॉट (.) चलेंगे; शुरू या आख़िर में डॉट नहीं';
  }
  return null;
}

class UsernamePage extends StatefulWidget {
  const UsernamePage({
    super.key,
    required this.user,
    required this.onDone,
    required this.settings,
  });

  final User user;
  final VoidCallback onDone;
  final SettingsController settings;

  @override
  State<UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends State<UsernamePage> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = _ctrl.text.trim().toLowerCase();
    final err = usernameError(v);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final db = FirebaseFirestore.instance;
      final ref = db.collection('usernames').doc(v);
      final existing = await ref.get();
      if (!mounted) return;
      if (existing.exists) {
        setState(
          () => _error = _ut(
            widget.settings,
            'यह यूज़रनेम पहले से किसी और का है',
            'This username is already taken',
          ),
        );
        return;
      }
      await ref.set({'uid': widget.user.uid, 'email': widget.user.email});
      await db.collection('users').doc(widget.user.uid).set({
        'username': v,
      }, SetOptions(merge: true));
      if (mounted) widget.onDone();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _ut(
            widget.settings,
            'सेव नहीं हुआ, फिर कोशिश करें',
            'Could not save, try again',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 70,
                  height: 70,
                  cacheWidth: 210,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              _ut(widget.settings, 'यूज़रनेम बनाएँ', 'Create username'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              _ut(
                widget.settings,
                'लॉगिन के लिए एक यूज़रनेम चुनें।',
                'Pick a username for sign-in.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _ctrl,
              enabled: !_busy,
              style: TextStyle(color: _text, fontSize: 15),
              decoration: InputDecoration(
                labelText: _ut(widget.settings, 'यूज़रनेम', 'Username'),
                hintText: 'ashish.home',
                labelStyle: const TextStyle(color: _muted),
                floatingLabelStyle: const TextStyle(color: _accent),
                prefixIcon: const Icon(Icons.alternate_email, color: _muted),
                filled: true,
                fillColor: _fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _accent, width: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• 3 से 20 अक्षर\n• अक्षर (a-z), अंक (0-9), डॉट (.) और _\n• शुरू या आख़िर में डॉट नहीं',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 18),
            if (_error != null) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: _danger, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _onAccent,
                        ),
                      )
                    : Text(
                        _ut(
                          widget.settings,
                          'यूज़रनेम सेव करें',
                          'Save username',
                        ),
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => FirebaseAuth.instance.signOut(),
                child: Text(
                  _ut(widget.settings, 'लॉग आउट', 'Log out'),
                  style: const TextStyle(color: _muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
