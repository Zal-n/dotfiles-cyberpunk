function newc --description 'Creates a new defautl c file'
    printf "#include <stdio.h>\n\nint main()\n{\n\n}" >$argv[1]
    nvim $argv[1]
end
