# ENS160 I2C/SPI Air Quality Sensor support for Klipper
#
# Copyright (C) 2025 <minicx@disroot.org>
#
# This file may be distributed under the terms of the GNU GPLv3 license.
#
# ens160: I2C/SPI Air Quality sensor providing AQI (1-5), TVOC (ppb), and eCO2 (ppm)
# Can use external temperature/humidity sensor (AHT10/20/21) for compensation
import logging
from . import bus

ENS160_I2C_ADDR_LOW = 82     # 0x52 - MISO/ADDR pin low
ENS160_I2C_ADDR_HIGH = 83    # 0x53 - MISO/ADDR pin high (default)
ENS160_SPI_SPEED = 10000000  # 10 MHz max SPI speed

# Register addresses
ENS160_REG_PART_ID = 0x00
ENS160_REG_OPMODE = 0x10
ENS160_REG_CONFIG = 0x11
ENS160_REG_COMMAND = 0x12
ENS160_REG_TEMP_IN = 0x13
ENS160_REG_RH_IN = 0x15
ENS160_REG_DATA_STATUS = 0x20
ENS160_REG_DATA_AQI = 0x21
ENS160_REG_DATA_TVOC = 0x22
ENS160_REG_DATA_ECO2 = 0x24
ENS160_REG_GPR_READ = 0x48

# Operating modes
ENS160_OPMODE_DEEP_SLEEP = 0x00
ENS160_OPMODE_IDLE = 0x01
ENS160_OPMODE_STANDARD = 0x02
ENS160_OPMODE_RESET = 0xF0

# Commands
ENS160_CMD_NOP = 0x00
ENS160_CMD_GET_APPVER = 0x0E
ENS160_CMD_CLRGPR = 0xCC

# Expected Part ID
ENS160_PART_ID = 0x0160

