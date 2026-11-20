import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens_data.dart';
import 'store.dart';
import 'web_helpers_stub.dart' if (dart.library.js_interop) 'web_helpers_web.dart';

/// Avvisi per non perdere i dati: installazione su iOS e backup periodico.
class SafetyBanner extends StatelessWidget {
  const SafetyBanner({super.key});

  Widget _card(BuildContext context, IconData icon, String text, {VoidCallback? action, String? label}) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(text, style: TextStyle(color: cs.onErrorContainer)),
              if (action != null)
                TextButton(onPressed: action, child: Text(label ?? 'OK')),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (store.athlete == null) return const SizedBox.shrink();
    final items = <Widget>[];

    if (kIsWeb && isIOSBrowser() && !isStandalone()) {
      items.add(_card(
        context,
        Icons.add_to_home_screen,
        'Stai usando Safari: i dati possono essere cancellati dopo alcuni giorni senza uso. '
        'Tocca Condividi e poi "Aggiungi a Home", poi apri l\'app dall\'icona.',
      ));
    }

    final lb = store.lastBackup;
    final days = lb == null ? null : DateTime.now().difference(lb).inDays;
    if (lb == null || days! >= 14) {
      items.add(_card(
        context,
        Icons.backup_outlined,
        lb == null
            ? 'Non hai ancora fatto un backup. Esporta il file e tienilo al sicuro (Drive, email, iCloud).'
            : 'Ultimo backup $days giorni fa. Fanne uno nuovo.',
        action: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const DataScreen())),
        label: 'Fai il backup ora',
      ));
    }
    return Column(children: items);
  }
}
