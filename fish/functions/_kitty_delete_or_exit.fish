function _kitty_delete_or_exit --description 'ctrl-d that asks before closing the last kitty pane'
    # Like delete-or-exit, but when this shell is the pane's own process it
    # closes the pane through kitty/close_window.py, which confirms when it's
    # the last pane. Nested shells (nvim :terminal, fish in fish) just exit.
    if test -n "$(commandline)"
        commandline -f delete-char
    else if test "$(ps -o ppid= -p $fish_pid | string trim)" = "$KITTY_PID"
        kitten @ action --self kitten close_window.py
        or exit
    else
        exit
    end
end
