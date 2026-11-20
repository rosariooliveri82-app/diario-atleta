import 'models.dart';
import 'models_extra.dart';
import 'store.dart';

bool better(double a, double b, Specialty s) => s.lowerIsBetter ? a < b : a > b;

class Rec {
  final Specialty spec;
  final Result pb;
  final Result? sb;
  Rec(this.spec, this.pb, this.sb);
}

/// Record personali (PB) e stagionali (SB, anno corrente) per specialità.
List<Rec> computeRecords(List<Result> results) {
  final names = results.map((r) => r.specialty).toSet().toList()..sort();
  final year = DateTime.now().year;
  final out = <Rec>[];
  for (final n in names) {
    final s = store.specialtyOf(n);
    Result pick(Iterable<Result> it) =>
        it.reduce((p, c) => better(c.value, p.value, s) ? c : p);
    final rs = results.where((r) => r.specialty == n).toList();
    final ys = rs.where((r) => r.data.year == year);
    out.add(Rec(s, pick(rs), ys.isEmpty ? null : pick(ys)));
  }
  return out;
}

DateTime _monday(DateTime d) {
  final u = DateTime.utc(d.year, d.month, d.day);
  return u.subtract(Duration(days: u.weekday - 1));
}

/// Carico = durata (min) x RPE, sommato per settimana (lunedì), ultime [weeks].
List<MapEntry<DateTime, int>> weeklyLoad(List<Session> sessions, {int weeks = 8}) {
  final first = _monday(DateTime.now()).subtract(Duration(days: 7 * (weeks - 1)));
  final loads = List<int>.filled(weeks, 0);
  for (final s in sessions) {
    final diff = _monday(s.data).difference(first).inDays;
    if (diff < 0) continue;
    final idx = diff ~/ 7;
    if (idx >= weeks) continue;
    loads[idx] += s.durata * s.rpe;
  }
  return [
    for (var i = 0; i < weeks; i++)
      MapEntry(first.add(Duration(days: 7 * i)), loads[i]),
  ];
}

// ---- Agenda
class AgendaItem {
  final DateTime data;
  final String titolo;
  final String tipo;
  final String? sub;
  final EventItem? event;
  final bool auto; // scadenze prese dal profilo
  AgendaItem(this.data, this.titolo, this.tipo, {this.sub, this.event, this.auto = false});
}

List<AgendaItem> agendaItems() {
  final items = <AgendaItem>[
    for (final e in store.events)
      AgendaItem(e.data, e.titolo, e.tipo,
          sub: [e.luogo, e.note].where((x) => x.isNotEmpty).join(' · '), event: e),
  ];
  final a = store.athlete;
  if (a?.scadenzaCertificato != null) {
    items.add(AgendaItem(a!.scadenzaCertificato!, 'Scadenza certificato medico', 'Scadenza',
        auto: true));
  }
  if (a?.scadenzaTessera != null) {
    items.add(AgendaItem(a!.scadenzaTessera!, 'Scadenza tessera', 'Scadenza', auto: true));
  }
  items.sort((x, y) => x.data.compareTo(y.data));
  return items;
}

int daysFrom(DateTime d) {
  final n = DateTime.now();
  return DateTime.utc(d.year, d.month, d.day)
      .difference(DateTime.utc(n.year, n.month, n.day))
      .inDays;
}

String whenLabel(int d) {
  if (d == 0) return 'oggi';
  if (d == 1) return 'domani';
  if (d == -1) return 'ieri';
  return d > 0 ? 'tra $d giorni' : '${-d} giorni fa';
}

// ---- Ciclo (stime indicative, non diagnostiche)
class CycleInfo {
  final int cycleLen;
  final DateTime? lastStart;
  final DateTime? nextStart;
  final DateTime? ovulation;
  final int? day;
  final String? phase;
  final bool late;
  CycleInfo(this.cycleLen, this.lastStart, this.nextStart, this.ovulation, this.day,
      this.phase, this.late);
}

CycleInfo computeCycle(Athlete a, List<CycleEntry> entries) {
  DateTime u(DateTime x) => DateTime.utc(x.year, x.month, x.day);
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
  final starts = entries.map((e) => u(e.start)).toList()..sort((x, y) => y.compareTo(x));
  var len = a.cicloMedio;
  if (starts.length >= 2) {
    final gaps = <int>[];
    for (var i = 0; i < starts.length - 1 && gaps.length < 6; i++) {
      final g = starts[i].difference(starts[i + 1]).inDays;
      if (g >= 15 && g <= 60) gaps.add(g);
    }
    if (gaps.isNotEmpty) len = (gaps.reduce((x, y) => x + y) / gaps.length).round();
  }
  final last = starts.isNotEmpty
      ? starts.first
      : (a.ultimoCiclo == null ? null : u(a.ultimoCiclo!));
  if (last == null) return CycleInfo(len, null, null, null, null, null, false);
  final day = today.difference(last).inDays + 1;
  final next = last.add(Duration(days: len));
  final ov = next.subtract(const Duration(days: 14));
  final ovDay = len - 14 + 1;
  final isLate = day > len + 7;
  String phase;
  if (day < 1) {
    phase = 'Data futura';
  } else if (isLate) {
    phase = 'Oltre la durata media';
  } else if (day <= a.durataMestruo) {
    phase = 'Mestruale';
  } else if (day < ovDay - 1) {
    phase = 'Follicolare';
  } else if (day <= ovDay + 1) {
    phase = 'Ovulatoria (stimata)';
  } else {
    phase = 'Luteale';
  }
  return CycleInfo(len, last, next, ov, day, phase, isLate);
}
