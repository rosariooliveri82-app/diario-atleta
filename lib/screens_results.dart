import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'stats.dart';
import 'store.dart';
import 'widgets.dart';


class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String? filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gare')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final a = store.athlete;
          if (a == null) {
            snack(context, 'Crea prima il profilo atleta');
            return;
          }
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ResultForm(athleteId: a.id, specialty: filter)));
        },
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final a = store.athlete;
          if (a == null) {
            return const EmptyState(Icons.emoji_events_outlined,
                'Crea il profilo dalla scheda "Profilo" per registrare i risultati.');
          }
          final mine = store.results.where((r) => r.athleteId == a.id).toList();
          final names = mine.map((r) => r.specialty).toSet().toList()..sort();
          if (filter != null && !names.contains(filter)) filter = null;
          final shown = (filter == null ? mine : mine.where((r) => r.specialty == filter))
              .toList()
            ..sort((x, y) => y.data.compareTo(x.data));

          return Column(children: [
            if (names.isNotEmpty)
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                          label: const Text('Tutte'),
                          selected: filter == null,
                          onSelected: (_) => setState(() => filter = null)),
                    ),
                    for (final n in names)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                            label: Text(n),
                            selected: filter == n,
                            onSelected: (_) => setState(() => filter = n)),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: shown.isEmpty
                  ? const EmptyState(Icons.emoji_events_outlined,
                      'Nessun risultato.\nTocca + per aggiungerne uno.')
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 88),
                      children: [
                        if (filter == null) _RecordsCard(results: mine),
                        if (filter != null) _ChartCard(results: mine.where((r) => r.specialty == filter).toList(), specialty: store.specialtyOf(filter!)),
                        for (final r in shown) _resultTile(context, r, mine),
                      ],
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _resultTile(BuildContext context, Result r, List<Result> mine) {
    final s = store.specialtyOf(r.specialty);
    final same = mine.where((x) => x.specialty == r.specialty).toList();
    final best = same.map((x) => x.value).reduce((p, c) => better(c, p, s) ? c : p);
    final thisYear = DateTime.now().year;
    final yearVals = same.where((x) => x.data.year == thisYear).map((x) => x.value);
    final bestYear =
        yearVals.isEmpty ? null : yearVals.reduce((p, c) => better(c, p, s) ? c : p);
    final isPb = r.value == best;
    final isSb = !isPb && r.data.year == thisYear && bestYear != null && r.value == bestYear;
    return ListTile(
      leading: Icon(isPb ? Icons.military_tech : Icons.emoji_events_outlined,
          color: isPb ? Colors.amber : null),
      title: Text('${fmtPerf(r.value, s.kind)}  ·  ${r.specialty}'),
      subtitle: Text([
        fmtDate(r.data),
        if (r.luogo.isNotEmpty) r.luogo,
        if (r.vento.isNotEmpty) 'vento ${r.vento}',
      ].join(' · ')),
      trailing: isPb
          ? const Chip(label: Text('PB'))
          : (isSb ? const Chip(label: Text('SB')) : null),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ResultForm(athleteId: r.athleteId, result: r))),
    );
  }
}

class _RecordsCard extends StatelessWidget {
  final List<Result> results;
  const _RecordsCard({required this.results});
  @override
  Widget build(BuildContext context) {
    final recs = computeRecords(results);
    if (recs.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.military_tech, color: Colors.amber),
        title: const Text('Record personali (PB) e stagionali (SB)'),
        children: [
          for (final r in recs)
            ListTile(
              dense: true,
              title: Text(r.spec.name),
              subtitle: Text(
                  'PB ${fmtPerf(r.pb.value, r.spec.kind)} · ${fmtDate(r.pb.data)}'
                  '${r.sb == null ? '' : '\nSB ${fmtPerf(r.sb!.value, r.spec.kind)} · ${fmtDate(r.sb!.data)}'}'),
              isThreeLine: r.sb != null,
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<Result> results;
  final Specialty specialty;
  const _ChartCard({required this.results, required this.specialty});

  @override
  Widget build(BuildContext context) {
    final sorted = [...results]..sort((a, b) => a.data.compareTo(b.data));
    if (sorted.length < 2) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Servono almeno 2 risultati per mostrare il grafico.'),
      );
    }
    final spots = [
      for (var i = 0; i < sorted.length; i++) FlSpot(i.toDouble(), sorted[i].value)
    ];
    final values = sorted.map((r) => r.value);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final best = specialty.lowerIsBetter ? minV : maxV;
    final pad = (maxV - minV) == 0 ? 1.0 : (maxV - minV) * 0.15;
    final color = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(children: [
          Text('Andamento ${specialty.name} · PB ${fmtPerf(best, specialty.kind)}',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(LineChartData(
              minY: minV - pad,
              maxY: maxV + pad,
              minX: 0,
              maxX: (sorted.length - 1).toDouble(),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(y: best, color: Colors.amber, strokeWidth: 1, dashArray: [6, 4]),
              ]),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (v, meta) {
                      if (v == meta.min || v == meta.max) return const SizedBox();
                      return Text(
                          specialty.kind == Kind.time
                              ? fmtTime(v)
                              : v.toStringAsFixed(specialty.kind == Kind.points ? 0 : 2),
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: sorted.length > 6 ? (sorted.length / 5).ceilToDouble() : 1,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (v != i.toDouble() || i < 0 || i >= sorted.length) {
                        return const SizedBox();
                      }
                      final d = sorted[i].data;
                      return Text('${two(d.day)}/${two(d.month)}',
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touched) => [
                    for (final t in touched)
                      LineTooltipItem(
                          '${fmtPerf(t.y, specialty.kind)}\n${fmtDate(sorted[t.x.toInt()].data)}',
                          const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            )),
          ),
          if (specialty.lowerIsBetter)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Nei tempi, più in basso = migliore',
                  style: TextStyle(fontSize: 11)),
            ),
        ]),
      ),
    );
  }
}

