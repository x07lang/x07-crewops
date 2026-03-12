# CrewOps Portal

The M7 portal surface is the external customer entry point inside the same deterministic app and seed-backed backend.

## Routes And Data

- route: `portal`
- primary backend calls: `POST /api/portal/session`, `GET /api/portal/me`, `GET /api/portal/invoices`, `GET /api/portal/service-history`, `POST /api/portal/requests`, `POST /api/portal/requests/:id/convert`
- default role mapping: `portal_user -> portal`

## Seeded Coverage

The seed includes:

- portal accounts and sessions
- customer timeline events
- invoice and service-history views for the seeded account
- service requests with status and conversion state
- adoption summary metrics inside `summary.portal_adoption_summary`

Estimate approval remains part of the shared commercial workflow. The portal route reads the seeded customer snapshot while approval replay is carried through the same estimate entities and `sync.enterprise_ops.portal_approval_status`.

## Sync And Conflict State

Portal-specific replay state lives under `sync.enterprise_ops`:

- `portal_approval_status`
- `stale_portal_request_id`

These fields let the reducer render approval success, stale approval, and request handoff state without introducing nondeterministic network behavior.
