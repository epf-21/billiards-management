-- +goose Up
CREATE TABLE tournaments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id uuid NOT NULL REFERENCES branches (id),
    name varchar(120) NOT NULL,
    format tournament_format NOT NULL,
    starts_at timestamptz NOT NULL,
    entry_fee numeric(12, 2) NOT NULL DEFAULT 0,
    status tournament_status NOT NULL DEFAULT 'draft',
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tournament_registrations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid NOT NULL REFERENCES tournaments (id),
    customer_id uuid NOT NULL REFERENCES customers (id),
    amount_paid numeric(12, 2),
    method payment_method,
    cash_shift_id uuid REFERENCES cash_shifts (id),
    paid_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tournament_id, customer_id),
    CHECK (method IS NULL OR method IN ('cash', 'qr', 'transfer'))
);

CREATE TABLE tournament_matches (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid NOT NULL REFERENCES tournaments (id),
    round integer NOT NULL,
    number integer NOT NULL,
    player1_id uuid REFERENCES customers (id),
    player2_id uuid REFERENCES customers (id),
    winner_id uuid REFERENCES customers (id),
    table_id uuid REFERENCES tables (id),
    status match_status NOT NULL DEFAULT 'pending',
    played_at timestamptz,
    UNIQUE (tournament_id, round, number),
    CHECK (round > 0 AND number > 0)
);

-- +goose Down
DROP TABLE IF EXISTS tournament_matches;
DROP TABLE IF EXISTS tournament_registrations;
DROP TABLE IF EXISTS tournaments;
