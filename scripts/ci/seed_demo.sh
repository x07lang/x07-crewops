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
APP_VERSION = "0.6.0"


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
users["user_portal_morgan"] = {
    "id": "user_portal_morgan",
    "role": "portal_user",
    "name": "Morgan Hale",
    "team_ids": [],
    "branch_id": "branch_north",
    "customer_id": "cust_020",
    "tenant_id": "tenant_northline",
    "portal_account_id": "portal_account_001",
}
users["user_enterprise_iris"] = {
    "id": "user_enterprise_iris",
    "role": "enterprise_admin",
    "name": "Iris Bennett",
    "team_ids": [],
    "branch_id": "branch_north",
    "tenant_id": "tenant_northline",
    "workspace_ids": [
        "workspace_hq",
        "workspace_branch_north",
        "workspace_branch_south",
    ],
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

price_books = {
    "price_book_branch_north": {
        "id": "price_book_branch_north",
        "scope": "branch",
        "branch_id": "branch_north",
        "customer_id": None,
        "name": "North Commercial Standard",
        "currency": "USD",
        "revision": 3,
        "effective_at": "2026-03-01T00:00:00Z",
        "tax_rule_id": "tax_rule_wa",
        "billing_policy_id": "billing_policy_branch_north",
    },
    "price_book_branch_south": {
        "id": "price_book_branch_south",
        "scope": "branch",
        "branch_id": "branch_south",
        "customer_id": None,
        "name": "South Commercial Standard",
        "currency": "USD",
        "revision": 2,
        "effective_at": "2026-03-01T00:00:00Z",
        "tax_rule_id": "tax_rule_or",
        "billing_policy_id": "billing_policy_branch_south",
    },
    "price_book_customer_cust_018": {
        "id": "price_book_customer_cust_018",
        "scope": "customer",
        "branch_id": "branch_south",
        "customer_id": "cust_018",
        "name": "Customer 18 Contract Override",
        "currency": "USD",
        "revision": 4,
        "effective_at": "2026-03-05T00:00:00Z",
        "tax_rule_id": "tax_rule_or",
        "billing_policy_id": "billing_policy_customer_cust_018",
    },
}

price_book_items = {
    "price_item_service_call_north": {
        "id": "price_item_service_call_north",
        "price_book_id": "price_book_branch_north",
        "kind": "service_fee",
        "code": "svc-call",
        "label": "Standard service call",
        "uom": "visit",
        "unit_rate": 145.0,
        "taxable": True,
    },
    "price_item_service_call_south": {
        "id": "price_item_service_call_south",
        "price_book_id": "price_book_branch_south",
        "kind": "service_fee",
        "code": "svc-call",
        "label": "Standard service call",
        "uom": "visit",
        "unit_rate": 135.0,
        "taxable": True,
    },
    "price_item_labor_standard_north": {
        "id": "price_item_labor_standard_north",
        "price_book_id": "price_book_branch_north",
        "kind": "labor",
        "code": "labor-std",
        "label": "Standard labor",
        "uom": "hour",
        "unit_rate": 96.0,
        "taxable": True,
    },
    "price_item_labor_standard_south": {
        "id": "price_item_labor_standard_south",
        "price_book_id": "price_book_branch_south",
        "kind": "labor",
        "code": "labor-std",
        "label": "Standard labor",
        "uom": "hour",
        "unit_rate": 92.0,
        "taxable": True,
    },
    "price_item_travel_north": {
        "id": "price_item_travel_north",
        "price_book_id": "price_book_branch_north",
        "kind": "travel",
        "code": "travel-a",
        "label": "Zone A travel fee",
        "uom": "visit",
        "unit_rate": 28.0,
        "taxable": True,
    },
    "price_item_travel_south": {
        "id": "price_item_travel_south",
        "price_book_id": "price_book_branch_south",
        "kind": "travel",
        "code": "travel-a",
        "label": "Zone A travel fee",
        "uom": "visit",
        "unit_rate": 24.0,
        "taxable": True,
    },
}

labor_rate_policies = {
    "labor_policy_branch_north": {
        "id": "labor_policy_branch_north",
        "branch_id": "branch_north",
        "default_category": "standard",
        "hourly_rate": 96.0,
        "overtime_hourly_rate": 132.0,
        "minimum_minutes": 60,
    },
    "labor_policy_branch_south": {
        "id": "labor_policy_branch_south",
        "branch_id": "branch_south",
        "default_category": "standard",
        "hourly_rate": 92.0,
        "overtime_hourly_rate": 126.0,
        "minimum_minutes": 60,
    },
}

part_rate_policies = {
    "part_rate_north_filter": {
        "id": "part_rate_north_filter",
        "branch_id": "branch_north",
        "part_id": "part_filter_merv13",
        "unit_rate": 26.0,
    },
    "part_rate_north_belt": {
        "id": "part_rate_north_belt",
        "branch_id": "branch_north",
        "part_id": "part_belt_a42",
        "unit_rate": 21.0,
    },
    "part_rate_north_cleaner": {
        "id": "part_rate_north_cleaner",
        "branch_id": "branch_north",
        "part_id": "part_contact_cleaner",
        "unit_rate": 12.5,
    },
    "part_rate_south_filter": {
        "id": "part_rate_south_filter",
        "branch_id": "branch_south",
        "part_id": "part_filter_merv13",
        "unit_rate": 24.5,
    },
    "part_rate_south_belt": {
        "id": "part_rate_south_belt",
        "branch_id": "branch_south",
        "part_id": "part_belt_a42",
        "unit_rate": 19.5,
    },
    "part_rate_south_cleaner": {
        "id": "part_rate_south_cleaner",
        "branch_id": "branch_south",
        "part_id": "part_contact_cleaner",
        "unit_rate": 11.5,
    },
}

billing_policies = {
    "billing_policy_branch_north": {
        "id": "billing_policy_branch_north",
        "scope": "branch",
        "branch_id": "branch_north",
        "customer_id": None,
        "default_labor_policy_id": "labor_policy_branch_north",
        "default_price_book_id": "price_book_branch_north",
        "minimum_charge": 145.0,
        "travel_fee_behavior": "flat_per_visit",
        "invoice_terms_days": 15,
        "currency": "USD",
        "auto_generate_invoice_on_approval": True,
    },
    "billing_policy_branch_south": {
        "id": "billing_policy_branch_south",
        "scope": "branch",
        "branch_id": "branch_south",
        "customer_id": None,
        "default_labor_policy_id": "labor_policy_branch_south",
        "default_price_book_id": "price_book_branch_south",
        "minimum_charge": 135.0,
        "travel_fee_behavior": "flat_per_visit",
        "invoice_terms_days": 21,
        "currency": "USD",
        "auto_generate_invoice_on_approval": True,
    },
    "billing_policy_customer_cust_018": {
        "id": "billing_policy_customer_cust_018",
        "scope": "customer",
        "branch_id": "branch_south",
        "customer_id": "cust_018",
        "default_labor_policy_id": "labor_policy_branch_south",
        "default_price_book_id": "price_book_customer_cust_018",
        "minimum_charge": 125.0,
        "travel_fee_behavior": "waived",
        "invoice_terms_days": 10,
        "currency": "USD",
        "auto_generate_invoice_on_approval": True,
    },
}

tax_rules = {
    "tax_rule_wa": {
        "id": "tax_rule_wa",
        "branch_id": "branch_north",
        "label": "WA sales tax",
        "rate_pct": 10.1,
        "inclusive": False,
    },
    "tax_rule_or": {
        "id": "tax_rule_or",
        "branch_id": "branch_south",
        "label": "OR sales tax",
        "rate_pct": 0.0,
        "inclusive": False,
    },
}

discount_rules = {
    "discount_rule_loyalty": {
        "id": "discount_rule_loyalty",
        "kind": "percent",
        "value": 5.0,
        "label": "Loyalty discount",
    },
    "discount_rule_pm_bundle": {
        "id": "discount_rule_pm_bundle",
        "kind": "flat",
        "value": 18.0,
        "label": "Bundle credit",
    },
    "discount_rule_municipal": {
        "id": "discount_rule_municipal",
        "kind": "percent",
        "value": 7.5,
        "label": "Municipal services discount",
    },
}

invoice_artifacts = {}
service_summary_artifacts = {}
invoices = {}
invoice_lines = {}
invoice_adjustments = {}
payment_records = {}
payment_allocations = {}
customer_statements = {}
receivable_summaries = {}
export_jobs = {}
finance_rollups = {}
profitability_snapshots = {}


def part_rate_for(branch_id, part_id):
    for policy in part_rate_policies.values():
        if policy["branch_id"] == branch_id and policy["part_id"] == part_id:
            return policy["unit_rate"]
    return 0.0


def tax_rate_for(branch_id):
    return tax_rules["tax_rule_wa"]["rate_pct"] if branch_id == "branch_north" else tax_rules["tax_rule_or"]["rate_pct"]


def discount_amount_for_rule(rule_id, subtotal):
    if rule_id is None:
        return 0.0
    rule = discount_rules[rule_id]
    if rule["kind"] == "percent":
        return round(subtotal * rule["value"] / 100.0, 2)
    return round(rule["value"], 2)


def visit_id_for_work_order(work_order_id):
    return f"visit_{work_order_id.split('_')[1]}"


def add_invoice(blueprint):
    invoice_id = blueprint["id"]
    work_order_ids = blueprint["work_order_ids"]
    source_work_order = work_orders[work_order_ids[0]]
    customer_id = blueprint.get("customer_id", source_work_order["customer_id"])
    branch_id = blueprint.get("branch_id", source_work_order["branch_id"])
    team_id = blueprint.get("team_id", source_work_order["team_id"])
    billing_policy_id = blueprint.get(
        "billing_policy_id",
        "billing_policy_branch_north" if branch_id == "branch_north" else "billing_policy_branch_south",
    )
    price_book_id = blueprint.get(
        "price_book_id",
        "price_book_branch_north" if branch_id == "branch_north" else "price_book_branch_south",
    )
    tax_rule_id = blueprint.get(
        "tax_rule_id",
        "tax_rule_wa" if branch_id == "branch_north" else "tax_rule_or",
    )
    line_ids = []
    subtotal = 0.0
    taxable_subtotal = 0.0
    first_work_order_id = work_order_ids[0]
    first_visit_id = visit_id_for_work_order(first_work_order_id)
    line_specs = [
        {
            "suffix": "service",
            "kind": "service_fee",
            "description": "Standard service call",
            "quantity": 1.0,
            "unit_rate": blueprint["service_fee"],
            "taxable": True,
            "source_work_order_id": first_work_order_id,
            "source_visit_id": first_visit_id,
        },
        {
            "suffix": "labor",
            "kind": "labor",
            "description": blueprint.get("labor_label", "Standard labor"),
            "quantity": blueprint["labor_hours"],
            "unit_rate": blueprint["labor_rate"],
            "taxable": True,
            "source_work_order_id": first_work_order_id,
            "source_visit_id": first_visit_id,
        },
        {
            "suffix": "travel",
            "kind": "travel",
            "description": "Zone A travel fee",
            "quantity": 1.0,
            "unit_rate": blueprint["travel_fee"],
            "taxable": True,
            "source_work_order_id": first_work_order_id,
            "source_visit_id": first_visit_id,
        },
    ]
    for index, part_usage in enumerate(blueprint.get("parts", []), start=1):
        line_specs.append(
            {
                "suffix": f"part_{index}",
                "kind": "part",
                "description": parts_catalog[part_usage["part_id"]]["name"],
                "quantity": float(part_usage["qty"]),
                "unit_rate": float(part_usage["unit_rate"]),
                "taxable": True,
                "source_work_order_id": part_usage.get("source_work_order_id", first_work_order_id),
                "source_visit_id": visit_id_for_work_order(
                    part_usage.get("source_work_order_id", first_work_order_id)
                ),
            }
        )
    for line_spec in line_specs:
        line_id = f"invoice_line_{invoice_id}_{line_spec['suffix']}"
        amount = round(line_spec["quantity"] * line_spec["unit_rate"], 2)
        invoice_lines[line_id] = {
            "id": line_id,
            "invoice_id": invoice_id,
            "kind": line_spec["kind"],
            "description": line_spec["description"],
            "quantity": line_spec["quantity"],
            "unit_rate": line_spec["unit_rate"],
            "amount": amount,
            "taxable": line_spec["taxable"],
            "source_work_order_id": line_spec["source_work_order_id"],
            "source_visit_id": line_spec["source_visit_id"],
        }
        line_ids.append(line_id)
        subtotal = round(subtotal + amount, 2)
        if line_spec["taxable"]:
            taxable_subtotal = round(taxable_subtotal + amount, 2)

    adjustment_ids = []
    discount_total = discount_amount_for_rule(blueprint.get("discount_rule_id"), subtotal)
    if discount_total:
        discount_id = f"invoice_adjustment_{invoice_id}_discount"
        invoice_adjustments[discount_id] = {
            "id": discount_id,
            "invoice_id": invoice_id,
            "kind": "discount",
            "label": discount_rules[blueprint["discount_rule_id"]]["label"],
            "amount": discount_total,
        }
        adjustment_ids.append(discount_id)
    manual_credit = round(float(blueprint.get("manual_credit", 0.0)), 2)
    if manual_credit:
        credit_id = f"invoice_adjustment_{invoice_id}_credit"
        invoice_adjustments[credit_id] = {
            "id": credit_id,
            "invoice_id": invoice_id,
            "kind": "credit",
            "label": "Service recovery credit",
            "amount": manual_credit,
        }
        adjustment_ids.append(credit_id)
    taxable_after_discount = max(round(taxable_subtotal - discount_total - manual_credit, 2), 0.0)
    tax_total = round(taxable_after_discount * tax_rate_for(branch_id) / 100.0, 2)
    if tax_total:
        tax_id = f"invoice_adjustment_{invoice_id}_tax"
        invoice_adjustments[tax_id] = {
            "id": tax_id,
            "invoice_id": invoice_id,
            "kind": "tax",
            "label": tax_rules[tax_rule_id]["label"],
            "amount": tax_total,
        }
        adjustment_ids.append(tax_id)
    total = round(subtotal - discount_total - manual_credit + tax_total, 2)
    aging_bucket = blueprint.get("aging_bucket", "current")
    issue_date = blueprint["issue_date"]
    sent_at = blueprint.get("sent_at")
    invoice_artifact_id = f"invoice_artifact_{invoice_id}"
    service_summary_artifact_id = f"service_summary_{invoice_id}"
    invoice_artifacts[invoice_artifact_id] = {
        "id": invoice_artifact_id,
        "invoice_id": invoice_id,
        "status": blueprint.get("invoice_artifact_status", "ready"),
        "format": "pdf",
        "file_name": f"{blueprint['number'].lower()}.pdf",
        "download_path": f"/artifacts/invoices/{invoice_id}.pdf",
        "render_input_hash": f"hash_{invoice_id}",
        "generated_at": blueprint.get("artifact_generated_at", now),
        "retryable": blueprint.get("invoice_artifact_status", "ready") != "ready",
        "error_code": blueprint.get("invoice_artifact_error_code"),
        "error_message": blueprint.get("invoice_artifact_error_message"),
    }
    service_summary_artifacts[service_summary_artifact_id] = {
        "id": service_summary_artifact_id,
        "invoice_id": invoice_id,
        "work_order_ids": work_order_ids,
        "status": blueprint.get("service_summary_status", "ready"),
        "format": "pdf",
        "file_name": f"{invoice_id}_service_summary.pdf",
        "download_path": f"/artifacts/service-summaries/{invoice_id}.pdf",
        "generated_at": blueprint.get("service_summary_generated_at", now),
        "retryable": blueprint.get("service_summary_status", "ready") != "ready",
        "error_code": blueprint.get("service_summary_error_code"),
        "error_message": blueprint.get("service_summary_error_message"),
    }
    invoices[invoice_id] = {
        "id": invoice_id,
        "number": blueprint["number"],
        "status": blueprint["status"],
        "revision": blueprint.get("revision", 1),
        "lock_status": blueprint.get(
            "lock_status",
            "editable" if blueprint["status"] in {"draft", "pending_review"} else "locked",
        ),
        "lock_reason": blueprint.get("lock_reason"),
        "branch_id": branch_id,
        "team_id": team_id,
        "customer_id": customer_id,
        "currency": "USD",
        "price_book_id": price_book_id,
        "billing_policy_id": billing_policy_id,
        "tax_rule_id": tax_rule_id,
        "discount_rule_id": blueprint.get("discount_rule_id"),
        "issue_date": issue_date,
        "due_date": blueprint["due_date"],
        "sent_at": sent_at,
        "paid_at": blueprint.get("paid_at"),
        "voided_at": blueprint.get("voided_at"),
        "written_off_at": blueprint.get("written_off_at"),
        "source_work_order_ids": work_order_ids,
        "source_visit_ids": [visit_id_for_work_order(work_order_id) for work_order_id in work_order_ids],
        "memo": blueprint["memo"],
        "line_ids": line_ids,
        "adjustment_ids": adjustment_ids,
        "payment_ids": [],
        "invoice_artifact_id": invoice_artifact_id,
        "service_summary_artifact_id": service_summary_artifact_id,
        "subtotal": subtotal,
        "discount_total": round(discount_total + manual_credit, 2),
        "tax_total": tax_total,
        "total": total,
        "paid_total": 0.0,
        "balance_due": total,
        "aging_bucket": aging_bucket,
    }
    return invoice_id


invoice_blueprints = [
    {
        "id": "inv_001",
        "number": "INV-4001",
        "status": "draft",
        "work_order_ids": ["wo_013"],
        "issue_date": "2026-03-15",
        "due_date": "2026-03-30",
        "service_fee": 145.0,
        "labor_hours": 1.75,
        "labor_rate": 96.0,
        "travel_fee": 28.0,
        "parts": [{"part_id": "part_filter_merv13", "qty": 1, "unit_rate": 26.0}],
        "memo": "Drafted from approved PM visit pending office review.",
        "aging_bucket": "current",
    },
    {
        "id": "inv_002",
        "number": "INV-4002",
        "status": "pending_review",
        "work_order_ids": ["wo_014"],
        "issue_date": "2026-03-16",
        "due_date": "2026-03-31",
        "service_fee": 145.0,
        "labor_hours": 2.25,
        "labor_rate": 96.0,
        "travel_fee": 28.0,
        "parts": [{"part_id": "part_belt_a42", "qty": 1, "unit_rate": 21.0}],
        "discount_rule_id": "discount_rule_pm_bundle",
        "memo": "Awaiting billing supervisor review after technician correction notes.",
        "aging_bucket": "current",
    },
    {
        "id": "inv_003",
        "number": "INV-4003",
        "status": "issued",
        "work_order_ids": ["wo_015"],
        "issue_date": "2026-03-10",
        "due_date": "2026-03-25",
        "service_fee": 135.0,
        "labor_hours": 2.0,
        "labor_rate": 92.0,
        "travel_fee": 24.0,
        "parts": [{"part_id": "part_filter_merv13", "qty": 2, "unit_rate": 24.5}],
        "memo": "Issued and ready to send to customer.",
        "aging_bucket": "current",
        "lock_status": "revision_sensitive",
    },
    {
        "id": "inv_004",
        "number": "INV-4004",
        "status": "sent",
        "work_order_ids": ["wo_018"],
        "issue_date": "2026-03-13",
        "due_date": "2026-03-23",
        "sent_at": "2026-03-13T16:30:00Z",
        "service_fee": 125.0,
        "labor_hours": 1.5,
        "labor_rate": 88.0,
        "travel_fee": 0.0,
        "parts": [{"part_id": "part_filter_merv13", "qty": 1, "unit_rate": 23.0}],
        "price_book_id": "price_book_customer_cust_018",
        "billing_policy_id": "billing_policy_customer_cust_018",
        "memo": "Sent under contracted South branch customer override.",
        "aging_bucket": "current",
        "lock_status": "revision_sensitive",
    },
    {
        "id": "inv_005",
        "number": "INV-4005",
        "status": "partially_paid",
        "work_order_ids": ["wo_019"],
        "issue_date": "2026-03-14",
        "due_date": "2026-03-29",
        "sent_at": "2026-03-14T18:00:00Z",
        "service_fee": 145.0,
        "labor_hours": 2.5,
        "labor_rate": 96.0,
        "travel_fee": 28.0,
        "parts": [{"part_id": "part_belt_a42", "qty": 1, "unit_rate": 21.0}],
        "discount_rule_id": "discount_rule_loyalty",
        "memo": "Customer submitted deposit; remainder still outstanding.",
        "aging_bucket": "1_30",
        "lock_status": "locked",
    },
    {
        "id": "inv_006",
        "number": "INV-4006",
        "status": "paid",
        "work_order_ids": ["wo_024"],
        "issue_date": "2026-03-12",
        "due_date": "2026-03-27",
        "sent_at": "2026-03-12T17:10:00Z",
        "paid_at": "2026-03-17T14:45:00Z",
        "service_fee": 135.0,
        "labor_hours": 2.0,
        "labor_rate": 92.0,
        "travel_fee": 24.0,
        "parts": [{"part_id": "part_filter_merv13", "qty": 1, "unit_rate": 24.5}],
        "memo": "Paid in full by branch procurement card.",
        "aging_bucket": "current",
        "lock_status": "locked",
    },
    {
        "id": "inv_007",
        "number": "INV-4007",
        "status": "overdue",
        "work_order_ids": ["wo_013", "wo_019"],
        "customer_id": "cust_013",
        "team_id": "team_north_alpha",
        "issue_date": "2026-02-05",
        "due_date": "2026-02-20",
        "sent_at": "2026-02-05T15:30:00Z",
        "service_fee": 145.0,
        "labor_hours": 3.0,
        "labor_rate": 96.0,
        "travel_fee": 28.0,
        "parts": [
            {"part_id": "part_filter_merv13", "qty": 2, "unit_rate": 26.0},
            {"part_id": "part_contact_cleaner", "qty": 1, "unit_rate": 12.5},
        ],
        "memo": "Past due balance driving the North branch aging bucket.",
        "aging_bucket": "31_60",
        "lock_status": "locked",
        "invoice_artifact_status": "failed",
        "invoice_artifact_error_code": "render_template_missing",
        "invoice_artifact_error_message": "Invoice PDF render template was unavailable.",
    },
    {
        "id": "inv_008",
        "number": "INV-4008",
        "status": "voided",
        "work_order_ids": ["wo_015"],
        "issue_date": "2026-02-18",
        "due_date": "2026-03-04",
        "sent_at": "2026-02-18T12:10:00Z",
        "voided_at": "2026-02-19T09:00:00Z",
        "service_fee": 135.0,
        "labor_hours": 1.0,
        "labor_rate": 92.0,
        "travel_fee": 24.0,
        "parts": [],
        "manual_credit": 24.0,
        "memo": "Voided after duplicate issue and reopened under a corrected draft.",
        "aging_bucket": "current",
        "lock_status": "locked",
    },
    {
        "id": "inv_009",
        "number": "INV-4009",
        "status": "written_off",
        "work_order_ids": ["wo_024"],
        "customer_id": "cust_004",
        "branch_id": "branch_south",
        "team_id": "team_south_gamma",
        "issue_date": "2026-01-10",
        "due_date": "2026-01-31",
        "sent_at": "2026-01-10T11:20:00Z",
        "written_off_at": "2026-03-01T08:30:00Z",
        "service_fee": 135.0,
        "labor_hours": 1.5,
        "labor_rate": 92.0,
        "travel_fee": 24.0,
        "parts": [{"part_id": "part_belt_a42", "qty": 1, "unit_rate": 19.5}],
        "memo": "Legacy balance written off after approved service credit.",
        "aging_bucket": "61_plus",
        "lock_status": "locked",
    },
]

for blueprint in invoice_blueprints:
    add_invoice(blueprint)


def add_payment(payment_id, invoice_id, amount, method, received_at, external_ref, unapplied_amount=0.0, reversal_of=None):
    invoice = invoices[invoice_id]
    allocation_id = f"payment_allocation_{payment_id}"
    applied_amount = round(float(amount) - float(unapplied_amount), 2)
    payment_records[payment_id] = {
        "id": payment_id,
        "invoice_id": invoice_id,
        "customer_id": invoice["customer_id"],
        "branch_id": invoice["branch_id"],
        "amount": round(float(amount), 2),
        "applied_amount": applied_amount,
        "unapplied_amount": round(float(unapplied_amount), 2),
        "method": method,
        "received_at": received_at,
        "external_ref": external_ref,
        "status": "posted" if reversal_of is None else "reversal",
        "reversal_of": reversal_of,
    }
    if applied_amount > 0:
        payment_allocations[allocation_id] = {
            "id": allocation_id,
            "payment_id": payment_id,
            "invoice_id": invoice_id,
            "amount": applied_amount,
            "applied_at": received_at,
        }
    invoice["payment_ids"].append(payment_id)
    invoice["paid_total"] = round(invoice["paid_total"] + applied_amount, 2)
    invoice["balance_due"] = round(max(invoice["total"] - invoice["paid_total"], 0.0), 2)


add_payment(
    "payment_005_a",
    "inv_005",
    220.0,
    "ach",
    "2026-03-16T14:10:00Z",
    "ACH-55201",
)
add_payment(
    "payment_006_a",
    "inv_006",
    invoices["inv_006"]["total"],
    "card",
    "2026-03-17T14:45:00Z",
    "CARD-99021",
)
add_payment(
    "payment_007_a",
    "inv_007",
    90.0,
    "check",
    "2026-02-10T17:00:00Z",
    "CHK-4420",
)

for invoice in invoices.values():
    if invoice["status"] == "partially_paid" and invoice["balance_due"] <= 0:
        invoice["status"] = "paid"
    if invoice["status"] == "paid" and invoice["paid_total"] <= 0:
        invoice["paid_total"] = invoice["total"]
        invoice["balance_due"] = 0.0

for invoice in invoices.values():
    customer_id = invoice["customer_id"]
    statement_id = f"statement_{customer_id}"
    statement = customer_statements.setdefault(
        statement_id,
        {
            "id": statement_id,
            "customer_id": customer_id,
            "currency": "USD",
            "statement_date": now,
            "invoice_ids": [],
            "payment_ids": [],
            "current_balance": 0.0,
            "overdue_balance": 0.0,
            "aging_buckets": {"current": 0.0, "1_30": 0.0, "31_60": 0.0, "61_plus": 0.0},
        },
    )
    statement["invoice_ids"].append(invoice["id"])
    statement["current_balance"] = round(statement["current_balance"] + invoice["balance_due"], 2)
    statement["aging_buckets"][invoice["aging_bucket"]] = round(
        statement["aging_buckets"][invoice["aging_bucket"]] + invoice["balance_due"], 2
    )
    if invoice["aging_bucket"] != "current":
        statement["overdue_balance"] = round(statement["overdue_balance"] + invoice["balance_due"], 2)
for payment in payment_records.values():
    statement_id = f"statement_{payment['customer_id']}"
    if statement_id in customer_statements:
        customer_statements[statement_id]["payment_ids"].append(payment["id"])

for branch in branches:
    branch_invoices = [invoice for invoice in invoices.values() if invoice["branch_id"] == branch["id"]]
    summary_id = f"receivable_{branch['id']}"
    receivable_summaries[summary_id] = {
        "id": summary_id,
        "scope": "branch",
        "branch_id": branch["id"],
        "customer_id": None,
        "open_invoice_count": len([invoice for invoice in branch_invoices if invoice["balance_due"] > 0]),
        "overdue_invoice_count": len(
            [invoice for invoice in branch_invoices if invoice["status"] in {"overdue", "written_off"}]
        ),
        "current_balance": round(sum(invoice["balance_due"] for invoice in branch_invoices), 2),
        "overdue_balance": round(
            sum(
                invoice["balance_due"]
                for invoice in branch_invoices
                if invoice["aging_bucket"] in {"1_30", "31_60", "61_plus"}
            ),
            2,
        ),
    }
for statement in customer_statements.values():
    receivable_summaries[f"receivable_{statement['customer_id']}"] = {
        "id": f"receivable_{statement['customer_id']}",
        "scope": "customer",
        "branch_id": customers[statement["customer_id"]]["branch_id"],
        "customer_id": statement["customer_id"],
        "open_invoice_count": len(statement["invoice_ids"]),
        "overdue_invoice_count": len(
            [
                invoice_id
                for invoice_id in statement["invoice_ids"]
                if invoices[invoice_id]["aging_bucket"] in {"1_30", "31_60", "61_plus"}
            ]
        ),
        "current_balance": statement["current_balance"],
        "overdue_balance": statement["overdue_balance"],
    }


def line_totals_for_invoice(invoice_id):
    totals = {"labor": 0.0, "parts": 0.0, "service_fee": 0.0, "travel": 0.0}
    for line_id in invoices[invoice_id]["line_ids"]:
        line = invoice_lines[line_id]
        kind = "parts" if line["kind"] == "part" else line["kind"]
        totals[kind] = round(totals.get(kind, 0.0) + line["amount"], 2)
    return totals


def add_finance_rollup(rollup_id, scope, branch_id=None, team_id=None):
    selected = [
        invoice
        for invoice in invoices.values()
        if (branch_id is None or invoice["branch_id"] == branch_id)
        and (team_id is None or invoice["team_id"] == team_id)
    ]
    if not selected:
        return
    revenue_total = round(
        sum(invoice["total"] for invoice in selected if invoice["status"] not in {"voided", "written_off"}),
        2,
    )
    paid_total = round(sum(invoice["paid_total"] for invoice in selected), 2)
    receivable_total = round(sum(invoice["balance_due"] for invoice in selected), 2)
    overdue_total = round(
        sum(
            invoice["balance_due"]
            for invoice in selected
            if invoice["aging_bucket"] in {"1_30", "31_60", "61_plus"}
        ),
        2,
    )
    status_counts = {}
    totals_by_kind = {"labor": 0.0, "parts": 0.0, "service_fee": 0.0, "travel": 0.0}
    for invoice in selected:
        status_counts[invoice["status"]] = status_counts.get(invoice["status"], 0) + 1
        for kind, amount in line_totals_for_invoice(invoice["id"]).items():
            totals_by_kind[kind] = round(totals_by_kind.get(kind, 0.0) + amount, 2)
    average_ticket = round(revenue_total / max(len(selected), 1), 2)
    finance_rollups[rollup_id] = {
        "id": rollup_id,
        "scope": scope,
        "branch_id": branch_id,
        "team_id": team_id,
        "revenue_total": revenue_total,
        "paid_total": paid_total,
        "receivable_total": receivable_total,
        "overdue_total": overdue_total,
        "average_ticket": average_ticket,
        "invoice_status_counts": status_counts,
        "revenue_breakdown": totals_by_kind,
    }
    estimated_cost = round(totals_by_kind["labor"] * 0.52 + totals_by_kind["parts"] * 0.64 + totals_by_kind["travel"] * 0.35, 2)
    gross_margin = round(revenue_total - estimated_cost, 2)
    profitability_snapshots[rollup_id] = {
        "id": rollup_id,
        "scope": scope,
        "branch_id": branch_id,
        "team_id": team_id,
        "revenue_total": revenue_total,
        "estimated_cost_total": estimated_cost,
        "gross_margin_total": gross_margin,
        "gross_margin_pct": round((gross_margin / revenue_total) * 100.0, 2) if revenue_total else 0.0,
    }


add_finance_rollup("finance_global", "global")
for branch in branches:
    add_finance_rollup(f"finance_{branch['id']}", "branch", branch_id=branch["id"])
for team in teams:
    add_finance_rollup(f"finance_{team['id']}", "team", branch_id=team["branch_id"], team_id=team["id"])

export_jobs = {
    "export_job_001": {
        "id": "export_job_001",
        "kind": "invoices",
        "format": "csv",
        "status": "completed",
        "requested_by_user_id": "user_manager_jonas",
        "requested_at": "2026-03-11T08:15:00Z",
        "completed_at": "2026-03-11T08:16:00Z",
        "filters": {"branch_id": "branch_north", "status": "open", "date_from": "2026-03-01", "date_to": "2026-03-31"},
        "artifact_path": "/exports/export_job_001.csv",
        "record_count": 5,
        "data_revision": "finance_rev_2026_03_11_001",
        "retry_count": 0,
    },
    "export_job_002": {
        "id": "export_job_002",
        "kind": "receivables",
        "format": "json",
        "status": "failed",
        "requested_by_user_id": "user_manager_jonas",
        "requested_at": "2026-03-11T08:30:00Z",
        "completed_at": "2026-03-11T08:31:00Z",
        "filters": {"branch_id": "branch_south", "aging_bucket": "31_60", "status": "open"},
        "artifact_path": None,
        "record_count": 0,
        "data_revision": "finance_rev_2026_03_11_001",
        "retry_count": 1,
        "error_code": "export_render_failed",
        "error_message": "CSV writer exhausted the attachment manifest buffer.",
    },
    "export_job_003": {
        "id": "export_job_003",
        "kind": "profitability",
        "format": "json",
        "status": "running",
        "requested_by_user_id": "user_manager_jonas",
        "requested_at": "2026-03-11T08:45:00Z",
        "completed_at": None,
        "filters": {"scope": "global", "status": "all"},
        "artifact_path": None,
        "record_count": 0,
        "data_revision": "finance_rev_2026_03_11_002",
        "retry_count": 0,
    },
}

estimate_lines = {}
estimate_versions = {}
estimate_approvals = {}
proposal_artifacts = {}
estimates = {}


def estimate_version_id(estimate_id, revision):
    return f"estimate_version_{estimate_id}_r{revision}"


def build_estimate_bundle(blueprint):
    bundle_lines = {}
    bundle_versions = {}
    bundle_approvals = {}
    version_ids = []
    latest_shared_revision = blueprint.get("latest_shared_revision")
    approved_revision = blueprint.get("approved_revision")
    price_book_id = blueprint.get("price_book_id", f"price_book_{blueprint['branch_id']}")
    billing_policy_id = blueprint.get("billing_policy_id", f"billing_policy_{blueprint['branch_id']}")
    tax_rule_id = blueprint.get("tax_rule_id", "tax_rule_wa")
    discount_rule_id = blueprint.get("discount_rule_id", "discount_rule_loyalty")

    for version in blueprint["versions"]:
        version_id = estimate_version_id(blueprint["id"], version["revision"])
        version_ids.append(version_id)
        line_ids = []
        labor_subtotal = 0.0
        parts_subtotal = 0.0
        service_fee_total = 0.0
        travel_total = 0.0
        subtotal = 0.0

        for line_idx, line_spec in enumerate(version["lines"], start=1):
            line_id = f"estimate_line_{blueprint['id']}_r{version['revision']}_{line_idx:02d}"
            amount = round(line_spec["quantity"] * line_spec["unit_price"], 2)
            bundle_lines[line_id] = {
                "id": line_id,
                "estimate_version_id": version_id,
                "kind": line_spec["kind"],
                "description": line_spec["description"],
                "quantity": line_spec["quantity"],
                "uom": line_spec["uom"],
                "unit_price": line_spec["unit_price"],
                "amount": amount,
                "part_id": line_spec.get("part_id"),
            }
            line_ids.append(line_id)
            subtotal = round(subtotal + amount, 2)
            if line_spec["kind"] == "labor":
                labor_subtotal = round(labor_subtotal + amount, 2)
            elif line_spec["kind"] == "part":
                parts_subtotal = round(parts_subtotal + amount, 2)
            elif line_spec["kind"] == "service_fee":
                service_fee_total = round(service_fee_total + amount, 2)
            elif line_spec["kind"] == "travel":
                travel_total = round(travel_total + amount, 2)

        discount_total = round(subtotal * version.get("discount_rate", 0.0), 2)
        taxable_subtotal = round(subtotal - discount_total, 2)
        tax_total = round(taxable_subtotal * version.get("tax_rate", 0.0), 2)
        total = round(taxable_subtotal + tax_total, 2)

        bundle_versions[version_id] = {
            "id": version_id,
            "estimate_id": blueprint["id"],
            "revision": version["revision"],
            "state": version["state"],
            "created_at": version["created_at"],
            "created_by_user_id": version["created_by_user_id"],
            "shared_at": version.get("shared_at"),
            "line_ids": line_ids,
            "notes": version.get("notes", ""),
            "terms": version.get("terms", ""),
            "expiration_date": version.get("expiration_date", blueprint["expiration_date"]),
            "price_book_id": price_book_id,
            "billing_policy_id": billing_policy_id,
            "tax_rule_id": tax_rule_id,
            "discount_rule_id": discount_rule_id,
            "labor_subtotal": labor_subtotal,
            "parts_subtotal": parts_subtotal,
            "service_fee_total": service_fee_total,
            "travel_total": travel_total,
            "subtotal": subtotal,
            "discount_total": discount_total,
            "tax_total": tax_total,
            "total": total,
            "margin_note": version.get("margin_note"),
        }

    proposal_artifact_id = f"proposal_artifact_{blueprint['id']}"
    proposal_artifact = {
        "id": proposal_artifact_id,
        "estimate_id": blueprint["id"],
        "estimate_version_id": estimate_version_id(
            blueprint["id"],
            blueprint.get(
                "artifact_revision",
                latest_shared_revision or blueprint["current_revision"],
            ),
        ),
        "status": blueprint.get("artifact_status", "ready"),
        "printable_path": (
            f"/artifacts/proposals/{blueprint['id']}.pdf"
            if blueprint.get("artifact_status", "ready") != "draft"
            else None
        ),
        "json_path": f"/artifacts/proposals/{blueprint['id']}.json",
        "generated_at": blueprint.get("artifact_generated_at"),
        "retryable": blueprint.get("artifact_status", "ready") == "failed",
        "error_code": blueprint.get("artifact_error_code"),
        "error_message": blueprint.get("artifact_error_message"),
    }

    approval_ids = []
    for approval_idx, approval in enumerate(blueprint.get("approvals", []), start=1):
        approval_id = f"estimate_approval_{blueprint['id']}_{approval_idx:02d}"
        bundle_approvals[approval_id] = {
            "id": approval_id,
            "estimate_id": blueprint["id"],
            "estimate_version_id": estimate_version_id(
                blueprint["id"],
                approval["revision"],
            ),
            "state": approval["state"],
            "customer_name": approval["customer_name"],
            "captured_at": approval["captured_at"],
            "channel": approval["channel"],
            "signature_ref": approval.get("signature_ref"),
            "note": approval.get("note", ""),
            "reason": approval.get("reason"),
        }
        approval_ids.append(approval_id)

    current_version_id = estimate_version_id(blueprint["id"], blueprint["current_revision"])
    current_version = bundle_versions[current_version_id]
    estimate_doc = {
        "id": blueprint["id"],
        "number": blueprint["number"],
        "status": blueprint["status"],
        "customer_id": blueprint["customer_id"],
        "site_id": blueprint["site_id"],
        "asset_id": blueprint.get("asset_id"),
        "branch_id": blueprint["branch_id"],
        "team_id": blueprint["team_id"],
        "source_work_order_id": blueprint.get("source_work_order_id"),
        "source_visit_id": blueprint.get("source_visit_id"),
        "currency": blueprint.get("currency", "USD"),
        "current_version_id": current_version_id,
        "latest_shared_version_id": (
            estimate_version_id(blueprint["id"], latest_shared_revision)
            if latest_shared_revision is not None
            else None
        ),
        "approved_version_id": (
            estimate_version_id(blueprint["id"], approved_revision)
            if approved_revision is not None
            else None
        ),
        "version_ids": version_ids,
        "approval_ids": approval_ids,
        "proposal_artifact_id": proposal_artifact_id,
        "price_book_id": price_book_id,
        "billing_policy_id": billing_policy_id,
        "tax_rule_id": tax_rule_id,
        "discount_rule_id": discount_rule_id,
        "created_at": blueprint["created_at"],
        "updated_at": blueprint.get("updated_at", blueprint["created_at"]),
        "sent_at": blueprint.get("sent_at"),
        "viewed_at": blueprint.get("viewed_at"),
        "approved_at": blueprint.get("approved_at"),
        "rejected_at": blueprint.get("rejected_at"),
        "converted_at": blueprint.get("converted_at"),
        "expiration_date": blueprint["expiration_date"],
        "approval_state": blueprint.get("approval_state", "not_requested"),
        "linked_work_order_id": blueprint.get("linked_work_order_id"),
        "linked_agreement_id": blueprint.get("linked_agreement_id"),
        "origin": blueprint.get("origin", "backoffice"),
        "subtotal": current_version["subtotal"],
        "discount_total": current_version["discount_total"],
        "tax_total": current_version["tax_total"],
        "total": current_version["total"],
    }

    return {
        "estimate": estimate_doc,
        "versions": bundle_versions,
        "lines": bundle_lines,
        "approvals": bundle_approvals,
        "proposal_artifact": proposal_artifact,
    }


estimate_blueprints = [
    {
        "id": "est_001",
        "number": "EST-6001",
        "status": "draft",
        "customer_id": "cust_006",
        "site_id": "site_006",
        "asset_id": "asset_006",
        "branch_id": "branch_south",
        "team_id": "team_south_gamma",
        "source_work_order_id": "wo_006",
        "created_at": "2026-03-06T15:10:00Z",
        "updated_at": "2026-03-11T09:20:00Z",
        "expiration_date": "2026-04-12",
        "current_revision": 2,
        "latest_shared_revision": 1,
        "artifact_status": "draft",
        "versions": [
            {
                "revision": 1,
                "state": "superseded",
                "created_at": "2026-03-06T15:10:00Z",
                "created_by_user_id": "user_manager_jonas",
                "shared_at": "2026-03-07T17:00:00Z",
                "discount_rate": 0.03,
                "tax_rate": 0.101,
                "notes": "Filter replacement and belt inspection.",
                "terms": "Net 15.",
                "margin_note": "Bundle with PM follow-up.",
                "lines": [
                    {
                        "kind": "service_fee",
                        "description": "Preventive maintenance visit",
                        "quantity": 1,
                        "uom": "visit",
                        "unit_price": 185.0,
                    },
                    {
                        "kind": "labor",
                        "description": "Technician labor",
                        "quantity": 2,
                        "uom": "hour",
                        "unit_price": 98.0,
                    },
                    {
                        "kind": "part",
                        "description": "MERV 13 filter",
                        "quantity": 2,
                        "uom": "each",
                        "unit_price": 24.5,
                        "part_id": "part_filter_merv13",
                    },
                    {
                        "kind": "travel",
                        "description": "Travel charge",
                        "quantity": 1,
                        "uom": "trip",
                        "unit_price": 28.0,
                    },
                ],
            },
            {
                "revision": 2,
                "state": "draft",
                "created_at": "2026-03-11T09:10:00Z",
                "created_by_user_id": "user_manager_jonas",
                "discount_rate": 0.03,
                "tax_rate": 0.101,
                "notes": "Added condenser coil cleaning to the bundled visit.",
                "terms": "Net 15.",
                "margin_note": "Travel remains bundled to protect margin.",
                "lines": [
                    {
                        "kind": "service_fee",
                        "description": "Preventive maintenance visit",
                        "quantity": 1,
                        "uom": "visit",
                        "unit_price": 185.0,
                    },
                    {
                        "kind": "labor",
                        "description": "Technician labor",
                        "quantity": 2.5,
                        "uom": "hour",
                        "unit_price": 98.0,
                    },
                    {
                        "kind": "part",
                        "description": "MERV 13 filter",
                        "quantity": 2,
                        "uom": "each",
                        "unit_price": 24.5,
                        "part_id": "part_filter_merv13",
                    },
                    {
                        "kind": "travel",
                        "description": "Travel charge",
                        "quantity": 1,
                        "uom": "trip",
                        "unit_price": 28.0,
                    },
                ],
            },
        ],
    },
    {
        "id": "est_002",
        "number": "EST-6002",
        "status": "sent",
        "customer_id": "cust_011",
        "site_id": "site_011",
        "asset_id": "asset_011",
        "branch_id": "branch_north",
        "team_id": "team_north_alpha",
        "created_at": "2026-03-08T11:25:00Z",
        "updated_at": "2026-03-09T18:00:00Z",
        "expiration_date": "2026-03-31",
        "current_revision": 1,
        "latest_shared_revision": 1,
        "sent_at": "2026-03-09T18:00:00Z",
        "viewed_at": "2026-03-10T13:15:00Z",
        "approval_state": "awaiting_customer",
        "artifact_status": "ready",
        "artifact_generated_at": "2026-03-09T17:59:00Z",
        "versions": [
            {
                "revision": 1,
                "state": "sent",
                "created_at": "2026-03-08T11:25:00Z",
                "created_by_user_id": "user_manager_jonas",
                "shared_at": "2026-03-09T18:00:00Z",
                "discount_rate": 0.02,
                "tax_rate": 0.101,
                "notes": "Lobby door preventative service.",
                "terms": "Approval reserves a next-week service window.",
                "margin_note": "Keep labor fixed for trust-building.",
                "lines": [
                    {
                        "kind": "service_fee",
                        "description": "Door system tune-up",
                        "quantity": 1,
                        "uom": "visit",
                        "unit_price": 210.0,
                    },
                    {
                        "kind": "labor",
                        "description": "Door technician labor",
                        "quantity": 3,
                        "uom": "hour",
                        "unit_price": 92.0,
                    },
                    {
                        "kind": "part",
                        "description": "Contact cleaner",
                        "quantity": 1,
                        "uom": "can",
                        "unit_price": 18.5,
                        "part_id": "part_contact_cleaner",
                    },
                ],
            }
        ],
    },
    {
        "id": "est_003",
        "number": "EST-6003",
        "status": "viewed",
        "customer_id": "cust_018",
        "site_id": "site_018",
        "asset_id": "asset_018",
        "branch_id": "branch_south",
        "team_id": "team_south_gamma",
        "source_work_order_id": "wo_018",
        "created_at": "2026-03-07T09:40:00Z",
        "updated_at": "2026-03-10T16:45:00Z",
        "expiration_date": "2026-03-29",
        "current_revision": 2,
        "latest_shared_revision": 1,
        "sent_at": "2026-03-08T17:20:00Z",
        "viewed_at": "2026-03-09T10:00:00Z",
        "approval_state": "stale_revision",
        "artifact_status": "ready",
        "artifact_revision": 1,
        "artifact_generated_at": "2026-03-08T17:18:00Z",
        "versions": [
            {
                "revision": 1,
                "state": "sent",
                "created_at": "2026-03-07T09:40:00Z",
                "created_by_user_id": "user_manager_jonas",
                "shared_at": "2026-03-08T17:20:00Z",
                "discount_rate": 0.04,
                "tax_rate": 0.101,
                "notes": "Roof drain cleaning with minor sealing.",
                "terms": "Revision 1 shared for customer review.",
                "margin_note": "Keep parts visible to justify cost.",
                "lines": [
                    {
                        "kind": "service_fee",
                        "description": "Roof drain service window",
                        "quantity": 1,
                        "uom": "visit",
                        "unit_price": 240.0,
                    },
                    {
                        "kind": "labor",
                        "description": "Technician labor",
                        "quantity": 4,
                        "uom": "hour",
                        "unit_price": 94.0,
                    },
                    {
                        "kind": "travel",
                        "description": "Lift and travel charge",
                        "quantity": 1,
                        "uom": "trip",
                        "unit_price": 44.0,
                    },
                ],
            },
            {
                "revision": 2,
                "state": "draft",
                "created_at": "2026-03-10T16:45:00Z",
                "created_by_user_id": "user_manager_jonas",
                "discount_rate": 0.04,
                "tax_rate": 0.101,
                "notes": "Added follow-up flashing seal and drain camera inspection.",
                "terms": "Revision 2 requires a fresh customer confirmation.",
                "margin_note": "Revision 2 adds follow-up labor.",
                "lines": [
                    {
                        "kind": "service_fee",
                        "description": "Roof drain service window",
                        "quantity": 1,
                        "uom": "visit",
                        "unit_price": 240.0,
                    },
                    {
                        "kind": "labor",
                        "description": "Technician labor",
                        "quantity": 5,
                        "uom": "hour",
                        "unit_price": 94.0,
                    },
                    {
                        "kind": "travel",
                        "description": "Lift and travel charge",
                        "quantity": 1,
                        "uom": "trip",
                        "unit_price": 44.0,
                    },
                ],
            },
        ],
    },
    {
        "id": "est_004",
        "number": "EST-6004",
        "status": "approved",
        "customer_id": "cust_020",
        "site_id": "site_020",
        "asset_id": "asset_020",
        "branch_id": "branch_north",
        "team_id": "team_north_beta",
        "source_work_order_id": "wo_020",
        "created_at": "2026-03-04T14:30:00Z",
        "updated_at": "2026-03-06T08:00:00Z",
        "expiration_date": "2026-03-27",
        "current_revision": 1,
        "latest_shared_revision": 1,
        "approved_revision": 1,
        "sent_at": "2026-03-05T18:00:00Z",
        "viewed_at": "2026-03-05T19:10:00Z",
        "approved_at": "2026-03-06T08:00:00Z",
        "approval_state": "approved",
        "artifact_status": "ready",
        "artifact_generated_at": "2026-03-05T17:58:00Z",
        "linked_agreement_id": "agreement_001",
        "linked_work_order_id": "wo_020",
        "approvals": [
            {
                "revision": 1,
                "state": "approved",
                "customer_name": "Morgan Hale",
                "captured_at": "2026-03-06T08:00:00Z",
                "channel": "signature_capture",
                "signature_ref": "sig_est_004_approved",
                "note": "Approved annual service agreement.",
            }
        ],
        "versions": [
            {
                "revision": 1,
                "state": "approved",
                "created_at": "2026-03-04T14:30:00Z",
                "created_by_user_id": "user_manager_jonas",
                "shared_at": "2026-03-05T18:00:00Z",
                "discount_rate": 0.05,
                "tax_rate": 0.101,
                "notes": "Quarterly rooftop maintenance agreement.",
                "terms": "Twelve-month service agreement billed quarterly.",
                "margin_note": "Anchor with predictable quarterly cadence.",
                "lines": [
                    {
                        "kind": "service_fee",
                        "description": "Quarterly preventive maintenance program",
                        "quantity": 4,
                        "uom": "visit",
                        "unit_price": 520.0,
                    },
                    {
                        "kind": "labor",
                        "description": "Seasonal startup labor",
                        "quantity": 6,
                        "uom": "hour",
                        "unit_price": 95.0,
                    },
                    {
                        "kind": "part",
                        "description": "MERV 13 filter",
                        "quantity": 4,
                        "uom": "each",
                        "unit_price": 24.5,
                        "part_id": "part_filter_merv13",
                    },
                ],
            }
        ],
    },
]

for blueprint in estimate_blueprints:
    bundle = build_estimate_bundle(blueprint)
    estimates[blueprint["id"]] = bundle["estimate"]
    estimate_lines.update(bundle["lines"])
    estimate_versions.update(bundle["versions"])
    estimate_approvals.update(bundle["approvals"])
    proposal_artifacts[bundle["proposal_artifact"]["id"]] = bundle["proposal_artifact"]

agreement_lines = {
    "agreement_line_001_service": {
        "id": "agreement_line_001_service",
        "agreement_id": "agreement_001",
        "kind": "preventive_maintenance",
        "description": "Quarterly rooftop preventive maintenance",
        "included_quantity": 4,
        "uom": "visit",
        "annual_value": 2880.0,
    },
    "agreement_line_002_service": {
        "id": "agreement_line_002_service",
        "agreement_id": "agreement_002",
        "kind": "door_service",
        "description": "Quarterly lobby door service",
        "included_quantity": 4,
        "uom": "visit",
        "annual_value": 1560.0,
    },
    "agreement_line_003_service": {
        "id": "agreement_line_003_service",
        "agreement_id": "agreement_003",
        "kind": "roof_drain",
        "description": "Bi-monthly roof drain and flashing inspection",
        "included_quantity": 6,
        "uom": "visit",
        "annual_value": 2140.0,
    },
}
service_agreements = {
    "agreement_001": {
        "id": "agreement_001",
        "number": "AGR-7001",
        "status": "active",
        "source_estimate_id": "est_004",
        "source_estimate_version_id": "estimate_version_est_004_r1",
        "customer_id": "cust_020",
        "branch_id": "branch_north",
        "team_id": "team_north_beta",
        "covered_site_ids": ["site_020"],
        "covered_asset_ids": ["asset_020"],
        "agreement_line_ids": ["agreement_line_001_service"],
        "recurring_plan_ids": ["recurring_plan_001"],
        "renewal_record_ids": ["renewal_001"],
        "health_snapshot_id": "contract_health_agreement_001",
        "owner_user_id": "user_manager_jonas",
        "currency": "USD",
        "annual_value": 2880.0,
        "recurring_revenue_monthly": 240.0,
        "start_date": "2026-03-15",
        "end_date": "2027-03-14",
        "renewal_date": "2027-01-15",
        "service_window": "08:00-10:00",
        "sla_tier": "platinum",
        "response_commitment": "4h",
        "paused_at": None,
        "resumed_at": None,
        "notes": "Quarterly rooftop maintenance and seasonal startup coverage.",
    },
    "agreement_002": {
        "id": "agreement_002",
        "number": "AGR-7002",
        "status": "paused",
        "source_estimate_id": "est_002",
        "source_estimate_version_id": "estimate_version_est_002_r1",
        "customer_id": "cust_011",
        "branch_id": "branch_north",
        "team_id": "team_north_alpha",
        "covered_site_ids": ["site_011"],
        "covered_asset_ids": ["asset_011"],
        "agreement_line_ids": ["agreement_line_002_service"],
        "recurring_plan_ids": ["recurring_plan_002"],
        "renewal_record_ids": [],
        "health_snapshot_id": "contract_health_agreement_002",
        "owner_user_id": "user_manager_jonas",
        "currency": "USD",
        "annual_value": 1560.0,
        "recurring_revenue_monthly": 130.0,
        "start_date": "2026-01-01",
        "end_date": "2026-12-31",
        "renewal_date": "2026-11-30",
        "service_window": "09:00-11:00",
        "sla_tier": "gold",
        "response_commitment": "same_day",
        "paused_at": "2026-03-01T12:00:00Z",
        "resumed_at": None,
        "pause_reason": "Tenant blackout window through spring remodel.",
        "notes": "Pause retains future cadence and asset coverage.",
    },
    "agreement_003": {
        "id": "agreement_003",
        "number": "AGR-7003",
        "status": "renewal_pending",
        "source_estimate_id": "est_003",
        "source_estimate_version_id": "estimate_version_est_003_r1",
        "customer_id": "cust_018",
        "branch_id": "branch_south",
        "team_id": "team_south_gamma",
        "covered_site_ids": ["site_018"],
        "covered_asset_ids": ["asset_018"],
        "agreement_line_ids": ["agreement_line_003_service"],
        "recurring_plan_ids": ["recurring_plan_003"],
        "renewal_record_ids": ["renewal_002"],
        "health_snapshot_id": "contract_health_agreement_003",
        "owner_user_id": "user_manager_jonas",
        "currency": "USD",
        "annual_value": 2140.0,
        "recurring_revenue_monthly": 178.33,
        "start_date": "2025-04-01",
        "end_date": "2026-03-31",
        "renewal_date": "2026-03-25",
        "service_window": "13:00-15:00",
        "sla_tier": "gold",
        "response_commitment": "8h",
        "paused_at": None,
        "resumed_at": None,
        "notes": "Renewal is pending after scope edits to the latest estimate revision.",
    },
}
recurrence_rules = {
    "recurrence_rule_001": {
        "id": "recurrence_rule_001",
        "plan_id": "recurring_plan_001",
        "cadence_unit": "month",
        "interval": 3,
        "day_of_month": 15,
        "timezone": "America/Los_Angeles",
    },
    "recurrence_rule_002": {
        "id": "recurrence_rule_002",
        "plan_id": "recurring_plan_002",
        "cadence_unit": "month",
        "interval": 3,
        "day_of_month": 1,
        "timezone": "America/Los_Angeles",
    },
    "recurrence_rule_003": {
        "id": "recurrence_rule_003",
        "plan_id": "recurring_plan_003",
        "cadence_unit": "month",
        "interval": 2,
        "day_of_month": 20,
        "timezone": "America/Los_Angeles",
    },
}
recurring_plans = {
    "recurring_plan_001": {
        "id": "recurring_plan_001",
        "agreement_id": "agreement_001",
        "rule_id": "recurrence_rule_001",
        "status": "active",
        "next_scheduled_date": "2026-04-15",
        "service_window": "08:00-10:00",
        "covered_site_ids": ["site_020"],
        "covered_asset_ids": ["asset_020"],
        "included_service_types": ["pm", "filter_change"],
        "branch_id": "branch_north",
        "team_id": "team_north_beta",
        "last_generated_at": "2026-03-10T09:00:00Z",
        "generation_revision": 2,
        "last_generated_schedule_item_id": "schedule_item_001",
        "skip_history_ids": [],
    },
    "recurring_plan_002": {
        "id": "recurring_plan_002",
        "agreement_id": "agreement_002",
        "rule_id": "recurrence_rule_002",
        "status": "paused",
        "next_scheduled_date": "2026-06-01",
        "service_window": "09:00-11:00",
        "covered_site_ids": ["site_011"],
        "covered_asset_ids": ["asset_011"],
        "included_service_types": ["inspection", "door_adjustment"],
        "branch_id": "branch_north",
        "team_id": "team_north_alpha",
        "last_generated_at": "2026-02-25T10:30:00Z",
        "generation_revision": 1,
        "last_generated_schedule_item_id": "schedule_item_003",
        "skip_history_ids": ["schedule_item_003"],
        "pause_reason": "Tenant blackout window through remodel.",
    },
    "recurring_plan_003": {
        "id": "recurring_plan_003",
        "agreement_id": "agreement_003",
        "rule_id": "recurrence_rule_003",
        "status": "active",
        "next_scheduled_date": "2026-03-20",
        "service_window": "13:00-15:00",
        "covered_site_ids": ["site_018"],
        "covered_asset_ids": ["asset_018"],
        "included_service_types": ["roof_drain", "seal_check"],
        "branch_id": "branch_south",
        "team_id": "team_south_gamma",
        "last_generated_at": "2026-03-10T09:00:00Z",
        "generation_revision": 5,
        "last_generated_schedule_item_id": "schedule_item_004",
        "skip_history_ids": [],
    },
}
generated_schedule_items = {
    "schedule_item_001": {
        "id": "schedule_item_001",
        "plan_id": "recurring_plan_001",
        "agreement_id": "agreement_001",
        "scheduled_date": "2026-04-15",
        "service_window": "08:00-10:00",
        "status": "planned",
        "generated_work_order_id": None,
        "source_generation_revision": 2,
        "created_at": "2026-03-10T09:00:00Z",
        "skip_reason": None,
        "rescheduled_from_id": None,
    },
    "schedule_item_002": {
        "id": "schedule_item_002",
        "plan_id": "recurring_plan_001",
        "agreement_id": "agreement_001",
        "scheduled_date": "2026-07-15",
        "service_window": "08:00-10:00",
        "status": "planned",
        "generated_work_order_id": None,
        "source_generation_revision": 2,
        "created_at": "2026-03-10T09:00:00Z",
        "skip_reason": None,
        "rescheduled_from_id": None,
    },
    "schedule_item_003": {
        "id": "schedule_item_003",
        "plan_id": "recurring_plan_002",
        "agreement_id": "agreement_002",
        "scheduled_date": "2026-03-01",
        "service_window": "09:00-11:00",
        "status": "skipped",
        "generated_work_order_id": None,
        "source_generation_revision": 1,
        "created_at": "2026-02-25T10:30:00Z",
        "skip_reason": "Customer blackout window requested by site contact.",
        "rescheduled_from_id": None,
    },
    "schedule_item_004": {
        "id": "schedule_item_004",
        "plan_id": "recurring_plan_003",
        "agreement_id": "agreement_003",
        "scheduled_date": "2026-03-20",
        "service_window": "13:00-15:00",
        "status": "generated",
        "generated_work_order_id": "wo_018",
        "source_generation_revision": 5,
        "created_at": "2026-03-10T09:00:00Z",
        "skip_reason": None,
        "rescheduled_from_id": None,
    },
}
renewal_records = {
    "renewal_001": {
        "id": "renewal_001",
        "agreement_id": "agreement_001",
        "status": "scheduled",
        "due_date": "2027-01-15",
        "quoted_estimate_id": None,
        "prior_agreement_id": "agreement_001",
        "next_term_start": "2027-03-15",
        "created_at": "2026-03-01T10:00:00Z",
        "updated_at": "2026-03-01T10:00:00Z",
    },
    "renewal_002": {
        "id": "renewal_002",
        "agreement_id": "agreement_003",
        "status": "pending_review",
        "due_date": "2026-03-25",
        "quoted_estimate_id": "est_003",
        "prior_agreement_id": "agreement_003",
        "next_term_start": "2026-04-01",
        "created_at": "2026-03-09T15:30:00Z",
        "updated_at": "2026-03-10T16:45:00Z",
    },
}
contract_health_snapshots = {
    "contract_health_agreement_001": {
        "id": "contract_health_agreement_001",
        "agreement_id": "agreement_001",
        "health_status": "healthy",
        "service_completion_pct": 100.0,
        "skipped_occurrences": 0,
        "overdue_occurrences": 0,
        "renewal_risk": "low",
        "revenue_at_risk": 0.0,
    },
    "contract_health_agreement_002": {
        "id": "contract_health_agreement_002",
        "agreement_id": "agreement_002",
        "health_status": "paused",
        "service_completion_pct": 100.0,
        "skipped_occurrences": 1,
        "overdue_occurrences": 0,
        "renewal_risk": "medium",
        "revenue_at_risk": 130.0,
    },
    "contract_health_agreement_003": {
        "id": "contract_health_agreement_003",
        "agreement_id": "agreement_003",
        "health_status": "at_risk",
        "service_completion_pct": 83.33,
        "skipped_occurrences": 0,
        "overdue_occurrences": 1,
        "renewal_risk": "high",
        "revenue_at_risk": 178.33,
    },
}
recurring_revenue_rollups = {
    "recurring_revenue_global": {
        "id": "recurring_revenue_global",
        "scope": "global",
        "branch_id": None,
        "team_id": None,
        "monthly_recurring_revenue": 548.33,
        "annual_contract_value": 6580.0,
        "active_agreements": 1,
        "paused_agreements": 1,
        "renewal_pending_count": 1,
        "skipped_occurrences": 1,
    },
    "recurring_revenue_branch_north": {
        "id": "recurring_revenue_branch_north",
        "scope": "branch",
        "branch_id": "branch_north",
        "team_id": None,
        "monthly_recurring_revenue": 370.0,
        "annual_contract_value": 4440.0,
        "active_agreements": 1,
        "paused_agreements": 1,
        "renewal_pending_count": 0,
        "skipped_occurrences": 1,
    },
    "recurring_revenue_team_north_beta": {
        "id": "recurring_revenue_team_north_beta",
        "scope": "team",
        "branch_id": "branch_north",
        "team_id": "team_north_beta",
        "monthly_recurring_revenue": 240.0,
        "annual_contract_value": 2880.0,
        "active_agreements": 1,
        "paused_agreements": 0,
        "renewal_pending_count": 0,
        "skipped_occurrences": 0,
    },
}
integration_endpoints = {
    "integration_endpoint_accounting": {
        "id": "integration_endpoint_accounting",
        "kind": "accounting_export",
        "status": "healthy",
        "direction": "outbound",
        "created_at": "2026-02-20T12:00:00Z",
        "last_activity_at": "2026-03-11T08:16:00Z",
        "last_error": None,
        "connector_mapping_ids": ["connector_mapping_002"],
        "sync_job_ids": ["sync_job_001"],
    },
    "integration_endpoint_crm": {
        "id": "integration_endpoint_crm",
        "kind": "crm_sync",
        "status": "degraded",
        "direction": "bidirectional",
        "created_at": "2026-02-25T09:30:00Z",
        "last_activity_at": "2026-03-11T06:30:00Z",
        "last_error": "Duplicate downstream event id rejected during renewal sync.",
        "connector_mapping_ids": ["connector_mapping_001"],
        "sync_job_ids": ["sync_job_002"],
    },
}
api_key_records = {
    "api_key_001": {
        "id": "api_key_001",
        "label": "Ops sync key",
        "status": "active",
        "key_prefix": "x07_live_ops",
        "masked_secret": "x07_live_ops_****V7K2",
        "created_at": "2026-02-18T12:00:00Z",
        "rotated_at": None,
        "expires_at": "2026-09-01T00:00:00Z",
        "last_used_at": "2026-03-11T07:45:00Z",
        "scope_ids": ["estimates.read", "contracts.write", "recurring.generate"],
    },
    "api_key_002": {
        "id": "api_key_002",
        "label": "Finance export mirror",
        "status": "rotated",
        "key_prefix": "x07_fin",
        "masked_secret": "x07_fin_****T9D1",
        "created_at": "2026-01-12T09:00:00Z",
        "rotated_at": "2026-03-10T18:00:00Z",
        "expires_at": None,
        "last_used_at": "2026-03-10T17:55:00Z",
        "scope_ids": ["finance.read", "deliveries.read"],
        "replacement_key_id": "api_key_001",
    },
}
webhook_subscriptions = {
    "webhook_001": {
        "id": "webhook_001",
        "label": "CRM opportunity updates",
        "status": "active",
        "endpoint_id": "integration_endpoint_crm",
        "endpoint_url": "https://example.test/hooks/crm",
        "event_types": ["estimate.approved", "contract.renewed"],
        "masked_secret": "whsec_****9c1e",
        "created_at": "2026-02-25T09:35:00Z",
        "last_delivery_at": "2026-03-06T08:01:01Z",
        "failure_count": 0,
        "connector_mapping_ids": ["connector_mapping_001"],
    },
    "webhook_002": {
        "id": "webhook_002",
        "label": "Operations schedule mirror",
        "status": "degraded",
        "endpoint_id": "integration_endpoint_accounting",
        "endpoint_url": "https://example.test/hooks/schedule",
        "event_types": ["recurring.generated", "invoice.issued", "payment.recorded"],
        "masked_secret": "whsec_****7fa2",
        "created_at": "2026-02-20T12:10:00Z",
        "last_delivery_at": "2026-03-10T09:02:00Z",
        "failure_count": 2,
        "connector_mapping_ids": ["connector_mapping_002"],
    },
}
webhook_deliveries = {
    "delivery_001": {
        "id": "delivery_001",
        "subscription_id": "webhook_001",
        "event_type": "estimate.approved",
        "entity_kind": "estimate",
        "entity_id": "est_004",
        "status": "delivered",
        "attempt_count": 1,
        "created_at": "2026-03-06T08:01:00Z",
        "last_attempt_at": "2026-03-06T08:01:01Z",
        "next_retry_at": None,
        "response_code": 202,
        "response_summary": "Accepted",
        "delivery_revision": "delivery_rev_001",
        "duplicate_of_id": None,
        "retryable": False,
    },
    "delivery_002": {
        "id": "delivery_002",
        "subscription_id": "webhook_002",
        "event_type": "recurring.generated",
        "entity_kind": "recurring_plan",
        "entity_id": "recurring_plan_003",
        "status": "failed",
        "attempt_count": 3,
        "created_at": "2026-03-10T09:00:00Z",
        "last_attempt_at": "2026-03-10T09:02:00Z",
        "next_retry_at": "2026-03-11T09:30:00Z",
        "response_code": 500,
        "response_summary": "Connector timed out during schedule export batch.",
        "delivery_revision": "delivery_rev_003",
        "duplicate_of_id": None,
        "retryable": True,
    },
    "delivery_003": {
        "id": "delivery_003",
        "subscription_id": "webhook_001",
        "event_type": "contract.renewed",
        "entity_kind": "service_agreement",
        "entity_id": "agreement_003",
        "status": "duplicate",
        "attempt_count": 1,
        "created_at": "2026-03-11T06:30:00Z",
        "last_attempt_at": "2026-03-11T06:30:00Z",
        "next_retry_at": None,
        "response_code": 409,
        "response_summary": "Duplicate downstream event id rejected by sink.",
        "delivery_revision": "delivery_rev_004",
        "duplicate_of_id": "delivery_001",
        "retryable": False,
    },
}
connector_mappings = {
    "connector_mapping_001": {
        "id": "connector_mapping_001",
        "endpoint_id": "integration_endpoint_crm",
        "entity_kind": "estimate",
        "status": "active",
        "external_object": "opportunity",
        "field_mappings": {
            "estimate_total": "amount",
            "customer_id": "account_ref",
            "status": "stage",
        },
        "updated_at": "2026-03-05T16:00:00Z",
    },
    "connector_mapping_002": {
        "id": "connector_mapping_002",
        "endpoint_id": "integration_endpoint_accounting",
        "entity_kind": "service_agreement",
        "status": "active",
        "external_object": "contract",
        "field_mappings": {
            "annual_value": "contract_value",
            "renewal_date": "renewal_date",
            "status": "contract_status",
        },
        "updated_at": "2026-03-07T09:00:00Z",
    },
}
import_or_sync_jobs = {
    "sync_job_001": {
        "id": "sync_job_001",
        "kind": "connector_backfill",
        "status": "completed",
        "endpoint_id": "integration_endpoint_accounting",
        "started_at": "2026-03-09T18:00:00Z",
        "completed_at": "2026-03-09T18:12:00Z",
        "summary": "Reconciled 12 invoices and 3 agreements.",
    },
    "sync_job_002": {
        "id": "sync_job_002",
        "kind": "webhook_retry",
        "status": "running",
        "endpoint_id": "integration_endpoint_crm",
        "started_at": "2026-03-11T06:35:00Z",
        "completed_at": None,
        "summary": "Retrying failed recurring-service deliveries.",
    },
}
tenants = {
    "tenant_northline": {
        "id": "tenant_northline",
        "status": "active",
        "name": "Northline Facilities",
        "display_name": "Northline CrewOps",
        "kind": "enterprise_parent",
        "workspace_ids": [
            "workspace_hq",
            "workspace_branch_north",
            "workspace_branch_south",
        ],
        "branding_pack_id": "branding_pack_northline",
        "portal_config": {
            "title": "Northline Service Portal",
            "allow_estimate_approval": True,
            "allow_request_intake": True,
            "show_invoice_balance": True,
        },
        "feature_flags": {
            "portal": True,
            "inventory": True,
            "procurement": True,
            "connectors": True,
            "white_label": True,
        },
        "readiness_status": "ready",
        "revision": 7,
    },
    "tenant_northline_branch": {
        "id": "tenant_northline_branch",
        "status": "pilot",
        "name": "Northline Northwest Franchise",
        "display_name": "Northline Northwest",
        "kind": "child_tenant",
        "parent_tenant_id": "tenant_northline",
        "workspace_ids": ["workspace_branch_north"],
        "branding_pack_id": "branding_pack_northwest",
        "portal_config": {
            "title": "Northwest Portal",
            "allow_estimate_approval": True,
            "allow_request_intake": True,
            "show_invoice_balance": True,
        },
        "feature_flags": {
            "portal": True,
            "inventory": True,
            "procurement": True,
            "connectors": True,
            "white_label": True,
        },
        "readiness_status": "config_incomplete",
        "revision": 3,
    },
}
workspaces = {
    "workspace_hq": {
        "id": "workspace_hq",
        "tenant_id": "tenant_northline",
        "kind": "hq",
        "name": "Headquarters",
        "branch_id": None,
    },
    "workspace_branch_north": {
        "id": "workspace_branch_north",
        "tenant_id": "tenant_northline",
        "kind": "branch",
        "name": "North Branch Workspace",
        "branch_id": "branch_north",
    },
    "workspace_branch_south": {
        "id": "workspace_branch_south",
        "tenant_id": "tenant_northline",
        "kind": "branch",
        "name": "South Branch Workspace",
        "branch_id": "branch_south",
    },
}
org_hierarchy_nodes = {
    "org_node_root": {
        "id": "org_node_root",
        "tenant_id": "tenant_northline",
        "parent_id": None,
        "kind": "tenant",
        "label": "Northline Facilities",
        "workspace_id": "workspace_hq",
    },
    "org_node_branch_north": {
        "id": "org_node_branch_north",
        "tenant_id": "tenant_northline",
        "parent_id": "org_node_root",
        "kind": "branch",
        "label": "North Branch",
        "workspace_id": "workspace_branch_north",
    },
    "org_node_branch_south": {
        "id": "org_node_branch_south",
        "tenant_id": "tenant_northline",
        "parent_id": "org_node_root",
        "kind": "branch",
        "label": "South Branch",
        "workspace_id": "workspace_branch_south",
    },
}
role_definitions = {
    "role_enterprise_admin": {
        "id": "role_enterprise_admin",
        "tenant_id": "tenant_northline",
        "label": "Enterprise Admin",
        "scope_kind": "tenant",
        "system_role": True,
    },
    "role_branch_manager": {
        "id": "role_branch_manager",
        "tenant_id": "tenant_northline",
        "label": "Branch Manager",
        "scope_kind": "workspace",
        "system_role": True,
    },
    "role_inventory_coordinator": {
        "id": "role_inventory_coordinator",
        "tenant_id": "tenant_northline",
        "label": "Inventory Coordinator",
        "scope_kind": "workspace",
        "system_role": False,
    },
    "role_portal_user": {
        "id": "role_portal_user",
        "tenant_id": "tenant_northline",
        "label": "Portal User",
        "scope_kind": "customer",
        "system_role": True,
    },
}
permission_grants = {
    "permission_grant_001": {
        "id": "permission_grant_001",
        "role_id": "role_enterprise_admin",
        "scope_id": "tenant_northline",
        "permissions": [
            "tenant.manage",
            "branding.manage",
            "portal.manage",
            "connector.manage",
        ],
        "assigned_user_ids": ["user_enterprise_iris"],
    },
    "permission_grant_002": {
        "id": "permission_grant_002",
        "role_id": "role_branch_manager",
        "scope_id": "workspace_branch_north",
        "permissions": [
            "inventory.view",
            "procurement.view",
            "dashboard.view",
        ],
        "assigned_user_ids": ["user_manager_jonas"],
    },
    "permission_grant_003": {
        "id": "permission_grant_003",
        "role_id": "role_inventory_coordinator",
        "scope_id": "workspace_branch_north",
        "permissions": [
            "inventory.manage",
            "procurement.manage",
        ],
        "assigned_user_ids": ["user_dispatch_rhea"],
    },
}
branding_packs = {
    "branding_pack_northline": {
        "id": "branding_pack_northline",
        "tenant_id": "tenant_northline",
        "display_name": "Northline CrewOps",
        "accent_color": "#0b6f68",
        "portal_title": "Northline Service Portal",
        "invoice_branding_ref": "northline-core",
        "navigation_sections": [
            "portal",
            "inventory",
            "procurement",
            "integration_dashboard",
        ],
        "revision": 7,
    },
    "branding_pack_northwest": {
        "id": "branding_pack_northwest",
        "tenant_id": "tenant_northline_branch",
        "display_name": "Northline Northwest",
        "accent_color": "#8a5c23",
        "portal_title": "Northwest Portal",
        "invoice_branding_ref": "northline-northwest",
        "navigation_sections": [
            "portal",
            "inventory",
            "procurement",
        ],
        "revision": 3,
    },
}
theme_overrides = {
    "theme_override_northline": {
        "id": "theme_override_northline",
        "branding_pack_id": "branding_pack_northline",
        "surface_color": "#f5efe6",
        "text_color": "#1e2b28",
    }
}
portal_accounts = {
    "portal_account_001": {
        "id": "portal_account_001",
        "tenant_id": "tenant_northline",
        "customer_id": "cust_020",
        "status": "active",
        "email": "morgan.hale@example.test",
        "display_name": "Morgan Hale",
        "pending_estimate_id": "est_004",
        "invoice_ids": ["inv_004"],
        "service_request_ids": ["service_request_001"],
        "timeline_event_ids": [
            "timeline_event_001",
            "timeline_event_002",
            "timeline_event_003",
        ],
        "upcoming_visit_ids": ["visit_018"],
    },
    "portal_account_002": {
        "id": "portal_account_002",
        "tenant_id": "tenant_northline_branch",
        "customer_id": "cust_018",
        "status": "invited",
        "email": "ops.cust18@example.test",
        "display_name": "Customer 18 Ops",
        "pending_estimate_id": None,
        "invoice_ids": ["inv_004"],
        "service_request_ids": [],
        "timeline_event_ids": [],
        "upcoming_visit_ids": [],
    },
}
portal_sessions = {
    "portal_session_001": {
        "id": "portal_session_001",
        "portal_account_id": "portal_account_001",
        "status": "active",
        "issued_at": "2026-03-11T08:45:00Z",
        "expires_at": "2026-03-11T16:45:00Z",
    }
}
customer_timeline_events = {
    "timeline_event_001": {
        "id": "timeline_event_001",
        "portal_account_id": "portal_account_001",
        "service_request_id": "service_request_001",
        "kind": "request_submitted",
        "customer_message": "Submitted rooftop drain inspection request.",
        "office_message": "Portal request created for branch triage.",
        "created_at": "2026-03-10T14:10:00Z",
    },
    "timeline_event_002": {
        "id": "timeline_event_002",
        "portal_account_id": "portal_account_001",
        "service_request_id": "service_request_001",
        "kind": "estimate_ready",
        "customer_message": "Estimate is ready for approval.",
        "office_message": "Estimate est_004 linked to portal request.",
        "created_at": "2026-03-11T08:20:00Z",
    },
    "timeline_event_003": {
        "id": "timeline_event_003",
        "portal_account_id": "portal_account_001",
        "service_request_id": "service_request_001",
        "kind": "visit_scheduled",
        "customer_message": "Service visit scheduled for March 20.",
        "office_message": "Dispatch linked portal request to visit_018.",
        "created_at": "2026-03-11T09:00:00Z",
    },
}
service_requests = {
    "service_request_001": {
        "id": "service_request_001",
        "tenant_id": "tenant_northline",
        "portal_account_id": "portal_account_001",
        "customer_id": "cust_020",
        "status": "triaged",
        "priority": "high",
        "summary": "Roof drain inspection and leak check",
        "structured_intake": {
            "site_id": "site_020",
            "asset_id": "asset_020",
            "requested_window": "2026-03-20",
            "issue_kind": "roof_drain",
        },
        "converted_work_order_id": "wo_018",
        "estimate_id": "est_004",
        "connector_reference": "crm_ticket_2044",
        "revision": 2,
    },
    "service_request_002": {
        "id": "service_request_002",
        "tenant_id": "tenant_northline_branch",
        "portal_account_id": "portal_account_002",
        "customer_id": "cust_018",
        "status": "submitted",
        "priority": "medium",
        "summary": "Door closer calibration",
        "structured_intake": {
            "site_id": "site_018",
            "asset_id": "asset_018",
            "requested_window": "2026-03-19",
            "issue_kind": "door_adjustment",
        },
        "converted_work_order_id": None,
        "estimate_id": None,
        "connector_reference": None,
        "revision": 1,
    },
}
inventory_items = {
    "inventory_item_filter_merv13": {
        "id": "inventory_item_filter_merv13",
        "tenant_id": "tenant_northline",
        "part_catalog_id": "part_filter_merv13",
        "sku": "FLT-MERV13-20x25x2",
        "name": "MERV 13 Filter",
        "status": "active",
        "primary_location_id": "stock_location_warehouse_north",
        "on_hand": 42,
        "reserved": 6,
        "reorder_threshold": 18,
        "preferred_vendor_id": "vendor_supply_hub",
    },
    "inventory_item_belt_a42": {
        "id": "inventory_item_belt_a42",
        "tenant_id": "tenant_northline",
        "part_catalog_id": "part_belt_a42",
        "sku": "BLT-A42",
        "name": "Drive Belt A42",
        "status": "active",
        "primary_location_id": "stock_location_warehouse_north",
        "on_hand": 16,
        "reserved": 4,
        "reorder_threshold": 10,
        "preferred_vendor_id": "vendor_supply_hub",
    },
    "inventory_item_contact_cleaner": {
        "id": "inventory_item_contact_cleaner",
        "tenant_id": "tenant_northline",
        "part_catalog_id": "part_contact_cleaner",
        "sku": "CLN-CNT-001",
        "name": "Contact Cleaner",
        "status": "active",
        "primary_location_id": "stock_location_warehouse_south",
        "on_hand": 9,
        "reserved": 1,
        "reorder_threshold": 8,
        "preferred_vendor_id": "vendor_supply_hub",
    },
    "inventory_item_roof_seal": {
        "id": "inventory_item_roof_seal",
        "tenant_id": "tenant_northline",
        "part_catalog_id": None,
        "sku": "SLN-ROOF-2G",
        "name": "Roof Sealant 2G",
        "status": "active",
        "primary_location_id": "stock_location_warehouse_north",
        "on_hand": 5,
        "reserved": 2,
        "reorder_threshold": 6,
        "preferred_vendor_id": "vendor_roofline",
    },
}
stock_locations = {
    "stock_location_warehouse_north": {
        "id": "stock_location_warehouse_north",
        "tenant_id": "tenant_northline",
        "kind": "warehouse",
        "label": "North Warehouse",
        "branch_id": "branch_north",
    },
    "stock_location_warehouse_south": {
        "id": "stock_location_warehouse_south",
        "tenant_id": "tenant_northline",
        "kind": "warehouse",
        "label": "South Warehouse",
        "branch_id": "branch_south",
    },
    "stock_location_van_alpha": {
        "id": "stock_location_van_alpha",
        "tenant_id": "tenant_northline",
        "kind": "vehicle",
        "label": "Van Alpha",
        "branch_id": "branch_north",
    },
    "stock_location_van_gamma": {
        "id": "stock_location_van_gamma",
        "tenant_id": "tenant_northline",
        "kind": "vehicle",
        "label": "Van Gamma",
        "branch_id": "branch_south",
    },
}
vehicle_stock = {
    "vehicle_stock_alpha_filter": {
        "id": "vehicle_stock_alpha_filter",
        "location_id": "stock_location_van_alpha",
        "inventory_item_id": "inventory_item_filter_merv13",
        "on_hand": 6,
        "reserved": 2,
    },
    "vehicle_stock_gamma_cleaner": {
        "id": "vehicle_stock_gamma_cleaner",
        "location_id": "stock_location_van_gamma",
        "inventory_item_id": "inventory_item_contact_cleaner",
        "on_hand": 3,
        "reserved": 0,
    },
}
stock_movements = {
    "stock_movement_001": {
        "id": "stock_movement_001",
        "tenant_id": "tenant_northline",
        "inventory_item_id": "inventory_item_filter_merv13",
        "location_id": "stock_location_van_alpha",
        "kind": "consume",
        "quantity": 2,
        "status": "posted",
        "reason": "Used on quarterly PM visit.",
        "source_work_order_id": "wo_013",
        "revision": 1,
    },
    "stock_movement_002": {
        "id": "stock_movement_002",
        "tenant_id": "tenant_northline",
        "inventory_item_id": "inventory_item_roof_seal",
        "location_id": "stock_location_warehouse_north",
        "kind": "transfer",
        "quantity": 1,
        "status": "posted",
        "reason": "Moved to van stock for leak follow-up.",
        "source_work_order_id": "wo_018",
        "revision": 2,
    },
}
cycle_counts = {
    "cycle_count_001": {
        "id": "cycle_count_001",
        "tenant_id": "tenant_northline",
        "location_id": "stock_location_warehouse_north",
        "status": "variance",
        "scheduled_date": "2026-03-12",
        "variance_item_ids": ["inventory_item_roof_seal"],
    }
}
vendors = {
    "vendor_supply_hub": {
        "id": "vendor_supply_hub",
        "tenant_id": "tenant_northline",
        "status": "active",
        "name": "Supply Hub NW",
        "payment_terms": "Net 30",
    },
    "vendor_roofline": {
        "id": "vendor_roofline",
        "tenant_id": "tenant_northline",
        "status": "active",
        "name": "Roofline Supply Co.",
        "payment_terms": "Net 15",
    },
}
vendor_catalog_items = {
    "vendor_catalog_001": {
        "id": "vendor_catalog_001",
        "vendor_id": "vendor_supply_hub",
        "inventory_item_id": "inventory_item_filter_merv13",
        "vendor_sku": "SUP-FLT-13",
        "unit_cost": 18.5,
    },
    "vendor_catalog_002": {
        "id": "vendor_catalog_002",
        "vendor_id": "vendor_supply_hub",
        "inventory_item_id": "inventory_item_contact_cleaner",
        "vendor_sku": "SUP-CLN-1",
        "unit_cost": 9.25,
    },
    "vendor_catalog_003": {
        "id": "vendor_catalog_003",
        "vendor_id": "vendor_roofline",
        "inventory_item_id": "inventory_item_roof_seal",
        "vendor_sku": "RF-SLN-2G",
        "unit_cost": 41.0,
    },
}
purchase_orders = {
    "purchase_order_001": {
        "id": "purchase_order_001",
        "tenant_id": "tenant_northline",
        "vendor_id": "vendor_supply_hub",
        "status": "open",
        "branch_id": "branch_north",
        "expected_delivery_date": "2026-03-14",
        "line_ids": ["purchase_order_line_001", "purchase_order_line_002"],
        "revision": 2,
    },
    "purchase_order_002": {
        "id": "purchase_order_002",
        "tenant_id": "tenant_northline",
        "vendor_id": "vendor_roofline",
        "status": "partial",
        "branch_id": "branch_south",
        "expected_delivery_date": "2026-03-13",
        "line_ids": ["purchase_order_line_003"],
        "revision": 3,
    },
}
purchase_order_lines = {
    "purchase_order_line_001": {
        "id": "purchase_order_line_001",
        "purchase_order_id": "purchase_order_001",
        "inventory_item_id": "inventory_item_filter_merv13",
        "expected_quantity": 24,
        "received_quantity": 0,
    },
    "purchase_order_line_002": {
        "id": "purchase_order_line_002",
        "purchase_order_id": "purchase_order_001",
        "inventory_item_id": "inventory_item_belt_a42",
        "expected_quantity": 12,
        "received_quantity": 0,
    },
    "purchase_order_line_003": {
        "id": "purchase_order_line_003",
        "purchase_order_id": "purchase_order_002",
        "inventory_item_id": "inventory_item_roof_seal",
        "expected_quantity": 8,
        "received_quantity": 3,
    },
}
receiving_records = {
    "receiving_record_001": {
        "id": "receiving_record_001",
        "purchase_order_id": "purchase_order_002",
        "status": "partial",
        "received_at": "2026-03-10T15:20:00Z",
        "mismatch": True,
        "line_receipts": [
            {
                "line_id": "purchase_order_line_003",
                "expected_quantity": 8,
                "received_quantity": 3,
            }
        ],
    }
}
reorder_suggestions = {
    "reorder_suggestion_001": {
        "id": "reorder_suggestion_001",
        "tenant_id": "tenant_northline",
        "inventory_item_id": "inventory_item_roof_seal",
        "location_id": "stock_location_warehouse_north",
        "recommended_quantity": 12,
        "reason": "Projected demand exceeds on-hand stock.",
    },
    "reorder_suggestion_002": {
        "id": "reorder_suggestion_002",
        "tenant_id": "tenant_northline",
        "inventory_item_id": "inventory_item_contact_cleaner",
        "location_id": "stock_location_warehouse_south",
        "recommended_quantity": 8,
        "reason": "South branch low-stock threshold crossed.",
    },
}
connector_instances = {
    "connector_instance_accounting": {
        "id": "connector_instance_accounting",
        "tenant_id": "tenant_northline",
        "provider_class": "accounting",
        "provider_name": "LedgerCloud",
        "status": "healthy",
        "config_revision": 4,
        "last_success_at": "2026-03-11T06:45:00Z",
        "mapping_ids": ["connector_mapping_002"],
    },
    "connector_instance_payments": {
        "id": "connector_instance_payments",
        "tenant_id": "tenant_northline",
        "provider_class": "payments",
        "provider_name": "PayArc",
        "status": "retry_required",
        "config_revision": 2,
        "last_success_at": "2026-03-10T18:15:00Z",
        "mapping_ids": [],
    },
    "connector_instance_crm": {
        "id": "connector_instance_crm",
        "tenant_id": "tenant_northline",
        "provider_class": "crm",
        "provider_name": "Orbit CRM",
        "status": "degraded",
        "config_revision": 5,
        "last_success_at": "2026-03-11T05:10:00Z",
        "mapping_ids": ["connector_mapping_001"],
    },
    "connector_instance_ticketing": {
        "id": "connector_instance_ticketing",
        "tenant_id": "tenant_northline_branch",
        "provider_class": "ticketing",
        "provider_name": "FieldDesk",
        "status": "config_stale",
        "config_revision": 3,
        "last_success_at": "2026-03-09T14:00:00Z",
        "mapping_ids": [],
    },
}
connector_sync_jobs = {
    "connector_sync_job_001": {
        "id": "connector_sync_job_001",
        "connector_instance_id": "connector_instance_accounting",
        "provider_class": "accounting",
        "status": "completed",
        "started_at": "2026-03-11T06:30:00Z",
        "completed_at": "2026-03-11T06:45:00Z",
    },
    "connector_sync_job_002": {
        "id": "connector_sync_job_002",
        "connector_instance_id": "connector_instance_crm",
        "provider_class": "crm",
        "status": "failed",
        "started_at": "2026-03-11T05:00:00Z",
        "completed_at": "2026-03-11T05:07:00Z",
    },
    "connector_sync_job_003": {
        "id": "connector_sync_job_003",
        "connector_instance_id": "connector_instance_ticketing",
        "provider_class": "ticketing",
        "status": "stale_config",
        "started_at": "2026-03-10T11:00:00Z",
        "completed_at": "2026-03-10T11:03:00Z",
    },
}
connector_delivery_records = {
    "connector_delivery_record_001": {
        "id": "connector_delivery_record_001",
        "connector_instance_id": "connector_instance_crm",
        "status": "failed",
        "entity_kind": "service_request",
        "entity_id": "service_request_001",
        "response_summary": "CRM rejected stale mapping revision.",
        "retryable": True,
    }
}
tenant_health_snapshots = {
    "tenant_health_northline": {
        "id": "tenant_health_northline",
        "tenant_id": "tenant_northline",
        "portal_conversion_rate": 0.67,
        "connector_failure_count": 2,
        "low_stock_count": 2,
        "po_backlog_count": 1,
        "readiness_status": "ready",
    },
    "tenant_health_northline_branch": {
        "id": "tenant_health_northline_branch",
        "tenant_id": "tenant_northline_branch",
        "portal_conversion_rate": 0.5,
        "connector_failure_count": 1,
        "low_stock_count": 1,
        "po_backlog_count": 1,
        "readiness_status": "config_incomplete",
    },
}
portal_adoption_rollups = {
    "portal_adoption_northline": {
        "id": "portal_adoption_northline",
        "tenant_id": "tenant_northline",
        "active_accounts": 1,
        "invited_accounts": 1,
        "request_conversion_rate": 0.5,
        "approval_conversion_rate": 1.0,
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
    "teams_by_branch": defaultdict(list),
    "users_by_role": defaultdict(list),
    "invoices_by_status": defaultdict(list),
    "invoices_by_customer": defaultdict(list),
    "invoices_by_branch": defaultdict(list),
    "invoices_by_team": defaultdict(list),
    "invoices_by_aging_bucket": defaultdict(list),
    "invoices_by_work_order": defaultdict(list),
    "payments_by_invoice": defaultdict(list),
    "payments_by_customer": defaultdict(list),
    "export_jobs_by_status": defaultdict(list),
    "price_books_by_branch": defaultdict(list),
    "price_books_by_customer": defaultdict(list),
    "statements_by_customer": defaultdict(list),
    "receivables_by_branch": defaultdict(list),
    "estimates_by_status": defaultdict(list),
    "estimates_by_customer": defaultdict(list),
    "estimates_by_branch": defaultdict(list),
    "agreements_by_status": defaultdict(list),
    "agreements_by_customer": defaultdict(list),
    "agreements_by_branch": defaultdict(list),
    "recurring_plans_by_status": defaultdict(list),
    "recurring_plans_by_agreement": defaultdict(list),
    "generated_schedule_items_by_plan": defaultdict(list),
    "renewal_records_by_status": defaultdict(list),
    "api_keys_by_status": defaultdict(list),
    "webhook_deliveries_by_status": defaultdict(list),
    "webhook_deliveries_by_subscription": defaultdict(list),
    "workspaces_by_tenant": defaultdict(list),
    "portal_accounts_by_tenant": defaultdict(list),
    "portal_accounts_by_status": defaultdict(list),
    "service_requests_by_tenant": defaultdict(list),
    "service_requests_by_status": defaultdict(list),
    "inventory_items_by_tenant": defaultdict(list),
    "inventory_items_by_status": defaultdict(list),
    "inventory_items_by_location": defaultdict(list),
    "stock_locations_by_tenant": defaultdict(list),
    "stock_movements_by_location": defaultdict(list),
    "stock_movements_by_status": defaultdict(list),
    "vendors_by_tenant": defaultdict(list),
    "purchase_orders_by_tenant": defaultdict(list),
    "purchase_orders_by_status": defaultdict(list),
    "purchase_orders_by_vendor": defaultdict(list),
    "receiving_records_by_purchase_order": defaultdict(list),
    "reorder_suggestions_by_location": defaultdict(list),
    "connector_instances_by_tenant": defaultdict(list),
    "connector_instances_by_status": defaultdict(list),
    "connector_instances_by_provider": defaultdict(list),
    "connector_sync_jobs_by_status": defaultdict(list),
    "connector_sync_jobs_by_provider": defaultdict(list),
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
for team in teams:
    indexes["teams_by_branch"][team["branch_id"]].append(team["id"])
for user in users.values():
    indexes["users_by_role"][user["role"]].append(user["id"])
for invoice_id, invoice in invoices.items():
    indexes["invoices_by_status"][invoice["status"]].append(invoice_id)
    indexes["invoices_by_customer"][invoice["customer_id"]].append(invoice_id)
    indexes["invoices_by_branch"][invoice["branch_id"]].append(invoice_id)
    indexes["invoices_by_team"][invoice["team_id"]].append(invoice_id)
    indexes["invoices_by_aging_bucket"][invoice["aging_bucket"]].append(invoice_id)
    for work_order_id in invoice["source_work_order_ids"]:
        indexes["invoices_by_work_order"][work_order_id].append(invoice_id)
for payment_id, payment in payment_records.items():
    indexes["payments_by_invoice"][payment["invoice_id"]].append(payment_id)
    indexes["payments_by_customer"][payment["customer_id"]].append(payment_id)
for export_job_id, export_job in export_jobs.items():
    indexes["export_jobs_by_status"][export_job["status"]].append(export_job_id)
for price_book_id, price_book in price_books.items():
    if price_book["branch_id"] is not None:
        indexes["price_books_by_branch"][price_book["branch_id"]].append(price_book_id)
    if price_book["customer_id"] is not None:
        indexes["price_books_by_customer"][price_book["customer_id"]].append(price_book_id)
for statement_id, statement in customer_statements.items():
    indexes["statements_by_customer"][statement["customer_id"]].append(statement_id)
for receivable_id, receivable in receivable_summaries.items():
    if receivable["branch_id"] is not None:
        indexes["receivables_by_branch"][receivable["branch_id"]].append(receivable_id)
for estimate_id, estimate in estimates.items():
    indexes["estimates_by_status"][estimate["status"]].append(estimate_id)
    indexes["estimates_by_customer"][estimate["customer_id"]].append(estimate_id)
    indexes["estimates_by_branch"][estimate["branch_id"]].append(estimate_id)
for agreement_id, agreement in service_agreements.items():
    indexes["agreements_by_status"][agreement["status"]].append(agreement_id)
    indexes["agreements_by_customer"][agreement["customer_id"]].append(agreement_id)
    indexes["agreements_by_branch"][agreement["branch_id"]].append(agreement_id)
for plan_id, plan in recurring_plans.items():
    indexes["recurring_plans_by_status"][plan["status"]].append(plan_id)
    indexes["recurring_plans_by_agreement"][plan["agreement_id"]].append(plan_id)
for item_id, item in generated_schedule_items.items():
    indexes["generated_schedule_items_by_plan"][item["plan_id"]].append(item_id)
for renewal_id, renewal in renewal_records.items():
    indexes["renewal_records_by_status"][renewal["status"]].append(renewal_id)
for api_key_id, api_key in api_key_records.items():
    indexes["api_keys_by_status"][api_key["status"]].append(api_key_id)
for delivery_id, delivery in webhook_deliveries.items():
    indexes["webhook_deliveries_by_status"][delivery["status"]].append(delivery_id)
    indexes["webhook_deliveries_by_subscription"][delivery["subscription_id"]].append(delivery_id)
for workspace_id, workspace in workspaces.items():
    indexes["workspaces_by_tenant"][workspace["tenant_id"]].append(workspace_id)
for portal_account_id, portal_account in portal_accounts.items():
    indexes["portal_accounts_by_tenant"][portal_account["tenant_id"]].append(portal_account_id)
    indexes["portal_accounts_by_status"][portal_account["status"]].append(portal_account_id)
for service_request_id, service_request in service_requests.items():
    indexes["service_requests_by_tenant"][service_request["tenant_id"]].append(service_request_id)
    indexes["service_requests_by_status"][service_request["status"]].append(service_request_id)
for inventory_item_id, inventory_item in inventory_items.items():
    indexes["inventory_items_by_tenant"][inventory_item["tenant_id"]].append(inventory_item_id)
    indexes["inventory_items_by_status"][inventory_item["status"]].append(inventory_item_id)
    indexes["inventory_items_by_location"][inventory_item["primary_location_id"]].append(
        inventory_item_id
    )
for stock_location_id, stock_location in stock_locations.items():
    indexes["stock_locations_by_tenant"][stock_location["tenant_id"]].append(stock_location_id)
for stock_movement_id, stock_movement in stock_movements.items():
    indexes["stock_movements_by_location"][stock_movement["location_id"]].append(stock_movement_id)
    indexes["stock_movements_by_status"][stock_movement["status"]].append(stock_movement_id)
for vendor_id, vendor in vendors.items():
    indexes["vendors_by_tenant"][vendor["tenant_id"]].append(vendor_id)
for purchase_order_id, purchase_order in purchase_orders.items():
    indexes["purchase_orders_by_tenant"][purchase_order["tenant_id"]].append(purchase_order_id)
    indexes["purchase_orders_by_status"][purchase_order["status"]].append(purchase_order_id)
    indexes["purchase_orders_by_vendor"][purchase_order["vendor_id"]].append(purchase_order_id)
for receiving_record_id, receiving_record in receiving_records.items():
    indexes["receiving_records_by_purchase_order"][receiving_record["purchase_order_id"]].append(
        receiving_record_id
    )
for reorder_suggestion_id, reorder_suggestion in reorder_suggestions.items():
    indexes["reorder_suggestions_by_location"][reorder_suggestion["location_id"]].append(
        reorder_suggestion_id
    )
for connector_instance_id, connector_instance in connector_instances.items():
    indexes["connector_instances_by_tenant"][connector_instance["tenant_id"]].append(
        connector_instance_id
    )
    indexes["connector_instances_by_status"][connector_instance["status"]].append(
        connector_instance_id
    )
    indexes["connector_instances_by_provider"][connector_instance["provider_class"]].append(
        connector_instance_id
    )
for connector_sync_job_id, connector_sync_job in connector_sync_jobs.items():
    indexes["connector_sync_jobs_by_status"][connector_sync_job["status"]].append(
        connector_sync_job_id
    )
    indexes["connector_sync_jobs_by_provider"][connector_sync_job["provider_class"]].append(
        connector_sync_job_id
    )
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
        "dispatchers": 1,
        "supervisors": 1,
        "managers": 1,
        "portal_users": len(portal_accounts),
        "enterprise_admins": 1,
        "customers": len(customers),
        "sites": len(sites),
        "assets": len(assets),
        "work_orders": len(work_orders),
        "visits": len(visits),
        "assignments": len(assignments),
        "invoices": len(invoices),
        "payments": len(payment_records),
        "export_jobs": len(export_jobs),
        "estimates": len(estimates),
        "estimate_versions": len(estimate_versions),
        "service_agreements": len(service_agreements),
        "recurring_plans": len(recurring_plans),
        "webhook_subscriptions": len(webhook_subscriptions),
        "webhook_deliveries": len(webhook_deliveries),
        "tenants": len(tenants),
        "workspaces": len(workspaces),
        "portal_accounts": len(portal_accounts),
        "service_requests": len(service_requests),
        "inventory_items": len(inventory_items),
        "stock_locations": len(stock_locations),
        "stock_movements": len(stock_movements),
        "vendors": len(vendors),
        "purchase_orders": len(purchase_orders),
        "receiving_records": len(receiving_records),
        "connector_instances": len(connector_instances),
        "connector_sync_jobs": len(connector_sync_jobs),
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
    "alert_unread": {
        "technician": 1,
        "dispatcher": 1,
        "supervisor": 1,
        "manager": 1,
    },
    "branch_rollups": list(branch_summaries.values()),
    "team_rollups": list(team_summaries.values()),
    "dashboard_rollup": dashboard_rollups["dashboard_default"],
    "workload_summary": workload_snapshots,
    "finance_metrics": finance_rollups["finance_global"],
    "invoice_status_counts": {
        key: len(value) for key, value in indexes["invoices_by_status"].items()
    },
    "aging_buckets": {
        key: len(value) for key, value in indexes["invoices_by_aging_bucket"].items()
    },
    "receivables_overview": {
        "total_open_balance": round(
            sum(invoice["balance_due"] for invoice in invoices.values()),
            2,
        ),
        "overdue_balance": round(
            sum(
                invoice["balance_due"]
                for invoice in invoices.values()
                if invoice["aging_bucket"] in {"1_30", "31_60", "61_plus"}
            ),
            2,
        ),
        "customer_count": len(customer_statements),
    },
    "export_job_counts": {
        key: len(value) for key, value in indexes["export_jobs_by_status"].items()
    },
    "profitability_summary": profitability_snapshots["finance_global"],
    "estimate_status_counts": {
        key: len(value) for key, value in indexes["estimates_by_status"].items()
    },
    "agreement_status_counts": {
        key: len(value) for key, value in indexes["agreements_by_status"].items()
    },
    "recurring_plan_status_counts": {
        key: len(value) for key, value in indexes["recurring_plans_by_status"].items()
    },
    "contract_health_overview": {
        "active": len(indexes["agreements_by_status"].get("active", [])),
        "paused": len(indexes["agreements_by_status"].get("paused", [])),
        "renewal_pending": len(indexes["agreements_by_status"].get("renewal_pending", [])),
        "at_risk_agreement_ids": [
            snapshot["agreement_id"]
            for snapshot in contract_health_snapshots.values()
            if snapshot["health_status"] == "at_risk"
        ],
    },
    "renewal_pipeline": {
        "pending_ids": indexes["renewal_records_by_status"].get("pending_review", []),
        "scheduled_ids": indexes["renewal_records_by_status"].get("scheduled", []),
        "due_next_30_days": [
            renewal["agreement_id"]
            for renewal in renewal_records.values()
            if renewal["due_date"] <= "2026-04-10"
        ],
    },
    "recurring_revenue_summary": recurring_revenue_rollups["recurring_revenue_global"],
    "integration_summary": {
        "active_api_keys": len(indexes["api_keys_by_status"].get("active", [])),
        "rotated_api_keys": len(indexes["api_keys_by_status"].get("rotated", [])),
        "failed_deliveries": len(indexes["webhook_deliveries_by_status"].get("failed", [])),
        "duplicate_deliveries": len(indexes["webhook_deliveries_by_status"].get("duplicate", [])),
        "active_webhooks": len(
            [
                subscription_id
                for subscription_id, subscription in webhook_subscriptions.items()
                if subscription["status"] == "active"
            ]
        ),
    },
    "tenant_health_overview": {
        tenant_id: snapshot
        for tenant_id, snapshot in (
            (tenant_health_snapshot["tenant_id"], tenant_health_snapshot)
            for tenant_health_snapshot in tenant_health_snapshots.values()
        )
    },
    "portal_adoption_summary": portal_adoption_rollups["portal_adoption_northline"],
    "inventory_summary": {
        "low_stock_item_ids": [
            inventory_item_id
            for inventory_item_id, inventory_item in inventory_items.items()
            if inventory_item["on_hand"] <= inventory_item["reorder_threshold"]
        ],
        "cycle_count_ids": list(cycle_counts),
        "movement_ids": list(stock_movements),
        "vehicle_location_ids": [
            stock_location_id
            for stock_location_id, stock_location in stock_locations.items()
            if stock_location["kind"] == "vehicle"
        ],
    },
    "procurement_summary": {
        "open_purchase_order_ids": indexes["purchase_orders_by_status"].get("open", []),
        "partial_purchase_order_ids": indexes["purchase_orders_by_status"].get("partial", []),
        "receiving_mismatch_ids": [
            receiving_record_id
            for receiving_record_id, receiving_record in receiving_records.items()
            if receiving_record["mismatch"]
        ],
        "reorder_suggestion_ids": list(reorder_suggestions),
    },
    "connector_health_summary": {
        "healthy_connector_ids": indexes["connector_instances_by_status"].get("healthy", []),
        "retry_required_connector_ids": indexes["connector_instances_by_status"].get(
            "retry_required", []
        ),
        "stale_connector_ids": indexes["connector_instances_by_status"].get(
            "config_stale", []
        ),
        "degraded_connector_ids": indexes["connector_instances_by_status"].get(
            "degraded", []
        ),
        "failed_sync_job_ids": indexes["connector_sync_jobs_by_status"].get("failed", []),
    },
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
    "price_books": price_books,
    "price_book_items": price_book_items,
    "labor_rate_policies": labor_rate_policies,
    "part_rate_policies": part_rate_policies,
    "billing_policies": billing_policies,
    "tax_rules": tax_rules,
    "discount_rules": discount_rules,
    "invoices": invoices,
    "invoice_lines": invoice_lines,
    "invoice_adjustments": invoice_adjustments,
    "invoice_artifacts": invoice_artifacts,
    "service_summary_artifacts": service_summary_artifacts,
    "payment_records": payment_records,
    "payment_allocations": payment_allocations,
    "customer_statements": customer_statements,
    "receivable_summaries": receivable_summaries,
    "export_jobs": export_jobs,
    "finance_rollups": finance_rollups,
    "profitability_snapshots": profitability_snapshots,
    "estimates": estimates,
    "estimate_versions": estimate_versions,
    "estimate_lines": estimate_lines,
    "estimate_approvals": estimate_approvals,
    "proposal_artifacts": proposal_artifacts,
    "service_agreements": service_agreements,
    "agreement_lines": agreement_lines,
    "recurring_plans": recurring_plans,
    "recurrence_rules": recurrence_rules,
    "generated_schedule_items": generated_schedule_items,
    "renewal_records": renewal_records,
    "contract_health_snapshots": contract_health_snapshots,
    "integration_endpoints": integration_endpoints,
    "api_key_records": api_key_records,
    "webhook_subscriptions": webhook_subscriptions,
    "webhook_deliveries": webhook_deliveries,
    "connector_mappings": connector_mappings,
    "import_or_sync_jobs": import_or_sync_jobs,
    "recurring_revenue_rollups": recurring_revenue_rollups,
    "tenants": tenants,
    "workspaces": workspaces,
    "org_hierarchy_nodes": org_hierarchy_nodes,
    "role_definitions": role_definitions,
    "permission_grants": permission_grants,
    "branding_packs": branding_packs,
    "theme_overrides": theme_overrides,
    "portal_accounts": portal_accounts,
    "portal_sessions": portal_sessions,
    "customer_timeline_events": customer_timeline_events,
    "service_requests": service_requests,
    "inventory_items": inventory_items,
    "stock_locations": stock_locations,
    "vehicle_stock": vehicle_stock,
    "stock_movements": stock_movements,
    "cycle_counts": cycle_counts,
    "vendors": vendors,
    "vendor_catalog_items": vendor_catalog_items,
    "purchase_orders": purchase_orders,
    "purchase_order_lines": purchase_order_lines,
    "receiving_records": receiving_records,
    "reorder_suggestions": reorder_suggestions,
    "connector_instances": connector_instances,
    "connector_sync_jobs": connector_sync_jobs,
    "connector_delivery_records": connector_delivery_records,
    "tenant_health_snapshots": tenant_health_snapshots,
    "portal_adoption_rollups": portal_adoption_rollups,
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
    "price_books": price_books,
    "price_book_items": price_book_items,
    "labor_rate_policies": labor_rate_policies,
    "part_rate_policies": part_rate_policies,
    "billing_policies": billing_policies,
    "tax_rules": tax_rules,
    "discount_rules": discount_rules,
    "invoices": invoices,
    "invoice_lines": invoice_lines,
    "invoice_adjustments": invoice_adjustments,
    "invoice_artifacts": invoice_artifacts,
    "service_summary_artifacts": service_summary_artifacts,
    "payment_records": payment_records,
    "payment_allocations": payment_allocations,
    "customer_statements": customer_statements,
    "receivable_summaries": receivable_summaries,
    "export_jobs": export_jobs,
    "finance_rollups": finance_rollups,
    "profitability_snapshots": profitability_snapshots,
    "estimates": estimates,
    "estimate_versions": estimate_versions,
    "estimate_lines": estimate_lines,
    "estimate_approvals": estimate_approvals,
    "proposal_artifacts": proposal_artifacts,
    "service_agreements": service_agreements,
    "agreement_lines": agreement_lines,
    "recurring_plans": recurring_plans,
    "recurrence_rules": recurrence_rules,
    "generated_schedule_items": generated_schedule_items,
    "renewal_records": renewal_records,
    "contract_health_snapshots": contract_health_snapshots,
    "integration_endpoints": integration_endpoints,
    "api_key_records": api_key_records,
    "webhook_subscriptions": webhook_subscriptions,
    "webhook_deliveries": webhook_deliveries,
    "connector_mappings": connector_mappings,
    "import_or_sync_jobs": import_or_sync_jobs,
    "recurring_revenue_rollups": recurring_revenue_rollups,
    "tenants": tenants,
    "workspaces": workspaces,
    "org_hierarchy_nodes": org_hierarchy_nodes,
    "role_definitions": role_definitions,
    "permission_grants": permission_grants,
    "branding_packs": branding_packs,
    "theme_overrides": theme_overrides,
    "portal_accounts": portal_accounts,
    "portal_sessions": portal_sessions,
    "customer_timeline_events": customer_timeline_events,
    "service_requests": service_requests,
    "inventory_items": inventory_items,
    "stock_locations": stock_locations,
    "vehicle_stock": vehicle_stock,
    "stock_movements": stock_movements,
    "cycle_counts": cycle_counts,
    "vendors": vendors,
    "vendor_catalog_items": vendor_catalog_items,
    "purchase_orders": purchase_orders,
    "purchase_order_lines": purchase_order_lines,
    "receiving_records": receiving_records,
    "reorder_suggestions": reorder_suggestions,
    "connector_instances": connector_instances,
    "connector_sync_jobs": connector_sync_jobs,
    "connector_delivery_records": connector_delivery_records,
    "tenant_health_snapshots": tenant_health_snapshots,
    "portal_adoption_rollups": portal_adoption_rollups,
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
        if work_order_id in work_orders
    },
    "templates": {
        template_id: compact_template_doc(templates[template_id])
        for template_id in bootstrap_template_ids
        if template_id in templates
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


def sync_doc(
    cursor,
    status,
    *,
    conflict_status="idle",
    conflict_message="",
    conflict_code=None,
    conflict_entity_id=None,
    invoice_lock_status="idle",
    invoice_lock_message="",
    stale_invoice_id=None,
    estimate_revision_status="idle",
    stale_estimate_id=None,
    agreement_revision_status="idle",
    stale_agreement_id=None,
    recurring_generation_status="idle",
    stale_recurring_plan_id=None,
    delivery_retry_status="idle",
    stale_delivery_id=None,
    payment_revision_status="idle",
    pricing_revision_status="idle",
    stale_price_book_id=None,
    export_status="idle",
    finance_revision="finance_rev_2026_03_11_001",
    portal_approval_status="idle",
    stale_portal_request_id=None,
    tenant_revision_status="idle",
    stale_tenant_id=None,
    inventory_movement_status="idle",
    stale_stock_location_id=None,
    receiving_status="idle",
    stale_purchase_order_id=None,
    connector_config_status="idle",
    stale_connector_instance_id=None,
):
    return {
        "cursor": cursor,
        "pending_ops": [],
        "last_pull_at": now,
        "last_push_at": None,
        "last_server_event_at": now,
        "status": status,
        "last_error": None,
        "conflict_status": conflict_status,
        "conflict_message": conflict_message,
        "conflict_code": conflict_code,
        "conflict_entity_id": conflict_entity_id,
        "invoice_lock_status": invoice_lock_status,
        "invoice_lock_message": invoice_lock_message,
        "stale_invoice_id": stale_invoice_id,
        "estimate_revision_status": estimate_revision_status,
        "stale_estimate_id": stale_estimate_id,
        "agreement_revision_status": agreement_revision_status,
        "stale_agreement_id": stale_agreement_id,
        "recurring_generation_status": recurring_generation_status,
        "stale_recurring_plan_id": stale_recurring_plan_id,
        "delivery_retry_status": delivery_retry_status,
        "stale_delivery_id": stale_delivery_id,
        "payment_revision_status": payment_revision_status,
        "pricing_revision_status": pricing_revision_status,
        "stale_price_book_id": stale_price_book_id,
        "export_status": export_status,
        "finance_revision": finance_revision,
        "unread_alerts": 4,
        "unread_activity": 6,
        "enterprise_ops": {
            "portal_approval_status": portal_approval_status,
            "stale_portal_request_id": stale_portal_request_id,
            "tenant_revision_status": tenant_revision_status,
            "stale_tenant_id": stale_tenant_id,
            "inventory_movement_status": inventory_movement_status,
            "stale_stock_location_id": stale_stock_location_id,
            "receiving_status": receiving_status,
            "stale_purchase_order_id": stale_purchase_order_id,
            "connector_config_status": connector_config_status,
            "stale_connector_instance_id": stale_connector_instance_id,
        },
    }


def compact_entity_snapshot(source_entities, extra_work_order_ids=None):
    work_order_ids = list(dict.fromkeys((extra_work_order_ids or []) + bootstrap_work_order_ids))
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
        "parts_catalog": clone_doc(source_entities["parts_catalog"]),
    }


def payload_with_snapshot(extra, extra_work_order_ids=None):
    out = dict(extra)
    out["entities"] = compact_entity_snapshot(base_entities, extra_work_order_ids)
    out["indexes"] = clone_doc(indexes)
    out["summary"] = clone_doc(summary)
    return out


def payload_with_snapshot_state(extra, entities_snapshot, indexes_snapshot, summary_snapshot):
    out = dict(extra)
    out["entities"] = clone_doc(entities_snapshot)
    out["indexes"] = clone_doc(indexes_snapshot)
    out["summary"] = clone_doc(summary_snapshot)
    return out


def payload_with_full_state(
    extra,
    entities_snapshot=None,
    indexes_snapshot=None,
    summary_snapshot=None,
):
    out = dict(extra)
    out["entities"] = clone_doc(base_entities if entities_snapshot is None else entities_snapshot)
    out["indexes"] = clone_doc(indexes if indexes_snapshot is None else indexes_snapshot)
    out["summary"] = clone_doc(summary if summary_snapshot is None else summary_snapshot)
    return out


def move_group_member(index_group, source_key, target_key, entity_id):
    if source_key is not None and source_key in index_group:
        index_group[source_key] = [
            item_id for item_id in index_group[source_key]
            if item_id != entity_id
        ]
        if not index_group[source_key]:
            del index_group[source_key]
    target_group = index_group.setdefault(target_key, [])
    if entity_id not in target_group:
        target_group.append(entity_id)


def adjust_counter(counter_doc, key, delta):
    counter_doc[key] = counter_doc.get(key, 0) + delta
    if counter_doc[key] == 0:
        del counter_doc[key]


meta_doc = {
    "app_name": "CrewOps",
    "app_version": APP_VERSION,
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
        "portal_user": {
            "user_id": "user_portal_morgan",
            "branch_id": "branch_north",
            "team_id": None,
        },
        "enterprise_admin": {
            "user_id": "user_enterprise_iris",
            "branch_id": "branch_north",
            "team_id": None,
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
        "app_version": APP_VERSION,
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

pricing_config_doc = payload_with_snapshot(
    {
        "pricing": {
            "price_book_ids": list(price_books),
            "billing_policy_ids": list(billing_policies),
            "tax_rule_ids": list(tax_rules),
            "discount_rule_ids": list(discount_rules),
            "revision": "pricing_rev_2026_03_11_001",
            "default_branch_price_books": {
                "branch_north": "price_book_branch_north",
                "branch_south": "price_book_branch_south",
            },
        },
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

pricing_update_doc = payload_with_snapshot(
    {
        "status": "updated",
        "message": "Saved pricing and billing policy changes.",
        "price_book_id": "price_book_branch_north",
        "billing_policy_id": "billing_policy_branch_north",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            finance_revision="finance_rev_2026_03_11_002",
        ),
    }
)

pricing_update_conflict_doc = payload_with_snapshot(
    {
        "status": "conflict",
        "message": "Pricing revision changed while the draft invoice was open.",
        "price_book_id": "price_book_customer_cust_018",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "conflict",
            conflict_status="stale",
            conflict_message="Pricing revision mismatch; refresh before saving.",
            conflict_code="pricing_revision_mismatch",
            conflict_entity_id="price_book_customer_cust_018",
            pricing_revision_status="mismatch",
            stale_price_book_id="price_book_customer_cust_018",
            finance_revision="finance_rev_2026_03_11_003",
        ),
    }
)

invoice_list_doc = payload_with_snapshot(
    {
        "invoice_ids": list(invoices),
        "open_invoice_ids": [
            invoice_id
            for invoice_id, invoice in invoices.items()
            if invoice["status"] not in {"paid", "voided", "written_off"}
        ],
        "receivable_summary_ids": list(receivable_summaries),
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

invoice_detail_map = {
    invoice_id: payload_with_snapshot(
        {
            "invoice_id": invoice_id,
            "invoice": invoice,
            "line_items": {
                line_id: invoice_lines[line_id]
                for line_id in invoice["line_ids"]
            },
            "adjustments": {
                adjustment_id: invoice_adjustments[adjustment_id]
                for adjustment_id in invoice["adjustment_ids"]
            },
            "payments": {
                payment_id: payment_records[payment_id]
                for payment_id in invoice["payment_ids"]
            },
            "statement": customer_statements[f"statement_{invoice['customer_id']}"],
            "artifacts": {
                invoice["invoice_artifact_id"]: invoice_artifacts[invoice["invoice_artifact_id"]],
                invoice["service_summary_artifact_id"]: service_summary_artifacts[
                    invoice["service_summary_artifact_id"]
                ],
            },
            "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
        }
    )
    for invoice_id, invoice in invoices.items()
}

invoice_generate_doc = payload_with_snapshot(
    {
        "status": "generated",
        "message": "Generated an invoice draft from approved work.",
        "invoice_id": "inv_001",
        "source_work_order_ids": invoices["inv_001"]["source_work_order_ids"],
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            finance_revision="finance_rev_2026_03_11_002",
        ),
    }
)

invoice_patch_doc = payload_with_snapshot(
    {
        "status": "updated",
        "message": "Updated invoice draft totals and memo.",
        "invoice_id": "inv_001",
        "revision": 2,
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            finance_revision="finance_rev_2026_03_11_002",
        ),
    }
)

invoice_issue_map = {
    invoice_id: payload_with_snapshot(
        {
            "status": "issued",
            "message": "Issued invoice and locked revision-sensitive fields.",
            "invoice_id": invoice_id,
            "sync": sync_doc(
                "sync_cursor_2026_03_11_103",
                "accepted",
                invoice_lock_status="revision_sensitive",
                finance_revision="finance_rev_2026_03_11_002",
            ),
        }
    )
    for invoice_id in invoices
}

invoice_lock_conflict_doc = payload_with_snapshot(
    {
        "status": "conflict",
        "message": "Invoice is locked because a newer issued revision already exists.",
        "invoice_id": "inv_007",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "conflict",
            conflict_status="locked",
            conflict_message="Refresh invoice data before editing or issuing.",
            conflict_code="invoice_locked",
            conflict_entity_id="inv_007",
            invoice_lock_status="locked",
            invoice_lock_message="Invoice is already overdue and locked to receivables controls.",
            stale_invoice_id="inv_007",
            finance_revision="finance_rev_2026_03_11_003",
        ),
    }
)

invoice_void_map = {
    invoice_id: payload_with_snapshot(
        {
            "status": "voided",
            "message": "Voided invoice and recorded a credit note.",
            "invoice_id": invoice_id,
            "sync": sync_doc(
                "sync_cursor_2026_03_11_103",
                "accepted",
                invoice_lock_status="locked",
                finance_revision="finance_rev_2026_03_11_002",
            ),
        }
    )
    for invoice_id in invoices
}

invoice_payment_map = {
    invoice_id: payload_with_snapshot(
        {
            "status": "recorded",
            "message": "Recorded payment allocation against invoice.",
            "invoice_id": invoice_id,
            "payment_id": f"payment_recorded_{invoice_id}",
            "sync": sync_doc(
                "sync_cursor_2026_03_11_103",
                "accepted",
                payment_revision_status="accepted",
                finance_revision="finance_rev_2026_03_11_002",
            ),
        }
    )
    for invoice_id in invoices
}

payment_revision_conflict_doc = payload_with_snapshot(
    {
        "status": "conflict",
        "message": "Payment revision mismatched the latest invoice balance.",
        "invoice_id": "inv_005",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "conflict",
            conflict_status="stale",
            conflict_message="Payment allocation was based on a stale invoice balance.",
            conflict_code="payment_revision_mismatch",
            conflict_entity_id="inv_005",
            payment_revision_status="mismatch",
            stale_invoice_id="inv_005",
            finance_revision="finance_rev_2026_03_11_003",
        ),
    }
)

finance_summary_doc = payload_with_snapshot(
    {
        "rollup": finance_rollups["finance_global"],
        "branch_rollups": {
            rollup_id: rollup
            for rollup_id, rollup in finance_rollups.items()
            if rollup["scope"] == "branch"
        },
        "team_rollups": {
            rollup_id: rollup
            for rollup_id, rollup in finance_rollups.items()
            if rollup["scope"] == "team"
        },
        "profitability": profitability_snapshots,
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

finance_receivables_doc = payload_with_snapshot(
    {
        "receivable_ids": list(receivable_summaries),
        "receivables": receivable_summaries,
        "statements": customer_statements,
        "overdue_invoice_ids": indexes["invoices_by_aging_bucket"]["31_60"]
        + indexes["invoices_by_aging_bucket"]["61_plus"],
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

customer_account_map = {
    customer_id: payload_with_snapshot(
        {
            "customer_id": customer_id,
            "customer": customers[customer_id],
            "statement": customer_statements[statement_id],
            "invoice_ids": indexes["invoices_by_customer"].get(customer_id, []),
            "payment_ids": indexes["payments_by_customer"].get(customer_id, []),
            "receivable_summary": receivable_summaries[f"receivable_{customer_id}"],
            "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
        }
    )
    for statement_id, statement in customer_statements.items()
    for customer_id in [statement["customer_id"]]
}

export_center_doc = payload_with_snapshot(
    {
        "export_job_ids": list(export_jobs),
        "jobs": export_jobs,
        "filters": {
            "formats": ["csv", "json"],
            "kinds": ["invoices", "receivables", "profitability"],
            "branch_ids": [branch["id"] for branch in branches],
        },
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle", export_status="idle"),
    }
)

export_create_doc = payload_with_snapshot(
    {
        "status": "queued",
        "message": "Queued export job and snapshotted finance revision.",
        "export_job_id": "export_job_003",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            export_status="running",
            finance_revision="finance_rev_2026_03_11_002",
        ),
    }
)

export_retry_map = {
    export_job_id: payload_with_snapshot(
        {
            "status": "retried",
            "message": "Retried export job with a fresh finance snapshot.",
            "export_job_id": export_job_id,
            "sync": sync_doc(
                "sync_cursor_2026_03_11_103",
                "accepted",
                export_status="running",
                finance_revision="finance_rev_2026_03_11_002",
            ),
        }
    )
    for export_job_id in export_jobs
}

invoice_artifact_map = {
    invoice_id: payload_with_snapshot(
        {
            "invoice_id": invoice_id,
            "artifact": invoice_artifacts[invoice["invoice_artifact_id"]],
            "sync": sync_doc(
                "sync_cursor_2026_03_11_101",
                "idle",
                export_status=invoice_artifacts[invoice["invoice_artifact_id"]]["status"],
            ),
        }
    )
    for invoice_id, invoice in invoices.items()
}

service_summary_map = {
    invoice_id: payload_with_snapshot(
        {
            "invoice_id": invoice_id,
            "artifact": service_summary_artifacts[invoice["service_summary_artifact_id"]],
            "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
        }
    )
    for invoice_id, invoice in invoices.items()
}

estimate_list_doc = payload_with_snapshot(
    {
        "estimate_ids": list(estimates),
        "approval_queue_ids": [
            estimate_id
            for estimate_id, estimate in estimates.items()
            if estimate["status"] in {"sent", "viewed"}
        ],
        "contract_candidate_ids": [
            estimate_id
            for estimate_id, estimate in estimates.items()
            if estimate["status"] == "approved"
        ],
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

estimate_detail_map = {
    estimate_id: payload_with_snapshot(
        {
            "estimate_id": estimate_id,
            "estimate": estimate,
            "versions": {
                version_id: estimate_versions[version_id]
                for version_id in estimate["version_ids"]
            },
            "lines": {
                line_id: estimate_lines[line_id]
                for version_id in estimate["version_ids"]
                for line_id in estimate_versions[version_id]["line_ids"]
            },
            "approvals": {
                approval_id: estimate_approvals[approval_id]
                for approval_id in estimate["approval_ids"]
            },
            "proposal_artifact": proposal_artifacts[estimate["proposal_artifact_id"]],
            "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
        }
    )
    for estimate_id, estimate in estimates.items()
}

estimate_create_blueprint = {
    "id": "est_005",
    "number": "EST-6005",
    "status": "draft",
    "customer_id": "cust_008",
    "site_id": "site_008",
    "asset_id": "asset_008",
    "branch_id": "branch_south",
    "team_id": "team_south_gamma",
    "created_at": "2026-03-11T10:15:00Z",
    "updated_at": "2026-03-11T10:15:00Z",
    "expiration_date": "2026-04-15",
    "current_revision": 1,
    "latest_shared_revision": None,
    "artifact_status": "draft",
    "versions": [
        {
            "revision": 1,
            "state": "draft",
            "created_at": "2026-03-11T10:15:00Z",
            "created_by_user_id": "user_manager_jonas",
            "discount_rate": 0.02,
            "tax_rate": 0.101,
            "notes": "New draft estimate created from customer request.",
            "terms": "Net 15.",
            "margin_note": "Base draft before customer review.",
            "lines": [
                {
                    "kind": "service_fee",
                    "description": "Lighting retrofit site walk",
                    "quantity": 1,
                    "uom": "visit",
                    "unit_price": 165.0,
                },
                {
                    "kind": "labor",
                    "description": "Estimator labor",
                    "quantity": 2,
                    "uom": "hour",
                    "unit_price": 88.0,
                },
            ],
        }
    ],
}
estimate_create_bundle = build_estimate_bundle(estimate_create_blueprint)
estimate_create_entities = clone_doc(base_entities)
estimate_create_indexes = clone_doc(indexes)
estimate_create_summary = clone_doc(summary)
estimate_create_entities["estimates"]["est_005"] = estimate_create_bundle["estimate"]
estimate_create_entities["estimate_versions"].update(estimate_create_bundle["versions"])
estimate_create_entities["estimate_lines"].update(estimate_create_bundle["lines"])
estimate_create_entities["estimate_approvals"].update(estimate_create_bundle["approvals"])
estimate_create_entities["proposal_artifacts"][
    estimate_create_bundle["proposal_artifact"]["id"]
] = estimate_create_bundle["proposal_artifact"]
estimate_create_indexes.setdefault("estimates_by_status", {}).setdefault("draft", []).append("est_005")
estimate_create_indexes.setdefault("estimates_by_customer", {}).setdefault("cust_008", []).append("est_005")
estimate_create_indexes.setdefault("estimates_by_branch", {}).setdefault("branch_south", []).append("est_005")
estimate_create_summary["counts"]["estimates"] = estimate_create_summary["counts"]["estimates"] + 1
estimate_create_summary["counts"]["estimate_versions"] = (
    estimate_create_summary["counts"]["estimate_versions"] + 1
)
estimate_create_summary["estimate_status_counts"]["draft"] = (
    estimate_create_summary["estimate_status_counts"].get("draft", 0) + 1
)
estimate_create_doc = payload_with_snapshot_state(
    {
        "status": "created",
        "message": "Created estimate draft and reserved revision 1.",
        "estimate_id": "est_005",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    estimate_create_entities,
    estimate_create_indexes,
    estimate_create_summary,
)

estimate_patch_map = {
    estimate_id: payload_with_snapshot(
        {
            "status": "updated",
            "message": "Saved estimate revision changes.",
            "estimate_id": estimate_id,
            "current_version_id": estimate["current_version_id"],
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        }
    )
    for estimate_id, estimate in estimates.items()
}

estimate_send_map = {
    estimate_id: payload_with_snapshot(
        {
            "status": "sent",
            "message": "Published estimate revision to the customer.",
            "estimate_id": estimate_id,
            "proposal_artifact_id": estimate["proposal_artifact_id"],
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        }
    )
    for estimate_id, estimate in estimates.items()
}

estimate_approve_entities = clone_doc(base_entities)
estimate_approve_indexes = clone_doc(indexes)
estimate_approve_summary = clone_doc(summary)
estimate_approve_entities["estimate_approvals"]["estimate_approval_est_002_01"] = {
    "id": "estimate_approval_est_002_01",
    "estimate_id": "est_002",
    "estimate_version_id": "estimate_version_est_002_r1",
    "state": "approved",
    "customer_name": "Morgan Hale",
    "captured_at": "2026-03-11T10:18:00Z",
    "channel": "signature_capture",
    "signature_ref": "sig_est_002_approved",
    "note": "Approved for next available service window.",
    "reason": None,
}
estimate_approve_entities["estimate_versions"]["estimate_version_est_002_r1"]["state"] = "approved"
estimate_approve_entities["estimates"]["est_002"]["status"] = "approved"
estimate_approve_entities["estimates"]["est_002"]["approval_state"] = "approved"
estimate_approve_entities["estimates"]["est_002"]["approval_ids"] = [
    "estimate_approval_est_002_01",
]
estimate_approve_entities["estimates"]["est_002"]["approved_version_id"] = "estimate_version_est_002_r1"
estimate_approve_entities["estimates"]["est_002"]["approved_at"] = "2026-03-11T10:18:00Z"
estimate_approve_entities["estimates"]["est_002"]["updated_at"] = "2026-03-11T10:18:00Z"
move_group_member(
    estimate_approve_indexes["estimates_by_status"],
    "sent",
    "approved",
    "est_002",
)
adjust_counter(estimate_approve_summary["estimate_status_counts"], "sent", -1)
adjust_counter(estimate_approve_summary["estimate_status_counts"], "approved", 1)
estimate_approve_doc_est_002 = payload_with_snapshot_state(
    {
        "status": "approved",
        "message": "Recorded customer approval for the current estimate revision.",
        "estimate_id": "est_002",
        "approval_id": "estimate_approval_est_002_01",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    estimate_approve_entities,
    estimate_approve_indexes,
    estimate_approve_summary,
)

estimate_approve_map = {
    **{
        estimate_id: payload_with_snapshot(
            {
                "status": "approved",
                "message": "Recorded customer approval for the current estimate revision.",
                "estimate_id": estimate_id,
                "approval_id": (
                    estimate["approval_ids"][0]
                    if estimate["approval_ids"]
                    else None
                ),
                "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
            }
        )
        for estimate_id, estimate in estimates.items()
        if estimate_id not in {"est_002", "est_003"}
    },
    "est_002": estimate_approve_doc_est_002,
}

estimate_reject_map = {
    estimate_id: payload_with_snapshot(
        {
            "status": "rejected",
            "message": "Recorded customer rejection and preserved estimate history.",
            "estimate_id": estimate_id,
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        }
    )
    for estimate_id in estimates
}

estimate_convert_entities = clone_doc(estimate_approve_entities)
estimate_convert_indexes = clone_doc(estimate_approve_indexes)
estimate_convert_summary = clone_doc(estimate_approve_summary)
estimate_convert_entities["estimates"]["est_002"]["linked_agreement_id"] = "agreement_002"
estimate_convert_entities["estimates"]["est_002"]["converted_at"] = "2026-03-11T10:19:00Z"
estimate_convert_entities["estimates"]["est_002"]["updated_at"] = "2026-03-11T10:19:00Z"
estimate_convert_doc_est_002 = payload_with_snapshot_state(
    {
        "status": "converted",
        "message": "Converted approved estimate into scheduled work and service agreement.",
        "estimate_id": "est_002",
        "agreement_id": "agreement_002",
        "source_estimate_version_id": "estimate_version_est_002_r1",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    estimate_convert_entities,
    estimate_convert_indexes,
    estimate_convert_summary,
)

estimate_convert_map = {
    "est_002": estimate_convert_doc_est_002,
    "est_004": payload_with_snapshot(
        {
            "status": "converted",
            "message": "Converted approved estimate into scheduled work and service agreement.",
            "estimate_id": "est_004",
            "work_order_id": "wo_020",
            "agreement_id": "agreement_001",
            "source_estimate_version_id": "estimate_version_est_004_r1",
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        }
    )
}

estimate_approval_conflict_doc = payload_with_snapshot(
    {
        "status": "conflict",
        "message": "Approval was submitted against a stale estimate revision.",
        "estimate_id": "est_003",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "conflict",
            conflict_status="stale",
            conflict_message="Estimate revision changed after approval started; refresh before approving.",
            conflict_code="estimate_approval_revision_mismatch",
            conflict_entity_id="est_003",
            estimate_revision_status="mismatch",
            stale_estimate_id="est_003",
        ),
    }
)

estimate_conversion_conflict_doc = payload_with_snapshot(
    {
        "status": "conflict",
        "message": "Conversion was blocked because the approved estimate revision is stale.",
        "estimate_id": "est_003",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "conflict",
            conflict_status="stale",
            conflict_message="Reopen the estimate and confirm the latest revision before converting.",
            conflict_code="estimate_conversion_revision_mismatch",
            conflict_entity_id="est_003",
            estimate_revision_status="mismatch",
            stale_estimate_id="est_003",
        ),
    }
)

contract_list_doc = payload_with_snapshot(
    {
        "agreement_ids": list(service_agreements),
        "agreements": service_agreements,
        "agreement_lines": agreement_lines,
        "recurring_plan_ids": list(recurring_plans),
        "renewal_records": renewal_records,
        "contract_health": contract_health_snapshots,
        "recurring_revenue": recurring_revenue_rollups,
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

contract_create_entities = clone_doc(base_entities)
contract_create_indexes = clone_doc(indexes)
contract_create_summary = clone_doc(summary)
contract_create_entities["service_agreements"]["agreement_004"] = {
    "id": "agreement_004",
    "number": "AGR-7004",
    "status": "draft",
    "source_estimate_id": "est_001",
    "source_estimate_version_id": "estimate_version_est_001_r2",
    "customer_id": "cust_006",
    "branch_id": "branch_south",
    "team_id": "team_south_gamma",
    "covered_site_ids": ["site_006"],
    "covered_asset_ids": ["asset_006"],
    "agreement_line_ids": ["agreement_line_004_service"],
    "recurring_plan_ids": ["recurring_plan_004"],
    "renewal_record_ids": [],
    "health_snapshot_id": "contract_health_agreement_004",
    "owner_user_id": "user_manager_jonas",
    "currency": "USD",
    "annual_value": 1980.0,
    "recurring_revenue_monthly": 165.0,
    "start_date": "2026-04-01",
    "end_date": "2027-03-31",
    "renewal_date": "2027-02-15",
    "service_window": "11:00-13:00",
    "sla_tier": "gold",
    "response_commitment": "same_day",
    "paused_at": None,
    "resumed_at": None,
    "notes": "Draft agreement created from estimate composer.",
}
contract_create_entities["agreement_lines"]["agreement_line_004_service"] = {
    "id": "agreement_line_004_service",
    "agreement_id": "agreement_004",
    "kind": "hvac_service",
    "description": "Quarterly HVAC maintenance coverage",
    "included_quantity": 4,
    "uom": "visit",
    "annual_value": 1980.0,
}
contract_create_entities["recurrence_rules"]["recurrence_rule_004"] = {
    "id": "recurrence_rule_004",
    "plan_id": "recurring_plan_004",
    "cadence_unit": "month",
    "interval": 3,
    "day_of_month": 1,
    "timezone": "America/Los_Angeles",
}
contract_create_entities["recurring_plans"]["recurring_plan_004"] = {
    "id": "recurring_plan_004",
    "agreement_id": "agreement_004",
    "rule_id": "recurrence_rule_004",
    "status": "draft",
    "next_scheduled_date": "2026-04-01",
    "service_window": "11:00-13:00",
    "covered_site_ids": ["site_006"],
    "covered_asset_ids": ["asset_006"],
    "included_service_types": ["pm"],
    "branch_id": "branch_south",
    "team_id": "team_south_gamma",
    "last_generated_at": None,
    "generation_revision": 0,
    "last_generated_schedule_item_id": None,
    "skip_history_ids": [],
}
contract_create_entities["contract_health_snapshots"]["contract_health_agreement_004"] = {
    "id": "contract_health_agreement_004",
    "agreement_id": "agreement_004",
    "health_status": "draft",
    "service_completion_pct": 0.0,
    "skipped_occurrences": 0,
    "overdue_occurrences": 0,
    "renewal_risk": "low",
    "revenue_at_risk": 0.0,
}
contract_create_indexes.setdefault("agreements_by_status", {}).setdefault("draft", []).append("agreement_004")
contract_create_indexes.setdefault("agreements_by_customer", {}).setdefault("cust_006", []).append("agreement_004")
contract_create_indexes.setdefault("agreements_by_branch", {}).setdefault("branch_south", []).append("agreement_004")
contract_create_indexes.setdefault("recurring_plans_by_status", {}).setdefault("draft", []).append("recurring_plan_004")
contract_create_indexes.setdefault("recurring_plans_by_agreement", {}).setdefault("agreement_004", []).append("recurring_plan_004")
contract_create_summary["counts"]["service_agreements"] = contract_create_summary["counts"]["service_agreements"] + 1
contract_create_summary["counts"]["recurring_plans"] = contract_create_summary["counts"]["recurring_plans"] + 1
contract_create_summary["agreement_status_counts"]["draft"] = (
    contract_create_summary["agreement_status_counts"].get("draft", 0) + 1
)
contract_create_summary["recurring_plan_status_counts"]["draft"] = (
    contract_create_summary["recurring_plan_status_counts"].get("draft", 0) + 1
)
contract_create_doc = payload_with_snapshot_state(
    {
        "status": "created",
        "message": "Created service agreement draft and recurring plan shell.",
        "agreement_id": "agreement_004",
        "recurring_plan_id": "recurring_plan_004",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    contract_create_entities,
    contract_create_indexes,
    contract_create_summary,
)


def build_contract_resume_doc(
    entities_snapshot,
    indexes_snapshot,
    summary_snapshot,
    agreement_id,
    recurring_plan_id,
    resumed_at,
):
    next_entities = clone_doc(entities_snapshot)
    next_indexes = clone_doc(indexes_snapshot)
    next_summary = clone_doc(summary_snapshot)
    previous_agreement_status = next_entities["service_agreements"][agreement_id]["status"]
    previous_plan_status = next_entities["recurring_plans"][recurring_plan_id]["status"]

    next_entities["service_agreements"][agreement_id]["status"] = "active"
    next_entities["service_agreements"][agreement_id]["paused_at"] = None
    next_entities["service_agreements"][agreement_id]["resumed_at"] = resumed_at
    next_entities["service_agreements"][agreement_id].pop("pause_reason", None)
    next_entities["recurring_plans"][recurring_plan_id]["status"] = "active"
    next_entities["recurring_plans"][recurring_plan_id].pop("pause_reason", None)
    next_entities["contract_health_snapshots"][
        next_entities["service_agreements"][agreement_id]["health_snapshot_id"]
    ]["health_status"] = "active"

    move_group_member(
        next_indexes["agreements_by_status"],
        previous_agreement_status,
        "active",
        agreement_id,
    )
    move_group_member(
        next_indexes["recurring_plans_by_status"],
        previous_plan_status,
        "active",
        recurring_plan_id,
    )
    adjust_counter(next_summary["agreement_status_counts"], previous_agreement_status, -1)
    adjust_counter(next_summary["agreement_status_counts"], "active", 1)
    adjust_counter(next_summary["recurring_plan_status_counts"], previous_plan_status, -1)
    adjust_counter(next_summary["recurring_plan_status_counts"], "active", 1)
    if previous_agreement_status == "paused":
        adjust_counter(next_summary["contract_health_overview"], "paused", -1)
        adjust_counter(next_summary["recurring_revenue_summary"], "paused_agreements", -1)
    adjust_counter(next_summary["contract_health_overview"], "active", 1)
    adjust_counter(next_summary["recurring_revenue_summary"], "active_agreements", 1)

    return payload_with_snapshot_state(
        {
            "status": "resumed",
            "message": "Resumed service agreement and restored next scheduled service.",
            "agreement_id": agreement_id,
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        },
        next_entities,
        next_indexes,
        next_summary,
    )

contract_patch_map = {
    agreement_id: payload_with_snapshot(
        {
            "status": "updated",
            "message": "Updated agreement coverage and billing metadata.",
            "agreement_id": agreement_id,
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        }
    )
    for agreement_id in service_agreements
}

contract_pause_map = {
    agreement_id: payload_with_snapshot(
        {
            "status": "paused",
            "message": "Paused service agreement and preserved recurring history.",
            "agreement_id": agreement_id,
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        }
    )
    for agreement_id in service_agreements
}

contract_resume_map = {
    **{
        agreement_id: payload_with_snapshot(
            {
                "status": "resumed",
                "message": "Resumed service agreement and restored next scheduled service.",
                "agreement_id": agreement_id,
                "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
            }
        )
        for agreement_id in service_agreements
        if agreement_id != "agreement_002"
    },
    "agreement_002": build_contract_resume_doc(
        base_entities,
        indexes,
        summary,
        "agreement_002",
        "recurring_plan_002",
        "2026-03-11T10:21:00Z",
    ),
    "agreement_004": build_contract_resume_doc(
        contract_create_entities,
        contract_create_indexes,
        contract_create_summary,
        "agreement_004",
        "recurring_plan_004",
        "2026-03-11T10:24:00Z",
    ),
}

contract_renew_map = {
    "agreement_001": payload_with_snapshot(
        {
            "status": "renewed",
            "message": "Created renewal record and preserved prior agreement history.",
            "agreement_id": "agreement_001",
            "renewal_record_id": "renewal_001",
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        }
    ),
    "agreement_002": payload_with_snapshot(
        {
            "status": "renewed",
            "message": "Created renewal record and preserved prior agreement history.",
            "agreement_id": "agreement_002",
            "renewal_record_id": "renewal_001",
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        }
    ),
}

contract_renewal_conflict_doc = payload_with_snapshot(
    {
        "status": "conflict",
        "message": "Renewal was blocked because a newer agreement revision already exists.",
        "agreement_id": "agreement_003",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "conflict",
            conflict_status="stale",
            conflict_message="Agreement renewal is revision-sensitive; refresh before renewing.",
            conflict_code="agreement_renewal_revision_mismatch",
            conflict_entity_id="agreement_003",
            agreement_revision_status="mismatch",
            stale_agreement_id="agreement_003",
        ),
    }
)

recurring_board_doc = payload_with_snapshot(
    {
        "plan_ids": list(recurring_plans),
        "plans": recurring_plans,
        "rules": recurrence_rules,
        "schedule_items": generated_schedule_items,
        "board": {
            "upcoming_schedule_item_ids": [
                item_id
                for item_id, item in generated_schedule_items.items()
                if item["status"] in {"planned", "generated"}
            ],
            "skipped_schedule_item_ids": indexes["generated_schedule_items_by_plan"].get("recurring_plan_002", []),
        },
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

recurring_generate_map = {
    "recurring_plan_001": payload_with_snapshot(
        {
            "status": "generated",
            "message": "Generated future schedule items without duplicates.",
            "plan_id": "recurring_plan_001",
            "generated_schedule_item_ids": ["schedule_item_001", "schedule_item_002"],
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        }
    ),
    "recurring_plan_002": payload_with_snapshot(
        {
            "status": "generated",
            "message": "Generated future schedule items without duplicates.",
            "plan_id": "recurring_plan_002",
            "generated_schedule_item_ids": ["schedule_item_003"],
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        }
    ),
}

recurring_skip_map = {
    plan_id: payload_with_snapshot(
        {
            "status": "skipped",
            "message": "Skipped the next recurring occurrence and preserved history.",
            "plan_id": plan_id,
            "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
        }
    )
    for plan_id in recurring_plans
}

recurring_generation_conflict_doc = payload_with_snapshot(
    {
        "status": "conflict",
        "message": "Recurring generation was blocked because a newer plan revision already generated future work.",
        "plan_id": "recurring_plan_003",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "conflict",
            conflict_status="stale",
            conflict_message="Recurring plan changed after future occurrences were generated; refresh before generating again.",
            conflict_code="recurring_generation_revision_mismatch",
            conflict_entity_id="recurring_plan_003",
            recurring_generation_status="mismatch",
            stale_recurring_plan_id="recurring_plan_003",
        ),
    }
)

integrations_center_doc = payload_with_snapshot(
    {
        "endpoint_ids": list(integration_endpoints),
        "api_key_ids": list(api_key_records),
        "webhook_subscription_ids": list(webhook_subscriptions),
        "connector_mapping_ids": list(connector_mappings),
        "sync_job_ids": list(import_or_sync_jobs),
        "delivery_summary": summary["integration_summary"],
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

integrations_deliveries_doc = payload_with_snapshot(
    {
        "delivery_ids": list(webhook_deliveries),
        "deliveries": webhook_deliveries,
        "failed_delivery_ids": indexes["webhook_deliveries_by_status"].get("failed", []),
        "duplicate_delivery_ids": indexes["webhook_deliveries_by_status"].get("duplicate", []),
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

api_key_create_entities = clone_doc(base_entities)
api_key_create_summary = clone_doc(summary)
api_key_create_entities["api_key_records"]["api_key_003"] = {
    "id": "api_key_003",
    "label": "New integration key",
    "status": "active",
    "key_prefix": "x07_live_new",
    "masked_secret": "x07_live_new_****Q2R4",
    "created_at": "2026-03-11T10:20:00Z",
    "rotated_at": None,
    "expires_at": "2026-12-31T00:00:00Z",
    "last_used_at": None,
    "scope_ids": ["integrations.read", "deliveries.read"],
}
api_key_create_indexes = clone_doc(indexes)
api_key_create_indexes.setdefault("api_keys_by_status", {}).setdefault("active", []).append("api_key_003")
api_key_create_summary["integration_summary"]["active_api_keys"] = (
    api_key_create_summary["integration_summary"]["active_api_keys"] + 1
)
integrations_api_key_create_doc = payload_with_snapshot_state(
    {
        "status": "created",
        "message": "Created API key metadata and masked the new secret.",
        "api_key_id": "api_key_003",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    api_key_create_entities,
    api_key_create_indexes,
    api_key_create_summary,
)

webhook_create_entities = clone_doc(base_entities)
webhook_create_indexes = clone_doc(indexes)
webhook_create_summary = clone_doc(summary)
webhook_create_entities["webhook_subscriptions"]["webhook_003"] = {
    "id": "webhook_003",
    "label": "Estimate lifecycle mirror",
    "status": "active",
    "endpoint_id": "integration_endpoint_crm",
    "endpoint_url": "https://example.test/hooks/estimates",
    "event_types": ["estimate.approved", "estimate.converted"],
    "masked_secret": "whsec_****4db3",
    "created_at": "2026-03-11T10:22:00Z",
    "last_delivery_at": None,
    "failure_count": 0,
    "connector_mapping_ids": ["connector_mapping_001"],
}
webhook_create_summary["counts"]["webhook_subscriptions"] = (
    webhook_create_summary["counts"]["webhook_subscriptions"] + 1
)
webhook_create_summary["integration_summary"]["active_webhooks"] = (
    webhook_create_summary["integration_summary"]["active_webhooks"] + 1
)
integrations_webhook_create_doc = payload_with_snapshot_state(
    {
        "status": "created",
        "message": "Created webhook subscription with masked secret metadata.",
        "webhook_subscription_id": "webhook_003",
        "sync": sync_doc("sync_cursor_2026_03_11_103", "accepted"),
    },
    webhook_create_entities,
    webhook_create_indexes,
    webhook_create_summary,
)

delivery_retry_entities = clone_doc(base_entities)
delivery_retry_indexes = clone_doc(indexes)
delivery_retry_summary = clone_doc(summary)
delivery_retry_entities["webhook_deliveries"]["delivery_002"]["attempt_count"] = 4
delivery_retry_entities["webhook_deliveries"]["delivery_002"]["last_attempt_at"] = "2026-03-11T09:31:00Z"
delivery_retry_entities["webhook_deliveries"]["delivery_002"]["next_retry_at"] = "2026-03-11T10:15:00Z"
delivery_retry_entities["webhook_deliveries"]["delivery_002"]["response_summary"] = (
    "Retry attempted, but the downstream connector still timed out."
)
delivery_retry_entities["webhook_deliveries"]["delivery_002"]["delivery_revision"] = "delivery_rev_005"
integrations_delivery_retry_doc = payload_with_snapshot_state(
    {
        "status": "retry_requested",
        "message": "Retried the failed delivery and recorded the downstream timeout for operator follow-up.",
        "delivery_id": "delivery_002",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            conflict_status="stale",
            conflict_message="Delivery remains failed after retry; inspect the delivery log.",
            conflict_code="webhook_delivery_retry_required",
            conflict_entity_id="delivery_002",
            delivery_retry_status="retry_required",
            stale_delivery_id="delivery_002",
        ),
    },
    delivery_retry_entities,
    delivery_retry_indexes,
    delivery_retry_summary,
)

enterprise_admin_doc = payload_with_full_state(
    {
        "tenant_ids": list(tenants),
        "workspace_ids": list(workspaces),
        "hierarchy_node_ids": list(org_hierarchy_nodes),
        "role_ids": list(role_definitions),
        "branding_pack_ids": list(branding_packs),
        "tenant_health_ids": list(tenant_health_snapshots),
        "readiness": {
            "status": "ready",
            "hosted_profile": "crewops_release",
            "pack_ready": True,
            "device_profiles_ready": False,
        },
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

admin_roles_doc = payload_with_full_state(
    {
        "role_ids": list(role_definitions),
        "permission_grant_ids": list(permission_grants),
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

admin_tenant_create_entities = clone_doc(base_entities)
admin_tenant_create_indexes = clone_doc(indexes)
admin_tenant_create_summary = clone_doc(summary)
admin_tenant_create_entities["tenants"]["tenant_lakeside"] = {
    "id": "tenant_lakeside",
    "status": "draft",
    "name": "Lakeside Service Group",
    "display_name": "Lakeside Service",
    "kind": "child_tenant",
    "parent_tenant_id": "tenant_northline",
    "workspace_ids": [],
    "branding_pack_id": None,
    "portal_config": {
        "title": "Lakeside Portal",
        "allow_estimate_approval": True,
        "allow_request_intake": True,
        "show_invoice_balance": False,
    },
    "feature_flags": {
        "portal": True,
        "inventory": False,
        "procurement": False,
        "connectors": False,
        "white_label": True,
    },
    "readiness_status": "draft",
    "revision": 1,
}
admin_tenant_create_summary["counts"]["tenants"] = admin_tenant_create_summary["counts"]["tenants"] + 1
admin_tenant_create_doc = payload_with_full_state(
    {
        "status": "created",
        "message": "Created tenant draft and queued branding setup.",
        "tenant_id": "tenant_lakeside",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            tenant_revision_status="accepted",
        ),
    },
    admin_tenant_create_entities,
    admin_tenant_create_indexes,
    admin_tenant_create_summary,
)

admin_tenant_patch_map = {
    tenant_id: payload_with_full_state(
        {
            "status": "updated",
            "message": "Updated tenant settings and readiness snapshot.",
            "tenant_id": tenant_id,
            "sync": sync_doc(
                "sync_cursor_2026_03_11_103",
                "accepted",
                tenant_revision_status="accepted",
                stale_tenant_id=tenant_id,
            ),
        }
    )
    for tenant_id in tenants
}

admin_role_create_entities = clone_doc(base_entities)
admin_role_create_indexes = clone_doc(indexes)
admin_role_create_summary = clone_doc(summary)
admin_role_create_entities["role_definitions"]["role_dispatch_lead"] = {
    "id": "role_dispatch_lead",
    "tenant_id": "tenant_northline",
    "label": "Dispatch Lead",
    "scope_kind": "workspace",
    "system_role": False,
}
admin_role_create_entities["permission_grants"]["permission_grant_004"] = {
    "id": "permission_grant_004",
    "role_id": "role_dispatch_lead",
    "scope_id": "workspace_branch_north",
    "permissions": ["dispatch.manage", "dashboard.view"],
    "assigned_user_ids": ["user_dispatch_rhea"],
}
admin_role_create_doc = payload_with_full_state(
    {
        "status": "created",
        "message": "Created scoped dispatch-lead role and grant.",
        "role_id": "role_dispatch_lead",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            tenant_revision_status="accepted",
        ),
    },
    admin_role_create_entities,
    admin_role_create_indexes,
    admin_role_create_summary,
)

admin_branding_update_entities = clone_doc(base_entities)
admin_branding_update_indexes = clone_doc(indexes)
admin_branding_update_summary = clone_doc(summary)
admin_branding_update_entities["branding_packs"]["branding_pack_northline"]["accent_color"] = "#9a4a1f"
admin_branding_update_entities["branding_packs"]["branding_pack_northline"]["portal_title"] = "Northline Customer Care Portal"
admin_branding_update_entities["branding_packs"]["branding_pack_northline"]["revision"] = 8
admin_branding_update_doc = payload_with_full_state(
    {
        "status": "updated",
        "message": "Updated tenant branding pack and refreshed portal theme preview.",
        "branding_pack_id": "branding_pack_northline",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            tenant_revision_status="accepted",
            stale_tenant_id="tenant_northline",
        ),
    },
    admin_branding_update_entities,
    admin_branding_update_indexes,
    admin_branding_update_summary,
)

portal_session_doc = payload_with_full_state(
    {
        "session": {
            "token": "portal_user_token",
            "role": "portal_user",
            "user_id": "user_portal_morgan",
            "branch_id": "branch_north",
            "team_id": None,
            "status": "ready",
        },
        "portal_account_id": "portal_account_001",
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

portal_me_doc = payload_with_full_state(
    {
        "portal_account_id": "portal_account_001",
        "tenant_id": "tenant_northline",
        "pending_estimate_id": "est_004",
        "invoice_ids": portal_accounts["portal_account_001"]["invoice_ids"],
        "upcoming_visit_ids": portal_accounts["portal_account_001"]["upcoming_visit_ids"],
        "timeline_event_ids": portal_accounts["portal_account_001"]["timeline_event_ids"],
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

portal_invoices_doc = payload_with_full_state(
    {
        "portal_account_id": "portal_account_001",
        "invoice_ids": portal_accounts["portal_account_001"]["invoice_ids"],
        "invoices": {
            invoice_id: invoices[invoice_id]
            for invoice_id in portal_accounts["portal_account_001"]["invoice_ids"]
        },
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

portal_service_history_doc = payload_with_full_state(
    {
        "portal_account_id": "portal_account_001",
        "timeline_event_ids": portal_accounts["portal_account_001"]["timeline_event_ids"],
        "timeline_events": customer_timeline_events,
        "service_request_ids": portal_accounts["portal_account_001"]["service_request_ids"],
        "upcoming_visit_ids": portal_accounts["portal_account_001"]["upcoming_visit_ids"],
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

portal_request_create_entities = clone_doc(base_entities)
portal_request_create_indexes = clone_doc(indexes)
portal_request_create_summary = clone_doc(summary)
portal_request_create_entities["service_requests"]["service_request_003"] = {
    "id": "service_request_003",
    "tenant_id": "tenant_northline",
    "portal_account_id": "portal_account_001",
    "customer_id": "cust_020",
    "status": "submitted",
    "priority": "high",
    "summary": "Lobby drain backup and odor check",
    "structured_intake": {
        "site_id": "site_020",
        "asset_id": "asset_020",
        "requested_window": "2026-03-22",
        "issue_kind": "drain_backup",
    },
    "converted_work_order_id": None,
    "estimate_id": None,
    "connector_reference": None,
    "revision": 1,
}
portal_request_create_indexes["service_requests_by_tenant"]["tenant_northline"].append("service_request_003")
portal_request_create_indexes["service_requests_by_status"].setdefault("submitted", []).append("service_request_003")
portal_request_create_summary["counts"]["service_requests"] = (
    portal_request_create_summary["counts"]["service_requests"] + 1
)
portal_request_create_doc = payload_with_full_state(
    {
        "status": "created",
        "message": "Submitted portal request and queued office triage.",
        "service_request_id": "service_request_003",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            portal_approval_status="accepted",
            stale_portal_request_id="service_request_003",
        ),
    },
    portal_request_create_entities,
    portal_request_create_indexes,
    portal_request_create_summary,
)

portal_request_convert_entities = clone_doc(portal_request_create_entities)
portal_request_convert_indexes = clone_doc(portal_request_create_indexes)
portal_request_convert_summary = clone_doc(portal_request_create_summary)
portal_request_convert_entities["service_requests"]["service_request_001"]["status"] = "converted"
portal_request_convert_entities["service_requests"]["service_request_001"]["converted_work_order_id"] = "wo_024"
portal_request_convert_entities["service_requests"]["service_request_001"]["connector_reference"] = "crm_ticket_442"
portal_request_convert_entities["customer_timeline_events"]["timeline_event_005"] = {
    "id": "timeline_event_005",
    "tenant_id": "tenant_northline",
    "portal_account_id": "portal_account_001",
    "kind": "request_converted",
    "summary": "Office triage converted the request into work order WO-1224.",
    "visible_to_customer": True,
    "source_request_id": "service_request_001",
    "work_order_id": "wo_024",
    "connector_reference": "crm_ticket_442",
    "created_at": "2026-03-11T10:45:00Z",
}
portal_request_convert_entities["portal_accounts"]["portal_account_001"]["timeline_event_ids"].append(
    "timeline_event_005"
)
portal_request_convert_indexes["service_requests_by_status"].setdefault("converted", []).append(
    "service_request_001"
)
portal_request_convert_summary["counts"]["customer_timeline_events"] = (
    portal_request_convert_summary["counts"].get("customer_timeline_events", len(customer_timeline_events))
    + 1
)
portal_request_convert_map = {
    "service_request_001": payload_with_full_state(
        {
            "status": "converted",
            "message": "Converted portal request into an office work order and linked the customer timeline.",
            "service_request_id": "service_request_001",
            "work_order_id": "wo_024",
            "connector_reference": "crm_ticket_442",
            "sync": sync_doc(
                "sync_cursor_2026_03_11_103",
                "accepted",
                portal_approval_status="accepted",
                stale_portal_request_id="service_request_001",
            ),
        },
        portal_request_convert_entities,
        portal_request_convert_indexes,
        portal_request_convert_summary,
    )
}

portal_estimate_approve_doc = payload_with_full_state(
    {
        "status": "approved",
        "message": "Recorded portal estimate approval and linked it to the office timeline.",
        "estimate_id": "est_004",
        "service_request_id": "service_request_001",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            portal_approval_status="approved",
            stale_portal_request_id="service_request_001",
        ),
    }
)

portal_approval_conflict_doc = payload_with_full_state(
    {
        "status": "conflict",
        "message": "Portal approval targeted a stale estimate revision.",
        "estimate_id": "est_004",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "conflict",
            conflict_status="stale",
            conflict_message="Refresh portal approval state before retrying.",
            conflict_code="portal_approval_revision_mismatch",
            conflict_entity_id="est_004",
            portal_approval_status="mismatch",
            stale_portal_request_id="service_request_001",
        ),
    }
)

inventory_items_doc = payload_with_full_state(
    {
        "inventory_item_ids": list(inventory_items),
        "stock_location_ids": list(stock_locations),
        "movement_ids": list(stock_movements),
        "cycle_count_ids": list(cycle_counts),
        "low_stock_item_ids": summary["inventory_summary"]["low_stock_item_ids"],
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

inventory_movement_entities = clone_doc(base_entities)
inventory_movement_indexes = clone_doc(indexes)
inventory_movement_summary = clone_doc(summary)
inventory_movement_entities["stock_movements"]["stock_movement_003"] = {
    "id": "stock_movement_003",
    "tenant_id": "tenant_northline",
    "inventory_item_id": "inventory_item_contact_cleaner",
    "location_id": "stock_location_van_gamma",
    "kind": "consume",
    "quantity": 1,
    "status": "posted",
    "reason": "Consumed during panel reset follow-up.",
    "source_work_order_id": "wo_024",
    "revision": 1,
}
inventory_movement_indexes["stock_movements_by_location"].setdefault(
    "stock_location_van_gamma", []
).append("stock_movement_003")
inventory_movement_indexes["stock_movements_by_status"].setdefault("posted", []).append(
    "stock_movement_003"
)
inventory_movement_summary["counts"]["stock_movements"] = (
    inventory_movement_summary["counts"]["stock_movements"] + 1
)
inventory_movement_doc = payload_with_full_state(
    {
        "status": "posted",
        "message": "Recorded stock consumption and updated variance diagnostics.",
        "stock_movement_id": "stock_movement_003",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            inventory_movement_status="accepted",
            stale_stock_location_id="stock_location_van_gamma",
        ),
    },
    inventory_movement_entities,
    inventory_movement_indexes,
    inventory_movement_summary,
)

inventory_count_doc = payload_with_full_state(
    {
        "status": "count_recorded",
        "message": "Recorded cycle-count variance for north warehouse.",
        "cycle_count_id": "cycle_count_001",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            inventory_movement_status="variance",
            stale_stock_location_id="stock_location_warehouse_north",
        ),
    }
)

procurement_orders_doc = payload_with_full_state(
    {
        "vendor_ids": list(vendors),
        "purchase_order_ids": list(purchase_orders),
        "reorder_suggestion_ids": list(reorder_suggestions),
        "receiving_record_ids": list(receiving_records),
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

procurement_po_create_entities = clone_doc(base_entities)
procurement_po_create_indexes = clone_doc(indexes)
procurement_po_create_summary = clone_doc(summary)
procurement_po_create_entities["purchase_orders"]["purchase_order_003"] = {
    "id": "purchase_order_003",
    "tenant_id": "tenant_northline",
    "vendor_id": "vendor_supply_hub",
    "status": "draft",
    "branch_id": "branch_north",
    "expected_delivery_date": "2026-03-18",
    "line_ids": [],
    "revision": 1,
}
procurement_po_create_indexes["purchase_orders_by_tenant"]["tenant_northline"].append(
    "purchase_order_003"
)
procurement_po_create_indexes["purchase_orders_by_status"].setdefault("draft", []).append(
    "purchase_order_003"
)
procurement_po_create_indexes["purchase_orders_by_vendor"]["vendor_supply_hub"].append(
    "purchase_order_003"
)
procurement_po_create_summary["counts"]["purchase_orders"] = (
    procurement_po_create_summary["counts"]["purchase_orders"] + 1
)
procurement_po_create_doc = payload_with_full_state(
    {
        "status": "created",
        "message": "Created purchase order draft from replenishment queue.",
        "purchase_order_id": "purchase_order_003",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            receiving_status="draft",
            stale_purchase_order_id="purchase_order_003",
        ),
    },
    procurement_po_create_entities,
    procurement_po_create_indexes,
    procurement_po_create_summary,
)

procurement_receive_doc = payload_with_full_state(
    {
        "status": "received",
        "message": "Recorded partial receiving and preserved PO variance history.",
        "purchase_order_id": "purchase_order_002",
        "receiving_record_id": "receiving_record_001",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            receiving_status="partial",
            stale_purchase_order_id="purchase_order_002",
        ),
    }
)

connectors_vendor_doc = payload_with_full_state(
    {
        "connector_instance_ids": list(connector_instances),
        "connector_sync_job_ids": list(connector_sync_jobs),
        "connector_delivery_record_ids": list(connector_delivery_records),
        "provider_classes": ["accounting", "payments", "crm", "ticketing"],
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
)

connectors_vendor_create_entities = clone_doc(base_entities)
connectors_vendor_create_indexes = clone_doc(indexes)
connectors_vendor_create_summary = clone_doc(summary)
connectors_vendor_create_entities["connector_instances"]["connector_instance_payables"] = {
    "id": "connector_instance_payables",
    "tenant_id": "tenant_northline",
    "provider_class": "accounting",
    "provider_name": "LedgerCloud AP",
    "status": "healthy",
    "config_revision": 1,
    "last_success_at": None,
    "mapping_ids": [],
}
connectors_vendor_create_indexes["connector_instances_by_tenant"]["tenant_northline"].append(
    "connector_instance_payables"
)
connectors_vendor_create_indexes["connector_instances_by_status"].setdefault("healthy", []).append(
    "connector_instance_payables"
)
connectors_vendor_create_indexes["connector_instances_by_provider"].setdefault(
    "accounting", []
).append("connector_instance_payables")
connectors_vendor_create_summary["counts"]["connector_instances"] = (
    connectors_vendor_create_summary["counts"]["connector_instances"] + 1
)
connectors_vendor_create_doc = payload_with_full_state(
    {
        "status": "created",
        "message": "Created vendor connector instance with safe display metadata only.",
        "connector_instance_id": "connector_instance_payables",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "accepted",
            connector_config_status="accepted",
            stale_connector_instance_id="connector_instance_payables",
        ),
    },
    connectors_vendor_create_entities,
    connectors_vendor_create_indexes,
    connectors_vendor_create_summary,
)

connectors_vendor_sync_map = {
    connector_instance_id: payload_with_full_state(
        {
            "status": "sync_requested",
            "message": "Queued provider-specific sync and preserved audit history.",
            "connector_instance_id": connector_instance_id,
            "sync": sync_doc(
                "sync_cursor_2026_03_11_103",
                "accepted",
                connector_config_status="accepted",
                stale_connector_instance_id=connector_instance_id,
            ),
        }
    )
    for connector_instance_id in connector_instances
}
connectors_vendor_sync_map["connector_instance_ticketing"] = payload_with_full_state(
    {
        "status": "conflict",
        "message": "Connector config revision is stale and must be refreshed before sync.",
        "connector_instance_id": "connector_instance_ticketing",
        "sync": sync_doc(
            "sync_cursor_2026_03_11_103",
            "conflict",
            conflict_status="stale",
            conflict_message="Refresh connector config before retrying sync.",
            conflict_code="connector_config_revision_mismatch",
            conflict_entity_id="connector_instance_ticketing",
            connector_config_status="mismatch",
            stale_connector_instance_id="connector_instance_ticketing",
        ),
    }
)

connectors_vendor_deliveries_map = {
    connector_instance_id: payload_with_full_state(
        {
            "connector_instance_id": connector_instance_id,
            "delivery_record_ids": [
                delivery_record_id
                for delivery_record_id, delivery_record in connector_delivery_records.items()
                if delivery_record["connector_instance_id"] == connector_instance_id
            ],
            "delivery_records": {
                delivery_record_id: delivery_record
                for delivery_record_id, delivery_record in connector_delivery_records.items()
                if delivery_record["connector_instance_id"] == connector_instance_id
            },
            "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
        }
    )
    for connector_instance_id in connector_instances
}

release_readiness_doc = payload_with_full_state(
    {
        "readiness": {
            "app_profile": "crewops_release",
            "pack_ready": True,
            "desktop_profile_ready": True,
            "mobile_base_url_configured": False,
            "hosted_prep_smoke": "non_blocking",
            "connector_artifact_handling": "ready",
        },
        "todo_items": [
            "Configure real iOS/Android backend base_url.",
            "Promote hosted prep smoke from profile sanity to live probe once environment is configured.",
        ],
        "sync": sync_doc("sync_cursor_2026_03_11_101", "idle"),
    }
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
        {
            "kind": "invoice",
            "entity_id": "inv_005",
            "work_order_id": "wo_019",
        },
        {
            "kind": "pricing_policy",
            "entity_id": "price_book_customer_cust_018",
            "work_order_id": "wo_018",
        },
        {
            "kind": "export_job",
            "entity_id": "export_job_002",
            "work_order_id": "wo_024",
        },
        {
            "kind": "estimate",
            "entity_id": "est_003",
            "work_order_id": "wo_018",
        },
        {
            "kind": "service_agreement",
            "entity_id": "agreement_003",
            "work_order_id": "wo_018",
        },
        {
            "kind": "recurring_plan",
            "entity_id": "recurring_plan_003",
            "work_order_id": "wo_018",
        },
        {
            "kind": "webhook_delivery",
            "entity_id": "delivery_002",
            "work_order_id": "wo_018",
        },
        {
            "kind": "portal_request",
            "entity_id": "service_request_001",
            "work_order_id": "wo_018",
        },
        {
            "kind": "inventory_movement",
            "entity_id": "stock_movement_002",
            "work_order_id": "wo_018",
        },
        {
            "kind": "purchase_order",
            "entity_id": "purchase_order_002",
            "work_order_id": "wo_018",
        },
        {
            "kind": "connector_instance",
            "entity_id": "connector_instance_ticketing",
            "work_order_id": "wo_018",
        },
    ],
    "status": "idle",
    "received_at": now,
    "server_policies": {
        "signature_required_on_complete": True,
        "location_capture_optional": True,
        "offline_queue_mode": "client_ops_v1",
        "invoice_lock_mode": "revision_sensitive",
        "payment_record_mode": "append_only",
        "estimate_approval_mode": "revision_sensitive",
        "agreement_renewal_mode": "append_history",
        "recurring_generation_mode": "dedupe_by_plan_revision",
        "delivery_retry_mode": "append_only",
        "portal_approval_mode": "revision_sensitive",
        "tenant_revision_mode": "revision_sensitive",
        "inventory_movement_mode": "append_only",
        "receiving_mode": "append_history",
        "connector_config_mode": "revision_sensitive",
    },
    "entities": {
        "assignments": assignments,
        "review_queue_items": review_queue_items,
        "correction_tasks": correction_tasks,
        "activity_events": activity_events,
        "alerts": alerts,
        "price_books": price_books,
        "billing_policies": billing_policies,
        "invoices": invoices,
        "invoice_artifacts": invoice_artifacts,
        "payment_records": payment_records,
        "payment_allocations": payment_allocations,
        "export_jobs": export_jobs,
        "receivable_summaries": receivable_summaries,
        "estimates": estimates,
        "estimate_versions": estimate_versions,
        "estimate_lines": estimate_lines,
        "estimate_approvals": estimate_approvals,
        "proposal_artifacts": proposal_artifacts,
        "service_agreements": service_agreements,
        "agreement_lines": agreement_lines,
        "recurring_plans": recurring_plans,
        "recurrence_rules": recurrence_rules,
        "generated_schedule_items": generated_schedule_items,
        "renewal_records": renewal_records,
        "contract_health_snapshots": contract_health_snapshots,
        "integration_endpoints": integration_endpoints,
        "api_key_records": api_key_records,
        "webhook_subscriptions": webhook_subscriptions,
        "webhook_deliveries": webhook_deliveries,
        "connector_mappings": connector_mappings,
        "import_or_sync_jobs": import_or_sync_jobs,
        "recurring_revenue_rollups": recurring_revenue_rollups,
        "tenants": tenants,
        "workspaces": workspaces,
        "role_definitions": role_definitions,
        "permission_grants": permission_grants,
        "branding_packs": branding_packs,
        "portal_accounts": portal_accounts,
        "service_requests": service_requests,
        "customer_timeline_events": customer_timeline_events,
        "inventory_items": inventory_items,
        "stock_locations": stock_locations,
        "stock_movements": stock_movements,
        "vendors": vendors,
        "purchase_orders": purchase_orders,
        "purchase_order_lines": purchase_order_lines,
        "receiving_records": receiving_records,
        "reorder_suggestions": reorder_suggestions,
        "connector_instances": connector_instances,
        "connector_sync_jobs": connector_sync_jobs,
        "connector_delivery_records": connector_delivery_records,
        "tenant_health_snapshots": tenant_health_snapshots,
        "portal_adoption_rollups": portal_adoption_rollups,
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
        "op_invoice_patch_inv_001",
        "op_payment_record_inv_004",
        "op_export_retry_002",
        "op_estimate_send_est_001",
        "op_contract_pause_agreement_002",
        "op_recurring_skip_plan_002",
        "op_webhook_retry_delivery_002",
        "op_portal_approve_estimate_004",
        "op_inventory_consume_contact_cleaner",
        "op_procurement_receive_po_002",
        "op_connector_sync_ticketing",
    ],
    "conflicts": [
        {
            "kind": "estimate_approval",
            "entity_id": "est_003",
            "code": "estimate_approval_revision_mismatch",
            "message": "Refresh estimate revision before retrying approval.",
        },
        {
            "kind": "webhook_delivery",
            "entity_id": "delivery_002",
            "code": "webhook_delivery_retry_required",
            "message": "Delivery remains failed after retry; inspect the delivery log.",
        },
        {
            "kind": "connector_instance",
            "entity_id": "connector_instance_ticketing",
            "code": "connector_config_revision_mismatch",
            "message": "Connector config rotated while stale local state remained.",
        },
    ],
    "status": "accepted",
    "received_at": now,
    "entities": {
        "assignments": assignments,
        "review_queue_items": review_queue_items,
        "correction_tasks": correction_tasks,
        "activity_events": activity_events,
        "alerts": alerts,
        "invoices": invoices,
        "payment_records": payment_records,
        "payment_allocations": payment_allocations,
        "export_jobs": export_jobs,
        "receivable_summaries": receivable_summaries,
        "estimates": estimates,
        "estimate_versions": estimate_versions,
        "estimate_approvals": estimate_approvals,
        "service_agreements": service_agreements,
        "recurring_plans": recurring_plans,
        "generated_schedule_items": generated_schedule_items,
        "renewal_records": renewal_records,
        "webhook_deliveries": webhook_deliveries,
        "api_key_records": api_key_records,
        "service_requests": service_requests,
        "customer_timeline_events": customer_timeline_events,
        "inventory_items": inventory_items,
        "stock_locations": stock_locations,
        "stock_movements": stock_movements,
        "purchase_orders": purchase_orders,
        "receiving_records": receiving_records,
        "connector_instances": connector_instances,
        "connector_sync_jobs": connector_sync_jobs,
    },
    "indexes": indexes,
    "summary": summary,
    "sync": sync_doc(
        "sync_cursor_2026_03_11_103",
        "accepted",
        conflict_status="stale",
        conflict_message="One estimate approval requires refresh before retry.",
        conflict_code="estimate_approval_revision_mismatch",
        conflict_entity_id="est_003",
        estimate_revision_status="mismatch",
        stale_estimate_id="est_003",
        delivery_retry_status="retry_required",
        stale_delivery_id="delivery_002",
        payment_revision_status="accepted",
        export_status="running",
        finance_revision="finance_rev_2026_03_11_002",
        portal_approval_status="approved",
        stale_portal_request_id="service_request_001",
        tenant_revision_status="accepted",
        stale_tenant_id="tenant_northline",
        inventory_movement_status="accepted",
        stale_stock_location_id="stock_location_van_gamma",
        receiving_status="partial",
        stale_purchase_order_id="purchase_order_002",
        connector_config_status="mismatch",
        stale_connector_instance_id="connector_instance_ticketing",
    ),
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
                "demo_seed.login_enterprise_admin_body_v1",
                "demo_seed.login_manager_body_v1",
                "demo_seed.login_portal_user_body_v1",
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
                "demo_seed.pricing_config_body_v1",
                "demo_seed.pricing_update_body_v1",
                "demo_seed.pricing_update_conflict_body_v1",
                "demo_seed.invoice_list_body_v1",
                "demo_seed.invoice_detail_map_body_v1",
                "demo_seed.invoice_generate_body_v1",
                "demo_seed.invoice_patch_body_v1",
                "demo_seed.invoice_issue_map_body_v1",
                "demo_seed.invoice_lock_conflict_body_v1",
                "demo_seed.invoice_void_map_body_v1",
                "demo_seed.invoice_payment_map_body_v1",
                "demo_seed.payment_revision_conflict_body_v1",
                "demo_seed.finance_summary_body_v1",
                "demo_seed.finance_receivables_body_v1",
                "demo_seed.customer_account_map_body_v1",
                "demo_seed.export_center_body_v1",
                "demo_seed.export_create_body_v1",
                "demo_seed.export_retry_map_body_v1",
                "demo_seed.invoice_artifact_map_body_v1",
                "demo_seed.service_summary_map_body_v1",
                "demo_seed.estimate_list_body_v1",
                "demo_seed.estimate_detail_map_body_v1",
                "demo_seed.estimate_create_body_v1",
                "demo_seed.estimate_patch_map_body_v1",
                "demo_seed.estimate_send_map_body_v1",
                "demo_seed.estimate_approve_map_body_v1",
                "demo_seed.estimate_reject_map_body_v1",
                "demo_seed.estimate_convert_map_body_v1",
                "demo_seed.estimate_approval_conflict_body_v1",
                "demo_seed.estimate_conversion_conflict_body_v1",
                "demo_seed.contract_list_body_v1",
                "demo_seed.contract_create_body_v1",
                "demo_seed.contract_patch_map_body_v1",
                "demo_seed.contract_pause_map_body_v1",
                "demo_seed.contract_resume_map_body_v1",
                "demo_seed.contract_renew_map_body_v1",
                "demo_seed.contract_renewal_conflict_body_v1",
                "demo_seed.recurring_board_body_v1",
                "demo_seed.recurring_generate_map_body_v1",
                "demo_seed.recurring_skip_map_body_v1",
                "demo_seed.recurring_generation_conflict_body_v1",
                "demo_seed.integrations_center_body_v1",
                "demo_seed.integrations_deliveries_body_v1",
                "demo_seed.integrations_api_key_create_body_v1",
                "demo_seed.integrations_webhook_create_body_v1",
                "demo_seed.integrations_delivery_retry_body_v1",
                "demo_seed.enterprise_admin_body_v1",
                "demo_seed.admin_roles_body_v1",
                "demo_seed.admin_tenant_create_body_v1",
                "demo_seed.admin_tenant_patch_map_body_v1",
                "demo_seed.admin_role_create_body_v1",
                "demo_seed.admin_branding_update_body_v1",
                "demo_seed.portal_session_body_v1",
                "demo_seed.portal_me_body_v1",
                "demo_seed.portal_invoices_body_v1",
                "demo_seed.portal_service_history_body_v1",
                "demo_seed.portal_request_create_body_v1",
                "demo_seed.portal_request_convert_map_body_v1",
                "demo_seed.portal_estimate_approve_body_v1",
                "demo_seed.portal_approval_conflict_body_v1",
                "demo_seed.inventory_items_body_v1",
                "demo_seed.inventory_movement_body_v1",
                "demo_seed.inventory_count_body_v1",
                "demo_seed.procurement_orders_body_v1",
                "demo_seed.procurement_po_create_body_v1",
                "demo_seed.procurement_receive_body_v1",
                "demo_seed.connectors_vendor_body_v1",
                "demo_seed.connectors_vendor_create_body_v1",
                "demo_seed.connectors_vendor_sync_map_body_v1",
                "demo_seed.connectors_vendor_deliveries_map_body_v1",
                "demo_seed.release_readiness_body_v1",
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
            "demo_seed.login_enterprise_admin_body_v1",
            login_doc(
                "enterprise_admin",
                "user_enterprise_iris",
                "branch_north",
                None,
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
        bytes_defn(
            "demo_seed.login_portal_user_body_v1",
            login_doc(
                "portal_user",
                "user_portal_morgan",
                "branch_north",
                None,
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
        bytes_defn("demo_seed.pricing_config_body_v1", pricing_config_doc),
        bytes_defn("demo_seed.pricing_update_body_v1", pricing_update_doc),
        bytes_defn(
            "demo_seed.pricing_update_conflict_body_v1",
            pricing_update_conflict_doc,
        ),
        bytes_defn("demo_seed.invoice_list_body_v1", invoice_list_doc),
        bytes_defn("demo_seed.invoice_detail_map_body_v1", invoice_detail_map),
        bytes_defn("demo_seed.invoice_generate_body_v1", invoice_generate_doc),
        bytes_defn("demo_seed.invoice_patch_body_v1", invoice_patch_doc),
        bytes_defn("demo_seed.invoice_issue_map_body_v1", invoice_issue_map),
        bytes_defn(
            "demo_seed.invoice_lock_conflict_body_v1",
            invoice_lock_conflict_doc,
        ),
        bytes_defn("demo_seed.invoice_void_map_body_v1", invoice_void_map),
        bytes_defn("demo_seed.invoice_payment_map_body_v1", invoice_payment_map),
        bytes_defn(
            "demo_seed.payment_revision_conflict_body_v1",
            payment_revision_conflict_doc,
        ),
        bytes_defn("demo_seed.finance_summary_body_v1", finance_summary_doc),
        bytes_defn(
            "demo_seed.finance_receivables_body_v1",
            finance_receivables_doc,
        ),
        bytes_defn(
            "demo_seed.customer_account_map_body_v1",
            customer_account_map,
        ),
        bytes_defn("demo_seed.export_center_body_v1", export_center_doc),
        bytes_defn("demo_seed.export_create_body_v1", export_create_doc),
        bytes_defn("demo_seed.export_retry_map_body_v1", export_retry_map),
        bytes_defn(
            "demo_seed.invoice_artifact_map_body_v1",
            invoice_artifact_map,
        ),
        bytes_defn(
            "demo_seed.service_summary_map_body_v1",
            service_summary_map,
        ),
        bytes_defn("demo_seed.estimate_list_body_v1", estimate_list_doc),
        bytes_defn("demo_seed.estimate_detail_map_body_v1", estimate_detail_map),
        bytes_defn("demo_seed.estimate_create_body_v1", estimate_create_doc),
        bytes_defn("demo_seed.estimate_patch_map_body_v1", estimate_patch_map),
        bytes_defn("demo_seed.estimate_send_map_body_v1", estimate_send_map),
        bytes_defn("demo_seed.estimate_approve_map_body_v1", estimate_approve_map),
        bytes_defn("demo_seed.estimate_reject_map_body_v1", estimate_reject_map),
        bytes_defn("demo_seed.estimate_convert_map_body_v1", estimate_convert_map),
        bytes_defn(
            "demo_seed.estimate_approval_conflict_body_v1",
            estimate_approval_conflict_doc,
        ),
        bytes_defn(
            "demo_seed.estimate_conversion_conflict_body_v1",
            estimate_conversion_conflict_doc,
        ),
        bytes_defn("demo_seed.contract_list_body_v1", contract_list_doc),
        bytes_defn("demo_seed.contract_create_body_v1", contract_create_doc),
        bytes_defn("demo_seed.contract_patch_map_body_v1", contract_patch_map),
        bytes_defn("demo_seed.contract_pause_map_body_v1", contract_pause_map),
        bytes_defn("demo_seed.contract_resume_map_body_v1", contract_resume_map),
        bytes_defn("demo_seed.contract_renew_map_body_v1", contract_renew_map),
        bytes_defn(
            "demo_seed.contract_renewal_conflict_body_v1",
            contract_renewal_conflict_doc,
        ),
        bytes_defn("demo_seed.recurring_board_body_v1", recurring_board_doc),
        bytes_defn("demo_seed.recurring_generate_map_body_v1", recurring_generate_map),
        bytes_defn("demo_seed.recurring_skip_map_body_v1", recurring_skip_map),
        bytes_defn(
            "demo_seed.recurring_generation_conflict_body_v1",
            recurring_generation_conflict_doc,
        ),
        bytes_defn("demo_seed.integrations_center_body_v1", integrations_center_doc),
        bytes_defn(
            "demo_seed.integrations_deliveries_body_v1",
            integrations_deliveries_doc,
        ),
        bytes_defn(
            "demo_seed.integrations_api_key_create_body_v1",
            integrations_api_key_create_doc,
        ),
        bytes_defn(
            "demo_seed.integrations_webhook_create_body_v1",
            integrations_webhook_create_doc,
        ),
        bytes_defn(
            "demo_seed.integrations_delivery_retry_body_v1",
            integrations_delivery_retry_doc,
        ),
        bytes_defn("demo_seed.enterprise_admin_body_v1", enterprise_admin_doc),
        bytes_defn("demo_seed.admin_roles_body_v1", admin_roles_doc),
        bytes_defn("demo_seed.admin_tenant_create_body_v1", admin_tenant_create_doc),
        bytes_defn("demo_seed.admin_tenant_patch_map_body_v1", admin_tenant_patch_map),
        bytes_defn("demo_seed.admin_role_create_body_v1", admin_role_create_doc),
        bytes_defn("demo_seed.admin_branding_update_body_v1", admin_branding_update_doc),
        bytes_defn("demo_seed.portal_session_body_v1", portal_session_doc),
        bytes_defn("demo_seed.portal_me_body_v1", portal_me_doc),
        bytes_defn("demo_seed.portal_invoices_body_v1", portal_invoices_doc),
        bytes_defn("demo_seed.portal_service_history_body_v1", portal_service_history_doc),
        bytes_defn("demo_seed.portal_request_create_body_v1", portal_request_create_doc),
        bytes_defn(
            "demo_seed.portal_request_convert_map_body_v1",
            portal_request_convert_map,
        ),
        bytes_defn("demo_seed.portal_estimate_approve_body_v1", portal_estimate_approve_doc),
        bytes_defn("demo_seed.portal_approval_conflict_body_v1", portal_approval_conflict_doc),
        bytes_defn("demo_seed.inventory_items_body_v1", inventory_items_doc),
        bytes_defn("demo_seed.inventory_movement_body_v1", inventory_movement_doc),
        bytes_defn("demo_seed.inventory_count_body_v1", inventory_count_doc),
        bytes_defn("demo_seed.procurement_orders_body_v1", procurement_orders_doc),
        bytes_defn("demo_seed.procurement_po_create_body_v1", procurement_po_create_doc),
        bytes_defn("demo_seed.procurement_receive_body_v1", procurement_receive_doc),
        bytes_defn("demo_seed.connectors_vendor_body_v1", connectors_vendor_doc),
        bytes_defn("demo_seed.connectors_vendor_create_body_v1", connectors_vendor_create_doc),
        bytes_defn(
            "demo_seed.connectors_vendor_sync_map_body_v1",
            connectors_vendor_sync_map,
        ),
        bytes_defn(
            "demo_seed.connectors_vendor_deliveries_map_body_v1",
            connectors_vendor_deliveries_map,
        ),
        bytes_defn("demo_seed.release_readiness_body_v1", release_readiness_doc),
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
