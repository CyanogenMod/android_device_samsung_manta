/*
 * Copyright (C) 2012 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <dumpstate.h>

void dumpstate_board()
{
    dump_file("board revision", "/sys/devices/soc0/board_rev");
    dump_file("soc family", "/sys/devices/soc0/family");
    dump_file("soc revision", "/sys/devices/soc0/revision");
    dump_file("soc type", "/sys/devices/soc0/machine");
    dump_file("soc die_id", "/sys/devices/soc0/soc_id");
    dump_file("mmc0 name", "/sys/devices/platform/dw_mmc.0/mmc_host/mmc0/mmc0:0001/name");
    dump_file("mmc0 cid", "/sys/devices/platform/dw_mmc.0/mmc_host/mmc0/mmc0:0001/cid");
    dump_file("mmc0 csd", "/sys/devices/platform/dw_mmc.0/mmc_host/mmc0/mmc0:0001/csd");
    dump_file("mmc0 ext_csd", "/d/mmc0/mmc0:0001/ext_csd");
    dump_file("wlan", "/sys/module/bcmdhd/parameters/info_string");
    dump_file("touchscreen name", "/sys/class/input/input0/name");
    dump_file("android power", "/d/android-power");
    dump_file("manta power", "/d/manta-power");
    dump_file("smb347 charger regs", "/d/smb347-regs");
};
