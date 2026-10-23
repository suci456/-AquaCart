import React, { useState } from 'react';

// Seed initial state with realistic Califnco data
const initialProducts = [
  {
    id: 'prod-ro-01',
    title: 'AquaPure Alkaline RO+UV+UF+Copper 12L',
    category: 'RO Purifiers',
    retailPrice: 13499,
    wholesalePrice: 9450,
    wholesaleMoq: 5,
    stockQuantity: 120,
    status: 'In Stock',
  },
  {
    id: 'prod-ro-02',
    title: 'HydroShield Under-Sink Compact RO System',
    category: 'RO Purifiers',
    retailPrice: 17999,
    wholesalePrice: 12900,
    wholesaleMoq: 4,
    stockQuantity: 45,
    status: 'Low Stock',
  },
  {
    id: 'prod-comm-01',
    title: 'AquaCommercial 50 LPH SS RO Plant',
    category: 'Commercial Plants',
    retailPrice: 34999,
    wholesalePrice: 25500,
    wholesaleMoq: 2,
    stockQuantity: 28,
    status: 'In Stock',
  },
  {
    id: 'prod-filter-01',
    title: 'Complete 5-Stage Purifier Filter Kit',
    category: 'Filters & Spares',
    retailPrice: 1799,
    wholesalePrice: 1100,
    wholesaleMoq: 10,
    stockQuantity: 350,
    status: 'In Stock',
  },
  {
    id: 'prod-amc-01',
    title: '1-Year Comprehensive Domestic RO AMC',
    category: 'AMC Plans',
    retailPrice: 3499,
    wholesalePrice: 2499,
    wholesaleMoq: 5,
    stockQuantity: 999,
    status: 'Active',
  },
];

const initialOrders = [
  {
    id: 'ord-1001',
    orderNumber: 'AQ-2026-9041',
    customer: 'Rahul Sharma (Customer)',
    type: 'Retail',
    items: 'AquaPure Alkaline RO 12L (1 unit)',
    total: 15338,
    paymentMethod: 'Razorpay Test (pay_NzJ874k29LmOp)',
    status: 'Dispatched',
    date: '2026-10-21',
  },
  {
    id: 'ord-1002',
    orderNumber: 'AQ-2026-9042',
    customer: 'AquaTech Water Solutions Pvt Ltd',
    type: 'Wholesale B2B',
    items: 'AquaPure Alkaline (10 units), 5-Stage Filters (25 packs)',
    total: 143960,
    paymentMethod: '15-Day Dealer Credit',
    status: 'Confirmed',
    date: '2026-10-22',
  },
];

const initialServiceTickets = [
  {
    id: 'sr-201',
    ticketNumber: 'SR-1048',
    customer: 'Rahul Sharma',
    phone: '+91 98765 43210',
    type: 'New Installation',
    model: 'AquaPure Alkaline 12L RO',
    slot: 'Tomorrow, Morning (9AM-1PM)',
    technician: 'Suresh Kumar (+91 98450 11223)',
    status: 'Assigned',
  },
  {
    id: 'sr-202',
    ticketNumber: 'SR-1049',
    customer: 'Deepika Iyer',
    phone: '+91 97412 88990',
    type: 'Filter / Membrane Replacement',
    model: 'HydroShield Under-Sink RO',
    slot: 'Today, Evening (5PM-8PM)',
    technician: 'Unassigned',
    status: 'Pending Dispatch',
  },
];

const initialDealers = [
  {
    id: 'dlr-01',
    companyName: 'AquaTech Water Solutions Pvt Ltd',
    contactPerson: 'Vikram Patel',
    phone: '+91 98220 54321',
    email: 'dealer@aquatechsolutions.com',
    gstNumber: '29AABCU9603R1ZM',
    tradeLicense: 'TL-BLR-2024-8849',
    wholesaleTier: 'Gold Partner (35% Margin)',
    status: 'Approved',
  },
  {
    id: 'dlr-02',
    companyName: 'BlueDrop Enterprises & Plumbing',
    contactPerson: 'Karthik Raja',
    phone: '+91 94432 10987',
    email: 'sales@bluedropwater.in',
    gstNumber: '33AAACB1234F1ZQ',
    tradeLicense: 'TL-CHN-2025-1102',
    wholesaleTier: 'Silver Partner (25% Margin)',
    status: 'Pending Review',
  },
];

