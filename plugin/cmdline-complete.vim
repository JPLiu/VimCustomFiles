vim9script noclear

# 防止重复加载（通过检查函数是否存在）
if exists('*CmdlineComplete')
    finish
endif

# ===== 修复 &cpo 存储问题（Vim9 兼容方式） =====
var save_cpo = &cpo
set cpo&vim

# 默认键位映射
# 映射 <c-p> 和 <c-n> 到 <Plug> 映射，以便后续调用 CmdlineComplete 函数
if !hasmapto('<Plug>CmdlineCompleteBackward', 'c')
    cnoremap <unique> <silent> <c-p> <Plug>CmdlineCompleteBackward
endif
if !hasmapto('<Plug>CmdlineCompleteForward', 'c')
    cnoremap <unique> <silent> <c-n> <Plug>CmdlineCompleteForward
endif

# 将 <Plug> 映射到实际的函数调用
cnoremap <silent> <Plug>CmdlineCompleteBackward <c-r>=CmdlineComplete(1)<CR>
cnoremap <silent> <Plug>CmdlineCompleteForward  <c-r>=CmdlineComplete(0)<CR>

# ===== 全局状态管理（不使用 g: 或 s: 前缀）=====
# 在 Vim9 脚本中，所有变量默认在脚本模块内具有局部作用域
# 不需要 s: 或 g: 前缀，但要注意这些变量只在脚本模块内有效
var seed = ""
var completions = [""]
var completions_set = {}
var comp_i = 0
var search_cursor = getpos(".")
var sought_bw = 0
var sought_fw = 0
var last_cmdline = ""
var last_pos = 0

# 初始化变量
def InitVariables()
    if seed == ""  # 检查 seed 是否为空，作为初始化标志
        seed = ""
        completions = [""]
        completions_set = {}
        comp_i = 0
        search_cursor = getpos(".")
        sought_bw = 0
        sought_fw = 0
        last_cmdline = ""
        last_pos = 0
    endif
enddef

# 生成补全列表（纯 VimScript 实现）
def GenerateCompletions(seed_arg: string, backward: bool): bool
    var regexp: string
    if empty(seed_arg)
        regexp = '\<\k\k\+'  # 匹配至少 2 个关键字字符
    elseif seed_arg =~ '\K'  # 处理特殊关键字字符
        regexp = '\<\(\V' .. seed_arg .. '\)\k\+'
    else
        regexp = '\<' .. seed_arg .. '\k\+'  # 匹配种子词 + 后续关键字字符
    endif

    # 忽略大小写（如果启用且未启用 smartcase）
    if &ignorecase && !(&smartcase && seed_arg =~ '\C[A-Z]')
        regexp = '\c' .. regexp
    endif

    # 备份当前 ignorecase 设置，搜索时禁用忽略大小写
    var save_ignorecase: bool = &ignorecase
    set noignorecase

    var r: list<number> = []  # 搜索范围（行号）
    if sought_bw < search_cursor[1]  # 如果之前向后搜索过
        var r1: number = search_cursor[1] - sought_bw
        var r2: number = 1
        if sought_fw > line('$') - search_cursor[1] + 1
            r2 = sought_fw - line('$') + search_cursor[1]
        endif
        if backward
            r = [r1, r2]  # 向后搜索范围
        else
            r = [r2, r1]  # 向前搜索范围
        endif
    endif
    if sought_fw < line('$') - search_cursor[1] + 1  # 如果之前向前搜索过
        var r1: number = line('$')
        var r2: number = search_cursor[1] + sought_fw
        if sought_bw > search_cursor[1]
            r1 = line('$') - sought_bw + search_cursor[1]
        endif
        if backward
            r = r + [r1, r2]
        else
            r = [r2, r1] + r  # 向前搜索范围
        endif
    endif

    var found: bool = false
    while !empty(r) && !found
        var candidates: list<string> = []
        var line_num: number = r[0]
        var line: string = getline(line_num)
        var start: number = match(line, regexp)  # 查找匹配的起始位置

        while start != -1
            var candidate: string = matchstr(line, '\k\+', start)  # 提取关键字
            var next_pos: number = start + len(candidate)
            # 检查是否在光标附近（避免重复匹配）
            if r[0] != search_cursor[1]
                    \ || (backward && (!sought_bw && start < search_cursor[2]
                        \ || sought_bw && start >= search_cursor[2]))
                    \ || (!backward && (sought_fw && next_pos < search_cursor[2]
                        \ || !sought_fw && next_pos >= search_cursor[2]))
                add(candidates, candidate)
            endif
            start = match(line, regexp, next_pos)  # 继续查找下一个匹配
        endwhile

        if !empty(candidates)
            if backward
                # 向后补全：从后往前遍历，避免重复
                for i in range(len(candidates) - 1, 0, -1)
                    var candidate: string = candidates[i]
                    if !has_key(completions_set, candidate)
                        completions_set[candidate] = 1
                        call insert(completions, candidate)
                        comp_i += 1
                        found = true
                    endif
                endfor
            else
                # 向前补全：从前往后遍历，避免重复
                for i in range(len(candidates))
                    var candidate: string = candidates[i]
                    if !has_key(completions_set, candidate)
                        completions_set[candidate] = 1
                        call add(completions, candidate)
                        found = true
                    endif
                endfor
            endif
        endif

        if backward
            sought_bw += 1  # 记录向后搜索次数
        else
            sought_fw += 1  # 记录向前搜索次数
        endif

        if found
            break
        endif

        # 调整搜索范围
        if r[1] > r[0]
            r[0] += 1
        elseif r[1] < r[0]
            r[0] -= 1
        else
            remove(r, 0, 1)  # 移除无效范围
        endif
    endwhile

    # 恢复 ignorecase 设置
    &ignorecase = save_ignorecase

    return true
