#!/bin/sh

if [ -z "$1" ]; then
    echo "select.sh table [database=sm_181202.sqlite]" 1>&2
    exit 1
fi
TABLE=$1
shift

if [ -n "$1" ]; then
    COND="where $@"
fi

sqlite3 "/c/Users/MSI G60/AppData/Roaming/SuperMemo World/SuperMemo.com/UserData.dat" -html -header "select * from ${TABLE} ${COND}" | awk '
function bits(c, most, least,     d, i) {
    d = 1;
    for (i = 1; i <= least; i++) {
        d = d * 2;
    }
    c = int(c / d);
    d = 1;
    for (i = 1; i <= most - least + 1; i++) {
        d = d * 2;
    }
    c = c % d;
    return c;
}
function utf8(c) {
    if (c <= 0x7f) {
        # 0x00 do 0x7F            – bity 0xxxxxxx, gdzie kolejne „x” to bity – licząc od najwyższego
        return sprintf("%c", bits(c, 6, 0));
    } else if (c <= 0x7ff) {
        # 0x80 do 0x7FF           – bity 110xxxxx 10xxxxxx
        return sprintf("%c%c", 0xc0 + bits(c, 10, 6), 0x80 + bits(c, 5, 0));
    } else if (c <= 0xffff) {
        # 0x800 do 0xFFFF         – bity 1110xxxx 10xxxxxx 10xxxxxx
        return sprintf("%c%c%c", 0xe0 + bits(c, 15, 12), 0x80 + bits(c, 11, 6), 0x80 + bits(c, 5, 0));
    } else if (c <= 0x1FFFFF) {
        # 0x10000 do 0x1FFFFF     – bity 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        return sprintf("%c%c%c%c", 0xf0 + bits(c, 20, 18), 0x80 + bits(c, 17, 12), 0x80 + bits(c, 11, 6), 0x80 + bits(c, 5, 0));
    } else if (c <= 0x3FFFFFF) {
        # 0x200000 do 0x3FFFFFF   – bity 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
        return sprintf("%c%c%c%c%c", 0xf8 + bits(c, 25, 24), 0x80 + bits(c, 23, 18), 0x80 + bits(c, 17, 12), 0x80 + bits(c, 11, 6), 0x80 + bits(c, 5, 0));
    } else {
        # 0x4000000 do 0x7FFFFFFF – bity 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
        return sprintf("%c%c%c%c%c%c", 0xfd + bits(c, 30, 30), 0xfd + bits(c, 29, 24), 0x80 + bits(c, 23, 18), 0x80 + bits(c, 17, 12), 0x80 + bits(c, 11, 6), 0x80 + bits(c, 5, 0));
    }
}
BEGIN{
    ATTR=0;
    OPEN=0;

    REPL["&#39;"] = sprintf("%c", 39);
    REPL["&#34;"] = "\"";
    REPL["&quot;"] = "\"";

    REPL["&lt;"] = "<";
    REPL["&gt;"] = ">";

    TAG = "TH";
}
function non_empty(pos,     i) {
    for (i = 1; i < pos; i++) {
        if (substr($0, i, 1) != " ") {
            return i;
        }
    }
    return 0;
}
function strip(pos, tag,     i) {
    i = non_empty(pos);
    if (i != 0) {
        print "Data before (at " i " ): " $0 >"/dev/stderr";
        exit(1);
    }
    $0 = substr($0, pos + tag);
}
{
    for(;;) {
        i = index($0, "<TR>");
        if (i > 0) {
            if ((OPEN != 0) || (ATTR != 0)) {
                print "Not closed: " $0 >"/dev/stderr";
                exit(1);
            }
            strip(i, 4);
            continue;
        }

        i = index($0, "<" TAG ">");
        if (i > 0) {
            if (OPEN == 1) {
                print "Duplicated OPEN tag: " $0 >"/dev/stderr";
                exit(1);
            }
            OPEN = 1;
            ATTR++;
            strip(i, 4);
            continue;
        }

        i = index($0, "</" TAG ">");
        if (i > 0) {
            if (OPEN == 0) {
                print "Not OPENed " $0 >"/dev/stderr";
                exit(1);
            }
            if (i != 1) {
                if (ATTR in VAL) {
                    VAL[ATTR] = VAL[ATTR] "\\n" substr($0, 1, i - 1);
                } else {
                    VAL[ATTR] = substr($0, 1, i - 1);
                }
            }
            $0 = substr($0, i + 5);
            OPEN = 0;
        }

        i = index($0, "</TR>");
        if (i > 0) {
            if (ATTR == 0) {
                print "Empty row " $0 >"/dev/stderr";
                exit(1);
            }
            if (OPEN != 0) {
                print "Not CLOSEd " $0 >"/dev/stderr";
                exit(1);
            }\
            for (i = 1; i <= ATTR; i++) {
                if (i != 1) {
                    printf("%c", 0x1e);
                }
                gsub("&amp;", "\\&", VAL[i]);
                for (r in REPL) {
                    gsub(r, REPL[r], VAL[i]);
                }
                # convert &#utf_codes to plain characters
                while ((j = match(VAL[i], "\\&#[0-9]*;")) > 0) {
                    VAL[i] = substr(VAL[i], 1, j - 1) utf8(substr(VAL[i], j + 2, RLENGTH - 3) + 1 - 1) substr(VAL[i], j + RLENGTH);
                }
                while (j = index(VAL[i], sprintf("%c", 0x1e)) != 0) {
                    VAL[i] = substr(VAL[i], 1, j - 1) "&#30;" substr(VAL[i], j + 1);
                }
                printf("%s", VAL[i]);
            }
            printf("\n");
            $0 = substr($0, i + 5);
            delete VAL;
            ATTR = 0;
            TAG = "TD";
        }

        if (OPEN == 1) {
            if (non_empty(length($0)) != 0) {
                if (ATTR in VAL) {
                    VAL[ATTR] = VAL[ATTR] "\\n" $0;
                } else {
                    VAL[ATTR] = $0;
                }
            }
        } else if (non_empty(length($0)) != 0) {
            print "Data between tags: " $0 >"/dev/stderr";
            exit(1);
        }
        break;
    }
}
END{
    if ((OPEN != 0) || (ATTR != 0)) {
        print "Not finished document" >"/dev/stderr";
        exit(1);
    }
}'
