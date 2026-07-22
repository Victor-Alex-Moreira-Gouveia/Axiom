CREATE TABLE server_identity (
    id SERIAL PRIMARY KEY,
    server_name VARCHAR(100) NOT NULL,
    server_uuid UUID DEFAULT gen_random_uuid(),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO server_identity(server_name)
VALUES ('Raspberry Pi 4B - Tardis');