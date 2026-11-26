-- +goose Up
CREATE TABLE prepaid_packages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(80) NOT NULL UNIQUE,
    price numeric(12, 2) NOT NULL,
    granted_balance numeric(12, 2) NOT NULL,
    validity_days integer,
    active boolean NOT NULL DEFAULT true
);

CREATE TABLE balance_movements (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id uuid NOT NULL REFERENCES customers (id),
    type balance_movement_type NOT NULL,
    amount numeric(12, 2) NOT NULL,
    package_id uuid REFERENCES prepaid_packages (id),
    account_id uuid REFERENCES accounts (id),
    cash_shift_id uuid REFERENCES cash_shifts (id),
    method payment_method,
    expires_at timestamptz,
    created_by_user_id uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK ((type = 'top_up' AND method IN ('cash', 'qr', 'transfer')) OR (type <> 'top_up' AND method IS NULL))
);

CREATE TABLE credits (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id uuid NOT NULL REFERENCES customers (id),
    account_id uuid NOT NULL UNIQUE REFERENCES accounts (id),
    original_amount numeric(12, 2) NOT NULL,
    pending_amount numeric(12, 2) NOT NULL,
    status credit_status NOT NULL DEFAULT 'pending',
    due_at date,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE credit_payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    credit_id uuid NOT NULL REFERENCES credits (id),
    amount numeric(12, 2) NOT NULL,
    method payment_method NOT NULL,
    cash_shift_id uuid REFERENCES cash_shifts (id),
    created_by_user_id uuid NOT NULL REFERENCES users (id),
    paid_at timestamptz NOT NULL DEFAULT now(),
    CHECK (method IN ('cash', 'qr', 'transfer'))
);

-- +goose Down
DROP TABLE IF EXISTS credit_payments;
DROP TABLE IF EXISTS credits;
DROP TABLE IF EXISTS balance_movements;
DROP TABLE IF EXISTS prepaid_packages;
