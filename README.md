# PocketAirBnB

A Bangladesh-centric, Airbnb-style stay-discovery app built with **Flutter**,
**Riverpod** and **go_router**. Android-only.

The app currently runs fully **on-device with no backend**: the hotel catalog
ships as a bundled JSON fixture, and auth, profile, favorites, trips, inbox
and host listings persist locally via `shared_preferences`. A real backend
(database + auth) is planned as the next phase and can be slotted in behind
the existing provider APIs.

## Features

- Splash → onboarding → local sign-up / login (session persists) or guest mode.
- Explore feed with city collections, search with filters/sort, interactive
  OpenStreetMap view with price markers.
- Hotel details with image carousel, amenities and booking flow
  (dates, guests, rooms, BDT price breakdown).
- Trips (upcoming/past, cancel, review), Saved (wishlist), Inbox — all
  persisted on-device and reachable from the Profile tab.
- Become a Host: create listings that appear in the guest feed immediately,
  manage availability on a calendar.
- Mock AI chat assistant.
- Material 3 theme, Inter typography, `৳` currency formatting.

## Project structure

```
lib/
  main.dart                 # ProviderScope + runApp
  app/                      # MaterialApp.router, theme, routes
  core/                     # utils (currency, validators), small widgets
  data/
    models/                 # Hotel, Property, TripBooking
    repositories/           # HotelRepository (bundled fixture)
    services/local_store.dart  # SharedPreferences persistence layer
  providers/                # Riverpod state (auth, hotels, booking, ...)
  features/                 # one folder per screen
  shared/widgets/           # reusable cards, sheets, search bar
assets/
  fixtures/hotels_bd.json   # bundled hotel catalog
  images/branding/logo.png
```

## Getting started

```powershell
flutter pub get
flutter analyze
flutter test
flutter run          # needs an Android device or emulator
```
