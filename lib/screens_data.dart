import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'store.dart';
import 'widgets.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  Future<void> _export(BuildContext context) async {
    try {
      final f = await store.exportZip();
      await Share.shareXFiles([XFile(f.path)],
          subject: 'Backup Diario Atletica',
          text: 'Backup Diario Atletica. Apri l\'app sul nuovo telefono > Dati > Importa.');
    } catch (e) {
      if (context.mounted) snack(context, 'Errore export: $e');
    }
  }

  Future<void> _import(BuildContext context) async {
    final r = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    final path = r?.files.single.path;
    if (path == null || !context.mounted) return;
    final mode = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(title: const Text('Come importare?'), children: [
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'merge'),
            child: const Text('Unisci ai dati esistenti')),
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'replace'),
            child: const Text('Sostituisci tutto (cancella i dati attuali)')),
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c), child: const Text('Annulla')),
      ]),
    );
    if (mode == null) return;
    try {
      await store.importZip(path, replace: mode == 'replace');
      if (context.mounted) snack(context, 'Importazione completata');
    } catch (e) {
      if (context.mounted) snack(context, 'Errore import: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dati e info')),
      body: ListView(children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
              'I dati sono salvati solo su questo telefono. Per passarli a un altro telefono, '
              'esporta il backup (.zip, con anche le foto delle tessere), invialo e importalo dall\'altro.'),
        ),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('Esporta backup'),
          subtitle: const Text('Condividi via WhatsApp, email, Drive, AirDrop…'),
          onTap: () => _export(context),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Importa backup'),
          onTap: () => _import(context),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Diario Atletica'),
          subtitle: Text(appCredits),
        ),
      ]),
    );
  }
}
