#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

python3 - "$ROOT" <<'PY'
import copy
import json
import pathlib
import sys
from collections import defaultdict

root = pathlib.Path(sys.argv[1])
now = "2026-03-11T00:00:00Z"


def clone_doc(doc):
    return copy.deepcopy(doc)


def bytes_defn(name, payload):
    return {
        "kind": "defn",
        "name": name,
        "params": [],
        "result": "bytes",
        "body": ["bytes.lit", json.dumps(payload, separators=(",", ":"))],
    }


org = {
    "id": "org_demo",
    "name": "Northline Facilities",
    "vertical": "property_maintenance",
}
branches = [
    {
        "id": "branch_north",
        "org_id": org["id"],
        "name": "North Branch",
        "city": "Seattle",
    },
    {
        "id": "branch_south",
        "org_id": org["id"],
        "name": "South Branch",
        "city": "Portland",
    },
]
teams = [
    {
        "id": "team_north_alpha",
        "branch_id": "branch_north",
        "name": "North Alpha",
    },
    {
        "id": "team_north_beta",
        "branch_id": "branch_north",
        "name": "North Beta",
    },
    {
        "id": "team_south_gamma",
        "branch_id": "branch_south",
        "name": "South Gamma",
    },
]
technicians = [
    ("user_tech_ava", "Ava Mercer", "team_north_alpha", "branch_north"),
    ("user_tech_noah", "Noah Patel", "team_north_alpha", "branch_north"),
    ("user_tech_zoe", "Zoe Kim", "team_north_alpha", "branch_north"),
    ("user_tech_liam", "Liam Brooks", "team_north_beta", "branch_north"),
    ("user_tech_mila", "Mila Santos", "team_north_beta", "branch_north"),
    ("user_tech_omar", "Omar Bell", "team_south_gamma", "branch_south"),
    ("user_tech_ivy", "Ivy Tran", "team_south_gamma", "branch_south"),
    ("user_tech_jude", "Jude Lopez", "team_south_gamma", "branch_south"),
]

users = {}
for user_id, name, team_id, branch_id in technicians:
    users[user_id] = {
        "id": user_id,
        "role": "technician",
        "name": name,
        "team_ids": [team_id],
        "branch_id": branch_id,
    }
users["user_dispatch_rhea"] = {
    "id": "user_dispatch_rhea",
    "role": "dispatcher",
    "name": "Rhea Cole",
    "team_ids": [team["id"] for team in teams],
    "branch_id": "branch_north",
}
users["user_supervisor_nadia"] = {
    "id": "user_supervisor_nadia",
    "role": "supervisor",
    "name": "Nadia Hart",
    "team_ids": [team["id"] for team in teams],
    "branch_id": "branch_north",
}
users["user_manager_jonas"] = {
    "id": "user_manager_jonas",
    "role": "manager",
    "name": "Jonas Reed",
    "team_ids": [team["id"] for team in teams],
    "branch_id": "branch_north",
}

customers = {}
for i in range(1, 21):
    customer_id = f"cust_{i:03d}"
    branch = branches[(i - 1) % len(branches)]
    customers[customer_id] = {
        "id": customer_id,
        "name": f"Customer {i:02d}",
        "branch_id": branch["id"],
        "segment": "commercial" if i % 3 else "municipal",
    }

sites = {}
for i in range(1, 31):
    site_id = f"site_{i:03d}"
    customer_id = f"cust_{((i - 1) % 20) + 1:03d}"
    branch = branches[(i - 1) % len(branches)]
    sites[site_id] = {
        "id": site_id,
        "customer_id": customer_id,
        "branch_id": branch["id"],
        "name": f"Site {i:02d}",
        "city": branch["city"],
        "sla_tier": ["gold", "platinum", "silver"][(i - 1) % 3],
    }

assets = {}
asset_kinds = ["pump", "panel", "door", "hvac"]
service_levels = ["standard", "routine", "critical"]
for i in range(1, 61):
    asset_id = f"asset_{i:03d}"
    site_id = f"site_{((i - 1) % 30) + 1:03d}"
    assets[asset_id] = {
        "id": asset_id,
        "site_id": site_id,
        "customer_id": sites[site_id]["customer_id"],
        "kind": asset_kinds[i % 4],
        "name": f"Asset {i:03d}",
        "service_level": service_levels[i % 3],
    }

parts_catalog = {
    "part_filter_merv13": {
        "id": "part_filter_merv13",
        "sku": "FLT-MERV13-20x25x2",
        "name": "MERV 13 Filter",
        "uom": "each",
    },
    "part_belt_a42": {
        "id": "part_belt_a42",
        "sku": "BLT-A42",
        "name": "Drive Belt A42",
        "uom": "each",
    },
    "part_contact_cleaner": {
        "id": "part_contact_cleaner",
        "sku": "CLN-CNT-001",
        "name": "Contact Cleaner",
        "uom": "can",
    },
}

templates = {
    "tmpl_arrival": {
        "id": "tmpl_arrival",
        "name": "Arrival Walkthrough",
        "version": 1,
        "sections": [
            {
                "id": "arrival",
                "title": "Arrival",
                "fields": [
                    {
                        "id": "safety_ready",
                        "type": "checkbox",
                        "label": "Safety walkthrough completed",
                        "required": True,
                    }
                ],
            }
        ],
    },
    "tmpl_pm": {
        "id": "tmpl_pm",
        "name": "Preventive Maintenance",
        "version": 3,
        "sections": [
            {
                "id": "arrival",
                "title": "Arrival",
                "fields": [
                    {
                        "id": "safety_ready",
                        "type": "checkbox",
                        "label": "Safety walkthrough completed",
                        "required": True,
                    }
                ],
            },
            {
                "id": "inspection",
                "title": "Inspection",
                "fields": [
                    {
                        "id": "temperature_reading",
                        "type": "number",
                        "label": "Supply temperature (F)",
                        "required": True,
                    },
                    {
                        "id": "filter_condition",
                        "type": "choice",
                        "label": "Filter condition",
                        "required": True,
                        "options": ["clean", "replace"],
                    },
                    {
                        "id": "findings",
                        "type": "textarea",
                        "label": "Findings",
                        "required": True,
                    },
                ],
            },
        ],
        "completion_policy": {
            "signature_required_on_complete": True,
            "block_reason_required": True,
            "location_capture_optional": True,
        },
        "evidence_policy": {
            "allow_camera": True,
            "allow_import": True,
            "accepted_kinds": ["image", "pdf"],
        },
    },
    "tmpl_closeout": {
        "id": "tmpl_closeout",
        "name": "Closeout Review",
        "version": 1,
        "sections": [
            {
                "id": "closeout",
                "title": "Closeout",
                "fields": [
                    {
                        "id": "summary",
                        "type": "textarea",
                        "label": "Completion summary",
                        "required": True,
                    }
                ],
            }
        ],
    },
}

