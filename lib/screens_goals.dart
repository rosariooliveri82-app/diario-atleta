import 'package:flutter/material.dart';

import 'models.dart';
import 'models_extra.dart';
import 'stats.dart';
import 'store.dart';
import 'widgets.dart';

double? goalBest(Goal g) {
  final s = store.specialtyOf(g.specialty);
  final rs = store.results.where((r) => r.specialty == g.specialty).toList();
  if (rs.isEmpty) return null;
  return rs.map((r) => r.value).reduce((p, c) => better(c, p, s) ? c : p);
}

double goalProgress(Goal g) {
  final s = store.specialtyOf(g.specialty);
  final rs = store.results.where((r) => r.specialty == g.specialty).toList()
    ..sort((a, b) => a.data.compareTo(b.data));
  if (rs.isEmpty) return 0;
  final base = rs.first.value;
  final best = goalBest(g)!;
  if (s.lowerIsBetter ? best <= g.target : best >= g.target) return 1;
  final span = (g.target - base).abs();
  if (span == 0) return 0;
  final done = s.lowerIsBetter ? base - best : best - base;
  return (done / span).clamp(0.0, 1.0).toDouble();
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Obiettivi stagionali')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const GoalForm())),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.goals.isEmpty) {
            return const EmptyState(Icons.flag_outlined,
                'Nessun obiettivo.\nEs. "Salto in lungo 5,00 m entro maggio".\nPuoi usarli anche come minimo di categoria da raggiungere.');
          }
          return ListView(padding: const EdgeInsets.only(bottom: 88, top: 8), children: [
            for (final g in store.goals) _tile(context, g),
          ]);
        },
      ),
    );
  }

  Widget _tile(BuildContext context, Goal g) {
    final s = store.specialtyOf(g.specialty);
    final best = goalBest(g);
    final p = goalProgress(g);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(p >= 1 ? Icons.check_circle : Icons.flag,
            color: p >= 1 ? Colors.green : null),
        title: Text('${g.specialty}: ${fmtPerf(g.target, s.kind)}'),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text([
            best == null ? 'Nessun risultato' : 'Attuale ${fmtPerf(best, s.kind)}',
            if (g.scadenza != null) 'entro ${fmtDate(g.scadenza!)}',
          ].join(' · ')),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: p, minHeight: 8),
          const SizedBox(height: 2),
          Text('${(p * 100).round()}%'),
          if (g.note.isNotEmpty) Text(g.note),
        ]),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => GoalForm(goal: g))),
      ),
    );
  }
}

class GoalForm extends StatefulWidget {
  final Goal? goal;
  const GoalForm({super.key, this.goal});
  @override
  State<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<GoalForm> {
  late String specialty;
  DateTime? scadenza;
  late final TextEditingController target, note;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    specialty = g?.specialty ?? store.specialties.first.name;
    scadenza = g?.scadenza;
    final s = store.specialtyOf(specialty);
    target = TextEditingController(
        text: g == null ? '' : fmtPerf(g.target, s.kind).replaceAll(RegExp(r'[^0-9:.]'), ''));
    note = TextEditingController(text: g?.note);
  }

  Future<void> _save() async {
    final s = store.specialtyOf(specialty);
    final v = parsePerf(target.text, s.kind);
    if (v == null) {
      snack(context, 'Valore non valido');
      return;
    }
    await store.put(
        store.goals,
        Goal(
          id: widget.goal?.id ?? newId(),
          specialty: specialty,
          target: v,
          scadenza: scadenza,
          note: note.text.trim(),
        ),
        (x) => x.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = store.specialtyOf(specialty);
    final hint = switch (s.kind) {
      Kind.time => 'es. 11.45  /  2:05.30',
      Kind.dist => 'es. 5.00 (metri)',
      Kind.points => 'es. 3500',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? 'Nuovo obiettivo' : 'Modifica obiettivo'),
        actions: [
          if (widget.goal != null)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await confirm(context, 'Eliminare questo obiettivo?')) {
                    await store.remove(store.goals, widget.goal!.id, (x) => x.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                }),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(
          value: specialty,
          isExpanded: true,
          decoration:
              const InputDecoration(labelText: 'Specialità', border: OutlineInputBorder()),
          items: [
            for (final sp in store.specialties)
              DropdownMenuItem(value: sp.name, child: Text(sp.name)),
          ],
          onChanged: (v) => setState(() => specialty = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: target,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: 'Obiettivo', hintText: hint, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        ListTile(
          shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4)),
          title: const Text('Scadenza (facoltativa)'),
          subtitle: Text(scadenza == null ? 'Nessuna' : fmtDate(scadenza!)),
          trailing: scadenza == null
              ? const Icon(Icons.calendar_today)
              : IconButton(
                  icon: const Icon(Icons.clear), onPressed: () => setState(() => scadenza = null)),
          onTap: () async {
            final d = await pickDate(context, scadenza ?? DateTime.now(),
                first: DateTime(2020), last: DateTime.now().add(const Duration(days: 365 * 3)));
            if (d != null) setState(() => scadenza = d);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
        ),
      ]),
    );
  }
}
