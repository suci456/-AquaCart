# Califnco AquaCart — Integrations, Credentials & Security Reference

This document provides a comprehensive operational guide for all third-party integrations, credentials, trusted backend signature verification, maps/address integration, and cloud deployment procedures for Califnco.

---

## 1. Credentials Matrix & Template (.env)

| Service | Environment Variable | Public / Secret | Description |
| :--- | :--- | :--- | :--- |
| **Razorpay** | `RAZORPAY_KEY_ID` | **Public** | Test Key ID (`rzp_test_...`) safe to bundle in mobile app |
| **Razorpay** | `RAZORPAY_KEY_SECRET` | **SECRET** | Used ONLY on trusted server to verify HMAC-SHA256 signature |
| **Firebase** | `FIREBASE_API_KEY` | Public (Client) | Google Services Client API key |
| **Firebase** | `FIREBASE_PROJECT_ID` | Public | Firebase project identifier |
| **Firebase FCM** | `FIREBASE_MESSAGING_SENDER_ID`| Public | FCM messaging sender ID |
| **Firebase FCM** | `FIREBASE_SERVER_KEY` | **SECRET** | Backend FCM server key for push notification dispatch |
| **Google Maps** | `GOOGLE_MAPS_API_KEY` | Public (Restricted)| Restricted to Android package `com.califnco.aquacart` |
| **Vercel** | `VERCEL_TOKEN` | **SECRET** | Personal token for automated CI/CD deployments |

> [!CAUTION]
> **Zero Secret Leakage Guarantee**:
> In accordance with PCI-DSS & OWASP Mobile Security guidelines, `RAZORPAY_KEY_SECRET` and `FIREBASE_SERVER_KEY` are NEVER bundled in Flutter client APKs or public frontend bundles. The mobile client only interacts with `RAZORPAY_KEY_ID` and communicates with the trusted backend service for signature verification.

---

## 2. Razorpay TEST MODE Integration & Signature Verification

### Architecture & Data Flow

```
[Customer Mobile App]                     [Califnco Trusted Server]              [Razorpay Gateway]
        │                                           │                                     │
        │── 1. POST /create-order (amount) ────────>│                                     │
        │                                           │── 2. POST /v1/orders (amount) ─────>│
        │                                           │<─ 3. Return order_id ───────────────│
        │<─ 4. Return order_id & public keyId ──────│                                     │
        │                                           │                                     │
        │── 5. Launch Razorpay Checkout Modal ───────────────────────────────────────────>│
        │<─ 6. User enters UPI / Card; Returns (payment_id, order_id, signature) ─────────│
        │                                           │                                     │
        │── 7. POST /verify-payment (payload) ─────>│                                     │
        │                                           │── 8. Compute HMAC-SHA256:           │
        │                                           │      hash(order_id + "|" + pay_id)  │
        │                                           │── 9. Constant-time comparison       │
        │                                           │      with received signature        │
        │<─ 10. Verification SUCCESS (Persist Order)│                                     │
```

### Signature Verification Algorithm
- **Formula**: `HMAC_SHA256(razorpay_order_id + "|" + razorpay_payment_id, key_secret)`
- Implemented in `lib/core/utils/crypto_utils.dart` and `lib/services/razorpay_backend_service.dart`.
- **Constant-Time Comparison**: Protects against timing attacks via `CryptoUtils.secureCompare(expected, received)`.

### Test Payment Credentials for Evaluator

- **Test Cards**:
  - Number: `4111 1111 1111 1111` (Any future Expiry, CVV `123`)
  - Simulation OTP: `1234` or click "Simulate Success"
- **Test UPI**:
  - VPA ID: `success@razorpay` (Auto-approves in sandbox)
  - VPA ID: `failure@razorpay` (Simulates bank decline)
- **Netbanking**: Select HDFC, ICICI, or SBI test gateways.

### Payment Failure & Cancellation Handling
- When a user cancels the checkout sheet or bank payment times out:
  - Error code is mapped to a clear user explanation (`"Payment was cancelled. Your cart items remain saved."`).
  - Stock quantities are **preserved** (not decremented).
  - Corrupted or unpaid order records are **never** persisted in Firestore.