statuses = [
    "scheduled",
    "scheduled",
    "scheduled",
    "dispatched",
    "dispatched",
    "dispatched",
    "en_route",
    "en_route",
    "on_site",
    "on_site",
    "blocked",
    "blocked",
    "completed",
    "completed",
    "completed",
    "needs_review",
    "needs_review",
    "invoiced",
    "closed",
    "canceled",
    "draft",
    "scheduled",
    "dispatched",
    "completed",
    "needs_review",
]
priorities = ["medium", "high", "urgent", "low"]
titles = [
    "Quarterly PM",
    "Leak follow-up",
    "Sensor drift",
    "Roof drain check",
    "Panel reset",
]
windows = ["08:00-10:00", "10:00-12:00", "13:00-15:00", "15:00-17:00"]
review_states = {
    16: "awaiting_review",
    17: "correction_requested",
    25: "resubmitted",
}
activity_kinds = {
    "scheduled": "assignment",
    "dispatched": "dispatch_ready",
    "en_route": "travel_started",
    "on_site": "arrival",
    "blocked": "blocked",
    "completed": "submit",
    "needs_review": "awaiting_review",
    "invoiced": "approved",
    "closed": "closed",
    "canceled": "canceled",
    "draft": "intake_created",
}

work_orders = {}
visits = {}
assignments = {}
schedule_windows = {}
activity_events = {}
review_queue_items = {}
review_decisions = {}
correction_tasks = {}
correction_responses = {}

for i in range(1, 26):
    work_order_id = f"wo_{i:03d}"
    visit_id = f"visit_{i:03d}"
    assignment_id = f"assignment_{i:03d}"
    schedule_window_id = f"schedule_window_{i:03d}"
    site_id = f"site_{((i - 1) % 30) + 1:03d}"
    asset_id = f"asset_{((i - 1) % 60) + 1:03d}"
    team = teams[(i - 1) % len(teams)]
    technician_id = technicians[(i - 1) % len(technicians)][0]
    status = statuses[i - 1]
    scheduled_day = f"2026-03-{((i - 1) % 7) + 10:02d}"
    created_at = (
        f"{scheduled_day}T{8 + ((i - 1) % 4) * 2:02d}:00:00Z"
    )
    review_state = review_states.get(
        i,
        "approved"
        if status in {"completed", "invoiced", "closed"}
        else "not_required" if status in {"canceled", "draft"} else "not_ready",
    )
    work_orders[work_order_id] = {
        "id": work_order_id,
        "number": f"WO-{1200 + i}",
        "title": titles[i % len(titles)],
        "status": status,
        "priority": priorities[(i - 1) % len(priorities)],
        "branch_id": team["branch_id"],
        "team_id": team["id"],
        "assignee_user_id": technician_id,
        "customer_id": sites[site_id]["customer_id"],
        "site_id": site_id,
        "asset_id": asset_id,
        "scheduled_day": scheduled_day,
        "window": windows[i % len(windows)],
        "review_state": review_state,
        "assignment_revision": 2 if i in {6, 17, 25} else 1,
        "latest_assignment_id": assignment_id,
        "schedule_window_id": schedule_window_id,
        "sla_bucket": ["attention", "attention", "stable", "on_track"][
            (i - 1) % 4
        ],
        "template_id": "tmpl_pm" if i % 3 else "tmpl_closeout",
        "completion_policy": {
            "signature_required_on_complete": True,
            "block_reason_required": True,
            "location_capture_optional": True,
        },
        "allowed_part_ids": list(parts_catalog)[: 1 + (i % 3)],
    }
    visits[visit_id] = {
        "id": visit_id,
        "work_order_id": work_order_id,
        "user_id": technician_id,
        "state": "planned" if status in {"scheduled", "dispatched", "en_route"} else "logged",
        "team_id": team["id"],
        "branch_id": team["branch_id"],
        "site_id": site_id,
        "asset_id": asset_id,
        "template_id": work_orders[work_order_id]["template_id"],
        "review_state": review_state,
        "planned_start": created_at,
        "execution": {
            "status": "planned"
            if status in {"scheduled", "dispatched", "en_route"}
            else "resume_required",
            "autosave_status": "idle",
            "completion_mode": "complete",
            "signature_required": True,
            "location_capture_optional": True,
            "notes": "",
            "labor_minutes": 0,
            "parts_used": [],
            "attachments": [],
        },
    }
    assignments[assignment_id] = {
        "id": assignment_id,
        "work_order_id": work_order_id,
        "assignee_user_id": technician_id,
        "team_id": team["id"],
        "branch_id": team["branch_id"],
        "revision": work_orders[work_order_id]["assignment_revision"],
        "scheduled_day": scheduled_day,
        "window": windows[i % len(windows)],
        "priority": work_orders[work_order_id]["priority"],
        "changed_at": created_at,
    }
    schedule_windows[schedule_window_id] = {
        "id": schedule_window_id,
        "work_order_id": work_order_id,
        "day": scheduled_day,
        "window": windows[i % len(windows)],
        "branch_id": team["branch_id"],
        "team_id": team["id"],
    }
    activity_id = f"activity_{i:03d}"
    activity_role = (
        "supervisor"
        if review_state in {"awaiting_review", "correction_requested", "resubmitted"}
        else "dispatcher"
        if status in {"scheduled", "dispatched", "en_route"}
        else "manager"
        if status in {"draft", "invoiced"}
        else "technician"
    )
    activity_events[activity_id] = {
        "id": activity_id,
        "kind": activity_kinds[status],
        "work_order_id": work_order_id,
        "visit_id": visit_id,
        "role": activity_role,
        "message": f"WO-{1200 + i} {titles[i % len(titles)]}",
        "created_at": created_at,
        "unread": i % 2 == 0,
    }
    if review_state in {"awaiting_review", "correction_requested", "resubmitted"}:
        queue_id = f"review_queue_{i:03d}"
        review_queue_items[queue_id] = {
            "id": queue_id,
            "visit_id": visit_id,
            "work_order_id": work_order_id,
            "status": review_state,
            "priority": work_orders[work_order_id]["priority"],
            "branch_id": team["branch_id"],
            "team_id": team["id"],
            "assignee_user_id": technician_id,
            "submitted_at": created_at,
        }
    if review_state == "awaiting_review":
        review_decisions[f"review_decision_{i:03d}"] = {
            "id": f"review_decision_{i:03d}",
            "visit_id": visit_id,
            "work_order_id": work_order_id,
            "outcome": "approved",
            "reviewer_user_id": "user_supervisor_nadia",
            "note": "Ready for closeout.",
        }
    if review_state in {"correction_requested", "resubmitted"}:
        correction_id = f"correction_{i:03d}" if i != 25 else "correction_017"
        correction_tasks[correction_id] = {
            "id": correction_id,
            "visit_id": visit_id if i != 25 else "visit_017",
            "work_order_id": work_order_id if i != 25 else "wo_017",
            "status": review_state if i == 25 else "resubmitted" if i == 17 else review_state,
            "reason_code": "missing_evidence",
            "supervisor_note": "Add evidence and clarify the findings.",
            "requested_by_user_id": "user_supervisor_nadia",
        }
    if review_state == "resubmitted":
        correction_responses["correction_response_025"] = {
            "id": "correction_response_025",
            "correction_task_id": "correction_017",
            "visit_id": visit_id,
            "work_order_id": work_order_id,
            "status": "resubmitted",
            "response_note": "Uploaded additional evidence and clarified findings.",
            "submitted_by_user_id": technician_id,
        }

