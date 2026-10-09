package com.azurahouse.controller;

import com.azurahouse.model.*;
import com.azurahouse.dao.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/GetActiveOrders")
public class GetActiveOrdersServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String path = getServletContext().getRealPath("/");
        OrderDAO orderDAO = new OrderDAO();
        List<Order> allOrders = orderDAO.getAll(path);
        
        StringBuilder html = new StringBuilder();
        
        if (allOrders != null && !allOrders.isEmpty()) {
            for (Order o : allOrders) {
                // Only show orders that are NOT "Completed"
                if (o.status != null && !"Completed".equalsIgnoreCase(o.status)) {
                    
                    boolean isPaid = "Paid".equalsIgnoreCase(o.status);
                    boolean isPartial = "Partially Paid".equalsIgnoreCase(o.status);
                    boolean isTakeout = (o.type != null && "Takeout".equalsIgnoreCase(o.type));
                    
                    // Logic for buttons
                    boolean showPayButton = !isPaid;
                    boolean showDoneButton = isTakeout || isPaid;
                    
                    // Style classes
                    String borderClass = isPaid ? "border-success" : (isPartial ? "border-info" : "border-warning");
                    
                    // Prepare price strings for the JavaScript function
                    List<String> priceStrs = new ArrayList<>();
                    if (o.itemPrices != null) {
                        for (Double p : o.itemPrices) priceStrs.add(String.format("%.2f", p));
                    }
                    String priceJoin = String.join("|", priceStrs);
                    String itemJoin = (o.items != null) ? String.join("|", o.items) : "";

                    // Start Building the Card HTML
                    html.append("<div class='col-md-3 mb-2'>")
                        .append("<div class='card card-body border-0 shadow-sm border-start border-4 ").append(borderClass).append("'>")
                        .append("<div class='d-flex justify-content-between align-items-start'>")
                        .append("<div>")
                        .append("<span class='fw-bold d-block text-dark'>").append(isTakeout ? "🥡 Takeout" : "Table " + o.tableNumber).append("</span>")
                        .append("<span class='text-success fw-bold' style='font-size: 0.8rem;'>RM ").append(String.format("%.2f", o.totalPrice)).append("</span>")
                        .append("</div>")
                        .append("<div class='d-flex gap-1'>");

                    // Pay Button
                    if (showPayButton) {
                        html.append("<button class='btn btn-sm btn-outline-success py-0 px-2' ")
                            .append("onclick=\"openCounterPayment('").append(o.orderId).append("', '").append(itemJoin).append("', '").append(priceJoin).append("', ").append(isTakeout).append(")\">")
                            .append("Pay</button>");
                    }

                    // Done Button
                    if (showDoneButton) {
                        html.append("<form action='MenuManagementServlet' method='POST' class='m-0'>")
                            .append("<input type='hidden' name='action' value='completeOrder'>")
                            .append("<input type='hidden' name='orderId' value='").append(o.orderId).append("'>")
                            .append("<button type='submit' class='btn btn-sm btn-success py-0 px-2 fw-bold'>Done</button>")
                            .append("</form>");
                    }

                    html.append("</div></div>") // End header
                        .append("<hr class='my-2 opacity-25'>")
                        .append("<small class='text-dark' style='font-size: 0.75rem; min-height: 30px; display: block;'>")
                        .append((o.items != null && !o.items.isEmpty()) ? String.join(", ", o.items) : "Empty Order")
                        .append("</small>")
                        .append("<div class='mt-2 d-flex justify-content-between align-items-center'>")
                        .append("<div class='d-flex gap-1 align-items-center'>")
                        .append("<span class='badge bg-light text-dark border' style='font-size: 0.6rem;'>").append(o.status).append("</span>");
                    
                    if (isTakeout) {
                        html.append("<span class='takeout-badge'>TAKEOUT</span>");
                    }

                    html.append("</div></div></div></div>"); // Close tags
                }
            }
        } else {
            html.append("<p class='text-muted small ms-2'>All caught up!</p>");
        }

        response.setContentType("text/html");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(html.toString());
    }
}