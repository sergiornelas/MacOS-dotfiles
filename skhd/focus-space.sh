#!/bin/sh
# Enfoca el escritorio N con el atajo nativo de Mission Control y lo repara si
# el Dock lo perdió.
#
# En System Settings, "Switch to Desktop 1-4" están en hyper + F13-F16 (teclas
# que nadie más usa) y skhd las simula: así el salto es directo, con una sola
# animación. yabai --focus lo haría sin animación, pero requiere la scripting
# addition y con ella desactivar SIP.
#
# Desde macOS 27 (Golden Gate) el Dock pierde de vez en cuando los atajos de
# algunos escritorios (al parecer al conectar o desconectar el monitor) y solo
# los recupera al reiniciarse. Si tras el atajo el escritorio no se vuelve
# visible, se reinicia el Dock y se reintenta: el costo es una espera de un par
# de segundos, una vez por cada vez que se rompe.
#
# TEMPORAL: solo hasta que Golden Gate corrija el bug al conectar/desconectar el
# display. Para revertir: en Mission Control devolver "Switch to Desktop 1-4" a
# hyper + i/o/p/u, quitar los atajos de "Space navigation" en skhdrc y borrar
# este script.

target=$1
case $target in
  1) key=f13 ;;
  2) key=f14 ;;
  3) key=f15 ;;
  4) key=f16 ;;
  *) exit 1 ;;
esac

visible() {
  [ "$(yabai -m query --spaces --space "$target" | jq '."is-visible"')" = true ]
}

# Ya visible (quizá en el otro monitor): el atajo solo mueve el foco y no hay
# cambio que detectar
if visible; then
  skhd -k "hyper - $key"
  exit 0
fi

# Espera hasta $1 décimas de segundo a que el escritorio se vuelva visible. El
# salto nativo tarda ~0.4 s en reflejarse en yabai
wait_visible() {
  n=0
  while [ "$n" -lt "$1" ]; do
    visible && return 0
    /bin/sleep 0.1
    n=$((n + 1))
  done
  return 1
}

skhd -k "hyper - $key"
wait_visible 10 && exit 0

killall Dock
# El Dock tarda en volver a registrar los atajos: se reintenta hasta que
# responda. Pulsaciones de más no importan, todas van al mismo escritorio
n=0
while [ "$n" -lt 10 ]; do
  /bin/sleep 0.5
  skhd -k "hyper - $key"
  wait_visible 5 && exit 0
  n=$((n + 1))
done