class ENS160:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.name = config.get_name().split()[-1]
        self.reactor = self.printer.get_reactor()

        # Setup command helper
        ENS160CommandHelper(config, self)

        self.interface_type = self._detect_interface_type(config)
        
        if self.interface_type == 'i2c':
            self._setup_i2c(config)
        else:
            self._setup_spi(config)
        
        self.report_time = config.getint('ens160_report_time', 60, minval=10)
        
        self.aht_sensor_name = config.get('aht_sensor', None)

        self.aqi = 0
        self.tvoc = 0
        self.eco2 = 0
        self.data_ready = False
        self.initialized = False

        self._callback = None
        
        self.sample_timer = self.reactor.register_timer(self._sample_ens160)
        self.printer.add_object("ens160 " + self.name, self)
        self.printer.register_event_handler("klippy:connect", self.handle_connect)

    def _detect_interface_type(self, config):
        has_i2c = config.get('i2c_bus', None) is not None
        has_spi = config.get('spi_bus', None) is not None or config.get('cs_pin', None) is not None
        
        if has_i2c and has_spi:
            raise config.error("ens160: Cannot specify both I2C and SPI configuration")
        elif has_i2c:
            return 'i2c'
        elif has_spi:
            return 'spi'
        else:
            return 'i2c'

    def _setup_i2c(self, config):
        self.i2c = bus.MCU_I2C_from_config(
            config, default_addr=ENS160_I2C_ADDR_HIGH, default_speed=100000)
        logging.info("ENS160: Using I2C interface")

    def _setup_spi(self, config):
        self.spi = bus.MCU_SPI_from_config(
            config, 3, default_speed=ENS160_SPI_SPEED)
        logging.info("ENS160: Using SPI interface")

    def handle_connect(self):
        if self._init_ens160():
            self.reactor.update_timer(self.sample_timer, self.reactor.NOW)
        else:
            logging.error("ens160: initialization failed, sensor disabled")

    def setup_minmax(self, min_temp, max_temp):
        pass

    def setup_callback(self, cb):
        self._callback = cb

    def get_report_time_delta(self):
        return self.report_time

    def _read_register(self, reg, length=1):
        try:
            if self.interface_type == 'i2c':
                self.i2c.i2c_write([reg])
                read = self.i2c.i2c_read([], length)
                if read is None or len(read['response']) < length:
                    return None
                return read['response']
            else:
                # SPI: set R/W bit high (bit 0 = 1)
                cmd = [reg | 0x01] + [0x00] * length
                read = self.spi.spi_transfer(cmd)
                if read is None or len(read) < length + 1:
                    return None
                return read[1:]  # Skip command byte
        except Exception as e:
            logging.exception("ens160: Register read error (reg 0x%02X): %s", reg, e)
            return None

    def _write_register(self, reg, data):
        try:
            if self.interface_type == 'i2c':
                if isinstance(data, (list, tuple)):
                    self.i2c.i2c_write([reg] + list(data))
                else:
                    self.i2c.i2c_write([reg, data])
            else:
                # SPI: R/W bit low (bit 0 = 0)
                if isinstance(data, (list, tuple)):
                    cmd = [reg & 0xFE] + list(data)
                else:
                    cmd = [reg & 0xFE, data]
                self.spi.spi_send(cmd)
            return True
        except Exception as e:
            logging.exception("ens160: Register write error (reg 0x%02X): %s", reg, e)
            return False

    def _init_ens160(self):
        try:
            part_id_data = self._read_register(ENS160_REG_PART_ID, 2)
            if part_id_data is None:
                logging.error("ens160: Failed to read Part ID")
                return False
            
            part_id = part_id_data[0] | (part_id_data[1] << 8)  # Little endian
            if part_id != ENS160_PART_ID:
                logging.error("ens160: Invalid Part ID: 0x%04X (expected 0x%04X)", 
                             part_id, ENS160_PART_ID)
                return False
            
            if not self._write_register(ENS160_REG_OPMODE, ENS160_OPMODE_RESET):
                logging.error("ens160: Failed to reset device")
                return False
            self.reactor.pause(self.reactor.monotonic() + 0.100)
            
            if not self._write_register(ENS160_REG_OPMODE, ENS160_OPMODE_IDLE):
                logging.error("ens160: Failed to set IDLE mode")
                return False
            self.reactor.pause(self.reactor.monotonic() + 0.010)
            
            if not self._write_register(ENS160_REG_COMMAND, ENS160_CMD_CLRGPR):
                logging.error("ens160: Failed to clear GPR registers")
                return False
            self.reactor.pause(self.reactor.monotonic() + 0.010)
            
            if not self._write_register(ENS160_REG_OPMODE, ENS160_OPMODE_STANDARD):
                logging.error("ens160: Failed to set STANDARD mode")
                return False
            self.reactor.pause(self.reactor.monotonic() + 0.020)
            
            if self._write_register(ENS160_REG_COMMAND, ENS160_CMD_GET_APPVER):
                self.reactor.pause(self.reactor.monotonic() + 0.010)
                gpr_data = self._read_register(ENS160_REG_GPR_READ, 8)
                if gpr_data:
                    fw_version = "%d.%d.%d" % (gpr_data[4], gpr_data[5], gpr_data[6])
                    logging.info("ens160: Successfully initialized (Part ID: 0x%04X, FW: %s)", 
                                part_id, fw_version)
                else:
                    logging.info("ens160: Successfully initialized (Part ID: 0x%04X)", part_id)
            
            self.initialized = True
            return True
            
        except Exception as e:
            logging.exception("ens160: Initialization error: %s", e)
            return False

    def _set_compensation_data(self, temp_c, humidity_rh):
        try:
            if temp_c is not None:
                temp_kelvin = temp_c + 273.15
                # Temperature: Kelvin * 64 (16-bit, little endian)
                temp_raw = int(temp_kelvin * 64)
                temp_raw = max(0, min(65535, temp_raw))
                
                temp_bytes = (temp_raw & 0xFF, (temp_raw >> 8) & 0xFF)
                self._write_register(ENS160_REG_TEMP_IN, temp_bytes)
            
            if humidity_rh is not None:
                # Humidity: RH% * 512 (16-bit, little endian)
                hum_raw = int(humidity_rh * 512)
                hum_raw = max(0, min(65535, hum_raw))
                
                hum_bytes = (hum_raw & 0xFF, (hum_raw >> 8) & 0xFF)
                self._write_register(ENS160_REG_RH_IN, hum_bytes)
                
        except Exception as e:
            logging.warning("ens160: Failed to set compensation data: %s", e)

    def _get_compensation_from_sensor(self, eventtime):
        if not self.aht_sensor_name:
            return None, None
            
        try:
            try:
                sensor_obj = self.printer.lookup_object("aht10 " + self.aht_sensor_name)
                status = sensor_obj.get_status(eventtime)
                
                return status.get('temperature', None), status.get('humidity', None)
            except:
                pass
                
            logging.warning("ens160: Temperature sensor '%s' not found for compensation", 
                           self.aht_sensor_name)
            return None, None
            
        except Exception as e:
            logging.warning("ens160: Error getting compensation data: %s", e)
            return None, None

    def _make_measurement(self, eventtime):
        if not self.initialized:
            return False
            
        try:
            temp_c, humidity_rh = self._get_compensation_from_sensor(eventtime)
            if temp_c is not None or humidity_rh is not None:
                self._set_compensation_data(temp_c, humidity_rh)
            
            status_data = self._read_register(ENS160_REG_DATA_STATUS, 1)
            if status_data is None:
                return False
            
            status = status_data[0]
            self.data_ready = bool(status & 0x02)  # NEWDAT bit
            
            if status & 0x40:  # STATER bit - error
                logging.warning("ens160: Device reports error status")
                return False
            
            if not self.data_ready:
                return True
            
            aqi_data = self._read_register(ENS160_REG_DATA_AQI, 1)
            if aqi_data:
                self.aqi = aqi_data[0] & 0x07
            
            tvoc_data = self._read_register(ENS160_REG_DATA_TVOC, 2)
            if tvoc_data:
                self.tvoc = tvoc_data[0] | (tvoc_data[1] << 8)
            
            eco2_data = self._read_register(ENS160_REG_DATA_ECO2, 2)
            if eco2_data:
                self.eco2 = eco2_data[0] | (eco2_data[1] << 8)

            return True
            
        except Exception as e:
            logging.exception("ens160: Measurement error: %s", e)
            return False

    def _sample_ens160(self, eventtime):
        if not self._make_measurement(eventtime):
            self.aqi = self.tvoc = self.eco2 = 0
            return self.reactor.NEVER

        measured_time = self.reactor.monotonic()
        
        if self._callback is not None:
            mcu = None
            if self.interface_type == 'i2c':
                mcu = self.i2c.get_mcu()
            elif self.interface_type == 'spi':
                mcu = self.spi.get_mcu()
            
            if mcu:
                print_time = mcu.estimated_print_time(measured_time)
                self._callback(print_time, self.tvoc)
        
        return measured_time + self.report_time

    def get_status(self, eventtime):
        return {
            'temperature': round(self.tvoc, 2),
            'aqi': int(self.aqi),
            'tvoc': int(self.tvoc),
            'eco2': int(self.eco2),
            'data_ready': self.data_ready,
            'initialized': self.initialized,
        }

class ENS160CommandHelper:
    def __init__(self, config, chip):
        self.printer = config.get_printer()
        self.chip = chip
        name_parts = config.get_name().split()
        self.name = name_parts[-1]
        self.register_commands(self.name)
        if len(name_parts) == 1:
            if self.name == "ens160" or not config.has_section("ens160"):
                self.register_commands(None)
    
    def register_commands(self, name):
        gcode = self.printer.lookup_object('gcode')
        gcode.register_mux_command("QUERY_ENS160", "CHIP", name,
                                   self.cmd_QUERY_ENS160,
                                   desc=self.cmd_QUERY_ENS160_help)
    
    cmd_QUERY_ENS160_help = "Query ENS160 air quality sensor"
    def cmd_QUERY_ENS160(self, gcmd):
        status = self.chip.get_status(None)
        gcmd.respond_info(
            "AQI=%d TVOC=%dppb eCO2=%dppm ready=%s init=%s" % (
                status.get('aqi', 0),
                status.get('tvoc', 0),
                status.get('eco2', 0),
                status.get('data_ready', False),
                status.get('initialized', False),
            )
        )

def load_config(config):
    pheater = config.get_printer().lookup_object("heaters")
    pheater.add_sensor_factory("ENS160", ENS160)