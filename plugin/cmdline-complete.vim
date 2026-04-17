vim9script noclear

# 防止重复加载
if exists('*g:CmdlineComplete')
    finish
endif

var save_cpo = &cpo
set cpo&vim

# ===== 键位映射 (核心修复区) =====
if !hasmapto('<Plug>CmdlineCompleteBackward', 'c')
    cnoremap <unique> <silent> <c-p> <Plug>CmdlineCompleteBackward
endif
if !hasmapto('<Plug>CmdlineCompleteForward', 'c')
    cnoremap <unique> <silent> <c-n> <Plug>CmdlineCompleteForward
endif

# 这里必须使用 v:true 和 v:false，因为映射表达式在全局作用域求值
cnoremap <silent> <Plug>CmdlineCompleteBackward <c-r>=g:CmdlineComplete(v:true)<CR>
cnoremap <silent> <Plug>CmdlineCompleteForward  <c-r>=g:CmdlineComplete(v:false)<CR>

# ===== 变量管理 =====
var seed: string = ""
var completions: list<string> = [""]
var completions_set: dict<number> = {}
var comp_i: number = 0
var search_cursor: list<number> = [0, 0, 0, 0]
var sought_bw: number = 0
var sought_fw: number = 0
var last_cmdline: string = ""
var last_pos: number = 0

def InitVariables()
    seed = ""
    completions = [""]
    completions_set = {}
    comp_i = 0
    search_cursor = getpos(".")
    sought_bw = 0
    sought_fw = 0
    last_cmdline = ""
    last_pos = 0
enddef

# 生成补全列表
def GenerateCompletions(seed_arg: string, backward: bool): bool
    var regexp: string
    if empty(seed_arg)
        regexp = '\<\k\k\+'
    elseif seed_arg =~ '\K'
        regexp = '\<\(\V' .. seed_arg .. '\)\k\+'
    else
        regexp = '\<' .. seed_arg .. '\k\+'
    endif

    if &ignorecase && !(&smartcase && seed_arg =~ '\C[A-Z]')
        regexp = '\c' .. regexp
    endif

    var save_ignorecase = &ignorecase
    set noignorecase

    var r: list<number> = []
    # Vim9 显式比较
    if sought_bw < search_cursor[1]
        var r1 = search_cursor[1] - sought_bw
        var r2 = 1
        if sought_fw > (line('$') - search_cursor[1] + 1)
            r2 = sought_fw - line('$') + search_cursor[1]
        endif
        r = backward ? [r1, r2] : [r2, r1]
    endif

    if sought_fw < (line('$') - search_cursor[1] + 1)
        var r1 = line('$')
        var r2 = search_cursor[1] + sought_fw
        if sought_bw > search_cursor[1]
            r1 = line('$') - sought_bw + search_cursor[1]
        endif
        if backward
            r += [r1, r2]
        else
            r = [r2, r1] + r
        endif
    endif

    var found = false
    while !empty(r) && !found
        var candidates: list<string> = []
        var line_num = r[0]
        var line_str = getline(line_num)
        var start = match(line_str, regexp)

        while start != -1
            var candidate = matchstr(line_str, '\k\+', start)
            var next_pos = start + len(candidate)
            
            var is_near_cursor = false
            if line_num != search_cursor[1]
                is_near_cursor = true
            elseif backward && ((sought_bw == 0 && start < search_cursor[2]) || (sought_bw != 0 && start >= search_cursor[2]))
                is_near_cursor = true
            elseif !backward && ((sought_fw != 0 && next_pos < search_cursor[2]) || (sought_fw == 0 && next_pos >= search_cursor[2]))
                is_near_cursor = true
            endif

            if is_near_cursor
                add(candidates, candidate)
            endif
            start = match(line_str, regexp, next_pos)
        endwhile

        if !empty(candidates)
            if backward
                for i in range(len(candidates) - 1, 0, -1)
                    var cand = candidates[i]
                    if !has_key(completions_set, cand)
                        completions_set[cand] = 1
                        insert(completions, cand, 1)
                        comp_i += 1
                        found = true
                    endif
                endfor
            else
                for cand in candidates
                    if !has_key(completions_set, cand)
                        completions_set[cand] = 1
                        add(completions, cand)
                        found = true
                    endif
                endfor
            endif
        endif

        if backward
            sought_bw += 1
        else
            sought_fw += 1
        endif

        if found | break | endif

        if r[1] > r[0]
            r[0] += 1
        elseif r[1] < r[0]
            r[0] -= 1
        else
            remove(r, 0, 1)
        endif
    endwhile

    &ignorecase = save_ignorecase
    return found
enddef

# 主函数
def g:CmdlineComplete(backward: bool): string
    var cmdline = getcmdline()
    var pos = getcmdpos()

    if cmdline != last_cmdline || pos != last_pos
        InitVariables()
        last_cmdline = cmdline
        last_pos = pos

        var s = match(strpart(cmdline, 0, pos - 1), '\k*$')
        seed = (s == -1) ? "" : strpart(cmdline, s, pos - 1 - s)
        
        completions = [seed]
        completions_set = {}
    endif

    var at_boundary = false
    if backward && comp_i == 0
        at_boundary = true
    elseif !backward && comp_i == (len(completions) - 1)
        at_boundary = true
    endif

    if at_boundary && (sought_bw + sought_fw <= line('$'))
        GenerateCompletions(seed, backward)
    endif

    var old_word = completions[comp_i]

    if backward
        comp_i = (comp_i == 0) ? (len(completions) - 1) : (comp_i - 1)
    else
        comp_i = (comp_i == (len(completions) - 1)) ? 0 : (comp_i + 1)
    endif

    var new_word = completions[comp_i]

    last_cmdline = strpart(last_cmdline, 0, last_pos - 1 - len(old_word)) .. new_word .. strpart(last_cmdline, last_pos - 1)
    last_pos = last_pos - len(old_word) + len(new_word)

    feedkeys(" \<bs>", 'n')
    return substitute(old_word, ".", "\<c-h>", "g") .. new_word
enddef

&cpo = save_cpo
