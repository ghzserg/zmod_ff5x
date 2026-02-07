# (C) 2025 @AlexSamara763 https://t.me/AlexSamara763
# (C) 2026 ninjamida https://github.com/ninjamida
#
# Use: "C:\python_folder\python.exe" "C:\Scripts\add_md5.py";
# Or: "/usr/bin/python3" "/home/user/add_md5.py";
import sys
import hashlib
import os

if len(sys.argv) < 2:
    sys.exit()

file_path = sys.argv[1]

try:
    with open(file_path, 'rb') as f:
        content = f.read()

    if content.startswith(b'; MD5:'):
        end_line_pos = content.index('\n')
        content = content[end_line_pos+1:]

    md5_hash = hashlib.md5(content).hexdigest()

    md5_line = b'; MD5:' + md5_hash.encode('ascii') + b'\r\n'

    new_content = md5_line + content

    with open(file_path, 'wb') as f:
        f.write(new_content)

except Exception:
    sys.exit()
