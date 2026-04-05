# CrewOps Vendor Connectors

CrewOps adds tenant-scoped vendor connector health and delivery visibility on top of the existing integrations surface. `integration_dashboard` complements `integrations`; it does not replace the original API key and webhook controls.

## Routes And Data

- route: `integration_dashboard`
- backend calls: `GET /api/connectors/vendor`, `POST /api/connectors/vendor`, `POST /api/connectors/vendor/:id/sync`, `GET /api/connectors/vendor/:id/deliveries`

## Seeded Coverage

The seed includes:

- connector instances by provider and tenant
- connector sync jobs
- connector delivery records
- provider classes for accounting, payments, CRM, and ticketing
- connector health summary metrics inside `summary.connector_health_summary`

## Sync State

Connector replay state uses:

- `sync.enterprise_ops.connector_config_status`
- `sync.enterprise_ops.stale_connector_instance_id`
- `sync.commercial_ops.delivery_retry_status`
- `sync.commercial_ops.stale_delivery_id`
