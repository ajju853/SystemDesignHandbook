# 03-Linux: Linux Fundamentals for System Design & Cloud Engineering

Linux is the backbone of modern cloud infrastructure. This module covers everything from basic commands to kernel-level features that power containers, performance tuning, and production operations.

## Table of Contents

| # | Topic | File |
|---|-------|------|
| 1 | **Linux Basics** — FS hierarchy, commands, pipes, redirection | [01-linux-basics.md](./01-linux-basics.md) |
| 2 | **Process Management** — ps, top, signals, systemd | [02-process-management.md](./02-process-management.md) |
| 3 | **Memory Management** — virtual memory, swap, OOM, NUMA | [03-memory-management.md](./03-memory-management.md) |
| 4 | **File Systems** — ext4, XFS, Btrfs, LVM, RAID, inodes | [04-file-systems.md](./04-file-systems.md) |
| 5 | **Networking** — ip, ss, tcpdump, iptables, DNS, netns | [05-networking.md](./05-networking.md) |
| 6 | **Shell Scripting** — bash, sed, awk, cron, error handling | [06-shell-scripting.md](./06-shell-scripting.md) |
| 7 | **Performance Tuning** — sysctl, ulimit, perf, strace, sar | [07-performance-tuning.md](./07-performance-tuning.md) |
| 8 | **Security Hardening** — sudoers, SSH, SELinux, auditd | [08-security-hardening.md](./08-security-hardening.md) |
| 9 | **Containerization** — cgroups, namespaces, OverlayFS, seccomp | [09-containerization.md](./09-containerization.md) |

## Prerequisites

- Basic familiarity with the command line
- A Linux environment (Ubuntu/Debian or RHEL/CentOS recommended) for hands-on practice

## Related Modules

- [04-Databases](../04-Databases/README.md) — Databases often run on Linux; understand FS and memory tuning
- [08-Docker](../08-Docker/README.md) — Docker leverages cgroups, namespaces, and union filesystems
- [09-Kubernetes](../09-Kubernetes/README.md) — K8s nodes are Linux hosts; pod networking uses netns
- [14-DevOps](../14-DevOps/README.md) — CI/CD pipelines execute on Linux agents
- [15-SRE](../15-SRE/README.md) — SRE relies on Linux performance observability tools
