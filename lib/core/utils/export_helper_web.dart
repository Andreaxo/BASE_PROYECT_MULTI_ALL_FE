import 'dart:html' as html;
import 'package:excel/excel.dart';

Future<void> exportToExcel({
  required List<String> headers,
  required List<List<String>> rows,
  required String filename,
}) async {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];

  // Append header row
  sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

  // Append data rows
  for (final row in rows) {
    sheet.appendRow(row.map((cell) => TextCellValue(cell)).toList());
  }

  final bytes = excel.save();
  if (bytes == null) return;

  final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', '$filename.xlsx')
    ..click();

  html.Url.revokeObjectUrl(url);
}

Future<void> exportToPdfAndPrint({
  required String title,
  required List<String> headers,
  required List<List<String>> rows,
}) async {
  final htmlBuffer = StringBuffer();
  htmlBuffer.write('''
    <!DOCTYPE html>
    <html>
    <head>
      <title>$title</title>
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 30px; color: #333; }
        h1 { text-align: center; color: #1e293b; margin-bottom: 25px; font-weight: 600; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        th, td { border: 1px solid #e2e8f0; padding: 12px 15px; text-align: left; font-size: 13px; }
        th { background-color: #f8fafc; color: #334155; font-weight: bold; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
        tr:nth-child(even) { background-color: #f8fafc; }
        tr:hover { background-color: #f1f5f9; }
        @media print {
          body { margin: 15px; }
          table { box-shadow: none; page-break-inside: auto; }
          tr { page-break-inside: avoid; page-break-after: auto; }
        }
      </style>
    </head>
    <body>
      <h1>$title</h1>
      <table>
        <thead>
          <tr>
            ${headers.map((h) => '<th>$h</th>').join('\n')}
          </tr>
        </thead>
        <tbody>
          ${rows.map((row) => '<tr>${row.map((cell) => '<td>$cell</td>').join('')}</tr>').join('\n')}
        </tbody>
      </table>
      <script>
        window.onload = function() {
          window.print();
        };
      </script>
    </body>
    </html>
  ''');

  final blob = html.Blob([htmlBuffer.toString()], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Open the printable HTML in a new tab
  html.window.open(url, '_blank');
}
