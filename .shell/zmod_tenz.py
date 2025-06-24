# (C 2025) ghzserg https://github.com/ghzserg/zmod/ 
# (C 2025) @FishingSoulFT
# (C 2024-2025) VoronKor https://github.com/VoronKor/tensistor_board_adm5
import serial
import time
import threading
import logging
from functools import partial

# Параметры порта
port = '/dev/ttyS7'
baudrate = 9600
HOST_REPORT_TIME = 0.2

class zmod_tenz:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.reactor = self.printer.get_reactor()
        self.name = config.get_name().split()[-1]
        self.temp = self.min_temp = self.max_temp = 0.0
        self.printer.add_object("temperature_load " + self.name, self)
        self._command = "H7"
        self.command_lock = threading.Lock()
        self.response_condition = threading.Condition()  # Условная переменная для ожидания ответов
        self.pending_responses = {}  # Хранение ожидаемых ответов {command_id: response}
        self.command_counter = 0  # Счетчик для уникальных ID команд

        self.stop_thread = False  # Флаг для остановки потока
        self.sensor_thread = threading.Thread(target=self._sensor_reader)
        self.sensor_thread.daemon = True  # Поток завершится при выходе из программы
        self.sensor_thread.start()

        self.zcontrol = 0
        self.zcommand = 0
        self.printer.load_object(config, 'pause_resume')
        self.gcode = self.printer.lookup_object('gcode')
        self.gcode.register_command('ZCONTROL_ON', self.cmd_ZCONTROL_ON)
        self.gcode.register_command('ZCONTROL_PAUSE', self.cmd_ZCONTROL_PAUSE)
        self.gcode.register_command('ZCONTROL_ABORT', self.cmd_ZCONTROL_ABORT)
        self.gcode.register_command('ZCONTROL_STATUS', self.cmd_ZCONTROL_STATUS)
        self.gcode.register_command('ZCONTROL_OFF', self.cmd_ZCONTROL_OFF)

        self.gcode.register_command('H1', self.cmd_H1)
        self.gcode.register_command('H2', self.cmd_H2)
        self.gcode.register_command('H3', self.cmd_H3)
        self.gcode.register_command('H7', self.cmd_H7)
        self.gcode.register_command('_LOAD_CELL_TARE', self.cmd_LOAD_CELL_TARE)

        self.zmod = self.printer.lookup_object('zmod', None)
        self.language = 'en'
        if self.zmod is not None:
            self.language = self.zmod.get_lang()

    def send_command_and_wait(self, command, timeout=5.0):
        """
        Отправляет команду и возвращает ответ.
        :param command: Команда для отправки (например, "H1").
        :param timeout: Таймаут ожидания ответа.
        :return: Ответ от датчика или None при таймауте.
        """
        with self.command_lock:
            self.command_counter += 1
            command_id = self.command_counter  # Уникальный ID команды

        # Сохранение ожидаемого ответа
        with self.response_condition:
            self.pending_responses[command_id] = None
            self.set_command(f"{command}#{command_id}")  # Добавление ID к команде

        # Ожидание ответа
        with self.response_condition:
            waited = self.response_condition.wait(timeout)
            if not waited or self.pending_responses[command_id] is None:
                with self.command_lock:
                    del self.pending_responses[command_id]
                return None

            response = self.pending_responses[command_id]
            with self.command_lock:
                del self.pending_responses[command_id]
            return response

    def get_command(self):
        """Безопасное получение текущей команды"""
        with self.command_lock:
            return self._command

    def set_command(self, new_command):
        """Безопасное изменение команды"""
        with self.command_lock:
            self._command = new_command

    def cmd_LOAD_CELL_TARE(self, gcmd):
        max_attempts = 10
        attempt = 0

        while attempt < max_attempts:
            attempt += 1
            self.cmd_H1(gcmd)  # Вызов команды H1 для сброса веса
            self.gcode.respond_info(f"N {attempt}. Weight: {self.temp}")

            if abs(self.temp) < 200:
                self.gcode.respond_info(f"Cell Tare: OK. Weight: {self.temp}")
                return

            time.sleep(0.5)  # Пауза между попытками

        # Вывод ошибки через action_raise_error
        error_msg = f"Cell Tare: Error. Weight: {self.temp} https://github.com/ghzserg/zmod/wiki/FAQ" 
        raise self.gcode.error(error_msg)  # Прерывает выполнение макроса и выводит ошибку

    def cmd_H1(self, gcmd):
        current_command = "H1"
        message=self.send_command_and_wait(current_command)
        self.gcode.respond_info(f"{current_command} > {message}")

    def cmd_H2(self, gcmd):
        current_command = "H2 S500"
        message=self.send_command_and_wait(current_command)
        self.gcode.respond_info(f"{current_command} > {message}")

    def cmd_H3(self, gcmd):
        current_command = "H3 S200"
        message=self.send_command_and_wait(current_command)
        self.gcode.respond_info(f"{current_command} > {message}")

    def cmd_H7(self, gcmd):
        current_command = "H7"
        message=self.send_command_and_wait(current_command)
        self.gcode.respond_info(f"{current_command} > {message}")

    def _zcontrol(self, measured_time, cur_temp):
        # Логика PAUSE
        if self.zcommand == 1:
            msg = (
                f"!! Nozzle hit bed or part detachment. Weight {cur_temp}. PAUSE. https://github.com/ghzserg/zmod/wiki/Global_en#nozzle_control"
                if self.language != 'ru'
                else f"!! Удар сопла о стол или отрыв детали. Вес {cur_temp}. PAUSE. https://github.com/ghzserg/zmod/wiki/Global_ru#nozzle_control"
            )
            self.gcode.respond_raw(msg)

            pause_resume = self.printer.lookup_object('pause_resume')

            def async_pause(eventtime):
                pause_resume.send_pause_command()
                self.gcode.run_script_from_command("PAUSE\nM400\n")
                return measured_time + HOST_REPORT_TIME

            self.reactor.register_callback(async_pause)
        else: # SHUTDOWN
            shutdown_msg = (
                f"Nozzle hit bed or part detachment. Weight {cur_temp}. FIRMWARE_RESTART. https://github.com/ghzserg/zmod/wiki/Global_en#nozzle_control"
                if self.language != 'ru'
                else f"Удар сопла о стол или отрыв детали. Вес {cur_temp}. FIRMWARE_RESTART. https://github.com/ghzserg/zmod/wiki/Global_ru#nozzle_control"
            )
            self.stop_thread = True
            self.printer.invoke_async_shutdown(shutdown_msg, shutdown_msg)

    def _sensor_reader(self):
        """Поток для чтения данных с датчика"""
        mcu = self.printer.lookup_object('mcu')
        while not self.stop_thread:
            try:
                ser = serial.Serial(port, baudrate, timeout=1)
                while not self.stop_thread:
                    current_command = self.get_command()

                    command_id = -1
                    # Проверка формата команды (например, "H1#123")
                    if '#' in current_command:
                        command, command_id = current_command.split('#', 1)
                        command_id = int(command_id)
                    else:
                        command = current_command

                    ser.write(command.encode())
                    time.sleep(0.05)

                    # Чтение ответа
                    response = ser.readline().decode('utf-8').rstrip()

                    if command_id == -1:
                        message = response.split()
                        if len(message) >= 5:
                            cur_temp = abs(float(message[4]))
                            measured_time = self.reactor.monotonic()
                            self.temp = cur_temp
                            self._callback(mcu.estimated_print_time(measured_time), cur_temp)
                            if self.max_temp != 2048 and self.zcontrol == 1 and cur_temp > self.max_temp:
                                self._zcontrol(measured_time, cur_temp)
                    else:
                        # Сохранение ответа для соответствующей команды
                        with self.response_condition:
                            self.pending_responses[command_id] = response
                            self.response_condition.notify_all()
                        self.set_command("H7")

                    time.sleep(HOST_REPORT_TIME)
            except Exception as e:
                ser.close()
                self.temp = -200
                measured_time = self.reactor.monotonic()
                self._callback(mcu.estimated_print_time(measured_time), -200)
                logging.exception("temperature_load: Sensor thread error")
            finally:
                ser.close()

    def setup_minmax(self, min_temp, max_temp):
        self.min_temp = min_temp
        self.max_temp = max_temp

    def get_report_time_delta(self):
        return HOST_REPORT_TIME

    def setup_callback(self, cb):
        self._callback = cb

    def getlang(self):
        if self.zmod is None:
            self.language = 'en'
            self.zmod = self.printer.lookup_object('zmod', None)
            if self.zmod is not None:
                self.language = self.zmod.get_lang()

    def cmd_ZCONTROL_ON(self, gcmd):
        if self.max_temp != 2048 and self.zcontrol == 0:
            status_msg = f"ZCONTROL_ON. {self.max_temp}. {'PAUSE' if self.zcommand == 1 else 'ABORT'}"
            gcmd.respond_info(status_msg)
        self.zcontrol = 1

    def cmd_ZCONTROL_OFF(self, gcmd):
        if self.max_temp != 2048 and self.zcontrol == 1:
            status_msg = "ZCONTROL_OFF"
            gcmd.respond_info(status_msg)
        self.zcontrol = 0

    def cmd_ZCONTROL_PAUSE(self, gcmd):
        if self.max_temp != 2048 and self.zcommand == 0:
            status_msg = f"{'ZCONTROL_ON' if self.zcontrol == 1 else 'ZCONTROL_OFF'}. {self.max_temp}. PAUSE"
        self.zcommand = 1

    def cmd_ZCONTROL_ABORT(self, gcmd):
        if self.max_temp != 2048 and self.zcommand == 1:
            status_msg = f"{'ZCONTROL_ON' if self.zcontrol == 1 else 'ZCONTROL_OFF'}. {self.max_temp}. ABORT"
        self.zcommand = 0

    def cmd_ZCONTROL_STATUS(self, gcmd):
        self.getlang()
        if self.max_temp == 2048:
            if self.language != 'ru':
                msg = "Weight control is not configured. // To configure: NOZZLE_CONTROL WEIGHT=1500"
            else:
                msg = "Контроль веса не настроен. // Для настройки: NOZZLE_CONTROL WEIGHT=1500"
            gcmd.respond_info(msg)
        else:
            if self.zcontrol == 1:
                if self.language != 'ru':
                    status_msg = "Weight: %d; Control is configured and active." % self.max_temp
                else:
                    status_msg = "Вес: %d; Контроль настроен и активен." % self.max_temp
            else:
                if self.language != 'ru':
                    status_msg = "Weight: %d; Control is configured but inactive." % self.max_temp
                else:
                    status_msg = "Вес: %d; Контроль настроен и не активен." % self.max_temp
            gcmd.respond_info(status_msg)

            if self.zcommand == 1:
                if self.language != 'ru':
                    action_msg = "PAUSE is triggered when activated. // ZCONTROL_PAUSE"
                else:
                    action_msg = "При сработке вызывается PAUSE. // ZCONTROL_PAUSE"
            else:
                if self.language != 'ru':
                    action_msg = "Klipper is disabled when triggered. // ZCONTROL_ABORT"
                else:
                    action_msg = "При сработке отключается Klipper. // ZCONTROL_ABORT"
            gcmd.respond_info(action_msg)

    def __del__(self):
        self.stop_thread = True
        with self.response_condition:
            self.response_condition.notify_all()  # Прерывание ожидания при завершении
        if self.sensor_thread.is_alive():
            self.sensor_thread.join(timeout=1.0)

def load_config(config):
    # Register sensor
    pheaters = config.get_printer().load_object(config, "heaters")
    pheaters.add_sensor_factory("temperature_load", zmod_tenz)
