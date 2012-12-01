#!/bin/bash

# Copyright (C) 2012 The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

for FILE in `cat cm-proprietary-blobs.txt | grep -v "^#"`; do
    # FILE format is src':'dest, so parse it
    DEST=${FILE##*:}
    saveIFS=$IFS
    IFS=":"
    SRC=($FILE)
    IFS=$saveIFS
    SRC=${SRC[0]}

    # create the dest dir if necessary
    DIR=`dirname $DEST`
    if [ ! -d ${DIR} ]; then
	echo mkdir -p ${DIR}
        mkdir -p ${DIR}
    fi

    # pull the file off the device into dest
    echo adb pull ${SRC} ${DEST}
    adb pull ${SRC} ${DEST}
done

./setup-makefiles.sh
