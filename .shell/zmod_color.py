import json
import requests
import subprocess

COLOR_MAPPING = {
    "ffffff": {
        "ru": "белый", "en": "white",
        "de": "weiß", "fr": "blanc", "it": "bianco", "es": "blanco",
        "zh": "白色", "ja": "白", "ko": "흰색"
    },
    "fef043": {
        "ru": "ярко-желтый", "en": "bright yellow",
        "de": "knallgelb", "fr": "jaune vif", "it": "giallo brillante", "es": "amarillo brillante",
        "zh": "亮黄色", "ja": "明るい黄色", "ko": "밝은 노란색"
    },
    "dcf478": {
        "ru": "светло-зеленый", "en": "light green",
        "de": "hellgrün", "fr": "vert clair", "it": "verde chiaro", "es": "verde claro",
        "zh": "浅绿色", "ja": "薄緑", "ko": "연두색"
    },
    "0acc38": {
        "ru": "зеленый", "en": "green",
        "de": "grün", "fr": "vert", "it": "verde", "es": "verde",
        "zh": "绿色", "ja": "緑", "ko": "초록색"
    },
    "067749": {
        "ru": "темно-зеленый", "en": "dark green",
        "de": "dunkelgrün", "fr": "vert foncé", "it": "verde scuro", "es": "verde oscuro",
        "zh": "深绿色", "ja": "濃い緑", "ko": "진한 녹색"
    },
    "0c6283": {
        "ru": "сине-зеленый", "en": "cyan",
        "de": "türkis", "fr": "cyan", "it": "ciano", "es": "cian",
        "zh": "青绿色", "ja": "シアン", "ko": "청록색"
    },
    "0de2a0": {
        "ru": "бирюзовый", "en": "turquoise",
        "de": "türkis", "fr": "turquoise", "it": "turchese", "es": "turquesa",
        "zh": "绿松石色", "ja": "ターコイズ", "ko": "터키석색"
    },
    "75d9f3": {
        "ru": "голубой", "en": "light blue",
        "de": "hellblau", "fr": "bleu clair", "it": "azzurro", "es": "azul claro",
        "zh": "天蓝色", "ja": "水色", "ko": "하늘색"
    },
    "45a8f9": {
        "ru": "синий", "en": "blue",
        "de": "blau", "fr": "bleu", "it": "blu", "es": "azul",
        "zh": "蓝色", "ja": "青", "ko": "파란색"
    },
    "2750e0": {
        "ru": "темно-синий", "en": "dark blue",
        "de": "dunkelblau", "fr": "bleu foncé", "it": "blu scuro", "es": "azul oscuro",
        "zh": "深蓝色", "ja": "濃い青", "ko": "진한 파란색"
    },
    "46328e": {
        "ru": "фиолетовый", "en": "purple",
        "de": "lila", "fr": "violet", "it": "viola", "es": "morado",
        "zh": "紫色", "ja": "紫", "ko": "보라색"
    },
    "a03cf7": {
        "ru": "ярко-фиолетовый", "en": "bright purple",
        "de": "knalllila", "fr": "violet vif", "it": "viola brillante", "es": "morado brillante",
        "zh": "亮紫色", "ja": "明るい紫", "ko": "밝은 보라색"
    },
    "f330f9": {
        "ru": "пурпурный", "en": "magenta",
        "de": "magenta", "fr": "magenta", "it": "magenta", "es": "magenta",
        "zh": "品红色", "ja": "マゼンタ", "ko": "자홍색"
    },
    "d4b0dc": {
        "ru": "сиреневый", "en": "lilac",
        "de": "lilafarben", "fr": "lilas", "it": "lilla", "es": "lila",
        "zh": "丁香色", "ja": "ライラック", "ko": "라일락색"
    },
    "f95d73": {
        "ru": "розовый", "en": "pink",
        "de": "rosa", "fr": "rose", "it": "rosa", "es": "rosa",
        "zh": "粉色", "ja": "ピンク", "ko": "분홍색"
    },
    "f72224": {
        "ru": "красный", "en": "red",
        "de": "rot", "fr": "rouge", "it": "rosso", "es": "rojo",
        "zh": "红色", "ja": "赤", "ko": "빨간색"
    },
    "7c4b00": {
        "ru": "коричневый", "en": "brown",
        "de": "braun", "fr": "marron", "it": "marrone", "es": "marrón",
        "zh": "棕色", "ja": "茶色", "ko": "갈색"
    },
    "f98d33": {
        "ru": "оранжевый", "en": "orange",
        "de": "orange", "fr": "orange", "it": "arancione", "es": "naranja",
        "zh": "橙色", "ja": "オレンジ", "ko": "주황색"
    },
    "fdebd5": {
        "ru": "бежевый", "en": "beige",
        "de": "beige", "fr": "beige", "it": "beige", "es": "beige",
        "zh": "米色", "ja": "ベージュ", "ko": "베이지색"
    },
    "d3c4a3": {
        "ru": "светло-коричневый", "en": "light brown",
        "de": "hellbraun", "fr": "brun clair", "it": "marrone chiaro", "es": "marrón claro",
        "zh": "浅棕色", "ja": "薄茶色", "ko": "연한 갈색"
    },
    "af7836": {
        "ru": "терракотовый", "en": "terracotta",
        "de": "terracotta", "fr": "terre cuite", "it": "terracotta", "es": "terracota",
        "zh": "陶土色", "ja": "テラコッタ", "ko": "테라코타색"
    },
    "898989": {
        "ru": "серый", "en": "gray",
        "de": "grau", "fr": "gris", "it": "grigio", "es": "gris",
        "zh": "灰色", "ja": "灰色", "ko": "회색"
    },
    "bcbcbc": {
        "ru": "светло-серый", "en": "light gray",
        "de": "hellgrau", "fr": "gris clair", "it": "grigio chiaro", "es": "gris claro",
        "zh": "浅灰色", "ja": "薄灰色", "ko": "연한 회색"
    },
    "161616": {
        "ru": "черный", "en": "black",
        "de": "schwarz", "fr": "noir", "it": "nero", "es": "negro",
        "zh": "黑色", "ja": "黒", "ko": "검은색"
    }
}

