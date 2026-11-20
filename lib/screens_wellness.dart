import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'models_extra.dart';
import 'stats.dart';
import 'store.dart';
import 'widgets.dart';

// ======================= Benessere (peso, sonno, infortuni)

class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benessere')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const WellnessForm())),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final list = [...store.wellness]..sort((a, b) => b.data.compareTo(a.data));
          if (list.isEmpty) {
            return const EmptyState(Icons.monitor_heart_outlined,
                'Registra peso, ore di sonno, dolori e infortuni.\nTocca + per iniziare.');
          }
          final pesi = list.where((w) => w.peso != null).toList().reversed.toList();
          return ListView(padding: const EdgeInsets.only(bottom: 88), children: [
            if (pesi.length >= 2) _WeightChart(entries: pesi),
            for (final w in list)
              ListTile(
                leading: Icon(w.infortunio.isNotEmpty ? Icons.healing : Icons.monitor_heart_outlined,
                    color: w.infortunio.isNotEmpty ? Colors.red : null),
                title: Text(fmtDate(w.data)),
                subtitle: Text([
                  if (w.peso != null) 'Peso ${w.peso!.toStringAsFixed(1)} kg',
                  if (w.sonno != null) 'Sonno ${w.sonno!.toStringAsFixed(1)} h',
                  if (w.dolore > 0) 'Dolore ${w.dolore}/10',
                  if (w.infortunio.isNotEmpty) 'Infortunio: ${w.infortunio}',
                  if (w.note.isNotEmpty) w.note,
                ].join(' · ')),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => WellnessForm(entry: w))),
              ),
          ]);
        },
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<Wellness> entries;
  const _WeightChart({required this.entries});
  @override
  Widget build(BuildContext context) {
    final vals = entries.map((e) => e.peso!).toList();
    final minV = vals.reduce((a, b) => a < b ? a : b);
    final maxV = vals.reduce((a, b) => a > b ? a : b);
    final pad = (maxV - minV) == 0 ? 1.0 : (maxV - minV) * 0.2;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(children: [
          Text('Andamento peso (kg)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              minY: minV - pad,
              maxY: maxV + pad,
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, m) => (v == m.min || v == m.max)
                        ? const SizedBox()
                        : Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: entries.length > 6 ? (entries.length / 5).ceilToDouble() : 1,
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (v != i.toDouble() || i < 0 || i >= entries.length) {
                        return const SizedBox();
                      }
                      final d = entries[i].data;
                      return Text('${two(d.day)}/${two(d.month)}',
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [for (var i = 0; i < entries.length; i++) FlSpot(i.toDouble(), entries[i].peso!)],
                  color: Theme.of(context).colorScheme.secondary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            )),
          ),
        ]),
      ),
    );
  }
}

class WellnessForm extends StatefulWidget {
  final Wellness? entry;
  const WellnessForm({super.key, this.entry});
  @override
  State<WellnessForm> createState() => _WellnessFormState();
}

class _WellnessFormState extends State<WellnessForm> {
  late DateTime data;
  late int dolore;
  late final TextEditingController peso, sonno, infortunio, note;

  @override
  void initState() {
    super.initState();
    final w = widget.entry;
    data = w?.data ?? DateTime.now();
    dolore = w?.dolore ?? 0;
    peso = TextEditingController(text: w?.peso?.toString() ?? '');
    sonno = TextEditingController(text: w?.sonno?.toString() ?? '');
    infortunio = TextEditingController(text: w?.infortunio);
    note = TextEditingController(text: w?.note);
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    await store.put(
        store.wellness,
        Wellness(
          id: widget.entry?.id ?? newId(),
          data: data,
          peso: _num(peso),
          sonno: _num(sonno),
          dolore: dolore,
          infortunio: infortunio.text.trim(),
          note: note.text.trim(),
        ),
        (x) => x.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Nuova registrazione' : 'Modifica registrazione'),
        actions: [
          if (widget.entry != null)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await confirm(context, 'Eliminare questa registrazione?')) {
                    await store.remove(store.wellness, widget.entry!.id, (x) => x.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                }),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(
          shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4)),
          title: const Text('Data'),
          subtitle: Text(fmtDate(data)),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await pickDate(context, data, first: DateTime(2020));
            if (d != null) setState(() => data = d);
          },
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: peso,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: sonno,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Sonno (ore)', border: OutlineInputBorder()),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Text('Dolore / fastidio: $dolore / 10'),
        Slider(
            value: dolore.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$dolore',
            onChanged: (v) => setState(() => dolore = v.round())),
        TextField(
          controller: infortunio,
          decoration: const InputDecoration(
              labelText: 'Infortunio / zona dolorante (facoltativo)',
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
        ),
      ]),
    );
  }
}

