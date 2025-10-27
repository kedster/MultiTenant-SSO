# GitHub Copilot Instructions for MultiTenant-SSO

## Project Overview
This is a multi-tenant SSO (Single Sign-On) authentication system built for Cloudflare Workers. The project aims to create an OpenAuth server that can handle OAuth2/OIDC authentication for multiple organizations and internal applications.

## Technology Stack
- **Primary Language**: TypeScript
- **Runtime**: Cloudflare Workers
- **Database**: Cloudflare D1 (PostgreSQL-compatible)
- **Storage**: Cloudflare KV Store
- **Frontend**: React/TypeScript (for admin portal)

## Code Style Guidelines
- Use TypeScript for all new code
- Follow functional programming patterns where appropriate
- Use async/await for asynchronous operations
- Prefer const over let, avoid var
- Use descriptive variable and function names
- Add JSDoc comments for public APIs
- Follow the existing code structure and patterns

## Security Best Practices
- Never commit secrets or API keys
- Always validate and sanitize user input
- Use parameterized queries for database operations
- Implement proper error handling without exposing sensitive information
- Follow OAuth2/OIDC security best practices
- Implement rate limiting for authentication endpoints
- Use short-lived access tokens with refresh tokens

## Architecture Guidelines
- Keep multi-tenant logic isolated and well-tested
- Ensure tenant data is properly isolated
- Use middleware pattern for authentication/authorization
- Keep Workers functions lean and efficient
- Implement proper logging and monitoring
- Follow serverless best practices

## Testing Guidelines
- Write unit tests for business logic
- Write integration tests for API endpoints
- Mock external dependencies in tests
- Aim for high test coverage on critical paths
- Test multi-tenant scenarios thoroughly

## Documentation
- Update README.md for significant changes
- Document complex algorithms or business logic
- Keep API documentation up to date
- Document configuration options and environment variables

## Contribution Process
1. Create feature branches from main
2. Follow the pull request template
3. Ensure all tests pass
4. Get code review approval before merging
5. Squash commits when merging to main
