#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys
from collections import defaultdict

root = pathlib.Path(sys.argv[1])

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
        "sla_tier": ["silver", "gold", "platinum"][i % 3],
    }

assets = {}
for i in range(1, 61):
    asset_id = f"asset_{i:03d}"
    site_id = f"site_{((i - 1) % 30) + 1:03d}"
    assets[asset_id] = {
        "id": asset_id,
        "site_id": site_id,
        "customer_id": sites[site_id]["customer_id"],
        "kind": ["hvac", "pump", "panel", "door"][i % 4],
        "name": f"Asset {i:03d}",
        "service_level": ["critical", "standard", "routine"][i % 3],
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
priorities = ["low", "medium", "high", "urgent"]

work_orders = {}
visits = {}
for i in range(1, 26):
    work_order_id = f"wo_{i:03d}"
    site_id = f"site_{((i - 1) % 30) + 1:03d}"
    asset_id = f"asset_{((i - 1) % 60) + 1:03d}"
    team = teams[(i - 1) % len(teams)]
    technician_id = technicians[(i - 1) % len(technicians)][0]
    status = statuses[i - 1]
    work_orders[work_order_id] = {
        "id": work_order_id,
        "number": f"WO-{1200 + i}",
        "title": [
            "Quarterly PM",
            "Leak follow-up",
            "Sensor drift",
            "Roof drain check",
            "Panel reset",
        ][i % 5],
        "status": status,
        "priority": priorities[i % 4],
        "branch_id": team["branch_id"],
        "team_id": team["id"],
        "assignee_user_id": technician_id,
        "customer_id": sites[site_id]["customer_id"],
        "site_id": site_id,
        "asset_id": asset_id,
        "scheduled_day": f"2026-03-{((i - 1) % 7) + 10:02d}",
        "window": ["08:00-10:00", "10:00-12:00", "13:00-15:00", "15:00-17:00"][
            i % 4
        ],
        "sla_bucket": ["on_track", "attention", "attention", "stable"][i % 4],
        "template_id": "tmpl_pm" if i % 3 else "tmpl_closeout",
        "completion_policy": {
            "signature_required_on_complete": True,
            "block_reason_required": True,
            "location_capture_optional": True,
        },
        "allowed_part_ids": list(parts_catalog)[: 1 + (i % 3)],
    }
    visits[f"visit_{i:03d}"] = {
        "id": f"visit_{i:03d}",
        "work_order_id": work_order_id,
        "user_id": technician_id,
        "state": "planned" if status in {"scheduled", "dispatched", "en_route"} else "logged",
        "team_id": team["id"],
        "branch_id": team["branch_id"],
        "site_id": site_id,
        "asset_id": asset_id,
        "template_id": work_orders[work_order_id]["template_id"],
        "planned_start": f"2026-03-{((i - 1) % 7) + 10:02d}T{8 + (i % 4) * 2:02d}:00:00Z",
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
    "assets_by_site": defaultdict(list),
    "sites_by_customer": defaultdict(list),
}
for work_order_id, work_order in work_orders.items():
    indexes["work_orders_by_status"][work_order["status"]].append(work_order_id)
    indexes["work_orders_by_assignee"][work_order["assignee_user_id"]].append(work_order_id)
for asset_id, asset in assets.items():
    indexes["assets_by_site"][asset["site_id"]].append(asset_id)
for site_id, site in sites.items():
    indexes["sites_by_customer"][site["customer_id"]].append(site_id)
indexes["work_orders_by_assignee"] = dict(indexes["work_orders_by_assignee"])
indexes["assets_by_site"] = dict(indexes["assets_by_site"])
indexes["sites_by_customer"] = dict(indexes["sites_by_customer"])

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
        "review": len(indexes["work_orders_by_status"]["needs_review"]),
        "completion_rate": "76%",
    },
    "technician_today": {
        user_id: indexes["work_orders_by_assignee"].get(user_id, [])[:3]
        for user_id, *_ in technicians
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
    "indexes": indexes,
    "summary": summary,
}

fixture_compact = json.dumps(fixture, separators=(",", ":"))
meta_doc = {
    "app_name": "CrewOps",
    "app_version": "0.2.0",
    "build_profile": "dev",
    "environment": "local",
    "generated_at": "2026-03-10T00:00:00Z",
}
sync_pull_doc = {
    "cursor": "sync_cursor_2026_03_10_102",
    "changes": [],
    "status": "idle",
    "received_at": "2026-03-10T00:00:00Z",
    "server_policies": {
        "signature_required_on_complete": True,
        "location_capture_optional": True,
        "offline_queue_mode": "client_ops_v1",
    },
}
sync_push_doc = {
    "cursor": "sync_cursor_2026_03_10_103",
    "accepted_ops": [
        "op_check_in_visit_001",
        "op_save_draft_visit_001",
        "op_submit_visit_001",
    ],
    "conflicts": [],
    "status": "accepted",
    "received_at": "2026-03-10T00:00:00Z",
}

template_arrival_doc = templates["tmpl_arrival"]
template_pm_doc = templates["tmpl_pm"]
template_closeout_doc = templates["tmpl_closeout"]
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
        "manager": {
            "user_id": "user_manager_jonas",
            "branch_id": "branch_north",
            "team_id": "team_north_alpha",
        },
    },
    "bootstrap": {
        "status": "ready",
        "source": "http",
        "last_loaded_at": "2026-03-10T00:00:00Z",
        "sync_cursor": "sync_cursor_2026_03_10_101",
    },
    "entities": {
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
    },
    "indexes": indexes,
    "summary": summary,
    "sync": {
        "cursor": "sync_cursor_2026_03_10_101",
        "pending_ops": [],
        "last_pull_at": "2026-03-10T00:00:00Z",
        "last_push_at": None,
        "status": "idle",
        "last_error": None,
        "conflict_status": "idle",
        "conflict_message": "",
    },
    "diagnostics": {
        "app_version": "0.2.0",
        "target_kind": "web",
        "build_profile": "dev",
    },
}


def bytes_defn(name, payload):
    return {
        "kind": "defn",
        "name": name,
        "params": [],
        "result": "bytes",
        "body": ["bytes.lit", json.dumps(payload, separators=(",", ":"))],
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
                "demo_seed.login_dispatcher_body_v1",
                "demo_seed.login_manager_body_v1",
                "demo_seed.login_technician_body_v1",
                "demo_seed.meta_body_v1",
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
            "demo_seed.login_manager_body_v1",
            login_doc(
                "manager",
                "user_manager_jonas",
                "branch_north",
                "team_north_alpha",
            ),
        ),
        bytes_defn("demo_seed.meta_body_v1", meta_doc),
        bytes_defn("demo_seed.sync_pull_body_v1", sync_pull_doc),
        bytes_defn("demo_seed.sync_push_body_v1", sync_push_doc),
        bytes_defn("demo_seed.template_arrival_body_v1", template_arrival_doc),
        bytes_defn("demo_seed.template_pm_body_v1", template_pm_doc),
        bytes_defn("demo_seed.template_closeout_body_v1", template_closeout_doc),
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
