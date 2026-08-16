#!/bin/sh
# Salta el foco y el cursor al "otro" display.
#
# La decisión se toma según la POSICIÓN FÍSICA REAL del cursor (ground-truth
# del OS), no según el estado de foco de yabai. El foco de yabai se actualiza
# de forma asíncrona, así que consultarlo en cambios rápidos (p.ej. hyper-j
# seguido de hyper-k) devolvía un estado viejo y el cursor no seguía al display
# correcto. La posición del cursor, en cambio, siempre está al día.
#
# Nota: pensado para 2 monitores (elige el display que no contiene el cursor).
# Con 3+ toma el primero que no lo contiene, que puede no ser el deseado.

pos=$(cliclick p)
px=${pos%,*}
py=${pos#*,}

target=$(yabai -m query --displays | jq --argjson px "$px" --argjson py "$py" -r '
  first(.[] | select(
    $px < .frame.x or $px >= (.frame.x + .frame.w) or
    $py < .frame.y or $py >= (.frame.y + .frame.h)
  ))')

[ -z "$target" ] && exit 0

idx=$(printf '%s' "$target" | jq -r '.index')
coords=$(printf '%s' "$target" | jq -r '.frame | "\(.x + .w / 2 | floor),\(.y + .h / 2 | floor)"')

# Mueve el cursor ANTES de enfocar: si se hace después, el warp compite con la
# transición de display y a veces se pierde. Con mouse_follows_focus apagado, el
# --focus no toca el cursor, así que queda donde lo dejamos. El segundo warp
# reafirma la posición por si la transición la alteró.
cliclick "m:$coords"
yabai -m display --focus "$idx"
cliclick "m:$coords"
