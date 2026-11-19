import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'store.dart';

Future<DateTime?> pickDate(BuildContext context, DateTime initial,
    {DateTime? first, DateTime? last}) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(1930),
    lastDate: last ?? DateTime.now().add(const Duration(days: 365)),
  );
}

Future<bool> confirm(BuildContext context, String message) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Conferma')),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> askText(BuildContext context, String title, {String hint = ''}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annulla')),
        FilledButton(
            onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: const Text('OK')),
      ],
    ),
  );
}

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState(this.icon, this.text, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ]),
        ),
      );
}

/// Selettore atleta attivo, mostrato in cima alle schermate Gare/Allenamenti.
class AthletePicker extends StatelessWidget {
  const AthletePicker({super.key});
  @override
  Widget build(BuildContext context) {
    if (store.athletes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DropdownButtonFormField<String>(
        value: store.currentAthlete?.id,
        decoration: const InputDecoration(
            labelText: 'Atleta', border: OutlineInputBorder(), isDense: true),
        items: [
          for (final a in store.athletes)
            DropdownMenuItem(value: a.id, child: Text(a.fullName)),
        ],
        onChanged: (v) {
          if (v != null) store.selectAthlete(v);
        },
      ),
    );
  }
}

/// Anteprima / selezione di un'immagine salvata nella cartella dell'app.
class ImageSlot extends StatelessWidget {
  final String label;
  final String? fileName;
  final ValueChanged<String?> onChanged;
  const ImageSlot(
      {super.key, required this.label, required this.fileName, required this.onChanged});

  Future<void> _pick(BuildContext context, ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1800, imageQuality: 85);
    if (x == null) return;
    onChanged(await store.importImage(x));
  }

  @override
  Widget build(BuildContext context) {
    final has = fileName != null && File(store.imagePath(fileName!)).existsSync();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (has)
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ImageViewer(path: store.imagePath(fileName!)))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(store.imagePath(fileName!)),
                    height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          Wrap(spacing: 8, children: [
            TextButton.icon(
                onPressed: () => _pick(context, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galleria')),
            TextButton.icon(
                onPressed: () => _pick(context, ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Foto')),
            if (has)
              TextButton.icon(
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Rimuovi')),
          ]),
        ]),
      ),
    );
  }
}

class ImageViewer extends StatelessWidget {
  final String path;
  const ImageViewer({super.key, required this.path});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(),
        body: Center(child: InteractiveViewer(child: Image.file(File(path)))),
      );
}
