# 01 — Linux Basics

## What is it?

Linux is a Unix-like open-source operating system kernel. Its user-space tools (GNU coreutils) provide the command-line interface that system administrators and DevOps engineers use daily to manage servers.

## Why it matters for Cloud/DevOps

- Nearly all cloud VMs, containers, and serverless runtimes run Linux
- Every Docker image is built on a Linux distribution
- Configuration management (Ansible, Puppet), CI/CD agents, and monitoring agents all execute Linux commands
- Understanding the filesystem and basic commands is the foundation for debugging any production issue

```mermaid
graph TD
    Root[/] --> bin[/bin]
    Root --> etc[/etc]
    Root --> home[/home]
    Root --> proc[/proc]
    Root --> tmp[/tmp]
    Root --> usr[/usr]
    Root --> var[/var]
    var --> log[/var/log]
    var --> spool[/var/spool]
    usr --> usrbin[/usr/bin]
    usr --> usrlib[/usr/lib]
```

## Key Concepts

### File System Hierarchy Standard (FHS)

| Path | Purpose |
|------|---------|
| `/` | Root directory |
| `/bin` | Essential user binaries (now symlink to `/usr/bin`) |
| `/sbin` | System binaries (now symlink to `/usr/sbin`) |
| `/etc` | Host-specific configuration files |
| `/var` | Variable data — logs (`/var/log`), spools, caches |
| `/tmp` | Temporary files (cleared on reboot) |
| `/home` | User home directories |
| `/root` | Root user's home |
| `/proc` | Virtual filesystem for kernel / process info |
| `/sys` | Kernel/device information |
| `/dev` | Device files |
| `/usr` | User system resources — binaries, libraries, docs |
| `/opt` | Optional third-party software |
| `/mnt` | Temporary mount points |

### Essential Commands

```bash
# Navigation
ls -la                     # List all files with details
cd /var/log                # Change directory
pwd                        # Print working directory

# File operations
cp -r source/ dest/        # Copy recursively
mv file.txt /tmp/          # Move / rename
rm -rf dir/                # Remove recursively (⚠ careful)
cat /etc/os-release        # Print file contents
less /var/log/syslog       # Page through files
head -n 20 file            # First 20 lines
tail -f /var/log/syslog    # Follow log in real-time

# Searching
grep -r "ERROR" /var/log/  # Recursive search
find /etc -name "*.conf"   # Find files by name
locate nginx.conf           # Search indexed database (requires updatedb)

# Permissions
chmod 755 script.sh        # rwxr-xr-x
chown user:group file      # Change owner/group
chmod +x script.sh         # Add execute
```

**Permission notation:** `rwxr-xr--` breaks into Owner(6) / Group(5) / Others(4). Numeric: read=4, write=2, execute=1.

### Pipes and Redirection

```bash
# Redirection
command > file             # stdout → file (overwrite)
command >> file            # stdout → file (append)
command 2> file            # stderr → file
command &> file            # both stdout + stderr → file
command < file             # file → stdin

# Pipes
ps aux | grep nginx        # Pipe output of ps into grep
dmesg | tail -20           # Last 20 kernel messages
cat access.log | cut -d' ' -f1 | sort | uniq -c | sort -nr  # Top IPs

# Here documents
cat << EOF > config.conf
server {
    listen 80;
    server_name example.com;
}
EOF

# Process substitution (bash)
diff <(ls dir1) <(ls dir2)
```

## Commands Reference

| Command | What it does | Common flags |
|---------|-------------|--------------|
| `ls` | List directory contents | `-la` long+all, `-lh` human sizes, `-lt` by time |
| `cd` | Change directory | — |
| `cp` | Copy files | `-r` recursive, `-p` preserve attrs, `-a` archive |
| `mv` | Move / rename | — |
| `rm` | Remove files | `-r` recursive, `-f` force, `-i` interactive |
| `cat` | Concatenate / print | `-n` line numbers |
| `grep` | Search text | `-r` recursive, `-i` case-insensitive, `-v` invert, `-c` count |
| `find` | Find files | `-name`, `-type f/d`, `-mtime +7`, `-exec` |
| `chmod` | Change permissions | numeric (755) or symbolic (u+x) |
| `chown` | Change ownership | `user:group` |
| `ln` | Create links | `-s` symbolic |
| `wc` | Word/line count | `-l` lines, `-w` words |
| `sort` | Sort lines | `-n` numeric, `-r` reverse, `-k` key |
| `uniq` | Unique lines | `-c` count occurrences |
| `cut` | Cut fields | `-d` delimiter, `-f` fields |

## Interview Questions

**Q1:** What is the difference between a hard link and a symbolic link?  
**A:** A hard link is a direct directory entry pointing to the same inode (same data blocks). Deleting the original does not remove data until all hard links are removed. A symbolic link is a special file pointing to another file by path; it breaks if the target is moved/deleted. Hard links cannot cross filesystems or point to directories.

**Q2:** Explain what `chmod 755` and `chmod 644` mean.  
**A:** `755` = rwxr-xr-x (owner can r/w/x, group can r/x, others can r/x — typical for executables/directories). `644` = rw-r--r-- (owner can r/w, group and others can r — typical for files).

**Q3:** What is the difference between `>` and `>>` in shell redirection?  
**A:** `>` overwrites the target file. `>>` appends to the target file. Both create the file if it does not exist.

**Q4:** How would you find the 5 largest files under `/var/log`?  
**A:** `find /var/log -type f -exec du -h {} + | sort -rh | head -5`. Or with du: `du -ah /var/log | sort -rh | head -5`.

**Q5:** What is stored in `/proc` and how is it useful?  
**A:** `/proc` is a virtual filesystem exposing kernel data structures. Each process has `/proc/<PID>/` with maps, fd, environ, cmdline. `/proc/cpuinfo`, `/proc/meminfo`, `/proc/loadavg` provide system-level info without external tools.

## Cross-Links

- [02-process-management.md](./02-process-management.md) — processes have PIDs accessible via `/proc/<PID>`
- [04-file-systems.md](./04-file-systems.md) — inodes, links, mount points
- [08-Docker](../08-Docker/README.md) — Dockerfiles use Linux commands
- [14-DevOps](../14-DevOps/README.md) — CI/CD pipelines run shell commands
