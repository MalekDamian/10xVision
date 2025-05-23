\<conversation\_summary> <decisions>

1. UUIDy mają być generowane po stronie aplikacji.
2. Każda detekcja zapisywana jako oddzielny wpis z atrybutami: object\_type, detected\_at (TIMESTAMPTZ) i confidence.
3. Wszystkie znaczące znaczniki czasu w bazie przechowywane jako TIMESTAMPTZ (UTC).
4. Automatyczne partycjonowanie RANGE po kolumnie event\_time w tabelach alerts i detections – codzienne partycje, usuwane po 10 dniach.
5. Indeksy B-tree na alerts(event\_time), alerts(label), detections(alert\_id).
6. Autovacuum dla dużych tabel historycznych z wyregulowanymi parametrami vacuum\_scale\_factor i autovacuum\_vacuum\_threshold.
7. Włączenie archive\_mode i implementacja archive\_command po stronie aplikacji do archiwizacji WAL.
8. Tabela alerts zawiera kolumnę camera\_id UUID (FK do cameras) przygotowującą system na wiele kamer.
9. Poziom izolacji transakcji WRITE: SERIALIZABLE; READ (panel historii): READ COMMITTED.

   </decisions>

\<matched\_recommendations>

1. Usunięcie domyślnej gen\_random\_uuid() i przyjęcie, że aplikacja dostarcza UUID.
2. Definicja kolumn detections(object\_type TEXT, detected\_at TIMESTAMPTZ, confidence DOUBLE PRECISION).
3. Użycie TIMESTAMPTZ dla wszystkich timestampów.
4. Automatyzacja tworzenia i usuwania partycji RANGE na event\_time w alerts i detections.
5. Utrzymanie indeksów B-tree na najczęściej filtrowanych kolumnach.
6. Dostosowanie autovacuum dla tabel historycznych.
7. Konfiguracja archive\_mode i archive\_command w celu zarządzania WAL archiving.
8. Dodanie kolumny camera\_id UUID REFERENCES cameras(id) w tabeli alerts.
9. Zastosowanie poziomu izolacji REPEATABLE READ lub SERIALIZABLE dla zapisów i READ COMMITTED dla odczytów (wymagane: SERIALIZABLE dla zapisów).
   \</matched\_recommendations>

\<database\_planning\_summary>
**Główne wymagania**:

* Przechowywanie alertów (pojedynczy alert może zawierać wiele detekcji) i pojedynczych wpisów detekcji z metadanymi (\<object\_type>, \<detected\_at>, <confidence>).
* Retencja danych: automatyczne usuwanie starszych niż 10 dni, limit rozmiaru bazy 2 GB zarządzany przez archiwizację WAL i monitorowanie.
* Wsparcie dla pojedynczej kamery z przygotowaniem na wiele kamer (camera\_id).
* Prosty model admina bez RLS, bez dodatkowych ograniczeń.
* Wysoka integralność: transakcje WRITE na poziomie SERIALIZABLE, odczyty w panelu historii na poziomie READ COMMITTED.

**Kluczowe encje i relacje**:

* `cameras(id UUID PK) 1–N alerts`
* `alerts(id UUID PK, camera_id UUID FK, event_time TIMESTAMPTZ, type TEXT, label TEXT, thumbnail_path TEXT)`
* `detections(id UUID PK, alert_id UUID FK, object_type TEXT, detected_at TIMESTAMPTZ, confidence DOUBLE PRECISION)`
* `known_faces`, `known_plates` (UUID, unikalna nazwa lub tablica, embedding VECTOR)
* `users(id UUID PK)`, `login_attempts(id UUID PK, user_id UUID FK, attempt_time TIMESTAMPTZ, success BOOLEAN, ip_address TEXT)`
* Metryki Prometheus eksponowane przez endpoint, nie przechowywane w DB.

**Bezpieczeństwo i skalowalność**:

* Brak RLS na MVP; rola `admin` z pełnymi uprawnieniami.
* Izolacja SERIALIZABLE dla zapisów zapobiega konfliktom, READ COMMITTED dla odczytów minimalizuje blokady.
* Partycjonowanie i autovacuum zapewniają skalowalność historycznych danych.
* WAL archiving i CI testy backup/restore gwarantują odporność na awarie.

\</database\_planning\_summary>

\<unresolved\_issues>
Brak – wszystkie wcześniejsze wątpliwości dotyczące izolacji transakcji i struktury schematu zostały rozstrzygnięte.
\</unresolved\_issues>
\</conversation\_summary>