alerts = {
    "alert_dispatcher_overdue": {
        "id": "alert_dispatcher_overdue",
        "role": "dispatcher",
        "severity": "high",
        "work_order_id": "wo_005",
        "message": "WO-1205 is nearing SLA breach.",
    },
    "alert_supervisor_review": {
        "id": "alert_supervisor_review",
        "role": "supervisor",
        "severity": "medium",
        "work_order_id": "wo_016",
        "message": "Review queue has awaiting items.",
    },
    "alert_manager_sla": {
        "id": "alert_manager_sla",
        "role": "manager",
        "severity": "high",
        "work_order_id": "wo_010",
        "message": "North branch SLA risk is elevated.",
    },
    "alert_technician_reassign": {
        "id": "alert_technician_reassign",
        "role": "technician",
        "severity": "medium",
        "work_order_id": "wo_006",
        "message": "A reassignment changed your day plan.",
    },
}

sla_policies = {
    "sla_default": {
        "id": "sla_default",
        "location_policy": "optional",
        "signature_policy": "required",
        "review_policy": "required",
        "default_priority": "medium",
        "expected_duration": "90",
        "breach_threshold_minutes": 120,
    }
}
dashboard_rollups = {
    "dashboard_default": {
        "id": "dashboard_default",
        "branch_ids": [branch["id"] for branch in branches],
        "team_ids": [team["id"] for team in teams],
        "overdue": 4,
        "blocked": 2,
        "awaiting_review": 1,
        "correction_requested": 1,
        "resubmitted": 1,
        "sla_risk": 13,
    }
}
workload_snapshots = {
    "team_north_alpha": {
        "id": "workload_team_north_alpha",
        "team_id": "team_north_alpha",
        "scheduled": 3,
        "active": 2,
        "review": 2,
    },
    "team_north_beta": {
        "id": "workload_team_north_beta",
        "team_id": "team_north_beta",
        "scheduled": 3,
        "active": 1,
        "review": 1,
    },
    "team_south_gamma": {
        "id": "workload_team_south_gamma",
        "team_id": "team_south_gamma",
        "scheduled": 2,
        "active": 1,
        "review": 0,
    },
}
branch_summaries = {
    "branch_north": {
        "id": "branch_north",
        "branch_id": "branch_north",
        "open_work_orders": 15,
        "review_backlog": 3,
        "sla_risk": 9,
    },
    "branch_south": {
        "id": "branch_south",
        "branch_id": "branch_south",
        "open_work_orders": 8,
        "review_backlog": 0,
        "sla_risk": 4,
    },
}
team_summaries = {
    "team_north_alpha": {
        "id": "team_north_alpha",
        "team_id": "team_north_alpha",
        "branch_id": "branch_north",
        "open_work_orders": 8,
        "blocked": 0,
    },
    "team_north_beta": {
        "id": "team_north_beta",
        "team_id": "team_north_beta",
        "branch_id": "branch_north",
        "open_work_orders": 7,
        "blocked": 1,
    },
    "team_south_gamma": {
        "id": "team_south_gamma",
        "team_id": "team_south_gamma",
        "branch_id": "branch_south",
        "open_work_orders": 8,
        "blocked": 1,
    },
}
dispatch_filters = {
    "dispatch_default": {
        "id": "dispatch_default",
        "day": "2026-03-11",
        "branch_id": "branch_north",
        "team_id": "all",
        "status": "all",
        "priority": "all",
    }
}

