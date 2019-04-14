#!/bin/sh
./select.sh courses | awk '
BEGIN{
    FS = ":";
    FILE = "course_names.dat";
    NAMES[""] = "";
    while ((getline < FILE) > 0) {
        if ($2 in NAMES) {
            print "Duplicated name " $2 >"/dev/stderr";
            exit(1);
        }
        i = gsub("# *", "", $1);
        DISABLED[$1] = i;
        COURSES[$1] = $2;
        NAMES[$2] = $1;
    }
    close(FILE);

    FS = sprintf("%c", 0x1e);
    ID = 0;
    VERSION = 0;
    MODIFIED = 0;
    TITLE = 0;
}
{
    if (ID == 0) {
        for (i = 1; i <= NF; i++) {
            if ($i == "Id") {
                ID = i;
            } else if ($i == "Version") {
                VERSION = i;
            } else if ($i == "Modified") {
                MODIFIED = i;
            } else if ($i == "Title") {
                TITLE = i;
            }
        }
        next;
    }

    if (!($ID in COURSES)) {
        print "Course \"" $TITLE "\" (" $ID ") not added!" >"/dev/stderr";
        printf("#%s:%s\n", $ID, $TITLE) >>FILE;
        close(FILE);
        next;
    }
    if (DISABLED[$ID] != 0) {
        print "Course \"" COURSES[$ID] "\" (" $ID ") disabled!" >"/dev/stderr";
        next;
    }

    system("mkdir -p \"" COURSES[$ID] "\"");
    BUILD=COURSES[$ID] "/.build";

    if (((getline VER_MOD < BUILD) > 0) && (VER_MOD == $VERSION ":" $MODIFIED)) {
        print "Course \"" COURSES[$ID] "\" (" $ID ") not updated" >"/dev/stderr";
        close(BUILD);
        next;
    }

    print $VERSION ":" $MODIFIED >BUILD;
    close(BUILD);
    system("./gen_course.sh " $ID " \"" COURSES[$ID] "\"");
}'
