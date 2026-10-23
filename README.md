# 💧 AquaCart - Water Purifier E-Commerce, Service & Wholesale Platform
> **Califnco Round 1 Technical Assignment**  
> *Built with Flutter (Android & Cross-Platform), Cloud Firestore, Firebase Authentication, Razorpay Test Mode, Admin Web Dashboard, and n8n AI Instagram Automation.*

---

## 🌟 Executive Summary

**AquaCart** is an end-to-end digital ecosystem for modern water purification solutions, engineered to serve three distinct user stakeholders within a unified platform:

1. **Retail Customers**: Discover domestic & commercial RO/UV/UF purifiers, filters, and AMC plans, complete checkout with Razorpay test mode, track real-time order fulfillment, and book doorstep installation & filter maintenance.
2. **Authorized Dealers (B2B)**: Access wholesale tier pricing with enforced Minimum Order Quantities (MOQ), calculate bulk margins, access 15-day dealer credit lines, and manage wholesale invoices.
3. **Operations & Admins**: Full-featured Web Dashboard to monitor real-time platform KPIs, manage product prices and inventory, schedule field service technicians, and verify dealer GSTIN KYC applications.
4. **Marketing Automation (n8n)**: Dedicated AI-powered workflow generating daily educational water quality posts and publishing to Instagram via Meta Graph API.

---

## 🏗️ System Architecture

```mermaid
graph TD
    subgraph Mobile_App [AquaCart Flutter Client (Android)]
        UI[Material 3 UI + Aqua Theme]
        State[Provider State Management]
        AuthSvc[Auth Service & Role Guard]
        PaySvc[Razorpay Test Gateway]
        Catalog[Role-Based Pricing Engine]
    end

    subgraph Operations [Admin Web Dashboard (Vite + React)]
        AdminUI[Operations Console]
        InvMgt[Stock & Pricing Manager]
        OrderMgt[Order Pipeline & Dispatch]
        DealerMgt[B2B Partner KYC Review]
        TechMgt[Field Technician Scheduler]
    end

    subgraph Cloud_Infrastructure [Firebase Backend]
        FAuth[Firebase Authentication]
        Firestore[(Cloud Firestore NoSQL)]
        Rules[Firestore Security Rules]
    end

    subgraph AI_Automation [n8n AI Engine]
        Cron[Daily 9 AM IST Cron]
        OpenAI[GPT-4o Copywriter + DALL-E 3]
        MetaAPI[Instagram Graph API]
    end

    UI --> State
    State --> AuthSvc
    State --> Catalog
    State --> PaySvc
    AuthSvc --> FAuth
    Catalog --> Firestore

    AdminUI --> Firestore

    Cron --> OpenAI --> MetaAPI
```

---

## 👥 Multi-Role Permissions Matrix

| Capability | Customer | Dealer (B2B) | Admin HQ |
| :--- | :---: | :---: | :---: |
| **Catalog Pricing** | Retail MRP & Discounts | Wholesale Tier Rates (Up to 40% margin) | Full Cost, Retail & Wholesale Edit |
| **Min Order Qty (MOQ)** | 1 Unit | Enforced (e.g., 5+ units for purifiers) | Any quantity (Samples) |
| **Payment Options** | Razorpay Test / UPI / COD | Razorpay Test / 15-Day Dealer Credit | View status / Manual mark paid |
| **Service Engine** | Book Installation / Filter Change | Bulk installation for clients | Assign Technicians & Dispatch |
| **Verification & KYC** | Instant standard sign-up | GSTIN, Trade License & Business PAN | Review & 1-Click Approve / Reject |

---

## 📁 Repository Structure

```
d:/AquaCart/
├── android/                          # Native Android wrapper, Manifest & Gradle
├── lib/                              # Flutter Mobile Application Source
│   ├── core/
│   │   ├── constants/                # App colors, roles, categories, order statuses
│   │   ├── theme/                    # Material 3 theme with Google Fonts
│   │   └── utils/                    # Currency (INR ₹) and date formatters
│   ├── models/                       # User, Product, Order, Service, Notification models
│   ├── providers/                    # Auth, Product, Cart, Order, Service providers
│   ├── services/                     # Mock data fallback, AuthService, RazorpayService
│   ├── screens/
│   │   ├── auth/                     # Login & Dealer B2B Registration with GSTIN
│   │   ├── customer/                 # Catalog, Detail, Cart, Checkout, Tracking, Service
│   │   ├── dealer/                   # Wholesale Dashboard, MOQ Bulk Order Engine
│   │   ├── notifications_screen.dart # Real-time alerts & status updates
│   │   ├── profile_screen.dart       # Account info & fast role switcher
│   │   └── splash_screen.dart        # Splash & entrypoint
│   ├── widgets/                      # ProductCard, ServiceCard, RoleBadge, AppButton
│   └── main.dart                     # App multi-provider entrypoint
├── admin_dashboard/                  # Web Dashboard for Admin (Vite + React)
│   ├── src/
│   │   ├── App.jsx                   # Live KPIs, Inventory, Orders, Technician Dispatch
│   │   ├── main.jsx
│   │   └── index.css
│   ├── package.json
│   └── vite.config.js
├── n8n_workflows/                    # n8n AI Marketing Automation
│   ├── daily_instagram_post_workflow.json # Exportable n8n workflow
│   └── README.md                     # Setup, credentials & node walkthrough
├── firebase/
│   └── firestore.rules               # Multi-role Cloud Firestore security rules
├── .env.example                      # Template for secrets and credentials
├── pubspec.yaml                      # Flutter dependencies
└── README.md                         # Documentation
```