indexes = {
    "work_orders_by_status": {
        key: []
        for key in [
            "draft",
            "scheduled",
            "dispatched",
            "en_route",
            "on_site",
            "blocked",
            "completed",
            "needs_review",
            "invoiced",
            "closed",
            "canceled",
        ]
    },
    "work_orders_by_assignee": defaultdict(list),
    "work_orders_by_branch": defaultdict(list),
    "work_orders_by_team": defaultdict(list),
    "work_orders_by_day": defaultdict(list),
    "work_orders_by_review_state": defaultdict(list),
    "work_orders_by_priority": defaultdict(list),
    "review_queue_by_status": defaultdict(list),
    "alerts_by_role": defaultdict(list),
    "activity_by_role": defaultdict(list),
    "assets_by_site": defaultdict(list),
    "sites_by_customer": defaultdict(list),
}
for work_order_id, work_order in work_orders.items():
    indexes["work_orders_by_status"][work_order["status"]].append(work_order_id)
    indexes["work_orders_by_assignee"][work_order["assignee_user_id"]].append(work_order_id)
    indexes["work_orders_by_branch"][work_order["branch_id"]].append(work_order_id)
    indexes["work_orders_by_team"][work_order["team_id"]].append(work_order_id)
    indexes["work_orders_by_day"][work_order["scheduled_day"]].append(work_order_id)
    indexes["work_orders_by_review_state"][work_order["review_state"]].append(work_order_id)
    indexes["work_orders_by_priority"][work_order["priority"]].append(work_order_id)
for review_queue_id, item in review_queue_items.items():
    indexes["review_queue_by_status"][item["status"]].append(review_queue_id)
for alert_id, alert in alerts.items():
    indexes["alerts_by_role"][alert["role"]].append(alert_id)
for activity_id, activity in activity_events.items():
    indexes["activity_by_role"][activity["role"]].append(activity_id)
for asset_id, asset in assets.items():
    indexes["assets_by_site"][asset["site_id"]].append(asset_id)
for site_id, site in sites.items():
    indexes["sites_by_customer"][site["customer_id"]].append(site_id)
indexes = {
    key: {
        inner_key: value
        for inner_key, value in sorted(inner.items())
    }
    if isinstance(inner, defaultdict)
    else inner
    for key, inner in indexes.items()
}

summary = {
    "counts": {
        "branches": len(branches),
        "teams": len(teams),
        "technicians": len(technicians),
        "customers": len(customers),
        "sites": len(sites),
        "assets": len(assets),
        "work_orders": len(work_orders),
    },
    "status_counts": {
        key: len(value) for key, value in indexes["work_orders_by_status"].items()
    },
    "attention_work_orders": [
        work_order_id
        for work_order_id, work_order in work_orders.items()
        if work_order["sla_bucket"] == "attention"
    ][:6],
    "dispatcher_focus": list(work_orders)[:8],
    "manager_metrics": {
        "overdue": 4,
        "blocked": len(indexes["work_orders_by_status"]["blocked"]),
        "review": len(indexes["review_queue_by_status"]["awaiting_review"])
        + len(indexes["review_queue_by_status"]["correction_requested"])
        + len(indexes["review_queue_by_status"]["resubmitted"]),
        "completion_rate": "76%",
        "sla_risk": 13,
    },
    "supervisor_metrics": {
        "awaiting_review": len(indexes["review_queue_by_status"]["awaiting_review"]),
        "correction_requested": len(indexes["review_queue_by_status"]["correction_requested"]),
        "resubmitted": len(indexes["review_queue_by_status"]["resubmitted"]),
    },
    "technician_today": {
        user_id: indexes["work_orders_by_assignee"].get(user_id, [])[:3]
        for user_id, *_ in technicians
    },
    "activity_unread": {
        "technician": 1,
        "dispatcher": 1,
        "supervisor": 1,
        "manager": 1,
    },
    "branch_rollups": list(branch_summaries.values()),
    "team_rollups": list(team_summaries.values()),
    "dashboard_rollup": dashboard_rollups["dashboard_default"],
}

fixture = {
    "organization": org,
    "branches": {branch["id"]: branch for branch in branches},
    "teams": {team["id"]: team for team in teams},
    "users": users,
    "customers": customers,
    "sites": sites,
    "assets": assets,
    "work_orders": work_orders,
    "visits": visits,
    "templates": templates,
    "parts_catalog": parts_catalog,
    "assignments": assignments,
    "schedule_windows": schedule_windows,
    "review_queue_items": review_queue_items,
    "review_decisions": review_decisions,
    "correction_tasks": correction_tasks,
    "correction_responses": correction_responses,
    "activity_events": activity_events,
    "alerts": alerts,
    "sla_policies": sla_policies,
    "dashboard_rollups": dashboard_rollups,
    "workload_snapshots": workload_snapshots,
    "branch_summaries": branch_summaries,
    "team_summaries": team_summaries,
    "dispatch_filters": dispatch_filters,
    "indexes": indexes,
    "summary": summary,
}

base_entities = {
    "org": {org["id"]: org},
    "branches": fixture["branches"],
    "teams": fixture["teams"],
    "users": users,
    "customers": customers,
    "sites": sites,
    "assets": assets,
    "work_orders": work_orders,
    "visits": visits,
    "templates": templates,
    "parts_catalog": parts_catalog,
    "assignments": assignments,
    "schedule_windows": schedule_windows,
    "review_queue_items": review_queue_items,
    "review_decisions": review_decisions,
    "correction_tasks": correction_tasks,
    "correction_responses": correction_responses,
    "activity_events": activity_events,
    "alerts": alerts,
    "sla_policies": sla_policies,
    "dashboard_rollups": dashboard_rollups,
    "workload_snapshots": workload_snapshots,
    "branch_summaries": branch_summaries,
    "team_summaries": team_summaries,
    "dispatch_filters": dispatch_filters,
}
bootstrap_work_order_ids = [
    "wo_001",
    "wo_002",
    "wo_003",
    "wo_004",
    "wo_005",
    "wo_006",
]
bootstrap_template_ids = ["tmpl_arrival", "tmpl_pm", "tmpl_closeout"]
review_snapshot_work_order_ids = ["wo_016", "wo_017", "wo_025"]


def compact_work_order_doc(work_order):
    return {
        "id": work_order["id"],
        "number": work_order["number"],
        "title": work_order["title"],
        "priority": work_order["priority"],
        "scheduled_day": work_order["scheduled_day"],
        "window": work_order["window"],
        "allowed_part_ids": clone_doc(work_order["allowed_part_ids"]),
    }


