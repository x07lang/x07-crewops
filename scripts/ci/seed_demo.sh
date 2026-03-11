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
APP_VERSION = "0.4.0"


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
        "customers": len(customers),
        "sites": len(sites),
        "assets": len(assets),
        "work_orders": len(work_orders),
        "visits": len(visits),
        "assignments": len(assignments),
        "invoices": len(invoices),
        "payments": len(payment_records),
        "export_jobs": len(export_jobs),
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


bootstrap_entities = clone_doc(base_entities)
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
    payment_revision_status="idle",
    pricing_revision_status="idle",
    stale_price_book_id=None,
    export_status="idle",
    finance_revision="finance_rev_2026_03_11_001",
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
        "payment_revision_status": payment_revision_status,
        "pricing_revision_status": pricing_revision_status,
        "stale_price_book_id": stale_price_book_id,
        "export_status": export_status,
        "finance_revision": finance_revision,
        "unread_alerts": 4,
        "unread_activity": 6,
    }


def compact_entity_snapshot(source_entities, extra_work_order_ids=None):
    return clone_doc(source_entities)


def payload_with_snapshot(extra, extra_work_order_ids=None):
    out = dict(extra)
    out["entities"] = compact_entity_snapshot(base_entities, extra_work_order_ids)
    out["indexes"] = clone_doc(indexes)
    out["summary"] = clone_doc(summary)
    return out


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
    ],
    "status": "idle",
    "received_at": now,
    "server_policies": {
        "signature_required_on_complete": True,
        "location_capture_optional": True,
        "offline_queue_mode": "client_ops_v1",
        "invoice_lock_mode": "revision_sensitive",
        "payment_record_mode": "append_only",
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
        "invoices": invoices,
        "payment_records": payment_records,
        "payment_allocations": payment_allocations,
        "export_jobs": export_jobs,
        "receivable_summaries": receivable_summaries,
    },
    "indexes": indexes,
    "summary": summary,
    "sync": sync_doc(
        "sync_cursor_2026_03_11_103",
        "accepted",
        payment_revision_status="accepted",
        export_status="running",
        finance_revision="finance_rev_2026_03_11_002",
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
