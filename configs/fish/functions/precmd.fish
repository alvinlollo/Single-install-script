function precmd --wraps="print -Pn '\\e]133;D;%?\\a\\e]133;A\\a'" --description "alias precmd=print -Pn '\\e]133;D;%?\\a\\e]133;A\\a'"
    print -Pn '\e]133;D;%?\a\e]133;A\a' $argv
end
