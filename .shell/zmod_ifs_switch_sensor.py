# ZmodIfsSwitchSensor
# Copyright (C) 2025 ghzserg https://github.com/ghzserg/zmod
import inspect

from .filament_switch_sensor import RunoutHelper

class ZmodIfsSwitchSensor:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.name = config.get_name().split()[-1]

        self.runout_helper = RunoutHelper(config)
        self.get_status = self.runout_helper.get_status
        self.printer.add_object(f"filament_switch_sensor {self.name}", self)

        self.reactor = self.printer.get_reactor()
        sig = inspect.signature(self.runout_helper.note_filament_present)
        if 'eventtime' in sig.parameters:
            self.new = True
        else:
            self.new = False

        self.printer.register_event_handler("klippy:ready", self._handle_ready)
        self.gcode = self.printer.lookup_object('gcode')
        self.gcode.register_command('IFS_SWITCH_ON', self.cmd_IFS_SWITCH_ON)
        self.gcode.register_command('IFS_SWITCH_OFF', self.cmd_IFS_SWITCH_OFF)

    def _handle_ready(self):
        self.query_adc = self.printer.lookup_object('query_adc')
        self.timer = self.reactor.register_timer(self.check_state, self.reactor.NOW)
        self.check_state(self.reactor.NOW)

    def cmd_IFS_SWITCH_ON(self, gcmd):
        if self.new:
            eventtime = self.reactor.monotonic()
            self.runout_helper.note_filament_present(eventtime, True)
        else:
            self.runout_helper.note_filament_present(True)

    def cmd_IFS_SWITCH_OFF(self, gcmd):
        if self.new:
            eventtime = self.reactor.monotonic()
            self.runout_helper.note_filament_present(eventtime, False)
        else:
            self.runout_helper.note_filament_present(False)

    def check_state(self, eventtime):
        try:
            new_state = self.get_filament()
        except Exception as e:
            self.gcode.respond_info(f"Error reading filament sensor: {e}")
            new_state = True

        sig = inspect.signature(self.runout_helper.note_filament_present)
        if self.new:
            self.runout_helper.note_filament_present(eventtime, new_state)
        else:
            self.runout_helper.note_filament_present(new_state)

        return eventtime + 0.5

    def get_filament(self):
        value, _ = self.query_adc.adc["temperature_sensor filamentValue"].get_last_value()
        return value >= 0.72 if value > 0.3 else True


# ZmodIfsPortSensor

class ZmodIfsPortSensor:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.name = config.get_name().split()[-1]

        self.runout_helper = RunoutHelper(config)
        self.port = config.getint('port', 0, minval=0, maxval=4)
        self.get_status = self.runout_helper.get_status
        self.printer.add_object(f"filament_switch_sensor {self.name}", self)

        self.reactor = self.printer.get_reactor()
        sig = inspect.signature(self.runout_helper.note_filament_present)
        self.new = 'eventtime' in sig.parameters

        self.last_state = True
        self.timer = self.reactor.register_timer(self.check_state, self.reactor.NOW)

        self.printer.register_event_handler("klippy:ready", self._handle_ready)
        self.gcode = self.printer.lookup_object('gcode')

    def _handle_ready(self):
        self.ifs = self.printer.lookup_object('zmod_ifs')
        self.check_state(self.reactor.NOW)

    def check_state(self, eventtime):
        try:
            new_state = self.get_filament()
        except Exception as e:
            self.gcode.respond_info(f"Error reading filament sensor: {e}")
            new_state = True

        print_state = self.printer.lookup_object('print_stats').get_status(eventtime)['state']
        is_printing = print_state in ('printing')

        if not is_printing and hasattr(self, "last_state") and self.last_state and not new_state:
            self.runout_helper._exec_gcode("", self.runout_helper.runout_gcode)
        self.last_state = new_state

        sig = inspect.signature(self.runout_helper.note_filament_present)
        if self.new:
            self.runout_helper.note_filament_present(eventtime, new_state)
        else:
            self.runout_helper.note_filament_present(new_state)

        return eventtime + 0.5

    def get_filament(self):
        return self.ifs.get_port(self.port)

def load_config_prefix(config):
    sensor_type = config.get('type', 'switch')
    if sensor_type == 'port':
        return ZmodIfsPortSensor(config)
    else:
        return ZmodIfsSwitchSensor(config)
