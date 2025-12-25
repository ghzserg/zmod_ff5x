# (C) 2025 ghzserg https://github.com/ghzserg/zmod/
import json
import os
import serial
import re
import time
import threading
import logging

# Параметры порта
PORT = '/dev/ttyS4'
BAUDRATE = 115200
PARITY = 'N'
STOPBITS = 1
BYTESIZE = 8
TIMEOUT = 0.2
HOST_REPORT_TIME = 0.2
OPROS_EXTRUDER = 0.1

FFCONFIG='/usr/prog/config/Adventurer5M.json'
TYPECONFIG='/usr/data/config/mod_data/filament.json'
FILE_CONFIG='/usr/data/config/mod_data/file.json'

FFS_STATUS_DELTA     = 11  # Дельта от первой катушки
FFS_STATUS_OPROS     =  3  # Опрос катушек
FFS_STATUS_READY     =  5  # Готов к работе
FFS_STATUS_ZAGAT     =  7  # 18, 29, 40 поджата катушка
FFS_STATUS_ZAGRUZKA  = 11  # 22, 33, 44 загрузка катушки
FFS_STATUS_VIGRUZKA  = 15  # 26, 37, 48 выгрузка катушки
FFS_STATUS_OTZGAT    = 12  # 23, 34, 45 отжим катушки
FFS_STATUS_DRV_ERROR = 127 # Ошибка драйвера

RET_OK       = 0         # Все отработало штатно
RET_EXTRUDER = 1         # по сработке датчика экструдера
RET_SILK     = 2         # по сработке дачика прутка
RET_STALL    = 3         # по сработке движения прутка
RET_TIMEOUT  = 4         # Таймаут получения нужного статуса
RET_EXIT     = 5         # По завершению программы
RET_RETRY    = 6         # Надо повторить запрос

