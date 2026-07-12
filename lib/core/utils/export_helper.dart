import 'export_helper_stub.dart'
    if (dart.library.html) 'export_helper_web.dart'
    if (dart.library.io) 'export_helper_desktop.dart' as impl;

class ExportHelper {
  /// Exports headers and rows to a real .xlsx file (Microsoft Excel).
  /// Saves it to Downloads or triggers a web download.
  static Future<void> exportToExcel({
    required List<String> headers,
    required List<List<String>> rows,
    required String filename,
  }) {
    return impl.exportToExcel(
      headers: headers,
      rows: rows,
      filename: filename,
    );
  }

  /// Generates a clean printable HTML document, saving it/opening it in the browser
  /// to trigger the native Print dialog (which supports Print and Save to PDF).
  static Future<void> exportToPdfAndPrint({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return impl.exportToPdfAndPrint(
      title: title,
      headers: headers,
      rows: rows,
    );
  }
}
