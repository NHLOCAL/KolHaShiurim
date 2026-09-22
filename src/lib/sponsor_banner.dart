import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SponsorBanner extends StatefulWidget {
  const SponsorBanner({super.key, this.launchWebsite});

  static final Uri website = Uri.parse('https://alef-bot.top');

  /// Allows the link outcome to be checked without opening a browser in tests.
  final Future<bool> Function(Uri)? launchWebsite;

  @override
  State<SponsorBanner> createState() => _SponsorBannerState();
}

class _SponsorBannerState extends State<SponsorBanner> {
  bool _linkFailed = false;

  Future<void> _openWebsite() async {
    bool opened = false;
    try {
      opened =
          await (widget.launchWebsite?.call(SponsorBanner.website) ??
              launchUrl(
                SponsorBanner.website,
                mode: LaunchMode.externalApplication,
              ));
    } catch (_) {
      opened = false;
    }
    if (mounted) {
      setState(() => _linkFailed = !opened);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.inverseSurface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 0,
                children: [
                  TextButton(
                    onPressed: _openWebsite,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onInverseSurface,
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    child: const Text('בחסות אלף בוט'),
                  ),
                  Text(
                    '0774632641',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: colors.onInverseSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (_linkFailed)
                Text(
                  'לא ניתן לפתוח את אתר אלף בוט',
                  style: TextStyle(color: colors.onInverseSurface),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
