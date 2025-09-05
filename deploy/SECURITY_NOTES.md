# Security Notes for IAP/IAM Integration

## Overview
This document outlines security considerations for integrating the Flutter web frontend with Google Cloud IAP (Identity-Aware Proxy) and IAM.

## Architecture Security Model

### Trust Boundaries
1. **Public Frontend**: Flutter web app served from Cloud Run (publicly accessible)
2. **Secured Backend**: API services behind Cloud IAP via HTTPS Load Balancer
3. **Identity Layer**: Google Cloud IAP handles authentication/authorization

### Authentication Flow
1. User accesses frontend (public, no authentication required)
2. Frontend makes API calls to `/api/*` endpoints
3. Load Balancer routes `/api/*` to IAP-protected backend
4. IAP validates user identity and injects headers:
   - `X-Goog-Authenticated-User-Email`
   - `X-Goog-Authenticated-User-Id`
   - `X-Goog-IAP-JWT-Assertion`

## Security Guidelines

### Frontend Security
- **No Secrets**: Never embed API keys, tokens, or credentials in frontend code
- **Runtime Config**: Use environment-based configuration injection (not build-time)
- **Same-Origin**: Prefer same-origin `/api/*` calls to avoid CORS complexity
- **CSP Headers**: Add Content Security Policy headers once domain is finalized

### Backend Security
- **IAP Validation**: Always validate IAP JWT assertions in backend services
- **Header Trust**: Trust `X-Goog-Authenticated-User-*` headers only when behind IAP
- **CORS Policy**: Configure CORS appropriately if not using same-origin proxy

### IAP Configuration
- **Least Privilege**: Grant IAP access only to required Google Groups/users
- **Audience Validation**: Backend should validate JWT audience matches expected value
- **Session Management**: IAP handles session cookies; frontend should not manage tokens

## Integration Choices

### Option 1: Same-Origin Proxy (Recommended)
- Configure nginx to proxy `/api/*` → backend URL
- Frontend makes relative API calls
- Simplifies CORS and cookie handling
- All traffic appears to come from same origin

### Option 2: Cross-Origin Calls
- Frontend calls backend URL directly
- Requires proper CORS configuration
- IAP cookies still work for authentication
- More complex error handling

## Environment Variables Impact

### IAP_MODE=true
- Frontend relies on IAP cookie authentication
- No custom Authorization headers required
- Backend validates IAP JWT assertions

### IAP_MODE=false
- For development/testing without IAP
- May require alternative authentication method
- Backend should handle absence of IAP headers gracefully

## Security Checklist

- [ ] IAP is enabled on backend Cloud Run service
- [ ] Load Balancer URL map routes `/api/*` to backend
- [ ] Frontend served with appropriate security headers
- [ ] Backend validates IAP JWT assertions
- [ ] No hardcoded secrets in frontend code
- [ ] Runtime config injection working properly
- [ ] CORS configured if using cross-origin calls
- [ ] Access control configured via Google Groups
- [ ] SSL/TLS certificates properly configured
- [ ] Security headers (CSP, HSTS) added for production domain

## Monitoring and Logging

### Security Events to Monitor
- Failed IAP authentication attempts
- Unauthorized API access attempts
- Invalid JWT assertion validation
- Unusual traffic patterns to `/api/*` endpoints

### Logging Best Practices
- Log authentication events in backend
- Avoid logging sensitive user data
- Use structured logging for security events
- Monitor for suspicious patterns in Cloud Logging

## Common Pitfalls

1. **Token Management**: Don't try to extract/manage IAP tokens in frontend
2. **CORS Confusion**: Use same-origin proxy to avoid CORS issues
3. **Header Spoofing**: Never trust IAP headers outside of IAP-protected services
4. **Cache Issues**: Ensure runtime config is never cached
5. **Development Auth**: Provide clear local development authentication strategy

## References

- [Google Cloud IAP Documentation](https://cloud.google.com/iap/docs)
- [Securing IAP with JWT Verification](https://cloud.google.com/iap/docs/signed-headers-howto)
- [Cloud Run IAP Integration](https://cloud.google.com/run/docs/authenticating/overview)
