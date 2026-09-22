import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SponsorBanner extends StatefulWidget {
  const SponsorBanner({super.key, this.launchWebsite, this.compact = false});

  final bool compact;

  static final Uri website = Uri.parse('https://alef-bot.top').replace(
    queryParameters: const {
      'utm_source': 'kol_hashiurim',
      'utm_medium': 'desktop_app',
      'utm_campaign': 'sponsorship',
      'utm_content': 'footer',
    },
  );

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Container(
        width: double.infinity,
        decoration: widget.compact
            ? BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colors.onSurface.withValues(alpha: 0.10),
                  ),
                ),
              )
            : null,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: widget.compact ? 0 : 6,
            ),
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
                        foregroundColor: colors.onSurface,
                        minimumSize: const Size(48, 40),
                        textStyle: TextStyle(
                          fontSize: widget.compact ? 13 : 17,
                          fontWeight: widget.compact
                              ? FontWeight.w500
                              : FontWeight.bold,
                          decoration: widget.compact
                              ? TextDecoration.none
                              : TextDecoration.underline,
                        ),
                      ),
                      child: const Text(
                        'בחסות אלף בוט - תמלול מדויק לתוכן תורני',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      '0774632641',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: colors.onSurface.withValues(
                          alpha: widget.compact ? 0.7 : 1,
                        ),
                        fontSize: widget.compact ? 12 : 17,
                        fontWeight: widget.compact
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (_linkFailed)
                  Text(
                    'לא ניתן לפתוח את אתר אלף בוט',
                    style: TextStyle(color: colors.onSurface),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
