import 'dart:io';

void main() {
  var dir = Directory('lib');
  var files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  int errors = 0;
  
  for (var file in files) {
    var lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (line.startsWith('import ') || line.startsWith('export ')) {
        var match = RegExp(r"['""]([^'""]+)['""]").firstMatch(line);
        if (match != null) {
          var uri = match.group(1)!;
          if (!uri.startsWith('package:') && !uri.startsWith('dart:')) {
            // Relative path
            var baseDir = file.parent;
            var targetFile = File(baseDir.path + Platform.pathSeparator + uri).resolveSymbolicLinksSync();
            
            // Check exact casing by reading parent directory
            var targetName = uri.split('/').last;
            var targetParentDir = Directory(baseDir.path + Platform.pathSeparator + uri).parent;
            
            if (targetParentDir.existsSync()) {
              var actualFiles = targetParentDir.listSync().map((f) => f.uri.pathSegments.last).toList();
              if (!actualFiles.contains(targetName)) {
                print("CASE MISMATCH in ${file.path}:${i+1}: $line (Expected exactly '$targetName' but it's not found in $actualFiles)");
                errors++;
              }
            } else {
              print("MISSING DIRECTORY in ${file.path}:${i+1}: $line");
              errors++;
            }
          } else if (uri.startsWith('package:edutrack/')) {
            // Absolute package path
            var path = uri.substring('package:edutrack/'.length);
            var targetFile = File('lib' + Platform.pathSeparator + path);
            var targetName = path.split('/').last;
            var targetParentDir = targetFile.parent;
            if (targetParentDir.existsSync()) {
              var actualFiles = targetParentDir.listSync().map((f) => f.uri.pathSegments.last).toList();
              if (!actualFiles.contains(targetName)) {
                print("CASE MISMATCH in ${file.path}:${i+1}: $line (Expected exactly '$targetName' but it's not found in $actualFiles)");
                errors++;
              }
            } else {
              print("MISSING DIRECTORY in ${file.path}:${i+1}: $line");
              errors++;
            }
          }
        }
      }
    }
  }
  if (errors == 0) {
    print("ALL IMPORTS CASE-CORRECT.");
  }
}
