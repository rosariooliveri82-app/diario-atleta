import 'package:flutter/material.dart';

import 'models.dart';
import 'store.dart';
import 'widgets.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  String? filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Allenamenti')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final a = store.currentAthlete;
          if (a == null) {
            snack(context, 'Crea prima un atleta');
            return;
          }
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => SessionForm(athleteId: a.id, tipo: filter)));
        },
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final a = store.currentAthlete;
          if (a == null) {
            return const EmptyState(Icons.fitness_center,
                'Crea un atleta dalla scheda "Atleti" per usare il diario.');
          }
          final mine = store.sessions.where((s) => s.athleteId == a.id).toList();
          final types = mine.map((s) => s.tipo).toSet().toList()..sort();
          if (filter != null && !types.contains(filter)) filter = null;
          final shown = mine.where((s) => filter == null || s.tipo == filter).toList()
            ..sort((x, y) => y.data.compareTo(x.data));
          return Column(children: [
            const AthletePicker(),
            if (types.isNotEmpty)
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                          label: const Text('Tutti'),
                          selected: filter == null,
                          onSelected: (_) => setState(() => filter = null)),
                    ),
                    for (final t in types)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                            label: Text(t),
                            selected: filter == t,
                            onSelected: (_) => setState(() => filter = t)),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: shown.isEmpty
                  ? const EmptyState(Icons.fitness_center,
                      'Nessun allenamento.\nTocca + per registrare una seduta.')
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 88),
                      children: [for (final s in shown) _tile(context, s)],
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _tile(BuildContext context, Session s) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(s.titolo.isEmpty ? s.tipo : '${s.tipo} · ${s.titolo}'),
        subtitle: Text([
          fmtDate(s.data),
          if (s.durata > 0) '${s.durata} min',
          'RPE ${s.rpe}',
          if (s.exercises.isNotEmpty) '\n${s.exercises.map((e) => e.summary).join('\n')}',
        ].join(' · ').replaceAll(' · \n', '\n')),
        isThreeLine: s.exercises.isNotEmpty,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'dup') {
              await store.upsertSession(Session(
                id: newId(),
                athleteId: s.athleteId,
                data: DateTime.now(),
                tipo: s.tipo,
                titolo: s.titolo,
                durata: s.durata,
                rpe: s.rpe,
                note: s.note,
                exercises: s.exercises
                    .map((e) => Exercise(
                        nome: e.nome,
                        serie: e.serie,
                        rip: e.rip,
                        misura: e.misura,
                        recupero: e.recupero))
                    .toList(),
              ));
              if (context.mounted) snack(context, 'Seduta duplicata con data di oggi');
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'dup', child: Text('Duplica (data di oggi)')),
          ],
        ),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SessionForm(athleteId: s.athleteId, session: s))),
      ),
    );
  }
}

class SessionForm extends StatefulWidget {
  final String athleteId;
  final Session? session;
  final String? tipo;
  const SessionForm({super.key, required this.athleteId, this.session, this.tipo});
  @override
  State<SessionForm> createState() => _SessionFormState();
}

class _ExRow {
  final nome = TextEditingController();
  final serie = TextEditingController();
  final rip = TextEditingController();
  final misura = TextEditingController();
  final recupero = TextEditingController();
  final risultati = TextEditingController();
  _ExRow([Exercise? e]) {
    if (e != null) {
      nome.text = e.nome;
      serie.text = e.serie;
      rip.text = e.rip;
      misura.text = e.misura;
      recupero.text = e.recupero;
      risultati.text = e.risultati;
    }
  }
  Exercise toExercise() => Exercise(
        nome: nome.text.trim(),
        serie: serie.text.trim(),
        rip: rip.text.trim(),
        misura: misura.text.trim(),
        recupero: recupero.text.trim(),
        risultati: risultati.text.trim(),
      );
}

class _SessionFormState extends State<SessionForm> {
  late String tipo;
  late DateTime data;
  late int rpe;
  late final TextEditingController titolo, durata, note;
  late List<_ExRow> rows;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    tipo = s?.tipo ?? widget.tipo ?? store.trainingTypes.first;
    data = s?.data ?? DateTime.now();
    rpe = s?.rpe ?? 5;
    titolo = TextEditingController(text: s?.titolo);
    durata = TextEditingController(text: (s?.durata ?? 0) > 0 ? '${s!.durata}' : '');
    note = TextEditingController(text: s?.note);
    rows = (s?.exercises ?? []).map((e) => _ExRow(e)).toList();
  }

  Future<void> _newType() async {
    final t = await askText(context, 'Nuovo tipo di allenamento', hint: 'es. Skip, Circuito, Piscina');
    if (t == null || t.isEmpty) return;
    await store.addTrainingType(t);
    setState(() => tipo = t);
  }

  Future<void> _save() async {
    await store.upsertSession(Session(
      id: widget.session?.id ?? newId(),
      athleteId: widget.athleteId,
      data: data,
      tipo: tipo,
      titolo: titolo.text.trim(),
      durata: int.tryParse(durata.text.trim()) ?? 0,
      rpe: rpe,
      note: note.text.trim(),
      exercises: rows
          .map((r) => r.toExercise())
          .where((e) => e.nome.isNotEmpty)
          .toList(),
    ));
    if (mounted) Navigator.pop(context);
  }

  Widget _field(TextEditingController c, String label, {TextInputType? kb}) => TextField(
        controller: c,
        keyboardType: kb,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder(), isDense: true),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session == null ? 'Nuova seduta' : 'Modifica seduta'),
        actions: [
          if (widget.session != null)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await confirm(context, 'Eliminare questa seduta?')) {
                    await store.deleteSession(widget.session!.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                }),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: tipo,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Tipo', border: OutlineInputBorder()),
              items: [
                for (final t in store.trainingTypes)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => tipo = v!),
            ),
          ),
          IconButton(onPressed: _newType, icon: const Icon(Icons.add_circle_outline)),
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
        _field(titolo, 'Titolo (facoltativo)'),
        const SizedBox(height: 12),
        _field(durata, 'Durata (minuti)', kb: TextInputType.number),
        const SizedBox(height: 12),
        Text('Sforzo percepito (RPE): $rpe / 10'),
        Slider(
            value: rpe.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$rpe',
            onChanged: (v) => setState(() => rpe = v.round())),
        const Divider(),
        Text('Esercizi', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < rows.length; i++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(children: [
                  Expanded(child: _field(rows[i].nome, 'Esercizio (es. Ripetute 150m, Balzi)')),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => rows.removeAt(i))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _field(rows[i].serie, 'Serie', kb: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(rows[i].rip, 'Rip.', kb: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(rows[i].recupero, 'Recupero')),
                ]),
                const SizedBox(height: 8),
                _field(rows[i].misura, 'Distanza / carico / altezza'),
                const SizedBox(height: 8),
                _field(rows[i].risultati, 'Tempi / misure ottenute'),
              ]),
            ),
          ),
        OutlinedButton.icon(
            onPressed: () => setState(() => rows.add(_ExRow())),
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi esercizio')),
        const SizedBox(height: 16),
        TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
        ),
      ]),
    );
  }
}
