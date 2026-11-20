/// Categoria FIDAL calcolata sull'età compiuta nell'anno solare
/// (anno corrente - anno di nascita). Verificare ogni stagione le
/// tabelle ufficiali FIDAL: le fasce possono cambiare.
String categoriaFidal(DateTime nascita, String sesso, {DateTime? on}) {
  final age = (on ?? DateTime.now()).year - nascita.year;
  final f = sesso == 'F';
  String g(String m, String fm) => f ? fm : m;

  if (age <= 5) return 'Esordienti 5';
  if (age <= 7) return 'Esordienti C';
  if (age <= 9) return 'Esordienti B';
  if (age <= 11) return 'Esordienti A';
  if (age <= 13) return g('Ragazzi', 'Ragazze');
  if (age <= 15) return g('Cadetti', 'Cadette');
  if (age <= 17) return g('Allievi', 'Allieve');
  if (age <= 19) return g('Juniores M', 'Juniores F');
  if (age <= 22) return g('Promesse M', 'Promesse F');
  if (age <= 34) return g('Seniores M', 'Seniores F');
  final band = (age ~/ 5) * 5;
  return g('Master SM$band', 'Master SF$band');
}

int etaAnnoSolare(DateTime nascita, {DateTime? on}) =>
    (on ?? DateTime.now()).year - nascita.year;
