# RBAC (Role-Based Access Control)

## Definition
RBAC is an access control model where permissions are assigned to roles, and users are assigned to roles. Instead of managing permissions per-user, you manage them per-role.

## Core Concepts

```
User ───► Role ───► Permissions
 │           │           │
 │           ├── Admin ──► Read, Write, Delete, Manage Users
 │           ├── Editor ─► Read, Write
 │           └── Viewer ─► Read
 │
 Example:
 User: Alice → Role: Admin → Permissions: {read, write, delete}
 User: Bob → Role: Viewer → Permissions: {read}
```

## RBAC vs ABAC

| Aspect | RBAC | ABAC |
|--------|------|------|
| **Granularity** | Role-level | Attribute-level |
| **Complexity** | Simple, easy to understand | Complex, policy-driven |
| **Maintenance** | Adding a role requires updates everywhere | Add policy without code changes |
| **Context-aware** | No (role is static) | Yes (time, location, device) |
| **Best for** | Most enterprise apps | Multi-tenant, compliance-heavy |
| **Example** | "Admins can delete" | "Admins can delete during business hours from office" |

## Implementing RBAC

```sql
-- Database schema
CREATE TABLE roles (
    id INT PRIMARY KEY,
    name VARCHAR(50) UNIQUE
);

CREATE TABLE permissions (
    id INT PRIMARY KEY,
    resource VARCHAR(100),  -- e.g., "document", "user"
    action VARCHAR(50)      -- e.g., "read", "write", "delete"
);

CREATE TABLE role_permissions (
    role_id INT REFERENCES roles(id),
    permission_id INT REFERENCES permissions(id),
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
    user_id VARCHAR(36),
    role_id INT REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);

-- Check permission
SELECT 1 FROM user_roles ur
JOIN role_permissions rp ON ur.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE ur.user_id = 'alice' AND p.resource = 'document' AND p.action = 'delete';
```

## Interview Questions

1. How does RBAC simplify permission management?
2. What are the limitations of RBAC?
3. How do you implement RBAC in a microservice architecture?
4. When would you choose ABAC over RBAC?
5. Design an RBAC system for a multi-tenant SaaS platform
