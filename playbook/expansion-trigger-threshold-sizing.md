---
axis: expansion-trigger-threshold-sizing
rule_count_floor: 8
---

# Expansion-trigger threshold sizing (growth_rate x lead_time x safety_buffer)

Research trail: Little's Law (L = λW; Little 1961), Dan Slimmon's applied Little's-Law capacity-scaling writeup (worker-thread occupancy example), production-system utilization-threshold findings (Project Production Institute), and percentile-occupancy planning practice. All fetched/searched this session.

## Rules

1. When sizing how many additional units of a resource (servers, worker threads, connections, shards) an expansion needs to add, compute required occupancy as arrival_rate x average_wait_time per Little's Law (L = λW) first, then size the expansion against that computed occupancy — not against a flat headcount guess — because L = λW gives the exact long-run average in-flight count the resource must sustain. source: https://blog.danslimmon.com/2022/06/07/using-littles-law-to-scale-applications/

2. When the expansion-trigger threshold is being stated, express it as growth_rate x lead_time x safety_buffer with each term labeled and traceable to a source number, not as a bare flat percentage (e.g. "expand at 80%") — a bare percentage hides which of the three terms is driving the trigger and cannot be re-derived when any one input changes. source: https://blog.danslimmon.com/2022/06/07/using-littles-law-to-scale-applications/

3. When computing L = λW for a trigger threshold, never use the mean/average λ and W alone to size the buffer — Little's Law gives only the long-term average, and the same source that derives it explicitly warns "from moment to moment, the occupancy of the system will vary around this average," so the threshold must be sized off a stated percentile (e.g. p95/p97.5/p99) of the occupancy distribution, not the mean. source: https://blog.danslimmon.com/2022/06/07/using-littles-law-to-scale-applications/

4. When a system's utilization approaches roughly 80-85% under queueing dynamics, treat that band as the practical trigger zone for expansion rather than waiting for visible saturation — production-system analysis using Little's Law found cycle-time explosion (queue buildup) becomes very likely once utilization crosses that band, because a system with no spare capacity margin turns any minor delay into a compounding queue. source: https://projectproduction.org/journal/littles-law-a-practical-approach-to-understanding-production-system-performance/

5. When sizing the lead_time term of the threshold formula, use the full time from "trigger fires" to "new capacity is actually serving traffic" (procurement/provisioning/warm-up, not just the order-placement step) — a threshold that only accounts for order lead time and ignores provisioning/warm-up time fires too late, because unserved demand accrues for the entire gap, not just the ordering portion of it. source: https://sre.google/static/pdf/login_winter20_10_torres.pdf

6. When the growth_rate term is derived from a forecast that mixes organic and inorganic demand, use the combined (summed) forecast from the demand-shape axis's rule 7 as the growth_rate input, not the organic component alone — a threshold sized only off organic growth under-triggers whenever a scheduled inorganic event lands inside the lead-time window, since the event's step change is real unserved demand the trigger must account for.

7. When the safety_buffer term is being chosen, size it from the same variability-and-service-level logic used for physical-inventory safety stock — buffer scales with demand variability, lead-time variability, and the required service level, and going from a 90% to a 99% service level can "nearly double" the needed buffer rather than scaling linearly — so treat safety_buffer as a function of the target percentile, not a flat constant reused across all resources. source: https://www.workingcapitalhub.com/inventory/safety-stock-explained/

8. When stating the threshold's target percentile, pick it based on the resource's failure consequence, not a single house-wide default — a resource whose exhaustion silently degrades (e.g. background batch capacity) can be sized to a lower percentile (e.g. p90) than one whose exhaustion is user-visible and hard to reverse quickly (e.g. request-serving capacity), which should be sized to a higher percentile (p97.5-p99) per the same service-level-drives-buffer-size logic. source: https://www.workingcapitalhub.com/inventory/safety-stock-explained/

9. **REMOVAL**: When a prior threshold was set as a bare percentage with no recorded growth_rate/lead_time/safety_buffer decomposition, do not carry that bare number forward unchanged into a new capacity record — drop the undecomposed figure and recompute all three terms explicitly, because an unlabeled inherited number cannot be checked for staleness (a lead time that has since shortened, or a growth rate that has since changed) and silently perpetuates whatever assumptions produced it originally. source: https://blog.danslimmon.com/2022/06/07/using-littles-law-to-scale-applications/

10. **REMOVAL**: When the average-latency/average-occupancy figures alone are already in hand and look adequate for a trigger decision, do not stop there and skip the percentile step — drop the practice of using the mean as a stand-in for tail behavior; the source deriving L = λW itself flags this as insufficient because moment-to-moment variance around the mean is exactly what a trigger threshold must be safe against, not the average case. source: https://blog.danslimmon.com/2022/06/07/using-littles-law-to-scale-applications/
