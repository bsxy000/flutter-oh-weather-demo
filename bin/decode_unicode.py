#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Unicode 编码转换工具
将文件中的 Unicode 转义序列（如 \u6b63\u5728）转换为实际的中文字符
"""

import os
import re
import sys


def convert_unicode(text):
    """将 Unicode 转义序列转换为实际字符"""
    # 匹配 \uXXXX 格式
    pattern = r'\\u([0-9a-fA-F]{4})'

    def replace_match(match):
        hex_code = match.group(1)
        return chr(int(hex_code, 16))

    return re.sub(pattern, replace_match, text)


def convert_file(file_path):
    """转换单个文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        converted = convert_unicode(content)

        if content != converted:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(converted)
            return True
        return False
    except Exception as e:
        print(f'错误处理文件 {file_path}: {e}')
        return False


def main():
    """主函数"""
    print('正在转换项目中的 Unicode 编码字符串...\n')

    # 需要处理的目录列表
    directories = ['lib', 'test']

    total_files = 0
    modified_files = 0

    for dir_name in directories:
        if not os.path.exists(dir_name):
            print(f'目录不存在: {dir_name}')
            continue

        for root, dirs, files in os.walk(dir_name):
            for file in files:
                if file.endswith('.dart'):
                    file_path = os.path.join(root, file)
                    total_files += 1
                    if convert_file(file_path):
                        modified_files += 1
                        print(f'已转换: {file_path}')

    print(f'\n转换完成！')
    print(f'扫描文件数: {total_files}')
    print(f'修改文件数: {modified_files}')


if __name__ == '__main__':
    main()
