# (c) 2025 minicx https://github.com/loss-and-quick
# (c) 2025 ghzserg https://github.com/ghzserg/zmod

import logging
import mcu

from enum import Enum

MCU_FLASHFORGE_RESPONSE = "flashforge_loadcell_response"

MCU_CMD_FLASHFORGE_H1 = "flashforge_loadcell_h1"
MCU_CMD_FLASHFORGE_H2 = "flashforge_loadcell_h2 weight=%u"
MCU_CMD_FLASHFORGE_H3 = "flashforge_loadcell_h3 weight=%u"
MCU_CMD_FLASHFORGE_H7 = "flashforge_loadcell_h7"
MCU_CMD_FLASHFORGE_TEST = "flashforge_loadcell_test_cmd cmd=%*s"


class Commands(Enum):
    H1 = 'H1'
    H2 = 'H2'
    H3 = 'H3'
    H7 = 'H7'
    TEST = 'TEST'

_MCU_CMD_MAP = {
    MCU_CMD_FLASHFORGE_H1: Commands.H1,
    MCU_CMD_FLASHFORGE_H2: Commands.H2,
    MCU_CMD_FLASHFORGE_H3: Commands.H3,
    MCU_CMD_FLASHFORGE_H7: Commands.H7,
    MCU_CMD_FLASHFORGE_TEST: Commands.TEST,
}

class MCUResponse:
    def __init__(self, params):
        self.params = params
        self.command_name = self._decode(params.get('command'))
        self.status = self._decode(params.get('status'), 'unknown')
        self.raw_response = self._decode(params.get('raw_response'))
        try:
            self.value = int(params.get('value', 0))
        except (ValueError, TypeError):
            self.value = 0

    def _decode(self, value, default=''):
        if value is None: return default
        if isinstance(value, str): return value
        try: return value.decode('utf-8')
        except: return default


