import logging
import mcu

MCU_TVOC_RESPONSE = "flashforge_tvoc_response"

REPORT_TIME = 0.5

class MCUResponse:
    def __init__(self, params):
        self.params = params
        self.status = self._decode(params.get('status'), 'unknown')
        try:
            self.tvoc = int(params.get('tvoc', 0))
            self.co2 = int(params.get('co2', 0))
            self.hcho = int(params.get('hcho', 0))
        except:
            self.tvoc = 0
            self.co2 = 0
            self.hcho = 0

    def _decode(self, value, default=''):
        if value is None: 
            return default
        if isinstance(value, str): 
            return value
        try: 
            return value.decode('utf-8')
        except: 
            return default

class FlashforgeTVOC:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.gcode = self.printer.lookup_object('gcode')
        self.name = config.get_name().split()[-1]
        self.mcu = mcu.get_printer_mcu(self.printer, config.get('mcu'))
        self.mcu.register_response(self._handle_tvoc_response, MCU_TVOC_RESPONSE)
        self.logger = logging.getLogger('klippy')

        self.last_tvoc_value = 0
        self.last_co2_value = 0
        self.last_hcho_value = 0
        self.last_status = 'unknown'

        self.gcode.register_command(
            "FLASHFORGE_GET_TVOC",
            self.cmd_GET_TVOC,
            desc="Get current TVOC reading from sensor"
        )

    def _handle_tvoc_response(self, params):
        response = MCUResponse(params)
        self.logger.debug(f"{self.name}:"
                         f"TVOC: {response.tvoc} µg/m³, "
                         f"CO2: {response.co2} ppm, "
                         f"HCHO: {response.hcho} µg/m³, "
                         f"Status: {response.status}")

        self.last_tvoc_value = response.tvoc
        self.last_co2_value = response.co2
        self.last_hcho_value = response.hcho
        self.last_status = response.status

    def cmd_GET_TVOC(self, gcmd):
        gcmd.respond_info(
            f"{self.name}:1"
            f"TVOC: {self.last_tvoc_value} µg/m³, "
            f"CO2: {self.last_co2_value} ppm, "
            f"Formaldehyde: {self.last_hcho_value} µg/m³, "
            f"Status: {self.last_status}"
        )

    def get_status(self, eventtime):
        return {
            'tvoc': self.last_tvoc_value,
            'co2': self.last_co2_value,
            'hcho': self.last_hcho_value,
            'status': self.last_status,
        }

class TVOCSensor:
    def __init__(self, config, tvoc):
        self.tvoc = tvoc
        self.printer = config.get_printer()
        self.reactor = self.printer.get_reactor()
        self.name = config.get_name().split()[-1]
        self.logger = logging.getLogger('klippy')

        self.sample_timer = self.reactor.register_timer(self._sample)

        self._callback = None

        self.printer.register_event_handler("klippy:connect", self._handle_connect)

    def _handle_connect(self):
        self.reactor.update_timer(self.sample_timer, self.reactor.NOW)

    def _sample(self, eventtime):
        measured_time = self.reactor.monotonic()
        if self._callback:
            self._callback(self.tvoc.mcu.estimated_print_time(measured_time), round(self.tvoc.last_tvoc_value / 10))
        return measured_time + 0.5

    def setup_callback(self, cb):
        self._callback = cb

    def get_report_time_delta(self):
        return REPORT_TIME

    def setup_minmax(self, min_temp, max_temp):
        pass

    def get_temp(self, eventtime):
        return self.tvoc.last_tvoc_value, 0

    def get_status(self, eventtime):
        return {'temperature': self.tvoc.last_tvoc_value, **self.tvoc.get_status(eventtime)}


def load_config(config):
    tvoc = FlashforgeTVOC(config)

    pheaters = config.get_printer().load_object(config, "heaters")
    pheaters.add_sensor_factory(
        "flashforge_tvoc",
        lambda cfg: TVOCSensor(cfg, tvoc)
    )

    return tvoc