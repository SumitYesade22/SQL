# Shop practice database

The database used by `sql-basics`, `sql-intermediate` and `sql-advanced`. It is a small
online electronics shop. Everything here is plain text: `schema.sql` creates the tables,
the seven CSV files fill them. The notebooks build `shop.db` from these files in their
setup cell, so nothing needs downloading and the same schema carries across all three levels.

## Tables

| Table | Rows | What it holds |
| --- | --- | --- |
| `categories` | 8 | Product categories — Laptops, Phones, Audio, Accessories, Monitors, Storage, Cameras, Wearables |
| `customers` | 60 | Who buys. `customer_id`, `name`, `email`, `city`, `state`, `signup_date` |
| `employees` | 15 | Staff. `manager_id` points back at `employees`, so the table is a hierarchy |
| `products` | 40 | `price` is today's list price in INR, `cost` is what the shop pays, plus `stock` |
| `orders` | 300 | One row per order: `customer_id`, `order_date`, `status`, `channel`, `employee_id` |
| `order_items` | 673 | The lines inside an order: `quantity`, `unit_price`, `discount` |
| `payments` | 248 | One row per paid order: `paid_on`, `amount`, `method` |

Orders run from January 2023 to December 2024 with a gentle growth trend, so
month-over-month and running-total queries have something to show.

## How the tables connect

```
categories ──< products ──< order_items >── orders >── customers
                                              │
                                              ├──< payments
                                              └── employees (manager_id ──> employees)
```

- `orders.customer_id` → `customers.customer_id`
- `orders.employee_id` → `employees.employee_id` — NULL for `web` and `app` orders, filled for `store` and `phone`
- `order_items.order_id` → `orders.order_id`
- `order_items.product_id` → `products.product_id`
- `payments.order_id` → `orders.order_id`
- `products.category_id` → `categories.category_id`
- `employees.manager_id` → `employees.employee_id` — NULL only for the founder

## Column notes

- `orders.status` is one of `placed`, `shipped`, `delivered`, `cancelled`, `returned`. Most
  revenue questions should exclude `cancelled`.
- `orders.channel` is one of `web`, `app`, `store`, `phone`.
- `order_items.unit_price` is the price **on the day of the order**, which is not always
  `products.price`. Revenue is `quantity * unit_price * (1 - discount)`.
- `order_items.discount` is a fraction: `0.10` means ten percent off.
- All dates are stored as `TEXT` in `YYYY-MM-DD` form, which is what SQLite's date functions expect.

## Deliberate imperfections

The data is messy on purpose. Each of these exists so an exercise has something real to bite on:

| What | Where | Practices |
| --- | --- | --- |
| 5 customers have no `city` | `customers` | `IS NULL`, `COALESCE`, why `city = NULL` never matches |
| 9 customers never ordered | `customers` vs `orders` | `LEFT JOIN … IS NULL`, `NOT EXISTS` |
| 52 orders have no payment | `orders` vs `payments` | `LEFT JOIN`, anti-joins, `SUM` over NULLs |
| 2 products were never ordered | `products` vs `order_items` | anti-joins, and why `INNER JOIN` hides rows |
| 2 people signed up twice with the same email | `customers` 12/59 and 28/60 | dedup with `ROW_NUMBER`, self-joins |
| 3 products sold at an older, higher price during 2023 | `order_items.unit_price` | why you store the price you charged, not today's price |
| `employee_id` is NULL on every web and app order | `orders` | `LEFT JOIN` to `employees`, `COUNT(col)` vs `COUNT(*)` |

## Rebuilding it yourself

```python
import sqlite3, pandas as pd
con = sqlite3.connect("shop.db")
con.executescript(open("schema.sql").read())
for t in ["categories", "customers", "employees", "products",
          "orders", "order_items", "payments"]:
    pd.read_csv(f"{t}.csv").to_sql(t, con, if_exists="append", index=False)
con.commit()
```

`schema.sql` starts with `DROP TABLE IF EXISTS`, so running this twice is safe.

The names, emails and figures are invented. Nothing here is real customer data.
