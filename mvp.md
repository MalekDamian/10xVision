# Aplikacja - id-service

### Główny problem
Sprawdzanie za oknem kto przyszedł na działkę lub przyjechał jest trudne i nie jest dla nieniwych osób. Trzeba wstać i sprawdzić, co zajmuje czas i nie mozna przygotować się na wizytę.


### Najmniejszy zestaw funkcjonalności
- Realtime'owa obsługa pliku mp4 i analiza obrazu
- Rozpoznanie obiektu - osoba lub tablica rejestracyjna pojazdu
- Integracja z zapamiętanymi osobami lub tablicami
- Alert uzytkownika, ze ktos przyszedl lub przyjechal z informacją czy go znamy lub nie (kim jest). Jesli nie znamy to pytanie czy dodajemy do bazy.


### Co NIE wchodzi w zakres MVP
- Aplikacja mobilna - na poczatek alerty, docelowo integracja z Home Assistant
- Obsługujemy na start tylko format MP4

### Kryteria sukcesu
- wykrycie tablicy rejestracyjnej na co najmniej 80% klatek z testowego nagrania
- wykrycie twarzy w co najmniej 80% klatek z nagrania
- rozpoznanie tablicy lub twarzy w co najmniej 80%