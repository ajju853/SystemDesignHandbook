# OpenID Connect

## Definition
OpenID Connect (OIDC) is an identity layer on top of OAuth 2.0 that allows clients to verify user identity. OAuth 2.0 provides authorization; OIDC adds authentication.

## Key Addition: ID Token

JWT containing user identity claims:

```json
{
  "iss": "https://accounts.google.com",
  "sub": "110169484474386276334",
  "aud": "client-id-123",
  "exp": 1311281970,
  "iat": 1311280970,
  "email": "alice@example.com",
  "email_verified": true,
  "name": "Alice Johnson"
}
```

## OAuth 2.0 vs OIDC

| Aspect | OAuth 2.0 | OIDC |
|--------|-----------|------|
| Purpose | Authorization | Authentication |
| Token | Access Token | ID Token (+ Access Token) |
| Protocol | Framework | Protocol on OAuth 2.0 |
| User info | Not standardized | Standard /userinfo endpoint |
| Scope | api:read, api:write | openid, profile, email |

## Interview Questions
1. How does OpenID Connect extend OAuth 2.0?
2. What information does an ID token contain?
3. How would you implement SSO using OIDC?
4. Compare OIDC with SAML for enterprise SSO
5. How does OIDC /userinfo endpoint work?
