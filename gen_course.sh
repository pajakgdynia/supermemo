#!/bin/sh -e

#skip SubscribeDate
#use Path for appropriate purpose and skip in course

echo "Building course $2 ($1).."
touch "$2/.build"

TREE="`./select.sh trees "CourseId=$1" | awk '
BEGIN{
    FS = sprintf("%c", 0x1e);
    DEFAULT=0;
    NUMBER=0;
    ID = 0;
}
{
    if (DEFAULT==0) {
        for (i = 1; i <= NF; i++) {
            if ($i == "IsDefault") {
                DEFAULT = i;
            } else if ($i == "Number") {
                NUMBER =i;
            }
        }
        next;
    }

    if (($DEFAULT == 1) || ((ID == 0) && ($DEFAULT == 0))) {
        ID = $NUMBER;
    }
}
END{
    print ID;
}'`"

# build course.xml: store tags from .hdr and process treesNodes (only for default tree)
(
    echo '<?xml version="1.0" encoding="utf-8"?>'
    echo '<course xmlns="http://www.supermemo.net/2006/smux">'

    ./select.sh Courses Id=$1 | awk '
        function totag(s,    out, i) {
            out = "";
            for (i = 1; i <= length(s); i++) {
                c = substr(s, i, 1);
                d = tolower(c);
                if ((i != 1) && (d != c)) {
                    out = out "-" d;
                } else {
                    out = out d;
                }
            }
            return out;
        }
        BEGIN{
            FS = sprintf("%c", 0x1e);
            HEADER = 0;

            MAPPING["CreateDate"] = "created";
            MAPPING["Id"] = "";
            MAPPING["Path"] = "";
            MAPPING["SubscribeDate"] = "";

            TRANSL["owner-id.0"] = "";
            TRANSL["flags.0"] = "";
            TRANSL["type.0"] = "regular";
            TRANSL["type.1"] = "vocabulary";
            TRANSL["type.2"] = "video";
            TRANSL["type.4"] = "private";
            TRANSL["type.6"] = "yle";
            TRANSL["type.7"] = "children";
            TRANSL["type.8"] = "exam";
        }
        {
            if (HEADER == 0) {
                for (i = 1; i <= NF; i++) {
                    if ($i in MAPPING) {
                        HEADERS[i] = MAPPING[$i];
                    } else {
                        HEADERS[i] = totag($i);
                    }
                }
                HEADER = 1;
            } else {
                for (i = 1; i <= NF; i++) {
                    v = $i;
                    if (HEADERS[i] "." $i in TRANSL) {
                        v = TRANSL[HEADERS[i] "." $i];
                    }
                    if ((HEADERS[i] != "") && (v != "")) {
                        printf("  <%s>%s</%s>\n", HEADERS[i], v, HEADERS[i]);
                    }
                }
            }
        }'

    (
        ./select.sh Pages CourseId=$1
        echo ""
        ./select.sh TreeNodes CourseId=$1 and TreeNumber=$TREE | awk '
        BEGIN{
            FS = sprintf("%c", 0x1e);
            PAGE = 0;
            _LT = 0;
            _RT = 0;
            DEPTH = 0;
            MAX = 0;
            MIN = 0;
        }
        {
            if (PAGE == 0) {
                for (i = 1; i <= NF; i++) {
                    if ($i == "PageNumber") {
                        PAGE = i;
                    } else if ($i == "LT") {
                        _LT= i;
                    } else if ($i == "RT") {
                        _RT= i;
                    } else if ($i == "Depth") {
                        DEPTH= i;
                    }
                }
                next;
            }

            if ($_RT == 0) {
                MIN++;
                $_LT = MIN;
                MIN++;
                $_RT = MIN;
                $DEPTH = 1;
            }

            PAGES[$_LT] = $PAGE;
            LEVEL[$_LT] = $DEPTH;
            # no more children
            PAGES[$_RT] = 0;
            if (MAX < $_RT) {
                MAX = $_RT;
            }
        }
        END{
            if (MAX <= 0) {
                print "Course has no items!" >"/dev/stderr";
                exit(1);
            }

            level = 0;
            for (i = 1; i <= MAX; i++) {
                if (!(i in PAGES)) {
                    print "Position " i " without a page!" >"/dev/stderr";
                    continue;
                }
                if (PAGES[i] == 0) {
                    level--;
                } else {
                    level++;
                    if (LEVEL[i] != level) {
                        print "Wrong level " level ", expected " LEVEL[i] ", page " PAGES[i] >"/dev/stderr";
                        LEVEL[i] = level;
                    }

                    printf("%d:%d\n", level, PAGES[i]);
                }
            }
            if (level != 0) {
                print "Wrong structure of the tree!" >"/dev/stderr";
                exit(1);
            }
        }'
    ) | awk '
        function totag(s,    out, i) {
            out = "";
            for (i = 1; i <= length(s); i++) {
                c = substr(s, i, 1);
                d = tolower(c);
                if ((i != 1) && (d != c)) {
                    out = out "-" d;
                } else {
                    out = out d;
                }
            }
            return out;
        }
        BEGIN{
            MAPPING["CourseId"] = "";
            MAPPING["Number"] = "id";
            MAPPING["ContentType"] = "content-type";
            MAPPING["LockedBy"] = "";
            MAPPING["Modified"] = "";

            TRANSL["type.0"] = "exercise";
            TRANSL["type.1"] = "once";
            TRANSL["type.5"] = "pres";
            TRANSL["content-type.0"] = "";
            TRANSL["tag.0"] = "";
            TRANSL["level.0"] = "";
            TRANSL["disabled.0"] = "";

            SEP = sprintf("%c", 0x1e);
            FS = SEP;
            PAGE = 0;
            LEVEL = -1;
            FIRST = 1;
        }
        {
            if (PAGE == 0) {
                for (i = 1; i <= NF; i++) {
                    if ($i == "Number") {
                        PAGE = i;
                    }
                    if ($i in MAPPING) {
                        HEADER[i] = MAPPING[$i];
                    } else {
                        HEADER[i] = totag($i);
                    }
                }
                next;
            }
            if ($0 == "") {
                LEVEL = 0;
                FS = ":";
                next;
            }
            if (LEVEL < 0) {
                DEF[$PAGE] = $0;
            } else {
                if (!($2 in DEF)) {
                    print "Page " $2 " definition not found!" >"/dev/stderr";
                    exit(1);
                }
                FF = split(DEF[$2], F, SEP);

                if (LEVEL == $1) {
                    printf " />\n";
                } else if (LEVEL + 1 == $1) {
                    LEVEL++;
                    if (FIRST) {
                        FIRST = 0;
                        printf "\n";
                    } else {
                        printf ">\n";
                    }
                } else if (LEVEL > $1) {
                    printf("/>\n");
                    while (LEVEL > $1) {
                        LEVEL--;
                        printf("%*s</element>\n", 2 * LEVEL, "");
                    }
                } else {
                    print "Wrong level " $1 >"/dev/stderr";
                    exit(1);
                }

                printf("%*s<element ", 2 * $1, "");
                for (i = 1; i <= FF; i++) {
                    v = F[i];
                    if (HEADER[i] "." F[i] in TRANSL) {
                        v = TRANSL[HEADER[i] "." F[i]];
                    }
                    if ((HEADER[i] != "") && (v != "")) {
                        printf(" %s=\"%s\"", HEADER[i], v);
                    }
                }
            }
        }
        END{
            if (LEVEL < 0) {
                print "No pages found, course not downloaded!" >"/dev/stderr";
                exit(1);
            }
            if (LEVEL < 1) {
                print "Wrong document structure, level=" LEVEL >"/dev/stderr";
                exit(1);
            }

            printf("/>\n");
            while (LEVEL > 1) {
                LEVEL--;
                printf("%*s</element>\n", 2 * LEVEL, "");
            }
        }' || rm "$2/.build"
    echo "</course>"
) >"$2/course.xml"
test -f "$2/.build" || exit 1