class FlashforgeLoadCell:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.reactor = self.printer.get_reactor()
        self.gcode = self.printer.lookup_object('gcode')
        self.name = config.get_name().split()[-1]
        self.mcu = mcu.get_printer_mcu(self.printer, config.get('mcu'))
        self.mcu.register_response(self._handle_flashforge_response, MCU_FLASHFORGE_RESPONSE)
        self.active_command = None
        self.logger = logging.getLogger('klippy')
        self.last_weight_grams = 0
        self.tare_threshold = config.getint('tare_threshold', 50, 0)
        self.tare_timeout = config.getfloat('tare_timeout', 10.0, 0.)
        self.supported_cmds = {}
        self.gcode.register_command(
            "H1",
            self.cmd_H1,
        )
        self.gcode.register_command(
            "FLASHFORGE_LOAD_CELL_TARE",
            self.cmd_LOAD_CELL_TARE,
            desc="Starts the weight tare (zeroing) procedure"
        )
        self.gcode.register_command(
            "FLASHFORGE_LOAD_CELL_CALIBRATE",
            self.cmd_LOAD_CELL_CALIBRATE,
            desc="Sends a calibration command"
        )
        self.gcode.register_command(
            "FLASHFORGE_LOAD_CELL_SAVE_CALIBRATION",
            self.cmd_LOAD_CELL_SAVE_CALIBRATION,
            desc="Sends calibration save command"
        )
        self.gcode.register_command(
            "FLASHFORGE_GET_LOAD_CELL_WEIGHT",
            self.cmd_GET_LOAD_CELL_WEIGHT,
            desc="Queries and displays the current weight"
        )
        self.gcode.register_command(
            "FLASHFORGE_LOAD_CELL_TEST",
            self.cmd_LOAD_CELL_TEST,
            desc="Sends an arbitrary command to the loadcell"
        )
        self.printer.register_event_handler("klippy:connect", self._handle_connect)

    def _handle_connect(self):
        for cmd_name in (
            MCU_CMD_FLASHFORGE_H1,
            MCU_CMD_FLASHFORGE_H2,
            MCU_CMD_FLASHFORGE_H3,
            MCU_CMD_FLASHFORGE_H7,
            MCU_CMD_FLASHFORGE_TEST
        ):
            cmd = self.mcu.try_lookup_command(cmd_name)
            if not cmd:
                raise Exception(
                    f"{self.name}: Required MCU command '{cmd_name}' is not available. Check your firmware."
                )
            self.supported_cmds[cmd_name] = cmd

    def _handle_flashforge_response(self, params):
        response = MCUResponse(params)
        self.logger.debug(f"{self.name}: Received response: {response.command_name}, status: {response.status}")

        if self.active_command:
            expected_cmd = self.active_command.get('cmd')
            if response.command_name == expected_cmd.value:
                completion = self.active_command.get('completion')
                if not completion.test():
                    completion.complete(response)
                return

        if response.command_name == Commands.H7.value and response.status == 'ok':
            self.last_weight_grams = abs(response.value)

    def _send_and_wait(self, command_name, params_list=None):
        if self.active_command:
            raise self.printer.command_error(f"{self.name}: Another G-Code command is already in progress.")

        cmd_obj = self.supported_cmds.get(command_name)
        cmd_enum = _MCU_CMD_MAP.get(command_name)
        if not cmd_obj or not cmd_enum:
            raise self.printer.command_error(f"{self.name}: MCU command '{command_name}' not found.")

        completion = self.reactor.completion()
        self.active_command = {'cmd': cmd_enum, 'completion': completion}

        try:
            if params_list:
                cmd_obj.send(params_list)
            else:
                cmd_obj.send()

            response = completion.wait(self.reactor.monotonic() + 0.6)

            if response is None:
                raise self.printer.command_error(f"{self.name}: MCU command '{cmd_enum.value}' timed out.")

            if response.status != 'ok':
                self._handle_mcu_error(response, command_name)

            return response
        finally:
            self.active_command = None

    def _handle_mcu_error(self, response: MCUResponse, cmd_name_fallback):
        cmd_name = response.command_name or cmd_name_fallback
        raise self.printer.command_error(
            f"{self.name}: Command '{cmd_name}' failed with status "
            f"'{response.status}'. MCU Response: '{response.raw_response}'")

    def cmd_GET_LOAD_CELL_WEIGHT(self, gcmd):
        response = self._send_and_wait(MCU_CMD_FLASHFORGE_H7)
        self.last_weight_grams = abs(response.value)
        gcmd.respond_info(f"{self.name}: Weight: {response.value} grams")

    def cmd_LOAD_CELL_TARE(self, gcmd):
        gcmd.respond_info(f"{self.name}: Starting tare procedure...")
        deadline = self.reactor.monotonic() + self.tare_timeout
        while self.reactor.monotonic() < deadline:
            try:
                self._send_and_wait(MCU_CMD_FLASHFORGE_H1)
                response = self._send_and_wait(MCU_CMD_FLASHFORGE_H7)
            except self.printer.command_error as e:
                raise gcmd.error(f"Tare step failed: {e}")

            if abs(response.value) <= self.tare_threshold:
                gcmd.respond_info(f"Tare successful. Final weight: {response.value}g")
                return

            gcmd.respond_info(f"Weight is {response.value}g, retrying...")
            self.reactor.pause(self.reactor.monotonic() + 0.2)
        raise gcmd.error(f"Tare failed to complete within {self.tare_timeout}s.")

    def cmd_H1(self, gcmd):
        deadline = self.reactor.monotonic() + self.tare_timeout
        while self.reactor.monotonic() < deadline:
            try:
                self._send_and_wait(MCU_CMD_FLASHFORGE_H1)
                response = self._send_and_wait(MCU_CMD_FLASHFORGE_H7)
            except self.printer.command_error as e:
                raise gcmd.error(f"Tare step failed: {e}")

            if abs(response.value) <= self.tare_threshold:
                return

            self.reactor.pause(self.reactor.monotonic() + 0.2)
        raise gcmd.error(f"Tare failed to complete within {self.tare_timeout}s.")

    def cmd_LOAD_CELL_CALIBRATE(self, gcmd):
        weight = gcmd.get_int('WEIGHT', 500, 0)
        self._send_and_wait(MCU_CMD_FLASHFORGE_H2, params_list=[weight])
        gcmd.respond_info(f"{self.name}: Calibrate command sent.")

    def cmd_LOAD_CELL_SAVE_CALIBRATION(self, gcmd):
        weight = gcmd.get_int('WEIGHT', 200, 0, 500)
        self._send_and_wait(MCU_CMD_FLASHFORGE_H3, params_list=[weight])
        gcmd.respond_info(f"{self.name}: Save calibration command sent.")

    def cmd_LOAD_CELL_TEST(self, gcmd):
        cmd_str = gcmd.get('CMD', None)
        if cmd_str is None:
            raise gcmd.error(f"{self.name}: No CMD parameter provided.")

        cmd_bytes = cmd_str.encode('utf-8')
        response = self._send_and_wait(MCU_CMD_FLASHFORGE_TEST, params_list=[cmd_bytes])
        gcmd.respond_info(f"{self.name}: Response: {response.raw_response}")


