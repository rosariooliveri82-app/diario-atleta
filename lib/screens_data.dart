import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'files.dart';
import 'store.dart';
import 'widgets.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  Future<void> _export(BuildContext context) async {
    try {
      await saveOrShare(store.exportZipBytes(), store.backupName(), 'zip');
      await store.markBackup();
    } catch (e) {
      if (context.mounted) snack(context, 'Errore export: $e');
    }
  }

  Future<void> _import(BuildContext context) async {
    final r = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['zip'], withData: true);
    final bytes = r?.files.single.bytes;
    if (bytes == null || !context.mounted) return;
    final mode = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(title: const Text('Come importare?'), children: [
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'merge'),
            child: const Text('Unisci ai dati esistenti')),
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'replace'),
            child: const Text('Sostituisci tutto (cancella i dati attuali)')),
        SimpleDialogOption(onPressed: () => Navigator.pop(c), child: const Text('Annulla')),
      ]),
    );
    if (mode == null) return;
    try {
      await store.importZipBytes(bytes, replace: mode == 'replace');
      if (context.mounted) snack(context, 'Importazione completata');
    } catch (e) {
      if (context.mounted) snack(context, 'Errore import: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dati e backup')),
      body: ListView(children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
              'I dati restano solo su questo dispositivo. Per passarli a un altro telefono '
              '(o per fare un backup) esporta il file .zip, inviatelo e importalo dall\'altra parte. '
              'Il backup comprende tutto: foto delle tessere, benessere e, se presente, il ciclo. '
              'Conservalo con cura.'),
        ),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('Esporta backup'),
          onTap: () => _export(context),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Importa backup'),
          onTap: () => _import(context),
        ),
      ]),
    );
  }
}
