-- +goose Up
CREATE TABLE rates (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id uuid NOT NULL REFERENCES branches (id),
    name varchar(60) NOT NULL,
    hourly_rate numeric(12, 2) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (branch_id, name)
);

CREATE TABLE tables (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id uuid NOT NULL REFERENCES branches (id),
    rate_id uuid NOT NULL REFERENCES rates (id),
    name varchar(60) NOT NULL,
    status table_status NOT NULL DEFAULT 'free',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (branch_id, name)
);

CREATE TABLE promotions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    rate_id uuid NOT NULL REFERENCES rates (id),
    name varchar(80) NOT NULL,
    hourly_discount numeric(12, 2) NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    weekday smallint,
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (ends_on >= starts_on),
    CHECK (weekday IS NULL OR weekday BETWEEN 1 AND 7)
);

CREATE TABLE reservations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    table_id uuid NOT NULL REFERENCES tables (id),
    customer_id uuid REFERENCES customers (id),
    starts_at timestamptz NOT NULL,
    ends_at timestamptz NOT NULL,
    status reservation_status NOT NULL DEFAULT 'pending',
    notes text,
    created_by_user_id uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    table_id uuid NOT NULL REFERENCES tables (id),
    opened_by_user_id uuid NOT NULL REFERENCES users (id),
    customer_id uuid REFERENCES customers (id),
    reservation_id uuid UNIQUE REFERENCES reservations (id),
    promotion_id uuid REFERENCES promotions (id),
    mode session_mode NOT NULL DEFAULT 'free',
    contracted_minutes integer,
    status session_status NOT NULL DEFAULT 'active',
    started_at timestamptz NOT NULL,
    finished_at timestamptz,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (mode <> 'fixed_time' OR (contracted_minutes IS NOT NULL AND contracted_minutes > 0))
);

CREATE TABLE session_pauses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id uuid NOT NULL REFERENCES sessions (id),
    paused_at timestamptz NOT NULL,
    resumed_at timestamptz
);

CREATE TABLE table_changes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id uuid NOT NULL REFERENCES sessions (id),
    source_table_id uuid NOT NULL REFERENCES tables (id),
    target_table_id uuid NOT NULL REFERENCES tables (id),
    changed_at timestamptz NOT NULL,
    played_minutes integer NOT NULL,
    accumulated_amount numeric(12, 2) NOT NULL
);

CREATE TABLE discounts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id uuid NOT NULL REFERENCES sessions (id),
    origin discount_origin NOT NULL DEFAULT 'manual',
    promotion_id uuid REFERENCES promotions (id),
    type discount_type NOT NULL,
    value numeric(12, 2) NOT NULL,
    applies_to discount_target NOT NULL DEFAULT 'total',
    applied_amount numeric(12, 2),
    reason varchar(200) NOT NULL,
    authorized_by_user_id uuid REFERENCES users (id),
    created_by_user_id uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK ((type = 'percentage' AND value BETWEEN 1 AND 100) OR (type = 'fixed_amount' AND value > 0))
);

-- +goose Down
DROP TABLE IF EXISTS discounts;
DROP TABLE IF EXISTS table_changes;
DROP TABLE IF EXISTS session_pauses;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS promotions;
DROP TABLE IF EXISTS tables;
DROP TABLE IF EXISTS rates;
