"Script_name: txt.vim

syn case ignore

scriptencoding utf-8

"关键词
syn keyword txtTodo todo fixme note debug comment notice
syn keyword txtError error bug caution dropped

"以# !号打头的行为注释文本
syn match txtComment '^[!#].*$' contains=txtTodo

"标题文本: 前面有任意个空格,数字.[数字.]打头, 并且该行里不含有,.。，等标点符号
"
syn match txtTitle "^\(\d\+ \)\+\s*[^,。，]\+$"
syn match txtTitle "^\(\d\+ \)\+\s*[^,。，]\+,"
"
syn match txtTitle "^\(\d\+\.\)\+\s*[^,。，]\+$"
syn match txtTitle "^\(\d\+\.\)\+\s*[^,。，]\+,"

"标题文本: 汉字数字加'.、'打头，且该行不含,.。，标点符号
syn match txtTitle "^\([第一二三四五六七八九十百千万亿篇卷章节]\+[、.]\)\+\s*[^,。，]\+$"
syn match txtTitle "^\([第一二三四五六七八九十百千万亿篇卷章节]\+[、.]\)\+\s*[^,。，]\+,"

"标题文本: 以数字打头, 中间有空格, 后跟任意文字. 且该行不含有,.。，标点符号
syn match txtTitle "^\d\s\+.\+\s*[^,。，]$"
syn match txtTitle "^\d\s\+.\+\s*[^,。，],"

"列表文本: 任意空格打头, 后跟一个[-+*.]
syn match txtList    '^\s*\zs[-+*.] [^ ]'me=e-1

"列表文本: 任意空格打头, 后跟一个(数字) 或 (字母) 打头的文本行
syn match txtList    '^\s*\zs(\=\([0-9]\+\|[a-zA-Z]\))'

"列表文本: 至少一个空格打头, [数字.]打头, 但随后不能跟数字(排除把5.5这样的文本当成列表) 
syn match txtList "^\s\+\zs\d\+\.\d\@!"

"引号内文字, 包括全角半角, 作用范围最多两行
syn match   txtQuotes     '["'“‘][^"'”’]\+\(\n\)\=[^"'”’]*["'”’]' contains=txtUrl,txtReference

"括号内文字, 不在行首(为了和txtList区别), 作用范围最多两行
syn match   txtParentesis "[(（][^)）]\+\(\n\)\=[^)）]*[)）]" contains=txtUrl,txtReference

"其它括号内文字, 作用范围最多两行, 大括号无行数限制
syn match txtBrackets     '<[^<]\+\(\n\)\=[^<]*>' contains=txtUrl,txtReference
syn match txtBrackets     '\[[^\[]\+\(\n\)\=[^\[]*\]' contains=txtUrl,txtReference
"syn region txtBrackets    matchgroup=txtOperator start="{"        end="}" contains=txtUrl,txtReference

"link url
syn match txtUrl '\<[A-Za-z0-9_.-]\+@\([A-Za-z0-9_-]\+\.\)\+[A-Za-z]\{2,4}\>\(?[A-Za-z0-9%&=+.,@*_-]\+\)\='
syn match txtUrl   '\<\(\(https\=\|ftp\|news\|telnet\|gopher\|wais\)://\([A-Za-z0-9._-]\+\(:[^ @]*\)\=@\)\=\|\(www[23]\=\.\|ftp\.\)\)[A-Za-z0-9%._/~:,=$@-]\+\>/*\(?[A-Za-z0-9/%&=+.,@*_-]\+\)\=\(#[A-Za-z0-9%._-]\+\)\='

"email text:
syn match txtEmailMsg '^\s*\(From\|De\|Sent\|To\|Para\|Date\|Data\|Assunto\|Subject\):.*'
"reference from reply email, quotes, etc.
syn match   txtReference '^[|>:]\(\s*[|>:]\)*'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"类html文本
"syn match   txtBold       '\*[^*[:blank:]].\{-}\*'hs=s+1,he=e-1
"syn match txtItalic "^\s\+.\+$" "斜体文本

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" color definitions (specific)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"hi txtUrl        term=bold        cterm=bold  ctermfg=blue    gui=underline     guifg=blue
"hi txtTitle     term=bold       cterm=bold      ctermfg=black   gui=bold        guifg=black
hi link txtUrl          Underlined"ModeMsg"Tabline
hi link txtTitle        Title"ModeMsg"Tabline
hi link txtList         SignColumn"DiffText"Statement
hi link txtComment      Comment
hi link txtReference    DiffAdd"Comment
hi link txtQuotes       String
hi link txtParentesis   MoreMsg"Comment
hi link txtBrackets     Todo
hi link txtError        ErrorMsg
hi link txtTodo         Todo
hi link txtEmailMsg     Structure

let b:current_syntax = 'txt'
" vim:tw=0:et
