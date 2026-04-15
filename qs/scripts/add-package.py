#!/usr/bin/env python3
# add-package.py
# ~/manix/qs/scripts/add-package.py
#
# Kullanım: python3 add-package.py <packages.nix yolu> <paket-adı>
# Çıktılar (stdout):
#   already_installed  → paket zaten listede
#   added              → başarıyla eklendi
#   error: <mesaj>     → bir şeyler yanlış gitti

import sys
import os
import re
import shutil
from datetime import datetime

def main():
    if len(sys.argv) != 3:
        print("error: kullanım: add-package.py <packages.nix> <attr>")
        sys.exit(1)

    filepath = os.path.expanduser(sys.argv[1])
    package  = sys.argv[2].strip()

    # Temel doğrulama
    if not re.match(r'^[a-zA-Z0-9_\-\.]+$', package):
        print("error: geçersiz paket adı: " + package)
        sys.exit(1)

    if not os.path.isfile(filepath):
        print("error: dosya bulunamadı: " + filepath)
        sys.exit(1)

    with open(filepath, 'r') as f:
        content = f.read()

    # Zaten yüklü mü? (satır başında whitespace + paket adı + whitespace/yorum/satırsonu)
    if re.search(r'^\s+' + re.escape(package) + r'\s*(?:#.*)?$', content, re.MULTILINE):
        print("already_installed")
        return

    lines = content.splitlines(keepends=True)

    # home.packages bloğunu bul ve kapanan `];` satırını tespit et
    in_packages_block = False
    bracket_depth     = 0
    insert_before_idx = -1

    for i, line in enumerate(lines):
        stripped = line.strip()

        if not in_packages_block:
            # home.packages = with pkgs; [ veya home.packages = [
            if re.search(r'home\.packages\s*=', line):
                in_packages_block = True
                bracket_depth = line.count('[') - line.count(']')
                # Tek satırda açılıp kapandıysa (home.packages = [];) atla
                if bracket_depth <= 0:
                    in_packages_block = False
        else:
            bracket_depth += line.count('[') - line.count(']')
            if bracket_depth <= 0:
                insert_before_idx = i
                break

    if insert_before_idx == -1:
        print("error: packages.nix içinde home.packages listesi bulunamadı")
        sys.exit(1)

    # Girintisini bir önceki satırdan al
    prev_line = lines[insert_before_idx - 1] if insert_before_idx > 0 else "    "
    indent    = re.match(r'^(\s*)', prev_line).group(1)
    # En az 4 boşluk olsun
    if len(indent) < 4:
        indent = "    "

    new_line = indent + package + "\n"

    # Yedek al
    backup_path = filepath + ".bak"
    shutil.copy2(filepath, backup_path)

    # Ekle
    lines.insert(insert_before_idx, new_line)

    with open(filepath, 'w') as f:
        f.writelines(lines)

    print("added")

if __name__ == "__main__":
    main()
