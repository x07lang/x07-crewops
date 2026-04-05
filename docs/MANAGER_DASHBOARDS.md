# Manager Dashboards

CrewOps `v0.6.0` keeps the manager dashboard and adds the enterprise control surface around it. Managers now move across operations, finance, receivables, exports, pricing, invoices, customer accounts, estimates, contracts, recurring plans, integrations, tenant health, inventory risk, procurement backlog, and connector health inside the same reducer.

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
- `estimates`
- `contracts`
- `recurring`
- `integrations`

Related drill-down routes stay in the same app shell:

- `enterprise`
- `inventory`
- `procurement`
- `integration_dashboard`

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
- `GET /api/estimates`
- `GET /api/contracts`
- `GET /api/recurring/board`
- `GET /api/integrations`
- `GET /api/integrations/deliveries`

## Summary Shapes

The manager route still reads the operational rollups:

- `manager_metrics`
- `branch_rollups`
- `team_rollups`
- `dashboard_rollup`
- `activity_unread`
- `alert_unread`

The finance, enterprise, and portal routes add:

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
- `tenant_health_overview`
- `portal_adoption_summary`
- `inventory_summary`
- `procurement_summary`
- `connector_health_summary`

Those shapes are normalized in bootstrap and commercial API responses, so the UI does not need route-specific joins.

## Commercial Control Surface

Managers can review and act on:

- price books, labor and part rate policies, billing policies, tax rules, and discount rules
- invoice lists, detail records, issue and void actions, payment posting, and generated artifacts
- customer account and statement views
- branch or customer receivable summaries
- export job state for invoice, receivable, and profitability extracts
- estimate drafts, revisions, approvals, and conversion candidates
- service agreements, renewal-pending contracts, and recurring-plan generation state
- API keys, webhook subscriptions, delivery logs, and connector mappings

## Decision Questions

The combined manager and commercial surface is built around a short set of questions:

- Where is the review or dispatch backlog creating billing delay?
- Which branches are carrying overdue balance or weak cash collection?
- Which customers need statement follow-up or contract renewal attention?
- Which estimate revisions are stale or blocked on approval?
- Are recurring plans, delivery retries, pricing revisions, invoice locks, or export failures blocking revenue operations?
- Which branch or team has the weakest profitability snapshot or recurring-revenue health?

## Release Coverage

The `v0.6.0` manager release bar covers:

- operational summary bootstrap and drill-down
- finance and profitability summary views
- receivable and customer account drill-down
- pricing and invoice control views
- estimate, contract, renewal, and recurring-service dashboards
- integrations center and delivery-log visibility
- enterprise health, inventory, procurement, and connector-health drill-down
- deterministic sync state for commercial conflicts and revisions
