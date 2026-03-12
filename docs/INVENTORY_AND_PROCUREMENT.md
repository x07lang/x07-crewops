# CrewOps Inventory And Procurement

M7 adds inventory and procurement without introducing a second app or a database-backed warehouse service.

## Routes And Data

- routes: `inventory`, `procurement`
- backend calls: `GET /api/inventory/items`, `POST /api/inventory/movements`, `POST /api/inventory/counts`, `GET /api/procurement/purchase-orders`, `POST /api/procurement/purchase-orders`, `POST /api/procurement/receiving`

## Seeded Coverage

The seed includes:

- inventory items and stock locations
- vehicle stock and stock movements
- cycle counts
- vendors and vendor catalog items
- purchase orders, purchase order lines, receiving records, and reorder suggestions

The route summaries are exposed through `summary.inventory_summary` and `summary.procurement_summary`, so low-stock items, receiving mismatches, and reorder queues can be surfaced without route-local joins.

## Sync State

Inventory and purchasing replay state lives under `sync.enterprise_ops`:

- `inventory_movement_status`
- `stale_stock_location_id`
- `receiving_status`
- `stale_purchase_order_id`
