#/bin/sh

echo "#!/bin/sh

check_dir()
{
    a=\$(stat -c '%a' \"\$1\" 2>/dev/null)
    if [ \"\$a\" != \"\$2\" ]; then
        echo -n \"\$1 - Ошибочные права (\$a!=\$2): \"
        mkdir -p \"\$1\" && chmod \"\$2\" \"\$1\" 2>/dev/null && echo \"Исправлено\" || echo \"Ошибка исправления\"
    fi
}

check_link()
{
    a=\$(readlink \"\$1\" 2>/dev/null)
    if [ \"\$a\" != \"\$2\" ]; then
        echo -n \"\$1 - Ошибочная ссылка (\$a!=\$2): \"
        rm -f \"\$1\" 2>/dev/null
        ln -s \"\$2\" \"\$1\" 2>/dev/null && echo \"Исправлено\"  || echo \"Ошибка исправления\"
    fi
}

check_file()
{
    a=\$(stat -c '%a' \"\$1\" 2>/dev/null)
    if [ \"\$a\" != \"\$2\" ]; then
        echo -n \"\$1 - Ошибочные права (\$a!=\$2): \"
        chmod \"\$2\" \"\$1\" 2>/dev/null && echo \"Исправлено\" || echo \"Ошибка исправления\"
    fi
}

" >list.link

echo "echo 'Проверяю права на каталоги...'">>list.link
find .  \
    -type d \
    -and -not -name "md5sum.list" \
    -and -not -name "md5.sh" \
    -and -not -name "link.sh" \
    -and -not -name "list.link" \
    -and -not -name "ts.conf" \
    -and -not -name "os-release" \
    -and -not -path "./tmp" \
    -and -not -path "./proc" \
    -and -not -path "./root" \
    -and -not -path "./sys" \
    -and -not -path "./dev/*" \
    -and -not -path "./etc/timezone" \
    -and -not -path "./etc/localtime" \
    -exec ./link.sh {} "dir" \; >>list.link

echo "echo 'Проверка символических ссылок...'" >>list.link
chmod +x list.link
find .  \
    -type l \
    -and -not -name "md5sum.list" \
    -and -not -name "md5.sh" \
    -and -not -name "link.sh" \
    -and -not -name "list.link" \
    -and -not -name "ts.conf" \
    -and -not -name "os-release" \
    -and -not -path "./tmp" \
    -and -not -path "./proc" \
    -and -not -path "./root" \
    -and -not -path "./sys" \
    -and -not -path "./dev/*" \
    -and -not -path "./etc/timezone" \
    -and -not -path "./etc/localtime" \
    -exec ./link.sh {} link \; >>list.link

echo "echo 'Проверяю права на файлы...'">>list.link
find .  \
    -type f \
    -and -not -name "md5sum.list" \
    -and -not -name "md5.sh" \
    -and -not -name "link.sh" \
    -and -not -name "list.link" \
    -and -not -name "ts.conf" \
    -and -not -name "os-release" \
    -and -not -path "./tmp" \
    -and -not -path "./proc" \
    -and -not -path "./root" \
    -and -not -path "./sys" \
    -and -not -path "./dev/*" \
    -and -not -path "./etc/timezone" \
    -and -not -path "./etc/localtime" \
    -exec ./link.sh {} "file" \; >>list.link

find .  \
    -type f \
    -and -not -name "md5sum.list" \
    -and -not -name "md5.sh" \
    -and -not -name "link.sh" \
    -and -not -name "list.link" \
    -and -not -name "ts.conf" \
    -and -not -name "os-release" \
    -and -not -path "./tmp" \
    -and -not -path "./proc" \
    -and -not -path "./root" \
    -and -not -path "./sys" \
    -and -not -path "./dev/*" \
    -and -not -path "./etc/timezone" \
    -and -not -path "./etc/localtime" \
    -exec md5sum {} \; >md5sum.list
