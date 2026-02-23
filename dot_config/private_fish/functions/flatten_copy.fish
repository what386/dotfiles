function flatten_copy
    if test (count $argv) -lt 2
        echo "Usage: flatten_copy SOURCE_DIR TARGET_DIR"
        return 1
    end

    set src $argv[1]
    set dst $argv[2]

    mkdir -p $dst

    set i 1
    for f in (find $src -type f)
        set base (basename $f)
        set target "$dst/$base"

        while test -e $target
            set target "$dst/"(string replace -r '(\.[^.]+)?$' "_$i\$1" -- $base)
            set i (math $i + 1)
        end

        cp $f $target
    end
end
