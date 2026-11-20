import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Web: scarica il file. Android: apre il menu di condivisione.
Future<void> saveOrShare(Uint8List bytes, String name, String ext) async {
  if (kIsWeb) {
    await FileSaver.instance.saveFile(
        name: name,
        bytes: bytes,
        ext: ext,
        mimeType: ext == 'pdf' ? MimeType.pdf : MimeType.zip);
  } else {
    final tmp = await getTemporaryDirectory();
    final f = File('${tmp.path}/$name.$ext');
    await f.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(f.path)], subject: name);
  }
}
