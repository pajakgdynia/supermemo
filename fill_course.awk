BEGIN{
    # DEF: definition name -> definition
    # PAT: pattern -> last assigned id for the pattern

    # styles
    DEF["div.0"] = "<div>[]</div>";
    DEF["center.0"] = "<div style=\"text-align: center\">[]</div>";
    DEF["left.0"] = "<div style=\"text-align: left\">[]</div>";

    DEF["b.0"] = "<span b>[]</span>";
    DEF["i.0"] = "<span i>[]</span>";

    DEF["sb.0"] = "<span style=\"font-weight: bold\">[]</span>";
    DEF["sb.1"] = "<span style=\"font-weight: bold;\">[]</span>";

    DEF["su.0"] = "<span style=\"text-decoration: underline\">[]</span>";
    DEF["su.1"] = "<span style=\"text-decoration: underline;\">[]</span>";

    DEF["si.0"] = "<span style=\"font-style: italic\">[]</span>";
    DEF["si.1"] = "<span style=\"font-style: italic;\">[]</span>";

    # special supermemo notation
    # used to keep part of speech
    DEF["part.em"] = "<em>[]</em>";
    # used to add examples, collocations, etc
    DEF["ext.small"] = "<small>[]</small>";

    # subelements for standard elements
    DEF["o.0"] = "<option>[]</option>";
    DEF["o.1"] = "<option correct=\"true\">[]</option>";

    DEF[".drag.d-answer"] = "<d-answer>[]</d-answer>";
    DEF[".drag.d-header"] = "<header>[]</header>";

    # standard elements
    DEF["transl.0"] = "<text><sentence>[]</sentence><translation>[]</translation></text>";
    DEF["preview.0"] = "<preview>[]</preview>";

    DEF["false.0"] = "<true-false true=\"true\" false=\"false\" correct=\"false\" labels=\"true\" />";
    DEF["true.1"] = "<true-false true=\"true\" false=\"false\" correct=\"true\" labels=\"true\" />";

    # true-false with correct attribute in the value (either true/t/false/f)
    # but rather to be added to "reverse" translation as "cond"
    DEF["cond.correct"] = "<true-false true=\"true\" false=\"false\" labels=\"true\" />";

    DEF["pad.0"] = "<spellpad />";
    DEF["pad.1"] = "<spellpad></spellpad>";
    DEF["pad.2"] = "<spellpad>[]</spellpad>";
    DEF["check.0"] = "<checkbox>[]</checkbox>";
    DEF["order.0"] = "<ordering-list>[]</ordering-list>";
    DEF["select.0"] = "<select-phrases>[]</select-phrases>";
    DEF["multi.0"] = "<m-drop><drop-answers>[]</drop-answers><drop-headers>[]</drop-headers>[]</m-drop>";
    DEF["drag.0"] = "<drag-drop><drop-text>[]</drop-text>[]</drag-drop>";
    DEF["radio.0"] = "<radio>[]</radio>";
    DEF["dlist.0"] = "<droplist>[]</droplist>";

    # default plain arrays..
    DEF[".row.1"] = "<tr><td>[]</td></tr>";
    DEF[".row.2"] = "<tr><td>[]</td><td>[]</td></tr>";
    DEF[".row.3"] = "<tr><td>[]</td><td>[]</td><td>[]</td></tr>";
    DEF["tab.0"] = "<table><tbody>[]</tbody></table>";

    # lists: either ol, ul or dl.. Not specified here.
    DEF[".item"] = "<li>[]</li>";

    # media
    DEF["sfx.0"] = "<sfx />";
    DEF["gfx.0"] = "<gfx />";

    # mailto link
    DEF["mailto.0"] = "<a href=\"mailto:*\">[]</a>";
}

function split_opts(ARR, val,      opts, level, opt, i, c) {
    level = 0;
    opt = "";
    opts = 0;
    for (i = 1; i <= length(val); i++) {
        c = substr(val, i, 1);
        if (c == "]") {
            level--;
            if (level == 0) {
                ARR[opts++] = opt;
                opt = "";
            }
        }
        if (level != 0) {
            opt = opt c;
        }
        if (c == "[") {
            level++;
        }
    }
    return opts;
}

