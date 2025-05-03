# Summary

### [Payments API (SLA)](#option01)
- #### **Service Level Objectives** [here](slo.md#option01)

### [User Authentication (SLA)](#option02)
- #### **Service Level Objectives** [here](slo.md#option02)

### [Admin Dashboard (SLA)](#option03)
- #### Overview
- #### Admin Dashboard Service
- #### SLA Metrics
- #### SLO: Availability Details
- #### SLO: Latency Details
- #### Incident Response
- #### Support and Maintenance
- #### Penalties
- #### Review of this document
- #### Contact and Escalation
- #### Useful Links

---

## [Payments API (SLA)](#option01)
- **Service Name:** Payments API
- **Customer:** Internal Finance Team
- **Availability Target:** 99.95%
- **Support Hours:** 24x7
- **Penalties for Breach:** Performance credits in next billing cycle

### **Service Level Objectives** [here](slo.md#option01)

---

## [User Authentication (SLA)](#option02)
- **Service Name:** User Authentication
- **Customer:** All applications
- **Availability Target:** 99.9%
- **Support Hours:** Business hours
- **Penalties for Breach:** Incident escalation and RCA within 48h

### **Service Level Objectives** [here](slo.md#option02)

---

## [Admin Dashboard (SLA)](#option03)

### Overview

This Service Level Agreement (SLA) defines the commitments, responsibilities, and expectations between the **Platform Operations Team** and stakeholders regarding the **Admin Dashboard** service. This service is used by internal administrators to manage core configurations, monitor system health, and trigger operational workflows. Given its critical role in system governance and incident resolution, strict service guarantees are essential.

### Admin Dashboard Service

- **Service Name:** Admin Dashboard  
- **Environment:** Production  
- **Primary Users:** Internal administrators, SREs, DevOps, Engineering leads  
- **Access Pattern:** Web interface + REST/gRPC APIs  
- **Dependencies:** Authentication Service, Audit Log Service, Configuration Service


### SLA Metrics

| Metric        | Target Value           | Measurement Window | Error Budget |
|---------------|------------------------|--------------------|--------------|
| **Availability** | ≥ 99.95% uptime        | Monthly (30 days)  | ≤ 21.6 min   |
| **Latency (P95)** | ≤ 500ms per request    | Monthly (30 days)  | ≤ 5% of total requests |
| **Incident Response Time** | ≤ 15 minutes (P1) | Per incident        | N/A          |
| **Time to Resolution (TTR)** | ≤ 4 hours (P1), ≤ 1 business day (P2) | Per incident | N/A          |

---

### SLO: Availability Details

**Definition:**  
Availability is defined as the successful responsiveness of the Admin Dashboard’s `/admin`, `/config`, and `/audit` endpoints returning HTTP 200/2xx codes and the web UI being fully functional.

**Monitoring Tools:**  
- Uptime checks: Pingdom, Prometheus Blackbox Exporter  
- Application health probes (Kubernetes readiness and liveness)  
- Synthetic transactions via Selenium or Puppeteer

**Exclusions:**  
- Scheduled maintenance windows (with 48h notice)
- Force majeure events (e.g., regional outages, natural disasters)
- Failures due to upstream third-party services (e.g., identity provider)


### SLO: Latency Details

**Definition:**  
The 95th percentile of response times must be ≤ 500ms for the following:

- Dashboard UI initial load  
- REST API endpoints: `/admin`, `/config`, `/audit`  
- Backend operations triggered from the UI (e.g., saving configuration)

**Measurement Tools:**  
- Prometheus histograms with OpenTelemetry instrumentation  
- Browser Real User Monitoring (RUM) via Web Vitals  
- Distributed tracing (Jaeger, Datadog APM)


### Incident Response

| Priority | Description                              | Initial Response Time | Time to Resolution |
|----------|------------------------------------------|------------------------|--------------------|
| P1       | Total service outage, data loss, critical path broken | ≤ 15 minutes           | ≤ 4 hours          |
| P2       | Partial outage or degraded performance    | ≤ 30 minutes           | ≤ 1 business day   |
| P3       | Minor issue with workaround               | ≤ 1 business day       | Best effort        |

**Escalation Path:**

1. On-call SRE (PagerDuty or Opsgenie)
2. SRE Team Lead
3. Engineering Manager
4. Head of Platform

### Support and Maintenance

**Support Hours:**  
- Monday to Friday, 08:00 – 18:00 UTC  
- 24/7 On-call rotation for P1/P2 incidents

**Maintenance Windows:**  
- Sundays, 02:00 – 04:00 UTC  
- Announced 48 hours in advance unless emergency patches are required

### Penalties

While this SLA sets internal standards rather than external contractual obligations, failure to meet these standards will trigger the following reviews:

- **Postmortem RCA** for every P1 incident
- **Monthly SLO compliance review**
- **Quarterly SLA breach trend report**
- **Executive escalation** if SLA compliance drops below 99% for two consecutive months

### Review of this document

This SLA will be reviewed **quarterly** or upon significant architectural/service changes. Change requests must be submitted via RFC and approved by the SRE team and product stakeholders.

- **Version:** 1.0  
- **Last Reviewed:** 2025-05-03  
- **Next Review:** 2025-08-01  
- **Owner:** Alexandre Mulatinho

### Contact and Escalation

| Role               | Contact                |
|--------------------|------------------------|
| On-Call Engineer   | `oncall@company.link`  |
| SRE Team Lead      | `sre-lead@company.link`|
| Engineering Manager| `eng-manager@company.link`|
| Incident Hotline   | `+1-800-123-4567`      |

### Useful Links

- [SLO Definitions](./slo.md)  
- [Monitoring Dashboards (Grafana)](https://grafana.company.com/d/admin-dashboard)  
- [Runbooks and Playbooks](runbooks/admin-dashboard.md)  
- [Incident Retrospectives](postmortem.md)