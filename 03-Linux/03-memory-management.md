# 03 — Memory Management

## What is it?

Linux memory management handles how physical RAM and swap space are allocated to processes. It uses **virtual memory** (paging) so each process sees a contiguous address space mapped to physical pages via the MMU's page tables. The kernel manages page allocation, swapping, caching, and the OOM killer as a last resort.

## Why it matters for Cloud/DevOps

- Memory is the most constrained resource on cloud VMs (by cost); overcommitting leads to OOM kills
- Understanding RSS vs VSZ is critical for container resource requests and limits in Kubernetes
- SWAP configuration affects performance — especially on latency-sensitive services
- NUMA awareness is essential for database servers (Redis, PostgreSQL, MySQL) on multi-socket machines
- Memory pressure indicators (free, available, cached) guide scaling decisions

## Key Concepts

### Virtual Memory

Each process has its own virtual address space (0 to `TASK_SIZE`, usually 47 bits on x86_64). The MMU translates virtual addresses to physical pages.

```
Process A                    Process B
+----------+                +----------+
| Stack    |                | Stack    |
|   ↓      |                |   ↓      |
|   ↑      |                |   ↑      |
| Heap     |                | Heap     |
| Data     |                | Data     |
| Text     |                | Text     |
+----------+                +----------+
     ↓  MMU page tables        ↓
+----------------------------------+
|         Physical RAM            |
+----------------------------------+
```

```bash
# Memory maps of a process
cat /proc/1/maps              # Address space of PID 1
pmap -x 1234                  # Detailed memory map for PID 1234
```

### RSS, VSZ, and Shared Memory

| Metric | Meaning |
|--------|---------|
| **VSZ** | Virtual memory size — total address space allocated |
| **RSS** | Resident set size — physical RAM currently used |
| **Shared** | Memory shared with other processes (shared libraries) |
| **Dirty** | Pages modified but not yet written to disk |
| **PSS** | Proportional set size — RSS split by number of sharing processes |

```bash
# Per-process memory usage
ps -eo pid,ppid,cmd,vsz,rss,%mem --sort=-%mem | head -10

# System-wide
free -h                      # Human-readable memory summary
cat /proc/meminfo            # Detailed breakdown
```

### SWAP

Swap is disk-backed overflow when physical RAM is full. The kernel uses the **swapiness** parameter (0–100, default 60) to decide how aggressively to swap.

```bash
# Create and enable swap
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Check swap usage
swapon --show
cat /proc/swaps

# Tune swap behavior
sysctl vm.swappiness=10                   # Less aggressive swapping
echo "vm.swappiness=10" >> /etc/sysctl.conf  # Persist
```

### OOM Killer

When memory is exhausted, the kernel invokes the Out-Of-Memory killer. It scores processes by `oom_score` and kills the highest scorer.

```bash
# Check OOM score
cat /proc/1234/oom_score    # Higher = more likely to be killed
cat /proc/1234/oom_score_adj  # -1000 disables OOM kill, +1000 makes likely

# Protect a critical process
echo -1000 > /proc/mysql_pid/oom_score_adj

# Past OOM events
journalctl -k | grep -i oom
dmesg | grep -i "killed process"
```

### NUMA Architecture

Non-Uniform Memory Access: each CPU socket has its own memory bank. Accessing local memory is faster than remote (another socket's memory).

```bash
# Check NUMA topology
numactl --hardware            # Node layout
lscpu | grep -i numa          # NUMA node count

# Run process on specific NUMA node
numactl --cpunodebind=0 --membind=0 ./latency-sensitive-app

# Check allocations per node
numastat -p <PID>
```

### Huge Pages

The default page size is 4 KB. Huge pages (2 MB or 1 GB) reduce TLB misses for large-memory applications.

```bash
# Transparent Huge Pages (THP) — automatic
cat /sys/kernel/mm/transparent_hugepage/enabled  # [always] madvise never
echo never > /sys/kernel/mm/transparent_hugepage/enabled  # Disable (for DBs)

# Static Huge Pages — pre-allocated
echo 1024 > /proc/sys/vm/nr_hugepages    # Allocate 1024 × 2MB = 2GB
cat /proc/meminfo | grep Huge             # Verify

# Use in applications (mmap with MAP_HUGETLB)
mount -t hugetlbfs hugetlbfs /mnt/huge
```

## Commands Reference

| Command | What it does | Key flags |
|---------|-------------|-----------|
| `free` | Show memory usage | `-h` human, `-m` MB, `-w` wide |
| `vmstat` | Virtual memory stats | `1` every second, `-s` summary |
| `top` / `htop` | Per-process memory | Press `M` sort by mem |
| `pmap` | Process memory map | `-x` extended, `-XX` kernel details |
| `smem` | PSS-based reporting | `-r` by RSS, `-p` by PSS |
| `numactl` | NUMA control | `--hardware`, `--cpunodebind`, `--membind` |
| `numastat` | NUMA allocation stats | `-p <PID>` |
| `sysctl` | Kernel parameter control | `vm.swappiness`, `vm.overcommit` |
| `slabtop` | Kernel slab cache info | Interactive |
| `ipcs` | IPC / shared memory | `-m` shmem segments |

## Interview Questions

**Q1:** What's the difference between RSS and VSZ?  
**A:** VSZ is the total virtual address space allocated (including mapped files, shared libraries, stack, heap — whether or not they're in RAM). RSS is the portion of physical RAM actually used. VSZ can be 10x larger than RSS. For container limits, use RSS (or PSS for more accuracy).

**Q2:** When would you disable Transparent Huge Pages?  
**A:** THP can cause latency spikes in databases (e.g., MySQL, PostgreSQL, MongoDB, Elasticsearch) because kernel background threads (`khugepaged`) defragment memory and pause processes. Databases typically recommend `echo never > /sys/kernel/mm/transparent_hugepage/enabled` and use explicit huge pages instead.

**Q3:** Explain the OOM killer's `oom_score` and `oom_score_adj`.  
**A:** `oom_score` is computed from the process's RSS, swap usage, page table memory, and other factors. Higher score = more likely to be killed. `oom_score_adj` (-1000 to +1000) adjusts this score: -1000 makes the process immune (badness score = 0), +1000 makes it the top target. Set +1000 for sacrificial processes, -1000 for critical daemons.

**Q4:** What is the NUMA effect on database performance?  
**A:** On multi-socket systems, a process running on socket A accessing memory on socket B incurs higher latency (20-40% slower). Database servers (especially Redis, MySQL) should be pinned to local NUMA nodes. Use `numactl --cpunodebind --membind` to avoid cross-socket memory access.

**Q5:** What does `vm.swappiness=1` mean and when would you use it?  
**A:** Swappiness (0–100) controls the kernel's tendency to swap. `1` tells the kernel to swap only to avoid OOM, keeping processes in RAM as much as possible. Used for latency-sensitive applications (databases, caches) where swapping would cause severe performance degradation.

## Cross-Links

- [02-process-management.md](./02-process-management.md) — OOM killer interaction with processes
- [07-performance-tuning.md](./07-performance-tuning.md) — sysctl tuning for memory
- [08-Docker](../08-Docker/README.md) — memory limits use cgroups memory controller
- [09-Kubernetes](../09-Kubernetes/README.md) — pod resource requests/limits map to cgroup memory limits
- [15-SRE](../15-SRE/README.md) — memory pressure alerting and capacity planning
