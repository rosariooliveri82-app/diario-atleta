int _counter = 0;
String newId() =>
    DateTime.now().microsecondsSinceEpoch.toRadixString(36) + (_counter++).toString();

String two(int n) => n.toString().padLeft(2, '0');
String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
String isoDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

enum Kind { time, dist, points }

class Specialty {
  final String name;
  final Kind kind;
  const Specialty(this.name, this.kind);
  Map<String, dynamic> toJson() => {'name': name, 'kind': kind.name};
  factory Specialty.fromJson(Map<String, dynamic> j) => Specialty(
      j['name'] as String, Kind.values.firstWhere((k) => k.name == j['kind']));
  bool get lowerIsBetter => kind == Kind.time;
}

const defaultSpecialties = <Specialty>[
  Specialty('50 m', Kind.time),
  Specialty('60 m', Kind.time),
  Specialty('80 m', Kind.time),
  Specialty('100 m', Kind.time),
  Specialty('150 m', Kind.time),
  Specialty('200 m', Kind.time),
  Specialty('300 m', Kind.time),
  Specialty('400 m', Kind.time),
  Specialty('600 m', Kind.time),
  Specialty('800 m', Kind.time),
  Specialty('1000 m', Kind.time),
  Specialty('1500 m', Kind.time),
  Specialty('2000 m', Kind.time),
  Specialty('3000 m', Kind.time),
  Specialty('5000 m', Kind.time),
  Specialty('10000 m', Kind.time),
  Specialty('60 hs', Kind.time),
  Specialty('80 hs', Kind.time),
  Specialty('100 hs', Kind.time),
  Specialty('110 hs', Kind.time),
  Specialty('200 hs', Kind.time),
  Specialty('300 hs', Kind.time),
  Specialty('400 hs', Kind.time),
  Specialty('1200 siepi', Kind.time),
  Specialty('2000 siepi', Kind.time),
  Specialty('3000 siepi', Kind.time),
  Specialty('Marcia', Kind.time),
  Specialty('Staffetta', Kind.time),
  Specialty('Cross', Kind.time),
  Specialty('Salto in alto', Kind.dist),
  Specialty('Salto con l\'asta', Kind.dist),
  Specialty('Salto in lungo', Kind.dist),
  Specialty('Salto triplo', Kind.dist),
  Specialty('Getto del peso', Kind.dist),
  Specialty('Lancio del disco', Kind.dist),
  Specialty('Lancio del martello', Kind.dist),
  Specialty('Lancio del giavellotto', Kind.dist),
  Specialty('Lancio del vortex', Kind.dist),
  Specialty('Lancio della palla', Kind.dist),
  Specialty('Pentathlon', Kind.points),
  Specialty('Esathlon', Kind.points),
  Specialty('Eptathlon', Kind.points),
  Specialty('Decathlon', Kind.points),
];

const defaultTrainingTypes = <String>[
  'Ripetute',
  'Corsa continua',
  'Pliometria',
  'Lanci',
  'Forza / Pesi',
  'Tecnica',
  'Mobilità / Stretching',
  'Gara',
  'Altro',
];

String fmtTime(double s) {
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  final secStr = sec.toStringAsFixed(2).padLeft(5, '0');
  if (h > 0) return '$h:${two(m)}:$secStr';
  if (m > 0) return '$m:$secStr';
  return secStr;
}

String fmtPerf(double v, Kind k) {
  switch (k) {
    case Kind.time:
      return fmtTime(v);
    case Kind.dist:
      return '${v.toStringAsFixed(2)} m';
    case Kind.points:
      return '${v.toStringAsFixed(0)} pt';
  }
}

/// Tempi: "11.45", "2:05.30", "1:02:10.5". Misure: "5.82".
double? parsePerf(String text, Kind k) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  if (k != Kind.time) return double.tryParse(t);
  try {
    double total = 0;
    for (final p in t.split(':')) {
      total = total * 60 + double.parse(p);
    }
    return total;
  } catch (_) {
    return null;
  }
}

class Athlete {
  String id;
  String nome;
  String cognome;
  String sesso; // 'M' | 'F'
  DateTime nascita;
  String tessera;
  String? fotoFidal;
  String? fotoSocieta;
  String note;

  Athlete({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.sesso,
    required this.nascita,
    this.tessera = '',
    this.fotoFidal,
    this.fotoSocieta,
    this.note = '',
  });

