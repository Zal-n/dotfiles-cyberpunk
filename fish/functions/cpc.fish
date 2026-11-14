function cpc --description 'Copies a files content to clipboard'
    cat $argv[1] | dms clipboard copy
end