enddef

# 主补全函数（处理 <c-p> / <c-n>）
def g:CmdlineComplete(backward: bool): string
    InitVariables()  # 初始化变量

    var cmdline: string = getcmdline()
    var pos: number = getcmdpos()

    # 如果命令行状态变化，重新计算补全种子
    if cmdline != last_cmdline || pos != last_pos
        last_cmdline = cmdline
        last_pos = pos

        var s: number = match(strpart(cmdline, 0, pos - 1), '\k*$')  # 找到最后一个关键字的位置
        if s == -1
            seed = ""
        else
            seed = strpart(cmdline, s, pos - 1 - s)  # 提取种子词
        endif
        completions = [seed]  # 初始化补全列表
        completions_set = {}  # 记录已补全的词
        comp_i = 0  # 当前补全索引
        search_cursor = getpos(".")  # 记录当前光标位置
        sought_bw = 0  # 向后搜索次数
        sought_fw = 0  # 向前搜索次数
    endif

    # 如果补全列表未初始化，尝试生成补全项
    if sought_bw + sought_fw <= line('$') && (
            (backward && comp_i == 0) ||
            (!backward && comp_i == len(completions) - 1))
        GenerateCompletions(seed, backward)
    endif

    var old: string = completions[comp_i]  # 当前补全词

    # 更新补全索引（循环）
    if backward
        if comp_i == 0
            comp_i = len(completions) - 1
        else
            comp_i -= 1
        endif
    else
        if comp_i == len(completions) - 1
            comp_i = 0
        else
            comp_i += 1
        endif
    endif

    var new: string = completions[comp_i]  # 新补全词

    # 更新命令行状态（替换旧词为新词）
    last_cmdline = strpart(last_cmdline, 0, last_pos - 1 - len(old))
            .. new .. strpart(last_cmdline, last_pos - 1)
    last_pos = last_pos - len(old) + len(new)

    # 发送退格键（避免映射冲突）
    feedkeys(" \<bs>", 'n')

    # 返回补全结果（替换旧词）
    return substitute(old, ".", "\<c-h>", "g") .. new
enddef
