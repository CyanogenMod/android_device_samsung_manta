# Healthd
BOARD_CHARGER_DISABLE_INIT_BLANK := true
BOARD_CHARGER_SHOW_PERCENTAGE := true
BOARD_HAL_STATIC_LIBRARIES := libhealthd.manta libdumpstate.manta

# Exclude CM Charger
WITH_CM_CHARGER := false
