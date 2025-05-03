# Identity Platform Refactor
- **Project Name:** Identity Refactor 2025
- **Sponsor:** CTO
- **Project Manager:** @mulatinho
- **Start Date:** 2025-05-01
- **Target Completion Date:** 2025-08-30
- **Budget:** $15,000

## Goals
- Improve scalability of user identity microservices
- Refactor legacy auth flows
- Migrate to centralized OAuth2-based architecture

## Scope
- In scope: Identity microservices, DB schema updates, SSO migration
- Out of scope: Payment integrations, frontend apps

## Milestones
| Date | Milestone |
|------|-----------|
| 2025-05-15 | Architecture design completed |
| 2025-06-15 | Refactor begins |
| 2025-08-15 | UAT and performance testing |
| 2025-08-30 | Production deployment |

## Risks
- Integration failure with legacy partners
- Delays in DB schema migration
- Team availability during vacation period

## Communication Plan
- Weekly sync: Tuesdays 10am PT
- Slack channel: #project-identity
- Status dashboard: Confluence [link](https://confluence.local/project)

## Success Criteria
- < 1s login latency in 99% of cases
- Zero downtime during cutover
- 100% test coverage for new services


---
---
---

# Project: Admin Dashboard Service

## Overview

The Admin Dashboard is a critical internal service used by administrators, SREs, and platform engineers to manage configurations, monitor system health, and trigger operational actions. It serves as the primary interface for control-plane visibility and observability.

## Goals

- Provide a centralized dashboard for administrative and operational tasks
- Execute privileged actions with traceability and auditability
- Display real-time metrics, logs, and platform configuration states
- Integrate with internal authentication, authorization, and configuration services

## Architecture

### Components

| Component         | Description                                           |
|------------------|-------------------------------------------------------|
| Frontend (React) | Web UI for navigating system states and actions       |
| Backend API (Go) | REST/gRPC service handling business and logic layers  |
| Auth Proxy       | Handles user identity and session validation via OIDC |
| Audit Logger     | Records all privileged operations for compliance      |
| Config Manager   | Interfaces with configuration services and caches     |

### Deployment Model

- Deployed to Kubernetes under the `internal-services` namespace
- Access restricted via internal load balancer
- Public access is denied; only reachable via SSO and internal network
- Container images published via GitHub Actions to internal registry

### External Dependencies

| Service            | Purpose                                    |
|--------------------|--------------------------------------------|
| OIDC Provider      | Authentication via corporate SSO           |
| Vault              | Secrets storage and retrieval              |
| Redis              | In-memory caching of UI widgets            |
| Audit Log System   | Centralized logging of user interactions   |
| Config Service     | Storage and retrieval of platform configs  |

## Deployment

### Repositories

- Frontend: `github.com/livredigital.com/admin-dashboard-ui`
- Backend: `github.com/livredigital.com/admin-dashboard-api`

### CI/CD

- GitHub Actions for test, build, and release workflows
- ArgoCD for continuous delivery
- Deployment manifests live in `infra/deployments/internal/admin-dashboard/`

### Environments

| Environment | URL                          | Deployment Strategy      |
|-------------|-------------------------------|---------------------------|
| Dev         | admin.dev.not-found.internal  | Auto-deploy on commit     |
| Staging     | admin.staging.not-found.internal | Manual approval gates |
| Production  | admin.not-found.internal      | Progressive rollout via ArgoCD |

## Observability

### Metrics

Exposed via `/metrics` endpoint (Prometheus format)

- `http_requests_total`
- `http_request_duration_seconds`
- `admin_action_errors_total`
- `dashboard_latency_seconds`

### Logging

- Structured logs in JSON format
- Routed to Loki and retained for 30 days
- Trace IDs included via OpenTelemetry instrumentation

### Dashboards

- Grafana panels for latency, errors, and audit activity
- Linked to alert rules in Alertmanager

### Tracing

- Backend and UI integrated with OpenTelemetry
- Exported to Jaeger with full span context for each request

## SLOs and SLA

| Metric        | Target Value                  | Measurement Source |
|---------------|-------------------------------|--------------------|
| Availability  | 99.95% over trailing 30 days  | Synthetic checks   |
| Latency       | 95% of requests < 500ms       | Prometheus         |
| Error Rate    | < 1% of requests (5xx codes)  | Prometheus         |

See [slo.md](./slo.md) and [sla.md](./sla.md) for full specifications.

## Security

- Auth: OIDC-based login via internal IdP
- Access Control: RBAC implemented for all backend endpoints
- Data: All actions logged with actor, timestamp, and parameters
- Secrets: Pulled from Vault, injected via Kubernetes secrets
- TLS: End-to-end encryption enforced internally via mTLS

## Operational Playbooks

| Situation                 | Document                                |
|---------------------------|-----------------------------------------|
| Dashboard unreachable     | runbooks/unavailable.md                 |
| Auth system degradation   | runbooks/auth-issues.md                 |
| Configuration rollback    | runbooks/config-revert.md               |
| API error rate spike      | runbooks/error-burst.md                 |

## Maintenance and Lifecycle

- Weekly: Dependency updates and basic UI sanity checks
- Monthly: SLA compliance review
- Quarterly: Chaos experiments and disaster recovery validation
- Version policy: Semantic versioning; minor versions biweekly

## Known Issues

- Audit log load time is high under large result sets
- Occasional UI refresh failure when Redis is unavailable

## Contact

| Role              | Email                         |
|-------------------|-------------------------------|
| Product Owner     | po@not-found.internal         |
| Tech Lead         | techlead@not-found.internal   |
| On-call SRE       | sre@not-found.internal        |
| Security Contact  | secops@not-found.internal     |

## Useful Links

- [SLO Definition](./slo.md)
- [SLA Agreement](./sla.md)
- [Architecture Diagram](../diagrams/admin-dashboard.png)
- [OpenAPI Spec](../api/admin-dashboard.yaml)
- [UX Design Guidelines](../design/ux-guidelines.md)
