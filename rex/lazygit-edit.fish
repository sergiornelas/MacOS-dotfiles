# `e` de lazygit dentro de Rex (os.edit en rex/lazygit.yml).
#
# Abre los archivos en el nvim de la pestaña: primero el del panel desde el que
# se abrió lazygit, luego cualquier otro (rex/init.lua, lazygit_editors). Rex da
# el pid de cada nvim, así que su socket se conoce sin preguntar a los demás nvim
# (uno colgado en otro lado no puede congelar lazygit). Después minimiza lazygit
# y enfoca ese nvim; si no hay nvim en la pestaña, abre uno en un split.
#
# Uso: fish lazygit-edit.fish [--line N] <archivo>...

set -l line
if test (count $argv) -ge 2 -a "$argv[1]" = --line
    set line $argv[2]
    set -e argv[1..2]
end
set -l files $argv
test (count $files) -eq 0; and exit 0

set -l lua_args
test -n "$line"; and set lua_args --line $line

# Los sockets de nvim viven en $TMPDIR/nvim.$USER/<aleatorio>/nvim.<pid>.0
set -l tmp $TMPDIR
test -n "$tmp"; or set tmp (getconf DARWIN_USER_TEMP_DIR)
set -l rundir (string trim -r -c / -- $tmp)/nvim.$USER

for editor in (rex do -b $REX_BLOCK lazygit_editors --json 2>/dev/null | jq -r '.editors[] | "\(.block_id) \(.pid)"')
    set -l parts (string split ' ' -- $editor)
    # Un nvim con interfaz tiene el socket en su hijo `nvim --embed`.
    for pid in $parts[2] (pgrep -P $parts[2])
        for sock in $rundir/*/nvim.$pid.0
            if nvim -u NONE -l (status dirname)/lazygit-open.lua $sock $lua_args $files
                rex do -b $REX_BLOCK lazygit_show_editor --args (jq -nc --arg b $parts[1] '{block_id: $b}') >/dev/null
                exit 0
            end
        end
    end
end

# Sin nvim en la pestaña: uno nuevo en un split junto al panel de origen.
set -l cmd nvim
test -n "$line"; and set -a cmd +$line
set -a cmd -- $files
rex do -b $REX_BLOCK lazygit_show_editor \
    --args (jq -nc --arg cwd $PWD '{argv: $ARGS.positional, cwd: $cwd}' --args $cmd) >/dev/null
