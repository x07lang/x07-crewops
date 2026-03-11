# Manager Dashboards

CrewOps `v0.4.0` keeps the manager dashboard and adds the M5 commercial control surface around it. Managers now move across operations, finance, receivables, exports, pricing, invoices, and customer account views inside the same reducer.

## Manager And Commercial Routes

Current manager-facing routes:

- `manager`
- `finance`
- `receivables`
- `exports`
- `pricing`
- `invoices`
- `customers`
- `activity`

Current manager-facing APIs:

- `GET /api/manager/summary`
- `GET /api/finance/summary`
- `GET /api/finance/receivables`
- `GET /api/customers/:id/account`
- `GET /api/exports/jobs`
- `POST /api/exports/jobs`
- `POST /api/exports/jobs/:id/retry`
- `GET /api/pricing/config`
- `PATCH /api/pricing/config`
- `GET /api/invoices`
- `POST /api/invoices/generate`
- `GET /api/invoices/:id`
- `PATCH /api/invoices/:id`
- `POST /api/invoices/:id/issue`
- `POST /api/invoices/:id/void`
- `POST /api/invoices/:id/payments`

## Summary Shapes

The manager route still reads the operational rollups:

- `manager_metrics`
- `branch_rollups`
- `team_rollups`
- `dashboard_rollup`
- `activity_unread`
- `alert_unread`

The commercial M5 routes add:

- `finance_metrics`
- `invoice_status_counts`
- `aging_buckets`
- `receivables_overview`
- `export_job_counts`
- `profitability_summary`

Those shapes are already normalized in bootstrap and commercial API responses, so the UI does not need view-specific joins.

## Commercial Control Surface

Managers can now review and act on:

- price books, labor and part rate policies, billing policies, tax rules, and discount rules
- invoice lists, detail records, issue and void actions, payment posting, and generated artifacts
- customer account and statement views
- branch or customer receivable summaries
- export job state for invoice, receivable, and profitability extracts
- finance rollups and profitability snapshots at global, branch, and team scope

## Decision Questions

The combined manager and finance surface is built around a short set of questions:

- Where is the review or dispatch backlog creating billing delay?
- Which branches are carrying overdue balance or weak cash collection?
- Which customers need statement follow-up?
- Are pricing revisions, invoice locks, or export failures blocking revenue operations?
- Which branch or team has the weakest profitability snapshot?

## Release Coverage

The `v0.4.0` manager release bar covers:

- operational summary bootstrap and drill-down
- finance and profitability summary views
- receivable and customer account drill-down
- pricing and invoice control views
- export job monitoring and retry
- deterministic sync state for commercial conflicts and revisions
