import 'models.dart';

const eventTypes = <String>[
  'Gara',
  'Allenamento collegiale',
  'Visita medica',
  'Scadenza',
  'Altro',
];

class Goal {
  String id;
  String specialty;
  double target;
  DateTime? scadenza;
  String note;

  Goal({
    required this.id,
    required this.specialty,
    required this.target,
    this.scadenza,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'specialty': specialty,
        'target': target,
        'scadenza': isoOrNull(scadenza),
        'note': note,
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'],
        specialty: j['specialty'],
        target: (j['target'] as num).toDouble(),
        scadenza: dOrNull(j['scadenza']),
        note: j['note'] ?? '',
      );
}

class EventItem {
  String id;
  DateTime data;
  String tipo;
  String titolo;
  String luogo;
  String note;

  EventItem({
    required this.id,
    required this.data,
    required this.tipo,
    required this.titolo,
    this.luogo = '',
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': isoDate(data),
        'tipo': tipo,
        'titolo': titolo,
        'luogo': luogo,
        'note': note,
      };

  factory EventItem.fromJson(Map<String, dynamic> j) => EventItem(
        id: j['id'],
        data: DateTime.parse(j['data']),
        tipo: j['tipo'] ?? 'Altro',
        titolo: j['titolo'] ?? '',
        luogo: j['luogo'] ?? '',
        note: j['note'] ?? '',
      );
}

class Wellness {
  String id;
  DateTime data;
  double? peso;
  double? sonno;
  int dolore; // 0-10
  String infortunio;
  String note;

  Wellness({
    required this.id,
    required this.data,
    this.peso,
    this.sonno,
    this.dolore = 0,
    this.infortunio = '',
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': isoDate(data),
        'peso': peso,
        'sonno': sonno,
        'dolore': dolore,
        'infortunio': infortunio,
        'note': note,
      };

  factory Wellness.fromJson(Map<String, dynamic> j) => Wellness(
        id: j['id'],
        data: DateTime.parse(j['data']),
        peso: (j['peso'] as num?)?.toDouble(),
        sonno: (j['sonno'] as num?)?.toDouble(),
        dolore: j['dolore'] ?? 0,
        infortunio: j['infortunio'] ?? '',
        note: j['note'] ?? '',
      );
}

class CycleEntry {
  String id;
  DateTime start;
  int giorni; // durata mestruazioni
  String note;

  CycleEntry({required this.id, required this.start, this.giorni = 5, this.note = ''});

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': isoDate(start),
        'giorni': giorni,
        'note': note,
      };

  factory CycleEntry.fromJson(Map<String, dynamic> j) => CycleEntry(
        id: j['id'],
        start: DateTime.parse(j['start']),
        giorni: j['giorni'] ?? 5,
        note: j['note'] ?? '',
      );
}
