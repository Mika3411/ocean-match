BEGIN;

CREATE TABLE IF NOT EXISTS ports (
  id text PRIMARY KEY,
  name text NOT NULL CHECK (char_length(name) BETWEEN 2 AND 120),
  country text NOT NULL CHECK (char_length(country) BETWEEN 2 AND 80),
  region text NOT NULL CHECK (char_length(region) BETWEEN 2 AND 120),
  latitude numeric(9, 6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude numeric(9, 6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO ports (id, name, country, region, latitude, longitude)
VALUES
  ('marseille', 'Marseille', 'France', 'Mediterranee', 43.296500, 5.369800),
  ('palma', 'Palma de Majorque', 'Espagne', 'Mediterranee', 39.569600, 2.650200),
  ('athenes', 'Athenes - Piree', 'Grece', 'Mediterranee', 37.942900, 23.646900),
  ('la-rochelle', 'La Rochelle', 'France', 'Atlantique Europe', 46.160300, -1.151100),
  ('lisbonne', 'Lisbonne', 'Portugal', 'Atlantique Europe', 38.722300, -9.139300),
  ('cadix', 'Cadix', 'Espagne', 'Atlantique Europe', 36.527100, -6.288600),
  ('las-palmas', 'Las Palmas', 'Espagne', 'Canaries', 28.123500, -15.436300),
  ('santa-cruz-tenerife', 'Santa Cruz de Tenerife', 'Espagne', 'Canaries', 28.463600, -16.251800),
  ('mindelo', 'Mindelo', 'Cap-Vert', 'Cap-Vert', 16.887800, -24.995800),
  ('praia', 'Praia', 'Cap-Vert', 'Cap-Vert', 14.933000, -23.513300),
  ('le-marin', 'Le Marin', 'Martinique', 'Caraibes', 14.472700, -60.869400),
  ('pointe-a-pitre', 'Pointe-a-Pitre', 'Guadeloupe', 'Caraibes', 16.241100, -61.533100),
  ('cartagene', 'Cartagene', 'Colombie', 'Caraibes', 10.391000, -75.479400),
  ('portsmouth', 'Portsmouth', 'Royaume-Uni', 'Europe du Nord', 50.819800, -1.088000),
  ('bergen', 'Bergen', 'Norvege', 'Europe du Nord', 60.392900, 5.324200),
  ('port-louis', 'Port Louis', 'Maurice', 'Ocean Indien', -20.160900, 57.501200),
  ('victoria-seychelles', 'Victoria', 'Seychelles', 'Ocean Indien', -4.619100, 55.451300),
  ('papeete', 'Papeete', 'Polynesie francaise', 'Pacifique', -17.551600, -149.558500),
  ('noumea', 'Noumea', 'Nouvelle-Caledonie', 'Pacifique', -22.271100, 166.441600)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    country = EXCLUDED.country,
    region = EXCLUDED.region,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude;

ALTER TABLE current_zones
  ADD COLUMN IF NOT EXISTS port_id text REFERENCES ports(id) ON DELETE SET NULL;

ALTER TABLE future_routes
  ADD COLUMN IF NOT EXISTS destination_port_id text REFERENCES ports(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS current_zones_port_id_idx ON current_zones(port_id);
CREATE INDEX IF NOT EXISTS future_routes_destination_port_id_idx
  ON future_routes(destination_port_id)
  WHERE is_active;

COMMIT;
