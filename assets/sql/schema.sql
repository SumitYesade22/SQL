-- Practice schema for the SQL course (SQLite).
-- A small online electronics shop: customers place orders, orders contain
-- items, items point at products, products sit in categories, store orders are
-- handled by an employee, and most (not all) orders get a payment.

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS customers;

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    name        TEXT    NOT NULL UNIQUE
);

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name        TEXT    NOT NULL,
    email       TEXT,
    city        TEXT,              -- NULL for a few customers who never filled it in
    state       TEXT,
    signup_date TEXT    NOT NULL   -- 'YYYY-MM-DD'
);

CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    name        TEXT    NOT NULL,
    role        TEXT    NOT NULL,
    manager_id  INTEGER REFERENCES employees(employee_id),  -- NULL for the founder
    city        TEXT,
    hire_date   TEXT    NOT NULL,
    salary      INTEGER NOT NULL
);

CREATE TABLE products (
    product_id  INTEGER PRIMARY KEY,
    name        TEXT    NOT NULL,
    category_id INTEGER NOT NULL REFERENCES categories(category_id),
    price       REAL    NOT NULL CHECK (price > 0),   -- current list price, INR
    cost        REAL    NOT NULL,                     -- what we pay for it, INR
    stock       INTEGER NOT NULL
);

CREATE TABLE orders (
    order_id    INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date  TEXT    NOT NULL,
    status      TEXT    NOT NULL
                CHECK (status IN ('placed', 'shipped', 'delivered', 'cancelled', 'returned')),
    channel     TEXT    NOT NULL
                CHECK (channel IN ('web', 'app', 'store', 'phone')),
    employee_id INTEGER REFERENCES employees(employee_id)  -- NULL for web and app orders
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER NOT NULL REFERENCES orders(order_id),
    product_id    INTEGER NOT NULL REFERENCES products(product_id),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    unit_price    REAL    NOT NULL,   -- price on the day of the order, not today's price
    discount      REAL    NOT NULL DEFAULT 0
);

CREATE TABLE payments (
    payment_id INTEGER PRIMARY KEY,
    order_id   INTEGER NOT NULL REFERENCES orders(order_id),
    paid_on    TEXT    NOT NULL,
    amount     REAL    NOT NULL,
    method     TEXT    NOT NULL
);
