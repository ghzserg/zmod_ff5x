class zmod:
    def __init__(self, config):
        self.printer = config.get_printer()
        gcode = self.printer.lookup_object('gcode')
        gcode.register_command('SAVE_SHAPER', self.cmd_SAVE_SHAPER)
        gcode.register_command('SET_ZMOD_LANG_EN', self.cmd_SET_ZMOD_LANG_EN)
        gcode.register_command('SET_ZMOD_LANG_RU', self.cmd_SET_ZMOD_LANG_RU)
        self.language = 'ru'

    def get_lang(self):
        return self.language

    def cmd_SAVE_SHAPER(self, gcmd):
        shaper_name = gcmd.get('NAME', '').lower()
        frequency = gcmd.get_float('FREQUENCY', 0.0)
        shaper_axis = gcmd.get('AXIS', '').lower()

        # Валидация параметров
        valid_shapers = ['mzv', 'zv', 'zvd', 'ei', '2hump_ei', '3hump_ei']
        if shaper_name not in valid_shapers:
            if self.language == 'en':
                raise gcmd.error("Invalid shaper. Allowed: %s" % ', '.join(valid_shapers))
            else:
                raise gcmd.error("Неверный шейпер. Допустимые: %s" % ', '.join(valid_shapers))
        if frequency <= 0:
            if self.language == 'en':
                raise gcmd.error("Frequency must be > 0")
            else:
                raise gcmd.error("Частота должна быть > 0")
        if shaper_axis not in ['x', 'y']:
            if self.language == 'en':
                raise gcmd.error("Axis must be X or Y")
            else:
                raise gcmd.error("Ось должна быть X или Y")

        # Сохранение параметров через Klipper API
        configfile = self.printer.lookup_object('configfile')
        configfile.set('input_shaper', 'shaper_type_%s' % shaper_axis, shaper_name)
        configfile.set('input_shaper', 'shaper_freq_%s' % shaper_axis, "%.1f" % frequency)

        # Информационное сообщение
        if self.language == 'en':
            gcmd.respond_info(
                "Parameters for axis %s have been saved. Run SAVE_CONFIG to apply changes." %
                shaper_axis.upper()
            )
        else:
            gcmd.respond_info(
                "Параметры для оси %s сохранены. Для применения выполните SAVE_CONFIG" %
                shaper_axis.upper()
            )

    def cmd_SET_ZMOD_LANG_EN(self, gcmd):
        self.language = 'en'

    def cmd_SET_ZMOD_LANG_RU(self, gcmd):
        self.language = 'ru'

def load_config(config):
    return zmod(config)
