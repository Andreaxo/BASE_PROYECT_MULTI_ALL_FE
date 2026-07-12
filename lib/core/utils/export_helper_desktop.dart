import 'dart:convert';
import 'dart:io';
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

  // Find standard Downloads directory on desktop platforms
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
  final downloadsDir = Directory('$home/Downloads');
  String savePath = '$home/$filename.xlsx';

  if (await downloadsDir.exists()) {
    savePath = '${downloadsDir.path}/$filename.xlsx';
  }

  final file = File(savePath);
  await file.writeAsBytes(bytes);
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
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { border: 1px solid #e2e8f0; padding: 12px 15px; text-align: left; font-size: 13px; }
        th { background-color: #f8fafc; color: #334155; font-weight: bold; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
        tr:nth-child(even) { background-color: #f8fafc; }
        tr:hover { background-color: #f1f5f9; }
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
    </body>
    </html>
  ''');

  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
  final tempFile = File('$home/Downloads/$title-print.html');
  await tempFile.writeAsString(htmlBuffer.toString(), encoding: utf8);

  // Open the printable HTML file in default desktop browser so user can Print/Save to PDF using standard browser print dialog
  if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', tempFile.path]);
  } else if (Platform.isMacOS) {
    await Process.run('open', [tempFile.path]);
  } else {
    await Process.run('xdg-open', [tempFile.path]);
  }
}
