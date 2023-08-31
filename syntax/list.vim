syntax case ignore

syntax match  AdbRessourceRule  "\$.*$"
syntax match  AdbCssSelector  "##.*$"
syntax match  AdbCommentUrl  "http\S*"
syntax match  AdbComment  "^!.*$"
syntax match  AdbComment  "^\[.*\]$" contains=AdbCommentUrl
syntax match  Adbif  "^#if.*$"

highlight link AdbIf Todo
highlight link AdbCssSelector  String
highlight link AdbComment Comment
highlight link AdbCommentUrl Tabline
highlight link AdbRessourceRule Structure


syntax match ClashDomain '^DOMAIN.*,'me=e-1
syntax match ClashComment '^#.*$'
highlight link ClashComment Comment
highlight link ClashDomain Keyword
