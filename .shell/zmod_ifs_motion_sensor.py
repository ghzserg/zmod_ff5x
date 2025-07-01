# zmod_ifs_motion_sensor.py
# Copyright (C) 2025 ghzserg https://github.com/ghzserg/zmod  

from .filament_switch_sensor import RunoutHelper

CHECK_RUNOUT_TIMEOUT = 0.250

class ZmodIfsMotionSensor:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.name = config.get_name().split()[-1]

        # Получаем объект zmod_ifs
        self.ifs = self.printer.lookup_object('zmod_ifs')

        # Параметры датчика
        self.extruder_name = config.get('extruder', 'extruder')
        self.detection_length = config.getfloat('detection_length', 8.0, above=0.0)

        # Инициализируем RunoutHelper
        self.runout_helper = RunoutHelper(config)

        # Инициализация экструдера и времени
        self.reactor = self.printer.get_reactor()
        self.extruder = None
        self.estimated_print_time = None  # Задаём позже

        # Таймер для проверки движения
        self.timer = self.reactor.register_timer(self._extruder_pos_update_event, self.reactor.NEVER)

        # Регистрация объекта
        self.printer.add_object(f"filament_motion_sensor {self.name}", self)

        # Регистрация событий
        self.printer.register_event_handler('klippy:ready', self._handle_ready)
        self.printer.register_event_handler('idle_timeout:printing', self._handle_printing)
        self.printer.register_event_handler('idle_timeout:ready', self._handle_not_printing)
        self.printer.register_event_handler('idle_timeout:idle', self._handle_not_printing)

    def _handle_ready(self):
        """Обработчик события klippy:ready"""
        self.extruder = self.printer.lookup_object(self.extruder_name)
        # Сохраняем ссылку на функцию, а не её результат
        self.estimated_print_time = self.printer.lookup_object('mcu').estimated_print_time
        self._update_filament_runout_pos()
        self.runout_helper.note_filament_present(True)
        self.reactor.update_timer(self.timer, self.reactor.NOW)

    def _update_filament_runout_pos(self, eventtime=None):
        if eventtime is None:
            eventtime = self.reactor.monotonic()
        self.filament_runout_pos = (
            self._get_extruder_pos(eventtime) +
            self.detection_length
        )

    def _get_extruder_pos(self, eventtime=None):
        if eventtime is None:
            eventtime = self.reactor.monotonic()

        print_time = self.estimated_print_time(eventtime)
        return self.extruder.find_past_position(print_time)

    def _extruder_pos_update_event(self, eventtime):
        extruder_pos = self._get_extruder_pos(eventtime)

        # Получаем статус филамента из zmod_ifs
        filament_present = self.ifs.get_ifs_sensor()

        if filament_present:
            self._update_filament_runout_pos(eventtime)
            self.runout_helper.note_filament_present(True)
        else:
            if extruder_pos < self.filament_runout_pos:
                self.runout_helper.note_filament_present(False)

        return eventtime + CHECK_RUNOUT_TIMEOUT

    def _handle_printing(self, print_time):
        self.reactor.update_timer(self.timer, self.reactor.NOW)

    def _handle_not_printing(self, print_time):
        self.reactor.update_timer(self.timer, self.reactor.NEVER)

    def get_status(self, eventtime):
        return self.runout_helper.get_status(eventtime)

def load_config_prefix(config):
    return ZmodIfsMotionSensor(config)
