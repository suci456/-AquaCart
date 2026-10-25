# AquaCart (Califnco) — Complete End-to-End System Workflow

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                               AquaCart Ecosystem                                 │
├───────────────────────┬─────────────────────────┬────────────────────────────────┤
│  Flutter Mobile App   │   Admin Web Dashboard   │      Automations & Cloud       │
│  (Customer & Dealer)  │     (React + Vite)      │    (Firebase, Razorpay, n8n)   │
└───────────────────────┴─────────────────────────┴────────────────────────────────┘
```

---

## 1. System Architecture Overview

AquaCart is an enterprise-grade water purification commerce and service platform operating across three primary user roles, an administrative command center, and cloud automation:

```mermaid
graph TD
    subgraph MobileApp ["AquaCart Flutter App"]
        Customer[Customer Retail]
        Dealer[Dealer B2B]
        TechService[Service Booking]
    end

    subgraph Backend ["Backend & Cloud Infrastructure"]
        Auth[Firebase Auth / Role System]
        Firestore[Cloud Firestore DB + RBAC Rules]
        Razorpay[Razorpay Payment Gateway]
        FCM[Firebase Cloud Messaging]
    end

    subgraph AdminPortal ["Admin Web Dashboard (Port 4173)"]
        AdminUI[Califnco Operations Control]
        OrderMgmt[Order Fulfillment]
        DealerReview[Dealer Approvals]
        ServiceDispatch[Technician Dispatch]
    end

    subgraph Automation ["n8n Workflow Engine"]
        Sheets[Google Sheets Catalog]
        GenAI[Gemini / Groq AI]
        InstaAPI[Instagram Graph API]
    end

    Customer -->|Places Order / Books Service| Auth
    Dealer -->|Bulk Orders / Registration| Auth
    Auth --> Firestore
    Customer -->|Checkout| Razorpay
    Razorpay -->|Signature Verification| Firestore
    Firestore -->|Status Triggers| FCM
    FCM -->|Push Notifications| Customer
    AdminUI -->|Manage & Approve| Firestore
    Sheets --> GenAI --> InstaAPI
```

---

## 2. Customer Retail Workflow

```mermaid
sequenceDiagram
    autonumber
    actor C as Customer
    participant App as Mobile App
    participant Pay as Razorpay Gateway
    participant FS as Firestore / Backend
    participant FCM as Push Notifications

    C->>App: 1. Launch App & Browse Catalog
    Note over App: Displays local AI assets + CDN product images
    C->>App: 2. View Product Details & Add to Cart
    C->>App: 3. Select Delivery Address (Map Picker)
    C->>App: 4. Initiate Checkout
    App->>FS: 5. Verify prices server-side (Tamper Guard)
    FS-->>App: Order token & verified amount
    App->>Pay: 6. Open Razorpay Checkout Sheet
    Pay-->>App: Payment Success (PaymentId, Signature)
    App->>FS: 7. Validate Signature & Create Order
    FS->>FCM: 8. Trigger "Order Placed" Notification
    FCM-->>C: Push: "Your AquaCart order is confirmed!"
    C->>App: 9. Track live progress in OrderTrackingScreen
```

### Step-by-Step Customer Journey:
1. **Catalog Exploration**:
   - Customer opens AquaCart and sees featured RO purifiers with high-definition visuals.
   - Products are categorized: Domestic RO, Commercial Plants, Filters & Membranes, Spare Parts.
2. **Product Detail View**:
   - Full technical specifications (purification capacity, stages, TDS range, recovery rate).
   - Price calculation, warranty terms, and stock status.
3. **Cart & MOQ Check**:
   - Customer adds units to cart. Retail orders have a Minimum Order Quantity (MOQ) of 1.
4. **Address & Delivery**:
   - Integration with Google Maps / GPS address picker to ensure accurate pin locations.
5. **Secure Payment (Razorpay Test Mode)**:
   - Client requests order creation.
   - Prices are recalculated from trusted catalog data (preventing client-side price tampering).
   - Razorpay sheet handles card, UPI, or net banking in test mode.
   - Cryptographic signature (`hmac_sha256`) is verified before order status is marked as `PAID`.
6. **Live Order Tracking**:
   - Customer monitors order stages: `Placed` ➔ `Confirmed` ➔ `Dispatched` ➔ `Delivered`.

---

## 3. Dealer B2B Wholesale Workflow

```mermaid
sequenceDiagram
    autonumber
    actor D as Dealer
    participant App as Mobile App
    participant FS as Firestore
    actor A as Califnco Admin

    D->>App: 1. Register with Business Info & GSTIN
    App->>FS: 2. Store Application (status: PENDING)
    Note over App: Wholesale pricing locked until approval
    A->>FS: 3. Admin verifies GSTIN & Approves Dealer
    FS-->>App: 4. Account upgraded (status: APPROVED)
    D->>App: 5. Wholesale Mode Activated
    Note over App: Wholesale margins & MOQs visible
    D->>App: 6. Multi-SKU Bulk Order Matrix
    D->>App: 7. Place Wholesale Order (Credit / Net-30)
    App->>FS: 8. Persist Order with DealerId & Tier
