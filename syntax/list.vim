syntax case ignore

syntax match ListComment '^# .*$'
highlight link ListComment Comment

syntax match ListBrackets '(.*)'
highlight link ListBrackets String

" Adblock Rule Syntax
syntax match  AdbRessourceRule  "\$.*$"
syntax match  AdbCssSelector  "##.*$"
syntax match  AdbComment  "^!.*$"
syntax match  AdbComment  "^\[.*\]$"
syntax match  Adbif  "^#if.*$"

highlight link AdbIf Todo
highlight link AdbCssSelector  String
highlight link AdbComment Comment
highlight link AdbCommentUrl Tabline
highlight link AdbRessourceRule Structure

" Clash Rule Syntax
syntax match ClashDomain '^DOMAIN.*,'me=e-1
syntax match ClashComment '^#--.*$'

highlight link ClashComment Comment
highlight link ClashDomain Keyword
