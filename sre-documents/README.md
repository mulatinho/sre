# SRE Technical Documents

In Site Reliability Engineering (SRE) and IT Project Management, certain technical documents are consistently used to ensure clarity, accountability, and alignment across teams. Here's a breakdown of the most commonly used ones in each domain:

---

## Service Level Agreement
Commitments made to customers.

- [SLA for Payments API](sla.md#option01)
- [SLA for User Authentication](sla.md#option02)

## Service Level Operation with SLIs
Internal reliability targets with metrics that measure what we need.

- [SLO for Payments API Service](slo.md#option01)
- - [SLIs for the first round of Payments API](slo.md#indicator01)
- - [SLIs for the second round of Payments API](slo.md#indicator02)
- [SLO for User Authentication Service](slo.md#option01)
- - [SLIs for the first round of User Authentication](slo.md#indicator02)
- - [SLIs for the second round of User Authentication](slo.md#indicator02)

---

## Runbook/Playbook Template

- [Payments API - Restart Procedure](runbook.md#option01)

---

## PostMortem Template
- [Payment API HTTP 50X Errors](postmortem.md#option01)

---

## Monitoring/Alert Specification

- [Payments API](alerting_spec.md#option01)