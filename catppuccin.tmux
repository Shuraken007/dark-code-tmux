#!/usr/bin/env bash
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_tmux_option() {
  local option value default
  option="$1"
  default="$2"
  value="$(tmux show-option -gqv "$option")"

  if [ -n "$value" ]; then
    echo "$value"
  else
    echo "$default"
  fi
}

set() {
  local option=$1
  local value=$2
  tmux_commands+=(set-option -gq "$option" "$value" ";")
}

setw() {
  local option=$1
  local value=$2
  tmux_commands+=(set-window-option -gq "$option" "$value" ";")
}

main() {
  local theme
  theme="$(get_tmux_option "@catppuccin_flavour" "dark-code")"

  # Aggregate all commands in one array
  local tmux_commands=()

  # NOTE: Pulling in the selected theme by the theme that's being set as local
  # variables.
  # shellcheck source=catppuccin-frappe.tmuxtheme
  source /dev/stdin <<<"$(sed -e "/^[^#].*=/s/^/local /" "${PLUGIN_DIR}/catppuccin-${theme}.tmuxtheme")"

  # status
  set status "on"
  set status-bg "${thm_bg}"
  set status-justify "left"
  set status-left-length "100"
  set status-right-length "100"

  # messages
  set message-style "fg=${thm_cyan},bg=${thm_bg},align=centre"
  set message-command-style "fg=${thm_cyan},bg=${thm_bg},align=centre"

  # panes
  set pane-border-style "fg=${thm_bg}"
  set pane-active-border-style "fg=${thm_blue}"

  # windows
  setw window-status-activity-style "fg=${thm_fg},bg=${thm_bg},none"
  setw window-status-separator ""
  setw window-status-style "fg=${thm_fg},bg=${thm_bg},none"

  # --------=== Statusline

  # NOTE: Checking for the value of @catppuccin_window_tabs_enabled
  local wt_enabled
  wt_enabled="$(get_tmux_option "@catppuccin_window_tabs_enabled" "off")"
  readonly wt_enabled

  local right_separator
  right_separator="$(get_tmux_option "@catppuccin_right_separator" "")"
  readonly right_separator

  local left_separator
  left_separator="$(get_tmux_option "@catppuccin_left_separator" "")"
  readonly left_separator

  local window
  window="$(get_tmux_option "@catppuccin_window" "off")"
  readonly window

  local user
  user="$(get_tmux_option "@catppuccin_user" "off")"
  readonly user

  local user_icon
  user_icon="$(get_tmux_option "@catppuccin_user_icon" "")"
  readonly user_icon

  local lang
  lang="$(get_tmux_option "@catppuccin_lang" "off")"
  readonly lang

  local host
  host="$(get_tmux_option "@catppuccin_host" "off")"
  readonly host

  local speed
  speed="$(get_tmux_option "@catppuccin_speed" "off")"
  readonly speed

  local directory_icon
  directory_icon="$(get_tmux_option "@catppuccin_directory_icon" "")"
  readonly directory_icon

  local window_icon
  window_icon="$(get_tmux_option "@catppuccin_window_icon" "")"
  readonly window_icon

  local session_icon
  session_icon="$(get_tmux_option "@catppuccin_session_icon" "")"
  readonly session_icon

  local language_icon
  language_icon="$(get_tmux_option "@catppuccin_language_icon" "󰗊")"
  readonly language_icon

  local host_icon
  host_icon="$(get_tmux_option "@catppuccin_host_icon" "󰒋")"
  readonly host_icon

  local date_time
  date_time="$(get_tmux_option "@catppuccin_date_time" "off")"
  readonly date_time

  local datetime_icon
  datetime_icon="$(get_tmux_option "@catppuccin_datetime_icon" "")"
  readonly datetime_icon

  local dspeed_icon
  dspeed_icon="$(get_tmux_option "@catppuccin_dspeed_icon" "D:")"
  readonly dspeed_icon

  # These variables are the defaults so that the setw and set calls are easier to parse.
  local show_directory
  readonly show_directory="#[fg=$thm_pink,bg=$thm_bg,nobold,nounderscore,noitalics]$right_separator#[fg=$thm_bg,bg=$thm_pink,nobold,nounderscore,noitalics]$directory_icon  #[fg=$thm_fg,bg=$thm_bg] #{b:pane_current_path} #{?client_prefix,#[fg=$thm_orange],#[fg=$thm_green]}"

  local show_window
  readonly show_window="#[fg=$thm_fg,bg=$thm_bg,nobold,nounderscore,noitalics]$right_separator#[fg=$thm_bg,bg=$thm_fg,nobold,nounderscore,noitalics]$window_icon #[fg=$thm_fg,bg=$thm_bg] #W #{?client_prefix,#[fg=$thm_orange], #[fg=$thm_green]}"

  local show_session
  local session_fg="#{?client_prefix,#[fg=$thm_orange],#[fg=$thm_green]}#[bg=$thm_bg]"
  local session_bg="#{?client_prefix,#[bg=$thm_orange],#[bg=$thm_green]}#[fg=$thm_bg]"

  readonly show_session="$session_fg$right_separator$session_bg$session_icon #[fg=$thm_fg,bg=$thm_bg] #S "

  local language="#(cat \$XDG_CACHE_HOME/windows_events/lang)"
  local lang_fg_color="#{?#{==:$language,ru},#[fg=$thm_orange],#[fg=$thm_green]}"
  local lang_bg_color="#{?#{==:$language,ru},#[bg=$thm_orange],#[bg=$thm_green]}"
  local show_lang
  readonly show_lang="$lang_fg_color#[bg=$thm_bg]$right_separator#[fg=$thm_bg]$lang_bg_color$language$lang_fg_color#[bg=$thm_bg]$left_separator#[fg=$thm_fg,bg=$thm_bg] "

  local show_directory_in_window_status
  readonly show_directory_in_window_status="#[fg=$thm_bg,bg=$thm_fg] #I #[fg=$thm_fg,bg=$thm_bg] #{b:pane_current_path} "

  local show_directory_in_window_status_current
  readonly show_directory_in_window_status_current="#[fg=$thm_bg,bg=$thm_light_orange] #I #[fg=$thm_fg,bg=$thm_bg] #{b:pane_current_path} "

  local show_window_in_window_status
  readonly show_window_in_window_status="#[fg=$thm_fg,bg=$thm_bg] #W #[fg=$thm_bg,bg=$thm_gray] #I#[fg=$thm_gray,bg=$thm_bg]$left_separator#[fg=$thm_fg,bg=$thm_bg,nobold,nounderscore,noitalics] "

  local show_window_in_window_status_current
  readonly show_window_in_window_status_current="#[fg=$thm_fg,bg=$thm_bg] #W #[fg=$thm_bg,bg=$thm_light_orange] #I#[fg=$thm_light_orange,bg=$thm_bg]$left_separator#[fg=$thm_fg,bg=$thm_bg,nobold,nounderscore,noitalics] "

  local show_user
  readonly show_user="#[fg=$thm_blue,bg=$thm_bg]$right_separator#[fg=$thm_bg,bg=$thm_blue]$user_icon #[fg=$thm_fg,bg=$thm_bg] #(whoami) "

  local show_host
  readonly show_host="#[fg=$thm_blue,bg=$thm_bg]$right_separator#[fg=$thm_bg,bg=$thm_blue]$host_icon #[fg=$thm_fg,bg=$thm_bg] #H "

  local show_date_time
  readonly show_date_time="#[fg=$thm_bg,bg=$thm_bg]$right_separator#[fg=$thm_fg,bg=$thm_bg]$datetime_icon #[fg=$thm_fg,bg=$thm_bg] $date_time "

  local show_speed
  readonly show_speed="#{?#{!=:#{download_speed},0 B/s},#[fg=$thm_green]#[bg=$thm_bg]$right_separator#[bg=$thm_green]#[fg=$thm_bg]$dspeed_icon #[fg=$thm_fg#,bg=$thm_bg] #{download_speed},}"

  local right_column1
  # Right column 1 by default shows the Window name.
  if [[ "${window}" == "on" ]]; then
    right_column1=$show_window
  fi

  # Right column 2 by default shows the current Session name.
  local right_column2=$show_session

  # Window status by default shows the current directory basename.
  local window_status_format=$show_directory_in_window_status
  local window_status_current_format=$show_directory_in_window_status_current

  # NOTE: With the @catppuccin_window_tabs_enabled set to on, we're going to
  # update the right_column1 and the window_status_* variables.
  if [[ "${wt_enabled}" == "on" ]]; then
    right_column1=$show_directory
    window_status_format="#($PLUGIN_DIR/get_status.pl --window-status-format)"
    window_status_current_format="#($PLUGIN_DIR/get_status.pl --window-status-current-format)"
  fi

  if [[ "${speed}" == "on" ]]; then
    right_column1=$show_speed$right_column1
  fi

  if [[ "${user}" == "on" ]]; then
    right_column2=$right_column2$show_user
  fi

  if [[ "${host}" == "on" ]]; then
    right_column2=$right_column2$show_host
  fi

  if [[ "${lang}" == "on" ]]; then
    right_column2=$show_lang$right_column2
  fi

  if [[ "${date_time}" != "off" ]]; then
    right_column2=$right_column2$show_date_time
  fi
  
  # set length
  # tmux set-option -g status-left-length 100
  # tmux set-option -g status-right-length 100
  set status-left "#($PLUGIN_DIR/get_status.pl --status-left)"
  set status-right "#($PLUGIN_DIR/get_status.pl --status-right)"
  # set status-right "${right_column1} ${right_column2}"
  # set status-window "#($PLUGIN_DIR/get_status.pl --windows)"
  # setw window-status-format "#($PLUGIN_DIR/get_status.pl --window-status-format)"
  # setw window-status-current-format "#($PLUGIN_DIR/get_status.pl --window-status-current-format)"
  setw window-status-format ""
  setw window-status-current-format ""

  # --------=== Modes
  #
  setw clock-mode-colour "${thm_blue}"
  setw mode-style "fg=${thm_orange} bg=${thm_blue} bold"

  tmux "${tmux_commands[@]}"
}

main "$@"