def compact_template_doc(template):
    sections = []
    if template["sections"]:
        first_label = template["sections"][0]["fields"][0]["label"]
        sections.append({"fields": [{"label": first_label}]})
    if len(template["sections"]) > 1:
        second_fields = []
        for field in template["sections"][1]["fields"][:3]:
            second_fields.append({"label": field["label"]})
        if second_fields:
            sections.append({"fields": second_fields})
    return {
        "id": template["id"],
        "name": template["name"],
        "sections": sections,
    }


bootstrap_entities = {
    "work_orders": {
        work_order_id: compact_work_order_doc(work_orders[work_order_id])
        for work_order_id in bootstrap_work_order_ids
    },
    "templates": {
        template_id: compact_template_doc(templates[template_id])
        for template_id in bootstrap_template_ids
    },
    "parts_catalog": clone_doc(parts_catalog),
}
review_entities = {
    "users": users,
    "branches": fixture["branches"],
    "teams": fixture["teams"],
    "sites": sites,
    "assets": assets,
    "work_orders": work_orders,
    "visits": visits,
    "review_queue_items": review_queue_items,
    "review_decisions": review_decisions,
    "correction_tasks": correction_tasks,
    "correction_responses": correction_responses,
    "activity_events": activity_events,
    "alerts": alerts,
}
review_indexes = {
    "work_orders_by_review_state": indexes["work_orders_by_review_state"],
    "review_queue_by_status": indexes["review_queue_by_status"],
    "alerts_by_role": indexes["alerts_by_role"],
    "activity_by_role": indexes["activity_by_role"],
}
review_summary = {
    "supervisor_metrics": summary["supervisor_metrics"],
    "activity_unread": summary["activity_unread"],
    "manager_metrics": summary["manager_metrics"],
}


def sync_doc(cursor, status):
    return {
        "cursor": cursor,
        "pending_ops": [],
        "last_pull_at": now,
        "last_push_at": None,
        "last_server_event_at": now,
        "status": status,
        "last_error": None,
        "conflict_status": "idle",
        "conflict_message": "",
        "conflict_code": None,
        "conflict_entity_id": None,
        "unread_alerts": 4,
        "unread_activity": 6,
    }


def compact_entity_snapshot(source_entities, extra_work_order_ids=None):
    work_order_ids = list(
        dict.fromkeys(bootstrap_work_order_ids + list(extra_work_order_ids or []))
    )
    return {
        "work_orders": {
            work_order_id: compact_work_order_doc(source_entities["work_orders"][work_order_id])
            for work_order_id in work_order_ids
            if work_order_id in source_entities["work_orders"]
        },
        "templates": {
            template_id: compact_template_doc(source_entities["templates"][template_id])
            for template_id in bootstrap_template_ids
            if template_id in source_entities["templates"]
        },
        "parts_catalog": clone_doc(source_entities.get("parts_catalog", parts_catalog)),
    }


def payload_with_snapshot(extra, extra_work_order_ids=None):
    out = dict(extra)
    out["entities"] = compact_entity_snapshot(base_entities, extra_work_order_ids)
    out["indexes"] = clone_doc(indexes)
    out["summary"] = clone_doc(summary)
    return out


meta_doc = {
    "app_name": "CrewOps",
    "app_version": "0.3.0",
    "build_profile": "dev",
    "environment": "local",
    "generated_at": now,
}


def login_doc(role, user_id, branch_id, team_id):
    return {
        "session": {
            "token": f"dev_{role}_token",
            "role": role,
            "user_id": user_id,
            "branch_id": branch_id,
            "team_id": team_id,
            "status": "ready",
        }
    }


bootstrap_doc = {
    "meta": meta_doc,
    "session_defaults": {
        "technician": {
            "user_id": "user_tech_ava",
            "branch_id": "branch_north",
            "team_id": "team_north_alpha",
        },
        "dispatcher": {
            "user_id": "user_dispatch_rhea",
            "branch_id": "branch_north",
            "team_id": "team_north_alpha",
        },
        "supervisor": {
            "user_id": "user_supervisor_nadia",
            "branch_id": "branch_north",
            "team_id": "team_north_alpha",
        },
        "manager": {
            "user_id": "user_manager_jonas",
            "branch_id": "branch_north",
            "team_id": "team_north_alpha",
        },
    },
    "bootstrap": {
        "status": "ready",
        "source": "http",
        "last_loaded_at": now,
        "sync_cursor": "sync_cursor_2026_03_11_101",
    },
    "entities": bootstrap_entities,
    "indexes": indexes,
    "summary": summary,
    "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    "diagnostics": {
        "app_version": "0.3.0",
        "target_kind": "web",
        "build_profile": "dev",
    },
}

dispatch_board_doc = payload_with_snapshot(
    {
        "board": {
            "day": "2026-03-11",
            "branch_id": "branch_north",
            "team_id": "all",
            "filters": dispatch_filters["dispatch_default"],
            "focus_work_orders": summary["dispatcher_focus"],
        },
        "workload": workload_snapshots,
        "alerts": ["alert_dispatcher_overdue"],
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    },
)

review_queue_doc = payload_with_snapshot(
    {
        "queue": list(review_queue_items),
        "items": review_queue_items,
        "corrections": correction_tasks,
        "alerts": ["alert_supervisor_review"],
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    },
    review_snapshot_work_order_ids,
)

