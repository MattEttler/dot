set relativenumber number
set ignorecase
set smartcase
set hlsearch
set cursorline

set termguicolors
colorscheme habamax

let &t_SI = "\e[6 q"
let &t_SR = "\e[4 q"
let &t_EI = "\e[2 q"

augroup autoquickfix
	autocmd!
	autocmd QuickFixCmdPost [^l]* cwindow
	autocmd QuickFixCmdPost l* lwindow
augroup END

nnoremap <C-p> :Gfind 
nnoremap <leader>ps :call <SID>DoGrep()<CR>

" Fuzzy search Git-tracked file contents with a clean Quickfix view
function! s:DoGrep()
    let pattern = input('Grep: ')
    if !empty(pattern)
        silent execute 'grep ' . pattern
        redraw!
        copen
    endif
endfunction

" Fuzzy search Git-tracked files with a clean Quickfix view
command! -nargs=+ Gfind call s:GitFuzzyFind(<f-args>)

function! s:GitFuzzyFind(...)
    " Build a fuzzy regex: .*arg1.*arg2.*
    let l:pattern = '.*' . join(a:000, '.*') . '.*'
    
    " Fast shell execution using git and grep
    let l:cmd = 'git ls-files | grep -iE "' . l:pattern . '"'
    let l:results = systemlist(l:cmd)

    if empty(l:results)
        echo "No matches found"
        return
    endif

    " REMOVE 'lnum' and 'text' to clean up the display
    " This leaves only the filename in the Quickfix list
    let l:qf_list = map(l:results, '{ "filename": v:val }')
    
    call setqflist(l:qf_list)
    copen
endfunction

" Hide line/column numbers in the Quickfix window via concealing
augroup QuickFixClean
    autocmd!
    autocmd FileType qf setlocal conceallevel=2 concealcursor=nc
    autocmd FileType qf syntax match qfSeparator /|.\+|/ transparent conceal
augroup END

if executable('git')
	set grepprg=git\ grep\ -n
	set grepformat^=%f:%l:%c:%m
endif

augroup highlight_yank
  autocmd!
  autocmd TextYankPost * silent! call s:HighlightYank()
augroup END

function! s:HighlightYank() abort
  " Get info about the most recent yank
  let regtype = getregtype()
  let startpos = getpos("'[")
  let endpos   = getpos("']")

  " Build a pattern to match the yanked area
  if regtype ==# 'V'
    " Linewise yank (yy, Y, etc.)
    let pattern = '\%>' . (startpos[1]-1) . 'l\%<' . (endpos[1]+1) . 'l'
  elseif regtype ==# 'v'
    " Characterwise yank
    let pattern = '\%>' . (startpos[1]-1) . 'l\%' . startpos[2] . 'c\_.*\%<' .
          \ (endpos[1]+1) . 'l\%' . endpos[2] . 'c'
  else
    " Blockwise or fallback
    let pattern = '\%>' . (startpos[1]-1) . 'l\%<' . (endpos[1]+1) . 'l'
  endif

  " Highlight and clear after 200ms
  silent! execute 'match Search /' . pattern . '/'
  redraw
  match none
endfunction

