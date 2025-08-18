DELETE FROM "main"."namespace_store"  WHERE namespace="fluidd" AND key="macros";
INSERT INTO "main"."namespace_store" ("namespace", "key", "value") VALUES ('fluidd', 'macros', '{
    "categories": [
        {
            "id": "944c031b-feef-4b75-badf-21c30508fb24",
            "name": "0. Main"
        },
        {
            "id": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "name": "1. Calibrations"
        },
        {
            "id": "0077449b-cd10-4059-aebd-bf17be6cb270",
            "name": "2. System"
        },
        {
            "id": "09a46273-5af4-4fc4-b232-442934c1e810",
            "name": "3. ZMOD"
        },
        {
            "id": "89ac157d-a16a-43f1-900a-498d683bf557",
            "name": "4. Filament"
        },
        {
            "id": "e004b7a8-256d-4070-8d81-90a2ccef470b",
            "name": "5. Pro"
        },
        {
            "id": "5ceaef9c-2e66-4bbf-998b-94fcab116597",
            "name": "6. Macro call on layer"
        },
        {
            "id": "69809e15-439e-45e3-b181-42ccbdde50eb",
            "name": "7. Rare"
        }
    ],
    "expanded": [
        0
    ],
    "stored": [
        {
            "alias": "",
            "categoryId": "e004b7a8-256d-4070-8d81-90a2ccef470b",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "air_circulation_external",
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "e004b7a8-256d-4070-8d81-90a2ccef470b",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "air_circulation_internal",
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "e004b7a8-256d-4070-8d81-90a2ccef470b",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "air_circulation_stop",
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "69809e15-439e-45e3-b181-42ccbdde50eb",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "set_timezone",
            "order": 1,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "09a46273-5af4-4fc4-b232-442934c1e810",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "zssh_on",
            "order": 7,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "0077449b-cd10-4059-aebd-bf17be6cb270",
            "color": "",
            "disabledWhilePrinting": true,
            "name": "test_emmc",
            "order": 4,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "0077449b-cd10-4059-aebd-bf17be6cb270",
            "color": "#ff0000",
            "disabledWhilePrinting": true,
            "name": "clear_emmc",
            "order": 5,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "09a46273-5af4-4fc4-b232-442934c1e810",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "zssh_off",
            "order": 8,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "09a46273-5af4-4fc4-b232-442934c1e810",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "zssh_restart",
            "order": 5,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "69809e15-439e-45e3-b181-42ccbdde50eb",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "zssh_reload",
            "order": 0,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "09a46273-5af4-4fc4-b232-442934c1e810",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "tar_config",
            "order": 9,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "09a46273-5af4-4fc4-b232-442934c1e810",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "restore_tar_config",
            "order": 10,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "09a46273-5af4-4fc4-b232-442934c1e810",
            "color": "",
            "disabledWhilePrinting": true,
            "name": "zflash",
            "order": 11,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "69809e15-439e-45e3-b181-42ccbdde50eb",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "stop_zmod",
            "order": 5,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "69809e15-439e-45e3-b181-42ccbdde50eb",
            "color": "",
            "disabledWhilePrinting": true,
            "name": "start_zmod",
            "order": 4,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "69809e15-439e-45e3-b181-42ccbdde50eb",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "date_get",
            "order": 2,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "0077449b-cd10-4059-aebd-bf17be6cb270",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "web",
            "order": 7,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "69809e15-439e-45e3-b181-42ccbdde50eb",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "date_set",
            "order": 3,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "check_md5",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "t1",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "t2",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "t3",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "t4",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "g28",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "m24",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "m25",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "set_fan_speed",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "line_purge",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "g17",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "g18",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "g19",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "kamp",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0077449b-cd10-4059-aebd-bf17be6cb270",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "mem",
            "order": 6,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "0077449b-cd10-4059-aebd-bf17be6cb270",
            "color": "",
            "disabledWhilePrinting": true,
            "name": "update_mcu",
            "order": 14,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "0077449b-cd10-4059-aebd-bf17be6cb270",
            "color": "#00ff00",
            "disabledWhilePrinting": true,
            "name": "check_system",
            "order": 3,
            "visible": true
        },
        {
            "alias": "Reset password",
            "categoryId": "0077449b-cd10-4059-aebd-bf17be6cb270",
            "color": "#00ff00",
            "disabledWhilePrinting": false,
            "name": "reset_passwd",
            "order": 15,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "#ff0000",
            "disabledWhilePrinting": true,
            "name": "reboot",
            "order": 2,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "restart_guppy",
            "order": 11,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": true,
            "name": "zrestore",
            "order": 10,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "mute",
            "order": 1,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "clear_nozzle",
            "order": 4,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "0077449b-cd10-4059-aebd-bf17be6cb270",
            "color": "#ff0000",
            "disabledWhilePrinting": false,
            "name": "shutdown",
            "order": 10,
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "69809e15-439e-45e3-b181-42ccbdde50eb",
            "color": "#ff0000",
            "disabledWhilePrinting": false,
            "name": "skip_zmod",
            "order": 6,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "09a46273-5af4-4fc4-b232-442934c1e810",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "camera_off",
            "order": 2,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "#008800",
            "disabledWhilePrinting": false,
            "name": "camera_restart",
            "order": 12,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "09a46273-5af4-4fc4-b232-442934c1e810",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "camera_on",
            "order": 1,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "0077449b-cd10-4059-aebd-bf17be6cb270",
            "color": "#ff0000",
            "disabledWhilePrinting": true,
            "name": "display_off",
            "order": 8,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "0077449b-cd10-4059-aebd-bf17be6cb270",
            "color": "#ff0000",
            "disabledWhilePrinting": true,
            "name": "display_on",
            "order": 9,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "m106",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "m107",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "m300",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "m356",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "m357",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "69809e15-439e-45e3-b181-42ccbdde50eb",
            "color": "#ff0000",
            "disabledWhilePrinting": true,
            "name": "remove_zmod",
            "order": 7,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "",
            "disabledWhilePrinting": true,
            "name": "auto_full_bed_level",
            "order": 1,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "",
            "disabledWhilePrinting": true,
            "name": "zshaper",
            "order": 7,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "",
            "disabledWhilePrinting": true,
            "name": "belts_shaper_calibration",
            "order": 6,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "",
            "disabledWhilePrinting": true,
            "name": "bed_level_screws_tune",
            "order": 0,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "#ff0000",
            "disabledWhilePrinting": true,
            "name": "nozzle_control",
            "order": 5,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "load_gcode_offset",
            "order": 8,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "set_gcode_offset",
            "order": 9,
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "set_led",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "save_gcode_offset",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "#ff0000",
            "disabledWhilePrinting": false,
            "name": "cancel_print",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "#008800",
            "disabledWhilePrinting": false,
            "name": "led",
            "order": 0,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "led_off",
            "order": 6,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "led_on",
            "order": 7,
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "",
            "disabledWhilePrinting": true,
            "name": "pid_tune_bed",
            "order": 2,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "play_midi",
            "order": 9,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "#00ff00",
            "disabledWhilePrinting": false,
            "name": "resume",
            "order": 14,
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "",
            "disabledWhilePrinting": true,
            "name": "pid_tune_extruder",
            "order": 3,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "89ac157d-a16a-43f1-900a-498d683bf557",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "coldpull",
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "89ac157d-a16a-43f1-900a-498d683bf557",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "load_material",
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "89ac157d-a16a-43f1-900a-498d683bf557",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "load_filament",
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "#ffff00",
            "disabledWhilePrinting": false,
            "name": "pause",
            "order": 13,
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "89ac157d-a16a-43f1-900a-498d683bf557",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "purge_filament",
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "89ac157d-a16a-43f1-900a-498d683bf557",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "unload_filament",
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "89ac157d-a16a-43f1-900a-498d683bf557",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "m600",
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "0",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "m900",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "5ceaef9c-2e66-4bbf-998b-94fcab116597",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "bed_mesh_calibrate",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "244d667b-c410-4e01-9bf1-e8e0b9deabe2",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "load_cell_tare",
            "order": 4,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "5ceaef9c-2e66-4bbf-998b-94fcab116597",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "end_print",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "5ceaef9c-2e66-4bbf-998b-94fcab116597",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "set_pause_at_layer",
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "5ceaef9c-2e66-4bbf-998b-94fcab116597",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "set_pause_next_layer",
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "5ceaef9c-2e66-4bbf-998b-94fcab116597",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "set_print_stats_info",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "5ceaef9c-2e66-4bbf-998b-94fcab116597",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "start_print",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "close_dialogs",
            "order": 5,
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "leveling_print_file",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "sdcard_print_file",
            "order": 15,
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "sdcard_reset_file",
            "order": 16,
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "noleveling_print_file",
            "visible": false
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "fast_close_dialogs",
            "order": 3,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "09a46273-5af4-4fc4-b232-442934c1e810",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "get_zmod_data",
            "order": 3,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "",
            "disabledWhilePrinting": false,
            "name": "new_save_config",
            "order": 8,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "#008800",
            "disabledWhilePrinting": false,
            "name": "save_zmod_data",
            "order": 13,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "#008800",
            "disabledWhilePrinting": true,
            "name": "color",
            "order": 14,
            "visible": true
        },
        {
            "alias": "",
            "categoryId": "944c031b-feef-4b75-badf-21c30508fb24",
            "color": "#008800",
            "disabledWhilePrinting": true,
            "name": "lang",
            "visible": true
        }
    ]
}');
DELETE FROM "main"."namespace_store"  WHERE namespace="mainsail" AND key="macros";
INSERT INTO "main"."namespace_store" ("namespace", "key", "value") VALUES ('mainsail', 'macros', '{
   "macrogroups" : {
      "1517f6e7-1f5a-49da-8f35-8b68eab60038" : {
         "color" : "primary",
         "colorCustom" : "#fff",
         "macros" : [
            {
               "color" : "group",
               "name" : "AUTO_FULL_BED_LEVEL",
               "pos" : 1,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "BED_LEVEL_SCREWS_TUNE",
               "pos" : 2,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "PID_TUNE_BED",
               "pos" : 3,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "PID_TUNE_EXTRUDER",
               "pos" : 4,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "LOAD_CELL_TARE",
               "pos" : 5,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "ZSHAPER",
               "pos" : 6,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "BELTS_SHAPER_CALIBRATION",
               "pos" : 7,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "LOAD_GCODE_OFFSET",
               "pos" : 8,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "NOZZLE_CONTROL",
               "pos" : 9,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : true
            }
         ],
         "name" : "1. Calibrations",
         "showInPause" : true,
         "showInPrinting" : true,
         "showInStandby" : true
      },
      "58151d61-dccd-4951-9836-e18f4d59ed65" : {
         "color" : "primary",
         "colorCustom" : "#fff",
         "macros" : [
            {
               "color" : "group",
               "name" : "LOAD_FILAMENT",
               "pos" : 1,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "LOAD_MATERIAL",
               "pos" : 2,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "PURGE_FILAMENT",
               "pos" : 3,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "UNLOAD_FILAMENT",
               "pos" : 4,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "COLDPULL",
               "pos" : 5,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "M600",
               "pos" : 6,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            }
         ],
         "name" : "3. Filament",
         "showInPause" : true,
         "showInPrinting" : true,
         "showInStandby" : true
      },
      "731852b2-3bf0-422a-a1fb-56d2f1f972a5" : {
         "color" : "primary",
         "colorCustom" : "#fff",
         "macros" : [
            {
               "color" : "group",
               "name" : "REBOOT",
               "pos" : 1,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "SHUTDOWN",
               "pos" : 2,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "LED_ON",
               "pos" : 3,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "LED_OFF",
               "pos" : 4,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "LED",
               "pos" : 5,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "PLAY_MIDI",
               "pos" : 6,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "CLEAR_NOZZLE",
               "pos" : 7,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "LEVELING_PRINT_FILE",
               "pos" : 8,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : false
            },
            {
               "color" : "group",
               "name" : "CLOSE_DIALOGS",
               "pos" : 9,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "FAST_CLOSE_DIALOGS",
               "pos" : 10,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "NEW_SAVE_CONFIG",
               "pos" : 11,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "NOLEVELING_PRINT_FILE",
               "pos" : 12,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : false
            },
            {
               "color" : "group",
               "name" : "G28",
               "pos" : 13,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : false
            },
            {
               "color" : "group",
               "name" : "M24",
               "pos" : 14,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : false
            },
            {
               "color" : "group",
               "name" : "M25",
               "pos" : 15,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : false
            },
            {
               "color" : "group",
               "name" : "SDCARD_RESET_FILE",
               "pos" : 16,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : false
            },
            {
               "color" : "group",
               "name" : "SDCARD_PRINT_FILE",
               "pos" : 17,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : false
            },
            {
               "color" : "group",
               "name" : "MUTE",
               "pos" : 18,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "ZRESTORE",
               "pos" : 19,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            }
         ],
         "name" : "0. Main",
         "showInPause" : true,
         "showInPrinting" : true,
         "showInStandby" : true
      },
      "9c23dcdb-a9bf-49fe-9473-12b149deb188" : {
         "color" : "primary",
         "colorCustom" : "#fff",
         "macros" : [
            {
               "color" : "group",
               "name" : "REBOOT",
               "pos" : 1,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "SHUTDOWN",
               "pos" : 2,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "WEB",
               "pos" : 3,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "DISPLAY_ON",
               "pos" : 4,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "DISPLAY_OFF",
               "pos" : 5,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "MEM",
               "pos" : 6,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "CAMERA_ON",
               "pos" : 7,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "CAMERA_RESTART",
               "pos" : 8,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "CAMERA_OFF",
               "pos" : 9,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "DATE_GET",
               "pos" : 10,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "DATE_SET",
               "pos" : 11,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "SET_TIMEZONE",
               "pos" : 12,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "TAR_CONFIG",
               "pos" : 13,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "RESTORE_TAR_CONFIG",
               "pos" : 14,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "GET_ZMOD_DATA",
               "pos" : 15,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "SAVE_ZMOD_DATA",
               "pos" : 16,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "START_ZMOD",
               "pos" : 17,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "STOP_ZMOD",
               "pos" : 18,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "SKIP_ZMOD",
               "pos" : 19,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "REMOVE_ZMOD",
               "pos" : 20,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "ZSSH_RESTART",
               "pos" : 21,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "TEST_EMMC",
               "pos" : 22,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "CLEAR_EMMC",
               "pos" : 23,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "ZSSH_ON",
               "pos" : 24,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "ZSSH_OFF",
               "pos" : 25,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "ZSSH_RELOAD",
               "pos" : 26,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "UPDATE_MCU",
               "pos" : 27,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "CHECK_SYSTEM",
               "pos" : 28,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "RESTART_GUPPY",
               "pos" : 29,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "ZFLASH",
               "pos" : 30,
               "showInPause" : false,
               "showInPrinting" : false,
               "showInStandby" : true
            }
         ],
         "name" : "2. System",
         "showInPause" : true,
         "showInPrinting" : true,
         "showInStandby" : true
      },
      "af5e2632-c4e2-4d53-aed9-f9127b1e5a38" : {
         "color" : "primary",
         "colorCustom" : "#fff",
         "macros" : [
            {
               "color" : "group",
               "name" : "AIR_CIRCULATION_EXTERNAL",
               "pos" : 1,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "AIR_CIRCULATION_INTERNAL",
               "pos" : 2,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            },
            {
               "color" : "group",
               "name" : "AIR_CIRCULATION_STOP",
               "pos" : 3,
               "showInPause" : true,
               "showInPrinting" : true,
               "showInStandby" : true
            }
         ],
         "name" : "4. Pro",
         "showInPause" : true,
         "showInPrinting" : true,
         "showInStandby" : true
      }
   },
   "mode" : "expert"
}
');
DELETE FROM "main"."namespace_store"  WHERE namespace="guppyscreen" AND key="macros";
INSERT INTO "main"."namespace_store" ("namespace", "key", "value") VALUES ('guppyscreen', 'macros', '{
  "settings": {
    "AIR_CIRCULATION_EXTERNAL": {
      "hidden": true
    },
    "AIR_CIRCULATION_INTERNAL": {
      "hidden": true
    },
    "AIR_CIRCULATION_STOP": {
      "hidden": true
    },
    "AUTO_FULL_BED_LEVEL": {
      "hidden": true
    },
    "BED_LEVEL_SCREWS_TUNE": {
      "hidden": true
    },
    "BED_MESH_CALIBRATE": {
      "hidden": true
    },
    "BELTS_SHAPER_CALIBRATION": {
      "hidden": true
    },
    "CAMERA_OFF": {
      "hidden": true
    },
    "CAMERA_ON": {
      "hidden": true
    },
    "CAMERA_RESTART": {
      "hidden": true
    },
    "CANCEL_PRINT": {
      "hidden": true
    },
    "CHECK_MD5": {
      "hidden": true
    },
    "CHECK_SYSTEM": {
      "hidden": true
    },
    "CLEAR_EMMC": {
      "hidden": true
    },
    "CLEAR_NOZZLE": {
      "hidden": true
    },
    "CLOSE_DIALOGS": {
      "hidden": true
    },
    "COLDPULL": {
      "hidden": true
    },
    "DATE_GET": {
      "hidden": true
    },
    "DATE_SET": {
      "hidden": true
    },
    "DISPLAY_OFF": {
      "hidden": true
    },
    "DISPLAY_ON": {
      "hidden": true
    },
    "END_PRINT": {
      "hidden": true
    },
    "FAST_CLOSE_DIALOGS": {
      "hidden": true
    },
    "G17": {
      "hidden": true
    },
    "G18": {
      "hidden": true
    },
    "G19": {
      "hidden": true
    },
    "G28": {
      "hidden": true
    },
    "GET_ZMOD_DATA": {
      "hidden": true
    },
    "KAMP": {
      "hidden": true
    },
    "LED": {
      "hidden": true
    },
    "LED_OFF": {
      "hidden": true
    },
    "LED_ON": {
      "hidden": true
    },
    "LINE_PURGE": {
      "hidden": true
    },
    "LOAD_CELL_TARE": {
      "hidden": true
    },
    "LOAD_FILAMENT": {
      "hidden": true
    },
    "LOAD_GCODE_OFFSET": {
      "hidden": true
    },
    "M106": {
      "hidden": true
    },
    "M107": {
      "hidden": true
    },
    "M24": {
      "hidden": true
    },
    "M25": {
      "hidden": true
    },
    "M300": {
      "hidden": true
    },
    "M356": {
      "hidden": true
    },
    "M357": {
      "hidden": true
    },
    "M600": {
      "hidden": true
    },
    "M900": {
      "hidden": true
    },
    "NEW_SAVE_CONFIG": {
      "hidden": true
    },
    "NOZZLE_CONTROL": {
      "hidden": true
    },
    "PAUSE": {
      "hidden": true
    },
    "PID_TUNE_BED": {
      "hidden": true
    },
    "PID_TUNE_EXTRUDER": {
      "hidden": true
    },
    "PLAY_MIDI": {
      "hidden": true
    },
    "PURGE_FILAMENT": {
      "hidden": true
    },
    "REBOOT": {
      "hidden": true
    },
    "RESTART_GUPPY": {
      "hidden": true
    },
    "REMOVE_ZMOD": {
      "hidden": true
    },
    "RESUME": {
      "hidden": true
    },
    "SAVE_ZMOD_DATA": {
      "hidden": true
    },
    "SHUTDOWN": {
      "hidden": true
    },
    "SDCARD_PRINT_FILE": {
      "hidden": true
    },
    "SDCARD_RESET_FILE": {
      "hidden": true
    },
    "SET_FAN_SPEED": {
      "hidden": true
    },
    "SET_GCODE_OFFSET": {
      "hidden": true
    },
    "SET_LED": {
      "hidden": true
    },
    "SET_PAUSE_AT_LAYER": {
      "hidden": true
    },
    "SET_PAUSE_NEXT_LAYER": {
      "hidden": true
    },
    "SET_PRINT_STATS_INFO": {
      "hidden": true
    },
    "SET_TIMEZONE": {
      "hidden": true
    },
    "SKIP_ZMOD": {
      "hidden": true
    },
    "START_PRINT": {
      "hidden": true
    },
    "START_ZMOD": {
      "hidden": true
    },
    "STOP_ZMOD": {
      "hidden": true
    },
    "TAR_CONFIG": {
      "hidden": true
    },
    "RESTORE_TAR_CONFIG": {
      "hidden": true
    },
    "TEST_EMMC": {
      "hidden": true
    },
    "UNLOAD_FILAMENT": {
      "hidden": true
    },
    "UPDATE_MCU": {
      "hidden": true
    },
    "WEB": {
      "hidden": true
    },
    "ZSHAPER": {
      "hidden": true
    },
    "ZSSH_OFF": {
      "hidden": true
    },
    "ZSSH_ON": {
      "hidden": true
    },
    "ZSSH_RELOAD": {
      "hidden": true
    },
    "ZSSH_RESTART": {
      "hidden": true
    }
  }
}');
