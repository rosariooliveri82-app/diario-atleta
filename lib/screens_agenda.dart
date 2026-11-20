import 'package:flutter/material.dart';

import 'models.dart';
import 'models_extra.dart';
import 'stats.dart';
import 'store.dart';
import 'widgets.dart';

IconData eventIcon(String tipo) {
  switch (tipo) {
    case 'Gara':
      return Icons.emoji_events;
    case 'Allenamento collegiale':
      return Icons.groups;
    case 'Visita medica':
      return Icons.medical_services_outlined;
    case 'Scadenza':
      return Icons.event_busy;
    default:
      return Icons.event;
  }
}

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  Color? _color(AgendaItem i, int days) {
    if (i.tipo == 'Scadenza' || i.tipo == 'Visita medica') {
      if (days < 0) return Colors.red;
      if (days <= 7) return Colors.red;
      if (days <= 30) return Colors.orange;
      return Colors.green;
    }
    return null;
  }

  Widget _tile(BuildContext context, AgendaItem i) {
    final days = daysFrom(i.data);
    final sub = (i.sub ?? '').isEmpty ? '' : '\n${i.sub}';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(eventIcon(i.tipo), color: _color(i, days)),
        title: Text(i.titolo),
        subtitle: Text('${fmtDate(i.data)} · ${whenLabel(days)}$sub'),
        isThreeLine: sub.isNotEmpty,
        onTap: i.event == null
            ? null
            : () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => EventForm(event: i.event))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const EventForm())),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final items = agendaItems();
          final up = items.where((i) => daysFrom(i.data) >= 0 || i.auto).toList();
          final past = items.where((i) => daysFrom(i.data) < 0 && !i.auto).toList().reversed.toList();
          if (items.isEmpty) {
            return const EmptyState(Icons.event,
                'Nessun impegno.\nTocca + per aggiungere gare, visite o scadenze.\nLe scadenze di certificato e tessera si impostano nel Profilo.');
          }
          return ListView(padding: const EdgeInsets.only(bottom: 88, top: 8), children: [
            for (final i in up) _tile(context, i),
            if (past.isNotEmpty)
              ExpansionTile(
                title: const Text('Passati'),
                children: [for (final i in past) _tile(context, i)],
              ),
          ]);
        },
      ),
    );
  }
}

class EventForm extends StatefulWidget {
  final EventItem? event;
  const EventForm({super.key, this.event});
  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  late String tipo;
  late DateTime data;
  late final TextEditingController titolo, luogo, note;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    tipo = e?.tipo ?? 'Gara';
    data = e?.data ?? DateTime.now().add(const Duration(days: 7));
    titolo = TextEditingController(text: e?.titolo);
    luogo = TextEditingController(text: e?.luogo);
    note = TextEditingController(text: e?.note);
  }

  Future<void> _save() async {
    if (titolo.text.trim().isEmpty) {
      snack(context, 'Inserisci un titolo');
      return;
    }
    await store.put(
        store.events,
        EventItem(
          id: widget.event?.id ?? newId(),
          data: data,
          tipo: tipo,
          titolo: titolo.text.trim(),
          luogo: luogo.text.trim(),
          note: note.text.trim(),
        ),
        (x) => x.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Nuovo impegno' : 'Modifica impegno'),
        actions: [
          if (widget.event != null)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await confirm(context, 'Eliminare questo impegno?')) {
                    await store.remove(store.events, widget.event!.id, (x) => x.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                }),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(
          value: tipo,
          decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
          items: [for (final t in eventTypes) DropdownMenuItem(value: t, child: Text(t))],
          onChanged: (v) => setState(() => tipo = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: titolo,
          decoration: const InputDecoration(
              labelText: 'Titolo (es. Campionato regionale)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
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
        TextField(
          controller: luogo,
          decoration: const InputDecoration(labelText: 'Luogo', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Note (specialità, orari, ritrovo…)', border: OutlineInputBorder()),
        ),
      ]),
    );
  }
}
