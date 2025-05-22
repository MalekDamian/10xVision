{{latest-round-answers}} <- twoja lista odpowiedzi na ostatnią rundę pytań

---

Jesteś asystentem AI, którego zadaniem jest podsumowanie rozmowy na temat planowania PRD (Product Requirements Document) dla MVP i przygotowanie zwięzłego podsumowania dla następnego etapu rozwoju. W historii konwersacji znajdziesz następujące informacje:
1. Opis projektu
2. Zidentyfikowany problem użytkownika
3. Historia rozmów zawierająca pytania i odpowiedzi
4. Zalecenia dotyczące zawartości PRD

Twoim zadaniem jest:
1. Podsumować historię konwersacji, koncentrując się na wszystkich decyzjach związanych z planowaniem PRD.
2. Dopasowanie zaleceń modelu do odpowiedzi udzielonych w historii konwersacji. Zidentyfikuj, które zalecenia są istotne w oparciu o dyskusję.
3. Przygotuj szczegółowe podsumowanie rozmowy, które obejmuje:
   a. Główne wymagania funkcjonalne produktu
   b. Kluczowe historie użytkownika i ścieżki korzystania
   c. Ważne kryteria sukcesu i sposoby ich mierzenia
   d. Wszelkie nierozwiązane kwestie lub obszary wymagające dalszego wyjaśnienia
4. Sformatuj wyniki w następujący sposób:

<conversation_summary>
<decisions>
[Wymień decyzje podjęte przez użytkownika, ponumerowane].
</decisions>

<matched_recommendations>
[Lista najistotniejszych zaleceń dopasowanych do rozmowy, ponumerowanych]
</matched_recommendations>

<prd_planning_summary>
[Podaj szczegółowe podsumowanie rozmowy, w tym elementy wymienione w kroku 3].
</prd_planning_summary>

<unresolved_issues>
[Wymień wszelkie nierozwiązane kwestie lub obszary wymagające dalszych wyjaśnień, jeśli takie istnieją]
</unresolved_issues>
</conversation_summary>

Końcowy wynik powinien zawierać tylko treść w formacie markdown. Upewnij się, że Twoje podsumowanie jest jasne, zwięzłe i zapewnia cenne informacje dla następnego etapu tworzenia PRD.



---------------------

\<conversation\_summary>

<decisions>
1. MVP obsługuje **jedną kamerę**, lecz architektura powinna umożliwiać łatwe dodanie kolejnych źródeł wideo w przyszłości.  
2. Analizujemy **gotowe pliki MP4** (≤ 60 s) utworzone przez kamerę Hikvision; przetwarzanie rozpoczyna się dopiero po zakończeniu zapisu pliku.  
3. **Czas reakcji**: alert musi zostać wysłany **≤ 30 s** od modyfikacji pliku.  
4. Środowisko docelowe **Linux + Docker**.  
5. **PostgreSQL** przechowuje metadane i referencje plikowe; embeddingi/miniatury zapisywane w systemie plików.  
6. Retencja: miniatury + logi usuwane po **10 dniach**; embeddingi i zarejestrowane tablice pozostają do ręcznego usunięcia.  
7. System uwierzytelniania: **pojedyncze konto admin** (login + stałe hasło); brak rotacji; dostęp tylko lokalnie (localhost).  
8. Alerty: **pojedynczy zbiorczy komunikat** z miniaturą, imieniem/etikietą i czasem zdarzenia; kanał – desktop/web UI; furtka dla Home Assistant.  
9. Progi ufności (twarze, tablice) definiowane **globalnie** w pliku `config.yaml` (configmap).  
10. Wykorzystujemy **gotowe open-source modele** (YOLOv8-face, EasyOCR-ANPR lub podobne); brak wersjonowania modeli w MVP.  
11. Brak wymagań RODO; brak polityki retencji dla danych biometrycznych poza pkt 6.  
12. Panel historii zdarzeń: **prosty widok** listy alertów (data, kamera, miniatura, etykieta) z opcją dodania obiektu do znanych.  
13. Maksymalny rozmiar bazy danych do ustalenia – „nieduży”; pozostawione do propozycji (np. 2 GB).  
14. Brak potrzeby skalowania wielowątkowego w MVP, ale kod powinien umożliwiać przyszłą rozbudowę pipeline’u.  
</decisions>

