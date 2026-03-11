# Dispatch And Review

CrewOps M4 turns the earlier technician-only execution flow into a multi-role operations loop. Dispatcher, supervisor, and technician now work against the same normalized seed, the same reducer, and the same deterministic backend.

## Dispatcher Surface

Dispatcher work centers on the `dispatch` route and the dispatch board snapshot from `GET /api/dispatch/board`.

The board is driven by:

- work orders
- assignments and assignment revisions
- schedule windows
- branch, team, day, status, and priority indexes
- dispatcher alerts
- shared summary rollups

Dispatcher responsibilities in the current app:

- create work orders
- edit work-order metadata
- assign or reassign technicians
- filter by branch, team, day, status, and priority
- track review-state exceptions without leaving the board
- monitor role-specific activity and alert state

Backend routes for dispatcher control:

- `GET /api/dispatch/board`
- `POST /api/work-orders`
- `PATCH /api/work-orders/:id`
- `POST /api/work-orders/:id/assign`
- `POST /api/work-orders/:id/reassign`

## Supervisor Review Queue

Supervisor work centers on the `review` route and the review snapshot from `GET /api/review/queue`.

The review queue reads:

- `review_queue_items`
- `review_decisions`
- `correction_tasks`
- `correction_responses`
- `work_orders_by_review_state`
- `review_queue_by_status`

Supervisor actions:

- approve a completed visit
- reject a visit outright
- request correction with a reason code and supervisor note
- review resubmitted work after correction

Backend routes for supervisor control:

- `GET /api/review/queue`
- `POST /api/review/:visit_id/approve`
- `POST /api/review/:visit_id/reject`
- `POST /api/review/:visit_id/request-correction`

## Correction Loop

The correction loop keeps technician execution and supervisor review connected without introducing separate ad hoc state.

Current correction model:

- a supervisor creates a `correction_task`
- the technician sees the correction context in the same reducer-backed workflow
- the technician resubmits through `POST /api/corrections/:id/resubmit`
- the queue records the item as `resubmitted`
- the supervisor can then close the loop with a new review decision

The current seeded review-state families are:

- `awaiting_review`
- `approved`
- `correction_requested`
- `resubmitted`
- `rejected`
- `not_required`
- `not_ready`

## Shared Activity And Alerts

Dispatch and review are not isolated side panels. They share one role-aware activity center and one normalized alert model.

Current shared activity inputs:

- `activity_events`
- `alerts`
- `activity_by_role`
- `alerts_by_role`
- unread counts in `summary.activity_unread`
- unread counts in sync metadata

Role-aware alert examples in the seed:

- dispatcher overdue or SLA warning
- supervisor review backlog
- manager branch risk
- technician reassignment notice

## Release Coverage

The `v0.3.0` release bar for dispatch and review covers:

- dispatcher filtering and board scanning
- create, assign, and reassign operations
- supervisor queue filtering
- approve or reject decisions
- correction request and technician resubmission
- role-aware activity or alert delivery
- sync conflict and stale assignment handling

CrewOps keeps these flows inside the same reducer and deterministic backend rather than splitting them into separate admin apps.
