# CartGuard — Flutter Mobile App

A polished, production-style Flutter shopping app for your **CartGuard AI**
project. It talks directly to your existing Node/Express backend
(`https://cartguard-ai-1.onrender.com/api`) — no backend changes needed.

## ✨ What's included

- **Modern Material 3 UI** — custom violet/emerald brand theme, rounded
  cards, gradient buttons, shimmer skeleton loaders, empty/error states.
- **Auth** — Login & Register screens wired to `/api/auth/register` and
  `/api/auth/login`, JWT persisted locally with `shared_preferences`.
- **Storefront (Home)** — search, category chips, 2-column product grid,
  pull-to-refresh.
- **Product detail** — hero image, specs table, quantity stepper, add to
  cart.
- **Cart** — swipe-to-delete, inline quantity steppers, live totals, and a
  banner that surfaces CartGuard's AI recovery offers/discounts when the
  backend returns one on the cart object.
- **Checkout → Orders** — places an order via `/api/orders`, shows an order
  success screen, and a full order-history screen with status chips
  (`PLACED` / `RESCUED` / `CANCELLED`).
- **Notifications** — reads `/api/cart/notifications` so shoppers can see
  the AI-generated recovery messages that the backend would otherwise only
  send over WhatsApp/email.
- **Behavioral telemetry** — a lightweight `SignalTracker` sends periodic
  heartbeats and app-lifecycle signals (`tab_switch`, `product_view`, etc.)
  to `/api/cart/heartbeat` and `/api/cart/signal`, the same micro-signals
  your ML risk engine already consumes from the web storefront.
- **Profile** — account info + logout.

## 🗂 Project structure

```
lib/
  core/            # theme, constants (API base URL lives here)
  models/          # Product, Cart, Order, User
  services/        # ApiClient (REST wrapper), SignalTracker (telemetry)
  providers/        # AuthProvider, ProductProvider, CartProvider (state)
  screens/          # one folder per feature area
  widgets/          # shared UI components
```

## 🚀 Getting started

This zip ships the **Dart application code** (`lib/`) and `pubspec.yaml`.
Flutter's platform folders (`android/`, `ios/`, `web/`) are project-specific
boilerplate that Flutter generates for you — regenerate them once, then
drop this code in:

```bash
# 1. Unzip, then from inside the project folder:
flutter create .

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device / emulator
flutter run
```

`flutter create .` is safe to run even though `lib/main.dart` already
exists — it only adds the missing `android/`, `ios/`, etc. folders and
won't overwrite your code.

### Requirements
- Flutter SDK 3.22+ (Dart 3.3+) — [install guide](https://docs.flutter.dev/get-started/install)
- Android Studio / Xcode for a device or emulator

## ⚙️ Configuration

The backend URL is a single constant in `lib/core/constants.dart`:

```dart
static const String baseUrl = 'https://cartguard-ai-1.onrender.com/api';
```

Change this if you redeploy the Node/Express server elsewhere. No other
code needs updating — every screen goes through `ApiClient`.

## 🔌 API endpoints this app uses

| Feature | Endpoint |
| --- | --- |
| Register / Login | `POST /auth/register`, `POST /auth/login` |
| Products | `GET /products`, `GET /products/:id` |
| Cart | `GET /cart`, `POST /cart/add`, `PUT /cart/update`, `DELETE /cart/:productId` |
| Telemetry | `POST /cart/signal`, `POST /cart/heartbeat`, `POST /cart/goodbye` |
| Notifications | `GET /cart/notifications` |
| Orders | `POST /orders`, `GET /orders/mine` |

All authenticated requests attach `Authorization: Bearer <token>`
automatically once a user logs in.

## 🎨 Design notes

The theme (`lib/core/theme.dart`) centers on your brand's violet
(`#7C3AED`) and emerald (`#10B981`) — the same palette as your README's
badges — applied consistently across buttons, chips, badges, and the AI
recovery banner in the cart, so the mobile app visually matches the
CartGuard AI brand rather than looking like a generic template.

## 📦 Building a release APK

```bash
flutter build apk --release
```

The signed/unsigned APK will be under `build/app/outputs/flutter-apk/`.
"# cartguard-ai-mobile" 
