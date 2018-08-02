#!/bin/sh

while [ "$1" != "" ]; do
    F1=$1
    shift

    echo ${F1} | grep '\.smpak$' >/dev/null || continue

    F=`basename ${F1} .smpak | sed 's/\.[0-9]*$//1'`
    echo "${F1} -> ${F}"

    mkdir -p ${F}
    cd ${F}
    if [ ! -d items ]; then
        cp ../${F1} .
        F2=`ls -1 *.smpak`
        ../smdec.exe ${F2}
        ../smunp.exe ${F2}
        rm ${F2}
        mkdir items
    fi

    awk -f ../strip_course.awk course.xml | awk -f ../fill_course.awk > ../${F}.def
    cd ..
done
