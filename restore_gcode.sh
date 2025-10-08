#!/bin/sh

JSON_FILE="/opt/config/mod_data/klipper_data.json"
TMP_PRINTER="/tmp/printer"

if [ "$1" = "test" ] && [ -f "$JSON_FILE" ]; then
    echo "!! Found unfinished print !!"
    read X Y Z E <<EOF
$(grep '"position":[^]]*' "$JSON_FILE" | sed -E 's/.*\[(.*)\].*/\1/' | tr ',' ' ')
EOF
    echo "_ZRESTORE Z=$Z" > "$TMP_PRINTER"
    exit
fi



if [ -f "$JSON_FILE" ]; then
  read X Y Z E <<EOF
$(grep '"position":[^]]*' "$JSON_FILE" | sed -E 's/.*\[(.*)\].*/\1/' | tr ',' ' ')
EOF

  # Leer objetos excluidos
  EXCLUDED=$(grep -o '"excluded_objects":[^]]*' "$JSON_FILE" | sed -E 's/.*\[(.*)/\1/')

  BED_TARGET=$(grep '"bed_target"' "$JSON_FILE" | sed -E 's/.*"bed_target": *([0-9.]+).*/\1/')
  EXTRUDER_TARGET=$(grep '"extruder_target"' "$JSON_FILE" | sed -E 's/.*"extruder_target": *([0-9.]+).*/\1/')
  ABSOLUTE_COORDS=$(grep '"absolute_coords"' "$JSON_FILE" | grep -o 'true\|false')
  E_MODE=$(grep '"e_mode"' "$JSON_FILE" | sed -E 's/.*"e_mode": *"([^"]+)".*/\1/')
  FAN_SPEED=$(grep '"fan_speed"' "$JSON_FILE" | sed -E 's/.*"fan_speed": *([0-9.]+).*/\1/')
  FILE_PATH=$(grep '"file_path"' "$JSON_FILE" | sed -E 's/.*"file_path": *"([^"]+)".*/\1/')
  FILE_POS=$(grep '"file_position"' "$JSON_FILE" | sed -E 's/.*"file_position": *([0-9.]+).*/\1/')
  EXTRUDE_FACTOR=$(grep '"extrude_factor"' "$JSON_FILE" | sed -E 's/.*"extrude_factor": *([0-9.]+).*/\1/')
  Z_OFFSET=$(grep '"z_offset"' "$JSON_FILE" | sed -E 's/.*"z_offset": *([-0-9.]+).*/\1/')
  PA_VALUE=$(grep '"pressure_advance"' "$JSON_FILE" | grep '"value"' | sed -E 's/.*"value": *([0-9.]+).*/\1/')
  PA_SMOOTH=$(grep '"pressure_advance"' "$JSON_FILE" | grep '"smooth_time"' | sed -E 's/.*"smooth_time": *([0-9.]+).*/\1/')
  RETRACT_LEN=$(grep '"retract_length"' "$JSON_FILE" | sed -E 's/.*"retract_length": *([0-9.]+).*/\1/')
  RETRACT_SPEED=$(grep '"retract_speed"' "$JSON_FILE" | sed -E 's/.*"retract_speed": *([0-9.]+).*/\1/')
  UNRETRACT_LEN=$(grep '"unretract_length"' "$JSON_FILE" | sed -E 's/.*"unretract_length": *([0-9.]+).*/\1/')
  UNRETRACT_SPEED=$(grep '"unretract_speed"' "$JSON_FILE" | sed -E 's/.*"unretract_speed": *([0-9.]+).*/\1/')


  {
    echo "_G28"

    # Objetos excluidos
    for OBJ in $(echo "$EXCLUDED" | tr ',' ' '); do
      echo "EXCLUDE_OBJECT NAME=$OBJ"
    done
    
    # Coordenadas absolutas/relativas
    if [ "$ABSOLUTE_COORDS" = "true" ]; then
      echo "G90"
    else
      echo "G91"
    fi

    # Modo extrusión
    if [ "$E_MODE" = "relative" ]; then
      echo "M83"
    else
      echo "M82"
    fi

    echo "SET_GCODE_OFFSET Z=$Z_OFFSET MOVE=0"
    echo "SET_PRESSURE_ADVANCE ADVANCE=$PA_VALUE SMOOTH_TIME=$PA_SMOOTH"
    echo "SET_RETRACTION RETRACT_LENGTH=$RETRACT_LEN RETRACT_SPEED=$RETRACT_SPEED UNRETRACT_EXTRA_LENGTH=$UNRETRACT_LEN UNRETRACT_SPEED=$UNRETRACT_SPEED"
    echo "M221 S$(echo "$EXTRUDE_FACTOR * 100" | bc)" # escala en %

    echo "G92 E$E"
    echo "G0 X$X Y$Y F6000"
    echo "G0 Z$Z"

    #echo "M140 S$BED_TARGET"
    #echo "M104 S$EXTRUDER_TARGET"
    echo "M106 S$(echo "$FAN_SPEED * 255" | bc)"

    echo "M23 $(basename "$FILE_PATH")"
    echo "M26 S$FILE_POS"
    echo "M24"
  } | tee "$TMP_PRINTER"

fi
