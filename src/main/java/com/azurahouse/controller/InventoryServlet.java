package com.azurahouse.controller;

import com.azurahouse.dao.InventoryDAO;
import com.azurahouse.model.StockItem;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.List;

@WebServlet("/InventoryServlet")
public class InventoryServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String path = getServletContext().getRealPath("/");
        String action = request.getParameter("action");
        InventoryDAO dao = new InventoryDAO();
        List<StockItem> stock = dao.getAll(path);

        if ("create".equals(action)) {
            String name = request.getParameter("itemName");
            int qty = Integer.parseInt(request.getParameter("quantity"));
            double price = Double.parseDouble(request.getParameter("price"));
            
            // Validation: No negative stock
            qty = Math.max(0, qty);
            
            int nextId = stock.isEmpty() ? 101 : stock.get(stock.size()-1).getStockId() + 1;
            stock.add(new StockItem(nextId, name, qty, price));
        } 
        else if ("update".equals(action)) {
            int id = Integer.parseInt(request.getParameter("stockId"));
            int qty = Integer.parseInt(request.getParameter("quantity"));
            
            // Validation: No negative stock
            qty = Math.max(0, qty);

            for (StockItem item : stock) {
                if (item.getStockId() == id) {
                    item.setQuantity(qty);
                    break;
                }
            }
        } 
        else if ("delete".equals(action)) {
            int id = Integer.parseInt(request.getParameter("stockId"));
            stock.removeIf(item -> item.getStockId() == id);
        }
        
        dao.saveAll(path, stock);
        response.sendRedirect("dashboard.jsp?status=inventoryUpdated");
    }
}