---

## 🚀 Quickstart & Setup Guide

### 1. Prerequisites
- **Flutter SDK**: `>=3.0.0`
- **Node.js**: `>=18.0.0` (for Admin Web Dashboard)
- **Firebase Account** (Optional for live mode; full mock data layer included)
- **Razorpay Test Account** (Test keys start with `rzp_test_...`)

### 2. Environment Configuration
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Populate your test keys:
```properties
APP_ENV=development
USE_MOCK_DATA=true # Standalone mode with full realistic mock catalog
RAZORPAY_KEY_ID=rzp_test_YourKeyHere
```

### 3. Running the Flutter Mobile Application
To run the Flutter app on Android emulator, connected device, or Chrome web preview:
```bash
flutter pub get
flutter run
```

> **Evaluation Shortcut**:  
> In the Login screen, click on the **1-Click Evaluation Personas** chips (**Customer**, **Dealer B2B**, or **Admin**) to immediately test that specific perspective. You can also switch roles at any time from the app bar or Profile screen!

### 4. Running the Admin Web Dashboard
The Admin Dashboard runs locally with Vite on port 3000:
```bash
cd admin_dashboard
npm install
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) in your browser to inspect real-time operations, inventory edits, technician dispatch, and dealer KYC approvals.

---

## 💳 Razorpay Test Mode Integration

The payment flow is wired using `RazorpayService`:
1. Navigating through Cart (`CartScreen`) checks whether user is a Customer or Dealer.
2. If Dealer, the cart validates whether each item meets its `wholesaleMoq`.
3. At Checkout (`CheckoutScreen`), selecting **Razorpay Online Payment (Test Mode)** launches the test gateway.
4. The test gateway provides one-click simulation for **Payment Success** and **Bank Decline / Timeout Failure**.
5. On success, an `OrderModel` is minted with a genuine `pay_...` transaction ID and moves immediately to the fulfillment pipeline.

---

## 🔧 Service & Maintenance Booking Engine

Customers and dealers can schedule doorstep water purifier services:
- **Service Types**: New Installation, Filter/Membrane Replacement, TDS Check & Repair, Annual AMC Visit.
- **Preferred Slot**: Morning (9AM-1PM), Afternoon (1PM-5PM), Evening (5PM-8PM).
- **Technician Dispatch**: Admin dashboard allows assigning certified field technicians with their name, phone, and badge ID.

---

## 🤖 n8n AI Daily Instagram Automation

The file [`n8n_workflows/daily_instagram_post_workflow.json`](file:///d:/AquaCart/n8n_workflows/daily_instagram_post_workflow.json) automates daily water purifier marketing:
- **Trigger**: Daily cron at 9:00 AM IST (or webhook for manual test runs).
- **Theme Engine**: Rotates between TDS Health facts, Copper & Alkaline benefits, Monsoon filter care, and Dealer B2B recruitment.
- **OpenAI Node**: Generates high-converting copywriting with relevant hashtags.
- **DALL-E 3 Node**: Creates custom 1080x1080 graphics.
- **Meta Graph API**: Creates Instagram media container and publishes directly to the feed.

---

## 🛡️ Firestore Security Rules

Production-grade rules are defined in [`firebase/firestore.rules`](file:///d:/AquaCart/firebase/firestore.rules):
- **Products**: Public read; write restricted to users with `admin` role.
- **Orders**: Users can read and create their own orders; admins can inspect and update all orders.
- **Service Requests**: Users can create and read their tickets; admins manage technician assignments.
- **Dealer Applications**: Dealers submit KYC; admins hold exclusive approval authority.

---

## 🧪 Testing & Verification Checklist

- [x] **Role Switching**: 1-click switcher between Customer, Dealer, and Admin personas.
- [x] **Dealer Wholesale Pricing**: Wholesale prices and discount percentages reflect accurately.
- [x] **MOQ Validation**: Warning banner and checkout button gatekeeper for orders below MOQ.
- [x] **Razorpay Checkout**: Test checkout modal with simulated success and failure callbacks.
- [x] **Order Fulfillment**: Order placement, Razorpay payment ID persistence, step-by-step tracking timeline.
- [x] **Service Booking**: Date picker, time slot selector, technician assignment cards.
- [x] **Admin Operations**: Product addition modal, order status update, technician dispatch, dealer approval pipeline.
- [x] **n8n Workflow**: Valid JSON ready for import with all nodes and connections.
