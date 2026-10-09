<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.azurahouse.dao.*, com.azurahouse.model.*, java.util.*, java.text.SimpleDateFormat, java.io.File" %>
<%
    String path = application.getRealPath("/");

    // --- ADMIN ACTIONS: CLEAR ORDERS & TRANSACTIONS ---
    String adminAction = request.getParameter("adminAction");
    if ("clearAllOrders".equals(adminAction)) {
        File ordersFile = new File(path + File.separator + "data" + File.separator + "orders.json");
        if (ordersFile.exists()) ordersFile.delete();
        response.sendRedirect("dashboard.jsp");
        return;
    } else if ("resetTransactions".equals(adminAction)) {
        File transFile = new File(path + File.separator + "data" + File.separator + "transactions.json");
        if (transFile.exists()) transFile.delete();
        response.sendRedirect("dashboard.jsp");
        return;
    }

    List<StockItem> stock = new InventoryDAO().getAll(path);
    List<MenuItem> menu = new MenuDAO().getAll(path);
    List<Order> allOrders = new OrderDAO().getAll(path);
    List<Transaction> transactions = new TransactionDAO().getAll(path);
    List<RecipeItem> recipes = new RecipeDAO().getAll(path);
    
    // --- 1. REVENUE & CHART LOGIC ---
    double dailyRevenue = 0;
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    String today = sdf.format(new Date());
    
    Map<String, Double> chartData = new LinkedHashMap<>();
    for(int i = 6; i >= 0; i--) {
        Calendar cal = Calendar.getInstance();
        cal.add(Calendar.DATE, -i);
        chartData.put(sdf.format(cal.getTime()), 0.0);
    }

    if(transactions != null) {
        for(Transaction t : transactions) {
            if(t != null && t.getTimestamp() != null) {
                String dateKey = t.getTimestamp().substring(0, 10);
                if(dateKey.equals(today)) dailyRevenue += t.getAmount();
                if(chartData.containsKey(dateKey)) {
                    chartData.put(dateKey, chartData.get(dateKey) + t.getAmount());
                }
            }
        }
    }

    StringBuilder labels = new StringBuilder("[");
    StringBuilder values = new StringBuilder("[");
    for (Map.Entry<String, Double> entry : chartData.entrySet()) {
        labels.append("'").append(entry.getKey()).append("',");
        values.append(entry.getValue()).append(",");
    }
    if(!chartData.isEmpty()) {
        labels.setLength(labels.length() - 1);
        values.setLength(values.length() - 1);
    }
    labels.append("]");
    values.append("]");

    List<Order> activeOrders = new ArrayList<>();
    List<Order> completedOrders = new ArrayList<>();
    if(allOrders != null) {
        for(Order o : allOrders) {
            if(o.status != null && "Completed".equalsIgnoreCase(o.status)) completedOrders.add(o);
            else activeOrders.add(o);
        }
    }

    List<StockItem> lowStockItems = new ArrayList<>();
    if(stock != null) {
        for(StockItem s : stock) {
            if(s.getQuantity() < 5.0) lowStockItems.add(s);
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azura House - Owner Dashboard</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="static/css/style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        .search-input { border-radius: 20px; padding-left: 15px; font-size: 0.85rem; }
        .alert-low-stock { border-left: 5px solid #dc3545; background-color: #fff5f5; }
        .chart-container { height: 180px; width: 100%; position: relative; }
        .btn-report { background-color: #f8f9fa; border: 1px solid #ddd; font-size: 0.75rem; color: #555; }
        .takeout-badge { background-color: #6f42c1; color: white; font-size: 0.65rem; padding: 2px 8px; border-radius: 50px; }
    </style>
</head>
<body class="bg-light">
    <div class="container py-4">
        
        <div class="row mb-4 g-3">
            <div class="col-md-4">
                <div class="bg-white p-3 shadow-sm rounded h-100 text-center">
                    <img src="static/images/logo.png" style="width: 50px;" class="mb-2">
                    <span class="text-muted small d-block">Today's Revenue</span>
                    <h3 class="text-success fw-bold m-0">RM <%= String.format("%.2f", dailyRevenue) %></h3>
                    <div class="d-flex justify-content-center flex-wrap gap-2 mt-2">
                        <button class="btn btn-sm btn-outline-secondary" data-bs-toggle="modal" data-bs-target="#historyModal">📜 History</button>
                        <button id="downloadReportBtn" class="btn btn-sm btn-report">📥 Report</button>
                        <div class="w-100 mt-1 d-flex justify-content-center gap-1">
                            <a href="dashboard.jsp?adminAction=clearAllOrders" class="btn btn-sm btn-outline-danger" style="font-size: 0.7rem;" onclick="return confirm('Delete ALL orders?')">🗑️ Orders</a>
                            <a href="dashboard.jsp?adminAction=resetTransactions" class="btn btn-sm btn-outline-danger" style="font-size: 0.7rem;" onclick="return confirm('Reset Sales/Chart?')">📊 Sales</a>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-8">
                <div class="bg-white p-3 shadow-sm rounded h-100">
                    <h6 class="fw-bold mb-2 small">7-Day Revenue Trend</h6>
                    <div class="chart-container">
                        <canvas id="revenueChart"></canvas>
                    </div>
                </div>
            </div>
        </div>

        <% if(!lowStockItems.isEmpty()) { %>
        <div class="alert alert-low-stock shadow-sm mb-4">
            <h6 class="text-danger fw-bold mb-1 small">⚠️ Low Stock Warning</h6>
            <div class="d-flex flex-wrap gap-1">
                <% for(StockItem ls : lowStockItems) { %>
                    <span class="badge bg-danger" style="font-size: 0.7rem;"><%= ls.getItemName() %> (<%= String.format("%.2f", ls.getQuantity()) %> left)</span>
                <% } %>
            </div>
        </div>
        <% } %>

        <h5 class="fw-bold mb-3">🍳 Kitchen Queue</h5>
        <div class="row mb-4" id="kitchen-queue-row">
            <% if(!activeOrders.isEmpty()) { for(Order o : activeOrders) { 
                boolean isPaid = "Paid".equalsIgnoreCase(o.status);
                boolean isPartial = "Partially Paid".equalsIgnoreCase(o.status);
                boolean isTakeout = (o.type != null && "Takeout".equalsIgnoreCase(o.type));
                
                boolean showPayButton = !isPaid;
                boolean showDoneButton = isTakeout || isPaid;

                String borderClass = isPaid ? "border-success" : (isPartial ? "border-info" : "border-warning");
                List<String> priceStrs = new ArrayList<>();
                if(o.itemPrices != null) { for(Double p : o.itemPrices) priceStrs.add(String.format("%.2f", p)); }
            %>
                <div class="col-md-3 mb-2">
                    <div class="card card-body border-0 shadow-sm border-start border-4 <%= borderClass %>">
                        <div class="d-flex justify-content-between align-items-start">
                            <div>
                                <span class="fw-bold d-block text-dark"><%= isTakeout ? "🥡 Takeout" : "Table " + o.tableNumber %></span>
                                <span class="text-success fw-bold" style="font-size: 0.8rem;">RM <%= String.format("%.2f", o.totalPrice) %></span>
                            </div>
                            <div class="d-flex gap-1">
                                <% if(showPayButton) { %>
                                <button class="btn btn-sm btn-outline-success py-0 px-2" 
                                        onclick="openCounterPayment('<%= o.orderId %>', '<%= String.join("|", o.items) %>', '<%= String.join("|", priceStrs) %>', <%= isTakeout %>)">Pay</button>
                                <% } %>
                                <% if(showDoneButton) { %>
                                <form action="MenuManagementServlet" method="POST" class="m-0">
                                    <input type="hidden" name="action" value="completeOrder">
                                    <input type="hidden" name="orderId" value="<%= o.orderId %>">
                                    <button type="submit" class="btn btn-sm btn-success py-0 px-2 fw-bold">Done</button>
                                </form>
                                <% } %>
                            </div>
                        </div>
                        <hr class="my-2 opacity-25">
                        <small class="text-dark" style="font-size: 0.75rem; min-height: 30px; display: block;">
                            <%= (o.items != null && !o.items.isEmpty()) ? String.join(", ", o.items) : "Empty Order" %>
                        </small>
                        <div class="mt-2 d-flex justify-content-between align-items-center">
                             <div class="d-flex gap-1 align-items-center">
                                <span class="badge bg-light text-dark border" style="font-size: 0.6rem;"><%= o.status %></span>
                                <% if(isTakeout) { %><span class="takeout-badge">TAKEOUT</span><% } %>
                             </div>
                        </div>
                    </div>
                </div>
            <% } } else { %><p class="text-muted small ms-2">All caught up!</p><% } %>
        </div>

        <div class="d-flex justify-content-between align-items-center mb-2">
            <h5 class="fw-bold m-0 text-dark">📦 Inventory</h5>
            <div class="d-flex gap-2">
                <input type="text" id="inventorySearch" class="form-control form-control-sm search-input" placeholder="Search...">
                <button class="btn btn-sm btn-dark" data-bs-toggle="collapse" data-bs-target="#stockForm">+</button>
            </div>
        </div>
        
        <div class="collapse mb-3" id="stockForm">
            <form action="InventoryServlet" method="POST" class="card card-body border-0 shadow-sm row g-2 flex-row">
                <input type="hidden" name="action" value="create">
                <div class="col-md-5"><input type="text" name="itemName" class="form-control form-control-sm" placeholder="Item Name" required></div>
                <div class="col-md-2"><input type="number" step="0.001" name="quantity" class="form-control form-control-sm" placeholder="Qty" required></div>
                <div class="col-md-3"><input type="number" step="0.01" name="price" class="form-control form-control-sm" placeholder="RM" required></div>
                <div class="col-md-2"><button type="submit" class="btn btn-sm btn-primary w-100">Add</button></div>
            </form>
        </div>

        <div class="card border-0 shadow-sm mb-5 overflow-hidden">
            <table class="table table-sm align-middle mb-0" id="inventoryTable">
                <thead class="table-light"><tr><th class="ps-3 text-dark">Item</th><th class="text-dark">Qty</th><th class="text-center text-dark">Action</th></tr></thead>
                <tbody>
                    <% if(stock != null) { for(StockItem s : stock) { %>
                    <tr class="searchable-row">
                        <td class="ps-3 item-name text-dark"><%= s.getItemName() %> <% if(s.getQuantity() < 5) { %><small class="text-danger ms-2 fw-bold">LOW</small><% } %></td>
                        <td>
                            <form action="InventoryServlet" method="POST" class="d-flex">
                                <input type="hidden" name="action" value="update"><input type="hidden" name="stockId" value="<%= s.getStockId() %>">
                                <input type="number" step="0.001" name="quantity" value="<%= s.getQuantity() %>" class="form-control form-control-sm me-1" style="width:75px;">
                                <button type="submit" class="btn btn-sm text-primary p-0">Set</button>
                            </form>
                        </td>
                        <td class="text-center">
                            <form action="InventoryServlet" method="POST">
                                <input type="hidden" name="action" value="delete"><input type="hidden" name="stockId" value="<%= s.getStockId() %>">
                                <button type="submit" class="btn btn-sm text-danger" onclick="return confirm('Delete stock?')">×</button>
                            </form>
                        </td>
                    </tr>
                    <% } } %>
                </tbody>
            </table>
        </div>

        <div class="bg-white p-4 shadow-sm rounded mb-5">
            <h5 class="fw-bold mb-3 text-primary">🔗 Recipe Linker</h5>
            <div class="row g-4">
                <div class="col-md-4 border-end">
                    <form action="RecipeManagementServlet" method="POST" class="small">
                        <input type="hidden" name="action" value="link">
                        <div class="mb-2"><label class="fw-bold text-dark">Menu Dish</label><select name="menuItemName" class="form-select form-select-sm"><% for(MenuItem mi : menu) { %><option value="<%= mi.getName() %>"><%= mi.getName() %></option><% } %></select></div>
                        <div class="mb-2"><label class="fw-bold text-dark">Stock Ingredient</label><select name="stockItemName" class="form-select form-select-sm"><% for(StockItem si : stock) { %><option value="<%= si.getItemName() %>"><%= si.getItemName() %></option><% } %></select></div>
                        <div class="mb-3"><label class="fw-bold text-dark">Qty (e.g. 0.125)</label><input type="number" step="0.001" name="quantity" class="form-control form-control-sm" value="1.0" required></div>
                        <button type="submit" class="btn btn-primary btn-sm w-100">Link Ingredient</button>
                    </form>
                </div>
                <div class="col-md-8">
                    <div style="max-height: 250px; overflow-y: auto;">
                        <table class="table table-sm small"><thead class="table-light sticky-top"><tr><th class="text-dark">Menu Item</th><th class="text-dark">Ingredient</th><th class="text-dark">Qty</th><th></th></tr></thead>
                            <tbody><% if(recipes != null) { for(RecipeItem r : recipes) { %>
                                <tr class="text-dark"><td><%= r.getMenuItemId() %></td><td><span class="badge bg-light text-dark border"><%= r.getStockItemName() %></span></td><td><%= String.format("%.3f", r.getQuantityNeeded()) %></td>
                                    <td class="text-end"><form action="RecipeManagementServlet" method="POST" class="d-inline"><input type="hidden" name="action" value="remove"><input type="hidden" name="menuItemName" value="<%= r.getMenuItemId() %>"><input type="hidden" name="stockItemName" value="<%= r.getStockItemName() %>"><button type="submit" class="btn btn-sm text-danger p-0 border-0 bg-transparent">×</button></form></td>
                                </tr><% } } %></tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <div class="d-flex justify-content-between align-items-center mb-2">
            <h5 class="fw-bold m-0 text-dark">🍽️ Menu Settings</h5>
            <div class="d-flex gap-2"><input type="text" id="menuSearch" class="form-control form-control-sm search-input" placeholder="Search menu..."><button class="btn btn-sm btn-primary" data-bs-toggle="collapse" data-bs-target="#menuForm">+</button></div>
        </div>

        <div class="collapse mb-3" id="menuForm">
            <form action="MenuManagementServlet" method="POST" enctype="multipart/form-data" class="card card-body border-0 shadow-sm row g-2 flex-row">
                <input type="hidden" name="action" value="create">
                <div class="col-md-3"><input type="text" name="name" class="form-control form-control-sm" placeholder="Name" required></div>
                <div class="col-md-2"><input type="number" step="0.01" name="price" class="form-control form-control-sm" placeholder="RM" required></div>
                <div class="col-md-2"><select name="category" class="form-select form-select-sm"><option value="Food">Food</option><option value="Drink">Drink</option><option value="Side Dish">Side Dish</option></select></div>
                <div class="col-md-3"><input type="file" name="imageFile" class="form-control form-control-sm"></div>
                <div class="col-md-2"><button type="submit" class="btn btn-sm btn-success w-100">Save</button></div>
            </form>
        </div>

        <div class="card border-0 shadow-sm mb-4 overflow-hidden">
            <table class="table table-sm align-middle mb-0" id="menuTable">
                <thead class="table-light"><tr><th class="ps-3 text-dark">Item</th><th class="text-dark">Price</th><th class="text-center text-dark">Actions</th></tr></thead>
                <tbody><% if(menu != null) { for(MenuItem m : menu) { %>
                    <tr class="searchable-row text-dark"><td class="ps-3 item-name"><%= m.getName() %> <small class="text-muted">(<%= m.getCategory() %>)</small></td><td>RM <%= String.format("%.2f", m.getPrice()) %></td>
                        <td class="text-center"><button type="button" class="btn btn-sm btn-outline-primary edit-menu-btn" data-id="<%= m.getId() %>" data-name="<%= m.getName() %>" data-price="<%= m.getPrice() %>" data-category="<%= m.getCategory() %>">Edit</button>
                            <form action="MenuManagementServlet" method="POST" class="d-inline"><input type="hidden" name="action" value="delete"><input type="hidden" name="id" value="<%= m.getId() %>"><button type="submit" class="btn btn-sm text-danger border-0 bg-transparent" onclick="return confirm('Delete?')">×</button></form></td>
                    </tr><% } } %></tbody>
            </table>
        </div>
    </div>

    <div class="modal fade" id="historyModal" tabindex="-1"><div class="modal-dialog modal-lg modal-dialog-centered"><div class="modal-content border-0 shadow"><div class="modal-header border-0"><h6 class="fw-bold m-0 text-dark">Order History</h6><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body p-0" style="max-height: 400px; overflow-y: auto;"><table class="table table-striped table-sm mb-0"><thead class="table-dark"><tr><th class="ps-3">Table</th><th>Items</th><th class="text-end pe-3">Status</th></tr></thead><tbody><% for(Order co : completedOrders) { %><tr><td class="ps-3 fw-bold text-dark">#<%= co.tableNumber %></td><td class="text-dark"><%= String.join(", ", co.items) %></td><td class="text-end pe-3"><span class="badge bg-success">Done</span></td></tr><% } %></tbody></table></div></div></div></div>
    
    <div class="modal fade" id="counterPaymentModal" tabindex="-1"><div class="modal-dialog modal-dialog-centered"><form action="PaymentServlet" method="POST" class="modal-content border-0 shadow"><div class="modal-header border-0 pb-0"><h6 class="fw-bold m-0 text-dark">Counter Payment</h6><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body"><input type="hidden" name="orderId" id="counterOrderId"><input type="hidden" name="paymentMethod" value="Counter"><p class="small text-muted mb-3" id="paymentInstruction">Select items being paid now:</p><div id="counterItemList"></div><div id="counterTotalDisplay" class="mt-3 p-3 bg-light rounded d-flex justify-content-between align-items-center"><span class="fw-bold small text-muted">Total for selection:</span><h5 class="m-0 text-primary fw-bold" id="selectionTotalRM">RM 0.00</h5></div></div><div class="modal-footer border-0"><button type="submit" class="btn btn-primary w-100 rounded-pill" id="processCounterPaymentBtn">Process Payment</button></div></form></div></div>
    
    <div class="modal fade" id="editMenuModal" tabindex="-1"><div class="modal-dialog modal-dialog-centered"><form action="MenuManagementServlet" method="POST" enctype="multipart/form-data" class="modal-content border-0 shadow"><div class="modal-header border-0"><h6 class="fw-bold m-0 text-dark">Edit Item</h6><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body"><input type="hidden" name="action" value="update"><input type="hidden" name="id" id="editMenuId"><div class="mb-3"><label class="small fw-bold text-dark">Name</label><input type="text" name="name" id="editMenuName" class="form-control" required></div><div class="mb-3"><label class="small fw-bold text-dark">Price (RM)</label><input type="number" step="0.01" name="price" id="editMenuPrice" class="form-control" required></div><div class="mb-3"><label class="small fw-bold text-dark">Category</label><select name="category" id="editMenuCategory" class="form-select"><option value="Food">Food</option><option value="Drink">Drink</option><option value="Side Dish">Side Dish</option></select></div><div class="mb-1"><label class="small fw-bold text-dark">Change Image</label><input type="file" name="imageFile" class="form-control form-control-sm"></div></div><div class="modal-footer border-0 p-3"><button type="submit" class="btn btn-primary w-100 py-2 rounded-pill">Update Menu</button></div></form></div></div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="static/js/script.js"></script>
    <script>
        const ctx = document.getElementById('revenueChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: <%= labels.toString() %>,
                datasets: [{
                    label: 'RM',
                    data: <%= values.toString() %>,
                    borderColor: '#2ecc71',
                    backgroundColor: 'rgba(46, 204, 113, 0.1)',
                    fill: true, tension: 0.4, borderWidth: 2, pointRadius: 3
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, grid: { display: false } }, x: { grid: { display: false } } } }
        });

        document.getElementById('downloadReportBtn').addEventListener('click', function() {
            let content = "AZURA HOUSE - DAILY REPORT\nDate: " + new Date().toLocaleDateString() + "\n--------------------------------\nTOTAL REVENUE: RM <%= String.format("%.2f", dailyRevenue) %>\n\nLOW STOCK ITEMS:\n";
            <% for(StockItem ls : lowStockItems) { %> content += "- <%= ls.getItemName() %>: <%= String.format("%.2f", ls.getQuantity()) %> remaining\n"; <% } %>
            const blob = new Blob([content], { type: 'text/plain' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a'); a.href = url; a.download = 'Daily_Report_' + new Date().toISOString().split('T')[0] + '.txt'; a.click();
        });

        // --- NEW AUTO-REFRESH KITCHEN QUEUE SCRIPT ---
        function refreshKitchenQueue() {
            // Only refresh if no modal is open (to avoid interrupting the owner while paying)
            if (document.querySelectorAll('.modal.show').length === 0) {
            	fetch('<%= request.getContextPath() %>/GetActiveOrders')
                    .then(response => response.text())
                    .then(html => {
                        const queueRow = document.getElementById('kitchen-queue-row');
                        // Only update if the content has actually changed to save performance
                        if (queueRow.innerHTML.trim() !== html.trim()) {
                            queueRow.innerHTML = html;
                        }
                    })
                    .catch(err => console.warn('Error fetching orders:', err));
            }
        }

        // Set to refresh every 3 seconds
        setInterval(refreshKitchenQueue, 3000);
    </script>
</body>
</html>