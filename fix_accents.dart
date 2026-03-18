import 'dart:io';
import 'dart:convert';
void main() {
  final dir = Directory('C:/Users/THEWAYNE/Documents/CAR225Mobile/lib/features/driver');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  final map = {
    'Ã©': 'é',
    'Ã¨': 'è',
    'Ã¢': 'â',
    'Ãª': 'ê',
    'Ã®': 'î',
    'Ã´': 'ô',
    'Ã»': 'û',
    'Ã§': 'ç',
    'Ã‰': 'É',
    'ÃŠ': 'Ê',
    'Ã ': 'à', // With space
    'Ã ': 'à', // With non-breaking space
    'Ã¯': 'ï',
  };
  
  for (final file in files) {
    var content = file.readAsStringSync(encoding: utf8);
    var old = content;
    for (final entry in map.entries) {
      if (entry.key == 'Ã ' || entry.key == 'Ã ') continue;
      content = content.replaceAll(entry.key, entry.value);
    }
    
    // Manual à replacements
    content = content.replaceAll('Ã ', 'à '); // Ensure following space
    content = content.replaceAll('Ã ', 'à'); // NBSP
    
    // Now any dangling Ã is very likely 'à' where the next character was not a space (like 'à l\'')
    content = content.replaceAll('Ã', 'à');
    
    if (content != old) {
      file.writeAsStringSync(content, encoding: utf8);
      print('Fixed \${file.path}');
    }
  }
}