export default function App() {
  const [activeTab, setActiveTab] = useState('overview'); // overview, products, orders, service, dealers
  const [products, setProducts] = useState(initialProducts);
  const [orders, setOrders] = useState(initialOrders);
  const [serviceTickets, setServiceTickets] = useState(initialServiceTickets);
  const [dealers, setDealers] = useState(initialDealers);

  // New product form state
  const [showAddProductModal, setShowAddProductModal] = useState(false);
  const [newProd, setNewProd] = useState({
    title: '',
    category: 'RO Purifiers',
    retailPrice: '',
    wholesalePrice: '',
    wholesaleMoq: '5',
    stockQuantity: '50',
  });

  // Assign technician modal
  const [selectedTicketId, setSelectedTicketId] = useState(null);
  const [technicianName, setTechnicianName] = useState('Ramesh Gowda');
  const [technicianPhone, setTechnicianPhone] = useState('+91 98860 99887');

  const handleAddProduct = (e) => {
    e.preventDefault();
    if (!newProd.title || !newProd.retailPrice) return;
    const item = {
      id: `prod-${Date.now()}`,
      title: newProd.title,
      category: newProd.category,
      retailPrice: parseFloat(newProd.retailPrice),
      wholesalePrice: parseFloat(newProd.wholesalePrice || newProd.retailPrice * 0.7),
      wholesaleMoq: parseInt(newProd.wholesaleMoq || 5),
      stockQuantity: parseInt(newProd.stockQuantity || 50),
      status: 'In Stock',
    };
    setProducts([item, ...products]);
    setShowAddProductModal(false);
    setNewProd({ title: '', category: 'RO Purifiers', retailPrice: '', wholesalePrice: '', wholesaleMoq: '5', stockQuantity: '50' });
  };

  const handleUpdateOrderStatus = (orderId, newStatus) => {
    setOrders(orders.map((o) => (o.id === orderId ? { ...o, status: newStatus } : o)));
  };

  const handleApproveDealer = (dealerId, newStatus) => {
    setDealers(dealers.map((d) => (d.id === dealerId ? { ...d, status: newStatus } : d)));
  };

  const handleAssignTechnician = (e) => {
    e.preventDefault();
    setServiceTickets(
      serviceTickets.map((t) =>
        t.id === selectedTicketId
          ? { ...t, technician: `${technicianName} (${technicianPhone})`, status: 'Assigned' }
          : t
      )
    );
    setSelectedTicketId(null);
  };

  // Calculations for overview KPIs
  const totalRevenue = orders.reduce((sum, o) => sum + o.total, 0);
  const pendingServices = serviceTickets.filter((t) => t.status !== 'Completed').length;
  const pendingDealers = dealers.filter((d) => d.status === 'Pending Review').length;

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar */}
      <aside
        style={{
          width: '260px',
          backgroundColor: 'var(--bg-sidebar)',
          color: '#ffffff',
          padding: '24px 16px',
          display: 'flex',
          flexDirection: 'column',
          gap: '8px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '24px', paddingLeft: '8px' }}>
          <div
            style={{
              width: '38px',
              height: '38px',
              borderRadius: '10px',
              background: 'linear-gradient(135deg, #0284c7, #06b6d4)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '20px',
            }}
          >
            💧
          </div>
          <div>
            <div style={{ fontWeight: '900', fontSize: '18px', letterSpacing: '-0.3px' }}>AquaCart HQ</div>
            <div style={{ fontSize: '11px', color: '#94a3b8' }}>Admin Operations Dashboard</div>
          </div>
        </div>

        <div style={{ fontSize: '10px', fontWeight: '700', color: '#64748b', textTransform: 'uppercase', paddingLeft: '8px', marginBottom: '6px' }}>
          Management Modules
        </div>

        <SidebarBtn
          icon="📊"
          label="Operations Overview"
          active={activeTab === 'overview'}
          onClick={() => setActiveTab('overview')}
        />
        <SidebarBtn
          icon="💧"
          label="Products & Inventory"
          badge={`${products.length}`}
          active={activeTab === 'products'}
          onClick={() => setActiveTab('products')}
        />
        <SidebarBtn
          icon="📦"
          label="Orders & Fulfillment"
          badge={`${orders.length}`}
          active={activeTab === 'orders'}
          onClick={() => setActiveTab('orders')}
        />
        <SidebarBtn
          icon="🔧"
          label="Service & AMC Dispatch"
          badge={pendingServices > 0 ? `${pendingServices}` : null}
          badgeColor="var(--warning)"
          active={activeTab === 'service'}
          onClick={() => setActiveTab('service')}
        />
        <SidebarBtn
          icon="🏢"
          label="Dealer Verification"
          badge={pendingDealers > 0 ? `${pendingDealers} new` : null}
          badgeColor="var(--badge-dealer)"
          active={activeTab === 'dealers'}
          onClick={() => setActiveTab('dealers')}
        />

        <div style={{ marginTop: 'auto', padding: '14px', borderRadius: '12px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)' }}>
          <div style={{ fontSize: '11px', color: '#94a3b8' }}>Environment</div>
          <div style={{ fontSize: '13px', fontWeight: 'bold', color: '#38bdf8', marginTop: '2px' }}>Firebase + Razorpay Sandbox</div>
          <div style={{ fontSize: '11px', color: '#64748b', marginTop: '4px' }}>Role: Super Admin</div>
        </div>
      </aside>

      {/* Main Content Area */}
      <main style={{ flex: 1, padding: '32px 40px', overflowY: 'auto' }}>
        {/* Top Header */}
        <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '28px' }}>
          <div>
            <h1 style={{ fontSize: '24px', fontWeight: '900', color: 'var(--text-main)' }}>
              {activeTab === 'overview' && 'Operations & Sales Overview'}
              {activeTab === 'products' && 'Product Catalog & Inventory Management'}
              {activeTab === 'orders' && 'Fulfillment & Order Pipeline'}
              {activeTab === 'service' && 'Water Purifier Service & AMC Scheduling'}
              {activeTab === 'dealers' && 'B2B Dealer Applications & Wholesale KYC'}
            </h1>
            <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
              Real-time monitoring of residential water purifiers, B2B dealer wholesale orders, and field technicians.
            </p>
          </div>

          <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
            {activeTab === 'products' && (
              <button
                onClick={() => setShowAddProductModal(true)}
                style={{
                  backgroundColor: 'var(--primary)',
                  color: '#ffffff',
                  padding: '10px 18px',
                  borderRadius: '10px',
                  border: 'none',
                  fontWeight: '700',
                  fontSize: '13px',
                }}
              >
                + Add Water Purifier / Part
              </button>
            )}
            <div
              style={{
                padding: '8px 14px',
                backgroundColor: '#ffffff',
                border: '1px solid var(--border)',
                borderRadius: '8px',
                fontSize: '12px',
                fontWeight: '600',
              }}
            >
              📅 {new Date().toLocaleDateString('en-IN', { month: 'short', day: 'numeric', year: 'numeric' })}
            </div>
          </div>
        </header>

        {/* Tab 1: Overview */}
        {activeTab === 'overview' && (
          <div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '18px', marginBottom: '32px' }}>
              <KpiCard title="Total Platform Revenue" value={`₹${totalRevenue.toLocaleString('en-IN')}`} icon="💰" trend="+24.8% this week" color="#0284c7" />
              <KpiCard title="Active Bulk & Retail Orders" value={`${orders.length}`} icon="📦" trend="100% test payments verified" color="#0d9488" />
              <KpiCard title="Service Visits Pending" value={`${pendingServices}`} icon="🔧" trend="Doorstep SLA < 24h" color="#f59e0b" />
              <KpiCard title="Partner Dealers" value={`${dealers.length}`} icon="🏢" trend={`${pendingDealers} pending verification`} color="#d97706" />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px' }}>
              <div style={{ backgroundColor: '#ffffff', padding: '24px', borderRadius: '16px', border: '1px solid var(--border)' }}>
                <h3 style={{ fontSize: '16px', fontWeight: '800', marginBottom: '16px' }}>Recent Order Activity</h3>
                <OrdersTable orders={orders} onUpdateStatus={handleUpdateOrderStatus} />
              </div>

              <div style={{ backgroundColor: '#ffffff', padding: '24px', borderRadius: '16px', border: '1px solid var(--border)' }}>
                <h3 style={{ fontSize: '16px', fontWeight: '800', marginBottom: '16px' }}>Service Technician Queue</h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  {serviceTickets.map((t) => (
                    <div key={t.id} style={{ padding: '12px', borderRadius: '10px', backgroundColor: 'var(--bg-main)', border: '1px solid var(--border)' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: 'bold' }}>
                        <span>{t.ticketNumber} - {t.type}</span>
                        <span style={{ color: t.status === 'Assigned' ? 'var(--success)' : 'var(--warning)' }}>{t.status}</span>
                      </div>
                      <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px' }}>{t.customer} • {t.model}</div>
                      <div style={{ fontSize: '11px', color: 'var(--primary)', marginTop: '4px' }}>👤 Tech: {t.technician}</div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Tab 2: Products */}
        {activeTab === 'products' && (
          <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid var(--border)', overflow: 'hidden' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead style={{ backgroundColor: 'var(--bg-main)', borderBottom: '1px solid var(--border)', fontWeight: '700', color: 'var(--text-muted)' }}>
                <tr>
                  <th style={{ padding: '14px 18px' }}>Product Title & Category</th>
                  <th style={{ padding: '14px 18px' }}>Retail Price (MRP)</th>
                  <th style={{ padding: '14px 18px' }}>Dealer Wholesale Price</th>
                  <th style={{ padding: '14px 18px' }}>Wholesale MOQ</th>
                  <th style={{ padding: '14px 18px' }}>Stock Qty</th>
                  <th style={{ padding: '14px 18px' }}>Inventory Status</th>
                </tr>
              </thead>
              <tbody>
                {products.map((p) => (
                  <tr key={p.id} style={{ borderBottom: '1px solid var(--border)' }}>
                    <td style={{ padding: '14px 18px' }}>
                      <div style={{ fontWeight: '700', color: 'var(--text-main)' }}>{p.title}</div>
                      <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{p.category}</div>
                    </td>
                    <td style={{ padding: '14px 18px', fontWeight: '700', color: 'var(--primary)' }}>₹{p.retailPrice.toLocaleString('en-IN')}</td>
                    <td style={{ padding: '14px 18px', fontWeight: '700', color: 'var(--badge-dealer)' }}>₹{p.wholesalePrice.toLocaleString('en-IN')}</td>
                    <td style={{ padding: '14px 18px', fontWeight: '600' }}>{p.wholesaleMoq} units</td>
                    <td style={{ padding: '14px 18px', fontWeight: 'bold' }}>{p.stockQuantity}</td>
                    <td style={{ padding: '14px 18px' }}>
                      <span
                        style={{
                          padding: '4px 8px',
                          borderRadius: '6px',
                          fontSize: '11px',
                          fontWeight: '700',
                          backgroundColor: p.status === 'In Stock' ? '#dcfce7' : '#fef3c7',
                          color: p.status === 'In Stock' ? '#166534' : '#92400e',
                        }}
                      >
                        {p.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Tab 3: Orders */}
        {activeTab === 'orders' && (
          <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid var(--border)', padding: '24px' }}>
            <OrdersTable orders={orders} onUpdateStatus={handleUpdateOrderStatus} showActions />
          </div>
        )}

        {/* Tab 4: Service */}
        {activeTab === 'service' && (
          <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid var(--border)', padding: '24px' }}>
            <h3 style={{ fontSize: '16px', fontWeight: '800', marginBottom: '16px' }}>Service Request Dispatch Queue</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              {serviceTickets.map((t) => (
                <div key={t.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '18px', border: '1px solid var(--border)', borderRadius: '12px' }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span style={{ fontWeight: '800', color: 'var(--primary)' }}>{t.ticketNumber}</span>
                      <span style={{ fontSize: '11px', padding: '3px 8px', borderRadius: '6px', backgroundColor: '#e0f2fe', color: '#0369a1', fontWeight: '700' }}>
                        {t.type}
                      </span>
                    </div>
                    <div style={{ fontWeight: '700', fontSize: '14px', marginTop: '6px' }}>{t.customer} ({t.phone})</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '2px' }}>Purifier: {t.model} • Slot: {t.slot}</div>
                    <div style={{ fontSize: '12px', color: 'var(--secondary)', marginTop: '4px', fontWeight: '600' }}>
                      🔧 Assigned Technician: {t.technician}
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button
                      onClick={() => setSelectedTicketId(t.id)}
                      style={{
                        padding: '8px 14px',
                        backgroundColor: 'var(--primary)',
                        color: '#ffffff',
                        border: 'none',
                        borderRadius: '8px',
                        fontWeight: '700',
                        fontSize: '12px',
                      }}
                    >
                      Assign Technician
                    </button>
                    {t.status !== 'Completed' && (
                      <button
                        onClick={() =>
                          setServiceTickets(serviceTickets.map((st) => (st.id === t.id ? { ...st, status: 'Completed' } : st)))
                        }
                        style={{
                          padding: '8px 14px',
                          backgroundColor: '#22c55e',
                          color: '#ffffff',
                          border: 'none',
                          borderRadius: '8px',
                          fontWeight: '700',
                          fontSize: '12px',
                        }}
                      >
                        Mark Completed
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Tab 5: Dealers */}
        {activeTab === 'dealers' && (
          <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid var(--border)', padding: '24px' }}>
            <h3 style={{ fontSize: '16px', fontWeight: '800', marginBottom: '16px' }}>Dealer B2B Partners & KYC Pipeline</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {dealers.map((d) => (
                <div key={d.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '18px', border: '1px solid var(--border)', borderRadius: '12px' }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span style={{ fontWeight: '800', fontSize: '15px' }}>{d.companyName}</span>
                      <span
                        style={{
                          padding: '3px 8px',
                          borderRadius: '6px',
                          fontSize: '11px',
                          fontWeight: 'bold',
                          backgroundColor: d.status === 'Approved' ? '#dcfce7' : '#fef3c7',
                          color: d.status === 'Approved' ? '#166534' : '#92400e',
                        }}
                      >
                        {d.status}
                      </span>
                    </div>
                    <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
                      Contact: {d.contactPerson} • {d.phone} • {d.email}
                    </div>
                    <div style={{ fontSize: '12px', fontWeight: '600', marginTop: '6px' }}>
                      GSTIN: <span style={{ color: 'var(--primary)' }}>{d.gstNumber}</span> • Trade License: {d.tradeLicense} • Tier: {d.wholesaleTier}
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '8px' }}>
                    {d.status !== 'Approved' && (
                      <button
                        onClick={() => handleApproveDealer(d.id, 'Approved')}
                        style={{
                          padding: '8px 14px',
                          backgroundColor: 'var(--success)',
                          color: '#ffffff',
                          border: 'none',
                          borderRadius: '8px',
                          fontWeight: '700',
                          fontSize: '12px',
                        }}
                      >
                        Approve Wholesale Account
                      </button>
                    )}
                    {d.status === 'Approved' && (
                      <button
                        onClick={() => handleApproveDealer(d.id, 'Suspended')}
                        style={{
                          padding: '8px 14px',
                          backgroundColor: '#fee2e2',
                          color: '#991b1b',
                          border: 'none',
                          borderRadius: '8px',
                          fontWeight: '700',
                          fontSize: '12px',
                        }}
                      >
                        Suspend Partner
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Modal: Add New Product */}
        {showAddProductModal && (
          <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 }}>
            <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', padding: '24px', width: '480px', maxWidth: '90%' }}>
              <h3 style={{ fontSize: '18px', fontWeight: '800', marginBottom: '16px' }}>Add Water Purifier or Spare Part</h3>
              <form onSubmit={handleAddProduct} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <input
                  type="text"
                  placeholder="Purifier / Filter Title"
                  value={newProd.title}
                  onChange={(e) => setNewProd({ ...newProd, title: e.target.value })}
                  style={{ padding: '10px 14px', borderRadius: '8px', border: '1px solid var(--border)' }}
                  required
                />
                <select
                  value={newProd.category}
                  onChange={(e) => setNewProd({ ...newProd, category: e.target.value })}
                  style={{ padding: '10px 14px', borderRadius: '8px', border: '1px solid var(--border)' }}
                >
                  <option>RO Purifiers</option>
                  <option>Commercial Plants</option>
                  <option>Filters & Spares</option>
                  <option>AMC Plans</option>
                </select>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                  <input
                    type="number"
                    placeholder="Retail Price (₹)"
                    value={newProd.retailPrice}
                    onChange={(e) => setNewProd({ ...newProd, retailPrice: e.target.value })}
                    style={{ padding: '10px 14px', borderRadius: '8px', border: '1px solid var(--border)' }}
                    required
                  />
                  <input
                    type="number"
                    placeholder="Dealer Wholesale (₹)"
                    value={newProd.wholesalePrice}
                    onChange={(e) => setNewProd({ ...newProd, wholesalePrice: e.target.value })}
                    style={{ padding: '10px 14px', borderRadius: '8px', border: '1px solid var(--border)' }}
                    required
                  />
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                  <input
                    type="number"
                    placeholder="Wholesale MOQ"
                    value={newProd.wholesaleMoq}
                    onChange={(e) => setNewProd({ ...newProd, wholesaleMoq: e.target.value })}
                    style={{ padding: '10px 14px', borderRadius: '8px', border: '1px solid var(--border)' }}
                    required
                  />
                  <input
                    type="number"
                    placeholder="Initial Stock Qty"
                    value={newProd.stockQuantity}
                    onChange={(e) => setNewProd({ ...newProd, stockQuantity: e.target.value })}
                    style={{ padding: '10px 14px', borderRadius: '8px', border: '1px solid var(--border)' }}
                    required
                  />
                </div>
                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '14px' }}>
                  <button
                    type="button"
                    onClick={() => setShowAddProductModal(false)}
                    style={{ padding: '10px 16px', borderRadius: '8px', border: '1px solid var(--border)', background: '#fff' }}
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    style={{ padding: '10px 18px', borderRadius: '8px', border: 'none', background: 'var(--primary)', color: '#fff', fontWeight: 'bold' }}
                  >
                    Save Product
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Modal: Assign Technician */}
        {selectedTicketId && (
          <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 }}>
            <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', padding: '24px', width: '420px', maxWidth: '90%' }}>
              <h3 style={{ fontSize: '18px', fontWeight: '800', marginBottom: '14px' }}>Assign Service Field Technician</h3>
              <form onSubmit={handleAssignTechnician} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <label style={{ fontSize: '12px', fontWeight: '600' }}>Technician Name</label>
                <input
                  type="text"
                  value={technicianName}
                  onChange={(e) => setTechnicianName(e.target.value)}
                  style={{ padding: '10px 14px', borderRadius: '8px', border: '1px solid var(--border)' }}
                  required
                />
                <label style={{ fontSize: '12px', fontWeight: '600' }}>Contact Phone</label>
                <input
                  type="text"
                  value={technicianPhone}
                  onChange={(e) => setTechnicianPhone(e.target.value)}
                  style={{ padding: '10px 14px', borderRadius: '8px', border: '1px solid var(--border)' }}
                  required
                />
                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '14px' }}>
                  <button
                    type="button"
                    onClick={() => setSelectedTicketId(null)}
                    style={{ padding: '10px 16px', borderRadius: '8px', border: '1px solid var(--border)', background: '#fff' }}
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    style={{ padding: '10px 18px', borderRadius: '8px', border: 'none', background: 'var(--primary)', color: '#fff', fontWeight: 'bold' }}
                  >
                    Confirm Dispatch
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

function SidebarBtn({ icon, label, badge, badgeColor, active, onClick }) {
  return (
    <button
      onClick={onClick}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '10px',
        width: '100%',
        padding: '12px 14px',
        borderRadius: '10px',
        border: 'none',
        backgroundColor: active ? 'var(--primary)' : 'transparent',
        color: active ? '#ffffff' : '#94a3b8',
        fontWeight: active ? '700' : '500',
        fontSize: '13px',
        textAlign: 'left',
        transition: 'all 0.15s ease',
      }}
    >
      <span style={{ fontSize: '16px' }}>{icon}</span>
      <span style={{ flex: 1 }}>{label}</span>
      {badge && (
        <span
          style={{
            padding: '2px 8px',
            borderRadius: '10px',
            fontSize: '10px',
            fontWeight: 'bold',
            backgroundColor: badgeColor || '#38bdf8',
            color: '#ffffff',
          }}
        >
          {badge}
        </span>
      )}
    </button>
  );
}

function KpiCard({ title, value, icon, trend, color }) {
  return (
    <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '16px', border: '1px solid var(--border)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-muted)' }}>{title}</span>
        <span style={{ fontSize: '20px' }}>{icon}</span>
      </div>
      <div style={{ fontSize: '24px', fontWeight: '900', color: color, marginTop: '8px' }}>{value}</div>
      <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}>{trend}</div>
    </div>
  );
}

function OrdersTable({ orders, onUpdateStatus, showActions = false }) {
  return (
    <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
      <thead style={{ borderBottom: '1px solid var(--border)', fontWeight: '700', color: 'var(--text-muted)' }}>
        <tr>
          <th style={{ padding: '10px 14px' }}>Order Ref</th>
          <th style={{ padding: '10px 14px' }}>Customer / Dealer</th>
          <th style={{ padding: '10px 14px' }}>Items</th>
          <th style={{ padding: '10px 14px' }}>Amount</th>
          <th style={{ padding: '10px 14px' }}>Status</th>
          {showActions && <th style={{ padding: '10px 14px' }}>Update Status</th>}
        </tr>
      </thead>
      <tbody>
        {orders.map((o) => (
          <tr key={o.id} style={{ borderBottom: '1px solid var(--border)' }}>
            <td style={{ padding: '12px 14px', fontWeight: 'bold', color: 'var(--primary)' }}>{o.orderNumber}</td>
            <td style={{ padding: '12px 14px' }}>
              <div style={{ fontWeight: '600' }}>{o.customer}</div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{o.type}</div>
            </td>
            <td style={{ padding: '12px 14px', maxWidth: '240px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {o.items}
            </td>
            <td style={{ padding: '12px 14px', fontWeight: 'bold' }}>₹{o.total.toLocaleString('en-IN')}</td>
            <td style={{ padding: '12px 14px' }}>
              <span
                style={{
                  padding: '4px 8px',
                  borderRadius: '6px',
                  fontSize: '11px',
                  fontWeight: 'bold',
                  backgroundColor: o.status === 'Dispatched' ? '#fef3c7' : '#dcfce7',
                  color: o.status === 'Dispatched' ? '#92400e' : '#166534',
                }}
              >
                {o.status}
              </span>
            </td>
            {showActions && (
              <td style={{ padding: '12px 14px' }}>
                <select
                  value={o.status}
                  onChange={(e) => onUpdateStatus(o.id, e.target.value)}
                  style={{ padding: '4px 8px', borderRadius: '6px', border: '1px solid var(--border)', fontSize: '12px' }}
                >
                  <option>Placed</option>
                  <option>Confirmed</option>
                  <option>Dispatched</option>
                  <option>Delivered</option>
                  <option>Cancelled</option>
                </select>
              </td>
            )}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