class zmod_ifs:
    def __init__(self, config):
        self.printer = config.get_printer()

        self.debug = config.getboolean('debug', False)
        self.stall_count = config.getint('stall_count', 3, minval=1)    # с какой попытки засчитывать что пруток остановилося
        self.silk_count = config.getint('silk_count', 1, minval=1)      # c какой попытки зачитывать что пруток в IFS
        self.retry_count = config.getint('retry_count', 3, minval=1)    # сколько раз повторять команду при ошибке

        self.debug = config.getboolean('debug', False)
        self.reactor = self.printer.get_reactor()
        self.gcode = self.printer.lookup_object('gcode')


        self.lang = 'en'
        self.ifs = False
        self.zmod = self.printer.lookup_object('zmod', None)
        self.zmod_color = self.printer.lookup_object('zmod_color', None)
        temp_defaults = {
            "PLA": 220,
            "PLA-CF": 220,
            "SILK": 230,
            "TPU": 230,
            "ABS": 250,
            "PETG": 250,
            "PETG-CF": 250
        }
        for option in config.get_prefix_options('filament_'):
            filament_type = option[len('filament_'):].upper()
            try:
                temp = config.getint(option)
                temp_defaults[filament_type] = temp
            except Exception:
                pass

        self.temp_defaults = temp_defaults
        if not self.zmod_color or self.zmod_color.get_display():
            return
        self.ifs_data = IfsData()

        self.zmod_color.valid_types = list(self.temp_defaults.keys()) + ['?']

        # Синхронизация потоков
        self._command_lock = threading.Lock()
        self._command = "F13"
        self._command_id = 0

        self._ret_command_lock = threading.Lock()
        self._ret_command_data = ""
        self._ret_command_id = 0

        self.stop_thread = False
        self.sensor_thread = threading.Thread(target=self._sensor_reader)
        self.sensor_thread.daemon = True

        # Регистрация событий
        self.printer.register_event_handler("klippy:ready", self._handle_ready)
        self.printer.register_event_handler("klippy:disconnect", self._handle_disconnect)
        self.printer.register_event_handler("klippy:shutdown", self._handle_shutdown)

        # Регистрация команд G-кода
        # Внешние команды
        self.gcode.register_command('PURGE_PRUTOK_IFS', self.cmd_PURGE_PRUTOK_IFS)      # Очистить пруток от IFS до экструдера
        self.gcode.register_command('REMOVE_PRUTOK_IFS', self.cmd_REMOVE_PRUTOK_IFS)    # Удаляет пруток по номеру прутка
        self.gcode.register_command('INSERT_PRUTOK_IFS', self.cmd_INSERT_PRUTOK_IFS)    # Вставить пруток в IFS по номеру прутка
        self.gcode.register_command('SET_CURRENT_PRUTOK', self.cmd_SET_CURRENT_PRUTOK)  # Указать klipper какой пруток сейчас активен
        self.gcode.register_command('ANALOG_PRUTOK', self.cmd_ANALOG_PRUTOK)            # Загрузить аналогичный пруток
        self.gcode.register_command('IFS_MOTION', self.cmd_IFS_MOTION)                  # Проверить, остановился или кончился филамент
        self.gcode.register_command('IFS_GET_COMAND', self.cmd_IFS_GET_COMMAND)         # Сообщить текущую команду

        # Внутренние конманды начинаются с IFS
        self.gcode.register_command('IFS_PRINT_DEFAULTS', self.cmd_IFS_PRINT_DEFAULTS)
        self.gcode.register_command('IFS_AUTOINSERT', self.cmd_IFS_AUTOINSERT, desc=self.cmd_IFS_AUTOINSERT_help)
        self.gcode.register_command('IFS_STATUS', self.cmd_IFS_STATUS, desc=self.cmd_IFS_STATUS_help)
        self.gcode.register_command('IFS_EXTRUDER_SENSOR', self.cmd_IFS_EXTRUDER_SENSOR)
        self.gcode.register_command('IFS_REMOVE_PRUTOK', self.cmd_IFS_REMOVE_PRUTOK)
        self.gcode.register_command('IFS_REMOVE_CURRENT_PRUTOK', self.cmd_IFS_REMOVE_CURRENT_PRUTOK)

        self.gcode.register_command('IFS_F10', self.cmd_IFS_F10)        # Вставить пруток
        self.gcode.register_command('IFS_F11', self.cmd_IFS_F11)        # Извлечь пруток
        self.gcode.register_command('IFS_F13', self.cmd_IFS_F13)        # Состояние IFS
        self.gcode.register_command('IFS_F15', self.cmd_IFS_F15)        # Сброс драйвера
        self.gcode.register_command('IFS_F18', self.cmd_IFS_F18)        # Отжим филамента везде
        self.gcode.register_command('IFS_F23', self.cmd_IFS_F23)        # Помечаем пруток как вставленный
        self.gcode.register_command('IFS_F24', self.cmd_IFS_F24)        # Прижим филамента
        self.gcode.register_command('IFS_F39', self.cmd_IFS_F39)        # Отжим филамента
        self.gcode.register_command('IFS_F112', self.cmd_IFS_F112)      # Прекращаем подачу прутка

    def _handle_ready(self):
        self.query_adc = self.printer.lookup_object('query_adc')
        self.filament_sensor = self.printer.lookup_object('temperature_sensor filamentValue')

        self.get_lang()
        self.get_prutok_config(1)
        self.sensor_thread.start()

    def get_ifs_status(self):
        return self.ifs

    def send_command_and_wait(self, command, timeout=5.0, result=None, extruder=None):
        """
        Отправляет команду и возвращает ответ.
        :param command: Команда для отправки (например, "H1").
        :param timeout: Таймаут ожидания ответа.
        :param result: Ожидаемый ответ
        :param extruder: Контролировать состояние экструдера
        :return: Ответ от датчика или None при таймауте.
        """
        with self._command_lock:
            self._command_id += 1
            command_id = self._command_id  # Уникальный ID команды
            self._command = f"{command}#{command_id}"
        start_time = eventtime = self.reactor.monotonic()

        if result is not None:
            if isinstance(result, str):
                expected_results = (result,)
            else:
                expected_results = tuple(result)
        else:
            expected_results = None

        while not self.stop_thread:
            if extruder: # Если нужно контролировать экструдер
                if self.get_extruder_sensor() == extruder['status']:
                    #self.info("Extruder trigger 1")
                    return None

            eventtime = self.reactor.pause(eventtime + HOST_REPORT_TIME)
            with self._ret_command_lock:
                ret_command_data = self._ret_command_data
                ret_command_id = self._ret_command_id
                self._ret_command_id = 0

            #if ret_command_id != 0:
            #    self.info(f"WAIT: {command}#{command_id} RET: #{ret_command_id} {ret_command_data}")
            if command_id == ret_command_id:
                if expected_results is not None:
                    if ret_command_data in expected_results:
                        return ret_command_data
                    else:
                        self.gcode.run_script_from_command("_ENABLE_SENSOR")
                        raise self.gcode.error(f"{command}#{command_id} ret {ret_command_data} != {expected_results}")
                        return None
                else:
                    return self._ret_command_data
            if eventtime - start_time > timeout:
                self.gcode.run_script_from_command("_ENABLE_SENSOR")
                if self.lang == 'ru':
                    error_msg = f"Таймаут ожидания ответа от команды {command}#{command_id}"
                else:
                    error_msg = f"Timeout waiting for response from command {command}#{command_id}"
                self.info(error_msg)
                self.gcode.run_script_from_command("IFS_F112")
                self.gcode.run_script_from_command("IFS_F18")
                raise self.gcode.error(error_msg)
                return None
        return None

    # self.wait_for_state(
    #     Port=2,
    #     FFS_state=FFS_STATUS_ZAGRUZKA,
    #     silk={'count': 3, 'status': True},
    #     stall={'count': 3, 'status': True},
    #     extruder={'status': True},
    #     timeout=15
    #     )
    def wait_for_state(self, Port=0, FFS_state=None, silk=None, stall=None, extruder=None, timeout=10):
        start_time = self.reactor.monotonic()
        check_state = None
        if FFS_state is not None:
            if Port != 0:
                check_state = (FFS_state + (Port-1)*FFS_STATUS_DELTA)
            else:
                check_state = FFS_state
        silk_count = stall_count = 0

        while not self.stop_thread:
            # Запрос статуса
            response = self.send_command_and_wait("F13", extruder=extruder)
            self.ifs_data.update_from_string(response)
            current_values = self.ifs_data.get_values()
            if extruder:
                if self.get_extruder_sensor() == extruder['status']: # Проверяем сработку датчика в экструдере
                    self.info("Extruder trigger 2")
                    return False, RET_EXTRUDER, current_values

            state = current_values['State']
            self.info(f"F13 need:{check_state}|{FFS_STATUS_READY} cur:{state} > {response}")

            # Проверка что статус готов
            if state == FFS_STATUS_READY:
                return True, RET_OK, current_values

            if state == FFS_STATUS_DRV_ERROR:
                gcmd_tmp = self.gcode.create_gcode_command("IFS_F15", "IFS_F15", {})
                self.cmd_IFS_F15(gcmd_tmp)
                return False, RET_RETRY, current_values

            if state == check_state:          # ждем сработки нужного статуса
                if silk and Port != 0:        # проверяем наличие прутка
                    current_silk = current_values['Silk']
                    if ((current_silk >> (Port - 1)) & 1 == 1) == silk['status']:
                        silk_count += 1
                        if silk_count >= silk['count']:
                            return False, RET_SILK, current_values
                    else:
                        silk_count = 0
                if stall and Port != 0:        # проверяем движение прутка
                    current_stall = current_values['stall_state']
                    if ((current_stall >> (Port - 1)) & 1 == 1) == stall['status']:
                        stall_count += 1
                        if stall_count >= stall['count']:
                            return False, RET_STALL, current_values
                    else:
                        stall_count = 0
            if self.reactor.monotonic() - start_time > timeout:
                if self.lang == 'ru':
                    error_msg = f"IFS: Вышло время для получения статуса {check_state}|{FFS_STATUS_READY} получен {state}"
                else:
                    error_msg = f"IFS: Timeout waiting for status {check_state}|{FFS_STATUS_READY}, received {state}"
                self.info(error_msg)
                self.gcode.run_script_from_command("IFS_F112")
                self.gcode.run_script_from_command("IFS_F18")
                raise self.gcode.error(error_msg)
                return False, RET_TIMEOUT, current_values

            self.reactor.pause(self.reactor.monotonic() + HOST_REPORT_TIME)
        return False, RET_EXIT, None


    def _handle_disconnect(self):
        logging.info("IFS: Printer disconnected. Stopping IFS thread.")
        self._close()

    def _handle_shutdown(self):
        logging.info("IFS: Printer shutdown. Stopping IFS thread.")
        self._close()

    def _close(self):
        self.stop_thread = True
        if self.sensor_thread.is_alive():
            self.sensor_thread.join(timeout=2.0)

    def _respond_info(self, msg):
        self.reactor.register_async_callback(
            lambda e: self.gcode.respond_info(msg))

    def _respond_raw(self, msg):
        self.reactor.register_async_callback(
            lambda e: self.gcode.respond_raw(msg))

    def info(self, msg):
        if self.debug:
            self.gcode.respond_info(msg)

    def get_lang(self):
        if self.zmod is None:
            self.lang = 'en'
            self.zmod = self.printer.lookup_object('zmod', None)
        if self.zmod is not None:
            self.lang = self.zmod.get_lang()

    def get_extruder_sensor(self):
        value, timestamp = self.query_adc.adc["temperature_sensor filamentValue"].get_last_value()
        result = True
        if value > 0.3:
            result = (value >= 0.72)
        return result

    def get_ifs_sensor(self, port):
        return self.ifs_data.get_stall(port)

    def set_cur_port(self, port):
        return self.ifs_data.set_cur_port(port)

    def get_port(self, port=0):
        if not self.ifs:
            return False
        return self.ifs_data.get_port(port)

    def print_str(self, string, info=True):
        if info:
            self.gcode.respond_info(string)
        else:
            self.info(string)
            self.gcode.run_script_from_command("IFS_F112")
            self.gcode.run_script_from_command("IFS_F18")
            raise self.gcode.error(string)

    # Получить текущий активный пруток из конфига
    def get_current_channel_from_config(self):
        with open(FFCONFIG, 'r') as file:
            config = json.load(file)
            prutok = int(config["FFMInfo"].get("channel", 0))
            self.set_cur_port(prutok)
            return prutok
        return 0

    # Получить тип прутка из конфига
    def get_prutok_type_from_config(self, prutok):
        ret="PLA"

        with open(FFCONFIG, 'r') as file:
            config = json.load(file)
            ret=config["FFMInfo"].get(f"ffmType{prutok}", "PLA")
        if ret not in self.temp_defaults:
            ret="PLA"
        return ret

    # Получить конфиг прутка по номеру прутка
    def get_prutok_config(self, prutok):
        if prutok < 0 or prutok > 4:
            self.print_str(f"Некорректный номер прутка {prutok}" if self.lang == 'ru' else f"Incorrect filament number {prutok}", False)
        filament=self.get_prutok_type_from_config(prutok)

        base_default = {
            "filament_unload_before_cutting": 0,    # На сколько поднимать филамент ПЕРЕД тем  как отрезать (по умолчанию 0)
            "filament_unload_after_cutting": 5,     # На сколько поднимать филамент ПОСЛЕ того как отрезали (по умолчанию 5)
            "filament_unload_after_drop": 3,        # Ретракт после сброса филамента (немного вытащить пруток из сопла, для предотвращения протечки,
                                                    #   когда смена прутка уже прошла и сопло едет дальше печатать)
            "filament_load_speed": 300,             # Скорость загрузки филамента (скорость вращения экструдера, 300 мм/м = 5 мм/c)
            "filament_unload_speed": 600,           # Скорость подъема  филамента (скорость вращения экструдера, 600 мм/м = 10 мм/c)
                                                    #   IFS работает на скорости 2*filament_unload_speed
            "filament_tube_length": 1000,           # Длина полной загрузки/выгрузки филамента (длинна тефлоновой трубки от IFS до головы, полезно дял тех у кого не стоковые трубки)
            "filament_drop_length": 90,             # Длина сброса в какашник (дистанция прутка который будет выдавлен в какашник, то есть дистанция прочистки сопла
                                                    #   от преведущего филамената и смешения цветов, полезно когда не используется башня для сброса смешанных цветов)
            "filament_drop_length_add": 90,         # Дополнительная длина сброса в какашник при смене типа филамента (смена разных материаалов, к примеру PETG на композитный PETG)
            "nozzle_cleaning_length": 60,           # Длина прочистки сопла (дистанция на сколько вытаскивать пруток из экструдера
                                                    #   (то есть на сколько милиметров доставать пруток из фидера, когда текущая катушка больше не используется)
            "filament_fan_speed": 102,              # Скорость работы вентилятора при сбросе через какашник (то есть сдувает подтеки из сопла, когда происходит очистка)
            #"temp": 230,                           # Температура до которой необхоидмо разогреть сопло для смены филамента

            "filament_autoinsert_empty_length": 600,# Сколько мм затягивать при автоматической вставке прутка, если экструдер пустой
            "filament_autoinsert_full_length": 550, # Сколько мм затягивать при автоматической вставке прутка, если экструдер был занят
            "filament_autoinsert_ret_length": 90,   # Сколько мм втягивать обратно, если сработал эдатчик экструдера (срабатывает только на пустом экструдере)
            "filament_autoinsert_speed": 1200       # Скорость вставки прутка
        }


        required_fields = ['temp'] + list(base_default.keys())

        try:
            with open(TYPECONFIG, 'r') as f:
                data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            data = {}

        changed = False

        for filament_name, temp_default in self.temp_defaults.items():
            if filament_name in data:
                existing = data[filament_name]
                normalized = {}
                normalized['temp'] = existing.get('temp', temp_default)
                for key, default_val in base_default.items():
                    normalized[key] = existing.get(key, default_val)

                if existing != normalized:
                    data[filament_name] = normalized
                    changed = True
            else:
                new_config = base_default.copy()
                new_config['temp'] = temp_default
                data[filament_name] = new_config
                changed = True

        if changed:
            with open(TYPECONFIG, 'w') as f:
                json.dump(data, f, indent=4)

        config = data.get(filament, {})
        config['filament_type'] = filament
        return config

    # Вывод температур
    def cmd_IFS_PRINT_DEFAULTS(self, gcmd):
        msg = ""
        for filament_type, temp in self.temp_defaults.items():
            msg += f"{filament_type}: {temp}°C\n"
        self.print_str(msg.strip())

    def cmd_IFS_GET_COMMAND(self, gcmd):
        with self._command_lock:
            current_command = self._command
            current_id = self._command_id
        with self._ret_command_lock:
            ret_command_data = self._ret_command_data
            ret_command_id = self._ret_command_id

        self.print_str(f"IFS_GET_COMMAND: {current_command} ID: {current_id} RET: {ret_command_data} RET_ID: {ret_command_id}")

    # Проверить остановился или закончился пруток
    def cmd_IFS_MOTION(self, gcmd):
        cur_prutok=self.get_current_channel_from_config()
        if self.get_port(cur_prutok):
            # Остановился
            self.gcode.run_script_from_command("_PRINT_IFS_MOTION PAUSE=1")
        else:
            # Закончился
            self.gcode.run_script_from_command("_PRINT_IFS_MOTION PAUSE=0")

    # Указать текущий пруток
    def cmd_SET_CURRENT_PRUTOK(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return
        cur_prutok = 99

        # Проверяем что пруток в экструдере
        if self.get_extruder_sensor():
            n_prutok = self.get_current_channel_from_config()
            if self.get_port(n_prutok):
                try:
                    with open(FILE_CONFIG, 'r') as f:
                        mapping = json.load(f)
                        cur_prutok = mapping.index(n_prutok)
                except Exception as e:
                    cur_prutok = 98

        channel = gcmd.get_int('CHANNEL', cur_prutok)
        if channel != cur_prutok:
            self.gcode.run_script_from_command(f"_A_CHANGE_FILAMENT CHANNEL={channel} RESTORE_POSITION=0 RESTORE_TEMP=0")
        else:
            self.print_str(f"Указываю активный пруток T{cur_prutok}" if self.lang == 'ru' else f"Setting active filament T{cur_prutok}")
            self.gcode.run_script_from_command(f"SDCARD_SET_CHANNEL CHANNEL={cur_prutok}")
        self.print_str("Включаю IFS" if self.lang == 'ru' else f"Enable IFS")
        self.gcode.run_script_from_command("SDCARD_ENABLE_FFM ENABLE=1")

    def cmd_ANALOG_PRUTOK(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        prutok = 1
        t_prutok = 0

        with open(FFCONFIG, 'r') as file:
            config = json.load(file)
            ffm_info = config["FFMInfo"]
            prutok = ffm_info.get("channel", 1)
            self.set_cur_port(prutok)
            filament_type = ffm_info.get(f"ffmType{prutok}", "PLA")
            filament_color = ffm_info.get(f"ffmColor{prutok}", "#161616")

        if filament_type not in self.temp_defaults:
            filament_type = "PLA"

        with open(FILE_CONFIG, 'r') as f:
            mapping = json.load(f)

        try:
            t_prutok = mapping.index(prutok)
        except ValueError:
            t_prutok = 0

        for i in range(1, 5):
            if (
                f"ffmType{i}" not in ffm_info or
                f"ffmColor{i}" not in ffm_info
            ):
                continue

            if (
                i != prutok and
                ffm_info[f"ffmType{i}"] == filament_type and
                ffm_info[f"ffmColor{i}"] == filament_color and
                self.get_port(i)
            ):
                new_mapping = [i if x == prutok else x for x in mapping]

                with open(FILE_CONFIG, 'w') as f:
                    json.dump(new_mapping, f)

                self.gcode.run_script_from_command("_PRINT_HEAD INFO=1 CHANNEL={t_prutok}")
                self.gcode.run_script_from_command(f"_A_CHANGE_FILAMENT CHANNEL={t_prutok} RESTORE_POSITION=0 RESTORE_TEMP=1")
                self.gcode.run_script_from_command("RESUME")
                return
        self.gcode.run_script_from_command("_PRINT_HEAD INFO=0")
        self.gcode.run_script_from_command("RESUME")

    # Извлечь пруток из IFS
    def cmd_REMOVE_PRUTOK_IFS(self, gcmd):
        prutok = gcmd.get_int('PRUTOK', 1)
        need_stop = gcmd.get_int('NEED_STOP', 1)
        config = self.get_prutok_config(prutok)

        self.gcode.run_script_from_command(
            f"_REMOVE_PRUTOK_IFS "
            f"PRUTOK={prutok} "
            f"TEMP={config['temp']} "
            f"NEED_STOP={need_stop} "
            f"FILAMENT_TYPE={config['filament_type']} "
            f"FILAMENT_UNLOAD_SPEED={config['filament_unload_speed']} "
            f"FILAMENT_LOAD_SPEED={config['filament_load_speed']} "
            f"FILAMENT_UNLOAD_BEFORE_CUTTING={config['filament_unload_before_cutting']} "
            f"FILAMENT_UNLOAD_AFTER_CUTTING={config['filament_unload_after_cutting']} "
            f"FILAMENT_UNLOAD_AFTER_DROP={config['filament_unload_after_drop']} "
            f"FILAMENT_TUBE_LENGTH={config['filament_tube_length']} "
            f"FILAMENT_DROP_LENGTH={config['filament_drop_length']} "
            f"FILAMENT_FAN_SPEED={config['filament_fan_speed']} "
            f"NOZZLE_CLEANING_LENGTH={config['nozzle_cleaning_length']} "
        )

    # Очистить пруток от IFS до экструдера
    def cmd_PURGE_PRUTOK_IFS(self, gcmd):
        prutok = self.get_current_channel_from_config()
        config = self.get_prutok_config(prutok)
        cycle_count = 0
        max_cycles = 20

        while self.get_extruder_sensor() and cycle_count < max_cycles:
            self.gcode.run_script_from_command(
                f"_PURGE_PRUTOK_IFS "
                f"PRUTOK={prutok} "
                f"FILAMENT_TYPE={config['filament_type']} "
                f"FILAMENT_UNLOAD_SPEED={config['filament_unload_speed']} "
                f"FILAMENT_LOAD_SPEED={config['filament_load_speed']} "
                f"FILAMENT_UNLOAD_BEFORE_CUTTING={config['filament_unload_before_cutting']} "
                f"FILAMENT_UNLOAD_AFTER_CUTTING={config['filament_unload_after_cutting']} "
                f"FILAMENT_UNLOAD_AFTER_DROP={config['filament_unload_after_drop']} "
                f"FILAMENT_TUBE_LENGTH={config['filament_tube_length']} "
                f"FILAMENT_DROP_LENGTH={config['filament_drop_length']} "
                f"FILAMENT_FAN_SPEED={config['filament_fan_speed']} "
                f"NOZZLE_CLEANING_LENGTH={config['nozzle_cleaning_length']} "
            )
            cycle_count += 1
        self.gcode.run_script_from_command("SET_GCODE_VARIABLE MACRO=_A_CHANGE_FILAMENT VARIABLE=purge VALUE=0")

    # Вставить пруток в IFS
    def cmd_INSERT_PRUTOK_IFS(self, gcmd):
        prutok = gcmd.get_int('PRUTOK', 1)
        need_stop = gcmd.get_int('NEED_STOP', 1)
        trash = gcmd.get_int('TRASH', 0)
        config = self.get_prutok_config(prutok)

        filament_drop_length_add = 0
        if self.get_extruder_sensor():
            cur_prutok = self.get_current_channel_from_config()
            cur_config=self.get_prutok_config(cur_prutok)
            if config['filament_type'] != cur_config['filament_type']:
                filament_drop_length_add = config['filament_drop_length_add']

        self.gcode.run_script_from_command(
            f"_INSERT_PRUTOK_IFS "
            f"PRUTOK={prutok} "
            f"TEMP={config['temp']} "
            f"NEED_STOP={need_stop} "
            f"TRASH={trash} "
            f"FILAMENT_TYPE={config['filament_type']} "
            f"FILAMENT_UNLOAD_SPEED={config['filament_unload_speed']} "
            f"FILAMENT_LOAD_SPEED={config['filament_load_speed']} "
            f"FILAMENT_UNLOAD_BEFORE_CUTTING={config['filament_unload_before_cutting']} "
            f"FILAMENT_UNLOAD_AFTER_CUTTING={config['filament_unload_after_cutting']} "
            f"FILAMENT_UNLOAD_AFTER_DROP={config['filament_unload_after_drop']} "
            f"FILAMENT_TUBE_LENGTH={config['filament_tube_length']} "
            f"FILAMENT_DROP_LENGTH={config['filament_drop_length']} "
            f"FILAMENT_DROP_LENGTH_ADD={filament_drop_length_add} "
            f"FILAMENT_FAN_SPEED={config['filament_fan_speed']} "
            f"NOZZLE_CLEANING_LENGTH={config['nozzle_cleaning_length']} "
        )

    def print_result(self, ret_code, values, prutok, info=True):
        if self.lang == 'ru':
            if ret_code == RET_OK:
                self.print_str("IFS в режиме готовности")
            elif ret_code == RET_EXTRUDER:
                self.print_str("Сработал датчик наличия прутка в экструдере", info)
            elif ret_code == RET_SILK:
                self.print_str(f"Нет прутка {prutok} в IFS", info)
            elif ret_code == RET_STALL:
                self.print_str(f"Остановился пруток {prutok} в IFS", info)
            elif ret_code == RET_TIMEOUT:
                self.print_str("Превышено время ожидания", info)
            elif ret_code == RET_EXIT:
                self.print_str("Завершение программы")
            elif ret_code == RET_RETRY:
                self.print_str("Сбой драйвера IFS", info)
            else:
                self.print_str("Неизвестный код завершения", info)
        else:
            if ret_code == RET_OK:
                self.print_str("IFS in ready mode")
            elif ret_code == RET_EXTRUDER:
                self.print_str("Filament sensor triggered in extruder", info)
            elif ret_code == RET_SILK:
                self.print_str(f"No filament {prutok} in IFS", info)
            elif ret_code == RET_STALL:
                self.print_str(f"Filament {prutok} stalled in IFS", info)
            elif ret_code == RET_TIMEOUT:
                self.print_str("Timeout exceeded", info)
            elif ret_code == RET_EXIT:
                self.print_str("Program termination")
            elif ret_code == RET_RETRY:
                self.print_str("IFS driver failure", info)
            else:
                self.print_str("Unknown return code", info)

    def _safe_run_script(self, script):
        try:
            self.gcode.run_script_from_command(script)
        except self.gcode.error as e:
            #self.info(f"Ошибка в асинхронном вызове {script}: {e}")
            pass

    cmd_IFS_AUTOINSERT_help = "Автоматическая загрузка филамента"
    def cmd_IFS_AUTOINSERT(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        prutok = gcmd.get_int('PRUTOK', 1)
        config = self.get_prutok_config(prutok)

        self.gcode.respond_info(f"Автоматическая вставка прутка {prutok}" if self.lang == 'ru' else f"Automatic filament insertion {prutok}")
        self.wait_for_state()

        # Прижим прутка
        gcmd_tmp = self.gcode.create_gcode_command("IFS_F24", "IFS_F24", {'PRUTOK': prutok})
        self.cmd_IFS_F24(gcmd_tmp)

        # Проверяем есть ли чтото в экструдере
        if self.get_extruder_sensor():
            self.gcode.respond_info("В экструдере есть пруток" if self.lang == 'ru' else "There is filament in the extruder")
            # Затягиваем пруток
            for attempt in range(self.retry_count):
                response = self._cmd_IFS_F10(prutok, leng=config['filament_autoinsert_full_length'], speed=config['filament_autoinsert_speed'])
                success, ret_code, values = self.wait_for_state(
                     Port=prutok,
                     FFS_state=FFS_STATUS_ZAGRUZKA,
                     silk={'count': self.silk_count, 'status': False},
                     stall={'count': self.stall_count, 'status': False},
                     timeout=120
                )
                if ret_code!=RET_RETRY:
                    break
        else:
            self.gcode.respond_info("В экструдере нет прутка" if self.lang == 'ru' else "No filament in the extruder")
            for attempt in range(self.retry_count):
                response = self._cmd_IFS_F10(prutok, leng=config['filament_autoinsert_empty_length'], speed=config['filament_autoinsert_speed'])
                success, ret_code, values = self.wait_for_state(
                     Port=prutok,
                     FFS_state=FFS_STATUS_ZAGRUZKA,
                     silk={'count': self.silk_count, 'status': False},
                     stall={'count': self.stall_count, 'status': False},
                     extruder={'status': True},
                     timeout=120
                )
                if ret_code!=RET_RETRY:
                    break
        if not success:
            self.gcode.run_script_from_command("IFS_F112")
            self.print_result(ret_code, values, prutok)
            if ret_code == RET_EXTRUDER:
                # Втягиваем пруток
                gcmd_tmp = self.gcode.create_gcode_command("IFS_F11", "IFS_F11", {'PRUTOK': prutok, 'LEN': config["filament_autoinsert_ret_length"], 'SPEED': config["filament_autoinsert_speed"]})
                self.cmd_IFS_F11(gcmd_tmp)

        # Помечаем как вставленный
        gcmd_tmp = self.gcode.create_gcode_command("IFS_F23", "IFS_F23", {'PRUTOK': prutok})
        self.cmd_IFS_F23(gcmd_tmp)

        # Отжимаем пруток
        gcmd_tmp = self.gcode.create_gcode_command("IFS_F39", "IFS_F39", {'PRUTOK': prutok})
        self.cmd_IFS_F39(gcmd_tmp)

    def _cmd_IFS_F10(self, prutok, leng, speed):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        self.gcode.respond_info(f"Вставить пруток {prutok} длинной {leng} со скоростью {speed}" if self.lang == 'ru' else f"Insert filament {prutok} with length {leng} at speed {speed}")
        response = self.send_command_and_wait(f"F10 C{prutok} L{leng} S{speed}", result=f"F10 ok. FFS channel {prutok} feeding.")
        self.info(f"F10 C{prutok} L{leng} S{speed} > {response}")
        return response

    # Загрузить пруток
    def cmd_IFS_F10(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        prutok = gcmd.get_int('PRUTOK', 1)
        leng = gcmd.get_int('LEN', 90)
        speed = gcmd.get_int('SPEED', 1200)
        if speed == 0:
            self.print_str("Скорость не может быть = 0" if self.lang == 'ru' else "Speed cannot be = 0", False)
        wait = gcmd.get_int('WAIT', 1)
        check = gcmd.get_int('CHECK', 0)
        sleep = gcmd.get_int('SLEEP', 0)

        for attempt in range(self.retry_count):
            response = self._cmd_IFS_F10(prutok, leng, speed)
            if sleep == 1:
                # Ждем пока треть прутка пройдет
                self.reactor.pause(self.reactor.monotonic() + (leng * 20) // speed + 1)
                return
            if wait == 1:
                if check == 1:
                    success, ret_code, values = self.wait_for_state(
                        Port=prutok,
                        FFS_state=FFS_STATUS_ZAGRUZKA,
                        silk={'count': self.silk_count, 'status': False},
                        stall={'count': self.stall_count, 'status': False},
                        extruder={'status': True},
                        timeout=120
                    )
                    if ret_code==RET_RETRY:
                        continue
                    if ret_code == RET_EXTRUDER or self.get_extruder_sensor():
                        self.print_result(RET_EXTRUDER, values, prutok)
                    else:
                        self.print_result(ret_code, values, prutok, info=False)
                    if not success:
                        self.gcode.run_script_from_command("IFS_F112")
                else:
                    success, ret_code, values = self.wait_for_state(timeout=120)
                if ret_code!=RET_RETRY:
                    break
            else:
                break

    def _cmd_IFS_F11(self, prutok, leng, speed):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        self.gcode.respond_info(f"Извлечь пруток {prutok} длинной {leng} со скоростью {speed}" if self.lang == 'ru' else f"Extract filament {prutok} with length {leng} at speed {speed}")
        response = self.send_command_and_wait(f"F11 C{prutok} L{leng} S{speed}", result=f"F11 ok. FFS channel {prutok} exiting.")
        self.info(f"F11 C{prutok} L{leng} S{speed} > {response}")
        return response

    # Выгрузить пруток
    def cmd_IFS_F11(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        prutok = gcmd.get_int('PRUTOK', 1)
        leng = gcmd.get_int('LEN', 90)
        speed = gcmd.get_int('SPEED', 1200)
        wait = gcmd.get_int('WAIT', 1)
        check = gcmd.get_int('CHECK', 0)

        for attempt in range(self.retry_count):
            response = self._cmd_IFS_F11(prutok, leng, speed)
            if wait == 1:
                if check == 1:
                    success, ret_code, values = self.wait_for_state(
                        Port=prutok,
                        FFS_state=FFS_STATUS_VIGRUZKA,
                        silk={'count': self.silk_count, 'status': False},
                        stall={'count': self.stall_count, 'status': False},
                        extruder={'status': False},
                        timeout=120
                    )
                    if ret_code==RET_RETRY:
                        continue
                    self.gcode.run_script_from_command("IFS_F112")
                else:
                    success, ret_code, values = self.wait_for_state(timeout=120)
                if ret_code!=RET_RETRY:
                    break
            else:
                break

    # Пометить пруток как вставленный
    def cmd_IFS_F23(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        prutok = gcmd.get_int('PRUTOK', 1)
        wait = gcmd.get_int('WAIT', 1)

        self.gcode.respond_info(f"Помечаем пруток {prutok}" if self.lang == 'ru' else f"Marking filament {prutok}")

        for attempt in range(self.retry_count):
            response = self.send_command_and_wait(f"F23 C{prutok}", result=f"F23 ok. chan {prutok}.")
            self.info(f"F23 C{prutok} > {response}")
            if wait == 1:
                success, ret_code, values = self.wait_for_state()
                if ret_code!=RET_RETRY:
                    break
            else:
                break

    # Заблокировать пруток
    def cmd_IFS_F24(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        prutok = gcmd.get_int('PRUTOK', 1)
        wait = gcmd.get_int('WAIT', 1)

        self.gcode.respond_info(f"Блокировка прутка {prutok}" if self.lang == 'ru' else f"Locking filament {prutok}")
        for attempt in range(self.retry_count):
            response = self.send_command_and_wait(f"F24 C{prutok}", result=f"F24 ok. chan {prutok}.")
            self.info(f"F24 C{prutok} > {response}")
            if wait == 1:
                success, ret_code, values = self.wait_for_state()
                if ret_code!=RET_RETRY:
                    break
            else:
                break

    # Разблокировать пруток
    def cmd_IFS_F39(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        prutok = gcmd.get_int('PRUTOK', 1)
        wait = gcmd.get_int('WAIT', 1)

        self.gcode.respond_info(f"Разблокировка прутка {prutok}" if self.lang == 'ru' else f"Unlocking filament {prutok}")
        for attempt in range(self.retry_count):
            response = self.send_command_and_wait(f"F39 C{prutok}", result=f"F39 ok. FFS channel {prutok} release.")
            self.info(f"F39 C{prutok} > {response}")
            if wait == 1:
                success, ret_code, values = self.wait_for_state()
                if ret_code!=RET_RETRY:
                    break
            else:
                break

    # Сброс драйвера
    def cmd_IFS_F15(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        self.gcode.respond_info(f"Сброс драйвера" if self.lang == 'ru' else f"Driver reset")
        response = self.send_command_and_wait("F15 C", result="F15 ok.")
        self.info(f"F15 > {response}")

    # Разблокировать пруток ALL
    def cmd_IFS_F18(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        wait = gcmd.get_int('WAIT', 1)

        self.gcode.respond_info(f"Разблокировка всех прутков" if self.lang == 'ru' else f"Unlocking all filaments")
        for attempt in range(self.retry_count):
            response = self.send_command_and_wait("F18", result=f"F18 ok", timeout=10.0)
            self.info(f"F18 > {response}")
            if wait == 1:
                success, ret_code, values = self.wait_for_state()
                if ret_code!=RET_RETRY:
                    break
            else:
                break

    # Остановить движение
    def cmd_IFS_F112(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        wait = gcmd.get_int('WAIT', 0)

        self.gcode.respond_info(f"Принудительно останавливаю движение прутка" if self.lang == 'ru' else f"Force stop filament movement")

        for attempt in range(self.retry_count):
            response = self.send_command_and_wait(f"F112", result=("F112 ok.", "F112 ok. yes."))
            self.info(f"F112 > {response}")
            if wait == 1:
                success, ret_code, values = self.wait_for_state()
                if ret_code!=RET_RETRY:
                    break
            else:
                break

    # Статус
    def cmd_IFS_F13(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        response = self.send_command_and_wait("F13")
        self.print_str(f"F13 > {response}")

    cmd_IFS_STATUS_help = "Get current IFS status"
    def cmd_IFS_STATUS(self, gcmd):
        values = self.ifs_data.get_values()
        gcmd.respond_info(json.dumps(values))

    def cmd_IFS_EXTRUDER_SENSOR(self, gcmd):
        info = gcmd.get_int('INFO', 0)

        if self.get_extruder_sensor():
            self.print_str("Пруток в экструдере" if self.lang == 'ru' else "Filament in extruder")
        else:
            self.print_str("Пруток ОТСУСТВУЕТ в экструдере" if self.lang == 'ru' else "Filament ABSENT in extruder", info == 1)

    def cmd_IFS_REMOVE_PRUTOK(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        prutok = gcmd.get_int('PRUTOK', 0)
        force = gcmd.get_int('FORCE', 1)
        need_trash = gcmd.get_int('NEED_TRASH', 0)

        if (not self.get_extruder_sensor() and force == 0) or prutok == 0:
            return

        config=self.get_prutok_config(prutok)
        self.gcode.run_script_from_command(
            f"_IFS_REMOVE_PRUTOK "
            f"PRUTOK={prutok} "
            f"FORCE={force} "
            f"NEED_TRASH={need_trash} "
            f"TEMP={config['temp']} "
            f"FILAMENT_TYPE={config['filament_type']} "
            f"FILAMENT_UNLOAD_SPEED={config['filament_unload_speed']} "
            f"FILAMENT_LOAD_SPEED={config['filament_load_speed']} "
            f"FILAMENT_UNLOAD_BEFORE_CUTTING={config['filament_unload_before_cutting']} "
            f"FILAMENT_UNLOAD_AFTER_CUTTING={config['filament_unload_after_cutting']} "
            f"FILAMENT_UNLOAD_AFTER_DROP={config['filament_unload_after_drop']} "
            f"FILAMENT_TUBE_LENGTH={config['filament_tube_length']} "
            f"FILAMENT_DROP_LENGTH={config['filament_drop_length']} "
            f"FILAMENT_FAN_SPEED={config['filament_fan_speed']} "
            f"NOZZLE_CLEANING_LENGTH={config['nozzle_cleaning_length']} "
        )

        if self.get_extruder_sensor():
            self.info("Не удалось извлечь пруток из экструдера")
            self.gcode.run_script_from_command("IFS_F112")
            self.gcode.run_script_from_command("IFS_F18")
            raise self.gcode.error("Не удалось извлечь пруток из экструдера" if self.lang == 'ru' else "Failed to extract filament from extruder")
        else:
            gcmd.respond_info("Пруток извлечен из экструдера" if self.lang == 'ru' else "Filament extracted from extruder")

    def cmd_IFS_REMOVE_CURRENT_PRUTOK(self, gcmd):
        if not self.ifs:
            self.gcode.run_script_from_command("_IFS_OFF")
            return

        if not self.get_extruder_sensor():
            return

        temp = int(gcmd.get_float('TEMP', 0.0))
        need_trash = gcmd.get_int('NEED_TRASH', 0)

        prutok = self.get_current_channel_from_config()
        config = self.get_prutok_config(prutok)

        if temp < int(config['temp']):
            gcmd.respond_info(f"Extruder Temp: {config['temp']}")
            self.gcode.run_script_from_command(f"M104 S{config['temp']}")
            self.gcode.run_script_from_command(f"TEMPERATURE_WAIT SENSOR=extruder MINIMUM={config['temp']-2} MAXIMUM={config['temp']+4}")
        self.gcode.run_script_from_command(f"IFS_REMOVE_PRUTOK PRUTOK={prutok} FORCE=0 NEED_TRASH={need_trash}")

    def _sensor_reader(self):
        while not self.stop_thread:
            ser = None
            logging.info("IFS: Starting connection attempt...")
            try:
                logging.info(f"IFS: {PORT} opening")
                ser = serial.Serial(
                    port=PORT,
                    baudrate=BAUDRATE,
                    parity=PARITY,
                    stopbits=STOPBITS,
                    bytesize=BYTESIZE,
                    timeout=TIMEOUT
                )
                logging.info(f"IFS: {PORT} open")
                while not self.stop_thread:
                    with self._command_lock:
                        current_command = self._command
                    command_id = -1
                    if '#' in current_command:
                        command, command_id = current_command.split('#', 1)
                        command_id = int(command_id)
                    else:
                        command = current_command

                    ser.write((command + "\r\n").encode())
                    time.sleep(0.2)
                    ser.write(b'\xFF')

                    response = ser.readline().decode('utf-8', errors='ignore').strip()
                    #self._respond_info(f"IN: {response}")
                    if not response:
                        if self.ifs:
                            if self.lang == 'ru':
                                logging.warning(f"Пустой ответ от устройства {current_command}")
                                self._respond_info(f"Пустой ответ от устройства {current_command}")
                                logging.warning("IFS не доступен")
                                self._respond_info("IFS не доступен")
                            else:
                                logging.warning(f"Empty response from device {current_command}")
                                self._respond_info(f"Empty response from device {current_command}")
                                logging.warning("IFS is not available")
                                self._respond_info("IFS is not available")
                            self.reactor.register_async_callback(
                                lambda eventtime: self._safe_run_script("_IFS_OFF")
                            )
                            self.ifs = False
                        break
                    if not self.ifs:
                        if self.lang == 'ru':
                            logging.warning("IFS доступен")
                            self._respond_info("IFS доступен")
                        else:
                            logging.warning("IFS is available")
                            self._respond_info("IFS is available")
                        self.reactor.register_async_callback(
                            lambda eventtime: self._safe_run_script("_IFS_ON")
                        )
                        self.ifs = True

                    if command_id == -1:
                        self.ifs_data.update_from_string(response)
                        current_values = self.ifs_data.get_values()

                        #self._respond_info(response)
                        #self._respond_info(json.dumps(current_values))

                        # Безопасная обработка события вставки
                        if current_values['NeedInsert']:
                            prutok = current_values['Insert']
                            self.reactor.register_async_callback(
                                lambda eventtime, p=prutok: self._safe_run_script(f"_IFS_AUTOINSERT PRUTOK={p}")
                            )
                    else:
                        #self._respond_info(f"! {command} -> {response}")
                        with self._ret_command_lock:
                            self._ret_command_data = response
                            self._ret_command_id = command_id
                            with self._command_lock:
                                if command_id == self._command_id: # Если текущая команда последняя, то переходим в режим опроса
                                    self._command = "F13"
                    time.sleep(HOST_REPORT_TIME)
            except serial.SerialException as e:
                logging.warning("IFS: Serial communication error: %s", e)
                self._respond_info(f"IFS: sensor error: Serial communication error: {str(e)}")
            except Exception as e:
                logging.exception("IFS: Error data")
                self._error(f"IFS: sensor error: Error data: {str(e)}")
            finally:
                if ser and hasattr(ser, 'is_open') and ser.is_open:
                    try:
                        ser.close()
                        logging.info(f"IFS: {PORT} closed")
                    except Exception as e:
                        logging.warning("IFS: Error closing IFS serial port: %s", e)
                time.sleep(1)

class IfsData:
    def __init__(self):
        self.lock = threading.Lock()
        self.cur_port = 0       # Текущий активный порт
        self.Port1 = False      # Загрузка порта 1
        self.Port2 = False      # Загрузка порта 2
        self.Port3 = False      # Загрузка порта 3
        self.Port4 = False      # Загрузка порта 4
        self.Silk = 0           # Загруженные порты
        self.Chan = 0           # Текущий активный порт
        self.Insert = 0         # В каком порту появился филамент
        self.Stall = False      # Движение по любому порту
        self.Stalls = [False, False, False, False]
        self.stall_state = 0    # Движение по любому порту RAW
        self.State = 0          # Состояние IFS
        self.NeedInsert = False # Нужно ли вставлять пруток

    def update_from_string(self, data_str):
        if data_str is None:
            return

        silk_state = 0
        silk = 0
        chan = 0
        insert = 0
        stall_state = 0
        state = 0

        state_match = re.search(r'FFS_state:\s*(\d+)', data_str)
        if state_match:
            state = int(state_match.group(1))

        silk_match = re.search(r'silk_state:\s*(\d+)', data_str)
        if silk_match:
            silk_state = int(silk_match.group(1))
        port1 = (silk_state >> 0) & 1 == 1
        port2 = (silk_state >> 1) & 1 == 1
        port3 = (silk_state >> 2) & 1 == 1
        port4 = (silk_state >> 3) & 1 == 1

        chan_match = re.search(r'chan:\s*(\d+)', data_str)
        if chan_match:
            chan = int(chan_match.group(1))

        insert_match = re.search(r'ffs_channels_insert:\s*(\d+)', data_str)
        if insert_match:
            insert = int(insert_match.group(1))
            insert = insert.bit_length()

        stall_match = re.search(r'stall_state:\s*(\d+)', data_str)
        if stall_match:
            stall_state = int(stall_match.group(1))

        with self.lock:
            self.Port1 = port1
            self.Port2 = port2
            self.Port3 = port3
            self.Port4 = port4
            self.stall_state = stall_state
            if self.cur_port == 0:
                self.Stall = stall_state != 0
            else:
                self.Stall = (stall_state >> (self.cur_port - 1) ) & 1 == 1
            self.Stalls[0] = (stall_state >> 0 ) & 1 == 1
            self.Stalls[1] = (stall_state >> 1 ) & 1 == 1
            self.Stalls[2] = (stall_state >> 2 ) & 1 == 1
            self.Stalls[3] = (stall_state >> 3 ) & 1 == 1
            self.Silk = silk_state
            self.State = state
            self.Chan = chan
            self.NeedInsert = insert != 0 and insert != self.Insert and state == FFS_STATUS_READY
            self.Insert = insert

    def set_cur_port(self, port):
        with self.lock:
            if port < 0 or port > 4:
                self.cur_port = 0
            else:
                self.cur_port = port

    def get_stall(self, port):
        with self.lock:
            if port == 0:
                return self.Stall
            else:
                return self.Stalls[port-1]

    # Возвращает статус конкретного порта
    def get_port(self, port):
        with self.lock:
            if port == 1:
                return self.Port1
            if port == 2:
                return self.Port2
            if port == 3:
                return self.Port3
            if port == 4:
                return self.Port4
            return False

    def get_values(self):
        with self.lock:
            return {
                'State':  self.State,
                'Port1':  self.Port1,
                'Port2':  self.Port2,
                'Port3':  self.Port3,
                'Port4':  self.Port4,
                'Silk':   self.Silk,
                'Chan':   self.Chan,
                'Insert': self.Insert,
                'NeedInsert': self.NeedInsert,
                'Stall':  self.Stall,
                'stall_state': self.stall_state
            }


def load_config(config):
    return zmod_ifs(config)

