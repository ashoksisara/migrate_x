/// Stub for non-web platforms. Use [download_helper_web.dart] on web.
void triggerZipDownload(List<int> bytes, String filename) {
  throw UnsupportedError(
    'File download is only supported on web. Run with: flutter run -d chrome',
  );
}
