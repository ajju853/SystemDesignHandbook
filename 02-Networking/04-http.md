# HTTP (Hypertext Transfer Protocol)

## Definition
HTTP is the foundation protocol of the World Wide Web. It's a request-response protocol in the client-server model, where a client (usually a web browser) sends a request to a server, which returns a response.

## Real-World Example
**Every website visit**: When you visit github.com, your browser sends an HTTP GET request to GitHub's servers, which respond with HTML, CSS, JS, and images. Each resource is fetched via HTTP.

## HTTP Request Structure

```
GET /api/users HTTP/1.1
Host: example.com
User-Agent: Mozilla/5.0
Accept: application/json
Authorization: Bearer <token>
Connection: keep-alive

                                  ← Blank line separates headers from body
{"query": "search term"}          ← Body (POST/PUT only)
```

## HTTP Response Structure

```
HTTP/1.1 200 OK
Date: Mon, 01 Jan 2024 12:00:00 GMT
Content-Type: application/json
Content-Length: 123
Cache-Control: max-age=3600
Set-Cookie: session=abc123; Path=/

                                  ← Blank line
{"id": 1, "name": "Alice"}       ← Response body
```

## HTTP Methods

| Method | Purpose | Idempotent | Safe | Has Body |
|--------|---------|------------|------|----------|
| GET | Retrieve resource | ✅ | ✅ | ❌ |
| HEAD | Get headers only | ✅ | ✅ | ❌ |
| POST | Create resource | ❌ | ❌ | ✅ |
| PUT | Replace resource | ✅ | ❌ | ✅ |
| PATCH | Partial update | ❌ | ❌ | ✅ |
| DELETE | Remove resource | ✅ | ❌ | ❌ |
| OPTIONS | Available methods | ✅ | ✅ | ❌ |

## HTTP Status Codes

### 1xx — Informational
- **100 Continue**: Send the rest of the request
- **101 Switching Protocols**: Upgrade to WebSocket

### 2xx — Success
- **200 OK**: Request succeeded
- **201 Created**: Resource created (POST)
- **202 Accepted**: Request accepted for async processing
- **204 No Content**: Success, no body (DELETE)

### 3xx — Redirection
- **301 Moved Permanently**: Resource moved, update your links
- **302 Found**: Temporary redirect
- **304 Not Modified**: Use cached version

### 4xx — Client Error
- **400 Bad Request**: Malformed request
- **401 Unauthorized**: Authentication required
- **403 Forbidden**: Authenticated but not allowed
- **404 Not Found**: Resource doesn't exist
- **405 Method Not Allowed**: Wrong HTTP method
- **429 Too Many Requests**: Rate limited

### 5xx — Server Error
- **500 Internal Server Error**: Generic server error
- **502 Bad Gateway**: Upstream server returned invalid response
- **503 Service Unavailable**: Temporarily overloaded or down
- **504 Gateway Timeout**: Upstream didn't respond in time

## HTTP Connection Models

### HTTP/1.0 — Short-lived
```
Client                  Server
  │                       │
  ├── Request ──────────►│
  │◄── Response ────────│
  │── Close ────────────►│
  │                       │
  ├── New Request ──────►│  ← New TCP connection!
  │◄── Response ────────│
  └───────────────────────┘
```

### HTTP/1.1 — Persistent + Pipelining
```
Client                  Server
  │                       │
  ├── Request ──────────►│
  │◄── Response ────────│
  ├── Request ──────────►│  ← Same connection (persistent)
  │◄── Response ────────│
  └───────────────────────┘
```

### HTTP/2 — Multiplexed
```
Client                  Server
  │                       │
  ├── Stream 1 ─────────►│
  ├── Stream 2 ─────────►│  ← Same connection, interleaved
  ├── Stream 3 ─────────►│
  │◄── Response 2 ──────│
  │◄── Response 1 ──────│
  │◄── Response 3 ──────│
  └───────────────────────┘
```

## Advantages
- Universal, widely supported
- Simple text-based protocol
- Stateless (scales well horizontally)
- Extensible (headers, methods, status codes)

## Disadvantages
- Text-based overhead (larger than binary protocols)
- No built-in encryption (HTTPS adds TLS)
- Head-of-line blocking (HTTP/1.1)
- Statelessness requires external session management

## Related Topics
- [HTTPS/TLS](../02-Networking/05-https-tls.md) — HTTP over TLS encryption
- [REST](../02-Networking/06-rest.md) — RESTful API design over HTTP
- [GraphQL](../02-Networking/07-graphql.md) — Alternative query language
- [gRPC](../02-Networking/08-grpc.md) — High-performance RPC with HTTP/2
- [HTTP/2](../02-Networking/12-http2.md) — Multiplexing, server push
- [HTTP/3](../02-Networking/13-http3.md) — QUIC, 0-RTT, UDP-based

## Interview Questions
1. What's the difference between PUT and PATCH?
2. How does HTTP keep-alive work?
3. What is HTTP pipelining and why was it problematic?
4. Explain the difference between 401 and 403 status codes
5. How does HTTP handle caching?