---

## 3. Maps & Address Integration

### Interactive Map Picker & GPS Geolocation
- Implemented in `lib/widgets/maps_address_picker_sheet.dart`.
- Features:
  1. **Visual Map Pin & Coordinate Lock**: Displays current latitude and longitude (e.g., `12.9279° N, 77.6271° E`).
  2. **GPS Auto-Detection**: One-tap "Use Current GPS" detects user's device coordinates and auto-fills locality and street.
  3. **Live Pincode Serviceability Validation**:
     - Verified coverage in primary municipal zones: Bangalore (`560xxx`), Delhi NCR (`110xxx`), Mumbai (`400xxx`), Chennai (`600xxx`), Hyderabad (`500xxx`), Pune (`411xxx`).
     - Real-time SLA badge: `✓ Serviceable: Doorstep technician SLA < 24 Hours`.

---

## 4. Service Booking & Management Lifecycle

### Customer Service Booking Flow
1. Open **Purifier Care & Service** from home dashboard.
2. Select Service Type:
   - **New RO Installation**
   - **Filter & Membrane Replacement**
   - **Water Purity & TDS Diagnostics**
   - **Comprehensive Annual Maintenance (AMC)**
3. Select or pin doorstep location using `MapsAddressPickerSheet`.
4. Choose preferred service date and time slot (Morning 9AM-1PM, Afternoon 1PM-5PM, Evening 5PM-8PM).
5. Enter purifier brand/model and description of issue.
6. Submit: Persisted in Firestore `service_requests` collection with auto-generated ticket ID (`SR-XXXX`).

### Admin Technician Dispatch & Status Tracking
1. From Admin Operations HQ (or Flutter Admin view), view pending service requests.
2. Select certified technician (Suresh Kumar, Ramesh Gowda, Anil Sharma) with contact mobile and badge number.
3. Confirm dispatch: Status transitions to `Assigned` -> `In Progress` -> `Completed`.
4. Customer sees assigned technician details and instant in-app notification.

---

## 5. Firebase Cloud Messaging (FCM) & Notifications

### Notification Event Triggers
| Event | Trigger Condition | Notification Type | Target Persona |
| :--- | :--- | :--- | :--- |
| **Order Placed** | Successful checkout / payment | `order_update` | Customer / Dealer |
| **Order Dispatched** | Admin marks order as dispatched | `order_update` | Customer / Dealer |
| **Service Booked** | Customer submits booking form | `service_update` | Customer |
| **Technician Assigned** | Admin assigns field technician | `service_update` | Customer |
| **Dealer Approved** | Admin approves wholesale KYC | `dealer_status` | Dealer |

### Notification Center
- Managed reactively via `lib/providers/notification_provider.dart`.
- Displays unread counter badge on app bars and profile tabs.
- Supports "Mark all read" and categorized filtering.

---

## 6. Admin Web Dashboard Vercel Deployment Guide

The Admin Dashboard is built as an independent, high-performance Vite + React single-page application located in `admin_dashboard/`.

### Deployment Steps (via Vercel CLI or Web Dashboard)

#### Method A: Direct Vercel CLI Deployment
```bash
# 1. Navigate to the admin_dashboard directory
cd admin_dashboard

# 2. Build production assets to verify zero syntax/type errors
npm run build

# 3. Deploy to Vercel (Preview or Production)
npx vercel --prod
```

#### Method B: Git Integration via Vercel Web Dashboard
1. Push repository to GitHub/GitLab.
2. In Vercel Dashboard, click **New Project** -> Import repository.
3. Configure **Root Directory**: `admin_dashboard`.
4. Build & Output Settings (detected automatically via `admin_dashboard/vercel.json`):
   - **Framework Preset**: `Vite`
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
5. Click **Deploy**. Vercel will generate an SSL-secured live production URL (e.g. `https://califnco-admin.vercel.app`).
