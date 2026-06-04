# WhatsApp Architecture

## Overview
WhatsApp serves 2B+ users with only ~50 engineers at acquisition. The key: simple architecture, Erlang, and extreme efficiency.

## Key Stats
- 2B+ users
- 65B+ messages/day
- ~50 engineers (at Facebook acquisition)
- Single server could handle 1M+ connections

## Architecture

```
Client ──► Connection Manager (Erlang)
                  │
            ┌─────┴─────┐
            │  Chat      │
            │  Router    │
            └─────┬─────┘
                  │
            ┌─────┴─────┐
            │  Account   │
            │  Store     │
            │  (custom)  │
            └───────────┘
```

## Key Lessons

| Technology | Why |
|------------|-----|
| **Erlang** | Soft real-time, massive concurrency, hot code reload |
| **Custom protocol** | Minimal overhead, binary, encrypted |
| **No message storage** | Messages deleted after delivery |
| **SMPP for SMS** | Carrier integration for verification |
| **FreeBSD** | Network stack optimization |

## Interview Questions
1. Why did WhatsApp choose Erlang?
2. How does WhatsApp handle message delivery with minimal infrastructure?
3. How does WhatsApp maintain end-to-end encryption?
4. How did WhatsApp scale to 2B users with a tiny team?
5. Design a simplified WhatsApp messaging system
