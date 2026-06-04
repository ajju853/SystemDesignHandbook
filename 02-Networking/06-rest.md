# REST (Representational State Transfer)

## Definition
REST is an architectural style for designing networked applications. It uses HTTP methods to perform CRUD operations on resources identified by URLs, with representations (JSON/XML) returned in responses.

## Real-World Example
**Twitter API**: Resources like tweets, users, timelines are exposed as RESTful endpoints. `GET /users/{id}` returns a user, `POST /tweets` creates a tweet, `DELETE /tweets/{id}` deletes one.

## REST Design Principles

### 1. Resources are Nouns, Not Verbs
```
✅ GET /users          (get all users)
✅ GET /users/123      (get user 123)
✅ POST /users         (create user)
✅ PUT /users/123      (update user 123)
✅ DELETE /users/123   (delete user 123)

❌ GET /getUsers
❌ POST /createUser
❌ GET /deleteUser?id=123
```

### 2. HTTP Methods Map to CRUD

| Action | HTTP Method | Endpoint | Status Code |
|--------|-------------|----------|-------------|
| Create | POST | /users | 201 Created |
| Read | GET | /users/{id} | 200 OK |
| Update (full) | PUT | /users/{id} | 200 OK |
| Update (partial) | PATCH | /users/{id} | 200 OK |
| Delete | DELETE | /users/{id} | 204 No Content |
| List | GET | /users | 200 OK |

### 3. Stateless
- Each request contains all necessary information
- No server-side session state
- Scales horizontally easily

### 4. Consistent URL Patterns
```
/users              → Collection
/users/{id}         → Single resource
/users/{id}/tweets  → Sub-resource collection
/users/{id}/tweets/{tweetId} → Single sub-resource
```

### 5. Use HTTP Status Codes
```
200 OK              → Success
201 Created         → Resource created
204 No Content      → Success, no body
400 Bad Request     → Client error
401 Unauthorized    → Not authenticated
403 Forbidden       → Not authorized
404 Not Found       → Resource missing
409 Conflict        → Version conflict
422 Unprocessable   → Validation error
429 Too Many Reqs   → Rate limited
500 Internal Error  → Server error
```

## RESTful API Example

```
Request:
  GET /api/v2/users/42 HTTP/1.1
  Host: api.twitter.com
  Authorization: Bearer token123
  Accept: application/json

Response:
  HTTP/1.1 200 OK
  Content-Type: application/json
  
  {
    "id": 42,
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "created_at": "2023-01-15T10:30:00Z",
    "_links": {
      "self": { "href": "/api/v2/users/42" },
      "tweets": { "href": "/api/v2/users/42/tweets" }
    }
  }
```

## REST vs GraphQL vs gRPC

| Feature | REST | GraphQL | gRPC |
|---------|------|---------|------|
| Protocol | HTTP/1.1+ | HTTP | HTTP/2 |
| Data format | JSON/XML | JSON | Protobuf (binary) |
| Schema | OpenAPI (optional) | Schema-first | Proto files |
| Over-fetching | Common | Rare | Rare |
| Under-fetching | Common | Rare | Rare |
| Caching | Easy (HTTP cache) | Complex | Complex |
| Tooling | Mature | Growing | Mature |
| Browser support | Native | Via client lib | Via gRPC-web |

## Pagination, Filtering, Sorting

```
// Pagination
GET /users?page=2&per_page=20
GET /users?cursor=abc123&limit=20   (cursor-based)

// Filtering
GET /users?status=active&role=admin

// Sorting
GET /users?sort=-created_at          (descending)
GET /users?sort=last_name            (ascending)

// Field selection
GET /users?fields=id,name,email      (reduces payload)

// Embedded resources
GET /users/42?include=tweets         (eager loading)
```

## Advantages
- Simple and intuitive
- Excellent caching (HTTP-native)
- Stateless scalability
- Wide tooling support
- Language-agnostic

## Disadvantages
- Over-fetching / under-fetching
- Multiple round trips for complex data
- No strict typing (JSON)
- URL design inconsistencies across teams

## Interview Questions
1. Design a RESTful API for a blogging platform
2. How do you handle versioning in REST APIs?
3. What are HATEOAS and Richardson Maturity Model?
4. How does REST compare to GraphQL for complex queries?
5. How do you implement pagination in a REST API?
