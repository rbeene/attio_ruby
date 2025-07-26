# Security Policy

## Supported Versions

We release security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| 0.x.x   | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please follow these steps:

1. **DO NOT** create a public GitHub issue for security vulnerabilities
2. Email security@yourdomain.com with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes

## Response Timeline

- **Initial Response**: Within 24 hours
- **Status Update**: Within 72 hours
- **Resolution Target**: 
  - Critical: 24-48 hours
  - High: 1 week
  - Medium: 2 weeks
  - Low: 1 month

## Security Best Practices

When using this gem:

1. **API Keys**: Never commit API keys to version control
2. **Environment Variables**: Use environment variables for sensitive configuration
3. **HTTPS**: All API calls are made over HTTPS
4. **Updates**: Keep the gem updated to receive security patches

## Security Features

This gem includes:

- Webhook signature verification
- Constant-time string comparison for secrets
- No eval() or dynamic code execution
- Input sanitization for all user inputs
- Secure token storage interfaces