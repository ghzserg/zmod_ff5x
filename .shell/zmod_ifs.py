# (C) 2025 ghzserg https://github.com/ghzserg/zmod/
import json
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

FFS_STATUS_DELTA    = 11 # дельта от первой катушки
FFS_STATUS_OPROS    = 3  # Опрос катушек
FFS_STATUS_READY    = 5  # Готов к работе
FFS_STATUS_ZAGAT    = 7  # 18, 29, 40 поджата катушка
FFS_STATUS_ZAGRUZKA = 11 # 22, 33, 44 загрузка катушки
FFS_STATUS_VIGRUZKA = 15 # 26, 37, 48 выгрузка катушки
FFS_STATUS_OTZGAT   = 12 # 23, 34, 45 отжим катушки

RET_OK       = 0         # Все отработало штатно
RET_EXTRUDER = 1         # по сработке датчика экструдера
RET_SILK     = 2         # по сработке дачика прутка
RET_STALL    = 3         # по сработке движения прутка
RET_TIMEOUT  = 4         # Таймаут получения нужного статуса
RET_EXIT     = 5         # По завершению программы

class zmod_ifs:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.debug = config.getboolean('debug', False)
        self.reactor = self.printer.get_reactor()
        self.gcode = self.printer.lookup_object('gcode')
        self.query_adc = self.printer.lookup_object('query_adc')
        self.filament_sensor = self.printer.lookup_object('temperature_sensor filamentValue')
        self.language = 'en'
        self.zmod = self.printer.lookup_object('zmod', None)
        if self.zmod is not None:
            self.language = self.zmod.get_lang()
        self.ifs_data = IfsData()

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
        self.gcode.register_command('IFS_AUTOINSERT', self.cmd_IFS_AUTOINSERT, desc=self.cmd_IFS_AUTOINSERT_help)
        self.gcode.register_command('IFS_STATUS', self.cmd_IFS_STATUS, desc=self.cmd_IFS_STATUS_help)
        self.gcode.register_command('IFS_EXTRUDER_SENSOR', self.cmd_IFS_EXTRUDER_SENSOR)
        self.gcode.register_command('IFS_REMOVE_PRUTOK', self.cmd_IFS_REMOVE_PRUTOK)
        self.gcode.register_command('IFS_REMOVE_CURRENT_PRUTOK', self.cmd_IFS_REMOVE_CURRENT_PRUTOK)

        self.gcode.register_command('IFS_F10', self.cmd_IFS_F10)        # Вставить пруток
        self.gcode.register_command('IFS_F11', self.cmd_IFS_F11)        # Извлечь пруток
        self.gcode.register_command('IFS_F23', self.cmd_IFS_F23)        # Помечаем пруток как вставленный
        self.gcode.register_command('IFS_F24', self.cmd_IFS_F24)        # Прижим филамента
        self.gcode.register_command('IFS_F39', self.cmd_IFS_F39)        # Отжим филамента
        self.gcode.register_command('IFS_F112', self.cmd_IFS_F112)      # Прекращаем подачу прутка

    # self.wait_for_state(
    #     Port=2,
    #     FFS_state=FFS_STATUS_ZAGRUZKA,
    #     silk={'count': 3, 'status': True},
    #     stall={'count': 3, 'status': True},
    #     extruder={'count': 1, 'status': True},
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
        silk_count = stall_count = extruder_count = 0

        while not self.stop_thread:
            # Запрос статуса
            response = self.send_command_and_wait("F13")
            self.ifs_data.update_from_string(response)
            current_values = self.ifs_data.get_values()
            state = current_values['State']
            self.info(f"F13 {state}?5?{check_state} > {response}")

            # Проверка что статус готов
            if state == FFS_STATUS_READY:
                return True, RET_OK, current_values

            if state == check_state:          # ждем сработки нужного статуса
                if extruder and self.get_extruder_sensor() == extruder['status']: # Проверяем сработку датчика в экструдере
                    extruder_count += 1
                    if extruder_count >= extruder['count']:
                        return False, RET_EXTRUDER, current_values
                else:
                    extruder_count = 0
                if silk and Port != 0:        # проверяем наличие прутка
                    current_silk = current_values['Silk']
                    if ((current_silk >> (Port - 1)) & 1 == 1) == silk['status']:
                        silk_count += 1
                        if silk_count >= silk['count']:
                            return False, RET_SILK, current_values
                    else:
                        silk_count = 0
                if stall and Port != 0:        # проверяем движение прутка
                    current_stall = current_values['Stall']
                    if ((current_stall >> (Port - 1)) & 1 == 1) == stall['status']:
                        stall_count += 1
                        if stall_count >= stall['count']:
                            return False, RET_STALL, current_values
                    else:
                        stall_count = 0
            if self.reactor.monotonic() - start_time > timeout:
                raise self.gcode.error(f"IFS: Вышло время для получения статуса {state}")
                return False, RET_TIMEOUT, current_values

            self.reactor.pause(self.reactor.monotonic() + HOST_REPORT_TIME)
        return False, RET_EXIT, None

    def _handle_ready(self):
        self.sensor_thread.start()

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

    def getlang(self):
        if self.zmod is None:
            self.language = 'en'
            self.zmod = self.printer.lookup_object('zmod', None)
            if self.zmod is not None:
                self.language = self.zmod.get_lang()

    def get_extruder_sensor(self):
        value, timestamp = self.query_adc.adc["temperature_sensor filamentValue"].get_last_value()
        result = True
        if value > 0.3:
            result = (value >= 0.72)
        return result

    def get_ifs_sensor(self):
        return self.ifs_data.get_stall()

    def send_command_and_wait(self, command, timeout=5.0, result=None):
        """
        Отправляет команду и возвращает ответ.
        :param command: Команда для отправки (например, "H1").
        :param timeout: Таймаут ожидания ответа.
        :return: Ответ от датчика или None при таймауте.
        """
        with self._command_lock:
            self._command_id += 1
            command_id = self._command_id  # Уникальный ID команды
            self._command = f"{command}#{command_id}"
        start_time = eventtime = self.reactor.monotonic()

        while not self.stop_thread:
            eventtime = self.reactor.pause(eventtime + HOST_REPORT_TIME)
            with self._ret_command_lock:
                ret_command_data=self._ret_command_data
                ret_command_id=self._ret_command_id
            if command_id ==ret_command_id:
                if result is not None:
                    if result==ret_command_data:
                        return ret_command_data
                    else:
                        raise self.gcode.error(f"{command}#{command_id} ret {ret_command_data} != {result}")
                        return None
                else:
                    return self._ret_command_data
            if eventtime - start_time > timeout:
                raise self.gcode.error(f"Таймаут ожидания ответа от команды {command}#{command_id}")
                return None
        return None

    def get_command(self):
        with self._command_lock:
            return self._command

    def set_command(self, new_command):
        with self._command_lock:
            self._command = f"{new_command}"

    def get_port(self, port=0):
        return self.ifs_data.get_port(port)

    def print_str(self, string, info=True):
        if info:
            self.gcode.respond_info(string)
        else:
            raise self.gcode.error(string)

    def print_result(self, ret_code, values, info=True):
        if ret_code == RET_OK:
            self.print_str("IFS в режиме готовности")
        elif ret_code == RET_EXTRUDER:
            self.print_str("Сработал датчик экструдера", info)
        elif ret_code == RET_SILK:
            self.print_str("Сработал датчик прутка", info)
        elif ret_code == RET_STALL:
            self.print_str("Сработала остановка прутка", info)
        elif ret_code == RET_TIMEOUT:
            self.print_str("Превышено время ожидания", info)
        elif ret_code == RET_EXIT:
            self.print_str("Завершение программы")
        else:
            self.print_str("Неизвестный код завершения", info)

    def _safe_run_script(self, script):
        try:
            self.gcode.run_script_from_command(script)
        except self.gcode.error as e:
            #self.info(f"Ошибка в асинхронном вызове {script}: {e}")
            pass

    cmd_IFS_AUTOINSERT_help = "Автоматическая загрузка филамента"
    def cmd_IFS_AUTOINSERT(self, gcmd):
        prutok = gcmd.get_int('PRUTOK', 1)

        self.gcode.respond_info(f"Автоматическая вставка прутка {prutok}")
        self.wait_for_state()

        # Прижим прутка
        gcmd = self.gcode.create_gcode_command("IFS_F24", "IFS_F24", {'PRUTOK': prutok})
        self.cmd_IFS_F24(gcmd)

        # Затягиваем пруток
        response = self._cmd_IFS_F10(prutok, leng=600, speed=1200)
        # Проверяем надо ли втягивать
        if self.get_extruder_sensor():
            self.gcode.respond_info("В экструдере есть пруток")
            success, ret_code, values = self.wait_for_state(
                 Port=prutok,
                 FFS_state=FFS_STATUS_ZAGRUZKA,
                 silk={'count': 3, 'status': False},
                 stall={'count': 3, 'status': False},
                 timeout=120
            )
        else:
            self.gcode.respond_info("В экструдере нет прутка")
            success, ret_code, values = self.wait_for_state(
                 Port=prutok,
                 FFS_state=FFS_STATUS_ZAGRUZKA,
                 silk={'count': 3, 'status': False},
                 stall={'count': 3, 'status': False},
                 extruder={'count': 1, 'status': True},
                 timeout=120
            )
        if not success:
            gcmd = self.gcode.create_gcode_command("IFS_F112", "IFS_F112", {})
            self.cmd_IFS_F112(gcmd)
            self.print_result(ret_code, values)
            if ret_code == RET_EXTRUDER:
                # Втягиваем пруток
                gcmd = self.gcode.create_gcode_command("IFS_F11", "IFS_F11", {'PRUTOK': prutok, 'LEN': 90, 'SPEED': 1200})
                self.cmd_IFS_F11(gcmd)

        # Помечаем как вставленный
        gcmd = self.gcode.create_gcode_command("IFS_F23", "IFS_F23", {'PRUTOK': prutok})
        self.cmd_IFS_F23(gcmd)

        # Отжимаем пруток
        gcmd = self.gcode.create_gcode_command("IFS_F39", "IFS_F39", {'PRUTOK': prutok})
        self.cmd_IFS_F39(gcmd)

    def _cmd_IFS_F10(self, prutok, leng, speed):
        self.gcode.respond_info(f"Вставить пруток {prutok} длинной {leng} со скоростью {speed}")
        response = self.send_command_and_wait(f"F10 C{prutok} L{leng} S{speed}", result=f"F10 ok. FFS channel {prutok} feeding.")
        self.info(f"F10 C{prutok} L{leng} S{speed} > {response}")
        return response

    # Загрузить пруток
    def cmd_IFS_F10(self, gcmd):
        prutok = gcmd.get_int('PRUTOK', 1)
        leng = gcmd.get_int('LEN', 90)
        speed = gcmd.get_int('SPEED', 1200)
        if speed==0:
            self.print_str("Скорость не может быть = 0", False)
        wait = gcmd.get_int('WAIT', 1)
        check = gcmd.get_int('CHECK', 0)
        sleep = gcmd.get_int('SLEEP', 0)

        response = self._cmd_IFS_F10(prutok, leng, speed)
        if sleep==1:
            # Ждем пока треть прутка пройдет
            self.reactor.pause(self.reactor.monotonic() + (leng * 20) // speed + 1)
            return
        if wait==1:
            if check==1:
                success, ret_code, values = self.wait_for_state(
                    Port=prutok,
                    FFS_state=FFS_STATUS_ZAGRUZKA,
                    silk={'count': 3, 'status': False},
                    stall={'count': 3, 'status': False},
                    extruder={'count': 1, 'status': True},
                    timeout=120
                )
                if not success:
                    gcmd = self.gcode.create_gcode_command("IFS_F112", "IFS_F112", {})
                    self.cmd_IFS_F112(gcmd)
                if ret_code == RET_EXTRUDER:
                    self.print_result(ret_code, values)
                else:
                    self.print_result(ret_code, values, info=False)
            else:
                self.wait_for_state(timeout=120)

    def _cmd_IFS_F11(self, prutok, leng, speed):
        self.gcode.respond_info(f"Извлечь пруток {prutok} длинной {leng} со скоростью {speed}")
        response = self.send_command_and_wait(f"F11 C{prutok} L{leng} S{speed}", result=f"F11 ok. FFS channel {prutok} exiting.")
        self.info(f"F11 C{prutok} L{leng} S{speed} > {response}")
        return response

    # Выгрузить пруток
    def cmd_IFS_F11(self, gcmd):
        prutok = gcmd.get_int('PRUTOK', 1)
        leng = gcmd.get_int('LEN', 90)
        speed = gcmd.get_int('SPEED', 1200)
        wait = gcmd.get_int('WAIT', 1)
        check = gcmd.get_int('CHECK', 0)

        response = self._cmd_IFS_F11(prutok, leng, speed)
        if wait==1:
            if check==1:
                success, ret_code, values = self.wait_for_state(
                    Port=prutok,
                    FFS_state=FFS_STATUS_VIGRUZKA,
                    silk={'count': 3, 'status': False},
                    stall={'count': 3, 'status': False},
                    extruder={'count': 1, 'status': True},
                    timeout=120
                )
                gcmd = self.gcode.create_gcode_command("IFS_F112", "IFS_F112", {})
                self.cmd_IFS_F112(gcmd)
            else:
                self.wait_for_state(timeout=120)

    # Пометить пруток как вставленный
    def cmd_IFS_F23(self, gcmd):
        prutok = gcmd.get_int('PRUTOK', 1)
        wait = gcmd.get_int('WAIT', 1)

        self.gcode.respond_info(f"Помечаем пруток {prutok}")

        response = self.send_command_and_wait(f"F23 C{prutok}", result=f"F23 ok. chan {prutok}.")
        self.info(f"F23 C{prutok} > {response}")
        if wait==1:
            self.wait_for_state()

    # Заблокировать пруток
    def cmd_IFS_F24(self, gcmd):
        prutok = gcmd.get_int('PRUTOK', 1)
        wait = gcmd.get_int('WAIT', 1)

        self.gcode.respond_info(f"Блокировка прутка {prutok}")
        response = self.send_command_and_wait(f"F24 C{prutok}", result=f"F24 ok. chan {prutok}.")
        self.info(f"F24 C{prutok} > {response}")
        if wait==1:
            self.wait_for_state()

    # Разблокировать пруток
    def cmd_IFS_F39(self, gcmd):
        prutok = gcmd.get_int('PRUTOK', 1)
        wait = gcmd.get_int('WAIT', 1)

        self.gcode.respond_info(f"Разблокировка прутка {prutok}")
        response = self.send_command_and_wait(f"F39 C{prutok}", result=f"F39 ok. FFS channel {prutok} release.")
        self.info(f"F39 C{prutok} > {response}")
        if wait==1:
            self.wait_for_state()

    # Остановить движение
    def cmd_IFS_F112(self, gcmd):
        wait = gcmd.get_int('WAIT', 0)

        response = self.send_command_and_wait(f"F112", result="F112 ok.")
        self.gcode.respond_info(f"Остановка движения прутка")
        self.info(f"F112 > {response}")
        if wait==1:
            self.wait_for_state()

    cmd_IFS_STATUS_help = "Get current IFS status"
    def cmd_IFS_STATUS(self, gcmd):
        values = self.ifs_data.get_values()
        gcmd.respond_info(json.dumps(values))

    def cmd_IFS_EXTRUDER_SENSOR(self, gcmd):
        info = gcmd.get_int('INFO', 0)

        if self.get_extruder_sensor():
            self.print_str("Пруток в экструдере")
        else:
            self.print_str("Пруток ОТСУСТВУЕТ в экструдере", info == 1)

    def cmd__IFS_REMOVE_PRUTOK(self, gcmd, prutok, force):
        if (not self.get_extruder_sensor() and force == 0) or prutok == 0:
            return

        gcmd.respond_info(f"Извлекаю пруток {prutok} из экструдера")
        self.gcode.run_script_from_command("_REZGEM_PRUTOK")
        self.gcode.run_script_from_command("_GOTO_KAKASHNIK")
        self.gcode.run_script_from_command(f"IFS_F24 PRUTOK={prutok}")

        self.gcode.run_script_from_command("G92 E0")
        self.gcode.run_script_from_command("G1 E-60 F600")
        self.gcode.run_script_from_command(f"IFS_F11 PRUTOK={prutok} LEN=100 SPEED=1200 WAIT=0")
        self.gcode.run_script_from_command("M400")

        if self.get_extruder_sensor():
            raise self.gcode.error("Не удалось извлечь пруток из экструдера")
        else:
            gcmd.respond_info("Пруток извлечен из экструдера")

    def cmd_IFS_REMOVE_PRUTOK(self, gcmd):
        prutok = gcmd.get_int('PRUTOK', 0)
        force = gcmd.get_int('FORCE', 1)
        self.cmd__IFS_REMOVE_PRUTOK(gcmd, prutok, force)

    def cmd_IFS_REMOVE_CURRENT_PRUTOK(self, gcmd):
        if not self.get_extruder_sensor():
            return

        values = self.ifs_data.get_values()
        prutok = values['Chan']

        with open('/usr/data/config/Adventurer5M.json', 'r') as file:
            config = json.load(file)
            prutok = config["FFMInfo"].get("channel", 0)

        self.cmd__IFS_REMOVE_PRUTOK(gcmd, prutok, 0)
        if values['Port1']:
            self.cmd__IFS_REMOVE_PRUTOK(gcmd, 1, 0)
        if values['Port2']:
            self.cmd__IFS_REMOVE_PRUTOK(gcmd, 2, 0)
        if values['Port3']:
            self.cmd__IFS_REMOVE_PRUTOK(gcmd, 3, 0)
        if values['Port4']:
            self.cmd__IFS_REMOVE_PRUTOK(gcmd, 4, 0)

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
                    current_command = self.get_command()
                    command_id = -1
                    if '#' in current_command:
                        command, command_id = current_command.split('#', 1)
                        command_id = int(command_id)
                    else:
                        command = current_command

                    ser.write(command.encode())
                    ser.write(b'\r\n')
                    time.sleep(0.2)
                    ser.write(b'\xFF')

                    response = ser.readline().decode('utf-8', errors='ignore').strip()
                    #self._respond_info(f"IN: {response}")
                    if not response:
                        if command_id == -1:
                            continue;
                        else:
                            logging.warning(f"Пустой ответ от устройства {current_command}")
                            break

                    if command_id == -1:
                        self.ifs_data.update_from_string(response)
                        current_values = self.ifs_data.get_values()

                        #self._respond_info(response)
                        #self._respond_info(json.dumps(current_values))

                        # Безопасная обработка события вставки
                        if current_values['NeedInsert']:
                            prutok = current_values['Insert']
                            self.reactor.register_async_callback(
                                lambda eventtime, p=prutok: self._safe_run_script(f"IFS_AUTOINSERT PRUTOK={p}")
                            )
                    else:
                        #self._respond_info(f"! {command} -> {response}")
                        with self._ret_command_lock:
                            self._ret_command_data = response
                            self._ret_command_id = command_id
                        with self._command_lock:
                            self._command = "F13"
                    time.sleep(HOST_REPORT_TIME)
            except serial.SerialException as e:
                logging.warning("IFS: Serial communication error: %s", e)
                self._respond_info(f"IFS: sensor error: {str(e)}")
            except Exception as e:
                logging.exception("IFS: Error data")
                self._error(f"IFS: sensor error: {str(e)}")
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
        self.Port1 = False      # Загрузка порта 1
        self.Port2 = False      # Загрузка порта 2
        self.Port3 = False      # Загрузка порта 3
        self.Port4 = False      # Загрузка порта 4
        self.Silk = 0           # Загруженные порты
        self.Chan = 0           # Текущий активный порт
        self.Insert = 0         # В каком порту появился филамент
        self.Stall = 0          # Скорость движения нити
        self.State = 0          # Состояние IFS
        self.NeedInsert = False # Нужно ли вставлять пруток

    def update_from_string(self, data_str):
        if data_str is None:
            return;

        silk_state = 0
        silk = 0
        chan = 0
        insert = 0
        stall = 0
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
            stall = int(stall_match.group(1))

        with self.lock:
            self.Port1 = port1
            self.Port2 = port2
            self.Port3 = port3
            self.Port4 = port4
            self.Silk = silk_state
            self.State = state
            self.Chan = chan
            self.NeedInsert = insert != 0 and insert != self.Insert and state == FFS_STATUS_READY
            self.Insert = insert
            self.Stall = stall

    def get_stall(self):
        with self.lock:
            return self.Stall != 0

    def get_port(self, port):
        with self.lock:
            if port==1:
                return self.Port1
            if port==2:
                return self.Port2
            if port==3:
                return self.Port3
            if port==4:
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
                'Stall':  self.Stall
            }


def load_config(config):
    return zmod_ifs(config)
