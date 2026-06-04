# 06 — Shell Scripting

## What is it?

Shell scripting (primarily Bash) is the art of automating command-line tasks by writing sequences of commands in a script file. It's the glue that ties together Linux tools — parsing logs, deploying software, orchestrating backups, and configuring servers.

## Why it matters for Cloud/DevOps

- Infrastructure-as-Code (Terraform, Ansible) often delegates to shell scripts for logic beyond their declarative model
- CI/CD pipelines (GitHub Actions, GitLab CI, Jenkins) execute shell commands as build steps
- Dockerfiles embed shell scripts for image customization
- Emergency incident response demands quick ad-hoc scripting
- Understanding shell scripting is prerequisite for understanding tools like `~/.bashrc`, init scripts, and cron jobs

## Key Concepts

### Variables and Parameter Expansion

```bash
# Variables — no spaces around =
NAME="world"
echo "Hello, $NAME"          # → Hello, world
echo "Hello, ${NAME}"        # Same, but allows ${NAME}_suffix

# Default values
echo "${USER:-default}"      # Use 'default' if USER is unset
echo "${USER:=default}"      # Assign default if unset
echo "${USER:?error msg}"    # Error if unset (exit)

# Special variables
echo "$0"                    # Script name
echo "$1 $2 $3"              # Positional arguments
echo "$#"                    # Number of arguments
echo "$@"                    # All arguments as separate words
echo "$*"                    # All arguments as single word
echo "$?"                    # Exit code of last command
echo "$$"                    # PID of current script
```

### Conditionals

```bash
# if / elif / else
if [ "$1" = "start" ]; then
    echo "Starting..."
elif [ "$1" = "stop" ]; then
    echo "Stopping..."
else
    echo "Usage: $0 {start|stop}"
    exit 1
fi

# File tests
if [ -f "$FILE" ]; then      # File exists and is regular
if [ -d "$DIR" ]; then       # Directory exists
if [ -x "$BIN" ]; then       # Executable exists
if [ -z "$STR" ]; then       # String is empty
if [ -n "$STR" ]; then       # String is non-empty

# Numeric comparison
if [ "$COUNT" -gt 10 ]; then  # -gt, -lt, -ge, -le, -eq, -ne

# String comparison
if [ "$A" = "$B" ]; then     # Equal (POSIX =, not ==)
if [ "$A" != "$B" ]; then    # Not equal

# Modern [[ ]] (Bash-only, supports regex)
if [[ "$FILE" =~ \.log$ ]]; then
    echo "It's a log file"
fi

# AND / OR
if [ "$1" = "on" ] && [ "$2" = "true" ]; then
if [ "$1" = "off" ] || [ "$1" = "stop" ]; then
```

### Loops

```bash
# For loop over explicit list
for i in 1 2 3 4 5; do
    echo "Number: $i"
done

# For loop over sequence
for i in {1..10}; do
    echo "$i"
done

# For loop over command output
for file in /var/log/*.log; do
    echo "Processing: $file"
done

# C-style for
for ((i=0; i<10; i++)); do
    echo "$i"
done

# While loop — read lines
while read -r line; do
    echo "LINE: $line"
done < /var/log/syslog

# While with counter
count=0
while [ "$count" -lt 5 ]; do
    echo "$count"
    ((count++))
done

# Until
until ping -c1 google.com &>/dev/null; do
    echo "Waiting for network..."
    sleep 2
done
```

### Functions

```bash
# Define
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Use
log_info "Deployment started"
log_error "Connection failed"

# Return values (status code, not stdout)
check_port() {
    nc -zv localhost "$1" &>/dev/null
    return $?
}

if check_port 8080; then
    echo "Port 8080 is open"
fi
```

### Error Handling

```bash
# Exit on error
set -e                        # Exit script on any command failure
set -u                        # Exit on undefined variable usage
set -o pipefail               # Fail pipeline if any command fails
set -euo pipefail             # "Holy trinity" — use at top of scripts

# Trap — catch signals / cleanup
cleanup() {
    echo "Cleaning up..."
    rm -f /tmp/tempfile_$$
}
trap cleanup EXIT             # Run on exit (always)
trap "echo Interrupted; exit" INT  # On Ctrl+C

# Check exit codes explicitly
if ! command_that_might_fail; then
    log_error "Command failed"
    exit 1
fi
```

### sed — Stream Editor

```bash
# Substitute
sed 's/old/new/' file          # First occurrence per line
sed 's/old/new/g' file         # Global (all occurrences)
sed -i 's/old/new/g' file      # In-place edit
sed 's/old/new/2' file         # Only 2nd occurrence per line

# Line addressing
sed '5s/old/new/' file         # Only line 5
sed '10,20s/old/new/' file     # Lines 10-20
sed '/^#/d' file               # Delete comment lines
sed '/DEBUG/,/END/d' file      # Delete range

# Print matching lines
sed -n '/ERROR/p' file         # -n suppresses default print
```