class ResultForm extends StatefulWidget {
  final String athleteId;
  final Result? result;
  final String? specialty;
  const ResultForm({super.key, required this.athleteId, this.result, this.specialty});
  @override
  State<ResultForm> createState() => _ResultFormState();
}

class _ResultFormState extends State<ResultForm> {
  final _key = GlobalKey<FormState>();
  late String specialty;
  late DateTime data;
  late final TextEditingController value, luogo, vento, note;

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    specialty = r?.specialty ?? widget.specialty ?? store.specialties.first.name;
    data = r?.data ?? DateTime.now();
    final s = store.specialtyOf(specialty);
    value = TextEditingController(text: r == null ? '' : fmtPerf(r.value, s.kind).replaceAll(RegExp(r'[^0-9:.]'), ''));
    luogo = TextEditingController(text: r?.luogo);
    vento = TextEditingController(text: r?.vento);
    note = TextEditingController(text: r?.note);
  }

  Future<void> _newSpecialty() async {
    final name = await askText(context, 'Nuova specialità', hint: 'es. 4x100, Lancio del peso 4 kg');
    if (name == null || name.isEmpty || !mounted) return;
    final kind = await showDialog<Kind>(
      context: context,
      builder: (c) => SimpleDialog(title: const Text('Tipo di misura'), children: [
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c, Kind.time), child: const Text('Tempo (più basso = meglio)')),
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c, Kind.dist), child: const Text('Misura in metri (più alto = meglio)')),
        SimpleDialogOption(
            onPressed: () => Navigator.pop(c, Kind.points), child: const Text('Punti (più alto = meglio)')),
      ]),
    );
    if (kind == null) return;
    await store.addSpecialty(Specialty(name, kind));
    setState(() => specialty = name);
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final s = store.specialtyOf(specialty);
    await store.upsertResult(Result(
      id: widget.result?.id ?? newId(),
      athleteId: widget.athleteId,
      data: data,
      specialty: specialty,
      value: parsePerf(value.text, s.kind)!,
      luogo: luogo.text.trim(),
      vento: vento.text.trim(),
      note: note.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = store.specialtyOf(specialty);
    final hint = switch (s.kind) {
      Kind.time => 'es. 11.45  /  2:05.30  /  1:02:10',
      Kind.dist => 'es. 5.82 (metri)',
      Kind.points => 'es. 3250',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.result == null ? 'Nuovo risultato' : 'Modifica risultato'),
        actions: [
          if (widget.result != null)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await confirm(context, 'Eliminare questo risultato?')) {
                    await store.deleteResult(widget.result!.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                }),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Form(
        key: _key,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: specialty,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Specialità', border: OutlineInputBorder()),
                items: [
                  for (final sp in store.specialties)
                    DropdownMenuItem(value: sp.name, child: Text(sp.name)),
                ],
                onChanged: (v) => setState(() => specialty = v!),
              ),
            ),
            IconButton(onPressed: _newSpecialty, icon: const Icon(Icons.add_circle_outline)),
          ]),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(4)),
            title: const Text('Data'),
            subtitle: Text(fmtDate(data)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await pickDate(context, data);
              if (d != null) setState(() => data = d);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: 'Prestazione', hintText: hint, border: const OutlineInputBorder()),
            validator: (v) => parsePerf(v ?? '', s.kind) == null ? 'Valore non valido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: luogo,
            decoration: const InputDecoration(
                labelText: 'Manifestazione / luogo', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: vento,
            decoration: const InputDecoration(
                labelText: 'Vento (m/s)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
          ),
        ]),
      ),
    );
  }
}
