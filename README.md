# 2S Sales: Flutter + Odoo

A Flutter app for sales staff, backed by Odoo. Users log in with their Odoo account and can:

- browse and search customers, and edit a customer's phone number
- as internal users only: list sales orders, see each order's lines, and confirm quotations

Customers and orders are cached for offline use, and phone edits made offline are queued and synced when the connection returns.

## Odoo backend

| | |
|---|---|
| URL | https://2stask.odoo.com |
| Database | `2stask` |
| Version | Odoo 19 (`saas~19.4+e`, Enterprise), One App Free plan (Sales only) |
| Admin login | `hamdymohamedelbltagy90@gmail.com` (password kept in `.env`, not in this repo) |
| Demo internal user | `demo@example.com`: salesperson who sees all documents (password is `SEED_DEMO_PASSWORD` in `.env`) |
| Portal test user | `portal@example.com`: not internal, so Sales Orders are hidden (password is `SEED_PORTAL_PASSWORD` in `.env`) |

Reviewers should use the two test accounts, not the admin account. Odoo 19 requires logins to be emails; `example.com` is a reserved domain, so no mail can reach a real inbox.

## Setup

Requirements: Flutter 3.38+ (Dart 3.10+), Android SDK, and an Android device or emulator. Run it on Android, not Chrome: a browser build is blocked by CORS because Odoo doesn't send CORS headers for `/web/*`.

```bash
flutter pub get

# 1. Credentials for the command-line tools (the app itself never reads .env)
cp .env.example .env        # then fill in ODOO_LOGIN / ODOO_PASSWORD / SEED_DEMO_PASSWORD / SEED_PORTAL_PASSWORD

# 2. Check the API against the live server
dart run tool/smoke_test.dart            # admin user
dart run tool/smoke_test.dart --demo     # internal demo user
dart run tool/smoke_test.dart --portal   # portal user

# 3. Seed test data (skips anything that already exists)
dart run tool/seed.dart

# 4. Run the app
flutter run                  # with a device connected (adb devices)
```

The login screen asks only for email and password. For security, the server URL and database are fixed at build time and users can't change them in the app. To point a build at another server:

```bash
flutter run --dart-define=ODOO_URL=https://other.odoo.com --dart-define=ODOO_DB=other
```

Quality checks: `flutter analyze` and `flutter test`.

### Seed data

`tool/seed.dart` creates the records defined in `lib/core/odoo/odoo_seed.dart`:

- 12 customers (`res.partner`, `customer_rank = 1`, `ref` = `SEED-01` … `SEED-12`)
- 6 products (`default_code` = `SEED-P01` … `SEED-P06`)
- 10 sales orders (`client_order_ref` = `SEED-SO-xx`): 3 confirmed and 7 quotations
- 1 internal demo user (`demo@example.com`, Sales "All Documents") and 1 portal user (`portal@example.com`, so `share = true`) for testing the permission check. Their passwords are reset to the values in `.env` on every run

If `SEED-` partners already exist, the customers, products and orders are skipped. The two test users are created if missing, otherwise updated. The seeder is a Dart script rather than the Python the brief asked for: Python isn't installed on the dev machine, and a Dart script can reuse the app's `OdooClient`.

## Features

| # | Requirement | Where |
|---|---|---|
| 1 | Email/password login, session remembered across restarts | `features/auth`, `AuthRepository.restoreSession` |
| 2 | Customers (`res.partner`, `customer_rank > 0`) with server-side search | `features/customers/view/customers_page.dart` |
| 3 | Customer details and phone editing | `features/customers/view/customer_detail_page.dart` |
| 4 | Internal user check (`res.users.share == false`) | `OdooService.isInternalUser` |
| 5 | Sales orders list, internal users only | `features/orders/view/orders_page.dart` |
| 6 | Order lines, and **Confirm** for `draft`/`sent` orders (`action_confirm`) | `features/orders/view/order_detail_page.dart` |
| 7 | Hive offline cache and an offline phone-edit queue that syncs automatically | `data/local/local_cache.dart`, `features/sync` |
| 8 | Logout (destroys the Odoo session and wipes local data) | `features/home/view/account_page.dart` |

Every list has loading, error, empty and cached-data states, plus pull to refresh.

## Architecture

