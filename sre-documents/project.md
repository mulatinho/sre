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