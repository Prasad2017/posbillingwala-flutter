# POS Billingwala v2 — Roadmap

## Phase 1 — Foundation
- [x] Flutter project for Android + iOS
- [x] App theme aligned with Android brand color
- [x] Feature module routes + home hub
- [x] Splash / licence gate / PB-PIN unlock
- [x] Login + trial register against existing API
- [x] Shared catalog/API models beyond auth

## Phase 2 — Core billing
- [x] Local database (Drift) — food types, categories, products, portions
- [x] Masters browse + cloud sync (categories/products)
- [x] Product catalog + cart
- [x] Invoice create / payment modes (Cash, UPI, Cash+UPI)
- [x] Takeaway flow (customer + takeaway billing)
- [x] Today's bills report

## Phase 3 — Restaurant modes
- [x] Table floor + dine-in billing
- [x] KOT delta rounds + on-screen preview
- [x] Join / split tables
- [x] Mess members + QR tokens + common Mess QR

## Phase 4 — Sync & hardware
- [x] Upload pending invoices to cloud
- [x] Download / pull cloud invoices
- [x] ESC/POS bill & KOT builder + share fallback
- [x] Android Bluetooth thermal print
- [x] iOS / LAN network ESC/POS print path

## Phase 5 — Parity & release
- [x] Reports hub (Today / Month / Day + sales KPIs)
- [x] Inventory stock-in/out ledger + expenses
- [x] FCM notifications (token register + mess/license/promo)
- [x] Store release prep (signing template + Play/App Store guide)
- [x] Store listing copy + screenshots / privacy checklist (`docs/STORE_RELEASE.md`)
- [ ] Production store listing assets & first public upload (keystore + consoles)

## Phase 6 — Android parity wiring (schema v9+)
- [x] Cross-platform device identity (no `android_id` package; legacy PHP field mapper)
- [x] Hand-written `toJson`/`fromJson` on API DTOs (Drift remains only codegen)
- [x] Server logout (`LogOut.php`)
- [x] Combos in cart (`addComboToCart`, negative productId, skip inventory deduct)
- [x] Masters local create + upload pending + combo download
- [x] POS combo chip strip
- [x] Full sync hub (masters / invoices / inventory / mess / dining)
- [x] Dining session network + sync status on open/settle + cloud upload/download
- [x] Mess member/token cloud upload + verify
- [x] Company + printer cloud settings on Settings page
- [x] Support tickets page + APIs
- [x] Pending invoice line delete / void bill
- [x] Reports payment-mode filter chips

## Phase 7 — Deep Android UI parity
- [x] Receipt shop header / UPI QR / duplicate bill / KOT auto-print
- [x] Trial bill gate, walk-in form, logo capture, POS subcategory + voice
- [x] Sales overview charts (7-day bars + payment donut)
- [x] Historical month picker on reports
- [x] Cloud sync pending chips + Fetch Data wipe-then-download
- [x] Shop CGST/SGST + cart GST fallback
- [x] Category reorder (long-press move)
- [x] Branch label on home
- [ ] Full hi/mr ARB string catalog (locale wiring exists; copy still mostly English)
- [x] Branch-scoped Drift rows (stamp + filter + login purge/claim)
- [x] Shared UI kit (`core/widgtes`) adopted across presentation (MPIN digits / POS search / a few custom sheets kept)
- [ ] Production store listing assets & first public upload (keystore + consoles)
