-- +goose Up
CREATE TABLE product_categories (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(60) NOT NULL UNIQUE
);

CREATE TABLE products (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id uuid NOT NULL REFERENCES branches (id),
    category_id uuid NOT NULL REFERENCES product_categories (id),
    name varchar(120) NOT NULL,
    price numeric(12, 2) NOT NULL,
    cost numeric(12, 2),
    stock integer NOT NULL DEFAULT 0,
    is_service boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE consumptions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id uuid NOT NULL REFERENCES sessions (id),
    product_id uuid NOT NULL REFERENCES products (id),
    quantity integer NOT NULL DEFAULT 1,
    unit_price numeric(12, 2) NOT NULL,
    created_by_user_id uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (quantity > 0)
);

CREATE TABLE suppliers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(120) NOT NULL,
    phone varchar(30),
    notes text
);

CREATE TABLE purchases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id uuid NOT NULL REFERENCES branches (id),
    supplier_id uuid REFERENCES suppliers (id),
    date date NOT NULL,
    total numeric(12, 2) NOT NULL,
    cash_movement_id uuid UNIQUE REFERENCES cash_movements (id),
    notes text,
    registered_by_user_id uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE purchase_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id uuid NOT NULL REFERENCES purchases (id),
    product_id uuid NOT NULL REFERENCES products (id),
    quantity integer NOT NULL,
    unit_cost numeric(12, 2) NOT NULL,
    CHECK (quantity > 0)
);

CREATE TABLE inventory_movements (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL REFERENCES products (id),
    type inventory_movement_type NOT NULL,
    quantity integer NOT NULL,
    purchase_item_id uuid REFERENCES purchase_items (id),
    consumption_id uuid REFERENCES consumptions (id),
    reason varchar(200),
    user_id uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now()
);

-- +goose Down
DROP TABLE IF EXISTS inventory_movements;
DROP TABLE IF EXISTS purchase_items;
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS consumptions;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS product_categories;
