import os

class zmod:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.language = config.get('language', 'en')
        self.gcode = self.printer.lookup_object('gcode')
        gcode_macro = self.printer.load_object(config, 'gcode_macro')
        self.on_error_gcode = gcode_macro.load_template(
            config, 'on_error_gcode', '')

        self.virtual_sdcard = self.printer.lookup_object('virtual_sdcard')
        self.sdcard_dirname = self.virtual_sdcard.sdcard_dirname

        self.gcode.register_command('SAVE_SHAPER', self.cmd_SAVE_SHAPER)
        self.gcode.register_command('ZEXCLUDE', self.cmd_ZEXCLUDE)

    def get_lang(self):
        return self.language

    def cmd_ZEXCLUDE(self, gcmd):
        filename = gcmd.get("FILENAME")
        if filename[0] == '/':
            filename = filename[1:]
        if not filename:
            raise gcmd.error("FILENAME is required")

        full_path = os.path.join(self.sdcard_dirname, filename)

        try:
            with open(full_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue

                    if line.startswith('EXCLUDE_OBJECT_DEFINE'):
                        try:
                            self.gcode.run_script(line)
                        except self.gcode.error as e:
                            error_message = str(e)
                            try:
                                self.gcode.run_script(self.on_error_gcode.render())
                            except:
                                logging.exception("zexclude_error")
                            break
                        except:
                            logging.exception("zexclude_error")
                            break
        except FileNotFoundError:
            gcmd.respond_error(f"File not found: {full_path}")
        except Exception:
            logging.exception("zexclude_file_error")

    def cmd_SAVE_SHAPER(self, gcmd):
        shaper_name = gcmd.get('NAME', '').lower()
        frequency = gcmd.get_float('FREQUENCY', 0.0)
        shaper_axis = gcmd.get('AXIS', '').lower()

        # Валидация параметров
        valid_shapers = ['mzv', 'zv', 'zvd', 'ei', '2hump_ei', '3hump_ei']
        if shaper_name not in valid_shapers:
            if self.language != 'ru':
                raise gcmd.error("Invalid shaper. Allowed: %s" % ', '.join(valid_shapers))
            else:
                raise gcmd.error("Неверный шейпер. Допустимые: %s" % ', '.join(valid_shapers))
        if frequency <= 0:
            if self.language != 'ru':
                raise gcmd.error("Frequency must be > 0")
            else:
                raise gcmd.error("Частота должна быть > 0")
        if shaper_axis not in ['x', 'y']:
            if self.language != 'ru':
                raise gcmd.error("Axis must be X or Y")
            else:
                raise gcmd.error("Ось должна быть X или Y")

        # Сохранение параметров через Klipper API
        configfile = self.printer.lookup_object('configfile')
        configfile.set('input_shaper', 'shaper_type_%s' % shaper_axis, shaper_name)
        configfile.set('input_shaper', 'shaper_freq_%s' % shaper_axis, "%.1f" % frequency)

        # Информационное сообщение
        if self.language != 'ru':
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
