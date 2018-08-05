#!/bin/sh

while [ "$1" != "" ]; do
    F1=$1
    shift

    DIR="`pwd`"
    if [ -d "${F1}" ]; then
        cd "${F1}"
        F=`basename "${F1}"`
    else
        if echo ${F1} | grep '\.smpak$' >/dev/null; then
            true
        else
            echo Not a smpak file ${F1} 1>&2
            continue
        fi

        F=`basename "${F1}" .smpak | sed 's/\.[0-9]*$//1'`
        echo "${F1} -> ${F}"

        mkdir -p "${F}"
        if [ ! -d items ]; then
            cp "${F1}" "${F}"
            cd "${F}"
            F2="`ls -1 *.smpak`"
            ../smdec.exe "${F2}"
            ../smunp.exe "${F2}"
            rm "${F2}"
        else
            cd "${F}"
        fi
    fi

    mkdir -p items
    awk -f ../strip_course.awk course.xml | awk -f ../fill_course.awk > "${DIR}/${F}.def"
    cd "${DIR}"
done
