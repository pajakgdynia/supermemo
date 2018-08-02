function print_tags(str) {
    print gensub("  *([a-zA-Z_]*)=\"([^\"]*)\"", "\n\\1: \\2", "G", str);
}

BEGIN{
    getline;
    getline;
}

{
    gsub("\r", "");
    if ($0 ~ " *</element>") {
        print "\n}";
    } else if ($0 ~ " *<element.* */ *>") {
        gsub(" *<element", "");
        gsub(" */ *> *", "");
        print_tags($0);
    } else if ($0 ~ " *<element.*>") {
        gsub(" *<element", "");
        gsub(" *>", "");
        print_tags($0);
        print "\n{";
    } else {
        $0 = gensub(" *<([-a-z0-9_]*) [a-z]*=\"([^\"]*)\">", "\\1:\\2: ", "G");
        $0 = gensub(" *<([-a-z0-9_]*)>", "\\1: ", "G");
        $0 = gensub("</.*>", "", "G");
        if (!($0 ~ "[-a-z0-9]*: .*")) {
            printf("    ");
        }
        print $0;
    }
}
