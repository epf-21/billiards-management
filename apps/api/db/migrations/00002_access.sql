-- +goose Up
CREATE TABLE branches (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(80) NOT NULL UNIQUE,
    address varchar(200),
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE business_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id uuid NOT NULL UNIQUE REFERENCES branches (id),
    trade_name varchar(120) NOT NULL,
    currency char(3) NOT NULL DEFAULT 'BOB',
    opening_time time,
    closing_time time,
    ticket_message text,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(50) NOT NULL UNIQUE,
    description varchar(200)
);

CREATE TABLE permissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code varchar(80) NOT NULL UNIQUE,
    description varchar(200)
);

CREATE TABLE role_permissions (
    role_id uuid NOT NULL REFERENCES roles (id),
    permission_id uuid NOT NULL REFERENCES permissions (id),
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id uuid NOT NULL REFERENCES roles (id),
    username varchar(50) NOT NULL UNIQUE,
    password_hash varchar(255) NOT NULL,
    full_name varchar(120) NOT NULL,
    active boolean NOT NULL DEFAULT true,
    is_shared boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE user_branches (
    user_id uuid NOT NULL REFERENCES users (id),
    branch_id uuid NOT NULL REFERENCES branches (id),
    PRIMARY KEY (user_id, branch_id)
);

CREATE TABLE refresh_tokens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users (id),
    token_hash varchar(255) NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id uuid REFERENCES branches (id),
    user_id uuid REFERENCES users (id),
    action varchar(80) NOT NULL,
    entity varchar(60) NOT NULL,
    entity_id uuid,
    details jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- +goose Down
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS user_branches;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS role_permissions;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS business_settings;
DROP TABLE IF EXISTS branches;
