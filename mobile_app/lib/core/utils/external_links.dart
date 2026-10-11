import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the platform browser / external app.
///
/// Malformed URLs and launch failures are swallowed so that legal or
/// informational links can never break the calling flow.
Future<void> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Best effort only.
  }
}
