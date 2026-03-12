# CrewOps Hosted Readiness

M7 adds a deterministic hosted-readiness surface so release state and tenant rollout completeness can be replayed locally.

## Backend Surface

- route source: `GET /api/release/readiness`
- handler: [`backend/src/hosted_readiness.x07.json`](../backend/src/hosted_readiness.x07.json)
- seed source: [`backend/src/demo_seed.x07.json`](../backend/src/demo_seed.x07.json)

## Seeded Coverage

The readiness payload summarizes:

- tenant readiness state
- connector backlog and failure counts
- low-stock and procurement backlog counts
- rollout completeness for branded and portal-enabled tenants

The same seeded rollout signals also appear in `summary.tenant_health_overview`, `summary.portal_adoption_summary`, `summary.inventory_summary`, `summary.procurement_summary`, and `summary.connector_health_summary`, so manager and enterprise drill-downs stay aligned.

The gate replays this state through the same seed-backed app bundle used for local web and device packaging.
