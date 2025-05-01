# Monitoring & Alerting: Auth Service

## Key Metrics
| Metric | Description | Threshold | Tool |
|--------|-------------|-----------|------|
| login_latency | Time to complete login | >750ms | Prometheus |
| login_errors_total | Auth failures | >100 errors in 5m | Prometheus |
| concurrent_sessions | Logged in users | >10K | Prometheus |

## Alert Rules

### Rule #01
- Alert Name: Auth Latency Spike
- Condition: latency > 750ms
- Severity: Warning
- Notification Channel: Slack #alerts-prod

### Rule #02
- Alert Name: Auth Login Erros
- Condition: error_rate > 100 in the range of 5m
- Severity: Error
- Notification Channel: Slack #alerts-prod

## Dashboards
- [Grafana Auth Panel](http://grafana.local/d/auth)

## Escalation Path
- Primary On-call: @sre-auth-tram
- Secondary: @backend-oncall