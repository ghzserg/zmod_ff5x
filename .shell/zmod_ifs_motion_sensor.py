# IFS Filament Motion Sensor Module
#
# Copyright (C) 2021 Joshua Wherrett <thejoshw.code@gmail.com>
# Copyright (C) 2025 ghzserg https://github.com/ghzserg/zmod
#
# This file may be distributed under the terms of the GNU GPLv3 license.
import logging
import inspect
from . import filament_switch_sensor

CHECK_RUNOUT_TIMEOUT = .250

class ZmodIfsMotionSensor:
    def __init__(self, config):
        self.name = config.get_name().split()[-1]
        # Read config
        self.printer = config.get_printer()
        self.extruder_name = config.get('extruder', 'extruder')
        self.detection_length = config.getfloat(
                'detection_length', 10., above=0.)
        # Get printer objects
        self.reactor = self.printer.get_reactor()
        self.runout_helper = filament_switch_sensor.RunoutHelper(config)
        self.port = config.getint('port', 0, minval=0, maxval=4)
        sig = inspect.signature(self.runout_helper.note_filament_present)

        self.zmod_color = self.printer.lookup_object('zmod_color', None)
        if not self.zmod_color or self.zmod_color.get_display():
            return

        if 'eventtime' in sig.parameters:
            self.new = True
        else:
            self.new = False
        self.get_status = self.runout_helper.get_status
        self.extruder = None
        self.estimated_print_time = None
        # Initialise internal state
        self.filament_runout_pos = None
        # Register commands and event handlers
        self.printer.register_event_handler('klippy:ready',
                self._handle_ready)
        self.printer.register_event_handler('idle_timeout:printing',
                self._handle_printing)
        self.printer.register_event_handler('idle_timeout:ready',
                self._handle_not_printing)
        self.printer.register_event_handler('idle_timeout:idle',
                self._handle_not_printing)
        # Регистрация объекта
        self.printer.add_object(f"filament_motion_sensor {self.name}", self)
        self.gcode = self.printer.lookup_object('gcode')
        if self.port == 0:
            self.gcode.register_command('IFS_MOTION_ON', self.cmd_IFS_MOTION_ON)
            self.gcode.register_command('IFS_MOTION_OFF', self.cmd_IFS_MOTION_OFF)

    def cmd_IFS_MOTION_ON(self, gcmd):
        eventtime = self.reactor.monotonic()
        self._update_filament_runout_pos(eventtime)
        if self.new:
            self.runout_helper.note_filament_present(eventtime, True)
        else:
            self.runout_helper.note_filament_present(True)

    def cmd_IFS_MOTION_OFF(self, gcmd):
        if self.new:
            eventtime = self.reactor.monotonic()
            self.runout_helper.note_filament_present(eventtime, False)
        else:
            self.runout_helper.note_filament_present(False)

    def _update_filament_runout_pos(self, eventtime=None):
        if eventtime is None:
            eventtime = self.reactor.monotonic()
        self.filament_runout_pos = (
                self._get_extruder_pos(eventtime) +
                self.detection_length)

    def _handle_ready(self):
        self.ifs = self.printer.lookup_object('zmod_ifs')
        if self.new:
            self.runout_helper.note_filament_present(self.reactor.monotonic(), True)
        else:
            self.runout_helper.note_filament_present(True)
        self.extruder = self.printer.lookup_object(self.extruder_name)
        self.estimated_print_time = (
                self.printer.lookup_object('mcu').estimated_print_time)
        self._update_filament_runout_pos()
        self._extruder_pos_update_timer = self.reactor.register_timer(
                self._extruder_pos_update_event)
    def _handle_printing(self, print_time):
        self.reactor.update_timer(self._extruder_pos_update_timer,
                self.reactor.NOW)
    def _handle_not_printing(self, print_time):
        self.reactor.update_timer(self._extruder_pos_update_timer,
                self.reactor.NEVER)
    def _get_extruder_pos(self, eventtime=None):
        if eventtime is None:
            eventtime = self.reactor.monotonic()
        print_time = self.estimated_print_time(eventtime)
        return self.extruder.find_past_position(print_time)
    def _extruder_pos_update_event(self, eventtime):
        # Получаем статус филамента из zmod_ifs
        if self.ifs.get_ifs_sensor(self.port):
            self._update_filament_runout_pos(eventtime)

            extruder_pos = self._get_extruder_pos(eventtime)
            #logging.info(f"MS: ON {extruder_pos} {self.filament_runout_pos} True")

            # Check for filament insertion
            # Filament is always assumed to be present on an encoder event
            if self.new:
                self.runout_helper.note_filament_present(eventtime, True)
            else:
                self.runout_helper.note_filament_present(True)
        else:
            extruder_pos = self._get_extruder_pos(eventtime)

            #logging.info(f"MS: OF {extruder_pos} {self.filament_runout_pos} {extruder_pos < self.filament_runout_pos}")

            # Check for filament runout
            if self.new:
                self.runout_helper.note_filament_present(eventtime,
                    extruder_pos < self.filament_runout_pos)
            else:
                self.runout_helper.note_filament_present(
                    extruder_pos < self.filament_runout_pos)

        return eventtime + CHECK_RUNOUT_TIMEOUT

def load_config_prefix(config):
    return ZmodIfsMotionSensor(config)
