Future<void> exportToExcel({
  required List<String> headers,
  required List<List<String>> rows,
  required String filename,
}) async {
  throw UnimplementedError('Platform not supported');
}

Future<void> exportToPdfAndPrint({
  required String title,
  required List<String> headers,
  required List<List<String>> rows,
}) async {
  throw UnimplementedError('Platform not supported');
}
