import 'package:crappy_turd/theme/palette.dart';
import 'package:flutter/material.dart';

/// Where the privacy policy is hosted -- the same URL the Play Store
/// listing links to.
const String privacyPolicyUrl =
    'https://github.com/cookiesncache/crappy_turd/blob/main/store/privacy-policy.md';

/// The privacy policy shown inside the app (Google Play requires one in-app
/// as well as on the store listing). This is a verbatim copy of
/// `store/privacy-policy.md`, the file [privacyPolicyUrl] serves;
/// `test/privacy_policy_test.dart` fails if the two ever drift apart, so
/// edit the Markdown file and paste it here.
const String privacyPolicyMarkdown = '''
# Crappy Turd Privacy Policy

_Effective November 11, 2026_

Crappy Turd ("the app") is a free game made by cookiesncache, an independent
hobby developer. This policy explains what happens to your information when
you play it.

## Information we collect

None. The app does not collect, store on any server, share or sell any
personal information or usage data.

- The app does not use the internet. It has no network access on Android.
- There are no ads, analytics, crash reporting or third-party tracking tools.
- There are no accounts, logins or in-app purchases.
- The app does not request access to your contacts, location, camera,
  microphone, photos or any other personal data.

## Information stored on your device

The app saves your best score on your device, so it's still there next
time you play. This information never leaves
your device. Uninstalling the app or clearing its data deletes it.

## Children

The app does not collect personal information from anyone, including
children under 13.

## Changes to this policy

If this policy changes, the updated version will be posted at this same
address with a new effective date.

## Contact

Questions about this policy: cookiesncache@gmail.com
''';

/// Opens the privacy policy in a scrollable dialog over the game.
Future<void> showPrivacyPolicy(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const PrivacyPolicyDialog(),
  );
}

/// A dialog rendering [privacyPolicyMarkdown], followed by the hosted
/// [privacyPolicyUrl] as selectable text.
class PrivacyPolicyDialog extends StatelessWidget {
  /// Creates the dialog.
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.panelBackground,
      title: const Text(
        'Privacy Policy',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Palette.turdDark,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._renderMarkdown(privacyPolicyMarkdown),
            const SizedBox(height: 12),
            const SelectableText(
              'Also online at: $privacyPolicyUrl',
              style: TextStyle(fontSize: 12, color: Palette.turdMid),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(color: Palette.turdDark),
          ),
        ),
      ],
    );
  }
}

/// Renders the small subset of Markdown the policy uses: the `#` title
/// (skipped, since the dialog has its own), `##` headings, an `_italic_`
/// line, `- ` bullets (with indented continuation lines), and plain
/// paragraphs. Blocks are separated by blank lines.
List<Widget> _renderMarkdown(String markdown) {
  const body = TextStyle(fontSize: 14, height: 1.35, color: Palette.turdDark);
  final widgets = <Widget>[];
  final blocks = markdown
      .replaceAll('\r\n', '\n')
      .trim()
      .split(RegExp(r'\n\s*\n'));

  for (final block in blocks) {
    final lines = block.split('\n');
    final first = lines.first;
    if (first.startsWith('# ')) {
      continue;
    }
    if (widgets.isNotEmpty) {
      widgets.add(const SizedBox(height: 10));
    }
    if (first.startsWith('## ')) {
      widgets.add(
        Text(
          first.substring(3),
          style: body.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      );
    } else if (first.startsWith('- ')) {
      final items = <String>[];
      for (final line in lines) {
        if (line.startsWith('- ')) {
          items.add(line.substring(2));
        } else {
          items[items.length - 1] = '${items.last} ${line.trim()}';
        }
      }
      for (final item in items) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: body),
                Expanded(child: Text(item, style: body)),
              ],
            ),
          ),
        );
      }
    } else {
      final text = lines.map((line) => line.trim()).join(' ');
      final italic =
          text.length > 1 && text.startsWith('_') && text.endsWith('_');
      widgets.add(
        Text(
          italic ? text.substring(1, text.length - 1) : text,
          style: italic ? body.copyWith(fontStyle: FontStyle.italic) : body,
        ),
      );
    }
  }
  return widgets;
}
