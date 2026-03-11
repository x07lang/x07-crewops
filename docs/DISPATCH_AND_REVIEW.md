# Dispatch And Review

CrewOps `v0.4.0` keeps dispatch and supervisor review as the front-line operational loop, then hands approved and completed work into the M5 commercial surface without switching apps or data models.

## Dispatcher Surface

Dispatcher work centers on the `dispatch` route and `GET /api/dispatch/board`.

The board is still driven by:

- work orders
- assignments and schedule windows
- branch, team, day, status, priority, and review-state indexes
- dispatcher alerts and shared activity

Dispatcher actions remain:

- create work orders
- edit work-order metadata
- assign and reassign technicians
- filter by branch, team, day, status, and priority
- track review-state exceptions from the same board

Backend routes:

- `GET /api/dispatch/board`
- `POST /api/work-orders`
- `PATCH /api/work-orders/:id`
- `POST /api/work-orders/:id/assign`
- `POST /api/work-orders/:id/reassign`

## Supervisor Review Queue

Supervisor work centers on the `review` route and `GET /api/review/queue`.

The review queue reads:

- `review_queue_items`
- `review_decisions`
- `correction_tasks`
- `correction_responses`
- `work_orders_by_review_state`
- `review_queue_by_status`

Supervisor actions remain:

- approve a completed visit
- reject a visit
- request correction with reason and note
- review resubmitted work

Backend routes:

- `GET /api/review/queue`
- `POST /api/review/:visit_id/approve`
- `POST /api/review/:visit_id/reject`
- `POST /api/review/:visit_id/request-correction`
- `POST /api/corrections/:id/resubmit`

## Handoff To Commercial M5

M5 does not replace dispatch or review. It extends the same workflow after work is completed or approved.

Downstream commercial surfaces read the same normalized tenant and snapshot updates through:

- `POST /api/invoices/generate`
- `GET /api/invoices`
- `GET /api/invoices/:id`
- `GET /api/customers/:id/account`
- `GET /api/finance/summary`
- `GET /api/finance/receivables`
- `GET /api/exports/jobs`

That keeps dispatch, review, invoicing, receivables, and finance aligned to one deterministic seed and one reducer state tree.

## Shared Activity And Sync

Dispatch and review still share one activity and alert model:

- `activity_events`
- `alerts`
- `activity_by_role`
- `alerts_by_role`
- unread counts in `summary.activity_unread` and `summary.alert_unread`

The sync branch now also surfaces commercial conflict state that operators can see after dispatch or review actions feed billing:

- `invoice_lock_status`
- `payment_revision_status`
- `pricing_revision_status`
- `export_status`
- `finance_revision`

## Release Coverage

The `v0.4.0` dispatch and review release bar covers:

- dispatcher filtering, intake, assign, and reassign flows
- supervisor approve, reject, and correction loops
- technician resubmission after correction
- activity and alert propagation
- downstream handoff into invoice generation and commercial summaries
- deterministic stale-lock and conflict responses
