# CrewOps Data Model

CrewOps `v0.5.0` ships an M6 seed that keeps the operations graph, retains the M5 finance layer, and adds estimate, contract, recurring-service, renewal, and integration entities. The canonical source is [`tests/fixtures/demo_org.json`](../tests/fixtures/demo_org.json), mirrored into deterministic backend payloads under [`backend/src/demo_seed.x07.json`](../backend/src/demo_seed.x07.json).

## Seed Scope

Core operations:

- `1` organization
- `2` branches
- `3` teams
- `11` users across technician, dispatcher, supervisor, and manager roles
- `20` customers
- `30` sites
- `60` assets
- `25` work orders
- `25` visits
- `25` assignments
- `25` schedule windows
- `3` review queue items
- `1` review decision
- `1` correction task
- `1` correction response
- `25` activity events
- `4` alerts
- `2` branch summaries
- `3` team summaries
- `1` dashboard rollup
- `3` workload snapshots

Commercial M5 and M6:

- `3` price books
- `6` price book items
- `3` billing policies
- `2` labor rate policies
- `6` part rate policies
- `2` tax rules
- `3` discount rules
- `9` invoices
- `36` invoice lines
- `7` invoice adjustments
- `9` invoice artifacts
- `9` service summary artifacts
- `6` customer statements
- `3` payment records
- `3` payment allocations
- `8` receivable summaries
- `3` export jobs
- `6` finance rollups
- `6` profitability snapshots
- `4` estimates
- `6` estimate versions
- `1` estimate approval
- `4` proposal artifacts
- `3` service agreements
- `3` agreement lines
- `3` recurring plans
- `3` recurrence rules
- `4` generated schedule items
- `2` renewal records
- `3` contract-health snapshots
- `2` integration endpoints
- `2` API key records
- `2` webhook subscriptions
- `3` webhook deliveries
- `2` connector mappings
- `2` import or sync jobs
- `3` recurring-revenue rollups

## Top-Level Entity Families

The generated fixture includes:

- organization, branches, teams, users
- customers, sites, assets
- work_orders, visits, templates, parts_catalog
- assignments, schedule_windows
- review_queue_items, review_decisions, correction_tasks, correction_responses
- activity_events, alerts, sla_policies, dispatch_filters
- branch_summaries, team_summaries, dashboard_rollups, workload_snapshots
- price_books, price_book_items
- labor_rate_policies, part_rate_policies, billing_policies
- tax_rules, discount_rules
- invoices, invoice_lines, invoice_adjustments
- invoice_artifacts, service_summary_artifacts
- payment_records, payment_allocations
- customer_statements, receivable_summaries
- export_jobs, finance_rollups, profitability_snapshots
- estimates, estimate_versions, estimate_approvals, proposal_artifacts
- service_agreements, agreement_lines
- recurring_plans, recurrence_rules, generated_schedule_items
- renewal_records, contract_health_snapshots
- integration_endpoints, api_key_records, webhook_subscriptions, webhook_deliveries
- connector_mappings, import_or_sync_jobs, recurring_revenue_rollups
- indexes, summary

## Commercial Entity Shape

Pricing and finance stay normalized rather than embedded on work orders:

- `price_books`
- `price_book_items`
- `billing_policies`
- `labor_rate_policies`
- `part_rate_policies`
- `tax_rules`
- `discount_rules`
- `invoices`
- `invoice_lines`
- `invoice_adjustments`
- `payment_records`
- `payment_allocations`
- `customer_statements`
- `receivable_summaries`
- `export_jobs`
- `finance_rollups`
- `profitability_snapshots`

M6 adds the contracted-service graph:

- `estimates`
- `estimate_versions`
- `estimate_approvals`
- `proposal_artifacts`
- `service_agreements`
- `agreement_lines`
- `recurring_plans`
- `recurrence_rules`
- `generated_schedule_items`
- `renewal_records`
- `contract_health_snapshots`
- `integration_endpoints`
- `api_key_records`
- `webhook_subscriptions`
- `webhook_deliveries`
- `connector_mappings`
- `import_or_sync_jobs`
- `recurring_revenue_rollups`

## Indexes And Summaries

The reducer reads normalized entities through precomputed indexes. M6 adds estimate, agreement, recurring-plan, renewal, API-key, and delivery indexes alongside the existing work-order, review, billing, and finance families.

Current M6 index families include:

- `estimates_by_status`
- `estimates_by_customer`
- `estimates_by_branch`
- `agreements_by_status`
- `agreements_by_customer`
- `agreements_by_branch`
- `recurring_plans_by_status`
- `recurring_plans_by_agreement`
- `generated_schedule_items_by_plan`
- `renewal_records_by_status`
- `api_keys_by_status`
- `webhook_deliveries_by_status`
- `webhook_deliveries_by_subscription`

The `summary` branch now carries:

- `manager_metrics`
- `branch_rollups`
- `team_rollups`
- `dashboard_rollup`
- `finance_metrics`
- `invoice_status_counts`
- `aging_buckets`
- `receivables_overview`
- `export_job_counts`
- `profitability_summary`
- `estimate_status_counts`
- `agreement_status_counts`
- `recurring_plan_status_counts`
- `contract_health_overview`
- `renewal_pipeline`
- `recurring_revenue_summary`
- `integration_summary`

## Reducer Draft And Sync State

The reducer keeps user-editable commercial inputs in `drafts`, including pricing labels, invoice fields, payment fields, export filters, and the M6 `commercial_ops` subtree for estimate, contract, recurring, and integration forms.

The `sync` branch includes:

- generic `conflict_status`, `conflict_code`, `conflict_entity_id`
- `invoice_lock_status` and `invoice_lock_message`
- `estimate_revision_status` and `stale_estimate_id`
- `agreement_revision_status` and `stale_agreement_id`
- `payment_revision_status`
- `pricing_revision_status` and `stale_price_book_id`
- `export_status`
- `finance_revision`
- nested recurring-generation and delivery-retry state used by the frontend reducer

## Lifecycle Enums

Estimate statuses in the seed:

- `draft`
- `sent`
- `viewed`
- `approved`

Service agreement statuses in the seed:

- `active`
- `paused`
- `renewal_pending`

Recurring-plan statuses in the seed:

- `active`
- `paused`

Invoice statuses in the seed:

- `draft`
- `pending_review`
- `issued`
- `sent`
- `partially_paid`
- `paid`
- `overdue`
- `voided`
- `written_off`