```

### Step-by-Step Dealer Journey:
1. **Dealer Onboarding**:
   - Dealer submits company name, trade license, GST number, and delivery hub address.
   - Initial status is `Pending`. During this phase, wholesale discounts cannot be claimed.
2. **Admin Verification**:
   - Califnco operations team reviews the application in the Web Dashboard and sets tier (`Silver`, `Gold`, `Platinum`).
3. **Wholesale Catalog Access**:
   - Once approved, the app displays discounted wholesale pricing (e.g. ₹9,450 vs ₹13,499 retail).
   - Each product enforces a wholesale Minimum Order Quantity (MOQ, e.g., 5 or 20 units).
4. **Bulk Order Matrix (`DealerBulkOrderScreen`)**:
   - Fast multi-SKU table where dealers select quantities across multiple filters and purifiers simultaneously.
   - Automatic live calculation of wholesale subtotal, 18% GST input tax credit, and volume margins.
5. **Dealer Order Isolation**:
   - Firestore security rules strictly constrain dealers to view *only* their own wholesale orders and authorized dealer tier pricing.

---

## 4. Service & Installation Workflow

```mermaid
sequenceDiagram
    autonumber
    actor C as Customer
    participant App as Mobile App
    participant FS as Firestore
    actor A as Admin
    actor T as Field Technician

    C->>App: 1. Select Service Type (Installation / Repair / Filter Change / AMC)
    C->>App: 2. Pick Preferred Date & Time Slot
    C->>App: 3. Select Service Address
    App->>FS: 4. Create Service Request (status: PENDING)
    A->>FS: 5. Assign Field Technician
    FS->>App: 6. Push notification to Customer
    T->>C: 7. Technician visits & completes job
    A->>FS: 8. Mark service as COMPLETED
```

### Service Categories:
- **New Purifier Installation**: Complimentary for new AquaCart buyers.
- **Filter & Membrane Replacement**: Scheduled based on TDS reading or calendar alert.
- **Emergency Repair & Leakage**: Priority technician dispatch within 4 hours.
- **Annual Maintenance Contract (AMC)**: Year-round coverage including 3 scheduled cleanings and membrane replacements.

---

## 5. Califnco Admin Web Operations Workflow

The Admin Dashboard runs as an independent web application at **`http://localhost:4173`**:

```
┌────────────────────────────────────────────────────────────────────────┐
│                      CALIFNCO ADMIN CONTROL PANEL                      │
├───────────────┬───────────────────┬─────────────────┬──────────────────┤
│ Total Revenue │  Customer Orders  │ Dealer Orders   │ Pending Approvals│
│  ₹ 4,82,500   │      124 Active   │    38 Bulk      │    4 New Dealers │
└───────────────┴───────────────────┴─────────────────┴──────────────────┘
```

### Core Operations in Admin Portal:
1. **Order Fulfillment Tab**:
   - View complete item breakdown with thumbnail product pictures.
   - Filter by customer retail vs dealer wholesale.
   - Update order status: Click to advance `Placed` ➔ `Confirmed` ➔ `Dispatched` ➔ `Delivered`.
2. **Dealer Application Tab**:
   - Review pending dealership applications with GSTIN and business credentials.
   - One-click **Approve** or **Reject** with tier assignment.
3. **Service Dispatch Tab**:
   - View requested services sorted by appointment date.
   - Assign local field technicians and record service completion.
4. **Inventory & SKU Catalog**:
   - View stock levels, retail pricing, wholesale pricing, and MOQs.

---

## 6. Daily Social Media Automation (n8n Workflow)

The automated marketing engine runs daily without manual intervention:

```mermaid
flowchart LR
    Cron[Schedule: Daily 9 AM] --> ReadSheet[Read Unposted SKU from Google Sheets]
    ReadSheet --> AI[Gemini / Groq Generates Caption & Hashtags]
    AI --> ImgHost[Cloudinary / ImgBB Generates Public CDN URL]
    ImgHost --> MetaAPI[Meta Graph API Creates Media Container]
    MetaAPI --> Publish[Publish to Instagram Feed]
    Publish --> WriteBack[Update Google Sheets: Posted=TRUE & MediaID]
```

1. **Trigger**: Runs every morning at 9:00 AM IST.
2. **Filter**: Searches the product catalog for items where `Posted == FALSE`.
3. **AI Content Generation**: Generates high-converting marketing copy highlighting water health, TDS reduction, and current offers.
4. **Publishing**: Sends product image and caption to the official Instagram Business Account.
5. **Audit Logging**: Marks the row as published with post timestamp and Instagram Media ID to guarantee zero duplicates.

---

## 7. Security & Integrity Safeguards

| Component | Security Mechanism |
|---|---|
| **Pricing** | Server-side price recalculation guards against client-side tampering |
| **Payments** | Razorpay cryptographic HMAC SHA-256 signature verification |
| **Wholesale Access** | Dual-layer check: UI blocks non-approved users AND Firestore rules reject unauthorized wholesale orders |
| **Database** | Granular Firestore Security Rules restricting read/write access per role (`customer`, `dealer`, `admin`) |
| **Asset Delivery** | Tiered fallback (Local offline assets ➔ Cloudflare/Unsplash CDN ➔ Branded SVG/Vector icon) |
