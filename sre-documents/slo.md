# Summary

### 1. [Light SLO document of a Payments API](#option01)
### 2. [Light SLO document of a User Authentication service](#option02)
### 3. [Detailed SLO document of the Admin Dashboard- Availability](#option03)
### 4. [Detailed SLO document of the Admin Dashboard - Latency](#option04)

---

## [Payments API](#option01)

**Objective:**
Ensure the Payments API basic network requisites

**Service Level Objectives (SLOs)**
- **Availability:** 99.95%
- **Latency (p99):** < 250ms
- **Error Rate:** < 0.05%

[**Service Level Indicators (SLIs)**](#indicator01)
| Metric | Description | Source |
|--------|-------------|--------|
| availability | Ratio of successful requests | Prometheus |
| latency_p99 | 99th percentile response time | Prometheus |
| error_rate | Error responses / total | Prometheus |

**Error Budget:**
Allows for 0.05% unavailability, which is about 21.6 minutes/month.

**Monitoring Strategy:**
- Send metrics to Prometheus and have a Grafana dashboard
- Dashboards showing percentiles (P50, P95, P99) for latency metrics.

---

## [User Authentication](#option02)
**Objective:**
Ensure user authentication through the auth-service

**Service Level Objectives (SLOs)**
- **Availability:** 99.9%
- **Latency (p95):** < 500ms
- **Error Rate:** < 1%

[**Service Level Indicators (SLIs)**](#indicator02)
| Metric | Description | Source |
|--------|-------------|--------|
| availability | Auth token issuance success | Prometheus |
| latency_p95 | 95th percentile of auth latency | Prometheus |
| error_rate | Auth failures / total | Prometheus |

**Error Budget:**
Ensure 99.99% of availability

**Monitoring Strategy:**
- Send metrics to Prometheus and have a Grafana dashboard
- Dashboards showing percentiles (P50, P95, P99) for latency metrics.

---

## [Admin Dashboard - Availability SLO](option#03)

### Service: Admin Dashboard

**Objective:**  
Ensure high availability for administrative users to manage system configurations and monitor operations.

**SLIs (Service Level Indicators):**

1. Percentage of successful HTTP 200 responses on `/admin` endpoint.
2. Uptime percentage measured via synthetic monitoring (e.g., Pingdom).
3. Percentage of successful gRPC health check responses.
4. Success ratio of internal service dependencies (e.g., auth, config APIs).

**SLO (Service Level Objective):**  
Maintain **99.95% availability** over a rolling 30-day window.

**Error Budget:**  
Allows for **0.05%** unavailability, which is about **21.6 minutes/month**.

**Monitoring Strategy:**

- Use uptime monitoring tools (e.g., Pingdom, UptimeRobot).
- gRPC and REST health probes.
- Alerts based on consecutive failed checks.
- Correlate with logs and incidents using tools like Grafana + Loki.

**Rationale:**  
The Admin Dashboard is critical for administrators. High availability ensures uninterrupted system visibility and control.

---

## [Admin Dashboard - Latency SLO](#option04)

### Service: Admin Dashboard

**Objective:**  
Provide a responsive user experience for administrators executing tasks.

**SLIs (Service Level Indicators):**

1. 95th percentile latency of `/admin` endpoint under 500ms.
2. Average response time for dashboard load under 300ms.
3. Latency of dependent API calls (e.g., `/config`, `/audit`) under 250ms.
4. Time to first meaningful paint (TTFMP) in browser < 1s.

**SLO (Service Level Objective):**  
95% of requests should complete within **500 milliseconds**.

**Error Budget:**  
5% of requests may exceed the latency threshold.

**Monitoring Strategy:**

- Use APM tools (e.g., New Relic, Datadog) to monitor response times.
- Track frontend performance with tools like Lighthouse or Web Vitals.
- Dashboards showing percentiles (P50, P95, P99) for latency metrics.
- Instrument backend services with OpenTelemetry.

**Rationale:**  
Admins require a fast interface for operational efficiency. Latency affects productivity and trust in system reliability.