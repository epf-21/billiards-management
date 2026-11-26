-- +goose Up
CREATE TABLE cash_shifts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id uuid NOT NULL REFERENCES branches (id),
    opened_by_user_id uuid NOT NULL REFERENCES users (id),
    responsible_name varchar(120),
    status cash_shift_status NOT NULL DEFAULT 'open',
    opening_amount numeric(12, 2) NOT NULL DEFAULT 0,
    closing_amount numeric(12, 2),
    opened_at timestamptz NOT NULL DEFAULT now(),
    closed_at timestamptz
);

CREATE TABLE accounts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id uuid NOT NULL UNIQUE REFERENCES sessions (id),
    cash_shift_id uuid REFERENCES cash_shifts (id),
    customer_id uuid REFERENCES customers (id),
    time_amount numeric(12, 2) NOT NULL,
    consumptions_amount numeric(12, 2) NOT NULL DEFAULT 0,
    discount_amount numeric(12, 2) NOT NULL DEFAULT 0,
    total_amount numeric(12, 2) NOT NULL,
    status account_status NOT NULL DEFAULT 'pending',
    voided_by_user_id uuid REFERENCES users (id),
    void_reason varchar(200),
    voided_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (discount_amount >= 0 AND discount_amount <= time_amount + consumptions_amount),
    CHECK (total_amount = time_amount + consumptions_amount - discount_amount)
);

CREATE TABLE cash_movements (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    cash_shift_id uuid NOT NULL REFERENCES cash_shifts (id),
    type cash_movement_type NOT NULL,
    amount numeric(12, 2) NOT NULL,
    reason varchar(200) NOT NULL,
    account_id uuid REFERENCES accounts (id),
    user_id uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (amount > 0)
);

CREATE TABLE payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id uuid NOT NULL REFERENCES accounts (id),
    method payment_method NOT NULL,
    amount numeric(12, 2) NOT NULL,
    reference varchar(80),
    paid_at timestamptz NOT NULL DEFAULT now(),
    created_by_user_id uuid NOT NULL REFERENCES users (id),
    CHECK (amount > 0)
);

CREATE TABLE expense_categories (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(60) NOT NULL UNIQUE
);

CREATE TABLE expenses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id uuid NOT NULL REFERENCES branches (id),
    category_id uuid NOT NULL REFERENCES expense_categories (id),
    amount numeric(12, 2) NOT NULL,
    description varchar(200) NOT NULL,
    date date NOT NULL,
    cash_movement_id uuid UNIQUE REFERENCES cash_movements (id),
    user_id uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (amount > 0)
);

-- +goose Down
DROP TABLE IF EXISTS expenses;
DROP TABLE IF EXISTS expense_categories;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS cash_movements;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS cash_shifts;
