# Labs Services

## Secrets

- use KeePassXC
- inject via env variables
- never hardcode

Example:

```yaml
environment:
  PASSWORD: ${SERVICE_PASSWORD}
```
