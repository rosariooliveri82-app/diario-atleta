import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'store.dart';
import 'widgets.dart';

/// Società dell'atleta + numeri utili da chiamare (inserita nel Profilo).
class ClubSection extends StatelessWidget {
  const ClubSection({super.key});

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    if (!await launchUrl(uri) && context.mounted) {
      snack(context, 'Impossibile avviare la chiamata');
    }
  }

  Future<void> _editContact(BuildContext context, {Contact? c}) async {
    final label = TextEditingController(text: c?.label);
    final numero = TextEditingController(text: c?.numero);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(c == null ? 'Nuovo numero utile' : 'Modifica numero'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: label,
              decoration: const InputDecoration(
                  labelText: 'Etichetta', hintText: 'es. Tenda società, Allenatore')),
          TextField(
              controller: numero,
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
      store.club.contatti.add(Contact(label.text.trim(), numero.text.trim()));
    } else {
      c.label = label.text.trim();
      c.numero = numero.text.trim();
    }
    await store.save();
  }

  @override
  Widget build(BuildContext context) {
    final c = store.club;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Card(
        child: ListTile(
          leading: const Icon(Icons.flag),
          title: Text(c.nome.isEmpty ? 'Società non inserita' : c.nome),
          subtitle: Text([
            if (c.codice.isNotEmpty) 'Codice FIDAL ${c.codice}',
            if (c.indirizzo.isNotEmpty) c.indirizzo,
            if (c.email.isNotEmpty) c.email,
          ].join('\n')),
          isThreeLine: false,
          trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ClubForm()))),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: Row(children: [
          Text('Numeri utili', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          TextButton.icon(
              onPressed: () => _editContact(context),
              icon: const Icon(Icons.add_call),
              label: const Text('Aggiungi')),
        ]),
      ),
      if (c.contatti.isEmpty)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Nessun numero. Aggiungi tenda società, allenatore, dirigenti…'),
        ),
      for (final k in c.contatti)
        Card(
          child: ListTile(
            leading: const Icon(Icons.phone, color: Color(0xFF2E7D32)),
            title: Text(k.label),
            subtitle: Text(k.numero),
            onTap: () => _call(context, k.numero),
            trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editContact(context, c: k)),
          ),
        ),
    ]);
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
