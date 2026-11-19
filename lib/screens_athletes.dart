import 'package:flutter/material.dart';

import 'categories.dart';
import 'models.dart';
import 'store.dart';
import 'widgets.dart';

class AthletesScreen extends StatelessWidget {
  const AthletesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atleti')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AthleteForm())),
        child: const Icon(Icons.person_add),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.athletes.isEmpty) {
            return const EmptyState(Icons.directions_run,
                'Nessun atleta.\nTocca + per creare il primo profilo.');
          }
          return ListView(
            children: [
              for (final a in store.athletes)
                ListTile(
                  leading: CircleAvatar(
                      child: Text(
                          '${a.cognome.isEmpty ? '?' : a.cognome[0]}${a.nome.isEmpty ? '' : a.nome[0]}'
                              .toUpperCase())),
                  title: Text(a.fullName),
                  subtitle: Text(
                      '${categoriaFidal(a.nascita, a.sesso)} · ${etaAnnoSolare(a.nascita)} anni'),
                  trailing: store.currentAthlete?.id == a.id
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AthleteDetail(id: a.id))),
                ),
            ],
          );
        },
      ),
    );
  }
}

class AthleteDetail extends StatelessWidget {
  final String id;
  const AthleteDetail({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final a = store.athletes.where((x) => x.id == id).firstOrNull;
        if (a == null) return const Scaffold(body: SizedBox());
        return Scaffold(
          appBar: AppBar(title: Text(a.fullName), actions: [
            IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AthleteForm(athlete: a)))),
            IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await confirm(context,
                      'Eliminare ${a.fullName} con tutte le gare e gli allenamenti?')) {
                    await store.deleteAthlete(a.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                }),
          ]),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(categoriaFidal(a.nascita, a.sesso),
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Nato/a il ${fmtDate(a.nascita)} (${etaAnnoSolare(a.nascita)} anni nell\'anno solare)'),
                  Text('Sesso: ${a.sesso == 'F' ? 'Femmina' : 'Maschio'}'),
                  if (a.tessera.isNotEmpty) Text('Tessera: ${a.tessera}'),
                  if (a.note.isNotEmpty) ...[const SizedBox(height: 8), Text(a.note)],
                ]),
              ),
            ),
            if (a.fotoFidal != null)
              ImageSlot(label: 'Tessera FIDAL', fileName: a.fotoFidal, onChanged: (_) {}),
            if (a.fotoSocieta != null)
              ImageSlot(label: 'Tessera società', fileName: a.fotoSocieta, onChanged: (_) {}),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                store.selectAthlete(a.id);
                snack(context, '${a.fullName} è ora l\'atleta attivo');
              },
              icon: const Icon(Icons.check),
              label: const Text('Usa come atleta attivo'),
            ),
          ]),
        );
      },
    );
  }
}

class AthleteForm extends StatefulWidget {
  final Athlete? athlete;
  const AthleteForm({super.key, this.athlete});
  @override
  State<AthleteForm> createState() => _AthleteFormState();
}

class _AthleteFormState extends State<AthleteForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController nome, cognome, tessera, note;
  late String sesso;
  late DateTime nascita;
  String? fotoFidal, fotoSocieta;

  @override
  void initState() {
    super.initState();
    final a = widget.athlete;
    nome = TextEditingController(text: a?.nome);
    cognome = TextEditingController(text: a?.cognome);
    tessera = TextEditingController(text: a?.tessera);
    note = TextEditingController(text: a?.note);
    sesso = a?.sesso ?? 'M';
    nascita = a?.nascita ?? DateTime(DateTime.now().year - 15, 1, 1);
    fotoFidal = a?.fotoFidal;
    fotoSocieta = a?.fotoSocieta;
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    await store.upsertAthlete(Athlete(
      id: widget.athlete?.id ?? newId(),
      nome: nome.text.trim(),
      cognome: cognome.text.trim(),
      sesso: sesso,
      nascita: nascita,
      tessera: tessera.text.trim(),
      fotoFidal: fotoFidal,
      fotoSocieta: fotoSocieta,
      note: note.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.athlete == null ? 'Nuovo atleta' : 'Modifica atleta'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Form(
        key: _key,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: cognome,
            decoration: const InputDecoration(labelText: 'Cognome', border: OutlineInputBorder()),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: nome,
            decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'M', label: Text('Maschio')),
              ButtonSegment(value: 'F', label: Text('Femmina')),
            ],
            selected: {sesso},
            onSelectionChanged: (s) => setState(() => sesso = s.first),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(4)),
            title: const Text('Data di nascita'),
            subtitle: Text(
                '${fmtDate(nascita)} → ${categoriaFidal(nascita, sesso)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await pickDate(context, nascita,
                  last: DateTime.now());
              if (d != null) setState(() => nascita = d);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: tessera,
            decoration: const InputDecoration(
                labelText: 'N. tessera FIDAL', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          ImageSlot(
              label: 'Foto tessera FIDAL',
              fileName: fotoFidal,
              onChanged: (v) => setState(() => fotoFidal = v)),
          ImageSlot(
              label: 'Foto tessera società',
              fileName: fotoSocieta,
              onChanged: (v) => setState(() => fotoSocieta = v)),
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
