import json
import requests
import subprocess

COLOR_MAPPING = {
    "ffffff": "белый",
    "fef043": "ярко-желтый",
    "dcf478": "светло-зеленый",
    "0acc38": "зеленый",
    "067749": "темно-зеленый",
    "0c6283": "сине-зеленый",
    "0de2a0": "бирюзовый",
    "75d9f3": "голубой",
    "45a8f9": "синий",
    "2750e0": "темно-синий",
    "46328e": "фиолетовый",
    "a03cf7": "ярко-фиолетовый",
    "f330f9": "пурпурный",
    "d4b0dc": "сиреневый",
    "f95d73": "розовый",
    "f72224": "красный",
    "7c4b00": "коричневый",
    "f98d33": "оранжевый",
    "fdebd5": "бежевый",
    "d3c4a3": "светло-коричневый",
    "af7836": "терракотовый",
    "898989": "серый",
    "bcbcbc": "светло-серый",
    "161616": "черный"
}

class zmod_color:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object('gcode')
        self.gcode.register_command(
            'GET_ZCOLOR', self.cmd_GET_ZCOLOR,
            desc=self.cmd_GET_ZCOLOR_help
        )
        self.gcode.register_command(
            'RUN_ZCOLOR', self.cmd_RUN_ZCOLOR,
            desc=self.cmd_RUN_ZCOLOR_help
        )
        self.gcode.register_command(
            'CHANGE_ZCOLOR', self.cmd_CHANGE_ZCOLOR,
            desc=self.cmd_CHANGE_ZCOLOR_help
        )
        self.gcode.register_command(
            'IN_ZCOLOR', self.cmd_IN_ZCOLOR,
            desc=self.cmd_IN_ZCOLOR_help
        )
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
    def zsend_post_request(self, api, payload=None):
        base_ip = self.get_printer_ip()
        url = f"http://{base_ip}:8898{api}"
        headers = {
            "Accept": "*/*",
            "Content-Type": "application/json"
        }
        data = {
            "serialNumber": self.serialNumber,
            "checkCode": self.checkCode
        }
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
    def parse_printer_response(self, response_data):
        slots_info = []
        slots = response_data.get('detail', {}).get('matlStationInfo', {}).get('slotInfos', [])
        for slot in slots:
            if slot.get('hasFilament', True):
                slot_id = slot.get('slotId', 'N/A')
                material = slot.get('materialName', 'Неизвестный материал')
                hex_color = slot.get('materialColor', '161616').replace("#", "")

                color_name = COLOR_MAPPING.get(hex_color.lower(), hex_color)

                slots_info.append({
                    'ID': slot_id,
                    'Материал': material.upper(),
                    'Цвет': color_name,
                    'HEX': hex_color.upper()
                })
        return slots_info
    cmd_GET_ZCOLOR_help = "Получить сохраненные цвета"
    def cmd_GET_ZCOLOR(self, gcmd):
        status_code, response_data = self.zsend_post_request("/detail")
        if status_code:
