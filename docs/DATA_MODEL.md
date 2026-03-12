# CrewOps Data Model

CrewOps `v0.6.0` ships an M7 seed that keeps the original operations graph, retains the M5 and M6 finance and commercial layers, and adds tenant, portal, inventory, procurement, connector, and readiness entities. The canonical source is [`tests/fixtures/demo_org.json`](../tests/fixtures/demo_org.json), mirrored into deterministic backend payloads under [`backend/src/demo_seed.x07.json`](../backend/src/demo_seed.x07.json).

## Seed Scope

Core operations:

- `1` organization
- `2` branches
- `3` teams
- `13` users across technician, dispatcher, supervisor, manager, portal, and enterprise-admin roles
- `20` customers
- `30` sites
- `60` assets
- `25` work orders
- `25` visits
- `25` assignments

Finance and commercial:

- price books, rate policies, billing policies, tax rules, discount rules
- invoices, invoice lines, invoice adjustments, service summary artifacts
- payment records, payment allocations, customer statements, receivable summaries
- export jobs, finance rollups, profitability snapshots
- estimates, estimate versions, estimate approvals, proposal artifacts
- service agreements, agreement lines, recurring plans, recurrence rules, generated schedule items, renewal records, contract-health snapshots
- integration endpoints, API keys, webhook subscriptions, webhook deliveries, connector mappings, import or sync jobs

M7 enterprise and hosted:

- tenants, workspaces, role definitions, permission grants
- branding packs, theme overrides
- portal accounts, portal sessions, customer timeline events, service requests
- inventory items, stock locations, vehicle stock, stock movements, cycle counts
- vendors, vendor catalog items, purchase orders, purchase order lines, receiving records, reorder suggestions
- connector instances, connector sync jobs, connector delivery records
- tenant health snapshots, portal adoption rollups

## Top-Level Entity Families

The generated fixture includes normalized families for:

- organization, branches, teams, users
- customers, sites, assets
- work_orders, visits, templates, parts_catalog
- assignments, schedule_windows
- review_queue_items, review_decisions, correction_tasks, correction_responses
- activity_events, alerts, dispatch_filters, sla_policies
- branch_summaries, team_summaries, dashboard_rollups, workload_snapshots
- price_books, price_book_items, labor_rate_policies, part_rate_policies, billing_policies
- tax_rules, discount_rules
- invoices, invoice_lines, invoice_adjustments, invoice_artifacts, service_summary_artifacts
- payment_records, payment_allocations
- customer_statements, receivable_summaries
- export_jobs, finance_rollups, profitability_snapshots
- estimates, estimate_versions, estimate_approvals, proposal_artifacts
- service_agreements, agreement_lines
- recurring_plans, recurrence_rules, generated_schedule_items
- renewal_records, contract_health_snapshots
- integration_endpoints, api_key_records, webhook_subscriptions, webhook_deliveries
- connector_mappings, import_or_sync_jobs, recurring_revenue_rollups
- tenants, workspaces, role_definitions, permission_grants, branding_packs, theme_overrides
- portal_accounts, portal_sessions, customer_timeline_events, service_requests
- inventory_items, stock_locations, vehicle_stock, stock_movements, cycle_counts
- vendors, vendor_catalog_items, purchase_orders, purchase_order_lines, receiving_records, reorder_suggestions
- connector_instances, connector_sync_jobs, connector_delivery_records
- tenant_health_snapshots, portal_adoption_rollups
- indexes, summary

## Indexes And Summary

The reducer reads normalized entities through precomputed indexes. M7 adds:

- `workspaces_by_tenant`
- `portal_accounts_by_tenant`
- `portal_accounts_by_status`
- `service_requests_by_tenant`
- `service_requests_by_status`
- `inventory_items_by_tenant`
- `inventory_items_by_status`
- `inventory_items_by_location`
- `stock_locations_by_tenant`
- `stock_movements_by_location`
- `stock_movements_by_status`
- `vendors_by_tenant`
- `purchase_orders_by_tenant`
- `purchase_orders_by_status`
- `purchase_orders_by_vendor`
- `receiving_records_by_purchase_order`
- `reorder_suggestions_by_location`
- `connector_instances_by_tenant`
- `connector_instances_by_status`
- `connector_instances_by_provider`
- `connector_sync_jobs_by_status`
- `connector_sync_jobs_by_provider`

The summary document now carries:

- tenant health rollups
- portal adoption rollups
- inventory low-stock and cycle-count summaries
- procurement backlog and receiving mismatch summaries
- connector health and failed-sync summaries

## Draft And Sync State

User-editable M7 inputs live under `drafts.enterprise_ops`, including tenant selection, branding colors, portal request details, inventory adjustments, receiving quantities, and connector retry selections.

Replay-safe enterprise conflict state lives under `sync.enterprise_ops`, including:

- `portal_approval_status`
- `tenant_revision_status`
- `inventory_movement_status`
- `receiving_status`
- `connector_config_status`
- stale ids for portal requests, tenants, stock locations, purchase orders, and connector instances
