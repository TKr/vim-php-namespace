" Inserts 'use' statements for the class under the cursor
" Makes use of tag files
"
" Maintainer: Arnaud Le Blanc <arnaud.lb at gmail dot com>
" URL: https://github.com/arnaud-lb/vim-php-namespace
"
" This is an adaptation of a script found at http://vim.wikia.com/wiki/Add_Java_import_statements_automatically

let s:capture = 0

let g:php_namespace_sort = get(g:, 'php_namespace_sort', "'{,'}-1sort i")

let g:php_namespace_sort_after_insert = get(g:, 'php_namespace_sort_after_insert', 0)

function! PhpFindMatchingUse(name)

    " matches use [function] Foo\Bar as <name>
    let pattern = '\%(^\|\r\|\n\)\s*use\%(\_s+function\)\?\_s\+\_[^;]\{-}\_s*\(\_[^;,]*\)\_s\+as\_s\+' . a:name . '\_s*[;,]'
    let fqn = s:searchCapture(pattern, 1)
    if fqn isnot 0
        return fqn
    endif

    " matches use [function] Foo\<name>
    let pattern = '\%(^\|\r\|\n\)\s*use\%(\_s+function\)\?\_s\+\_[^;]\{-}\_s*\(\_[^;,]*\%(\\\|\_s\)' . a:name . '\)\_s*[;,]'
    let fqn = s:searchCapture(pattern, 1)
    if fqn isnot 0
        return fqn
    endif

endfunction

function! PhpFindFqn(name)
    let restorepos = line(".") . "normal!" . virtcol(".") . "|"
    let loadedCount = 0
    let tags = []

    try
        let fqn = PhpFindMatchingUse(a:name)
        if fqn isnot 0
            return ['class', fqn]
        endif

        let tags = taglist("^".a:name."$")

        if len(tags) < 1
            throw "No tag were found for ".a:name."; is your tag file up to date? Tag files in use: ".join(tagfiles(),',')
        endif

        " see if some of the matching files are already loaded
        for tag in tags
            if bufexists(tag['filename'])
                let loadedCount += 1
            endif
        endfor

        exe "ptjump " . a:name
        try
            wincmd P
        catch /.*/
            return
        endtry
        1
        if search('^\s*\%(/\*.*\*/\s*\)\?\%(\%(abstract\|final\)\_s\+\)*\%(class\|interface\|trait\)\_s\+' . a:name . '\>') > 0
            if search('^\%(<?\%(php\s\+\)\?\)\?\s*namespace\s\+', 'be') > 0
                let start = col('.')
                call search('\([[:blank:]]*[[:alnum:]\\_]\)*', 'ce')
                let end = col('.')
                let ns = strpart(getline(line('.')), start, end-start)
                return ['class', ns . "\\" . a:name]
            else
                return ['class', a:name]
            endif
        elseif search('^\s*function\_s\+' . a:name . '\>') > 0
            if search('^\%(<?\%(php\s\+\)\?\)\?\s*namespace\s\+', 'be') > 0
                let start = col('.')
                call search('\([[:blank:]]*[[:alnum:]\\_]\)*', 'ce')
                let end = col('.')
                let ns = strpart(getline(line('.')), start, end-start)
                return ['function', ns . "\\" . a:name]
            else
                return a:name
            endif

        else
            throw a:name . ": not found!"
        endif
    finally
        let loadedCountNew = 0
        for tag in tags
            if bufexists(tag['filename'])
                let loadedCountNew += 1
            endif
        endfor

        if loadedCountNew > loadedCount
            " wipe preview window (from buffer list)
            silent! wincmd P
            if &previewwindow
                bwipeout
            endif
        else
            wincmd z
        endif
        exe restorepos
    endtry
endfunction

function! PhpInsertUse(...)
    exe "normal mz"
    if a:0 == 1
        let cur_name = a:1
    else
        " move to the first component
        " Foo\Bar => move to the F
        call search('[[:alnum:]\\:_]\+', 'bcW')
        let cur_name = expand("<cword>")
    endif
    try
        let search_phrase = substitute(cur_name, "::class", "", "")
        let fqn = PhpFindMatchingUse(search_phrase)
        if fqn isnot 0
            exe "normal! `z"
            throw "import for " . search_phrase . " already exists"
            return
        endif
        let tfqn = PhpFindFqn(search_phrase)
        if tfqn is 0
            throw "fully qualified class name was not found"
            return
        endif
        if tfqn[0] == 'function'
            let use = "use function ".tfqn[1].";"
        else
            let use = "use ".tfqn[1].";"
        endif
        " insert after last use or namespace or <?php
        if search('^use\_s\%(function\_s\+\)\?\_[[:alnum:][:blank:]\\_]*;', 'be') > 0
            call append(line('.'), use)
        elseif search('^\s*namespace\_s\_[[:alnum:][:blank:]\\_]*[;{]', 'be') > 0
            call append(line('.'), "")
            call append(line('.')+1, use)
        elseif search('<?\%(php\)\?', 'be') > 0
            call append(line('.'), "")
            call append(line('.')+1, use)
        else
            call append(1, use)
        endif
        if g:php_namespace_sort_after_insert
            call PhpSortUse()
        endif
    catch /.*/
        echoerr v:exception
    finally
        exe "normal! `z"
    endtry
endfunction

