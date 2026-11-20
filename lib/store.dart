import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'models_extra.dart';

const appVersion = '0.1';
const appCredits = '2026 Designed & Developed by Rosario OLIVERI Vers. $appVersion';

/// Salvataggio unico per Android e Web (shared_preferences):
/// dati in JSON, foto come base64. Nessun accesso diretto ai file.
class Store extends ChangeNotifier {
  late SharedPreferences _p;

  Athlete? athlete; // un solo profilo
  DateTime? lastBackup;
  List<Result> results = [];
  List<Session> sessions = [];
  Club club = Club();
  List<Specialty> customSpecialties = [];
  List<String> customTypes = [];
  List<Goal> goals = [];
  List<EventItem> events = [];
  List<Wellness> wellness = [];
  List<CycleEntry> cycles = [];
  final Map<String, Uint8List> _images = {};

  List<Specialty> get specialties => [...defaultSpecialties, ...customSpecialties];
  List<String> get trainingTypes => [...defaultTrainingTypes, ...customTypes];

  Specialty specialtyOf(String name) => specialties.firstWhere(
        (s) => s.name == name,
        orElse: () => Specialty(name, Kind.dist),
      );

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final lb = _p.getString('lastBackup');
    lastBackup = lb == null ? null : DateTime.tryParse(lb);
    final raw = _p.getString('data');
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw));
      } catch (e) {
        debugPrint('Errore lettura dati: $e');
      }
    }
    for (final k in _p.getKeys().where((k) => k.startsWith('img_'))) {
      try {
        _images[k.substring(4)] = base64Decode(_p.getString(k)!);
      } catch (_) {}
    }
    notifyListeners();
  }

  Map<String, dynamic> _toJson() => {
        'version': appVersion,
        'athlete': athlete?.toJson(),
        'results': results.map((r) => r.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'club': club.toJson(),
        'customSpecialties': customSpecialties.map((s) => s.toJson()).toList(),
        'customTypes': customTypes,
        'goals': goals.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'wellness': wellness.map((e) => e.toJson()).toList(),
        'cycles': cycles.map((e) => e.toJson()).toList(),
      };

  List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) f) =>
      ((raw ?? []) as List).map((e) => f(Map<String, dynamic>.from(e))).toList();

  void _fromJson(Map<String, dynamic> j) {
    athlete = j['athlete'] == null
        ? null
        : Athlete.fromJson(Map<String, dynamic>.from(j['athlete']));
    results = _list(j['results'], Result.fromJson);
    sessions = _list(j['sessions'], Session.fromJson);
    club = j['club'] == null
        ? Club()
        : Club.fromJson(Map<String, dynamic>.from(j['club']));
    customSpecialties = _list(j['customSpecialties'], Specialty.fromJson);
    customTypes = List<String>.from(j['customTypes'] ?? []);
    goals = _list(j['goals'], Goal.fromJson);
    events = _list(j['events'], EventItem.fromJson);
    wellness = _list(j['wellness'], Wellness.fromJson);
    cycles = _list(j['cycles'], CycleEntry.fromJson);
  }

  Future<void> save() async {
    await _p.setString('data', jsonEncode(_toJson()));
    notifyListeners();
  }

  // ---- Profilo
  Future<void> setAthlete(Athlete a) async {
    athlete = a;
    if (a.sesso == 'F' && a.ultimoCiclo != null && cycles.isEmpty) {
      cycles.add(CycleEntry(id: newId(), start: a.ultimoCiclo!, giorni: a.durataMestruo));
    }
    await _gcImages();
    await save();
  }

  Future<void> _gcImages() async {
    final used = {athlete?.fotoFidal, athlete?.fotoSocieta};
    for (final n in _images.keys.toList()) {
      if (!used.contains(n)) {
        _images.remove(n);
        await _p.remove('img_$n');
      }
    }
  }

  // ---- Gare
  Future<void> upsertResult(Result r) async {
    final i = results.indexWhere((x) => x.id == r.id);
    if (i >= 0) {
      results[i] = r;
    } else {
      results.add(r);
    }
    await save();
  }

  Future<void> deleteResult(String id) async {
    results.removeWhere((r) => r.id == id);
    await save();
  }

  // ---- Allenamenti
  Future<void> upsertSession(Session s) async {
    final i = sessions.indexWhere((x) => x.id == s.id);
    if (i >= 0) {
      sessions[i] = s;
    } else {
      sessions.add(s);
    }
    await save();
  }

  Future<void> deleteSession(String id) async {
    sessions.removeWhere((s) => s.id == id);
    await save();
  }

  Future<void> addSpecialty(Specialty s) async {
    if (specialties.any((x) => x.name.toLowerCase() == s.name.toLowerCase())) return;
    customSpecialties.add(s);
    await save();
  }

  Future<void> addTrainingType(String t) async {
    if (trainingTypes.any((x) => x.toLowerCase() == t.toLowerCase())) return;
    customTypes.add(t);
    await save();
  }

  Future<void> setClub(Club c) async {
    club = c;
    await save();
  }

  // ---- Liste generiche (obiettivi, agenda, benessere, ciclo)
  Future<void> put<T>(List<T> list, T item, String Function(T) id) async {
    final i = list.indexWhere((x) => id(x) == id(item));
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
    await save();
  }

  Future<void> remove<T>(List<T> list, String itemId, String Function(T) id) async {
    list.removeWhere((x) => id(x) == itemId);
    await save();
  }

  Future<void> markBackup() async {
    lastBackup = DateTime.now();
    await _p.setString('lastBackup', lastBackup!.toIso8601String());
    notifyListeners();
  }

  // ---- Immagini
  Uint8List? imageBytes(String? name) => name == null ? null : _images[name];

  Future<String> importImage(XFile x) async {
    final bytes = await x.readAsBytes();
    final name = newId();
    _images[name] = bytes;
    await _p.setString('img_$name', base64Encode(bytes));
    return name;
  }

  // ---- Export / Import
  String backupName() {
    final n = DateTime.now();
    return 'diario_atletica_${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}';
  }

  Uint8List exportZipBytes() {
    final a = Archive();
    final data = utf8.encode(jsonEncode(_toJson()));
    a.addFile(ArchiveFile('data.json', data.length, data));
    _images.forEach((name, bytes) {
      a.addFile(ArchiveFile('images/$name', bytes.length, bytes));
    });
    return Uint8List.fromList(ZipEncoder().encode(a)!);
  }

  /// replace = true: sostituisce tutto. false: unisce per id (l'importato vince).
  Future<void> importZipBytes(Uint8List zip, {required bool replace}) async {
    final archive = ZipDecoder().decodeBytes(zip);
    Map<String, dynamic>? json;
    final imgs = <String, Uint8List>{};
    for (final f in archive) {
      if (!f.isFile) continue;
      final bytes = Uint8List.fromList(f.content as List<int>);
      if (f.name == 'data.json') {
        json = jsonDecode(utf8.decode(bytes));
      } else if (f.name.startsWith('images/')) {
        final name = f.name.substring('images/'.length);
        if (name.isNotEmpty && !name.contains('/') && !name.contains('..')) {
          imgs[name] = bytes;
        }
      }
    }
    if (json == null) throw Exception('File non valido: data.json mancante');

    if (replace) {
      for (final n in _images.keys.toList()) {
        await _p.remove('img_$n');
      }
      _images.clear();
      _fromJson(json);
    } else {
      final other = Store();
      other._fromJson(json);
      athlete ??= other.athlete;
      results = _merge(results, other.results, (r) => r.id);
      sessions = _merge(sessions, other.sessions, (s) => s.id);
      goals = _merge(goals, other.goals, (x) => x.id);
      events = _merge(events, other.events, (x) => x.id);
      wellness = _merge(wellness, other.wellness, (x) => x.id);
      cycles = _merge(cycles, other.cycles, (x) => x.id);
      for (final s in other.customSpecialties) {
        if (!specialties.any((x) => x.name == s.name)) customSpecialties.add(s);
      }
      for (final t in other.customTypes) {
        if (!trainingTypes.contains(t)) customTypes.add(t);
      }
      if (club.nome.isEmpty) club = other.club;
    }
    for (final e in imgs.entries) {
      _images[e.key] = e.value;
      await _p.setString('img_${e.key}', base64Encode(e.value));
    }
    await save();
  }

  List<T> _merge<T>(List<T> mine, List<T> theirs, String Function(T) id) {
    final map = {for (final x in mine) id(x): x};
    for (final x in theirs) {
      map[id(x)] = x;
    }
    return map.values.toList();
  }
}

final store = Store();
