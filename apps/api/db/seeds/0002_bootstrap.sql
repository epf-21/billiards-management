CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO branches (name, address)
VALUES ('Sucursal Principal', 'Direccion principal')
ON CONFLICT (name) DO NOTHING;

INSERT INTO business_settings (branch_id, trade_name, currency)
SELECT id, 'Billiards Management', 'BOB'
FROM branches
WHERE name = 'Sucursal Principal'
ON CONFLICT (branch_id) DO NOTHING;

INSERT INTO permissions (code, description)
VALUES
    ('tables.operate', 'Operar mesas y sesiones'),
    ('sessions.start', 'Iniciar sesiones'),
    ('sessions.finish', 'Finalizar sesiones'),
    ('sales.create', 'Registrar consumos y cobros'),
    ('sales.discount', 'Aplicar descuentos'),
    ('cash.manage', 'Abrir y operar caja'),
    ('cash.close', 'Cerrar caja'),
    ('products.manage', 'Administrar productos'),
    ('inventory.manage', 'Administrar inventario'),
    ('rates.manage', 'Administrar tarifas'),
    ('reports.financial.read', 'Ver reportes financieros'),
    ('users.manage', 'Administrar usuarios'),
    ('branches.manage', 'Administrar sucursales')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'admin'
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'tables.operate',
    'sessions.start',
    'sessions.finish',
    'sales.create',
    'sales.discount',
    'cash.manage',
    'cash.close',
    'products.manage',
    'inventory.manage',
    'rates.manage',
    'reports.financial.read'
)
WHERE r.name = 'manager'
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'tables.operate',
    'sessions.start',
    'sessions.finish',
    'sales.create',
    'cash.manage'
)
WHERE r.name = 'cashier'
ON CONFLICT DO NOTHING;

INSERT INTO users (role_id, username, password_hash, full_name, active, is_shared)
SELECT r.id, 'admin', crypt('admin123', gen_salt('bf')), 'Administrador', true, false
FROM roles r
WHERE r.name = 'admin'
ON CONFLICT (username) DO NOTHING;

INSERT INTO user_branches (user_id, branch_id)
SELECT u.id, b.id
FROM users u
CROSS JOIN branches b
WHERE u.username = 'admin'
  AND b.name = 'Sucursal Principal'
ON CONFLICT DO NOTHING;

INSERT INTO rates (branch_id, name, hourly_rate)
SELECT id, 'Mesa estandar', 15.00
FROM branches
WHERE name = 'Sucursal Principal'
ON CONFLICT (branch_id, name) DO NOTHING;

INSERT INTO tables (branch_id, rate_id, name, status)
SELECT b.id, r.id, 'Mesa 1', 'free'
FROM branches b
JOIN rates r ON r.branch_id = b.id AND r.name = 'Mesa estandar'
WHERE b.name = 'Sucursal Principal'
ON CONFLICT (branch_id, name) DO NOTHING;
