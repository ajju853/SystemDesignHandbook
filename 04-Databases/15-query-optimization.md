# Query Optimization

## Definition
Query optimization is the process of improving database query performance by analyzing and tuning query execution plans, indexing strategies, and database configuration.

## Real-World Example
**Shopify**: Reduced query time for product search from 2 seconds to 50ms by adding composite indexes, optimizing JOINs, and using covering indexes — directly improving page load times and conversion rates.

## EXPLAIN Plans

```sql
EXPLAIN ANALYZE
SELECT u.name, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.created_at > '2024-01-01'
GROUP BY u.id;

-- Output:
-- Hash Right Join  (cost=124.5..156.7 rows=1200 width=40)
--   Hash Cond: (o.user_id = u.id)
--   ->  Seq Scan on orders o  (cost=0.0..34.2 rows=2340 width=8)
--   ->  Hash  (cost=100.5..100.5 rows=1200 width=36)
--         ->  Seq Scan on users u  
--             (cost=0.0..100.5 rows=1200 width=36)
--             Filter: (created_at > '2024-01-01')
```

## Common Optimization Techniques

### 1. Indexing
```sql
-- Add index for filtered columns
CREATE INDEX idx_users_created_at ON users (created_at);

-- Composite index for queried columns
CREATE INDEX idx_orders_user_date 
    ON orders (user_id, order_date DESC);

-- Covering index (includes all needed columns)
CREATE INDEX idx_orders_lookup 
    ON orders (user_id) INCLUDE (status, amount);
```

### 2. Query Rewriting

```sql
-- ❌ Bad: SELECT * with large table
SELECT * FROM orders WHERE user_id = 123;

-- ✅ Good: Select only needed columns
SELECT id, status, amount, created_at 
FROM orders 
WHERE user_id = 123 
ORDER BY created_at DESC 
LIMIT 10;

-- ❌ Bad: Not using index (function on column)
SELECT * FROM users WHERE LOWER(email) = 'alice@example.com';

-- ✅ Good: Using index (consider expression index)
SELECT * FROM users WHERE email = 'alice@example.com';
```

### 3. JOIN Optimization

```sql
-- Use indexes on JOIN columns
CREATE INDEX idx_users_id ON users (id);
CREATE INDEX idx_orders_user_id ON orders (user_id);

-- Filter before JOIN
SELECT u.name, o.amount
FROM users u
JOIN (
    SELECT * FROM orders 
    WHERE created_at > '2024-01-01'
) o ON u.id = o.user_id
WHERE u.status = 'active';
```

### 4. Avoiding N+1 Queries

```python
# ❌ Bad: N+1 queries
users = db.query("SELECT * FROM users")
for user in users:  # N queries!
    posts = db.query("SELECT * FROM posts WHERE user_id = ?", user.id)

# ✅ Good: Single JOIN
users = db.query("""
    SELECT u.*, p.* 
    FROM users u
    LEFT JOIN posts p ON u.id = p.user_id
    WHERE u.id IN (%s)
""")
```

## Common Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| SELECT * | Returns unnecessary columns | Specify columns |
| Missing WHERE | Full table scan | Add filters |
| No LIMIT | Returns all rows | Add pagination |
| Implicit type conversion | Index not used | Match types |
| OR conditions | May not use index | UNION or IN clause |
| Too many JOINs | Complex execution plan | Denormalize or break query |
| Non-SARGable | LOWER(), LIKE '%...' | Expression indexes |

## Query Optimization Checklist

```
☐ Check EXPLAIN plan — are there sequential scans?
☐ Are all filtered columns indexed?
☐ Are composite indexes in correct order (leftmost prefix)?
☐ Are JOIN columns indexed on both sides?
☐ Is the query returning only necessary columns?
☐ Is the query using appropriate LIMIT/pagination?
☐ Are data types matching between comparisons?
☐ Is the query cache-friendly (repeated queries)?
☐ Are there redundant or unused indexes?
☐ Is the query plan cost reasonable for data volume?
```

## Interview Questions
1. How do you identify and fix a slow query?
2. What's the difference between a sequential scan and an index scan?
3. How does the query optimizer choose which index to use?
4. What is an execution plan and how do you read it?
5. Design a query optimization strategy for a high-traffic e-commerce site