manager_summary_doc = payload_with_snapshot(
    {
        "dashboard_rollup": dashboard_rollups["dashboard_default"],
        "branch_summaries": branch_summaries,
        "team_summaries": team_summaries,
        "workload_snapshots": workload_snapshots,
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

activity_feed_doc = payload_with_snapshot(
    {
        "items": list(activity_events),
        "events": activity_events,
        "alerts": alerts,
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    },
)

created_entities = clone_doc(base_entities)
created_indexes = clone_doc(indexes)
created_summary = clone_doc(summary)
created_work_order = {
    "id": "wo_026",
    "number": "WO-1226",
    "title": "Dock door follow-up",
    "status": "scheduled",
    "priority": "high",
    "branch_id": "branch_north",
    "team_id": "team_north_alpha",
    "assignee_user_id": "user_tech_ava",
    "customer_id": "cust_001",
    "site_id": "site_001",
    "asset_id": "asset_001",
    "scheduled_day": "2026-03-11",
    "window": "15:00-17:00",
    "review_state": "not_ready",
    "assignment_revision": 1,
    "latest_assignment_id": "assignment_026",
    "schedule_window_id": "schedule_window_026",
    "sla_bucket": "attention",
    "template_id": "tmpl_pm",
    "completion_policy": {
        "signature_required_on_complete": True,
        "block_reason_required": True,
        "location_capture_optional": True,
    },
    "allowed_part_ids": ["part_filter_merv13", "part_belt_a42"],
}
created_visit = {
    "id": "visit_026",
    "work_order_id": "wo_026",
    "user_id": "user_tech_ava",
    "state": "planned",
    "team_id": "team_north_alpha",
    "branch_id": "branch_north",
    "site_id": "site_001",
    "asset_id": "asset_001",
    "template_id": "tmpl_pm",
    "review_state": "not_ready",
    "planned_start": "2026-03-11T15:00:00Z",
    "execution": {
        "status": "planned",
        "autosave_status": "idle",
        "completion_mode": "complete",
        "signature_required": True,
        "location_capture_optional": True,
        "notes": "",
        "labor_minutes": 0,
        "parts_used": [],
        "attachments": [],
    },
}
created_entities["work_orders"]["wo_026"] = created_work_order
created_entities["visits"]["visit_026"] = created_visit
created_entities["assignments"]["assignment_026"] = {
    "id": "assignment_026",
    "work_order_id": "wo_026",
    "assignee_user_id": "user_tech_ava",
    "team_id": "team_north_alpha",
    "branch_id": "branch_north",
    "revision": 1,
    "scheduled_day": "2026-03-11",
    "window": "15:00-17:00",
    "priority": "high",
    "changed_at": "2026-03-11T09:30:00Z",
}
created_entities["schedule_windows"]["schedule_window_026"] = {
    "id": "schedule_window_026",
    "work_order_id": "wo_026",
    "day": "2026-03-11",
    "window": "15:00-17:00",
    "branch_id": "branch_north",
    "team_id": "team_north_alpha",
}
created_entities["activity_events"]["activity_026"] = {
    "id": "activity_026",
    "kind": "intake_created",
    "work_order_id": "wo_026",
    "visit_id": "visit_026",
    "role": "dispatcher",
    "message": "WO-1226 Dock door follow-up",
    "created_at": "2026-03-11T09:30:00Z",
    "unread": True,
}
created_indexes["work_orders_by_status"]["scheduled"].append("wo_026")
created_indexes["work_orders_by_assignee"]["user_tech_ava"].append("wo_026")
created_indexes["work_orders_by_branch"]["branch_north"].append("wo_026")
created_indexes["work_orders_by_team"]["team_north_alpha"].append("wo_026")
created_indexes["work_orders_by_day"]["2026-03-11"].append("wo_026")
created_indexes["work_orders_by_review_state"]["not_ready"].append("wo_026")
created_indexes["work_orders_by_priority"]["high"].append("wo_026")
created_summary["counts"]["work_orders"] = 26
created_summary["status_counts"]["scheduled"] = (
    created_summary["status_counts"]["scheduled"] + 1
)
work_order_create_doc = {
    "status": "created",
    "message": "Created demo work order intake record.",
    "work_order_id": "wo_026",
    "entities": created_entities,
    "indexes": created_indexes,
    "summary": created_summary,
    "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
}

work_order_patch_doc = payload_with_snapshot(
    {
        "status": "updated",
        "message": "Updated work order metadata.",
        "work_order_id": "wo_001",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    ["wo_001"],
)
work_order_assign_doc = payload_with_snapshot(
    {
        "status": "assigned",
        "message": "Assigned work order to technician.",
        "work_order_id": "wo_001",
        "assignment_id": "assignment_001",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    ["wo_001"],
)
work_order_reassign_doc = payload_with_snapshot(
    {
        "status": "reassigned",
        "message": "Reassigned work order and published activity event.",
        "work_order_id": "wo_006",
        "assignment_id": "assignment_006",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    ["wo_006"],
)
review_approve_doc = payload_with_snapshot(
    {
        "status": "approved",
        "message": "Supervisor approved the visit.",
        "visit_id": "visit_016",
        "decision_id": "review_decision_016",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    ["wo_016"],
)
review_reject_doc = payload_with_snapshot(
    {
        "status": "rejected",
        "message": "Supervisor rejected the visit.",
        "visit_id": "visit_017",
        "decision_id": "review_decision_reject_017",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    ["wo_017"],
)
review_request_correction_doc = payload_with_snapshot(
    {
        "status": "correction_requested",
        "message": "Supervisor requested correction.",
        "visit_id": "visit_017",
        "correction_task_id": "correction_017",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    ["wo_017"],
)
correction_resubmit_doc = payload_with_snapshot(
    {
        "status": "resubmitted",
        "message": "Technician resubmitted the correction task.",
        "visit_id": "visit_025",
        "correction_task_id": "correction_017",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    ["wo_025"],
)
work_order_patch_map = {
    work_order_id: payload_with_snapshot(
        {
            "status": "updated",
            "message": "Updated work order metadata.",
            "work_order_id": work_order_id,
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        },
        [work_order_id],
    )
    for work_order_id in work_orders
}
work_order_assign_map = {
    work_order_id: payload_with_snapshot(
        {
            "status": "assigned",
            "message": "Assigned work order to technician.",
            "work_order_id": work_order_id,
            "assignment_id": work_orders[work_order_id]["latest_assignment_id"],
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        },
        [work_order_id],
    )
    for work_order_id in work_orders
}
work_order_reassign_map = {
    work_order_id: payload_with_snapshot(
        {
            "status": "reassigned",
            "message": "Reassigned work order and published activity event.",
            "work_order_id": work_order_id,
            "assignment_id": work_orders[work_order_id]["latest_assignment_id"],
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        },
        [work_order_id],
    )
    for work_order_id in work_orders
}
review_approve_map = {
    visit_id: payload_with_snapshot(
        {
            "status": "approved",
            "message": "Supervisor approved the visit.",
            "visit_id": visit_id,
            "decision_id": f"review_decision_{visit_id.split('_')[1]}",
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        },
        [f"wo_{visit_id.split('_')[1]}"],
    )
    for visit_id in visits
}
review_reject_map = {
    visit_id: payload_with_snapshot(
        {
            "status": "rejected",
            "message": "Supervisor rejected the visit.",
            "visit_id": visit_id,
            "decision_id": f"review_decision_reject_{visit_id.split('_')[1]}",
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        },
        [f"wo_{visit_id.split('_')[1]}"],
    )
    for visit_id in visits
}
review_request_correction_map = {
    visit_id: payload_with_snapshot(
        {
            "status": "correction_requested",
            "message": "Supervisor requested correction.",
            "visit_id": visit_id,
            "correction_task_id": f"correction_{visit_id.split('_')[1]}",
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        },
        [f"wo_{visit_id.split('_')[1]}"],
    )
    for visit_id in visits
}
correction_resubmit_map = {
    correction_id: payload_with_snapshot(
        {
            "status": "resubmitted",
            "message": "Technician resubmitted the correction task.",
            "visit_id": correction_tasks[correction_id]["visit_id"],
            "correction_task_id": correction_id,
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        },
        [correction_tasks[correction_id]["work_order_id"]],
    )
    for correction_id in correction_tasks
}

sync_pull_doc = {
    "cursor": "sync_cursor_2026_03_11_102",
    "changes": [
        {
            "kind": "assignment",
            "entity_id": "assignment_006",
            "work_order_id": "wo_006",
        },
        {
            "kind": "review_queue",
            "entity_id": "review_queue_017",
            "work_order_id": "wo_017",
        },
    ],
    "status": "idle",
    "received_at": now,
    "server_policies": {
        "signature_required_on_complete": True,
        "location_capture_optional": True,
        "offline_queue_mode": "client_ops_v1",
    },
    "entities": {
        "assignments": assignments,
        "review_queue_items": review_queue_items,
        "correction_tasks": correction_tasks,
        "activity_events": activity_events,
        "alerts": alerts,
    },
    "indexes": indexes,
    "summary": summary,
    "sync": sync_doc("sync_cursor_2026_03_11_102", "idle"),
}
sync_push_doc = {
    "cursor": "sync_cursor_2026_03_11_103",
    "accepted_ops": [
        "op_check_in_visit_001",
        "op_save_draft_visit_001",
        "op_submit_visit_001",
        "op_reassign_wo_006",
    ],
    "conflicts": [],
    "status": "accepted",
    "received_at": now,
    "entities": {
        "assignments": assignments,
        "review_queue_items": review_queue_items,
        "correction_tasks": correction_tasks,
        "activity_events": activity_events,
        "alerts": alerts,
    },
    "indexes": indexes,
    "summary": summary,
    "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
}

check_in_doc = {
    "visit_id": "visit_001",
    "status": "checked_in",
    "visit_state": "on_site",
    "checked_in_at": "2026-03-10T09:10:00Z",
    "location_capture_optional": True,
}
save_draft_doc = {
    "visit_id": "visit_001",
    "status": "saved",
    "server_draft_version": "draft_v3",
    "saved_at": "2026-03-10T09:12:00Z",
}
submit_doc = {
    "visit_id": "visit_001",
    "status": "accepted",
    "visit_state": "completed",
    "requires_signature": True,
    "submitted_at": "2026-03-10T10:05:00Z",
}
block_doc = {
    "visit_id": "visit_001",
    "status": "blocked",
    "visit_state": "blocked",
    "requires_block_reason": True,
    "submitted_at": "2026-03-10T10:05:00Z",
}
check_out_doc = {
    "visit_id": "visit_001",
    "status": "checked_out",
    "visit_state": "completed",
    "checked_out_at": "2026-03-10T10:05:00Z",
    "location_capture_optional": True,
}
attachment_register_doc = {
    "attachment_id": "att_demo_001",
    "status": "registered",
    "upload_path": "/api/attachments/att_demo_001/content",
    "manifest": {
        "source": "device",
        "kind": "image",
        "handle": "blob_demo_001",
    },
}
attachment_upload_doc = {
    "attachment_id": "att_demo_001",
    "status": "uploaded",
    "uploaded_at": "2026-03-10T09:33:00Z",
}

module = {
    "schema_version": "x07.x07ast@0.5.0",
    "kind": "module",
    "module_id": "demo_seed",
    "imports": [],
    "decls": [
        {
            "kind": "export",
            "names": [
                "demo_seed.bootstrap_body_v1",
                "demo_seed.fixture_body_v1",
                "demo_seed.entities_body_v1",
                "demo_seed.indexes_body_v1",
                "demo_seed.login_dispatcher_body_v1",
                "demo_seed.login_manager_body_v1",
                "demo_seed.login_supervisor_body_v1",
                "demo_seed.login_technician_body_v1",
                "demo_seed.meta_body_v1",
                "demo_seed.review_entities_body_v1",
                "demo_seed.review_indexes_body_v1",
                "demo_seed.review_summary_body_v1",
                "demo_seed.summary_body_v1",
                "demo_seed.sync_idle_body_v1",
                "demo_seed.sync_accepted_body_v1",
                "demo_seed.dispatch_board_body_v1",
                "demo_seed.review_queue_body_v1",
                "demo_seed.manager_summary_body_v1",
                "demo_seed.activity_feed_body_v1",
                "demo_seed.work_order_create_body_v1",
                "demo_seed.work_order_patch_body_v1",
                "demo_seed.work_order_patch_map_body_v1",
                "demo_seed.work_order_assign_body_v1",
                "demo_seed.work_order_assign_map_body_v1",
                "demo_seed.work_order_reassign_body_v1",
                "demo_seed.work_order_reassign_map_body_v1",
                "demo_seed.review_approve_body_v1",
                "demo_seed.review_approve_map_body_v1",
                "demo_seed.review_reject_body_v1",
                "demo_seed.review_reject_map_body_v1",
                "demo_seed.review_request_correction_body_v1",
                "demo_seed.review_request_correction_map_body_v1",
                "demo_seed.correction_resubmit_body_v1",
                "demo_seed.correction_resubmit_map_body_v1",
                "demo_seed.sync_pull_body_v1",
                "demo_seed.sync_push_body_v1",
                "demo_seed.template_arrival_body_v1",
                "demo_seed.template_pm_body_v1",
                "demo_seed.template_closeout_body_v1",
                "demo_seed.visit_block_body_v1",
                "demo_seed.visit_check_in_body_v1",
                "demo_seed.visit_check_out_body_v1",
                "demo_seed.visit_save_draft_body_v1",
                "demo_seed.visit_submit_body_v1",
                "demo_seed.attachment_register_body_v1",
                "demo_seed.attachment_upload_body_v1",
            ],
        },
        bytes_defn("demo_seed.fixture_body_v1", fixture),
        bytes_defn("demo_seed.entities_body_v1", base_entities),
        bytes_defn("demo_seed.indexes_body_v1", indexes),
        bytes_defn("demo_seed.bootstrap_body_v1", bootstrap_doc),
        bytes_defn(
            "demo_seed.login_technician_body_v1",
            login_doc(
                "technician",
                "user_tech_ava",
                "branch_north",
                "team_north_alpha",
            ),
        ),
        bytes_defn(
            "demo_seed.login_dispatcher_body_v1",
            login_doc(
                "dispatcher",
                "user_dispatch_rhea",
                "branch_north",
                "team_north_alpha",
            ),
        ),
        bytes_defn(
            "demo_seed.login_supervisor_body_v1",
            login_doc(
                "supervisor",
                "user_supervisor_nadia",
                "branch_north",
                "team_north_alpha",
            ),
        ),
        bytes_defn(
            "demo_seed.login_manager_body_v1",
            login_doc(
                "manager",
                "user_manager_jonas",
                "branch_north",
                "team_north_alpha",
            ),
        ),
        bytes_defn("demo_seed.meta_body_v1", meta_doc),
        bytes_defn("demo_seed.review_entities_body_v1", review_entities),
        bytes_defn("demo_seed.review_indexes_body_v1", review_indexes),
        bytes_defn("demo_seed.review_summary_body_v1", review_summary),
        bytes_defn("demo_seed.summary_body_v1", summary),
        bytes_defn("demo_seed.sync_idle_body_v1", sync_doc("sync_cursor_2026_03_11_101", "idle")),
        bytes_defn("demo_seed.sync_accepted_body_v1", sync_doc("sync_cursor_2026_03_11_103", "accepted")),
        bytes_defn("demo_seed.dispatch_board_body_v1", dispatch_board_doc),
        bytes_defn("demo_seed.review_queue_body_v1", review_queue_doc),
        bytes_defn("demo_seed.manager_summary_body_v1", manager_summary_doc),
        bytes_defn("demo_seed.activity_feed_body_v1", activity_feed_doc),
        bytes_defn("demo_seed.work_order_create_body_v1", work_order_create_doc),
        bytes_defn("demo_seed.work_order_patch_body_v1", work_order_patch_doc),
        bytes_defn("demo_seed.work_order_patch_map_body_v1", work_order_patch_map),
        bytes_defn("demo_seed.work_order_assign_body_v1", work_order_assign_doc),
        bytes_defn("demo_seed.work_order_assign_map_body_v1", work_order_assign_map),
        bytes_defn("demo_seed.work_order_reassign_body_v1", work_order_reassign_doc),
        bytes_defn("demo_seed.work_order_reassign_map_body_v1", work_order_reassign_map),
        bytes_defn("demo_seed.review_approve_body_v1", review_approve_doc),
        bytes_defn("demo_seed.review_approve_map_body_v1", review_approve_map),
        bytes_defn("demo_seed.review_reject_body_v1", review_reject_doc),
        bytes_defn("demo_seed.review_reject_map_body_v1", review_reject_map),
        bytes_defn(
            "demo_seed.review_request_correction_body_v1",
            review_request_correction_doc,
        ),
        bytes_defn(
            "demo_seed.review_request_correction_map_body_v1",
            review_request_correction_map,
        ),
        bytes_defn("demo_seed.correction_resubmit_body_v1", correction_resubmit_doc),
        bytes_defn(
            "demo_seed.correction_resubmit_map_body_v1",
            correction_resubmit_map,
        ),
        bytes_defn("demo_seed.sync_pull_body_v1", sync_pull_doc),
        bytes_defn("demo_seed.sync_push_body_v1", sync_push_doc),
        bytes_defn("demo_seed.template_arrival_body_v1", templates["tmpl_arrival"]),
        bytes_defn("demo_seed.template_pm_body_v1", templates["tmpl_pm"]),
        bytes_defn("demo_seed.template_closeout_body_v1", templates["tmpl_closeout"]),
        bytes_defn("demo_seed.visit_check_in_body_v1", check_in_doc),
        bytes_defn("demo_seed.visit_save_draft_body_v1", save_draft_doc),
        bytes_defn("demo_seed.visit_submit_body_v1", submit_doc),
        bytes_defn("demo_seed.visit_block_body_v1", block_doc),
        bytes_defn("demo_seed.visit_check_out_body_v1", check_out_doc),
        bytes_defn("demo_seed.attachment_register_body_v1", attachment_register_doc),
        bytes_defn("demo_seed.attachment_upload_body_v1", attachment_upload_doc),
    ],
}

(root / "tests" / "fixtures").mkdir(parents=True, exist_ok=True)
(root / "backend" / "src").mkdir(parents=True, exist_ok=True)

with (root / "tests" / "fixtures" / "demo_org.json").open("w", encoding="utf-8") as fh:
    json.dump(fixture, fh, indent=2)
    fh.write("\n")

with (root / "backend" / "src" / "demo_seed.x07.json").open("w", encoding="utf-8") as fh:
    json.dump(module, fh, indent=2)
    fh.write("\n")

print("wrote demo_org.json and backend/src/demo_seed.x07.json")
PY
