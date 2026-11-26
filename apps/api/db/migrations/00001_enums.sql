-- +goose Up
CREATE TYPE session_mode AS ENUM ('free', 'fixed_time');
CREATE TYPE table_status AS ENUM ('free', 'busy', 'reserved', 'maintenance');
CREATE TYPE session_status AS ENUM ('active', 'paused', 'finished');
CREATE TYPE cash_shift_status AS ENUM ('open', 'closed');
CREATE TYPE account_status AS ENUM ('pending', 'paid', 'voided');
CREATE TYPE payment_method AS ENUM ('cash', 'qr', 'transfer', 'prepaid_balance', 'credit');
CREATE TYPE cash_movement_type AS ENUM ('income', 'withdrawal', 'expense', 'refund');
CREATE TYPE discount_type AS ENUM ('percentage', 'fixed_amount');
CREATE TYPE discount_target AS ENUM ('time', 'consumptions', 'total');
CREATE TYPE discount_origin AS ENUM ('manual', 'daily_promotion');
CREATE TYPE balance_movement_type AS ENUM ('top_up', 'consumption', 'adjustment', 'refund');
CREATE TYPE credit_status AS ENUM ('pending', 'paid', 'voided');
CREATE TYPE reservation_status AS ENUM ('pending', 'confirmed', 'fulfilled', 'cancelled', 'no_show');
CREATE TYPE inventory_movement_type AS ENUM ('purchase', 'sale', 'adjustment', 'shrinkage', 'return');
CREATE TYPE tournament_format AS ENUM ('single_elimination', 'double_elimination', 'round_robin');
CREATE TYPE tournament_status AS ENUM ('draft', 'registration_open', 'in_progress', 'finished', 'cancelled');
CREATE TYPE match_status AS ENUM ('pending', 'in_progress', 'finished');

-- +goose Down
DROP TYPE IF EXISTS match_status;
DROP TYPE IF EXISTS tournament_status;
DROP TYPE IF EXISTS tournament_format;
DROP TYPE IF EXISTS inventory_movement_type;
DROP TYPE IF EXISTS reservation_status;
DROP TYPE IF EXISTS credit_status;
DROP TYPE IF EXISTS balance_movement_type;
DROP TYPE IF EXISTS discount_origin;
DROP TYPE IF EXISTS discount_target;
DROP TYPE IF EXISTS discount_type;
DROP TYPE IF EXISTS cash_movement_type;
DROP TYPE IF EXISTS payment_method;
DROP TYPE IF EXISTS account_status;
DROP TYPE IF EXISTS cash_shift_status;
DROP TYPE IF EXISTS session_status;
DROP TYPE IF EXISTS table_status;
DROP TYPE IF EXISTS session_mode;