function! PhpExpandClass()
    let restorepos = line(".") . "normal!" . virtcol(".") . "|"
    " move to last element
    call search('\%#[[:alnum:]\\_]\+', 'cW')
    " move to first char of last element
    call search('[[:alnum:]_]\+', 'bcW')
    let cur_class = expand("<cword>")
    let fqn = PhpFindFqn(cur_class)
    if fqn is 0
        return
    endif
    substitute /\%#[[:alnum:]\\_]\+/\=fqn[1]/
    exe restorepos
    " move cursor after fqn
    call search('\([[:blank:]]*[[:alnum:]\\_]\)*', 'ceW')
endfunction

function! PhpInsertUseInLine()
    let matches = s:SelectAllMatchesInLine()
    if len(matches) == 0
        echohl Error | echomsg "Nothing found" | echohl NONE
        return 1
    endif

    "Name storage of "added" and "skipped" classes/interfaces
    let status = {"added": [], "skipped": []}

    " Cycle through matches
    for currMatch in matches
        try
            call PhpInsertUse(currMatch)
            call add(status.added, currMatch)
        catch
            call add(status.skipped, {'name': currMatch, 'reason': substitute(v:exception, 'Vim(.\+):', '', 'g')})
        endtry
    endfor
    if len(status.added) > 0
        echomsg "Added \"Use\" for:"
        for element in status.added
            echomsg "  ― " . element
        endfor
    endif
    if len(status.skipped) > 0
        echohl Error | echomsg "Skipped \"Use\" for:" | echohl NONE
        for element in status.skipped
            echomsg "  ― " . element.name . " (Reason: " . element.reason .")"
        endfor
    endif
    return 0
endfunction

function! s:SelectAllMatchesInLine()
    let phpNames_pattern = '[a-zA-Z_][a-zA-Z0-9_]*'
    "let phpNamespace_pattern = "[\\_a-zA-Z\x7f-\xff][\\_a-zA-Z0-9\x7f-\xff]*"
    let funcName_pattern = phpNames_pattern
    let className_pattern = phpNames_pattern
    let interfaceName_pattern = phpNames_pattern
    "let traitName_pattern = phpNames_pattern
    let typeHints = ["int", "string", "float", "bool", "array", "callable", "iterable", "object", "self"]
    let typeHints_pattern = join(typeHints, '\|')
    let currLine = getline(".")

    "[public] function [someMethod|someFunc](Some\Interface $someVar): int {
    let patternsToMatch = ['function\s\+' . funcName_pattern . '\s*(\s*\(\(?\?\zs\(\%(' . typeHints_pattern . '\)\s\)\@!\)' . interfaceName_pattern  . '\)\+\ze\s\+[&\$]']

    "/** @param [null|]Some\Interface $someVar
    call add(patternsToMatch, '\* @param \%(null|\)\?\(\zs\(\(\%(mixed\|' . typeHints_pattern . '\)\s\)\@!\)' . className_pattern . '\)\+\ze\s\+\$')

    "$obj = new someClass[()];
    call add(patternsToMatch, 'new\s\+\zs' . className_pattern . '\ze\s*(\?')

    "return someClass::[someMethod($obj)|someVariable];
    call add(patternsToMatch, '\zs' . className_pattern . '\ze\s*::\s*' . phpNames_pattern . '\s*(\?')

    " class someClass extends anotherClass {
    call add(patternsToMatch, 'class\s\+' . className_pattern . '\s\+extends\s\+\zs' . className_pattern . '\ze')

    " class someClass [extends anotherClass] implements someInterface, anotherInterface {
    if currLine =~ 'class\s\+' . className_pattern . '.\+\simplements\s\+' . interfaceName_pattern
        call add(patternsToMatch, '\%(\zs' . interfaceName_pattern . '\ze\s*\%($\|{\|,\)\|,\s\+\zs' . interfaceName_pattern . '\ze\)')
    endif

    " Need to work it out better
    " class someClass {
    "     use someTraitInsideClasses;
    "if currLine =~ '\%(class\s\+'. className_pattern . '\)\@<=\_.\+use\s\+' . traitName_pattern . '\s*\%(,\|;\)'
    "    call add(patternsToMatch, '\%(\zs' . traitName_pattern . '\ze\s*\%(;\|,\)\|,\s\+\zs' . traitName_pattern . '\ze\)')
    "endif

    " How many patterns can be applied to the current line?
    call filter(patternsToMatch, 'currLine =~ v:val')

    let matches = []
    if len(patternsToMatch) > 0
        " Get all matches (classes and interfaces)
        call substitute(currLine, join(patternsToMatch, '\|'), '\=add(matches, submatch(0))', 'g')
    endif
    " Remove duplicates
    let uniqueList = []
    for m in matches
        if index(uniqueList, m) == -1
            call add(uniqueList, m)
        endif
    endfor
    return uniqueList
endfunction

function! s:searchCapture(pattern, nr)
    let s:capture = 0
    let str = join(getline(0, line('$')),"\n")
    call substitute(str, a:pattern, '\=[submatch(0), s:saveCapture(submatch('.a:nr.'))][0]', 'e')
    return s:capture
endfunction

function! s:saveCapture(capture)
    let s:capture = a:capture
endfunction

function! PhpSortUse()
    let restorepos = line(".") . "normal!" . virtcol(".") . "|"
     " insert after last use or namespace or <?php
    if search('^use\_s\_[[:alnum:][:blank:]\\_]*;', 'be') > 0
        execute g:php_namespace_sort
    else
        echo "No use statements found."
    endif
    exe restorepos
endfunction
