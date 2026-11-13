import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/project_store.dart';
import '../../ui/kit.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.screen, required this.store});
  final String screen;
  final ProjectStore store;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final form = GlobalKey<FormState>();
  late bool signup = widget.screen == 'Sign Up';
  bool obscure = true;
  String query = '', plan = 'Monthly';
  void go(String s) => openScreen(context, s, widget.store);
  void back() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      openScreen(context, 'Projects', widget.store, replace: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.screen.startsWith('Sign ')) return _auth();
    if (widget.screen == 'Subscription') return _subscription();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            PageHeader(widget.screen, onBack: back),
            Expanded(
              child: widget.screen == 'Settings'
                  ? _settings()
                  : widget.screen == 'Language'
                  ? _languages()
                  : _privacy(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _auth() => Scaffold(
    resizeToAvoidBottomInset: true,
    body: LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                SizedBox(
                  height: box.maxHeight * .445,
                  width: double.infinity,
                  child: art('auth-hero'),
                ),
                Expanded(
                  child: Container(
                    transform: Matrix4.translationValues(0, -16, 0),
                    decoration: const BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _authTab('Sign In', false),
                            const SizedBox(width: 24),
                            _authTab('Sign Up', true),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: form,
                          child: Column(
                            children: [
                              if (signup) ...[
                                _field('Name'),
                                const SizedBox(height: 20),
                              ],
                              _field(
                                'Email',
                                filled: widget.screen == 'Sign In Filled'
                                    ? 'nicephore@photo.com'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _field(
                                'Password',
                                filled: widget.screen == 'Sign In Filled'
                                    ? 'mage1234'
                                    : null,
                                password: true,
                              ),
                            ],
                          ),
                        ),
                        if (!signup)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _notice(
                                'Password recovery',
                                'This local demo has no account server. You can continue with any valid email and a password of 6 or more characters.',
                              ),
                              child: const Text(
                                'Forgot Password',
                                style: TextStyle(fontSize: 11, color: pink),
                              ),
                            ),
                          ),
                        const Spacer(),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            for (final label in ['Apple', 'Google']) ...[
                              IconButton.filledTonal(
                                tooltip: 'Continue with $label',
                                onPressed: () => _notice(
                                  'Continue with $label',
                                  'Social sign-in requires a configured account provider. Use the email form for the local demo.',
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: panel,
                                  minimumSize: const Size(50, 50),
                                ),
                                icon: label == 'Apple'
                                    ? const Icon(
                                        Icons.apple,
                                        color: muted,
                                        size: 30,
                                      )
                                    : const Text(
                                        'G',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: muted,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            const Spacer(),
                            PrimaryButton(
                              'Next',
                              icon: Icons.chevron_right,
                              onPressed: () {
                                if (form.currentState!.validate()) {
                                  openScreen(
                                    context,
                                    'Discover',
                                    widget.store,
                                    replace: true,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _authTab(String label, bool value) => InkWell(
    onTap: () => setState(() => signup = value),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: signup == value ? 30 : 19,
            fontWeight: signup == value ? FontWeight.w700 : FontWeight.w400,
            color: signup == value ? Colors.white : muted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 4,
          width: 27,
          color: signup == value ? pink : Colors.transparent,
        ),
      ],
    ),
  );
  Widget _field(String label, {String? filled, bool password = false}) =>
      TextFormField(
        initialValue: filled,
        obscureText: password && obscure,
        keyboardType: label == 'Email'
            ? TextInputType.emailAddress
            : TextInputType.text,
        textInputAction: password ? TextInputAction.done : TextInputAction.next,
        style: const TextStyle(fontSize: 15),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Enter your ${label.toLowerCase()}';
          }
          if (label == 'Email' &&
              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
            return 'Enter a valid email';
          }
          if (password && value.length < 6) return 'Use at least 6 characters';
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: muted, fontSize: 15),
          filled: true,
          fillColor: panel,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: password
              ? IconButton(
                  tooltip: obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: muted,
                    size: 21,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );
  Widget _settings() => ListView(
    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
    children: [
      InkWell(
        onTap: () => go('Subscription'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 216,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    art('premium'),
                    const Positioned(
                      left: 16,
                      bottom: 20,
                      child: Text(
                        'mage premium',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: panel,
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Get the premium feature and get\nthe unlimited access to the app.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: muted,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: muted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 36),
      for (final s in [
        'Language',
        'Restore Purchases',
        'Privacy Policy',
        'Rate Us on App Store',
      ])
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xff232426))),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(s, style: const TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right, size: 18, color: muted),
            onTap: () => ['Language', 'Privacy Policy'].contains(s)
                ? go(s)
                : _notice(
                    s,
                    s == 'Restore Purchases'
                        ? 'There are no purchases associated with this local demo.'
                        : 'Store listing is not configured for this demo.',
                  ),
          ),
        ),
    ],
  );
  Widget _languages() {
    const languages = [
      'English',
      'Spanish',
      'Chinese',
      'Japanese',
      'French',
      'German',
      'Russian',
      'Portugues',
      'Italian',
      'Korean',
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        SearchBox(hint: 'Search', onChanged: (v) => setState(() => query = v)),
        const SizedBox(height: 24),
        for (final l in languages.where(
          (l) => l.toLowerCase().contains(query.toLowerCase()),
        ))
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xff202123))),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(l, style: const TextStyle(fontSize: 15)),
              trailing: widget.store.language == l
                  ? const Icon(Icons.check_box_rounded, color: pink, size: 22)
                  : null,
              onTap: () async {
                await widget.store.setLanguage(l);
                if (mounted) {
                  setState(() {});
                  tell(
                    context,
                    'Preference saved: $l. Design preview uses English.',
                  );
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _privacy() => ListView(
    padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
    children: const [
      Text(
        'Your photos, your space',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      SizedBox(height: 20),
      Text(
        'Mage stores your projects on this device. Imported photos and edits are processed locally. No photos are uploaded by this demo.\n\n'
        'Photo access\nYou choose individual images through the system photo picker. Imported images are stored with local drafts so that saved projects can be reopened.\n\n'
        'Saved projects\nDrafts include canvas settings, text, shapes and image locations. Deleting a draft removes it from the project list. Exported PNG files remain in your device’s Pictures/Mage folder.\n\n'
        'Accounts and subscriptions\nSign-in and premium screens demonstrate the reference design. This build does not create accounts, collect payments or connect to a subscription service.\n\n'
        'Your choices\nYou can edit or delete local projects at any time. Removing the app clears its private draft data. Back up exported images separately.\n\n'
        'This is a development preview. Review a production privacy policy before publishing.',
        style: TextStyle(color: Color(0xffa2a2a8), height: 1.55, fontSize: 14),
      ),
    ],
  );
  Widget _subscription() => Scaffold(
    body: Column(
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * .5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              art('premium'),
              Positioned(
                top: 32,
                left: 16,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: back,
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
              ),
              const Positioned(
                left: 32,
                right: 32,
                bottom: 34,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'mage premium',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Get the premium feature and get the unlimited access to the app.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        for (final p in ['Monthly', 'Yearly'])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: InkWell(
              onTap: () => setState(() => plan = p),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: plan == p ? pink.withValues(alpha: .06) : panel,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: plan == p ? pink : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      plan == p
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: plan == p ? pink : muted,
                      size: 21,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            p == 'Monthly'
                                ? 'Pay monthly, cancel any time'
                                : 'Pay for a full year',
                            style: TextStyle(
                              fontSize: 9,
                              color: plan == p ? pink : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      p == 'Monthly' ? r'$ 19.99' : r'$ 129.99',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      p == 'Monthly' ? ' /m' : ' /y',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const Spacer(),
        PrimaryButton(
          'Subscribe Now',
          onPressed: () => _notice(
            'Premium preview',
            '$plan plan selected. Purchases are not enabled in this local build. No payment will be taken.',
          ),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );
  void _notice(String title, String text) => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