class LoadCellSensor:
    def __init__(self, config, loadcell):
        self.loadcell = loadcell
        self.printer = config.get_printer()
        self.reactor = self.printer.get_reactor()
        self.name = config.get_name().split()[-1]
        self.logger = logging.getLogger('klippy')
        self.gcode = self.printer.lookup_object('gcode')
        self.zcontrol = 0
        self.zcommand = 0
        self.max_temp = 2048
        self.sample_interval = config.getfloat('sample_interval', 0.2, 0.1)
        self.check_only_when_printing = config.getboolean('check_only_when_printing', True)
        try:
            self.pause_resume = self.printer.load_object(
                config, "pause_resume")
        except config.error:
            raise self.printer.config_error(
                f"{self.name} requires [pause_resume] to work,"
                " please add it to your config!")
        self.sample_timer = self.reactor.register_timer(self._sample)
        self._callback = None
        self.printer.register_event_handler("klippy:connect", self._handle_connect)
        # zmod start
        self.gcode.register_command('ZCONTROL_ON', self.cmd_ZCONTROL_ON)
        self.gcode.register_command('ZCONTROL_PAUSE', self.cmd_ZCONTROL_PAUSE)
        self.gcode.register_command('ZCONTROL_ABORT', self.cmd_ZCONTROL_ABORT)
        self.gcode.register_command('ZCONTROL_STATUS', self.cmd_ZCONTROL_STATUS)
        self.gcode.register_command('ZCONTROL_OFF', self.cmd_ZCONTROL_OFF)
        self.zmod = self.printer.lookup_object('zmod', None)
        self.language = 'en'
        if self.zmod is not None:
            self.language = self.zmod.get_lang()

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
    # zmod end

    def _handle_connect(self):
        self.reactor.update_timer(self.sample_timer, self.reactor.NOW)

    def _sample(self, eventtime):
        try:
            cmd_obj = self.loadcell.supported_cmds.get(MCU_CMD_FLASHFORGE_H7)
            if cmd_obj and not self.loadcell.active_command:
                cmd_obj.send()
        except Exception as e:
            self.logger.warning(f"{self.name}: Could not send H7 poll: {e}")
        temp = self.loadcell.last_weight_grams
        # zmod
        if temp > self.max_temp and self.zcontrol == 1:
            if self.zcommand == 1:
                msg = (f"!! Nozzle hit bed or part detachment. Weight {temp}>{self.max_temp}. PAUSE. https://github.com/ghzserg/zmod/wiki/Global_en#nozzle_control"
                       if self.language != 'ru'
                       else f"!! Удар сопла о стол или отрыв детали. Вес {temp}>{self.max_temp}. PAUSE. https://github.com/ghzserg/zmod/wiki/Global_ru#nozzle_control")
                self.gcode.respond_raw(msg)

                reactor = self.printer.get_reactor()
                pause_resume = self.printer.lookup_object('pause_resume')

                def async_pause(eventtime):
                    pause_resume.send_pause_command()
                    self.gcode.run_script_from_command("PAUSE\nM400\n")
                    return reactor.NEVER

                reactor.register_callback(async_pause)
            else:
                shutdown_msg = (
                    f"Nozzle hit bed or part detachment. Weight {temp}>{self.max_temp}. FIRMWARE_RESTART. https://github.com/ghzserg/zmod/wiki/Global_en#nozzle_control"
                    if self.language != 'ru'
                    else f"Удар сопла о стол или отрыв детали. Вес {temp}>{self.max_temp}. FIRMWARE_RESTART. https://github.com/ghzserg/zmod/wiki/Global_ru#nozzle_control"
                )
                self.printer.invoke_async_shutdown(shutdown_msg)
            return self.reactor.NEVER
        measured_time = self.reactor.monotonic()
        if self._callback:
            try:
                estimated = self.loadcell.mcu.estimated_print_time(measured_time)
            except Exception:
                estimated = None
            self._callback(estimated, temp)

        return measured_time + self.sample_interval

    def setup_callback(self, cb):
        self._callback = cb

    def get_report_time_delta(self):
        return self.sample_interval

    def setup_minmax(self, min_temp, max_temp):
        if max_temp > 2048:
            self.max_temp = 2048
        else:
            self.max_temp = max_temp

    def get_temp(self, eventtime):
        return self.loadcell.last_weight_grams, 0

    def get_status(self, eventtime):
        return {'temperature': self.loadcell.last_weight_grams}


def load_config(config):
    loadcell = FlashforgeLoadCell(config)
    pheaters = config.get_printer().load_object(config, "heaters")
    pheaters.add_sensor_factory(
        "flashforge_loadcell",
        lambda cfg: LoadCellSensor(cfg, loadcell)
    )
    return loadcell