function reformat_value(item, tag, name, value,        i, id, opts, v, vv, str) {
    if (tag == "em") {
        if (value ~ "(.*)") {
            value = substr(value, 2, length(value) - 2);
        }
    }
    if (tag == "small") {
        gsub(":$", "", value);
    }

    if (tag == "option") {
        if (name == "o.0") {
            return "[" value "]";
        } else if (name == "o.1") {
            return "[*" value "]";
        }
    }

    if (tag == "drag-drop") {
        i = index(value, "|");
        opts = split_opts(OPTS, substr(value, i+1));
        value = substr(value, 1, i - 1);
        while ((i = match(value, "\\[[0-9]*\\]")) > 0) {
            id = substr(value, i + 1, RLENGTH - 2);
            if (!(id in OPTS)) {
                print item ": no option " id >"/dev/stderr";
                exit(1);
            }
            if (id in USED) {
                print item ": option " id " already used" >"/dev/stderr";
            }
            USED[id] = "";
            value = substr(value, 1, i) "*" OPTS[id] substr(value, i + RLENGTH - 1);
        }
        for (i = 1; i < opts; i++) {
            if (!(i in USED)) {
                value = value "[" OPTS[i] "]";
            }
        }
        delete USED;
        delete OPTS;
    }
    if (tag == "m-drop") {
        # three blocks: first is with valid ids, second with row definitions, third with available options
        i = index(value, "|");
        split_opts(VAL, substr(value, 1, i - 1));
        value = substr(value, i+1);
        i = index(value, "|");
        rows = split_opts(ROW, substr(value, 1, i - 1));
        opts = split_opts(OPTS, substr(value, i + 1));
        value = "";

        for (i = 0; i < rows; i++) {
            vv = split(VAL[i], V, ",");
            value = value ROW[i] " ";
            for (v = 1; v <= vv; v++) {
                USED[V[v]] = "";
                if (!(V[v] in OPTS)) {
                    print item ":: no option " V[v] >"/dev/stderr";
                } else {
                    value=value "[*" OPTS[V[v]] "]";
                }
            }
            delete V;
        }
        for (i = 0; i < opts; i++) {
            if (!(i in USED)) {
                value = value "[" OPTS[i] "]";
            }
        }
        delete USED;
        delete ROW;
        delete VAL;
        delete OPTS;
    }

    if ((i = index(name, ".")) != 0) {
        name = substr(name, 1, i - 1);
    }
    if (name == "") {
        return "[" value "]";
    } else {
        return "@" name "[" value "]";
    }
}

