#!/usr/bin/env python3
import sys, re, math

# ---------------------- Funciones auxiliares ----------------------
def compute_bbox_from_block(block):
    re_cmd = re.compile(r'^(?P<cmd>G[0-9]+)\b', re.IGNORECASE)
    re_xy = re.compile(r'([XY])\s*([-+]?\d*\.?\d+)')
    re_ij = re.compile(r'([IJ])\s*([-+]?\d*\.?\d+)')

    cur_x = None
    cur_y = None

    xmin = float('inf')
    xmax = -float('inf')
    ymin = float('inf')
    ymax = -float('inf')

    def update_bbox(x, y):
        nonlocal xmin, xmax, ymin, ymax
        xmin = min(xmin, x)
        xmax = max(xmax, x)
        ymin = min(ymin, y)
        ymax = max(ymax, y)

    def angle_in_sweep(theta, start, end, ccw=True):
        def norm(a):
            return a % (2*math.pi)
        s = norm(start); e = norm(end); t = norm(theta)
        if ccw:
            if e >= s:
                return s <= t <= e
            else:
                return t >= s or t <= e
        else:
            if e <= s:
                return e <= t <= s
            else:
                return not (s < t < e)

    for line in block.splitlines():
        line = line.strip()
        if not line or line.startswith(';'):
            continue
        m_cmd = re_cmd.match(line)
        cmd = m_cmd.group('cmd').upper() if m_cmd else None
        coords = {k: float(v) for k,v in re_xy.findall(line)}
        ij = {k: float(v) for k,v in re_ij.findall(line)}

        if cmd in ('G0', 'G1') or cmd is None:
            # Determinar las nuevas coordenadas
            nx = coords.get('X', cur_x)
            ny = coords.get('Y', cur_y)

            # Inicializar si es la primera vez
            if nx is None or ny is None:
                continue
            if cur_x is None or cur_y is None:
                cur_x, cur_y = nx, ny
                update_bbox(cur_x, cur_y)
                continue

            update_bbox(cur_x, cur_y)
            update_bbox(nx, ny)
            cur_x, cur_y = nx, ny

        elif cmd in ('G2', 'G3'):
            if cur_x is None or cur_y is None:
                continue
            if 'X' not in coords or 'Y' not in coords:
                continue
            nx = coords['X']; ny = coords['Y']
            I = ij.get('I', 0.0); J = ij.get('J', 0.0)
            cx = cur_x + I; cy = cur_y + J
            r = math.hypot(cur_x - cx, cur_y - cy)
            start_ang = math.atan2(cur_y - cy, cur_x - cx)
            end_ang = math.atan2(ny - cy, nx - cx)
            ccw = (cmd == 'G3')
            update_bbox(cur_x, cur_y)
            update_bbox(nx, ny)
            for test_ang in [0, math.pi/2, math.pi, 3*math.pi/2]:
                if angle_in_sweep(test_ang, start_ang, end_ang, ccw=ccw):
                    tx = cx + r * math.cos(test_ang)
                    ty = cy + r * math.sin(test_ang)
                    update_bbox(tx, ty)
            cur_x, cur_y = nx, ny

    if xmin == float('inf'):
        return None
    return xmin, ymin, xmax, ymax


def extract_wipe_block_from_file(path):
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        text = f.read()
    start = text.find('; WIPE_TOWER_START')
    end = text.find('; WIPE_TOWER_END', start if start!=-1 else 0)
    if start == -1 or end == -1:
        return None
    block = text[start:end+len('; WIPE_TOWER_END')]
    return block


# ---------------------- Código principal ----------------------
if len(sys.argv) < 2:
    print("Uso: python3 add_wipe_tower.py <archivo.gcode>")
    sys.exit()

file_path = sys.argv[1]
wipe_block = extract_wipe_block_from_file(file_path)
if not wipe_block:
    print("No se encontró el bloque WIPE_TOWER en el G-code.")
    sys.exit(0)

bbox = compute_bbox_from_block(wipe_block)
if not bbox:
    print("No se encontraron coordenadas dentro del bloque WIPE_TOWER.")
    sys.exit(0)

xmin, ymin, xmax, ymax = bbox
center_x = (xmin + xmax) / 2
center_y = (ymin + ymax) / 2
polygon = f"[[{xmin:.6f},{ymin:.6f}],[{xmax:.6f},{ymin:.6f}],[{xmax:.6f},{ymax:.6f}],[{xmin:.6f},{ymax:.6f}]]"
wipe_line = f"EXCLUDE_OBJECT_DEFINE NAME=Wipe_Tower CENTER={center_x:.6f},{center_y:.6f} POLYGON={polygon}\n"

# Leer G-code existente
with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

# Comprobar si ya existe la línea de la torre
exists = any("EXCLUDE_OBJECT_DEFINE NAME=Wipe_Tower" in line for line in lines)
if not exists:
    # Insertar después de la última línea EXCLUDE_OBJECT_DEFINE si existe
    insert_index = None
    for i, line in enumerate(lines):
        if line.startswith("EXCLUDE_OBJECT_DEFINE"):
            insert_index = i  # actualizamos para que quede al final

    if insert_index is not None:
        lines.insert(insert_index + 1, wipe_line)  # solo una vez
    else:
        lines.append(wipe_line)  # si no hay ninguna, añadir al final

# Guardar el G-code modificado
with open(file_path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print(f"[OK] Añadida definición EXCLUDE_OBJECT_DEFINE de la torre de purga a {file_path}")
print(f"  Xmin={xmin:.6f}, Ymin={ymin:.6f}, Xmax={xmax:.6f}, Ymax={ymax:.6f}")