  String get fullName => '$cognome $nome';

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'cognome': cognome,
        'sesso': sesso,
        'nascita': isoDate(nascita),
        'tessera': tessera,
        'fotoFidal': fotoFidal,
        'fotoSocieta': fotoSocieta,
        'note': note,
      };

  factory Athlete.fromJson(Map<String, dynamic> j) => Athlete(
        id: j['id'],
        nome: j['nome'] ?? '',
        cognome: j['cognome'] ?? '',
        sesso: j['sesso'] ?? 'M',
        nascita: DateTime.parse(j['nascita']),
        tessera: j['tessera'] ?? '',
        fotoFidal: j['fotoFidal'],
        fotoSocieta: j['fotoSocieta'],
        note: j['note'] ?? '',
      );
}

class Result {
  String id;
  String athleteId;
  DateTime data;
  String specialty;
  double value;
  String luogo;
  String vento;
  String note;

  Result({
    required this.id,
    required this.athleteId,
    required this.data,
    required this.specialty,
    required this.value,
    this.luogo = '',
    this.vento = '',
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'athleteId': athleteId,
        'data': isoDate(data),
        'specialty': specialty,
        'value': value,
        'luogo': luogo,
        'vento': vento,
        'note': note,
      };

  factory Result.fromJson(Map<String, dynamic> j) => Result(
        id: j['id'],
        athleteId: j['athleteId'],
        data: DateTime.parse(j['data']),
        specialty: j['specialty'],
        value: (j['value'] as num).toDouble(),
        luogo: j['luogo'] ?? '',
        vento: j['vento'] ?? '',
        note: j['note'] ?? '',
      );
}

class Exercise {
  String nome;
  String serie;
  String rip;
  String misura; // distanza, carico, altezza ostacoli...
  String recupero;
  String risultati; // tempi / misure ottenute

  Exercise({
    this.nome = '',
    this.serie = '',
    this.rip = '',
    this.misura = '',
    this.recupero = '',
    this.risultati = '',
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'serie': serie,
        'rip': rip,
        'misura': misura,
        'recupero': recupero,
        'risultati': risultati,
      };

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        nome: j['nome'] ?? '',
        serie: j['serie'] ?? '',
        rip: j['rip'] ?? '',
        misura: j['misura'] ?? '',
        recupero: j['recupero'] ?? '',
        risultati: j['risultati'] ?? '',
      );

  String get summary {
    final parts = <String>[];
    if (serie.isNotEmpty || rip.isNotEmpty) {
      parts.add('${serie.isEmpty ? 1 : serie}x${rip.isEmpty ? 1 : rip}');
    }
    if (misura.isNotEmpty) parts.add(misura);
    if (recupero.isNotEmpty) parts.add('rec $recupero');
    return '$nome${parts.isEmpty ? '' : ' · ${parts.join(' · ')}'}';
  }
}

class Session {
  String id;
  String athleteId;
  DateTime data;
  String tipo;
  String titolo;
  int durata; // minuti
  int rpe; // 1-10
  String note;
  List<Exercise> exercises;

  Session({
    required this.id,
    required this.athleteId,
    required this.data,
    required this.tipo,
    this.titolo = '',
    this.durata = 0,
    this.rpe = 5,
    this.note = '',
    List<Exercise>? exercises,
  }) : exercises = exercises ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'athleteId': athleteId,
        'data': isoDate(data),
        'tipo': tipo,
        'titolo': titolo,
        'durata': durata,
        'rpe': rpe,
        'note': note,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        id: j['id'],
        athleteId: j['athleteId'],
        data: DateTime.parse(j['data']),
        tipo: j['tipo'] ?? 'Altro',
        titolo: j['titolo'] ?? '',
        durata: j['durata'] ?? 0,
        rpe: j['rpe'] ?? 5,
        note: j['note'] ?? '',
        exercises: ((j['exercises'] ?? []) as List)
            .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class Contact {
  String label;
  String numero;
  Contact(this.label, this.numero);
  Map<String, dynamic> toJson() => {'label': label, 'numero': numero};
  factory Contact.fromJson(Map<String, dynamic> j) =>
      Contact(j['label'] ?? '', j['numero'] ?? '');
}

class Club {
  String nome;
  String codice;
  String indirizzo;
  String email;
  List<Contact> contatti;

  Club({
    this.nome = '',
    this.codice = '',
    this.indirizzo = '',
    this.email = '',
    List<Contact>? contatti,
  }) : contatti = contatti ?? [];

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'codice': codice,
        'indirizzo': indirizzo,
        'email': email,
        'contatti': contatti.map((c) => c.toJson()).toList(),
      };

  factory Club.fromJson(Map<String, dynamic> j) => Club(
        nome: j['nome'] ?? '',
        codice: j['codice'] ?? '',
        indirizzo: j['indirizzo'] ?? '',
        email: j['email'] ?? '',
        contatti: ((j['contatti'] ?? []) as List)
            .map((c) => Contact.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
      );
}
