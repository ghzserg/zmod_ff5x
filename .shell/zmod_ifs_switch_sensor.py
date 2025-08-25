# ZmodIfsSwitchSensor
# Copyright (C) 2025 ghzserg https://github.com/ghzserg/zmod
import inspect

from .filament_switch_sensor import RunoutHelper

class ZmodIfsSwitchSensor:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.name = config.get_name().split()[-1]
        self.query_adc = self.printer.lookup_object('query_adc')

        self.runout_helper = RunoutHelper(config)
        self.get_status = self.runout_helper.get_status
        self.printer.add_object(f"filament_switch_sensor {self.name}", self)

        self.reactor = self.printer.get_reactor()

        self.printer.register_event_handler("klippy:ready", self._handle_ready)

    def _handle_ready(self):
        self.timer = self.reactor.register_timer(self.check_state, self.reactor.NOW)
        self.check_state(self.reactor.NOW)
        sig = inspect.signature(self.runout_helper.note_filament_present)
        if 'eventtime' in sig.parameters:
            self.new = True
        else
            self.new = False

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

def load_config_prefix(config):
    return ZmodIfsSwitchSensor(config)