# process all pages to itemXXXX.xml
echo "Create items $2 ($1).."
./select.sh PagesContent CourseId=$1 | awk -v DIR="${2}" '
    function totag(s,    out, i) {
        out = "";
        for (i = 1; i <= length(s); i++) {
            c = substr(s, i, 1);
            d = tolower(c);
            if ((i != 1) && (d != c)) {
                out = out "-" d;
            } else {
                out = out d;
            }
        }
        return out;
    }
    BEGIN{
        FS = sprintf("%c", 0x1e);
        ID = 0;

        MAPPING["CourseId"] = "";
        MAPPING["PageNumber"] = "";
        MAPPING["Path"] = "";
        MAPPING["SubscribeDate"] = "";

        MAPPING["CreateDate"] = "created";
    }
    {
        if (ID == 0) {
            for (i = 1; i <= NF; i++) {
                if ($i == "PageNumber") {
                    ID = i;
                }

                if ($i in MAPPING) {
                    HEADERS[i] = MAPPING[$i];
                } else {
                    HEADERS[i] = totag($i);
                }
            }
            next;
        }

        FILE=DIR sprintf("/item%05d.xml", $ID);
        printf("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n") >FILE;
        printf("<item xmlns=\"http://www.supermemo.net/2006/smux\">\n") >>FILE;
        for (i = 1; i <= NF; i++) {
            if ((HEADERS[i] != "") && ($i != "")) {
                j = index($i, "{\"content\":\"");
                if (j == 1) {
                    j = index($i, "\",\"media\":[]}");
                    if (j == length($i) - 12) {
                        $i = substr($i, 13, length($i) - 25);
                        gsub("\\\\\"", "\"", $i);
                    }
                }
                printf("  <%s>%s</%s>\n", HEADERS[i], $i, HEADERS[i]) >>FILE;
            }
        }
        printf("</item>\n") >>FILE;
        close(FILE);
    }'

# store media
echo "Store media $2 ($1).."
INPUT="`./select.sh Courses Id=$1 | awk -v DIR="$2" '
BEGIN{
    FS = sprintf("%c", 0x1e);
    PATH = 0;
    INPUT = "";
}
{
    if (PATH == 0) {
        for (i = 1; i <= NF; i++) {
            if ($i == "Path") {
                PATH = i;
            }
        }
        next;
    }

    if (INPUT == "") {
        INPUT = $PATH;
    }
}
END{
    print INPUT;
}'`"

./select.sh CoursesFiles CourseId=$1 | awk -v DIR="$2" '
BEGIN{
    CHECKED[DIR] = "";

    FS = sprintf("%c", 0x1e);
    PATH = 0;
    PAGE = 0;
    OFFSET = 0;
    LEN = 0;
}
{
    if (PATH == 0) {
        for (i = 1; i <= NF; i++) {
            if ($i == "Path") {
                PATH = i;
            } else if ($i == "Offset") {
                OFFSET = i;
            } else if ($i == "PageNumber") {
                PAGE = i;
            } else if ($i == "Length") {
                LEN = i;
            }
        }
        next;
    }

    OUT = DIR "/" $PATH;
    sub("/[^/]*$", "", OUT);
    if (!(OUT in CHECKED)) {
        system("mkdir -p \"" OUT "\"");
        CHECKED[OUT] = "";
    }
    printf("%d          \b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b", $PAGE) >"/dev/stderr";
    print $OFFSET " " $LEN " " DIR "/" $PATH;
}' | ./save.exe "${INPUT}"
