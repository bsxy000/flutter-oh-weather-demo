import 'dart:convert';
import 'dart:io';

void main() {
  print('正在转换项目中的 Unicode 编码字符串...\n');

  // 需要处理的目录列表
  final directories = [
    'lib',
    'test',
  ];

  int totalFiles = 0;
  int modifiedFiles = 0;

  for (final dir in directories) {
    final directory = Directory(dir);
    if (!directory.existsSync()) {
      print('目录不存在: $dir');
      continue;
    }

    directory
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .forEach((file) {
      totalFiles++;
      if (convertFile(file)) {
        modifiedFiles++;
      }
    });
  }

  print('\n转换完成！');
  print('扫描文件数: $totalFiles');
  print('修改文件数: $modifiedFiles');
}

bool convertFile(File file) {
  final content = file.readAsStringSync();
  final converted = convertUnicode(content);

  if (content != converted) {
    file.writeAsStringSync(converted);
    print('已转换: ${file.path}');
    return true;
  }
  return false;
}

String convertUnicode(String input) {
  // 匹配 \uXXXX 或 \u{XXXXX} 格式
  final pattern = RegExp(r'\\u([0-9a-fA-F]{4})|\\u\{([0-9a-fA-F]+)\}');
  return input.replaceAllMapped(pattern, (match) {
    final hex = match.group(1) ?? match.group(2);
    if (hex != null) {
      final codePoint = int.parse(hex, radix: 16);
      return String.fromCharCode(codePoint);
    }
    return match.group(0)!;
  });
}
