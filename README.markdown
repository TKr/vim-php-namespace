# Goal

vim-php-namespace is a vim plugin for inserting "use" statements automatically.

## Features

### Import classes or functions (add use statements)

### (Updates on this fork) 
The original plugin (information below) was wonderful! Unfortunately, it seems that it is no longer supported by the original developer ([arnaud-lb](https://github.com/arnaud-lb)).
The thing that I needed was the automatic addition of "use" statements without the need to place the cursor under the class names. That's why I made it!

Now just stay in the line (it doesn't matter exactly where: at the beginning, in the middle or at the end) with the `classes / interfaces etc.`, and press the `F3` key. It will find them all!

See some demo:

 * Applying for classes and interfaces when extends and implements a class
<img src="demo/test_namespace0.gif?raw=true" alt="Demo of how classes and interfaces are automatically found and added to the &rdquo;use&rdquo; statements" title="Demo of how classes and interfaces are automatically found and added to the &rdquo;use&rdquo; statements" />

 * Applying for classes and interfaces in PHPDocs and type hints
<img src="demo/test_namespace1.gif?raw=true" alt="Demo of how classes and interfaces are automatically found and added to the &rdquo;use&rdquo; statements" title="Demo of how classes and interfaces are automatically found and added to the &rdquo;use&rdquo; statements" />

 * Applying for classes when instantiating
<img src="demo/test_namespace2.gif?raw=true" alt="Demo of how classes and interfaces are automatically found and added to the &rdquo;use&rdquo; statements" title="Demo of how classes and interfaces are automatically found and added to the &rdquo;use&rdquo; statements" />

To use this feature, add the following mappings in `~/.vimrc`:
```vim
autocmd FileType php nnoremap <silent> <F3> :call PhpInsertUseInLine()<CR>
autocmd FileType php inoremap <silent> <F3> <Esc>:call PhpInsertUseInLine()<CR>
```
P.s for complex cases or when nothing was found, use the old features of the old author.
### ---- From here and below is the old author ----

Automatically adds the corresponding `use` statement for the name under the cursor.

To use this feature, add the following mappings in `~/.vimrc`:
```vim
function! IPhpInsertUse()
    call PhpInsertUse()
    call feedkeys('a',  'n')
endfunction
autocmd FileType php inoremap <Leader>u <Esc>:call IPhpInsertUse()<CR>
autocmd FileType php noremap <Leader>u :call PhpInsertUse()<CR>
```

Then, hitting `\u` in normal or insert mode will import the class or function under the cursor.

``` php
<?php
new Response<-- cursor here or on the name; hit \u now to insert the use statement
```

### Make class or function names fully qualified

Expands the name under the cursor to its fully qualified name.

To use this feature, add the following mappings  in `~/.vimrc`:
```vim
function! IPhpExpandClass()
    call PhpExpandClass()
    call feedkeys('a', 'n')
endfunction
autocmd FileType php inoremap <Leader>e <Esc>:call IPhpExpandClass()<CR>
autocmd FileType php noremap <Leader>e :call PhpExpandClass()<CR>
```

Then, hitting `\e` in normal or insert mode will expand the name to a fully qualified name.

``` php
<?php
$this->getMock('RouterInterface<-- cursor here or on the name; hit \e now to expand the class name'
```

### Sort existing use statements alphabetically

If you do not know how to organize use statements, (or anything else, for that
matter), the alphabetical order might be a sensible choice, because it makes
finding what you are looking for easier, and reduces the risk for conflicts :
if everyone adds new things at the same line, conflicts are guaranteed.

This vim plugin defines a `PhpSortUse()` you may use in your mappings:
```vim
autocmd FileType php inoremap <Leader>s <Esc>:call PhpSortUse()<CR>
autocmd FileType php noremap <Leader>s :call PhpSortUse()<CR>
```

On top of that, you may want to have the dependencies sorted every time you insert one.
To enable this feature, use the dedicated global option:
```vim
let g:php_namespace_sort_after_insert = 1
```

## Installation:

### Using [pathogen](https://github.com/tpope/vim-pathogen)

``` sh
git clone git://github.com/arnaud-lb/vim-php-namespace.git ~/.vim/bundle/vim-php-namespace
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

Add to vimrc:

``` vim
Plug 'arnaud-lb/vim-php-namespace'
```

Run command in vim:

``` vim
:PlugInstall
```

### Using [vundle](https://github.com/gmarik/vundle)

Add to vimrc:

``` vim
Bundle 'arnaud-lb/vim-php-namespace'
```

Run command in vim:

``` vim
:BundleInstall
```

### Manual installation

Download and copy `plugin/phpns.vim` to `~/.vim/plugin/`

## Post installation

### Generate a tag file

The plugin makes use of tag files. If you don't already use a tag file you may create one with the following command; after having installed the `ctags` package:
```sh
ctags -R --PHP-kinds=cfi
```

#### Traits

[universal-ctags] supports traits natively (with `--php-kinds=cfit`).

If you can't use universal-ctags, the `--regex-php` argument allows to extract traits:
```sh
ctags -R --PHP-kinds=cfi
ctags -R --PHP-kinds=cfi --regex-php="/^[ \t]*trait[ \t]+([a-z0_9_]+)/\1/t,traits/i"
```

You can also create a `~/.ctags` file with the following contents:
```sh
--regex-php=/^[ \t]*trait[ \t]+([a-z0_9_]+)/\1/t,traits/i
```

Note that using `--regex-php=` is 10x slower than using universal-ctags.

#### Automatically updating tags

The [AutoTags](http://www.vim.org/scripts/script.php?script_id=1343) plugin can update the tags file every time a file is created or modified under vim.

To keep updates fast, AutoTags won't operate if the tags file exceeds 7MB. To avoid exceeding this limit on projects with many dependencies, use a separate tags file for dependencies:
```sh
# dependencies tags file (index only the vendor directory, and save tags in ./tags.vendors)
ctags -R --PHP-kinds=cfi -f tags.vendors vendor

# project tags file (index only src, and save tags in ./tags; AutoTags will update this one)
ctags -R --PHP-kinds=cfi src
```

Do not forget to load both files in vim:
```vim
" ~/.vimrc
set tags+=tags,tags.vendors
```

### Key mappings

See [Features](#features) section for adding key mappings.

The `<Leader>` key usually is `\`.

## Credits:

 * Arnaud Le Blanc
 * [Contributors](https://github.com/arnaud-lb/vim-php-namespace/graphs/contributors)

This was originally based on a similar script for java packages found at http://vim.wikia.com/wiki/Add_Java_import_statements_automatically (in comments).
