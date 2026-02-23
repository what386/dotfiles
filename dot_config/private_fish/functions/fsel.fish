function fsel
    set query (string join ' ' $argv)

    # if user already provided quotes, pass through unchanged
    if string match -q '"*"' $query
        fselect $query
    else
        fselect "$query"
    end
end
