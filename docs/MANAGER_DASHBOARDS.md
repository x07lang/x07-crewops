# Manager Dashboards

The M4 manager surface turns CrewOps into an operations dashboard rather than a technician-only execution app. Managers consume the same normalized seed and backend snapshots as dispatch and review, but the presentation is summary-first and exception-first.

## Manager Route And API

- Primary route: `manager`
- Shared activity route: `activity`
- Summary API: `GET /api/manager/summary`

The manager route reads the normalized summary branches returned by bootstrap and manager-summary responses instead of joining ad hoc view-specific payloads in the shell.

## Core Summary Shapes

The current summary model exposes:

- `manager_metrics`
- `branch_rollups`
- `team_rollups`
- `dashboard_rollup`
- `activity_unread`

Current manager-facing metrics include:

- overdue count
- blocked count
- review backlog
- completion rate
- SLA risk

Branch and team rollups are normalized so the UI can drill down from organization-level exception cards into specific branch or team pressure points without changing data shape.

## Dashboard Priorities

The manager surface is built around operational questions:

- Which branches are at SLA risk?
- Where is the review backlog accumulating?
- Which teams are carrying blocked or overloaded work?
- Are unread alerts or activity items signaling a broader incident?

That is why the dashboard model keeps:

- branch-level open work-order counts
- branch-level review backlog
- branch-level SLA risk
- team-level open work orders
- team-level blocked counts
- one aggregated dashboard rollup for top-level cards

## Filters And Drill-Down

The default M4 UI state already includes manager-specific selectors:

- `manager_scope`
- `summary_scope`
- selected branch
- selected team
- selected activity item
- selected alert item

Those selectors let the manager route move between branch summary, team detail, and shared activity without booting a separate reporting context.

## Relationship To Dispatch And Review

Manager dashboards do not duplicate dispatcher or supervisor state. They summarize it.

Manager views read from the same underlying sources:

- work-order indexes
- review queue indexes
- alerts by role
- activity by role
- branch and team summaries
- dashboard rollups

This keeps the manager shell consistent with dispatcher and supervisor reality while preserving one reducer and one backend snapshot model.

## Release Coverage

The `v0.3.0` manager release bar covers:

- dashboard bootstrap and summary hydration
- branch or team drill-down
- exception-first SLA and backlog cards
- alert and activity unread state
- coordination with dispatch and review summaries during replay and regression runs