#            gcmd.respond_raw(json.dumps(response_data, indent=2))
            gcmd.respond_raw("// action:prompt_begin Загруженный материал")
            gcmd.respond_raw("// action:prompt_text Выберите катушку, для изменения")
            gcmd.respond_raw("// action:prompt_button_group_start")
            result = self.parse_printer_response(response_data)

            for slot in result:
                gcmd.respond_raw(f"// action:prompt_button {slot['ID']}: {slot['Материал']}/{slot['Цвет']}|RUN_ZCOLOR SLOT={slot['ID']} HEX={slot['HEX']} TYPE={slot['Материал']}|primary")

            gcmd.respond_raw("// action:prompt_button_group_end")
            gcmd.respond_raw("// action:prompt_footer_button Отмена|RESPOND TYPE=command MSG=action:prompt_end")
            gcmd.respond_raw("// action:prompt_show")
        else:
            gcmd.respond_raw(f"!! Нет ответа от принтера. Необходимо настроить принтер. На экране принтера: \"Настройки\" -> \"Иконка WiFi\" -> \"Сетевой режим\" -> включить ползунок \"Только локальные сети\"\n{response_data}")

    cmd_RUN_ZCOLOR_help = "Настроить катушку"
    def cmd_RUN_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")

        zslot = gcmd.get_int('SLOT', 0)
        if zslot < 1 or zslot > 4:
            raise gcmd.error("Неверный SLOT. Допустимые: 1-4")
        zhex = gcmd.get('HEX', '161616').upper()
        color_name = COLOR_MAPPING.get(zhex.lower(), zhex)
        ztype = gcmd.get('TYPE', '').upper()
        if zhex == '':
            zhex='161616'
        if ztype == '?':
            ztype='PLA'

        valid_type = ['PLA', 'ABS', 'PETG', 'TPU', 'PLA-CF', 'PETG-CF', 'SILK', '?']
        if ztype not in valid_type:
            raise gcmd.error(f"Неверный TYPE {ztype}. Допустимые: %s" % ', '.join(valid_type))

        gcmd.respond_raw("// action:prompt_begin Что сделать?")
        gcmd.respond_raw(f"// action:prompt_text Загружена катушка: {zslot}: {ztype}/{color_name}")

        gcmd.respond_raw("// action:prompt_button_group_start")
        gcmd.respond_raw(f"// action:prompt_button Сменить цвет|CHANGE_ZCOLOR SLOT={zslot} TYPE={ztype}|primary")
        gcmd.respond_raw(f"// action:prompt_button Сменить тип пластика|CHANGE_ZCOLOR SLOT={zslot} HEX={zhex}|primary")
        gcmd.respond_raw(f"// action:prompt_button Загрузить|IN_ZCOLOR SLOT={zslot} NAPR=0|primary")
        gcmd.respond_raw(f"// action:prompt_button Выгрузить|IN_ZCOLOR SLOT={zslot} NAPR=1|primary")
        gcmd.respond_raw("// action:prompt_button_group_end")

        gcmd.respond_raw("// action:prompt_footer_button Отмена|RESPOND TYPE=command MSG=action:prompt_end")
        gcmd.respond_raw("// action:prompt_show")

    cmd_CHANGE_ZCOLOR_help = "Сменить цвет на катушке"
    def cmd_CHANGE_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")

        zslot = gcmd.get_int('SLOT', 0)
        if zslot < 1 or zslot > 4:
            raise gcmd.error("Неверный SLOT. Допустимые: 1-4")
        zhex = gcmd.get('HEX', '').upper()
        ztype = gcmd.get('TYPE', '').upper()
        valid_type = ['PLA', 'ABS', 'PETG', 'TPU', 'PLA-CF', 'PETG-CF', 'SILK', '?']

        if zhex == '' and ztype == '':
            raise gcmd.error("Не указан TYPE и HEX")

        if zhex != '' and ztype!= '':
            if ztype == '?':
                ztype='PLA'

            valid_type = ['PLA', 'ABS', 'PETG', 'TPU', 'PLA-CF', 'PETG-CF', 'SILK', '?']
            if ztype not in valid_type:
                raise gcmd.error(f"Неверный TYPE {ztype}. Допустимые: %s" % ', '.join(valid_type))

            payload = {
                "cmd": "msConfig_cmd",
                "args": {
                    "slot": zslot,
                    "mt": ztype,
                    "rgb": f"#{zhex}"
                }
            }

            status_code, response_data = self.zsend_post_request("/control", payload=payload)
            if status_code:
                self.cmd_GET_ZCOLOR(gcmd)
                gcmd.respond_raw(f"{response_data}")
            else:
                gcmd.respond_raw(f"!! Ошибка смены цвета или типа пластика\n{response_data}")

        if zhex == '':
            if ztype == '?':
                ztype='PLA'

            if ztype not in valid_type:
                raise gcmd.error(f"Неверный TYPE {ztype}. Допустимые: %s" % ', '.join(valid_type))

            gcmd.respond_raw("// action:prompt_begin Укажите цвет?")
            gcmd.respond_raw(f"// action:prompt_text Загружена катушка: {zslot}: {ztype}")

            gcmd.respond_raw("// action:prompt_button_group_start")
            for index,(hex_code, color_name) in enumerate(COLOR_MAPPING.items(), start=1):
                gcmd.respond_raw(f"// action:prompt_button {color_name}|CHANGE_ZCOLOR SLOT={zslot} TYPE={ztype} HEX={hex_code}|primary")
            gcmd.respond_raw("// action:prompt_button_group_end")

            gcmd.respond_raw("// action:prompt_footer_button Отмена|RESPOND TYPE=command MSG=action:prompt_end")
            gcmd.respond_raw("// action:prompt_show")
        if ztype == '':
            color_name = COLOR_MAPPING.get(zhex.lower(), zhex)
            gcmd.respond_raw("// action:prompt_begin Укажите тип пластика?")
            gcmd.respond_raw(f"// action:prompt_text Загружена катушка: {zslot}: {color_name}")

            gcmd.respond_raw("// action:prompt_button_group_start")
            for item in valid_type[:-1]:
                gcmd.respond_raw(f"// action:prompt_button {item}|CHANGE_ZCOLOR SLOT={zslot} TYPE={item} HEX={zhex}|primary")
            gcmd.respond_raw("// action:prompt_button_group_end")

            gcmd.respond_raw("// action:prompt_footer_button Отмена|RESPOND TYPE=command MSG=action:prompt_end")
            gcmd.respond_raw("// action:prompt_show")
    cmd_IN_ZCOLOR_help = "Сменить цвет на катушке"
    def cmd_IN_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")

        zslot = gcmd.get_int('SLOT', 0)
        if zslot < 1 or zslot > 4:
            raise gcmd.error("Неверный SLOT. Допустимые: 1-4")
        napr = gcmd.get_int('NAPR', 0)
        if napr != 0 and napr != 1:
            raise gcmd.error("Неверное направление (NAPR) Допустимое: 0-1")
        payload = {
            "cmd": "ms_cmd",
            "args": {
                "slot": zslot,
                "action": napr
            }
        }

        status_code, response_data = self.zsend_post_request("/control", payload=payload)
        if status_code:
            gcmd.respond_raw(f"{response_data}")
        else:
            gcmd.respond_raw(f"!! Ошибка загрузки/выгрузки\n{response_data}")

def load_config(config):
    return zmod_color(config)
