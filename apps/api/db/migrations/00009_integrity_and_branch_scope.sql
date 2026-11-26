-- +goose Up
ALTER TABLE sessions ADD COLUMN branch_id uuid;
ALTER TABLE accounts ADD COLUMN branch_id uuid;
ALTER TABLE payments ADD COLUMN branch_id uuid;
ALTER TABLE payments ADD COLUMN cash_shift_id uuid;
ALTER TABLE consumptions ADD COLUMN branch_id uuid;
ALTER TABLE table_changes ADD COLUMN branch_id uuid;
ALTER TABLE discounts ADD COLUMN branch_id uuid;
ALTER TABLE reservations ADD COLUMN branch_id uuid;
ALTER TABLE promotions ADD COLUMN branch_id uuid;
ALTER TABLE cash_movements ADD COLUMN branch_id uuid;

UPDATE sessions s SET branch_id = t.branch_id FROM tables t WHERE t.id = s.table_id;
UPDATE accounts a SET branch_id = s.branch_id FROM sessions s WHERE s.id = a.session_id;
UPDATE payments p SET branch_id = a.branch_id, cash_shift_id = a.cash_shift_id FROM accounts a WHERE a.id = p.account_id;
UPDATE consumptions c SET branch_id = s.branch_id FROM sessions s WHERE s.id = c.session_id;
UPDATE table_changes tc SET branch_id = s.branch_id FROM sessions s WHERE s.id = tc.session_id;
UPDATE discounts d SET branch_id = s.branch_id FROM sessions s WHERE s.id = d.session_id;
UPDATE reservations r SET branch_id = t.branch_id FROM tables t WHERE t.id = r.table_id;
UPDATE promotions p SET branch_id = r.branch_id FROM rates r WHERE r.id = p.rate_id;
UPDATE cash_movements cm SET branch_id = cs.branch_id FROM cash_shifts cs WHERE cs.id = cm.cash_shift_id;

ALTER TABLE sessions ALTER COLUMN branch_id SET NOT NULL;
ALTER TABLE accounts ALTER COLUMN branch_id SET NOT NULL;
ALTER TABLE payments ALTER COLUMN branch_id SET NOT NULL;
ALTER TABLE payments ALTER COLUMN cash_shift_id SET NOT NULL;
ALTER TABLE consumptions ALTER COLUMN branch_id SET NOT NULL;
ALTER TABLE table_changes ALTER COLUMN branch_id SET NOT NULL;
ALTER TABLE discounts ALTER COLUMN branch_id SET NOT NULL;
ALTER TABLE reservations ALTER COLUMN branch_id SET NOT NULL;
ALTER TABLE promotions ALTER COLUMN branch_id SET NOT NULL;
ALTER TABLE cash_movements ALTER COLUMN branch_id SET NOT NULL;

ALTER TABLE sessions ADD CONSTRAINT sessions_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches (id);
ALTER TABLE accounts ADD CONSTRAINT accounts_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches (id);
ALTER TABLE payments ADD CONSTRAINT payments_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches (id);
ALTER TABLE payments ADD CONSTRAINT payments_cash_shift_id_fkey FOREIGN KEY (cash_shift_id) REFERENCES cash_shifts (id);
ALTER TABLE consumptions ADD CONSTRAINT consumptions_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches (id);
ALTER TABLE table_changes ADD CONSTRAINT table_changes_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches (id);
ALTER TABLE discounts ADD CONSTRAINT discounts_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches (id);
ALTER TABLE reservations ADD CONSTRAINT reservations_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches (id);
ALTER TABLE promotions ADD CONSTRAINT promotions_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches (id);
ALTER TABLE cash_movements ADD CONSTRAINT cash_movements_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches (id);

ALTER TABLE reservations ADD CONSTRAINT reservations_time_check CHECK (ends_at > starts_at);
ALTER TABLE promotions ADD CONSTRAINT promotions_hourly_discount_check CHECK (hourly_discount > 0);

-- +goose Down
ALTER TABLE promotions DROP CONSTRAINT IF EXISTS promotions_hourly_discount_check;
ALTER TABLE reservations DROP CONSTRAINT IF EXISTS reservations_time_check;

ALTER TABLE cash_movements DROP CONSTRAINT IF EXISTS cash_movements_branch_id_fkey;
ALTER TABLE promotions DROP CONSTRAINT IF EXISTS promotions_branch_id_fkey;
ALTER TABLE reservations DROP CONSTRAINT IF EXISTS reservations_branch_id_fkey;
ALTER TABLE discounts DROP CONSTRAINT IF EXISTS discounts_branch_id_fkey;
ALTER TABLE table_changes DROP CONSTRAINT IF EXISTS table_changes_branch_id_fkey;
ALTER TABLE consumptions DROP CONSTRAINT IF EXISTS consumptions_branch_id_fkey;
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_cash_shift_id_fkey;
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_branch_id_fkey;
ALTER TABLE accounts DROP CONSTRAINT IF EXISTS accounts_branch_id_fkey;
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_branch_id_fkey;

ALTER TABLE payments DROP COLUMN IF EXISTS cash_shift_id;
ALTER TABLE cash_movements DROP COLUMN IF EXISTS branch_id;
ALTER TABLE promotions DROP COLUMN IF EXISTS branch_id;
ALTER TABLE reservations DROP COLUMN IF EXISTS branch_id;
ALTER TABLE discounts DROP COLUMN IF EXISTS branch_id;
ALTER TABLE table_changes DROP COLUMN IF EXISTS branch_id;
ALTER TABLE consumptions DROP COLUMN IF EXISTS branch_id;
ALTER TABLE payments DROP COLUMN IF EXISTS branch_id;
ALTER TABLE accounts DROP COLUMN IF EXISTS branch_id;
ALTER TABLE sessions DROP COLUMN IF EXISTS branch_id;
