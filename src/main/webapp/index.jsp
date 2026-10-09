<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.azurahouse.dao.*, com.azurahouse.model.*, java.util.*" %>
<%
    // 1. Setup Path and DAOs
    String contextPath = application.getRealPath("/"); 
    MenuDAO menuDao = new MenuDAO();
    InventoryDAO invDao = new InventoryDAO();
    
    List<MenuItem> items = menuDao.getAll(contextPath); 
    List<StockItem> stockList = invDao.getAll(contextPath);

    // Stock Map for availability check
    Map<String, Double> stockMap = new HashMap<>();
    if(stockList != null) {
        for(StockItem s : stockList) {
            // Store by name for easy lookup (lowercase for matching)
            stockMap.put(s.getItemName().trim().toLowerCase(), s.getQuantity());
        }
    }

    // 2. Handling Table Number from URL
    String tableNum = request.getParameter("table");
    if(tableNum == null || tableNum.isEmpty()) {
        tableNum = "Counter"; 
    }
    
    // Persistent URL for "Order More" button
    String redirectUrl = "index.jsp?table=" + tableNum;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Azura House - Digital Menu</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="static/css/style.css">
    <style>
        .order-type-container { max-width: 300px; margin: 0 auto 20px auto; }
        .order-type-btn { border-radius: 50px; font-weight: 600; transition: all 0.3s ease; }
        .btn-check:checked + .order-type-btn {
            background-color: #2ecc71 !important;
            color: white !important;
            border-color: #2ecc71 !important;
        }
        .filter-btn { border-radius: 20px; border: 1px solid #ddd; background: white; padding: 5px 15px; font-size: 0.85rem; }
        .filter-btn.active { background-color: #34495e; color: white; border-color: #34495e; }
        .item-card { transition: transform 0.2s; border: none; }
        .item-card:active { transform: scale(0.98); }
        .menu-img { border-radius: 10px 10px 0 0; }
        /* Ensures labels are visible on white backgrounds */
        .text-dark { color: #2c3e50 !important; }
    </style>
</head>

<body class="bg-light">
   <header class="py-3 mb-4 border-bottom bg-white shadow-sm sticky-top">
   		<div class="container text-center">
            <img src="static/images/logo.png" alt="Azura House Logo" class="main-logo" style="height: 50px;">
        </div>
    </header>

    <div class="container py-2">
        <% if(request.getParameter("error") != null) { %>
            <div class="alert alert-danger text-center shadow-sm">
                Maaf! Item <strong><%= request.getParameter("item") %></strong> telah habis stok.
            </div>
        <% } %>

        <div class="alert alert-info text-center py-2 mb-3 shadow-sm rounded-pill text-dark">
            <strong>Meja:</strong> <%= tableNum %>
        </div>

        <form action="OrderServlet" method="POST" id="mainOrderForm">
            <input type="hidden" name="tableNumber" value="<%= tableNum %>">
            <input type="hidden" name="totalPriceHidden" id="totalPriceHidden" value="0.00">

            <div class="order-type-container">
                <div class="btn-group w-100 p-1 bg-white shadow-sm rounded-pill" role="group">
                    <input type="radio" class="btn-check" name="orderType" id="dineIn" value="Dine-In" checked>
                    <label class="btn btn-outline-secondary order-type-btn border-0" for="dineIn">🍽️ Dine-In</label>

                    <input type="radio" class="btn-check" name="orderType" id="takeout" value="Takeout">
                    <label class="btn btn-outline-secondary order-type-btn border-0" for="takeout">🥡 Takeout</label>
                </div>
            </div>

            <h1 class="text-center mb-4 main-title text-dark">Digital Menu</h1>
            
            <div class="d-flex justify-content-center mb-4 overflow-auto py-2">
                <div class="d-flex gap-2" id="categoryFilter">
                    <button type="button" class="btn filter-btn active" data-filter="all">All</button>
                    <button type="button" class="btn filter-btn" data-filter="Food">Mains</button>
                    <button type="button" class="btn filter-btn" data-filter="Drink">Drinks</button>
                    <button type="button" class="btn filter-btn" data-filter="Side Dish">Sides</button>
                </div>
            </div>

            <div class="row g-3 justify-content-center"> 
                <%
	                if(items != null && !items.isEmpty()) {
                        items.sort((a, b) -> a.getName().compareToIgnoreCase(b.getName()));
                        
	                    for(MenuItem item : items) {
                            // Logic: Default to 100 if not in stock table, otherwise use stock value
                            double stockQty = stockMap.getOrDefault(item.getName().toLowerCase(), 100.0);
                            
                            if (stockQty > 0) {
                                int displayQty = (int) Math.floor(stockQty);
                %>
                <div class="col-6 col-md-4 col-lg-3 mb-2 menu-item-container" data-category="<%= item.getCategory() %>"> 
                    <div class="card shadow-sm h-100 item-card">
                        <img src="static/images/menu/<%= item.getImage() %>" 
                             class="card-img-top menu-img" alt="<%= item.getName() %>"
                             style="height: 120px; object-fit: cover;"
                             onerror="this.src='static/images/logo.png';"> 
                        <div class="card-body d-flex flex-column p-2 p-md-3">
                            <h6 class="card-title mb-1 small fw-bold text-dark"><%= item.getName() %></h6>
                            <p class="text-success fw-bold mb-2" style="font-size: 0.9rem;">RM <%= String.format("%.2f", item.getPrice()) %></p>
                            
                            <div class="mt-auto">
                                <div class="form-check mb-2">
                                    <input class="form-check-input item-checkbox" type="checkbox" name="foodItem" 
                                           value="<%= item.getName() %>" 
                                           data-price="<%= item.getPrice() %>" 
                                           id="item_<%= item.getId() %>">
                                    <label class="form-check-label small fw-bold text-dark" for="item_<%= item.getId() %>">Add</label>
                                </div>
                                <input type="number" name="qty_<%= item.getName() %>" value="1" 
                                       class="form-control form-control-sm text-center" min="1" max="<%= displayQty %>">
                            </div>
                        </div>
                    </div>
                </div>
                <%      
                            }
                        } 
                    } else { %>
                        <div class="col-12 text-center py-5">
                            <p class="text-muted">No items found in menu.</p>
                        </div>
                <%  } %>
            </div>
            
            <div class="d-flex justify-content-center mt-5 mb-5 pb-5">
				<button type="button" id="placeOrderBtn" class="btn btn-primary btn-lg px-5 shadow rounded-pill">
				    View My Order
				</button>
            </div>

            <div class="modal fade" id="confirmModal" tabindex="-1" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered mx-auto" style="max-width: 400px;"> 
                    <div class="modal-content border-0 shadow">
                        <div class="modal-header border-0 pb-0">
                            <h5 class="modal-title w-100 text-center fw-bold text-dark">Review Order</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body">
                            <div id="orderSummaryList" class="mb-3">
                                </div>
                            <div class="d-flex justify-content-between fw-bold fs-5 p-2 bg-light rounded text-dark">
                                <span>Total:</span>
                                <span id="modalTotal" class="text-success">RM 0.00</span>
                            </div>
                        </div>
                        <div class="modal-footer border-0 flex-column pt-0">
                            <button type="submit" class="btn btn-success btn-lg w-100 mb-2 rounded-pill shadow-sm">Confirm Order</button>
                            <button type="button" class="btn btn-link text-muted btn-sm" data-bs-dismiss="modal">Add more items</button>
                        </div>
                    </div>
                </div>
            </div>
        </form>
    </div>
    
    <div class="modal fade" id="successModal" tabindex="-1" aria-hidden="true" data-bs-backdrop="static">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content text-center p-4 border-0 shadow-lg" style="border-radius: 25px;">
                <div class="modal-body">
                    <div class="mb-3">
                        <div class="rounded-circle bg-success text-white d-inline-flex align-items-center justify-content-center" 
                             style="width: 80px; height: 80px; font-size: 40px;">
                            &#10003; 
                        </div>
                    </div>
                    <h2 class="fw-bold text-dark">Order Received!</h2>
                    <p class="text-muted">Your order is being prepared.</p>
                    <div class="bg-light p-3 rounded mb-3">
                        <small class="text-uppercase text-muted d-block">Transaction ID</small>
                        <span class="fw-bold text-dark"><%= request.getParameter("trxId") != null ? request.getParameter("trxId") : "N/A" %></span>
                    </div>
                    <a href="<%= redirectUrl %>" class="btn btn-primary rounded-pill px-5 text-decoration-none">Order More</a>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="static/js/script.js"></script>
</body>
</html>