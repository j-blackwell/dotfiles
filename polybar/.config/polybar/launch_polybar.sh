config_path="~/.config/polybar/config.ini"

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload toph --config=$config_path &
  done
else
  polybar --reload toph --config=$config_path &
fi
