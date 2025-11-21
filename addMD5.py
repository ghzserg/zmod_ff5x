# (C) @AlexSamara763 https://t.me/AlexSamara763
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

    md5_hash = hashlib.md5(content).hexdigest().upper()

    md5_line = b'; MD5:' + md5_hash.encode('ascii') + b'\r\n'

    new_content = md5_line + content

    with open(file_path, 'wb') as f:
        f.write(new_content)

except Exception:
    sys.exit()
