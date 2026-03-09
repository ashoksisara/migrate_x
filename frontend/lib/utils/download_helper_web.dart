import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Triggers a file download in the browser.
void triggerZipDownload(List<int> bytes, String filename) {
  final blob = web.Blob(
    <JSUint8Array>[Uint8List.fromList(bytes).toJS].toJS,
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
