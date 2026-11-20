import 'package:flutter/material.dart';

import 'categories.dart';
import 'models.dart';
import 'safety.dart';
import 'screens_agenda.dart';
import 'screens_club.dart';
import 'stats.dart';
import 'store.dart';
import 'widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _deadline(String label, DateTime? d) {
    if (d == null) return const SizedBox.shrink();
    final days = daysFrom(d);
    final color = days < 0 ? Colors.red : (days <= 30 ? Colors.orange : Colors.green);
    return ListTile(
      dense: true,
      leading: Icon(days < 0 ? Icons.error : Icons.event_available, color: color),
      title: Text(label),
      subtitle: Text(
          '${fmtDate(d)} · ${days < 0 ? 'scaduto da ${-days} giorni' : whenLabel(days)}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final a = store.athlete;
        return Scaffold(
          appBar: AppBar(title: const Text('Il mio profilo'), actions: [
            if (a != null)
              IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ProfileForm(athlete: a)))),
          ]),
          body: a == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset('assets/icon.png', height: 140),
                      const SizedBox(height: 16),
                      const Text('Benvenuto! Crea il tuo profilo atleta per iniziare.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ProfileForm())),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Crea profilo')),
                    ]),
                  ),
                )
              : ListView(padding: const EdgeInsets.all(16), children: [
                  const SafetyBanner(),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.fullName, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(categoriaFidal(a.nascita, a.sesso),
                            style: Theme.of(context).textTheme.titleMedium),
                        if (store.club.nome.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.flag, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text(store.club.nome)),
                          ]),
                        ],
                        const SizedBox(height: 8),
                        Text('Nato/a il ${fmtDate(a.nascita)} (${etaAnnoSolare(a.nascita)} anni nell\'anno solare)'),
                        if (a.tessera.isNotEmpty) Text('Tessera FIDAL: ${a.tessera}'),
                        if (a.note.isNotEmpty) ...[const SizedBox(height: 8), Text(a.note)],
                      ]),
                    ),
                  ),
                  if (a.scadenzaCertificato != null || a.scadenzaTessera != null)
                    Card(
                      child: Column(children: [
                        _deadline('Certificato medico', a.scadenzaCertificato),
                        _deadline('Tessera', a.scadenzaTessera),
                      ]),
                    ),
                  ImageSlot(
                    label: 'Tessera FIDAL',
                    fileName: a.fotoFidal,
                    onChanged: (v) {
                      a.fotoFidal = v;
                      store.setAthlete(a);
                    },
                  ),
                  ImageSlot(
                    label: 'Tessera società',
                    fileName: a.fotoSocieta,
                    onChanged: (v) {
                      a.fotoSocieta = v;
                      store.setAthlete(a);
                    },
                  ),
                  const SizedBox(height: 8),
                  const ClubSection(),
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final next = agendaItems()
                        .where((i) => daysFrom(i.data) >= 0 && !i.auto)
                        .take(3)
                        .toList();
                    if (next.isEmpty) return const SizedBox.shrink();
                    return Card(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Text('Prossimi impegni',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        for (final i in next)
                          ListTile(
                            dense: true,
                            leading: Icon(eventIcon(i.tipo)),
                            title: Text(i.titolo),
                            subtitle: Text('${fmtDate(i.data)} · ${whenLabel(daysFrom(i.data))}'),
                          ),
                      ]),
                    );
                  }),
                ]),
        );
      },
    );
  }
}

class ProfileForm extends StatefulWidget {
  final Athlete? athlete;
  const ProfileForm({super.key, this.athlete});
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController nome, cognome, tessera, note, cicloMedio, durataMestruo;
  late String sesso;
  late DateTime nascita;
  String? fotoFidal, fotoSocieta;
  DateTime? scadCert, scadTessera, ultimoCiclo;

  @override
  void initState() {
    super.initState();
    final a = widget.athlete;
    nome = TextEditingController(text: a?.nome);
    cognome = TextEditingController(text: a?.cognome);
    tessera = TextEditingController(text: a?.tessera);
    note = TextEditingController(text: a?.note);
    cicloMedio = TextEditingController(text: '${a?.cicloMedio ?? 28}');
    durataMestruo = TextEditingController(text: '${a?.durataMestruo ?? 5}');
    sesso = a?.sesso ?? 'M';
    nascita = a?.nascita ?? DateTime(DateTime.now().year - 15, 1, 1);
    fotoFidal = a?.fotoFidal;
    fotoSocieta = a?.fotoSocieta;
    scadCert = a?.scadenzaCertificato;
    scadTessera = a?.scadenzaTessera;
    ultimoCiclo = a?.ultimoCiclo;
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final isF = sesso == 'F';
    await store.setAthlete(Athlete(
      id: widget.athlete?.id ?? newId(),
      nome: nome.text.trim(),
      cognome: cognome.text.trim(),
      sesso: sesso,
      nascita: nascita,
      tessera: tessera.text.trim(),
      fotoFidal: fotoFidal,
      fotoSocieta: fotoSocieta,
      note: note.text.trim(),
      scadenzaCertificato: scadCert,
      scadenzaTessera: scadTessera,
      cicloMedio: isF ? (int.tryParse(cicloMedio.text) ?? 28).clamp(15, 60).toInt() : 28,
      durataMestruo: isF ? (int.tryParse(durataMestruo.text) ?? 5).clamp(1, 12).toInt() : 5,
      ultimoCiclo: isF ? ultimoCiclo : null,
    ));
    if (mounted) Navigator.pop(context);
  }

  Widget _dateTile(String label, DateTime? value, ValueChanged<DateTime?> onChanged,
      {DateTime? first, DateTime? last}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(4)),
        title: Text(label),
        subtitle: Text(value == null ? 'Non impostata' : fmtDate(value)),
        trailing: value == null
            ? const Icon(Icons.calendar_today)
            : IconButton(icon: const Icon(Icons.clear), onPressed: () => onChanged(null)),
        onTap: () async {
          final d = await pickDate(context, value ?? DateTime.now(), first: first, last: last);
          if (d != null) onChanged(d);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final future = DateTime.now().add(const Duration(days: 365 * 5));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.athlete == null ? 'Crea profilo' : 'Modifica profilo'),
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
            subtitle: Text('${fmtDate(nascita)} → ${categoriaFidal(nascita, sesso)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await pickDate(context, nascita, last: DateTime.now());
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
          _dateTile('Scadenza certificato medico', scadCert,
              (d) => setState(() => scadCert = d),
              first: DateTime(2020), last: future),
          _dateTile('Scadenza tessera', scadTessera, (d) => setState(() => scadTessera = d),
              first: DateTime(2020), last: future),
          ImageSlot(
              label: 'Foto tessera FIDAL',
              fileName: fotoFidal,
              onChanged: (v) => setState(() => fotoFidal = v)),
          ImageSlot(
              label: 'Foto tessera società',
              fileName: fotoSocieta,
              onChanged: (v) => setState(() => fotoSocieta = v)),
          if (sesso == 'F')
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ciclo mestruale', style: Theme.of(context).textTheme.titleSmall),
                  const Text(
                      'Dati facoltativi, visibili solo nei profili femminili e salvati solo sul tuo dispositivo.',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: cicloMedio,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Durata media ciclo (giorni)',
                            border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: durataMestruo,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Giorni di mestruazione',
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _dateTile('Inizio ultimo ciclo', ultimoCiclo,
                      (d) => setState(() => ultimoCiclo = d),
                      first: DateTime.now().subtract(const Duration(days: 365)),
                      last: DateTime.now()),
                ]),
              ),
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
