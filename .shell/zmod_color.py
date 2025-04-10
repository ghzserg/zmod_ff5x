import json
import requests
import subprocess

COLOR_MAPPING = {
    "ffffff": {"ru": "белый", "en": "white"},
    "fef043": {"ru": "ярко-желтый", "en": "bright yellow"},
    "dcf478": {"ru": "светло-зеленый", "en": "light green"},
    "0acc38": {"ru": "зеленый", "en": "green"},
    "067749": {"ru": "темно-зеленый", "en": "dark green"},
    "0c6283": {"ru": "сине-зеленый", "en": "cyan"},
    "0de2a0": {"ru": "бирюзовый", "en": "turquoise"},
    "75d9f3": {"ru": "голубой", "en": "light blue"},
    "45a8f9": {"ru": "синий", "en": "blue"},
    "2750e0": {"ru": "темно-синий", "en": "dark blue"},
    "46328e": {"ru": "фиолетовый", "en": "purple"},
    "a03cf7": {"ru": "ярко-фиолетовый", "en": "bright purple"},
    "f330f9": {"ru": "пурпурный", "en": "magenta"},
    "d4b0dc": {"ru": "сиреневый", "en": "lilac"},
    "f95d73": {"ru": "розовый", "en": "pink"},
    "f72224": {"ru": "красный", "en": "red"},
    "7c4b00": {"ru": "коричневый", "en": "brown"},
    "f98d33": {"ru": "оранжевый", "en": "orange"},
    "fdebd5": {"ru": "бежевый", "en": "beige"},
    "d3c4a3": {"ru": "светло-коричневый", "en": "light brown"},
    "af7836": {"ru": "терракотовый", "en": "terracotta"},
    "898989": {"ru": "серый", "en": "gray"},
    "bcbcbc": {"ru": "светло-серый", "en": "light gray"},
    "161616": {"ru": "черный", "en": "black"}
}

TRANSLATIONS = {
    'ru': {
        'cancel': "Отмена",
        'change_color': "Сменить цвет",
        'change_spool': "Меняю на катушку {}: {} / {}",
        'change_type': "Сменить тип",
        'config_error': "!! Ошибка смены цвета / типа\n{}",
        'config_success': "Настройки сохранены",
        'error_color_or_type': "Укажите HEX или TYPE",
        'error_leveling': "Неверный LEVELING: {}. Допустимо: 0 или 1",
        'error_napr': "Недопустимое направление (0-1)",
        'error_no_filename': "Не указано имя файла (FILENAME).",
        'error_slot': "Неверный SLOT. Допустимые: 1-4",
        'error_tool': "Неверный TOOL{}: {}. Допустимо: 1-4",
        'error_type': "Неверный тип материала: {}. Допустимо: {}",
        'file_tool': "В файле",
        'load_error': "!! Ошибка загрузки / выгружки\n{}",
        'load_success': "Загрузка началась",
        'load': "Загрузить",
        'no_response': "!! Нет ответа от принтера. Настройте принтер: \"Настройки\" -> \"WiFi\" -> \"Сетевой режим\" -> \"Только локальные сети\"\n{}",
        'printing_error': "!! Ошибка печати файла\n{}",
        'prompt_choose': "Выберите катушку для изменения",
        'prompt_file': "Файл для печати: {}",
        'prompt_leveling_off': "Печать без карты стола",
        'prompt_leveling_on': "Печать с картой стола",
        'prompt_map_color': "Сопоставьте цвет из файла с катушкой",
        'prompt_material': "Загруженный материал",
        'reset_colors': "Сбросить цвета",
        'select_action': "Выберите действие",
        'select_color': "Выберите цвет",
        'select_type': "Выберите тип материала",
        'send_print': "Отправить на печать",
        'spool_info': "Катушка {}: {}/{}",
        'spool': "в катушке",
        'unload_error': "Ошибка выгрузки: {}",
        'unload_success': "Выгрузка начата",
        'unload': "Выгрузить"
    },
    'en': {
        'cancel': "Cancel",
        'change_color': "Change color",
        'change_spool': "Changing to spool {}: {}/{}",
        'change_type': "Change type",
        'config_error': "!! Error changing color/type\n{}",
        'config_success': "Settings saved",
        'error_color_or_type': "Specify HEX or TYPE",
        'error_leveling': "Invalid LEVELING: {}. Valid: 0 or 1",
        'error_napr': "Invalid direction (0-1)",
        'error_no_filename': "Missing FILENAME parameter",
        'error_slot': "Invalid SLOT. Valid: 1-4",
        'error_tool': "Invalid TOOL{}: {}. Valid: 1-4",
        'error_type': "Invalid material type: {}. Valid: {}",
        'file_tool': "In file",
        'load_error': "!! Load/unload error\n{}",
        'load_success': "Loading started",
        'load': "Load",
        'no_response': "!! No response from printer. Configure via: \"Settings\" -> \"WiFi\" -> \"Network Mode\" -> \"Local Only\"\n{}",
        'printing_error': "!! File printing error\n{}",
        'prompt_choose': "Select a spool to modify",
        'prompt_file': "File to print: {}",
        'prompt_leveling_off': "Print without bed leveling",
        'prompt_leveling_on': "Print with bed leveling",
        'prompt_map_color': "Map file color to spool",
        'prompt_material': "Loaded material",
        'reset_colors': "Reset colors",
        'select_action': "Select action",
        'select_color': "Select color",
        'select_type': "Select material type",
        'send_print': "Start print",
        'spool_info': "Spool {}: {}/{}",
        'spool': "in spool",
        'unload_error': "Unloading error: {}",
        'unload_success': "Unloading started",
        'unload': "Unload"
    }
}

