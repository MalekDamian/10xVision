# ID Service

## Opis projektu
ID Service to aplikacja do zarządzania tożsamością, która zapewnia bezpieczne i wydajne rozwiązanie do uwierzytelniania i autoryzacji użytkowników.

## Stos technologiczny

### Frontend
- React (z TypeScript)
- ESLint + Prettier do lintowania i formatowania kodu
- Node.js jako środowisko uruchomieniowe

### Backend
- Python
- Flake8 do lintowania
- Black do formatowania kodu

## Rozpoczęcie pracy lokalnie

### Wymagania wstępne
- Node.js (wersja określona w .nvmrc)
- Python 3.x
- pip (menedżer pakietów Pythona)

### Instalacja

1. Sklonuj repozytorium:
```bash
git clone [URL_REPOZYTORIUM]
cd id-service
```

2. Frontend:
```bash
# Instalacja zależności
npm install

# Uruchomienie serwera deweloperskiego
npm start
```

3. Backend:
```bash
# Instalacja zależności
pip install -r requirements.txt

# Uruchomienie serwera
python manage.py runserver
```

## Dostępne skrypty

### Frontend
- `npm run lint` - uruchomienie ESLint
- `npm run format` - formatowanie kodu za pomocą Prettier

### Backend
- `flake8 .` - uruchomienie lintera Python
- `black .` - formatowanie kodu Python

## Zakres projektu
Projekt obejmuje implementację systemu zarządzania tożsamością z następującymi głównymi funkcjonalnościami:
- Uwierzytelnianie użytkowników
- Zarządzanie sesjami
- Autoryzacja dostępu
- Bezpieczne przechowywanie danych uwierzytelniających

## Status projektu
🚧 Projekt w fazie rozwoju

## Licencja
[DO DODANIA] - Proszę określić preferowaną licencję

## Dodatkowe informacje
- Dokumentacja techniczna znajduje się w katalogu `/docs`
- Szczegółowe wymagania produktu dostępne są w pliku `prd.md`