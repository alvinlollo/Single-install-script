function preexec --wraps="print -Pn '\\e]133;B\\a\\e]133;C\\a'" --description "alias preexec=print -Pn '\\e]133;B\\a\\e]133;C\\a'"
    print -Pn '\e]133;B\a\e]133;C\a' $argv
end
