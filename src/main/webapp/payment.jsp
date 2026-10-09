<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azura House - Payment</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="static/css/style.css">
    <script src="static/js/payment-script.js"></script>
</head>
<body class="bg-light">
    <header class="py-3 mb-4 border-bottom bg-white shadow-sm">
        <div class="container text-center">
            <img src="static/images/logo.png" alt="Azura House Logo" class="main-logo">
        </div>
    </header>

    <div class="container text-center">
        <div class="card shadow mx-auto" style="max-width: 400px; border-radius: 20px;">
		    <div class="card-body p-4 text-center">
		        <h2 class="main-title mb-4">Payment</h2>
		        <p class="text-muted">Table: <strong><%= request.getParameter("tableNumber") %></strong></p>
		        <h3 class="text-success fw-bold mb-4">RM <%= request.getParameter("amount") %></h3>
		
		        <form action="PaymentServlet" method="post">
		            <input type="hidden" name="orderId" value="<%= request.getParameter("orderId") %>">
		            <input type="hidden" name="amount" value="<%= request.getParameter("amount") %>">
		            
		            <label class="small fw-bold d-block text-start mb-1 ms-1">Payment Method</label>
		            <select name="paymentMethod" id="payMethod" class="form-select mb-3" onchange="toggleQR()">
		                <option value="Cash">Cash at Counter</option>
		                <option value="E-Wallet">E-Wallet (QR Scan)</option>
		            </select>
		
		            <div id="qrDisplay" style="display:none;" class="mb-3">
		                <img src="static/images/qr-sample.png" style="width:200px;" class="border p-2 rounded bg-white">
		                <p class="small text-danger mt-2">Scan and show receipt to staff</p>
		            </div>
		
		            <button type="submit" class="btn btn-success btn-lg w-100 rounded-pill mb-3">Confirm Payment</button>
		            
		            <button type="button" onclick="window.history.back();" class="btn btn-link text-muted text-decoration-none small">
		                &larr; Cancel and Edit Order
		            </button>
		        </form>
		    </div>
		</div>
    </div>
</body>
</html>