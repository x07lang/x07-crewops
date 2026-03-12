# CrewOps Enterprise Admin

The M7 enterprise admin surface keeps tenant administration, branding, and rollout health inside CrewOps rather than a separate control plane.

## Routes And Data

- route: `enterprise`
- primary backend calls: `GET /api/admin/tenants`, `POST /api/admin/tenants`, `PATCH /api/admin/tenants/:id`, `GET /api/admin/roles`, `POST /api/admin/roles`, `POST /api/admin/branding`
- default role mapping: `enterprise_admin -> enterprise`

## Seeded Coverage

The seed includes:

- tenants and workspaces
- role definitions and permission grants
- branding packs and theme overrides
- tenant health snapshots and portal adoption rollups

The route is the drill-down surface for the seeded tenant health and readiness summary that also appears on `manager` and `integration_dashboard`.

## Sync State

Enterprise replay state lives under `sync.enterprise_ops`:

- `tenant_revision_status`
- `stale_tenant_id`

These fields carry revision-aware tenant edits and branding updates through deterministic replay. The same subtree also carries downstream stock, receiving, connector, and portal approval state so tenant configuration stays tied to the rest of the app.
