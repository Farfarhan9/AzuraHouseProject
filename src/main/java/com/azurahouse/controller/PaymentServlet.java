package com.azurahouse.controller;

import com.azurahouse.model.*;
import com.azurahouse.dao.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

@WebServlet("/PaymentServlet")
public class PaymentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String contextPath = getServletContext().getRealPath("/");
        String orderId = request.getParameter("orderId");
        String method = request.getParameter("paymentMethod"); // "E-Wallet", "Cash", or "Counter"
        
        OrderDAO orderDAO = new OrderDAO();
        List<Order> allOrders = orderDAO.getAll(contextPath);
        Order currentOrder = null;

        if (allOrders != null) {
            for (Order o : allOrders) {
                if (o.orderId != null && o.orderId.equals(orderId)) {
                    currentOrder = o;
                    break;
                }
            }
        }

        if (currentOrder != null) {
            double amountPaid = 0;

            // --- CASE A: CUSTOMER-SIDE PAYMENT (E-Wallet) ---
            if ("E-Wallet".equalsIgnoreCase(method)) {
                amountPaid = currentOrder.totalPrice;
                currentOrder.status = "Paid"; // Hides Pay button on dashboard
            } 
            // --- CASE B: CUSTOMER-SIDE PAYMENT (Cash at Counter) ---
            else if ("Cash".equalsIgnoreCase(method)) {
                amountPaid = 0; // Not paid yet
                currentOrder.status = "Ordered"; // Keeps Pay button visible for owner
            }
            // --- CASE C: OWNER-SIDE PAYMENT (From Dashboard Modal) ---
            else if ("Counter".equalsIgnoreCase(method)) {
                String[] selectedIndices = request.getParameterValues("payItem");
                if (selectedIndices != null) {
                    java.util.Arrays.sort(selectedIndices, java.util.Collections.reverseOrder());
                    double totalFromSelectedItems = 0;

                    for (String indexStr : selectedIndices) {
                        int idx = Integer.parseInt(indexStr);
                        if (currentOrder.items != null && idx < currentOrder.items.size() &&
                            currentOrder.itemPrices != null && idx < currentOrder.itemPrices.size()) {
                            
                            double itemPrice = currentOrder.itemPrices.get(idx);
                            totalFromSelectedItems += itemPrice;
                            currentOrder.items.remove(idx);
                            currentOrder.itemPrices.remove(idx);
                            currentOrder.totalPrice -= itemPrice;
                        }
                    }
                    amountPaid = totalFromSelectedItems;
                }

                if (currentOrder.items == null || currentOrder.items.isEmpty()) {
                    currentOrder.status = "Paid";
                    currentOrder.totalPrice = 0;
                } else {
                    currentOrder.status = "Partially Paid";
                }
            }

            // Save Transaction record
            String tId = "TRX-" + System.currentTimeMillis();
            String time = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
            Transaction t = new Transaction(tId, orderId, amountPaid, method, time);
            new TransactionDAO().addTransaction(contextPath, t);

            orderDAO.saveAll(contextPath, allOrders);
        }

        // Redirect Logic
        if ("Counter".equalsIgnoreCase(method)) {
            response.sendRedirect("dashboard.jsp?status=paymentSuccess");
        } else {
            response.sendRedirect("index.jsp?status=paid&trxId=" + orderId);
        }
    }
}