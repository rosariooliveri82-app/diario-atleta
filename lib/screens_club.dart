import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'store.dart';
import 'widgets.dart';

class ClubScreen extends StatelessWidget {
  const ClubScreen({super.key});

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    if (!await launchUrl(uri) && context.mounted) {
      snack(context, 'Impossibile avviare la chiamata');
    }
  }

  Future<void> _editContact(BuildContext context, {Contact? c}) async {
    final label = TextEditingController(text: c?.label);
    final num = TextEditingController(text: c?.numero);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(c == null ? 'Nuovo numero' : 'Modifica numero'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: label,
              decoration: const InputDecoration(
                  labelText: 'Etichetta', hintText: 'es. Tenda società, Allenatore')),
          TextField(
              controller: num,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Numero')),
        ]),
        actions: [
          if (c != null)
            TextButton(
                onPressed: () {
                  store.club.contatti.remove(c);
                  store.save();
                  Navigator.pop(d, false);
                },
                child: const Text('Elimina')),
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Salva')),
        ],
      ),
    );
    if (ok != true) return;
    if (c == null) {
      store.club.contatti.add(Contact(label.text.trim(), num.text.trim()));
    } else {
      c.label = label.text.trim();
      c.numero = num.text.trim();
    }
    await store.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Società'), actions: [
        IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ClubForm()))),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editContact(context),
        child: const Icon(Icons.add_call),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final c = store.club;
          return ListView(padding: const EdgeInsets.only(bottom: 88), children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: c.nome.isEmpty
                    ? const Text('Tocca la matita per inserire i dati della società.')
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.nome, style: Theme.of(context).textTheme.titleLarge),
                        if (c.codice.isNotEmpty) Text('Codice FIDAL: ${c.codice}'),
                        if (c.indirizzo.isNotEmpty) Text(c.indirizzo),
                        if (c.email.isNotEmpty) Text(c.email),
                      ]),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Numeri da contattare',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (c.contatti.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nessun numero. Tocca + per aggiungerne (tenda, allenatore, dirigenti…).'),
              ),
            for (final k in c.contatti)
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(k.label),
                subtitle: Text(k.numero),
                onTap: () => _call(context, k.numero),
                trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editContact(context, c: k)),
              ),
          ]);
        },
      ),
    );
  }
}

class ClubForm extends StatefulWidget {
  const ClubForm({super.key});
  @override
  State<ClubForm> createState() => _ClubFormState();
}

class _ClubFormState extends State<ClubForm> {
  late final nome = TextEditingController(text: store.club.nome);
  late final codice = TextEditingController(text: store.club.codice);
  late final indirizzo = TextEditingController(text: store.club.indirizzo);
  late final email = TextEditingController(text: store.club.email);

  Widget _f(TextEditingController c, String l) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
            controller: c,
            decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dati società'), actions: [
        IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              await store.setClub(Club(
                nome: nome.text.trim(),
                codice: codice.text.trim(),
                indirizzo: indirizzo.text.trim(),
                email: email.text.trim(),
                contatti: store.club.contatti,
              ));
              if (context.mounted) Navigator.pop(context);
            }),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _f(nome, 'Nome società'),
        _f(codice, 'Codice società FIDAL'),
        _f(indirizzo, 'Indirizzo / campo di allenamento'),
        _f(email, 'Email'),
      ]),
    );
  }
}