### awk — Text Processing

```bash
# Field extraction
awk '{print $1, $3}' file              # 1st and 3rd columns
awk -F: '{print $1, $6}' /etc/passwd   # Custom delimiter

# Pattern matching
awk '/ERROR/ {print $0}' /var/log/syslog
awk '$3 > 100 {print $1, $3}' /proc/meminfo

# Built-in variables
awk '{print NR, $0}' file              # Line numbers
awk 'END {print NR}' file              # Count lines
awk 'BEGIN {sum=0} {sum+=$1} END {print sum}'  # Sum column

# Formatted output
awk '{printf "%-20s %8d\n", $1, $2}' file
```

### Cron Jobs

```bash
# Edit crontab
crontab -e                    # Edit current user's crontab
crontab -l                    # List cron jobs

# Format: minute hour day month weekday command
#         0-59   0-23 1-31 1-12   0-6

# Examples:
*/5 * * * * /usr/local/bin/healthcheck.sh     # Every 5 minutes
0 * * * * /usr/local/bin/hourly-backup.sh     # Every hour at :00
0 2 * * * /usr/local/bin/daily-cleanup.sh     # Daily at 2 AM
0 0 * * 0 /usr/local/bin/weekly-report.sh     # Sunday at midnight
0 0 1 * * /usr/local/bin/monthly-archive.sh   # 1st of month

# System cron directories (preferred for scripts)
/etc/cron.hourly/
/etc/cron.daily/
/etc/cron.weekly/
/etc/cron.monthly/
```

## Commands Reference

| Command | What it does | Key flags |
|---------|-------------|-----------|
| `grep` | Search text | `-r`, `-i`, `-v`, `-o`, `-E` |
| `sed` | Stream editor | `-i`, `-n`, `s///g`, `d` |
| `awk` | Text processing | `-F`, `{print}`, `NR`, `NF` |
| `cut` | Column extraction | `-d`, `-f` |
| `sort` | Sort lines | `-n`, `-r`, `-k`, `-t` |
| `uniq` | Unique lines | `-c`, `-d` |
| `xargs` | Build/execute args | `-I`, `-P` parallel, `-n` |
| `tee` | Split stdout to file | `-a` append |
| `tr` | Translate chars | `-d` delete, `-s` squeeze |
| `basename` | Strip dir | — |
| `dirname` | Strip file | — |
| `date` | Date/time | `+%Y-%m-%d`, `-d` other date |
| `crontab` | Cron editor | `-e`, `-l`, `-r` |

## Interview Questions

**Q1:** What is the difference between `$@` and `$*` in Bash?  
**A:** `$@` expands each argument as a separate quoted word — `"$@"` becomes `"arg1" "arg2" "arg3"`. `$*` expands all arguments as a single word — `"$*"` becomes `"arg1 arg2 arg3"`. For iterating arguments, always use `"$@"`.

**Q2:** What does `set -euo pipefail` mean and why should you use it?  
**A:** `set -e` exits on any error (`exit 0` command fails). `set -u` treats undefined variables as errors. `set -o pipefail` makes a pipeline fail if any command in the pipeline fails (not just the last). Together they prevent silent failures — critical for production automation scripts.

**Q3:** How do you debug a bash script?  
**A:** Use `bash -x script.sh` (prints each command with expanded arguments before executing). Or add `set -x` inside the script to enable and `set +x` to disable. For less verbosity, `bash -v` prints lines as read. Also check `$?` systematically.

**Q4:** When would you use `awk` vs `sed` vs plain bash?  
**A:** `sed` excels at simple substitutions and line-based edits (`s/old/new/g`). `awk` is ideal for structured columnar data (like `/etc/passwd`, logs). Plain bash handles simple conditions, loops, and command orchestration. For anything involving CSV parsing or JSON manipulation, use dedicated tools (e.g., `jq` for JSON).

**Q5:** How does `xargs` work and why is it useful?  
**A:** `xargs` reads items from stdin and builds/runs commands with those items as arguments. `find /tmp -name "*.tmp" -print0 | xargs -0 rm` avoids "Argument list too long" errors. `-P N` parallelizes execution (e.g., `xargs -P 4 curl` for parallel HTTP requests).

## Cross-Links

- [01-linux-basics.md](./01-linux-basics.md) — the commands that scripts orchestrate
- [07-performance-tuning.md](./07-performance-tuning.md) — scripts collect performance data
- [08-Docker](../08-Docker/README.md) — Dockerfiles use shell scripting in RUN commands
- [14-DevOps](../14-DevOps/README.md) — CI/CD pipelines execute shell scripts