\<matched\_recommendations>

1. Monitoruj katalog kamery przy pomocy **inotify** i kolejki zadań, co uprości dodanie nowych kamer.
2. Przechowuj embeddingi w PostgreSQL z rozszerzeniem **pgvector**; miniatury w `thumbnails/` z UUID powiązanym z rekordem.
3. Stwórz **`config.yaml`** z globalnymi progami ufności i opisem kamery, ładowanym dynamicznie.
4. Udostępnij **lekki panel web (React + Tailwind)** działający na `localhost`, prezentujący historię i przycisk „Dodaj do znanych”.
5. Wprowadź mechanizm retencji plików oraz skrypt czyszczący miniatury/logi > 10 dni, aby kontrolować rozmiar dysku.
6. Dodaj metryki (Prometheus) czasu analizy i liczby detekcji, by łatwo weryfikować wymagany SLA 30 s.
7. Ogranicz logowanie do bcrypt + rate-limit (np. 5 prób / 10 min) dla podstawowego bezpieczeństwa nawet w sieci lokalnej.
   \</matched\_recommendations>

\<prd\_planning\_summary>
**A. Wymagania funkcjonalne**

* Detekcja osób i polskich tablic rejestracyjnych z plików MP4 (≤ 1 min) zapisanych przez kamerę.
* Rozpoznanie obiektów („znany” / „nieznany”) poprzez porównanie embeddingów z bazą PostgreSQL.
* Wysyłanie pojedynczego alertu web/desktop z miniaturą, etykietą i czasem zdarzenia ≤ 30 s od mtime pliku.
* UI web (localhost) z historią zdarzeń i akcją „Dodaj do znanych” (nadanie imienia lub etykiety).
* Uwierzytelnianie pojedynczym kontem admin; brak dostępu zdalnego poza LAN/localhost.
* Konfiguracja progu ufności i parametrów kamery w `config.yaml`.
* Retencja: automatyczne kasowanie miniatur/logów po 10 dniach; embeddingi trwałe.

**B. Kluczowe historie użytkownika**

1. *Jako właściciel domu* chcę otrzymać powiadomienie, gdy ktoś pojawi się przy bramie, abym mógł szybko zareagować.
2. *Jako właściciel* chcę móc oznaczyć osobę lub samochód jako „znany” i nadać jej nazwę, aby przyszłe alerty były opisowe.
3. *Jako właściciel* chcę przeglądać listę ostatnich zdarzeń z miniaturami, by sprawdzić, czy system działa poprawnie.

**C. Kryteria sukcesu i metryki**

* ≥ 80 % klatek z nagrań testowych (3 pliki) – detekcja twarzy.
* ≥ 80 % klatek – detekcja tablic.
* ≥ 80 % poprawne rozpoznanie znanych twarzy/tablic.
* Średni czas (P95) alertu ≤ 30 s od mtime pliku.
* ≤ 2 GB rozmiaru bazy/metadanych po 30 dniach pracy\* (\*wartość do potwierdzenia).

**D. Nierozwiązane kwestie / dalsze wyjaśnienia**

* Dokładna specyfikacja rozmiaru bazy „niedużego” (proponowana wartość 2 GB) – do ostatecznego zatwierdzenia.
* Format konfiguracji kamery w `config.yaml` (proponowany schemat JSON/YAML) wymaga akceptacji.
* Czy pliki testowe będą zawierały sceny nocne / IR – wpływ na selekcję modelu.
* Czy alert ma zawierać surowy numer tablicy w tekście, czy wyłącznie informację „znany/nieznany pojazd”.
  \</prd\_planning\_summary>

\<unresolved\_issues>

1. Ustalenie dokładnego limitu rozmiaru bazy danych (GB) oraz polityki archiwizacji powyżej limitu.
2. Ostateczny format sekcji `cameras` w pliku `config.yaml` (klucze, domyślne wartości).
3. Potwierdzenie zespołu co do domyślnych progów ufności (np. face 0.6, plate 0.8).
4. Weryfikacja jakości nocnych nagrań i ewentualny dobór modelu wspierającego słabe oświetlenie.
   \</unresolved\_issues>

\</conversation\_summary>