TRANSLATIONS = {
    'ru': {
        'cancel': "Отмена",
        'change_color': "Сменить цвет",
        'change_spool': "Меняю на катушку {}: {} / {}",
        'change_type': "Сменить тип",
        'config_error': "!! Ошибка смены цвета / типа\n{}",
        'config_success': "Настройки сохранены",
        'error_color_or_type': "Укажите HEX или TYPE",
        'error_leveling': "Неверный LEVELING: {}. Допустимо: 0 или 1",
        'error_napr': "Недопустимое направление (0-1)",
        'error_no_filename': "Не указано имя файла (FILENAME).",
        'error_slot': "Неверный SLOT. Допустимые: 1-4",
        'error_tool': "Неверный TOOL{}: {}. Допустимо: 1-4",
        'error_type': "Неверный тип материала: {}. Допустимо: {}",
        'file_tool': "В файле",
        'load_error': "!! Ошибка загрузки / выгружки\n{}",
        'load_success': "Загрузка началась",
        'load': "Загрузить",
        'no_response': "!! Нет ответа от принтера. Настройте принтер: \"Настройки\" -> \"WiFi\" -> \"Сетевой режим\" -> \"Только локальные сети\"\n{}",
        'printing_error': "!! Ошибка печати файла\n{}",
        'prompt_choose': "Выберите катушку для изменения",
        'prompt_file': "Файл для печати: {}",
        'prompt_leveling_off': "Печать без карты стола",
        'prompt_leveling_on': "Печать с картой стола",
        'prompt_map_color': "Сопоставьте цвет из файла с катушкой",
        'prompt_material': "Загруженный материал",
        'reset_colors': "Сбросить цвета",
        'select_action': "Выберите действие",
        'select_color': "Выберите цвет",
        'select_type': "Выберите тип материала",
        'send_print': "Отправить на печать",
        'spool_info': "Катушка {}: {}/{}",
        'spool': "в катушке",
        'unload_error': "Ошибка выгрузки: {}",
        'unload_success': "Выгрузка начата",
        'unload': "Выгрузить"
    },
    'en': {
        'cancel': "Cancel",
        'change_color': "Change color",
        'change_spool': "Changing to spool {}: {}/{}",
        'change_type': "Change type",
        'config_error': "!! Error changing color/type\n{}",
        'config_success': "Settings saved",
        'error_color_or_type': "Specify HEX or TYPE",
        'error_leveling': "Invalid LEVELING: {}. Valid: 0 or 1",
        'error_napr': "Invalid direction (0-1)",
        'error_no_filename': "Missing FILENAME parameter",
        'error_slot': "Invalid SLOT. Valid: 1-4",
        'error_tool': "Invalid TOOL{}: {}. Valid: 1-4",
        'error_type': "Invalid material type: {}. Valid: {}",
        'file_tool': "In file",
        'load_error': "!! Load/unload error\n{}",
        'load_success': "Loading started",
        'load': "Load",
        'no_response': "!! No response from printer. Configure via: \"Settings\" -> \"WiFi\" -> \"Network Mode\" -> \"Local Only\"\n{}",
        'printing_error': "!! File printing error\n{}",
        'prompt_choose': "Select a spool to modify",
        'prompt_file': "File to print: {}",
        'prompt_leveling_off': "Print without bed leveling",
        'prompt_leveling_on': "Print with bed leveling",
        'prompt_map_color': "Map file color to spool",
        'prompt_material': "Loaded material",
        'reset_colors': "Reset colors",
        'select_action': "Select action",
        'select_color': "Select color",
        'select_type': "Select material type",
        'send_print': "Start print",
        'spool_info': "Spool {}: {}/{}",
        'spool': "in spool",
        'unload_error': "Unloading error: {}",
        'unload_success': "Unloading started",
        'unload': "Unload"
    },
    'de': {
        'cancel': "Abbrechen",
        'change_color': "Farbe ändern",
        'change_spool': "Wechsle zu Spule {}: {}/{}",
        'change_type': "Typ ändern",
        'config_error': "!! Fehler beim Ändern von Farbe/Typ\n{}",
        'config_success': "Einstellungen gespeichert",
        'error_color_or_type': "Geben Sie HEX oder TYP an",
        'error_leveling': "Ungültiges LEVELING: {}. Erlaubt: 0 oder 1",
        'error_napr': "Ungültige Richtung (0-1)",
        'error_no_filename': "Dateiname nicht angegeben (FILENAME)",
        'error_slot': "Ungültiger SLOT. Erlaubt: 1-4",
        'error_tool': "Ungültiges TOOL{}: {}. Erlaubt: 1-4",
        'error_type': "Ungültiger Materialtyp: {}. Erlaubt: {}",
        'file_tool': "In Datei",
        'load_error': "!! Fehler beim Laden/Entladen\n{}",
        'load_success': "Laden gestartet",
        'load': "Laden",
        'no_response': "!! Keine Antwort vom Drucker. Konfigurieren Sie: \"Einstellungen\" -> \"WLAN\" -> \"Netzwerkmodus\" -> \"Nur lokal\"\n{}",
        'printing_error': "!! Fehler beim Drucken der Datei\n{}",
        'prompt_choose': "Wählen Sie eine Spule zum Ändern",
        'prompt_file': "Zu druckende Datei: {}",
        'prompt_leveling_off': "Drucken ohne Bett-Nivellierung",
        'prompt_leveling_on': "Drucken mit Bett-Nivellierung",
        'prompt_map_color': "Farbe aus Datei einer Spule zuordnen",
        'prompt_material': "Geladenes Material",
        'reset_colors': "Farben zurücksetzen",
        'select_action': "Aktion auswählen",
        'select_color': "Farbe auswählen",
        'select_type': "Materialtyp auswählen",
        'send_print': "Druck starten",
        'spool_info': "Spule {}: {}/{}",
        'spool': "in Spule",
        'unload_error': "Fehler beim Entladen: {}",
        'unload_success': "Entladen gestartet",
        'unload': "Entladen"
    },
    'fr': {
        'cancel': "Annuler",
        'change_color': "Changer la couleur",
        'change_spool': "Changement vers la bobine {}: {}/{}",
        'change_type': "Changer le type",
        'config_error': "!! Erreur lors du changement de couleur/type\n{}",
        'config_success': "Paramètres enregistrés",
        'error_color_or_type': "Indiquez HEX ou TYPE",
        'error_leveling': "LEVELING invalide: {}. Autorisé: 0 ou 1",
        'error_napr': "Direction invalide (0-1)",
        'error_no_filename': "Nom de fichier non spécifié (FILENAME)",
        'error_slot': "Emplacement SLOT invalide. Autorisé: 1-4",
        'error_tool': "Outil TOOL{} invalide: {}. Autorisé: 1-4",
        'error_type': "Type de matériau invalide: {}. Autorisé: {}",
        'file_tool': "Dans le fichier",
        'load_error': "!! Erreur de chargement/déchargement\n{}",
        'load_success': "Chargement commencé",
        'load': "Charger",
        'no_response': "!! Aucune réponse de l'imprimante. Configurez via : \"Paramètres\" -> \"WiFi\" -> \"Mode réseau\" -> \"Réseau local uniquement\"\n{}",
        'printing_error': "!! Erreur d'impression du fichier\n{}",
        'prompt_choose': "Sélectionnez une bobine à modifier",
        'prompt_file': "Fichier à imprimer : {}",
        'prompt_leveling_off': "Imprimer sans nivellement du lit",
        'prompt_leveling_on': "Imprimer avec nivellement du lit",
        'prompt_map_color': "Associer la couleur du fichier à une bobine",
        'prompt_material': "Matériau chargé",
        'reset_colors': "Réinitialiser les couleurs",
        'select_action': "Sélectionner une action",
        'select_color': "Sélectionner une couleur",
        'select_type': "Sélectionner un type de matériau",
        'send_print': "Démarrer l'impression",
        'spool_info': "Bobine {}: {}/{}",
        'spool': "dans la bobine",
        'unload_error': "Erreur de déchargement : {}",
        'unload_success': "Déchargement commencé",
        'unload': "Décharger"
    },
    'it': {
        'cancel': "Annulla",
        'change_color': "Cambia colore",
        'change_spool': "Cambio a bobina {}: {}/{}",
        'change_type': "Cambia tipo",
        'config_error': "!! Errore durante la modifica di colore/tipo\n{}",
        'config_success': "Impostazioni salvate",
        'error_color_or_type': "Specificare HEX o TYPE",
        'error_leveling': "LEVELING non valido: {}. Consentiti: 0 o 1",
        'error_napr': "Direzione non valida (0-1)",
        'error_no_filename': "Nome file non specificato (FILENAME)",
        'error_slot': "Slot non valido. Consentiti: 1-4",
        'error_tool': "Strumento TOOL{} non valido: {}. Consentiti: 1-4",
        'error_type': "Tipo di materiale non valido: {}. Consentiti: {}",
        'file_tool': "Nel file",
        'load_error': "!! Errore di caricamento/scaricamento\n{}",
        'load_success': "Caricamento avviato",
        'load': "Carica",
        'no_response': "!! Nessuna risposta dalla stampante. Configura tramite: \"Impostazioni\" -> \"WiFi\" -> \"Modalità rete\" -> \"Solo locale\"\n{}",
        'printing_error': "!! Errore di stampa del file\n{}",
        'prompt_choose': "Seleziona una bobina da modificare",
        'prompt_file': "File da stampare: {}",
        'prompt_leveling_off': "Stampa senza livellamento del letto",
        'prompt_leveling_on': "Stampa con livellamento del letto",
        'prompt_map_color': "Associa il colore del file alla bobina",
        'prompt_material': "Materiale caricato",
        'reset_colors': "Reimposta colori",
        'select_action': "Seleziona azione",
        'select_color': "Seleziona colore",
        'select_type': "Seleziona tipo di materiale",
        'send_print': "Avvia stampa",
        'spool_info': "Bobina {}: {}/{}",
        'spool': "nella bobina",
        'unload_error': "Errore di scaricamento: {}",
        'unload_success': "Scaricamento avviato",
        'unload': "Scarica"
    },
    'es': {
        'cancel': "Cancelar",
        'change_color': "Cambiar color",
        'change_spool': "Cambiando a carrete {}: {}/{}",
        'change_type': "Cambiar tipo",
        'config_error': "!! Error al cambiar color/tipo\n{}",
        'config_success': "Configuración guardada",
        'error_color_or_type': "Especifique HEX o TYPE",
        'error_leveling': "LEVELING inválido: {}. Permitido: 0 o 1",
        'error_napr': "Dirección inválida (0-1)",
        'error_no_filename': "Nombre de archivo no especificado (FILENAME)",
        'error_slot': "Ranura SLOT inválida. Permitidas: 1-4",
        'error_tool': "Herramienta TOOL{} inválida: {}. Permitidas: 1-4",
        'error_type': "Tipo de material inválido: {}. Permitidos: {}",
        'file_tool': "En el archivo",
        'load_error': "!! Error de carga/descarga\n{}",
        'load_success': "Carga iniciada",
        'load': "Cargar",
        'no_response': "!! Sin respuesta de la impresora. Configure en: \"Ajustes\" -> \"WiFi\" -> \"Modo de red\" -> \"Solo local\"\n{}",
        'printing_error': "!! Error al imprimir el archivo\n{}",
        'prompt_choose': "Seleccione un carrete para modificar",
        'prompt_file': "Archivo para imprimir: {}",
        'prompt_leveling_off': "Imprimir sin nivelación de cama",
        'prompt_leveling_on': "Imprimir con nivelación de cama",
        'prompt_map_color': "Mapear color del archivo al carrete",
        'prompt_material': "Material cargado",
        'reset_colors': "Restablecer colores",
        'select_action': "Seleccionar acción",
        'select_color': "Seleccionar color",
        'select_type': "Seleccionar tipo de material",
        'send_print': "Iniciar impresión",
        'spool_info': "Carrete {}: {}/{}",
        'spool': "en el carrete",
        'unload_error': "Error de descarga: {}",
        'unload_success': "Descarga iniciada",
        'unload': "Descargar"
    },
    'zh': {
        'cancel': "取消",
        'change_color': "更改颜色",
        'change_spool': "正在切换到线轴{}: {}/{}",
        'change_type': "更改类型",
        'config_error': "!! 颜色/类型更改错误\n{}",
        'config_success': "设置已保存",
        'error_color_or_type': "请指定HEX或TYPE",
        'error_leveling': "无效的LEVELING: {}。允许值：0或1",
        'error_napr': "方向无效（0-1）",
        'error_no_filename': "未指定文件名（FILENAME）",
        'error_slot': "无效的SLOT。允许值：1-4",
        'error_tool': "无效的TOOL{}: {}。允许值：1-4",
        'error_type': "无效的材料类型: {}。允许值：{}",
        'file_tool': "文件中",
        'load_error': "!! 加载/卸载错误\n{}",
        'load_success': "开始加载",
        'load': "加载",
        'no_response': "!! 打印机无响应。请通过以下方式配置：\"设置\" -> \"WiFi\" -> \"网络模式\" -> \"仅本地网络\"\n{}",
        'printing_error': "!! 文件打印错误\n{}",
        'prompt_choose': "选择要修改的线轴",
        'prompt_file': "要打印的文件：{}",
        'prompt_leveling_off': "不使用调平打印",
        'prompt_leveling_on': "使用调平打印",
        'prompt_map_color': "将文件颜色映射到线轴",
        'prompt_material': "已加载材料",
        'reset_colors': "重置颜色",
        'select_action': "选择操作",
        'select_color': "选择颜色",
        'select_type': "选择材料类型",
        'send_print': "开始打印",
        'spool_info': "线轴{}: {}/{}",
        'spool': "在线轴中",
        'unload_error': "卸载错误：{}",
        'unload_success': "开始卸载",
        'unload': "卸载"
    },
    'ja': {
        'cancel': "キャンセル",
        'change_color': "色を変更",
        'change_spool': "スプール{}に変更中: {}/{}",
        'change_type': "タイプを変更",
        'config_error': "!! 色/タイプ変更エラー\n{}",
        'config_success': "設定が保存されました",
        'error_color_or_type': "HEXまたはTYPEを指定してください",
        'error_leveling': "無効なLEVELING: {}。0または1のみ有効",
        'error_napr': "方向が無効です（0-1）",
        'error_no_filename': "ファイル名が指定されていません（FILENAME）",
        'error_slot': "無効なSLOTです。1-4が有効",
        'error_tool': "無効なTOOL{}: {}。1-4が有効",
        'error_type': "無効な材料タイプ: {}。有効なタイプ：{}",
        'file_tool': "ファイル内",
        'load_error': "!! 読み込み/排出エラー\n{}",
        'load_success': "読み込み開始",
        'load': "読み込む",
        'no_response': "!! プリンターから応答なし。設定方法：\"設定\" -> \"WiFi\" -> \"ネットワークモード\" -> \"ローカルのみ\"\n{}",
        'printing_error': "!! ファイル印刷エラー\n{}",
        'prompt_choose': "変更するスプールを選択",
        'prompt_file': "印刷するファイル：{}",
        'prompt_leveling_off': "ベッドレベリングなしで印刷",
        'prompt_leveling_on': "ベッドレベリングを使用して印刷",
        'prompt_map_color': "ファイルの色をスプールにマッピング",
        'prompt_material': "読み込まれた材料",
        'reset_colors': "色をリセット",
        'select_action': "操作を選択",
        'select_color': "色を選択",
        'select_type': "材料タイプを選択",
        'send_print': "印刷を開始",
        'spool_info': "スプール{}: {}/{}",
        'spool': "スプール内",
        'unload_error': "排出エラー：{}",
        'unload_success': "排出を開始",
        'unload': "排出する"
    },
    'ko': {
        'cancel': "취소",
        'change_color': "색상 변경",
        'change_spool': "스풀 {}로 교체 중: {}/{}",
        'change_type': "유형 변경",
        'config_error': "!! 색상/유형 변경 오류\n{}",
        'config_success': "설정이 저장되었습니다",
        'error_color_or_type': "HEX 또는 TYPE을 지정하세요",
        'error_leveling': "잘못된 LEVELING: {}. 0 또는 1만 허용",
        'error_napr': "방향이 잘못되었습니다 (0-1)",
        'error_no_filename': "파일 이름이 지정되지 않음 (FILENAME)",
        'error_slot': "잘못된 SLOT. 1-4만 허용",
        'error_tool': "잘못된 TOOL{}: {}. 1-4만 허용",
        'error_type': "잘못된 재료 유형: {}. 허용된 유형: {}",
        'file_tool': "파일 내",
        'load_error': "!! 로드/언로드 오류\n{}",
        'load_success': "로드 시작",
        'load': "로드",
        'no_response': "!! 프린터 응답 없음. 설정 방법: \"설정\" -> \"WiFi\" -> \"네트워크 모드\" -> \"로컬 전용\"\n{}",
        'printing_error': "!! 파일 인쇄 오류\n{}",
        'prompt_choose': "수정할 스풀 선택",
        'prompt_file': "인쇄할 파일: {}",
        'prompt_leveling_off': "레벨링 없이 인쇄",
        'prompt_leveling_on': "레벨링으로 인쇄",
        'prompt_map_color': "파일 색상을 스풀에 매핑",
        'prompt_material': "로드된 재료",
        'reset_colors': "색상 초기화",
        'select_action': "작업 선택",
        'select_color': "색상 선택",
        'select_type': "재료 유형 선택",
        'send_print': "인쇄 시작",
        'spool_info': "스풀 {}: {}/{}",
        'spool': "스풀 내",
        'unload_error': "언로드 오류: {}",
        'unload_success': "언로드 시작",
        'unload': "언로드"
    }
}