```
lib/
├── main.dart                 # composition root: Hive, persistent cookie jar, DI
├── app.dart                  # MaterialApp + AuthCubit, routes on auth status
├── core/
│   ├── odoo/                 # pure Dart (no Flutter), shared with tool/
│   │   ├── odoo_client.dart      # Dio JSON-RPC client, session cookie, error mapping
│   │   ├── odoo_exceptions.dart  # typed errors (network, auth, session expired, access…)
│   │   ├── odoo_service.dart     # business calls: customers, phone, orders, confirm, role
│   │   ├── odoo_seed.dart        # seed data definition
│   │   └── odoo_smoke_test.dart  # live endpoint checks
│   ├── config/  network/  theme/  utils/  widgets/
├── data/
│   ├── models/               # Customer, SaleOrder, SaleOrderLine, UserSession, PendingPhoneEdit
│   ├── local/local_cache.dart    # Hive boxes (session, customers, orders, lines, queue)
│   └── repositories/         # online-first with a cache fallback
└── features/                 # one folder per feature: cubit/ + view/
    ├── auth/  customers/  orders/  sync/  home/
tool/                         # seed.dart, smoke_test.dart, env.dart (.env reader)
```

**Layers.** Views depend only on Cubits (`flutter_bloc`). Cubits depend on repositories. Repositories combine `OdooService` (remote) with `LocalCache` (Hive). Only the Odoo layer knows about JSON-RPC.

**Session scope.** `HomePage` is keyed by the user's uid and owns the session-scoped cubits (`SyncCubit`, `CustomersCubit` and `OrdersCubit`, the last one only for internal users). Logging out removes it, which disposes them. Portal users never get an `OrdersCubit`, so the app never calls `sale.order` for them.

**Session handling.** Odoo's `session_id` cookie is stored in a `PersistCookieJar`. On startup `restoreSession` calls `/web/session/get_session_info`:

- **Valid cookie:** the user goes straight to Home.
- **Expired cookie:** back to Login.
- **No network:** the cached session is kept, so the app opens offline with cached data.

If any call returns `SessionExpiredException`, `OdooClient.onSessionExpired` sends the user to Login.

**Offline.**
- **Reads:** customers, orders and order lines are cached in Hive. When Odoo is unreachable the repositories return cached data, and the UI says so.
- **Phone edits:** made offline, they go into a Hive queue with one entry per customer (the latest edit wins) and show a "waiting to sync" badge. `SyncCubit` watches `connectivity_plus` and flushes the queue when the connection returns, or on **Sync now**.
- **Rejected edits:** if Odoo rejects an edit (for example an access error), it is dropped and reported rather than retried forever.
- **Confirming an order:** needs a connection. It is never queued, because it has side effects on the server.

## API method: JSON-RPC with a session cookie

| Call | Endpoint |
|---|---|
| Login | `POST /web/session/authenticate` with `{db, login, password}`. Returns `uid` and sets the `session_id` cookie |
| Session check | `POST /web/session/get_session_info` |
| All ORM calls | `POST /web/dataset/call_kw` with `{model, method, args, kwargs}` (`search_read`, `read`, `write`, `action_confirm`) |
| Logout | `POST /web/session/destroy` |

Why this method:

- **It's the only API this plan allows.** The JSON-2 API (`/json/2/...`) needs an API key, which the One App Free plan doesn't provide. XML-RPC is deprecated in Odoo 19 and scheduled for removal.
- **Users log in with their own credentials.** Every call runs with that user's rights and record rules. This is what makes the permission check meaningful: a portal user sees no customers and can't write, and Odoo enforces that.
- **It's the protocol Odoo's own web client uses,** so its behavior is stable and well known: the same error payloads, `SessionExpiredException` handling and cookie lifetime.
- **No secrets are stored on the device.** Only the session cookie is kept; the password is never saved.

The role check reads `res.users.share` for the logged-in uid. `share == false` means the user belongs to `base.group_user` (internal); portal and public users are share users.

## Tests

`flutter test` runs 28 tests:

- **Models:** Odoo `false` values, many2one fields, UTC dates, and JSON round trips.
- **`OdooClient`:** request payloads, the session cookie, and mapping of every error type (with a fake Dio adapter).
- **Cubits:** auth, customers (including search debounce), phone save (synced, queued and rejected), and order confirmation (with `bloc_test` and `mocktail`).
- **Login screen:** validation, and showing errors from Odoo.
