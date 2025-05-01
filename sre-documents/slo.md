# [Payments API](#option01)

## Service Level Objectives (SLOs)
- **Availability:** 99.95%
- **Latency (p99):** < 250ms
- **Error Rate:** < 0.05%

## [Service Level Indicators (SLIs) 1st Iterator](#indicator01)
| Metric | Description | Source |
|--------|-------------|--------|
| availability | Ratio of successful requests | Prometheus |
| latency_p99 | 99th percentile response time | Prometheus |
| error_rate | Error responses / total | Prometheus |

## [Service Level Indicators (SLIs) 2nd Iterator](#indicator02)
| Metric | Description | Source |
|--------|-------------|--------|
| availability | Ratio of successful requests | Prometheus |
| latency_p99 | 99th percentile response time | Prometheus |
| error_rate | Error responses / total | Prometheus |

---

# [User Authentication](#option02)
## Service Level Objectives (SLOs)
- **Availability:** 99.9%
- **Latency (p95):** < 500ms
- **Error Rate:** < 1%

## [Service Level Indicators (SLIs) 1st Iterator](#option03)
| Metric | Description | Source |
|--------|-------------|--------|
| availability | Auth token issuance success | Prometheus |
| latency_p95 | 95th percentile of auth latency | Prometheus |
| error_rate | Auth failures / total | Prometheus |

## [Service Level Indicators (SLIs) 2nd Iterator](#option04)
| Metric | Description | Source |
|--------|-------------|--------|
| availability | Auth token issuance success | Prometheus |
| latency_p95 | 95th percentile of auth latency | Prometheus |
| error_rate | Auth failures / total | Prometheus |