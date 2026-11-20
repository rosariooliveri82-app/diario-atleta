import 'dart:typed_data';

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

/// Anteprima / selezione di un'immagine (salvata in memoria dallo store).
class ImageSlot extends StatelessWidget {
  final String label;
  final String? fileName;
  final ValueChanged<String?>? onChanged;
  const ImageSlot({super.key, required this.label, required this.fileName, this.onChanged});

  Future<void> _pick(ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1400, imageQuality: 80);
    if (x == null) return;
    onChanged?.call(await store.importImage(x));
  }

  void _view(BuildContext context, Uint8List bytes) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ImageViewer(bytes: bytes)));

  @override
  Widget build(BuildContext context) {
    final bytes = store.imageBytes(fileName);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (bytes != null)
            GestureDetector(
              onTap: () => _view(context, bytes),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(bytes,
                    height: 130, width: double.infinity, fit: BoxFit.cover),
              ),
            )
          else
            const Text('Nessuna immagine importata'),
          const SizedBox(height: 4),
          Wrap(spacing: 8, children: [
            if (bytes != null)
              FilledButton.tonalIcon(
                  onPressed: () => _view(context, bytes),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Visualizza')),
            if (onChanged != null) ...[
              TextButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(bytes == null ? 'Importa' : 'Sostituisci')),
              TextButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Foto')),
              if (bytes != null)
                TextButton.icon(
                    onPressed: () => onChanged!(null),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Rimuovi')),
            ],
          ]),
        ]),
      ),
    );
  }
}

class ImageViewer extends StatelessWidget {
  final Uint8List bytes;
  const ImageViewer({super.key, required this.bytes});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(),
        body: Center(child: InteractiveViewer(child: Image.memory(bytes))),
      );
}
