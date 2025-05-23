# Dokument wymagań produktu (PRD) – id-service

## 1. Przegląd produktu
id-service to samodzielna aplikacja działająca na Linuksie w kontenerze Docker, której celem jest wykrywanie oraz rozpoznawanie osób i polskich tablic rejestracyjnych na krótkich (≤ 60 s) plikach MP4 generowanych przez kamerę Hikvision. System porównuje wykryte obiekty z lokalną bazą „znanych” i wysyła pojedynczy alert web/desktop z miniaturą zdarzenia w czasie nieprzekraczającym 30 s od zapisu pliku. Aplikacja przechowuje metadane w PostgreSQL, pliki pomocnicze w systemie plików i udostępnia prosty interfejs web działający wyłącznie lokalnie.

## 2. Problem użytkownika
Właściciel działki, aby sprawdzić kto stoi przy bramie, musi podejść do okna; zajmuje to czas i uniemożliwia przygotowanie się na wizytę. Potrzebuje rozwiązania, które automatycznie poinformuje go o obecności gościa oraz powie, czy osoba lub pojazd jest mu znany.

## 3. Wymagania funkcjonalne
| ID | Wymaganie |
|----|-----------|
| FR-001 | Obsługa pojedynczej kamery zapisującej pliki MP4 o długości do 60 s; architektura przewiduje rozszerzenie o kolejne źródła. |
| FR-002 | Detekcja osoby i polskiej tablicy rejestracyjnej w min. 80 % klatek każdego nagrania testowego. |
| FR-003 | Rozpoznawanie znanych twarzy i tablic z dokładnością min. 80 %. |
| FR-004 | Wysłanie jednego zbiorczego alertu web/desktop z miniaturą, etykietą i czasem zdarzenia w ≤ 30 s od modyfikacji pliku. |
| FR-005 | Możliwość dodania nieznanego obiektu do bazy „znanych” poprzez UI (nadanie nazwy). |
| FR-006 | Panel historii prezentujący listę ostatnich zdarzeń z możliwością filtrowania i ponownego oznaczania. |
| FR-007 | Globalna konfiguracja progów ufności (face, plate) w pliku config.yaml ładowana bez restartu kontenera. |
| FR-008 | Uwierzytelnianie pojedynczym kontem admin (login + stałe hasło, bcrypt, rate-limit 5 prób / 10 min). |
| FR-009 | Retencja miniatur i logów: automatyczne usuwanie danych starszych niż 10 dni; embeddingi i znane tablice trwałe. |
| FR-010 | Zapewnienie metryk Prometheus (czas analizy, liczba detekcji, błędy I/O) dla monitoringu SLA. |
| FR-011 | Ograniczenie rozmiaru bazy metadanych do 2 GB; powyżej limitu system blokuje dodawanie nowych miniatur. |
| FR-012 | Przy uzyciu LLM via OpenRouter wykonanie agenta 'policy-agent', ktory zwroci liste zdarzen |
| FR-013 | Przy uzyciu LLM via OpenRouter wykonanie agenta 'policy-agent', ktory edytuje config na podstawie komend inline |

## 4. Granice produktu
* Obsługiwany format wejściowy: wyłącznie MP4 (brak strumieni RTSP/RTMP w MVP).
* Liczba kamer: jedna (rozszerzalność przewidziana, implementacja później).
* Dostęp do UI wyłącznie z localhost / LAN; brak wersji mobilnej ani publicznego dostępu.
* Brak integracji z Home Assistant w MVP (pozostawiona furtka w architekturze).
* Brak wersjonowania modeli ML w MVP; stosowane będą gotowe modele open-source (YOLOv8-face, EasyOCR-ANPR).
* Brak polityki RODO (wg wymagań użytkownika).

## 5. Historyjki użytkowników

| ID | Tytuł | Opis | Kryteria akceptacji |
|----|-------|------|---------------------|
| US-001 | Alert o osobie | Jako właściciel chcę otrzymać powiadomienie, gdy kamera wykryje osobę, abym mógł szybko zareagować. | • Po zapisaniu pliku MP4 z osobą system wysyła alert w ≤ 30 s.<br>• Alert zawiera miniaturę twarzy oraz etykietę „znany/nieznany”. |
| US-002 | Alert o pojeździe | Jako właściciel chcę otrzymać powiadomienie, gdy kamera wykryje pojazd, aby wiedzieć, kto przyjechał. | • Po zapisaniu pliku z tablicą system wysyła alert w ≤ 30 s.<br>• Alert zawiera miniaturę tablicy i etykietę „znany/nieznany”. |
| US-003 | Dodanie do znanych | Jako właściciel chcę dodać nieznany obiekt do bazy, by kolejne wizyty były oznaczone imieniem/etykietą. | • W alercie widoczny przycisk „Dodaj do znanych”.<br>• Po zapisaniu etykiety przyszłe alerty zawierają nową nazwę. |
| US-004 | Historia zdarzeń | Jako właściciel chcę przeglądać listę ostatnich zdarzeń, aby potwierdzić działanie systemu. | • UI pokazuje tabelę zdarzeń (czas, typ, miniatura, etykieta).<br>• Tabela przechowuje co najmniej 10 dni historii. |
| US-005 | Uwierzytelnianie | Jako właściciel chcę logować się do aplikacji, aby nikt inny nie miał dostępu do nagrań i bazy. | • Logowanie wymaga poprawnego loginu i hasła zahashowanego bcryptem.<br>• Po 5 nieudanych próbach w 10 min następuje blokada konta na 5 min. |
| US-006 | Konfiguracja progów | Jako właściciel chcę zmienić globalne progi ufności detekcji, aby dopasować czułość systemu. | • Edycja pliku config.yaml zmienia progi bez restartu kontenera.<br>• Zmienione progi obowiązują dla wszystkich kolejnych nagrań. |
| US-007 | Retencja danych | Jako właściciel chcę, by stare miniatury i logi usuwały się automatycznie, aby dysk nie uległ zapełnieniu. | • Cron lub proces serwisowy usuwa pliki > 10 dni.<br>• Rozmiar katalogu miniatur nie przekracza ustalonego limitu. |
| US-008 | Obsługa wielu obiektów | Jako właściciel nie chcę być zasypany wieloma alertami, gdy w jednej klatce jest więcej niż jeden obiekt. | • Jeżeli w pliku występuje wiele obiektów, system łączy je w jeden alert z listą etykiet. |
| US-009 | Monitoring SLA | Jako właściciel chcę widzieć statystyki detekcji i czasów reakcji, aby ocenić skuteczność systemu. | • Endpoint Prometheus udostępnia metryki: `alert_processing_seconds`, `detections_total`, `io_errors_total`. |

## 6. Metryki sukcesu
* Detekcja twarzy w min. 80 % klatek każdego z 3 plików testowych.
* Detekcja tablic w min. 80 % klatek każdego pliku testowego.
* Rozpoznanie znanych twarzy/tablic z dokładnością min. 80 %.
* Czas dostarczenia alertu (P95) ≤ 30 s od `mtime` pliku.
* Rozmiar bazy danych + miniatur ≤ 2 GB po 30 dniach pracy.
* Brak utraconych alertów w testach z 10 kolejnymi plikami.

