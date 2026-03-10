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
    }
    visits[f"visit_{i:03d}"] = {
        "id": f"visit_{i:03d}",
        "work_order_id": work_order_id,
        "user_id": technician_id,
        "state": "planned" if status in {"scheduled", "dispatched", "en_route"} else "logged",
    }

templates = {
    "tmpl_arrival": {
        "id": "tmpl_arrival",
        "name": "Arrival Walkthrough",
        "version": 1,
    },
    "tmpl_pm": {
        "id": "tmpl_pm",
        "name": "Preventive Maintenance",
        "version": 2,
    },
    "tmpl_closeout": {
        "id": "tmpl_closeout",
        "name": "Closeout Review",
        "version": 1,
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
    "indexes": indexes,
    "summary": summary,
}

fixture_compact = json.dumps(fixture, separators=(",", ":"))
meta_doc = {
    "app_name": "CrewOps",
    "app_version": "0.1.0",
    "build_profile": "dev",
    "environment": "local",
    "generated_at": "2026-03-10T00:00:00Z",
}
sync_pull_doc = {
    "cursor": "sync_cursor_2026_03_10_002",
    "changes": [],
    "status": "idle",
    "received_at": "2026-03-10T00:00:00Z",
}
sync_push_doc = {
    "cursor": "sync_cursor_2026_03_10_003",
    "applied": [
        "settings.theme",
        "settings.pinned_views",
        "ui.filters.status",
    ],
    "status": "accepted",
    "received_at": "2026-03-10T00:00:00Z",
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
        "sync_cursor": "sync_cursor_2026_03_10_001",
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
    },
    "indexes": indexes,
    "summary": summary,
    "sync": {
        "cursor": "sync_cursor_2026_03_10_001",
        "pending_ops": [],
        "last_pull_at": "2026-03-10T00:00:00Z",
        "last_push_at": None,
        "status": "idle",
        "last_error": None,
    },
    "diagnostics": {
        "app_version": "0.1.0",
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