// ======================= Ciclo mestruale (solo profili femminili)

class CycleScreen extends StatelessWidget {
  const CycleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final a = store.athlete;
        if (a == null || a.sesso != 'F') {
          return Scaffold(
              appBar: AppBar(title: const Text('Ciclo mestruale')),
              body: const EmptyState(Icons.info_outline,
                  'Disponibile solo per i profili femminili.'));
        }
        final info = computeCycle(a, store.cycles);
        final entries = [...store.cycles]..sort((x, y) => y.start.compareTo(x.start));
        return Scaffold(
          appBar: AppBar(title: const Text('Ciclo mestruale')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CycleForm())),
            icon: const Icon(Icons.add),
            label: const Text('Inizio ciclo'),
          ),
          body: ListView(padding: const EdgeInsets.only(bottom: 88), children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: info.lastStart == null
                    ? const Text(
                        'Segna la data di inizio dell\'ultimo ciclo (tasto in basso) per vedere stime e previsioni.')
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Giorno ${info.day} del ciclo',
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text('Fase stimata: ${info.phase}',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                            'Prossimo ciclo previsto: ${fmtDate(info.nextStart!)} (${whenLabel(daysFrom(info.nextStart!))})'),
                        Text('Ovulazione stimata: ${fmtDate(info.ovulation!)}'),
                        Text('Durata media ciclo: ${info.cycleLen} giorni'),
                        if (info.late) ...[
                          const SizedBox(height: 8),
                          const Text(
                              'Sono passati più giorni della media: aggiorna la data di inizio. '
                              'Se i ritardi si ripetono, parlane con il medico dello sport.',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ]),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                  'Stime indicative basate sulle date inserite: non sono un metodo contraccettivo '
                  'né una diagnosi. Per irregolarità, dolore forte o assenza di ciclo rivolgiti al medico.',
                  style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 8),
            for (final e in entries)
              ListTile(
                leading: const Icon(Icons.water_drop_outlined),
                title: Text('Inizio ${fmtDate(e.start)}'),
                subtitle: Text([
                  '${e.giorni} giorni',
                  if (e.note.isNotEmpty) e.note,
                ].join(' · ')),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => CycleForm(entry: e))),
              ),
          ]),
        );
      },
    );
  }
}

class CycleForm extends StatefulWidget {
  final CycleEntry? entry;
  const CycleForm({super.key, this.entry});
  @override
  State<CycleForm> createState() => _CycleFormState();
}

class _CycleFormState extends State<CycleForm> {
  late DateTime start;
  late final TextEditingController giorni, note;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    start = e?.start ?? DateTime.now();
    giorni = TextEditingController(text: '${e?.giorni ?? store.athlete?.durataMestruo ?? 5}');
    note = TextEditingController(text: e?.note);
  }

  Future<void> _save() async {
    await store.put(
        store.cycles,
        CycleEntry(
          id: widget.entry?.id ?? newId(),
          start: start,
          giorni: (int.tryParse(giorni.text) ?? 5).clamp(1, 12).toInt(),
          note: note.text.trim(),
        ),
        (x) => x.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Inizio ciclo' : 'Modifica ciclo'),
        actions: [
          if (widget.entry != null)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await confirm(context, 'Eliminare questa registrazione?')) {
                    await store.remove(store.cycles, widget.entry!.id, (x) => x.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                }),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(
          shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4)),
          title: const Text('Primo giorno del ciclo'),
          subtitle: Text(fmtDate(start)),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await pickDate(context, start,
                first: DateTime(2020), last: DateTime.now());
            if (d != null) setState(() => start = d);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: giorni,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Giorni di mestruazione', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Note (sintomi, energia, dolore…)', border: OutlineInputBorder()),
        ),
      ]),
    );
  }
}
