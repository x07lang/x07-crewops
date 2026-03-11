# CrewOps Data Model

CrewOps `v0.4.0` ships an M5 seed that keeps the operations graph and adds commercial billing and finance entities. The canonical source is [`tests/fixtures/demo_org.json`](../tests/fixtures/demo_org.json), mirrored into deterministic backend payloads under [`backend/src/demo_seed.x07.json`](../backend/src/demo_seed.x07.json).

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

Commercial M5:

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

## Top-Level Entity Families

The generated fixture now includes:

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
- indexes, summary

## Commercial Entity Shape

Pricing is normalized rather than embedded on work orders:

- `price_books` and `price_book_items`
- `billing_policies`
- `labor_rate_policies`
- `part_rate_policies`
- `tax_rules`
- `discount_rules`

Invoicing is modeled as separate commercial records:

- `invoices`
- `invoice_lines`
- `invoice_adjustments`
- `invoice_artifacts`
- `service_summary_artifacts`
- `payment_records`
- `payment_allocations`

Accounts receivable and finance views are read from:

- `customer_statements`
- `receivable_summaries`
- `export_jobs`
- `finance_rollups`
- `profitability_snapshots`

## Indexes And Summaries

The reducer continues to read normalized entities through precomputed indexes. M5 adds commercial index families alongside the existing work-order and review indexes.

Current commercial indexes include:

- `invoices_by_status`
- `invoices_by_customer`
- `invoices_by_branch`
- `invoices_by_team`
- `invoices_by_aging_bucket`
- `invoices_by_work_order`
- `payments_by_invoice`
- `payments_by_customer`
- `price_books_by_branch`
- `price_books_by_customer`
- `statements_by_customer`
- `receivables_by_branch`
- `export_jobs_by_status`

The `summary` branch now carries both operations and commercial rollups:

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

## Reducer Draft And Sync State

The reducer keeps user-editable commercial inputs in `drafts`, including pricing labels, invoice dates and memo, invoice line fields, payment fields, statement filters, receivable filters, and export filters.

The `sync` branch now includes:

- generic `conflict_status`, `conflict_code`, `conflict_entity_id`
- `invoice_lock_status` and `invoice_lock_message`
- `stale_invoice_id`
- `payment_revision_status`
- `pricing_revision_status`
- `stale_price_book_id`
- `export_status`
- `finance_revision`

## Lifecycle Enums

Work-order statuses in the seed:

- `draft`
- `scheduled`
- `dispatched`
- `en_route`
- `on_site`
- `blocked`
- `completed`
- `needs_review`
- `invoiced`
- `closed`
- `canceled`

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