class zmod_color:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.zmod = self.printer.lookup_object('zmod', None)
        self.language = 'ru'
        if self.zmod is not None:
            self.language = self.zmod.get_lang()
        self.gcode = self.printer.lookup_object('gcode')
        self.gcode.register_command('GET_T', self.cmd_GET_T)
        self.gcode.register_command('GET_ZCOLOR', self.cmd_GET_ZCOLOR)
        self.gcode.register_command('SET_ZCOLOR', self.cmd_SET_ZCOLOR)
        self.gcode.register_command('PRINT_ZCOLOR', self.cmd_PRINT_ZCOLOR)
        self.gcode.register_command('CHANGE_TOOL_ZCOLOR', self.cmd_CHANGE_TOOL_ZCOLOR)
        self.gcode.register_command('RUN_ZCOLOR', self.cmd_RUN_ZCOLOR)
        self.gcode.register_command('CHANGE_ZCOLOR', self.cmd_CHANGE_ZCOLOR)
        self.gcode.register_command('IN_ZCOLOR', self.cmd_IN_ZCOLOR)
        with open('/usr/data/config/Adventurer5M.json', 'r') as file:
            data = json.load(file)
            self.serialNumber = data['general']['printerSerialNumber']
            self.checkCode = data['general']['lanCode']

    def get_printer_ip(self):
        interfaces = ['wlan0', 'eth0']
        for iface in interfaces:
            try:
                result = subprocess.run(
                    ['ip', '-br', 'addr', 'show', iface],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    return result.stdout.split()[2].split('/')[0]
            except:
                pass
        return "Not found"

    def zsend_post_request(self, api, payload=None, send_data=None):
        base_ip = self.get_printer_ip()
        url = f"http://{base_ip}:8898{api}"
        headers = {
            "Accept": "*/*",
            "Content-Type": "application/json"
        }
        if send_data is not None:
            data = send_data
        else:
            data = {}

        data["serialNumber"] = self.serialNumber
        data["checkCode"] = self.checkCode

        if payload is not None:
            data["payload"] = payload

        try:
            response = requests.post(
                url,
                json=data,
                headers=headers,
                timeout=60
            )
            return response.status_code, response.json()
        except requests.exceptions.RequestException as e:
            return None, str(e)

    def _t(self, key, *args):
        return TRANSLATIONS[self.language][key].format(*args)

    def parse_printer_response(self, response_data):
        slots_info = []
        slots = response_data.get('detail', {}).get('matlStationInfo', {}).get('slotInfos', [])
        for slot in slots:
            if slot.get('hasFilament', True):
                slot_id = slot.get('slotId', 'N/A')
                material = slot.get('materialName', 'N/A').upper()
                hex_color = slot.get('materialColor', '161616').replace("#", "")
                color_name = COLOR_MAPPING.get(hex_color.lower(), {}).get(self.language, hex_color)
                slots_info.append({
                    'ID': slot_id,
                    'Material': material,
                    'Color': color_name,
                    'HEX': hex_color.upper()
                })
        return slots_info

    def cmd_GET_T(self, gcmd):
        zslot = gcmd.get_int('SLOT', 0)
        if zslot < 1 or zslot > 4:
            raise gcmd.error(self._t('error_slot'))
        status_code, response_data = self.zsend_post_request("/detail")
        if status_code:
            result = self.parse_printer_response(response_data)
            for slot in result:
                if zslot == int(slot['ID']):
                    msg = self._t('change_spool', slot['ID'], slot['Material'], slot['Color'])
                    gcmd.respond_raw(msg)
        else:
            gcmd.respond_raw(self._t('no_response', response_data))

    def cmd_GET_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        status_code, response_data = self.zsend_post_request("/detail")
        if status_code:
            gcmd.respond_raw(f"// action:prompt_begin {self._t('prompt_material')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('prompt_choose')}")
            gcmd.respond_raw("// action:prompt_button_group_start")
            result = self.parse_printer_response(response_data)
            for slot in result:
                btn_text = f"{slot['ID']}: {slot['Material']}/{slot['Color']}"
                gcmd.respond_raw(f"// action:prompt_button {btn_text}|RUN_ZCOLOR SLOT={slot['ID']} HEX={slot['HEX']} TYPE={slot['Material']}|primary")
            gcmd.respond_raw("// action:prompt_button_group_end")
            gcmd.respond_raw(f"// action:prompt_footer_button {self._t('cancel')}|RESPOND TYPE=command MSG=action:prompt_end")
            gcmd.respond_raw(f"// action:prompt_footer_button {self._t('reset_colors')}|RESET_ZCOLOR")
            gcmd.respond_raw("// action:prompt_show")
        else:
            gcmd.respond_raw(self._t('no_response', response_data))

    def cmd_SET_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        fname = gcmd.get('FILENAME', '')
        if fname == '':
            raise gcmd.error(self._t('error_no_filename'))

        leveling = gcmd.get_int('LEVELING', 0)
        if leveling not in (0, 1):
            raise gcmd.error(self._t('error_leveling', leveling))

        tools = [
            gcmd.get_int('TOOL0', 1),
            gcmd.get_int('TOOL1', 2),
            gcmd.get_int('TOOL2', 3),
            gcmd.get_int('TOOL3', 4)
        ]

        for i, tool in enumerate(tools):
            if tool < 1 or tool > 4:
                raise gcmd.error(self._t('error_tool', i, tool))

        status_code, response_data = self.zsend_post_request("/detail")
        if status_code:
            result = self.parse_printer_response(response_data)

            gcmd.respond_raw(f"// action:prompt_begin {self._t('prompt_material')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('prompt_map_color')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('prompt_file', fname)}")

            leveling_text = (
                self._t('prompt_leveling_on')
                if leveling
                else self._t('prompt_leveling_off')
            )
            gcmd.respond_raw(f"// action:prompt_text {leveling_text}")

            gcmd.respond_raw("// action:prompt_button_group_start")
            for tool_idx, tool_val in enumerate(tools):
                if 0 <= (tool_val - 1) < len(result):
                    slot_info = result[tool_val - 1]
                    btn_text = (
                        f"{self._t('file_tool')} {tool_idx+1} → "
                        f"{self._t('spool')} {slot_info['ID']}: "
                        f"{slot_info['Material']}/{slot_info['Color']}"
                    )
                    params = (
                        f"LEVELING={leveling} FILENAME=\"{fname}\" "
                        f"TOOL0={tools[0]} TOOL1={tools[1]} "
                            f"TOOL2={tools[2]} TOOL3={tools[3]}"
                    )
                    gcmd.respond_raw(
                        f"// action:prompt_button {btn_text}|"
                        f"CHANGE_TOOL_ZCOLOR TOOL={tool_idx+1} {params}|primary"
                    )
            gcmd.respond_raw("// action:prompt_button_group_end")

            gcmd.respond_raw(
                f"// action:prompt_footer_button {self._t('send_print')}|"
                f"PRINT_ZCOLOR LEVELING={leveling} FILENAME=\"{fname}\" "
                f"TOOL0={tools[0]} TOOL1={tools[1]} TOOL2={tools[2]} TOOL3={tools[3]}|red"
            )
            gcmd.respond_raw(f"// action:prompt_footer_button {self._t('cancel')}|RESPOND TYPE=command MSG=action:prompt_end")
            gcmd.respond_raw("// action:prompt_show")
        else:
            gcmd.respond_raw(self._t('no_response', response_data))

    def cmd_PRINT_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        fname = gcmd.get('FILENAME', '')
        if fname == '':
            raise gcmd.error(self._t('error_no_filename'))

        leveling = gcmd.get_int('LEVELING', 0)
        if leveling not in (0, 1):
            raise gcmd.error(self._t('error_leveling', leveling))

        tools = [
            gcmd.get_int('TOOL0', 1),
            gcmd.get_int('TOOL1', 2),
            gcmd.get_int('TOOL2', 3),
            gcmd.get_int('TOOL3', 4)
        ]

        for i, tool in enumerate(tools):
            if tool < 1 or tool > 4:
                raise gcmd.error(self._t('error_tool', i, tool))

        status_code, response_data = self.zsend_post_request("/detail")
        if status_code:
            result = self.parse_printer_response(response_data)
            material_mappings = []

            for tool_idx, tool_val in enumerate(tools):
                if 0 <= (tool_val - 1) < len(result):
                    slot_info = result[tool_val - 1]
                    material_mappings.append({
                        "toolId": tool_idx,
                        "slotId": slot_info['ID'],
                        "materialName": slot_info['Material'],
                        "toolMaterialColor": f"#{slot_info['HEX']}",
                        "slotMaterialColor": f"#{slot_info['HEX']}"
                    })

            data = {
                "fileName": fname,
                "levelingBeforePrint": bool(leveling),
                "flowCalibration": True,
                "useMatlStation": True,
                "gcodeToolCnt": len(material_mappings),
                "materialMappings": material_mappings
            }

            status_code2, response_data2 = self.zsend_post_request("/printGcode", send_data=data)
            if status_code2 == 200:
                gcmd.respond_raw(f"Status: {response_data2.get('msg', 'OK')}")
            else:
                gcmd.respond_raw(self._t('printing_error', response_data2))
        else:
            gcmd.respond_raw(self._t('no_response', response_data))

    def cmd_CHANGE_TOOL_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        fname = gcmd.get('FILENAME', '')
        if fname == '':
            raise gcmd.error(self._t('error_no_filename'))

        leveling = gcmd.get_int('LEVELING', 0)
        if leveling not in (0, 1):
            raise gcmd.error(self._t('error_leveling', leveling))

        ztool = gcmd.get_int('TOOL', 0)
        if ztool < 1 or ztool > 4:
            raise gcmd.error(self._t('error_tool', '', ztool))

        tools = [
            gcmd.get_int('TOOL0', 1),
            gcmd.get_int('TOOL1', 2),
            gcmd.get_int('TOOL2', 3),
            gcmd.get_int('TOOL3', 4)
        ]

        for i, tool in enumerate(tools):
            if tool < 1 or tool > 4:
                raise gcmd.error(self._t('error_tool', i, tool))

        if ztool == 1:
            params=f"TOOL1={tools[1]} TOOL2={tools[2]} TOOL3={tools[3]} FILENAME=\"{fname}\" LEVELING={leveling} "
        elif ztool == 2:
            params=f"TOOL0={tools[0]} TOOL2={tools[2]} TOOL3={tools[3]} FILENAME=\"{fname}\" LEVELING={leveling} "
        elif ztool == 3:
            params=f"TOOL0={tools[0]} TOOL1={tools[1]} TOOL3={tools[3]} FILENAME=\"{fname}\" LEVELING={leveling} "
        else:
            params=f"TOOL0={tools[0]} TOOL1={tools[0]} TOOL2={tools[2]} FILENAME=\"{fname}\" LEVELING={leveling} "

        status_code, response_data = self.zsend_post_request("/detail")
        if status_code:
#            gcmd.respond_raw(json.dumps(response_data, indent=2))
            result = self.parse_printer_response(response_data)
            gcmd.respond_raw(f"// action:prompt_begin {self._t('prompt_material')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('prompt_map_color')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('prompt_file', fname)}")

            gcmd.respond_raw("// action:prompt_button_group_start")
            for idx, slot in enumerate(result):
                btn_text = (
                    f"{self._t('file_tool')} {ztool} → "
                    f"{self._t('spool')} {slot['ID']}: "
                    f"{slot['Material']}/{slot['Color']}"
                )
                gcmd.respond_raw(
                    f"// action:prompt_button {btn_text}|"
                    f"SET_ZCOLOR TOOL{ztool-1}={idx+1} {params}|primary"
                )

            gcmd.respond_raw("// action:prompt_button_group_end")
            gcmd.respond_raw(
                f"// action:prompt_footer_button {self._t('cancel')}|"
                f"SET_ZCOLOR TOOL{ztool-1}={tools[ztool-1]} {params}"
            )
            gcmd.respond_raw("// action:prompt_show")
        else:
            gcmd.respond_raw(self._t('no_response', response_data))

    def cmd_RUN_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        zslot = gcmd.get_int('SLOT', 0)
        if zslot < 1 or zslot > 4:
            raise gcmd.error(self._t('error_slot'))

        zhex = gcmd.get('HEX', '161616').upper()
        ztype = gcmd.get('TYPE', '').upper()
        valid_types = ['PLA', 'ABS', 'PETG', 'TPU', 'PLA-CF', 'PETG-CF', 'SILK', '?']

        color_name = COLOR_MAPPING.get(zhex.lower(), {}).get(self.language, zhex)

        if ztype not in valid_types:
            raise gcmd.error(self._t('error_type', ztype, ', '.join(valid_types[:-1])))

        gcmd.respond_raw(f"// action:prompt_begin {self._t('select_action')}")
        gcmd.respond_raw(f"// action:prompt_text {self._t('spool_info', zslot, ztype, color_name)}")

        gcmd.respond_raw("// action:prompt_button_group_start")
        gcmd.respond_raw(
            f"// action:prompt_button {self._t('change_color')}|"
            f"CHANGE_ZCOLOR SLOT={zslot} TYPE={ztype}|primary"
        )
        gcmd.respond_raw(
            f"// action:prompt_button {self._t('change_type')}|"
            f"CHANGE_ZCOLOR SLOT={zslot} HEX={zhex}|primary"
        )
        gcmd.respond_raw(
            f"// action:prompt_button {self._t('load')}|"
            f"IN_ZCOLOR SLOT={zslot} NAPR=0|primary"
        )
        gcmd.respond_raw(
            f"// action:prompt_button {self._t('unload')}|"
            f"IN_ZCOLOR SLOT={zslot} NAPR=1|primary"
        )
        gcmd.respond_raw("// action:prompt_button_group_end")

        gcmd.respond_raw(f"// action:prompt_footer_button {self._t('cancel')}|RESPOND TYPE=command MSG=action:prompt_end")
        gcmd.respond_raw("// action:prompt_show")

    def cmd_CHANGE_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        zslot = gcmd.get_int('SLOT', 0)
        if zslot < 1 or zslot > 4:
            raise gcmd.error(self._t('error_slot'))

        zhex = gcmd.get('HEX', '').upper()
        ztype = gcmd.get('TYPE', '').upper()
        valid_types = ['PLA', 'ABS', 'PETG', 'TPU', 'PLA-CF', 'PETG-CF', 'SILK', '?']

        if not zhex and not ztype:
            raise gcmd.error(self._t('error_color_or_type'))

        if zhex and ztype:
            if ztype == '?':
                ztype = 'PLA'
            if ztype not in valid_types:
                raise gcmd.error(self._t('error_type', ztype, ', '.join(valid_types[:-1])))

            payload = {
                "cmd": "msConfig_cmd",
                "args": {
                    "slot": zslot,
                    "mt": ztype,
                    "rgb": f"#{zhex}"
                }
            }
            status_code, response_data = self.zsend_post_request("/control", payload=payload)
            if status_code == 200:
                self.cmd_GET_ZCOLOR(gcmd)
                gcmd.respond_raw(self._t('config_success'))
            else:
                gcmd.respond_raw(self._t('config_error', response_data))
            return

        if ztype:
            if ztype == '?':
                ztype = 'PLA'
            if ztype not in valid_types:
                raise gcmd.error(self._t('error_type', ztype, ', '.join(valid_types[:-1])))

            gcmd.respond_raw(f"// action:prompt_begin {self._t('select_color')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('spool_info', zslot, ztype, '')}")
            gcmd.respond_raw("// action:prompt_button_group_start")
            for hex_code, color_data in COLOR_MAPPING.items():
                color_name = color_data[self.language]
                gcmd.respond_raw(
                    f"// action:prompt_button {color_name}|"
                    f"CHANGE_ZCOLOR SLOT={zslot} TYPE={ztype} HEX={hex_code}|primary"
                )
            gcmd.respond_raw("// action:prompt_button_group_end")
            gcmd.respond_raw(f"// action:prompt_footer_button {self._t('cancel')}|RESPOND TYPE=command MSG=action:prompt_end")
            gcmd.respond_raw("// action:prompt_show")

        if zhex:
            color_name = COLOR_MAPPING.get(zhex.lower(), {}).get(self.language, zhex)
            gcmd.respond_raw(f"// action:prompt_begin {self._t('select_type')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('spool_info', zslot, '', color_name)}")
            gcmd.respond_raw("// action:prompt_button_group_start")
            for material in valid_types[:-1]:  # Исключаем '?'
                gcmd.respond_raw(
                    f"// action:prompt_button {material}|"
                    f"CHANGE_ZCOLOR SLOT={zslot} TYPE={material} HEX={zhex}|primary"
                )
            gcmd.respond_raw("// action:prompt_button_group_end")
            gcmd.respond_raw(f"// action:prompt_footer_button {self._t('cancel')}|RESPOND TYPE=command MSG=action:prompt_end")
            gcmd.respond_raw("// action:prompt_show")

    # Загрузка выгрузка филамента
    def cmd_IN_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        zslot = gcmd.get_int('SLOT', 0)
        if zslot < 1 or zslot > 4:
            raise gcmd.error(self._t('error_slot'))

        napr = gcmd.get_int('NAPR', 0)
        if napr not in (0, 1):
            raise gcmd.error(self._t('error_napr'))

        action = "load" if napr == 0 else "unload"
        payload = {
            "cmd": "ms_cmd",
            "args": {
                "slot": zslot,
                "action": napr
            }
        }
        status_code, response_data = self.zsend_post_request("/control", payload=payload)
        if status_code == 200:
            gcmd.respond_raw(self._t(f'{action}_success'))
        else:
            gcmd.respond_raw(self._t(f'{action}_error', response_data))

def load_config(config):
    return zmod_color(config)
