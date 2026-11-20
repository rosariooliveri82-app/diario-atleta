import 'package:flutter/material.dart';

import 'files.dart';
import 'report.dart';
import 'screens_data.dart';
import 'screens_goals.dart';
import 'screens_wellness.dart';
import 'store.dart';
import 'widgets.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _open(BuildContext context, Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  Future<void> _report(BuildContext context) async {
    if (store.athlete == null) {
      snack(context, 'Crea prima il profilo atleta');
      return;
    }
    var includeWellness = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          title: const Text('Riepilogo PDF'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
                'Profilo, record, ultime gare e allenamenti, obiettivi e carico settimanale. '
                'I dati del ciclo non vengono mai inclusi.'),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: includeWellness,
              onChanged: (v) => setS(() => includeWellness = v ?? false),
              title: const Text('Includi benessere (peso, sonno, infortuni)'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Crea PDF')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final bytes = await buildReport(includeWellness: includeWellness);
      await saveOrShare(bytes, 'riepilogo_atletica_${DateTime.now().year}', 'pdf');
    } catch (e) {
      if (context.mounted) snack(context, 'Errore PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Altro')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return ListView(children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Obiettivi stagionali'),
              subtitle: const Text('Traguardi con barra di avanzamento'),
              onTap: () => _open(context, const GoalsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: const Text('Benessere'),
              subtitle: const Text('Peso, sonno, dolori e infortuni'),
              onTap: () => _open(context, const WellnessScreen()),
            ),
            if (store.athlete?.sesso == 'F')
              ListTile(
                leading: const Icon(Icons.water_drop_outlined),
                title: const Text('Ciclo mestruale'),
                subtitle: const Text('Giorno, fase e previsione'),
                onTap: () => _open(context, const CycleScreen()),
              ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Riepilogo PDF per l\'allenatore'),
              onTap: () => _report(context),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Dati e backup'),
              subtitle: const Text('Esporta / importa per cambiare telefono'),
              onTap: () => _open(context, const DataScreen()),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Diario Atletica'),
              subtitle: Text(appCredits),
            ),
          ]);
        },
      ),
    );
  }
}
