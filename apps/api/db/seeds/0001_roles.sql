INSERT INTO roles (name, description)
VALUES
    ('admin', 'Administrador'),
    ('manager', 'Encargado'),
    ('cashier', 'Cajero')
ON CONFLICT (name) DO NOTHING;