class zmod_color:
    def __init__(self, config):
        self.printer = config.get_printer()

        self.display = config.getboolean('display', True)
        self.language = 'en'
        self.gcode = self.printer.lookup_object('gcode')
        self.gcode.register_command('GET_T', self.cmd_GET_T)
        self.gcode.register_command('GET_ZCOLOR', self.cmd_GET_ZCOLOR)
        self.gcode.register_command('SET_ZCOLOR', self.cmd_SET_ZCOLOR)
        self.gcode.register_command('PRINT_ZCOLOR', self.cmd_PRINT_ZCOLOR)
        self.gcode.register_command('CHANGE_TOOL_ZCOLOR', self.cmd_CHANGE_TOOL_ZCOLOR)
        self.gcode.register_command('RUN_ZCOLOR', self.cmd_RUN_ZCOLOR)
        self.gcode.register_command('CHANGE_ZCOLOR', self.cmd_CHANGE_ZCOLOR)
        self.gcode.register_command('IN_ZCOLOR', self.cmd_IN_ZCOLOR)
        self.printer.register_event_handler("klippy:ready", self._handle_ready)

        with open('/usr/data/config/Adventurer5M.json', 'r') as file:
            data = json.load(file)
            self.serialNumber = data['general']['printerSerialNumber']
            self.checkCode = data['general']['lanCode']

    def _handle_ready(self):
        self.zmod = self.printer.lookup_object('zmod', None)
        if self.zmod is not None:
            self.language = self.zmod.get_lang()
        self.zmod_ifs = self.printer.lookup_object('zmod_ifs', None)

    def get_printer_ip(self):
        interfaces = ['wlan0', 'eth0']
        for iface in interfaces:
            try:
                result = subprocess.run(
                    ['ip', '-br', 'addr', 'show', iface],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    return result.stdout.split()[2].split('/')[0]
            except:
                pass
        return "Not found"

    def get_printer_data_detail(self):
        response_data = {
            "detail": {
                "matlStationInfo": {
                    "slotInfos": []
                }
            }
        }

        with open('/usr/data/config/Adventurer5M.json', 'r') as file:
            config = json.load(file)

            ffm_info = config["FFMInfo"]
            for i in range(0, 5):
                color_key = f"ffmColor{i}"
                type_key = f"ffmType{i}"

                if color_key in ffm_info:
                    slot = {
                        "slotId": str(i),
                        "materialName": ffm_info.get(type_key, "N/A"),
                        "materialColor": ffm_info[color_key],
                        "hasFilament": self.zmod_ifs.get_port(i)
                    }
                    response_data["detail"]["matlStationInfo"]["slotInfos"].append(slot)

        return 200,response_data

    def zsend_post_request(self, api, payload=None, send_data=None):
        base_ip = self.get_printer_ip()
        url = f"http://{base_ip}:8898{api}"
        headers = {
            "Accept": "*/*",
            "Content-Type": "application/json"
        }
        if send_data is not None:
            data = send_data
        else:
            data = {}

        data["serialNumber"] = self.serialNumber
        data["checkCode"] = self.checkCode

        if payload is not None:
            data["payload"] = payload

        try:
            response = requests.post(
                url,
                json=data,
                headers=headers,
                timeout=60
            )
            try:
                response_json = response.json()
            except ValueError:
                return None, response.text
            if response_json.get("code") == 0:
                return response.status_code, response_json
            else:
                response_json["send_data"] = data
                response_json["send_url"] = url
                return None, response_json
        except requests.exceptions.RequestException as e:
            return None, str(e)

    def _t(self, key, *args):
        return TRANSLATIONS[self.language][key].format(*args)

    def parse_printer_response(self, response_data):
        slots_info = []
        slots = response_data.get('detail', {}).get('matlStationInfo', {}).get('slotInfos', [])
        for slot in slots:
            if slot.get('hasFilament', True):
                slot_id = slot.get('slotId', 'N/A')
                material = slot.get('materialName', 'N/A').upper()
                hex_color = slot.get('materialColor', '161616').replace("#", "")
                color_name = COLOR_MAPPING.get(hex_color.lower(), {}).get(self.language, hex_color)
                slots_info.append({
                    'ID': slot_id,
                    'Material': material,
                    'Color': color_name,
                    'HEX': hex_color.upper()
                })
        return slots_info

    def cmd_GET_T(self, gcmd):
        zslot = gcmd.get_int('SLOT', 0)
        if zslot < 1 or zslot > 4:
            raise gcmd.error(self._t('error_slot'))
        if self.display:
            status_code, response_data = self.zsend_post_request("/detail")
        else:
            status_code, response_data = self.get_printer_data_detail()
        if status_code:
            result = self.parse_printer_response(response_data)
            for slot in result:
                if zslot == int(slot['ID']):
                    msg = self._t('change_spool', slot['ID'], slot['Material'], slot['Color'])
                    gcmd.respond_raw(msg)
        else:
            gcmd.respond_raw(self._t('no_response', response_data))

    def cmd_GET_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        if self.display:
            status_code, response_data = self.zsend_post_request("/detail")
        else:
            status_code, response_data = self.get_printer_data_detail()
        if status_code:
            gcmd.respond_raw(f"// action:prompt_begin {self._t('prompt_material')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('prompt_choose')}")
            gcmd.respond_raw("// action:prompt_button_group_start")
            result = self.parse_printer_response(response_data)
            for slot in result:
                btn_text = f"{slot['ID']}: {slot['Material']}/{slot['Color']}"
                gcmd.respond_raw(f"// action:prompt_button {btn_text}|RUN_ZCOLOR SLOT={slot['ID']} HEX={slot['HEX']} TYPE={slot['Material']}|primary")
            gcmd.respond_raw("// action:prompt_button_group_end")
            gcmd.respond_raw(f"// action:prompt_footer_button {self._t('cancel')}|RESPOND TYPE=command MSG=action:prompt_end")
            gcmd.respond_raw(f"// action:prompt_footer_button {self._t('reset_colors')}|RESET_ZCOLOR")
            gcmd.respond_raw("// action:prompt_show")
        else:
            gcmd.respond_raw(self._t('no_response', response_data))

    def cmd_SET_ZCOLOR(self, gcmd):
        silent = gcmd.get_int('SILENT', 0)
        if silent == 0:
            gcmd.respond_raw("// action:prompt_end")

        fname = gcmd.get('FILENAME', '')
        if fname == '':
            raise gcmd.error(self._t('error_no_filename'))

        leveling = gcmd.get_int('LEVELING', 0)
        if leveling not in (0, 1):
            raise gcmd.error(self._t('error_leveling', leveling))

        tools = [
            gcmd.get_int('TOOL0', 1),
            gcmd.get_int('TOOL1', 2),
            gcmd.get_int('TOOL2', 3),
            gcmd.get_int('TOOL3', 4)
        ]

        for i, tool in enumerate(tools):
            if tool < 1 or tool > 4:
                raise gcmd.error(self._t('error_tool', i, tool))

        if self.display:
            status_code, response_data = self.zsend_post_request("/detail")
        else:
            status_code, response_data = self.get_printer_data_detail()
        if status_code:
            result = self.parse_printer_response(response_data)

            leveling_text = (
                self._t('prompt_leveling_on')
                if leveling
                else self._t('prompt_leveling_off')
            )

            if silent == 0:
                gcmd.respond_raw(f"// action:prompt_begin {self._t('prompt_material')}")
                gcmd.respond_raw(f"// action:prompt_text {self._t('prompt_map_color')}")
                gcmd.respond_raw(f"// action:prompt_text {self._t('prompt_file', fname)}")

                gcmd.respond_raw(f"// action:prompt_text {leveling_text}")

                gcmd.respond_raw("// action:prompt_button_group_start")
                for tool_idx, tool_val in enumerate(tools):
                    if 0 <= (tool_val - 1) < len(result):
                        slot_info = result[tool_val - 1]
                        btn_text = (
                            f"{self._t('file_tool')} {tool_idx+1} → "
                            f"{self._t('spool')} {slot_info['ID']}: "
                            f"{slot_info['Material']}/{slot_info['Color']}"
                        )
                        params = (
                            f"LEVELING={leveling} FILENAME=\"{fname}\" "
                            f"TOOL0={tools[0]} TOOL1={tools[1]} "
                            f"TOOL2={tools[2]} TOOL3={tools[3]}"
                        )
                        gcmd.respond_raw(
                            f"// action:prompt_button {btn_text}|"
                            f"CHANGE_TOOL_ZCOLOR TOOL={tool_idx+1} {params}|primary"
                        )
                gcmd.respond_raw("// action:prompt_button_group_end")

                gcmd.respond_raw(
                    f"// action:prompt_footer_button {self._t('send_print')}|"
                    f"PRINT_ZCOLOR LEVELING={leveling} FILENAME=\"{fname}\" "
                    f"TOOL0={tools[0]} TOOL1={tools[1]} TOOL2={tools[2]} TOOL3={tools[3]}|red"
                )
                gcmd.respond_raw(f"// action:prompt_footer_button {self._t('cancel')}|RESPOND TYPE=command MSG=action:prompt_end")
                gcmd.respond_raw("// action:prompt_show")
            elif silent == 1:
                gcmd.respond_raw(f"// {leveling_text}")
                gcmd.respond_raw(f"// IFS ON")
                for tool_idx, tool_val in enumerate(tools):
                    if 0 <= (tool_val - 1) < len(result):
                        slot_info = result[tool_val - 1]
                        gcmd.respond_raw(
                            f"{self._t('file_tool')} {tool_idx+1} → "
                            f"{self._t('spool')} {slot_info['ID']}: "
                            f"{slot_info['Material']}/{slot_info['Color']}"
                        )
                gcmd2 = self.gcode.create_gcode_command("PRINT_ZCOLOR", "PRINT_ZCOLOR", {
                        'LEVELING': leveling, 'FILENAME': fname,
                        'TOOL0': tools[0], 'TOOL1': tools[1], 'TOOL2': tools[2], 'TOOL3': tools[3]
                        })
                self.cmd_PRINT_ZCOLOR(gcmd2)
            elif silent == 2:
                gcmd.respond_raw(f"// {leveling_text}")
                gcmd.respond_raw(f"// IFS OFF")
                data = {
                    "fileName": fname,
                    "levelingBeforePrint": bool(leveling),
                    "flowCalibration": True,
                    "useMatlStation": False
                }
                status_code2, response_data2 = self.zsend_post_request("/printGcode", send_data=data)
                if status_code2 == 200:
                    gcmd.respond_raw(f"Status: {response_data2.get('msg', 'OK')}")
                else:
                    gcmd.respond_raw(self._t('printing_error', response_data2))
        else:
            gcmd.respond_raw(self._t('no_response', response_data))

    def cmd_PRINT_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        fname = gcmd.get('FILENAME', '')
        if fname == '':
            raise gcmd.error(self._t('error_no_filename'))

        leveling = gcmd.get_int('LEVELING', 0)
        if leveling not in (0, 1):
            raise gcmd.error(self._t('error_leveling', leveling))

        tools = [
            gcmd.get_int('TOOL0', 1),
            gcmd.get_int('TOOL1', 2),
            gcmd.get_int('TOOL2', 3),
            gcmd.get_int('TOOL3', 4)
        ]

        for i, tool in enumerate(tools):
            if tool < 1 or tool > 4:
                raise gcmd.error(self._t('error_tool', i, tool))

        if self.display:
            status_code, response_data = self.zsend_post_request("/detail")
        else:
            status_code, response_data = self.get_printer_data_detail()
        if status_code:
            result = self.parse_printer_response(response_data)
            material_mappings = []

            for tool_idx, tool_val in enumerate(tools):
                if 0 <= (tool_val - 1) < len(result):
                    slot_info = result[tool_val - 1]
                    material_mappings.append({
                        "toolId": tool_idx,
                        "slotId": slot_info['ID'],
                        "materialName": slot_info['Material'],
                        "toolMaterialColor": f"#{slot_info['HEX']}",
                        "slotMaterialColor": f"#{slot_info['HEX']}"
                    })

            data = {
                "fileName": fname,
                "levelingBeforePrint": bool(leveling),
                "flowCalibration": True,
                "useMatlStation": True,
                "gcodeToolCnt": len(material_mappings),
                "materialMappings": material_mappings
            }

            status_code2, response_data2 = self.zsend_post_request("/printGcode", send_data=data)
            if status_code2 == 200:
                gcmd.respond_raw(f"Status: {response_data2.get('msg', 'OK')}")
            else:
                gcmd.respond_raw(self._t('printing_error', response_data2))
        else:
            gcmd.respond_raw(self._t('no_response', response_data))

    def cmd_CHANGE_TOOL_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        fname = gcmd.get('FILENAME', '')
        if fname == '':
            raise gcmd.error(self._t('error_no_filename'))

        leveling = gcmd.get_int('LEVELING', 0)
        if leveling not in (0, 1):
            raise gcmd.error(self._t('error_leveling', leveling))

        ztool = gcmd.get_int('TOOL', 0)
        if ztool < 1 or ztool > 4:
            raise gcmd.error(self._t('error_tool', '', ztool))

        tools = [
            gcmd.get_int('TOOL0', 1),
            gcmd.get_int('TOOL1', 2),
            gcmd.get_int('TOOL2', 3),
            gcmd.get_int('TOOL3', 4)
        ]

        for i, tool in enumerate(tools):
            if tool < 1 or tool > 4:
                raise gcmd.error(self._t('error_tool', i, tool))

        if ztool == 1:
            params=f"TOOL1={tools[1]} TOOL2={tools[2]} TOOL3={tools[3]} FILENAME=\"{fname}\" LEVELING={leveling} "
        elif ztool == 2:
            params=f"TOOL0={tools[0]} TOOL2={tools[2]} TOOL3={tools[3]} FILENAME=\"{fname}\" LEVELING={leveling} "
        elif ztool == 3:
            params=f"TOOL0={tools[0]} TOOL1={tools[1]} TOOL3={tools[3]} FILENAME=\"{fname}\" LEVELING={leveling} "
        else:
            params=f"TOOL0={tools[0]} TOOL1={tools[0]} TOOL2={tools[2]} FILENAME=\"{fname}\" LEVELING={leveling} "

        if self.display:
            status_code, response_data = self.zsend_post_request("/detail")
        else:
            status_code, response_data = self.get_printer_data_detail()
        if status_code:
#            gcmd.respond_raw(json.dumps(response_data, indent=2))
            result = self.parse_printer_response(response_data)
            gcmd.respond_raw(f"// action:prompt_begin {self._t('prompt_material')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('prompt_map_color')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('prompt_file', fname)}")

            gcmd.respond_raw("// action:prompt_button_group_start")
            for idx, slot in enumerate(result):
                btn_text = (
                    f"{self._t('file_tool')} {ztool} → "
                    f"{self._t('spool')} {slot['ID']}: "
                    f"{slot['Material']}/{slot['Color']}"
                )
                gcmd.respond_raw(
                    f"// action:prompt_button {btn_text}|"
                    f"SET_ZCOLOR TOOL{ztool-1}={idx+1} {params}|primary"
                )

            gcmd.respond_raw("// action:prompt_button_group_end")
            gcmd.respond_raw(
                f"// action:prompt_footer_button {self._t('cancel')}|"
                f"SET_ZCOLOR TOOL{ztool-1}={tools[ztool-1]} {params}"
            )
            gcmd.respond_raw("// action:prompt_show")
        else:
            gcmd.respond_raw(self._t('no_response', response_data))

    def cmd_RUN_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        zslot = gcmd.get_int('SLOT', 0)
        if zslot < 1 or zslot > 4:
            raise gcmd.error(self._t('error_slot'))

        zhex = gcmd.get('HEX', '161616').upper()
        ztype = gcmd.get('TYPE', '').upper()
        valid_types = ['PLA', 'ABS', 'PETG', 'TPU', 'PLA-CF', 'PETG-CF', 'SILK', '?']

        color_name = COLOR_MAPPING.get(zhex.lower(), {}).get(self.language, zhex)

        if ztype not in valid_types:
            raise gcmd.error(self._t('error_type', ztype, ', '.join(valid_types[:-1])))

        gcmd.respond_raw(f"// action:prompt_begin {self._t('select_action')}")
        gcmd.respond_raw(f"// action:prompt_text {self._t('spool_info', zslot, ztype, color_name)}")

        gcmd.respond_raw("// action:prompt_button_group_start")
        gcmd.respond_raw(
            f"// action:prompt_button {self._t('change_color')}|"
            f"CHANGE_ZCOLOR SLOT={zslot} TYPE={ztype}|primary"
        )
        gcmd.respond_raw(
            f"// action:prompt_button {self._t('change_type')}|"
            f"CHANGE_ZCOLOR SLOT={zslot} HEX={zhex}|primary"
        )
        gcmd.respond_raw(
            f"// action:prompt_button {self._t('load')}|"
            f"IN_ZCOLOR SLOT={zslot} NAPR=0|primary"
        )
        gcmd.respond_raw(
            f"// action:prompt_button {self._t('unload')}|"
            f"IN_ZCOLOR SLOT={zslot} NAPR=1|primary"
        )
        gcmd.respond_raw("// action:prompt_button_group_end")

        gcmd.respond_raw(f"// action:prompt_footer_button {self._t('cancel')}|RESPOND TYPE=command MSG=action:prompt_end")
        gcmd.respond_raw("// action:prompt_show")

    def cmd_CHANGE_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        zslot = gcmd.get_int('SLOT', 0)
        if zslot < 1 or zslot > 4:
            raise gcmd.error(self._t('error_slot'))

        zhex = gcmd.get('HEX', '').upper()
        ztype = gcmd.get('TYPE', '').upper()
        valid_types = ['PLA', 'ABS', 'PETG', 'TPU', 'PLA-CF', 'PETG-CF', 'SILK', '?']

        if not zhex and not ztype:
            raise gcmd.error(self._t('error_color_or_type'))

        if zhex and ztype:
            if ztype == '?':
                ztype = 'PLA'
            if ztype not in valid_types:
                raise gcmd.error(self._t('error_type', ztype, ', '.join(valid_types[:-1])))

            payload = {
                "cmd": "msConfig_cmd",
                "args": {
                    "slot": zslot,
                    "mt": ztype,
                    "rgb": f"#{zhex}"
                }
            }
            status_code, response_data = self.zsend_post_request("/control", payload=payload)
            if status_code == 200:
                self.cmd_GET_ZCOLOR(gcmd)
                gcmd.respond_raw(self._t('config_success'))
            else:
                gcmd.respond_raw(self._t('config_error', response_data))
            return

        if ztype:
            if ztype == '?':
                ztype = 'PLA'
            if ztype not in valid_types:
                raise gcmd.error(self._t('error_type', ztype, ', '.join(valid_types[:-1])))

            gcmd.respond_raw(f"// action:prompt_begin {self._t('select_color')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('spool_info', zslot, ztype, '')}")
            gcmd.respond_raw("// action:prompt_button_group_start")
            for hex_code, color_data in COLOR_MAPPING.items():
                color_name = color_data[self.language]
                gcmd.respond_raw(
                    f"// action:prompt_button {color_name}|"
                    f"CHANGE_ZCOLOR SLOT={zslot} TYPE={ztype} HEX={hex_code}|primary"
                )
            gcmd.respond_raw("// action:prompt_button_group_end")
            gcmd.respond_raw(f"// action:prompt_footer_button {self._t('cancel')}|RESPOND TYPE=command MSG=action:prompt_end")
            gcmd.respond_raw("// action:prompt_show")

        if zhex:
            color_name = COLOR_MAPPING.get(zhex.lower(), {}).get(self.language, zhex)
            gcmd.respond_raw(f"// action:prompt_begin {self._t('select_type')}")
            gcmd.respond_raw(f"// action:prompt_text {self._t('spool_info', zslot, '', color_name)}")
            gcmd.respond_raw("// action:prompt_button_group_start")
            for material in valid_types[:-1]:  # Исключаем '?'
                gcmd.respond_raw(
                    f"// action:prompt_button {material}|"
                    f"CHANGE_ZCOLOR SLOT={zslot} TYPE={material} HEX={zhex}|primary"
                )
            gcmd.respond_raw("// action:prompt_button_group_end")
            gcmd.respond_raw(f"// action:prompt_footer_button {self._t('cancel')}|RESPOND TYPE=command MSG=action:prompt_end")
            gcmd.respond_raw("// action:prompt_show")

    # Загрузка выгрузка филамента
    def cmd_IN_ZCOLOR(self, gcmd):
        gcmd.respond_raw("// action:prompt_end")
        zslot = gcmd.get_int('SLOT', 0)
        if zslot < 1 or zslot > 4:
            raise gcmd.error(self._t('error_slot'))

        napr = gcmd.get_int('NAPR', 0)
        if napr not in (0, 1):
            raise gcmd.error(self._t('error_napr'))

        action = "load" if napr == 0 else "unload"
        payload = {
            "cmd": "ms_cmd",
            "args": {
                "slot": zslot,
                "action": napr
            }
        }
        status_code, response_data = self.zsend_post_request("/control", payload=payload)
        if status_code == 200:
            gcmd.respond_raw(self._t(f'{action}_success'))
        else:
            gcmd.respond_raw(self._t(f'{action}_error', response_data))

def load_config(config):
    return zmod_color(config)
