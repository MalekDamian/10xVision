## 1. Tabele

**cameras**

* `id` UUID PRIMARY KEY
* `name` TEXT NOT NULL UNIQUE
* `location` TEXT
* `created_at` TIMESTAMPTZ NOT NULL DEFAULT now()

**alerts**  *(PARTITION BY RANGE (event\_time))*

* `id` UUID PRIMARY KEY
* `camera_id` UUID NOT NULL REFERENCES cameras(id) ON DELETE CASCADE
* `event_time` TIMESTAMPTZ NOT NULL
* `type` TEXT NOT NULL CHECK (type IN ('face','plate'))
* `label` TEXT NOT NULL DEFAULT 'unknown'
* `thumbnail_path` TEXT NOT NULL
* `created_at` TIMESTAMPTZ NOT NULL DEFAULT now()

**detections**  *(PARTITION BY RANGE (detected\_at))*

* `id` UUID PRIMARY KEY
* `alert_id` UUID NOT NULL REFERENCES alerts(id) ON DELETE CASCADE
* `object_type` TEXT NOT NULL CHECK (object\_type IN ('face','plate','person','vehicle'))
* `detected_at` TIMESTAMPTZ NOT NULL
* `confidence` DOUBLE PRECISION NOT NULL
* `created_at` TIMESTAMPTZ NOT NULL DEFAULT now()

**known\_faces**

* `id` UUID PRIMARY KEY
* `name` TEXT NOT NULL UNIQUE
* `embedding` VECTOR NOT NULL
* `added_at` TIMESTAMPTZ NOT NULL DEFAULT now()

**known\_plates**

* `id` UUID PRIMARY KEY
* `plate_number` TEXT NOT NULL UNIQUE
* `embedding` VECTOR NOT NULL
* `added_at` TIMESTAMPTZ NOT NULL DEFAULT now()

**users**

* `id` UUID PRIMARY KEY
* `username` TEXT NOT NULL UNIQUE
* `password_hash` TEXT NOT NULL
* `created_at` TIMESTAMPTZ NOT NULL DEFAULT now()

**login\_attempts**

* `id` UUID PRIMARY KEY
* `user_id` UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
* `attempt_time` TIMESTAMPTZ NOT NULL DEFAULT now()
* `success` BOOLEAN NOT NULL
* `ip_address` INET

## 2. Relacje

* **cameras (1) ⇨ alerts (N)**  via `alerts.camera_id` → `cameras.id`
* **alerts (1) ⇨ detections (N)**  via `detections.alert_id` → `alerts.id`
* **users (1) ⇨ login\_attempts (N)** via `login_attempts.user_id` → `users.id`

## 3. Indeksy

* `CREATE INDEX idx_alerts_event_time ON alerts(event_time);`
* `CREATE INDEX idx_alerts_label ON alerts(label);`
* `CREATE INDEX idx_detections_alert_id ON detections(alert_id);`
* `CREATE INDEX idx_detections_detected_at ON detections(detected_at);`
* `CREATE INDEX idx_login_attempts_user_time ON login_attempts(user_id, attempt_time);`
* `CREATE INDEX idx_known_faces_name ON known_faces(name);`
* \`CREATE INDEX idx\_known\_plates\_number ON known\_plates(plate\_number);

## 4. Zasady Partycjonowania i Retencji

* **alerts**: `PARTITION BY RANGE (event_time)` z codziennymi partycjami.
* **detections**: `PARTITION BY RANGE (detected_at)` z codziennymi partycjami.
* Proces serwisowy usuwa partycje starsze niż 10 dni.

## 5. Zasady Bezpieczeństwa i RLS

* Brak RLS w MVP; rola `admin` z pełnymi uprawnieniami.
* Poziom izolacji transakcji:

  * **Zapisy**: SERIALIZABLE
  * **Odczyty (panel historii)**: READ COMMITTED

## 6. Dodatkowe Uwagi

* UUID generowane po stronie aplikacji.
* Wszystkie znaczące znaczniki czasu w UTC (`TIMESTAMPTZ`).
* Użycie rozszerzenia `pgvector` dla kolumn `embedding`.
* Autovacuum dostrojone dla tabel partycjonowanych (skalowanie i próg próżniowania).
* WAL archiving skonfigurowane (`archive_mode=on`, `archive_command` w aplikacji).
* Monitorowanie limitu bazy 2 GB i blokada dodawania miniatur po przekroczeniu.
