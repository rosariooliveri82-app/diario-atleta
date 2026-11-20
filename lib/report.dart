import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'categories.dart';
import 'models.dart';
import 'screens_goals.dart';
import 'stats.dart';
import 'store.dart';

/// Riepilogo PDF per l'allenatore. Il ciclo non viene mai incluso.
Future<Uint8List> buildReport({required bool includeWellness}) async {
  final doc = pw.Document();
  final a = store.athlete!;
  final now = DateTime.now();
  final recs = computeRecords(store.results);
  final results = [...store.results]..sort((x, y) => y.data.compareTo(x.data));
  final sessions = [...store.sessions]..sort((x, y) => y.data.compareTo(x.data));
  final red = PdfColor.fromInt(0xFFC8352B);

  pw.Widget h(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 4),
        child: pw.Text(t,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: red)),
      );

  pw.Widget table(List<String> headers, List<List<String>> rows) => rows.isEmpty
      ? pw.Text('-', style: const pw.TextStyle(fontSize: 9))
      : pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
        );

  String perf(Result r) => fmtPerf(r.value, store.specialtyOf(r.specialty).kind);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    footer: (c) => pw.Text(appCredits,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
    build: (c) => [
      pw.Text('Diario Atletica - Riepilogo',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: red)),
      pw.Text('Generato il ${fmtDate(now)}', style: const pw.TextStyle(fontSize: 9)),
      h('Atleta'),
      pw.Text(
          '${a.fullName} - ${categoriaFidal(a.nascita, a.sesso)}\n'
          'Nato/a il ${fmtDate(a.nascita)}'
          '${a.tessera.isEmpty ? '' : '\nTessera FIDAL: ${a.tessera}'}'
          '${store.club.nome.isEmpty ? '' : '\nSocieta: ${store.club.nome}'}',
          style: const pw.TextStyle(fontSize: 10)),
      if (store.club.contatti.isNotEmpty) ...[
        h('Numeri utili'),
        table(['Contatto', 'Numero'],
            [for (final k in store.club.contatti) [k.label, k.numero]]),
      ],
      h('Record personali (PB) e stagionali (SB)'),
      table(
        ['Specialita', 'PB', 'Data PB', 'SB ${now.year}'],
        [
          for (final r in recs)
            [
              r.spec.name,
              fmtPerf(r.pb.value, r.spec.kind),
              fmtDate(r.pb.data),
              r.sb == null ? '-' : fmtPerf(r.sb!.value, r.spec.kind),
            ]
        ],
      ),
      h('Ultimi risultati'),
      table(
        ['Data', 'Specialita', 'Prestazione', 'Luogo'],
        [
          for (final r in results.take(15))
            [fmtDate(r.data), r.specialty, perf(r), r.luogo]
        ],
      ),
      h('Obiettivi'),
      table(
        ['Specialita', 'Obiettivo', 'Attuale', 'Avanzamento'],
        [
          for (final g in store.goals)
            [
              g.specialty,
              fmtPerf(g.target, store.specialtyOf(g.specialty).kind),
              goalBest(g) == null
                  ? '-'
                  : fmtPerf(goalBest(g)!, store.specialtyOf(g.specialty).kind),
              '${(goalProgress(g) * 100).round()}%',
            ]
        ],
      ),
      h('Ultimi allenamenti'),
      table(
        ['Data', 'Tipo', 'Titolo', 'Min', 'RPE'],
        [
          for (final s in sessions.take(15))
            [fmtDate(s.data), s.tipo, s.titolo, '${s.durata}', '${s.rpe}']
        ],
      ),
      h('Carico settimanale (durata x RPE)'),
      table(
        ['Settimana dal', 'Carico'],
        [
          for (final w in weeklyLoad(store.sessions))
            [fmtDate(w.key), '${w.value}']
        ],
      ),
      h('Prossimi impegni'),
      table(
        ['Data', 'Tipo', 'Titolo'],
        [
          for (final i in agendaItems().where((i) => daysFrom(i.data) >= 0).take(10))
            [fmtDate(i.data), i.tipo, i.titolo]
        ],
      ),
      if (includeWellness) ...[
        h('Benessere (ultime registrazioni)'),
        table(
          ['Data', 'Peso kg', 'Sonno h', 'Dolore', 'Infortunio'],
          [
            for (final w in ([...store.wellness]..sort((x, y) => y.data.compareTo(x.data))).take(10))
              [
                fmtDate(w.data),
                w.peso?.toStringAsFixed(1) ?? '-',
                w.sonno?.toStringAsFixed(1) ?? '-',
                '${w.dolore}/10',
                w.infortunio,
              ]
          ],
        ),
      ],
    ],
  ));
  return doc.save();
}