function replace_type(id, tags, val, pattern,          tag, name, def, value, i, j, pat, found) {
    tt = split(tags, TT, "|");
    tag = TT[1];

    for (;;) {
        M[1] = match(val, "< *" tag " */ *>");        L[1] = RLENGTH; # <tag />
        M[2] = match(val, "< *" tag " [^>]*/ *>");  L[2] = RLENGTH; # <tag attr.. />
        if ((M[1] == 0) && (M[2] == 0)) {
            pat = 0;
        } else if (M[1] == 0) {
            pat = 2;
        } else if (M[2] == 0) {
            pat = 1;
        } else if (M[1] < M[2]) {
            pat = 1;
        } else {
            pat = 2;
        }

        if (pat == 0) {
            M[3] = match(val, "< *" tag " *>");            L[3] = RLENGTH; # <tag> ... </tag>
            M[4] = match(val, "< *" tag " [^>]*>");      L[4] = RLENGTH; # <tag attr..> ... </tag>

            if ((M[3] == 0) && (M[4] == 0)) {
                pat = 0;
            } else if (M[3] == 0) {
                pat = 4;
            } else if (M[4] == 0) {
                pat = 3;
            } else if (M[3] < M[4]) {
                pat = 3;
            } else {
                pat = 4;
            }
        }

        if (pat == 0) {
            break;
        }

        if ((pat == 1) || (pat == 2)) {
            def = substr(val, M[pat], L[pat]);
            value = "";
        } else if ((pat == 3) || (pat == 4)) {
            i = match(substr(val, M[pat] + L[pat]), "< */ *" tag " *>");
            if (i <= 0) {
                print id ": cannot find close for " tag " @" M[pat] >"/dev/stderr";
                print substr(val, 1, M[pat]) "<----" substr(val, M[pat]) >"/dev/stderr";
                exit(1);
            }
            L[pat] = L[pat] + i - 1 + RLENGTH;
            def = substr(val, M[pat], L[pat]);

            # check if any nested tags were found in the match..
            while ((i = match (substr(def, 2), "< *" tag "[ />]")) != 0) {
                L[pat] = L[pat] - i;
                M[pat] = M[pat] + i;
                def = substr(val, M[pat], L[pat]);
            }

            # build appropriate definition and value: keep requested tags in def, remove all from value
            # just by replacing them to ˻ and then replace one-by one.
            # DO NOT REPLACE these characters with real UTF-8 representations: these are 2 bytes then!
            for (i = 1; i <= tt; i++) {
                while ((j = match(def, "< */* *" TT[i] "[^>]*>")) > 0) {
                    def = substr(def, 1, j - 1) "ˢ substr(def, j + 1, RLENGTH - 2) "ۢ substr(def, j + RLENGTH);
                }
            }
            gsub("ܛ \n]*", "ۢ, def);
            gsub("[ \n]*ˢ, "ˢ, def);
            value = def;
            name = substr(def, match(def, "ܛ^̝+ˢ), RLENGTH);
            gsub("ܛ^̝+ˢ, "ܛ]ˢ, def);
            gsub("ۢ, ">", def);
            gsub("ˢ, "<", def);

            gsub("^(̛^ܝ*۩*", "", value);
            gsub("(̛^ܝ*۩*$", "", value);
            gsub("(̛^ܝ*۩+", "|", value);
        }

        if (tag == "a") {
            i = index(def, value);
            if (i > 0) {
                def = substr(def, 1, i - 1) "*" substr(def, i + length(value));
            }
        }

        if ((tag == "gfx") || (tag == "sfx") || (tag == "video")) {
            i = match(def, " file=\"[a-z]\"");
            if (i > 0) {
                value = value substr(def, i + 7, 1);
                def = substr(def, 1, i - 1) substr(def, i + RLENGTH);
            }
            i = match(def, " item-id=\"[0-9]*\"");
            if (i > 0) {
                if (value != "") {
                    value = value ":";
                }
                value = value substr(def, i + 10, RLENGTH - 11);
                def = substr(def, 1, i - 1) substr(def, i + RLENGTH);
            }
            # play-start="74" play-end="82,3"
            i = match(def, " play-start=\"[,.0-9]*\"");
            if (i > 0) {
                value = value "@" substr(def, i + 13, RLENGTH - 14);
                def = substr(def, 1, i - 1) substr(def, i + RLENGTH);
            }
            i = match(def, " play-end=\"[,.0-9]*\"");
            if (i > 0) {
                value = value "-" substr(def, i + 11, RLENGTH - 12);
                def = substr(def, 1, i - 1) substr(def, i + RLENGTH);
            }
        }
        if (tag == "spellpad") {
            # <spellpad correct="ans" charpad="en">a</spellpad>
            # <spellpad correct="ans" />
            i = match(def, " correct=\"[^\"]*\"");
            if (i <= 0) {
                print id ": spellpad without values (" def ")" >"/dev/stderr";
                exit(1);
            }
            if (value != "") {
                value = value ":";
            }
            value = value substr(def, i + 10, RLENGTH - 11);
            def = substr(def, 1, i - 1) substr(def, i + RLENGTH);
        }
        if (tag == "preview") {
            i = match(def, " ref=\".*\"");
            if (i <= 0) {
                print id ": review without id (" def ")" >"/dev/stderr";
                exit(1);
            }
            if (value != "") {
                value = value "|";
            }
            value = value substr(def, i + 6, RLENGTH - 7);
            def = substr(def, 1, i - 1) substr(def, i + RLENGTH);
        }

        found = 0;
        for (name in DEF) {
            if (DEF[name] == def) {
                found = 1;
                break;
            }
        }
        if (!found) {
            if (pattern in PAT) {
                PAT[pattern] = (1 + PAT[pattern]);
            } else {
                PAT[pattern] = 1;
            }
            name = pattern PAT[pattern];
            DEF[name] = def;
        }

        #print "[" id ":" tag ", def=" def ", name " name ", value=" value "]" >"/dev/stderr";
        val = substr(val, 1, M[pat] - 1) reformat_value(id, tag, name, value) substr(val, M[pat] + L[pat]);
    }
    return val;
}

function find_close(str, open,      level, c, i) {
    # it is assumed, that on open there is '['! It allows to find unmatched close tag
    if ((open != 0) && (substr(str, open, 1) != "[")) {
        print "Requested position starts with >" substr(str, open, 1) "<" >"/dev/stderr";
    }
    level = 1;
    for (i = open + 1; i <= length(str); i++) {
        c = substr(str, i, 1);
        if (c == "[") {
            level++;
        } else if (c == "]") {
            if (level == 1) {
                return i;
            }
            level--;
        }
    }
    return 0;
}

function process_body(def, body,       dd, tag) {
    if (!(def in DEF)) {
        for (dd in DEF) {
            if (dd ~ def "\\..*") {
                def = dd;
                break;
            }
        }
    }
    tag = DEF[def];
    gsub("< *", "", tag);
    gsub("[^-a-zA-Z0-9_].*$", "", tag);

    #true-false
    #checkbox
    #ordering-list
    #select-phrases: remove if strike out!
    #m-drop
    #drag-drop
    #radio
    #droplist

    if (tag == "sfx") {
        # stop collecting the audio..
        return "|";
    } else if (tag == "gfx") {
        # ignore gfx files
        return "";
    } else if (def == "part.em") {
        return "";
    } else if (def == "ext.small") {
        # do not append it to default audio
        return "|";
    } else if (tag == "text") {
        if (gsub("[|].*$", "", body) == 0) {
            return "";
        }
    } else if (tag == "spellpad") {
        gsub("^[^:]*:", "", body);
        gsub("[|].*$", "", body);
    }

    return body;
}

function append_media(file, val,      str, dname, i, j) {
    i = find_close(val, 0);
    if (i > 0) {
        str = substr(val, 1, i-1);
    } else {
        str = val;
    }
    # audio is followed by another cell
    gsub("^ *[|] *", "", str);

    gsub("<[^>]*>", "", str);

    while ((i = match(str, "@[^[]*\\[")) > 0) {
        dname = substr(str, i + 1, RLENGTH - 2);
        j = find_close(str, i + RLENGTH-1);
        if (j > 0) {
            str = substr(str, 1, i - 1) process_body(dname, substr(str, i + length(dname) + 2, j - (i + length(dname)) - 2)) substr(str, j + 1);
        } else {
            print file "/" dname ":: cannot find closing bracket" >"/dev/stderr";
            exit(1);
        }
    }
    # terminate with another column, option, etc
    gsub("[|].*$", "", str);

    # sometimes examples are put into the text..
    gsub("[(][^)]*[)]", "", str);

    gsub("\\\\n", "", str);
    gsub("\n", "", str);
    gsub("^  *", "", str);
    gsub("  *$", "", str);
    if (str != "") {
        MEDIA[file] = MEDIA[file] str "\n";
    }
}

function read_item(id,        file, doc, tag, val, attr, look, i, question, q_audio, answer, a_audio) {
    file = sprintf("item%05d.xml", id);
    if ((getline line < file) > 0) {
        close(file);
        system("mv " file " items/");
    }

    file = sprintf("items/item%05d.xml", id);
    if ((getline line < file) < 0) {
        printf("cannot open %s\n", file);
        exit(1);
    }
    doc = "";
    while ((getline line < file) > 0) {
        gsub("\r", "", line);
        if (doc != "") {
            doc = doc "\n" line;
        } else {
            doc = line;
        }
    }
    close(file);

    # ignore "top level"
    gsub(" *<item [^>]*>", "", doc);
    gsub(" *</item>", "", doc);

    question = "";
    q_audio = "";
    answer = "";
    a_audio = "";
    ret = "";
    while ((i = index(doc, "<")) > 0) {
        doc = substr(doc, i + 1);
        i = match(doc, "[ />]");
        tag = substr(doc, 1, i - 1);
        doc = substr(doc, i);

        i = index(doc, ">");
        if ((i > 1) && (substr(doc, i - 1, 1) == "/")) {
            attr = substr(doc, 1, i - 2);
            look = 0;
        } else {
            attr = substr(doc, 1, i - 1);
            look = 1;
        }
        gsub("^ *", "", attr);
        gsub(" *$", "", attr);
        if (attr != "") {
            ret = ret tag ": " attr "\n";
        }
        doc = substr(doc, i + 1);

        if (look) {
            if (attr != "") {
                print id ": attributes and value in " tag >"/dev/stderr";
                exit(1);
            }
            i = index(doc, "</" tag ">");
            if (i <= 0) {
                print id ": " tag " not closed:: " doc >"/dev/stderr";
                exit(1);
            }
            val = substr(doc, 1, i - 1);
            gsub("[ \n]*$", "", val);
            gsub("^[ \n]*", "", val);
            gsub("\\&\\#160;", "", val);

            if (tag == "question-audio") {
                q_audio = val;
            } else if (tag == "answer-audio") {
                a_audio = val;
            }

            val = gensub(" *< *br */ *>", "\\\\n", "G", val);
            val = replace_type(id, "a", val, "ref");

            val = replace_type(id, "div", val, "div");
            val = replace_type(id, "p", val, "s");

            # replace all styles: <b> <i> are replaced with "special" span tags
            val = gensub("< *([bi]) */ *>", "<span \\1 />", "G", val);
            val = gensub("< *([bi]) *>", "<span \\1>", "G", val);
            val = gensub("< *([bi]) *>", "<span \\1>", "G", val);
            val = gensub("< */ *[bi] *>", "</span>", "G", val);
            val = gensub("<span[^>]*> *</span>", "", "G", val);
            val = gensub("<span[^>]*/ *>", "", "G", val);
            val = replace_type(id, "span", val, "s");

            val = replace_type(id, "sfx", val, "sfx");
            val = replace_type(id, "gfx", val, "gfx");
            val = replace_type(id, "video", val, "video");

            # <text><sentence>to read</sentence><translation>przeczytac</translation></text>
            val = replace_type(id, "text|sentence|translation", val, "transl");

            # em: used to "identify" part of speach
            val = replace_type(id, "em", val, "part");
            # small: used to indicate additional tags
            val = replace_type(id, "small", val, "ext");
            # just another formatting
            val = replace_type(id, "strong", val, "s");
            val = replace_type(id, "big", val, "s");

            # <preview ref="644">model answer</preview>
            val = replace_type(id, "preview", val, "prev");

            # <spellpad correct="both sisters" />
            # <spellpad correct="'ve been studying|have been studying">study</spellpad>
            val = replace_type(id, "spellpad", val, "pad");

            # <true-false true="true" false="false" correct="true" labels="true" />
            val = replace_type(id, "true-false", val, "true");

            val = replace_type(id, "option", val, "option");

            # <checkbox display="inline">
            #     <option correct="true">haven't</option>
            #     <option correct="true">have not</option>
            #     <option>not have</option>
            # </checkbox>
            val = replace_type(id, "checkbox", val, "check");

            # <ordering-list orientation="horizontal" prefix-present="true" suffix-present="true">
            #     <option>I</option>
            #     <option>will</option>
            #     <option>be</option>
            #     <option>swimming</option>
            #     <option>.</option>
            # </ordering-list>
            val = replace_type(id, "ordering-list", val, "order");

            # <select-phrases>
            #     <option>Television</option>
            #     <option correct="true">journalists</option>
            #     <option>are</option>
            #     <option>discussing.</option>
            # </select-phrases>
            val = replace_type(id, "select-phrases", val, "select");

            # <radio display="inline">
            #     <option correct="true">'ve looked after</option>
            #     <option>'s looked after</option>
            # </radio>
            val = replace_type(id, "radio", val, "select");

            # <droplist>
            #     <option correct="true">parents'</option>
            #     <option>parent's</option>
            #     <option>parents</option>
            # </droplist>
            val = replace_type(id, "droplist", val, "select");

            # <drag-drop orientation="horizontal" dropsign="15">
            #    <drop-text>
            #        <gfx file="d" scale-base="512" /> [2]<br />
            #        <gfx file="b" scale-base="512" /> [0]<br />
            #        <gfx file="c" scale-base="512" /> [1]<br />
            #    </drop-text>
            #    <option>a jellyfish</option>
            #    <option>a shark</option>
            #    <option>a sea urchin</option>
            # </drag-drop>
            val = replace_type(id, "drag-drop|drop-text", val, "drag");

            # <m-drop>
            #     <drop-answers>
            #         <d-answer>0,1,2,3</d-answer>
            #         <d-answer>4,5,6</d-answer>
            #         <d-answer>7,8</d-answer>
            #     </drop-answers>
            #     <drop-headers>
            #         <header>Places where plants grow:</header>
            #         <header>Places where doctors are present:</header>
            #         <header>Places that keep law and order:</header>
            #     </drop-headers>
            #     <option>a greenhouse</option>
            #     <option>an island</option>
            #     <option>a park</option>
            #     <option>a field of wheat</option>
            #     <option>a surgery</option>
            #     <option>a surgical ward</option>
            #     <option>a nursing school</option>
            #     <option>a prison</option>
            #     <option>a police station</option>
            # </m-drop>
            val = replace_type(id, "d-answer", val, "");
            val = replace_type(id, "header", val, "");
            val = replace_type(id, "m-drop|drop-answers|drop-headers", val, "drag");

            # tables: no cells defined, whole row makes definition
            val = replace_type(id, "tr|td", val, "row");
            val = replace_type(id, "table|tbody", val, "tab");

            val = replace_type(id, "li", val, "item");
            val = replace_type(id, "ol", val, "list");
            val = replace_type(id, "ul", val, "list");
            val = replace_type(id, "dl", val, "list");

            if (tag == "question") {
                question = val;
            } else if (tag == "answer") {
                answer = val;
            }

            gsub("\n\n*", "\n", val);
            gsub("\n", "\n    ", val);
            if (index(val, "\n") > 0) {
                ret = ret tag ":\n    " val "\n";
            } else {
                ret = ret tag ": " val "\n";
            }
            doc = substr(doc, i + 3 + length(tag));
        }
    }

    val = sprintf("%05d", id);
    for (file in MEDIA) {
        if (substr(file, 1, 5) == val) {
            if (substr(file, 6) == "q.mp3") {
                append_media(file, question);
            } else if (substr(file, 6) == "a.mp3") {
                if (answer != "") {
                    append_media(file, answer);
                } else if (q_media != "true") {
                    append_media(file, question);
                }
            } else if (substr(file, 7) == ".mp3") {
                doc = "@sfx[q]" question "@sfx[a]" answer;
                i = match(doc, "@sfx[^[]*\\[" substr(file, 6, 1) "[^]]*\\]");
                if (i > 0) {
                    append_media(file, substr(doc, i + RLENGTH));
                } else {
                    print "Reference to " file " not found in " id >"/dev/stderr";
                }
            }
        }
    }

    return ret;
}

function print_file() {
    if (file != "") {
        if (keyword != "") {
            KEYWORDS[id] = keyword;
        }
        keyword = "";
        if (name != "") {
            NAMES[id] = name;
        }
        name = "";
        id = "";
        print file;
        file = "";
    }
}

BEGIN{
    MD5["-"] = "";
    cmd = "cd media && md5sum ??????.*";
    i = 0; j = 0;
    while ((cmd | getline) > 0) {
        MEDIA[substr($0, 35)] = "";
        j++;
        if ($1 in MD5) {
            MD5[$1] = MD5[$1] " " substr($0, 35);
        } else {
            MD5[$1] = substr($0, 35);
            i++;
        }
    }
    close(cmd);
    delete MD5["-"];
    print "Found " i " potentially uniq files, " j " in general" >"/dev/stderr";

    FS=": *";
}

{
    if ($0 == "") {
        print_file();
    }
    if ($1 == "keywords") {
        keyword = $2;
    }
    if ($1 == "name") {
        name = $2;
    } else if ($1=="id") {
        id = $2;
        printf $2 "     \r" >"/dev/stderr";
        file=read_item($2);
    }
    print $0;
}

END {
    print_file();

    # print all defs
    print "";
    j = asorti(DEF, SDEF);
    for (i = 1; i <= j; i++) {
        if (index(SDEF[i], ".") == 0) {
            print "@" SDEF[i] ": " DEF[SDEF[i]];
        }
    }

    # save media to media.txt file
    file = "media.txt";
    print "# defined media files" >file;
    # files are reported in the alphabetical order
    n = asort(MD5);
    for (i=1; i<=n; i++) {
        print MD5[i] >>file;

        # join media for all "same" files
        media = "";
        mm = split(MD5[i], MM, "  *");
        for (j = 1; j <= mm; j++) {
            id = MM[j];
            gsub("^0*", "", id);
            gsub("[a-z]\\..*$", "", id);
            if (id in KEYWORDS) {
                media = media KEYWORDS[id] "\n";
            }
            if (id in NAMES) {
                media = media NAMES[id] "\n";
            }
            if (MM[j] in MEDIA) {
                media = media MEDIA[MM[j]];
            }
        }
        delete MM;

        mm = split(media, MM, "\n");
        while (mm > 0) {
            name = "";
            for (j in MM) {
                if (name == "") {
                    name = MM[j];
                }
                if ((name == MM[j]) || (MM[j] == "")) {
                    REMOVE[j] = "";
                }
            }
            for (j in REMOVE) {
                delete MM[j];
                mm--;
            }
            delete REMOVE;

            if (name != "") {
                print name >>file;
            }
        }
        delete MM;

        print "" >>file;
    }
    close(file);
}
