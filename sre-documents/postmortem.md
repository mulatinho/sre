# Incident Postmortem: Auth Service Latency Spike
- **Date & Time:** 2025-02-27 07:45 UTC
- **Duration:** 20 minutes
- **Impact:** Login latency > 3s for all users
- **Severity Level:** SEV-2
- **Author:** Alexandre Mulatinho 

## Summary
Upstream rate limit triggered due to spike from 3rd-party integration.

## Timeline
| Time | Event |
|------|-------|
| 07:45 | Alert triggered |
| 07:48 | Verified 3rd-party request surge |
| 08:02 | Traffic blocked using WAF |
| 08:05 | Latency normalized |

## Root Cause
Unthrottled external traffic overload

## Resolution
Block offending IP range

## Contributing Factors
- Missing rate limits for partner integration

## Action Items
- [ ] Implement traffic shaping
- [ ] Notify integration team

## Lessons Learned
Partner traffic should be limited and observable

## Preventive Measures
- Add circuit breakers for external dependencies