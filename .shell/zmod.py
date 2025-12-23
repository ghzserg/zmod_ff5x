import os
import logging
import json

FFCONFIG1='/usr/prog/config/Adventurer5M.json'
FFCONFIG2='/opt/config/Adventurer5M.json'

class zmod:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.lang = config.get('language', 'en')
        self.ad5x = config.getboolean('ad5x', False)

        self.gcode = self.printer.lookup_object('gcode')
        gcode_macro = self.printer.load_object(config, 'gcode_macro')
        self.on_error_gcode = gcode_macro.load_template(
            config, 'on_error_gcode', '')

        self.virtual_sdcard = None
        self.sdcard_dirname = ""

        self.gcode.register_command('SAVE_SHAPER', self.cmd_SAVE_SHAPER)
        self.gcode.register_command('ZEXCLUDE', self.cmd_ZEXCLUDE)
        self.gcode.register_command('LOAD_ZOFFSET_NATIVE', self.cmd_LOAD_ZOFFSET_NATIVE)

        self.printer.register_event_handler("klippy:ready", self._handle_ready)

    def _handle_ready(self):
        self.virtual_sdcard = self.printer.lookup_object('virtual_sdcard')
        self.sdcard_dirname = self.virtual_sdcard.sdcard_dirname

    def get_lang(self):
        return self.lang

    def cmd_LOAD_ZOFFSET_NATIVE(self, gcmd):
        start = gcmd.get_int("START", 0)

        config_path = FFCONFIG1 if os.path.isfile(FFCONFIG1) else FFCONFIG2 if os.path.isfile(FFCONFIG2) else None
        if not config_path:
            raise gcmd.error(f"LOAD_ZOFFSET_NATIVE: File not found {FFCONFIG1}, {FFCONFIG2}")

        with open(config_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        try:
            z_probe_offset = data['leftExtruderOffset']['zProbeOffset']
        except KeyError as e:
            z_probe_offset = 0.0

        zoffset = round(float(z_probe_offset), 4)
        if not self.ad5x:
            zoffset += 0.025

        self.gcode.run_script_from_command(f"SET_GCODE_OFFSET Z={zoffset:.4f} START={start} FROM=LOAD_ZOFFSET_NATIVE")
        if start == 0:
            gcmd.respond_raw(f"Z-offset={zoffset:.4f}")

    def cmd_ZEXCLUDE(self, gcmd):
        filename = gcmd.get("FILENAME", None)
        if not filename:
            file_path = self.virtual_sdcard.file_path()
            if not file_path:
                gcmd.respond_raw("ZEXCLUDE: FILENAME is required (no file loaded)")
                return
            full_path = file_path
        else:
            if filename.startswith('/'):
                filename = filename[1:]
            full_path = os.path.join(self.sdcard_dirname, filename)

        try:
            with open(full_path, 'r') as f:
                gcmd.respond_raw(f"ZEXCLUDE: {full_path}")

                max_lines = 3000
                line_num = 0
                for line in f:
                    line_num += 1
                    if line_num > max_lines:
                        break

                    line = line.strip()

                    if not line or line.startswith('#'):
                        continue

                    if line.startswith('EXCLUDE_OBJECT_DEFINE'):
                        try:
                            self.gcode.run_script_from_command(line)
                        except self.gcode.error as e:
                            error_message = str(e)
                            gcmd.respond_raw(f"ZEXCLUDE: Error on line {line_num}: {error_message}")
                            logging.error(f"ZEXCLUDE: Error on line {line_num}: {error_message}")

                            try:
                                self.gcode.run_script_from_command(self.on_error_gcode.render())
                                gcmd.respond_raw("ZEXCLUDE: Error handler executed")
                            except:
                                logging.exception("zexclude_error")
                                gcmd.respond_raw("ZEXCLUDE: Error handler failed")
                            break
                        except Exception:
                            logging.exception("zexclude_error")
                            gcmd.respond_raw("ZEXCLUDE: Unexpected error during script execution")
                            break

        except FileNotFoundError:
            gcmd.respond_raw(f"ZEXCLUDE: File not found: {full_path}")
            logging.error(f"ZEXCLUDE: File not found: {full_path}")
        except Exception:
            logging.exception("zexclude_file_error")
            gcmd.respond_raw("ZEXCLUDE: Unexpected error during file processing")

        gcmd.respond_raw("ZEXCLUDE: End")

    def cmd_SAVE_SHAPER(self, gcmd):
        shaper_name = gcmd.get('NAME', '').lower()
        frequency = gcmd.get_float('FREQUENCY', 0.0)
        shaper_axis = gcmd.get('AXIS', '').lower()

        # Валидация параметров
        valid_shapers = ['mzv', 'zv', 'zvd', 'ei', '2hump_ei', '3hump_ei']
        if shaper_name not in valid_shapers:
            if self.lang != 'ru':
                raise gcmd.error("Invalid shaper. Allowed: %s" % ', '.join(valid_shapers))
            else:
                raise gcmd.error("Неверный шейпер. Допустимые: %s" % ', '.join(valid_shapers))
        if frequency <= 0:
            if self.lang != 'ru':
                raise gcmd.error("Frequency must be > 0")
            else:
                raise gcmd.error("Частота должна быть > 0")
        if shaper_axis not in ['x', 'y']:
            if self.lang != 'ru':
                raise gcmd.error("Axis must be X or Y")
            else:
                raise gcmd.error("Ось должна быть X или Y")

        # Сохранение параметров через Klipper API
        configfile = self.printer.lookup_object('configfile')
        configfile.set('input_shaper', 'shaper_type_%s' % shaper_axis, shaper_name)
        configfile.set('input_shaper', 'shaper_freq_%s' % shaper_axis, "%.1f" % frequency)

        # Информационное сообщение
        if self.lang != 'ru':
            gcmd.respond_info(
                "Parameters for axis %s have been saved. Run SAVE_CONFIG to apply changes." %
                shaper_axis.upper()
            )
        else:
            gcmd.respond_info(
                "Параметры для оси %s сохранены. Для применения выполните SAVE_CONFIG" %
                shaper_axis.upper()
            )

def load_config(config):
    return zmod(config)
