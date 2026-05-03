function _tide_item_jobs
    set -q _tide_jobs || return
    if set -q _tide_stopped_jobs && test "$_tide_stopped_jobs" -gt 0
        set -f icon '⚙️'
    else
        set -f icon $tide_jobs_icon
    end
    if test $_tide_jobs -ge $tide_jobs_number_threshold
        _tide_print_item jobs $icon' ' $_tide_jobs
    else
        _tide_print_item jobs $icon
    end
end
