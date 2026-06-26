import 'package:csv/csv.dart';

void main() {
  const csv = 'a;b;c\n1;2;3';
  final result = const CsvDecoder(fieldDelimiter: ';').convert(csv);
  print(result);
}
