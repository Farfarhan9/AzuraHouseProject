package com.azurahouse.controller;

import com.azurahouse.model.*;
import com.azurahouse.dao.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.File;
import java.io.IOException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/OrderServlet")
public class OrderServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String contextPath = getServletContext().getRealPath("/");
        
        File dataDir = new File(contextPath + File.separator + "data");
        if (!dataDir.exists()) dataDir.mkdirs();

        String tableStr = request.getParameter("tableNumber");
        if (tableStr == null || tableStr.isEmpty()) tableStr = "Counter";
        
        // NEW: Get the order type from the radio buttons in index.jsp
        String orderType = request.getParameter("orderType");
        if (orderType == null || orderType.isEmpty()) orderType = "Dine-In";

        String[] foodItems = request.getParameterValues("foodItem"); 
        String totalStr = request.getParameter("totalPriceHidden");
        double total = (totalStr != null) ? Double.parseDouble(totalStr) : 0.0;

        if (foodItems == null || foodItems.length == 0) {
            response.sendRedirect("index.jsp");
            return;
        }

        InventoryDAO invDao = new InventoryDAO();
        RecipeDAO recipeDao = new RecipeDAO();
        MenuDAO menuDao = new MenuDAO();
        
        List<StockItem> stockList = invDao.getAll(contextPath);
        List<MenuItem> menuList = menuDao.getAll(contextPath);
        
        List<String> displayItems = new ArrayList<>();
        List<Double> itemPrices = new ArrayList<>(); 

        // 1. STOCK LOGIC & ITEM BUILDING
        for (String itemName : foodItems) {
            String qtyParam = request.getParameter("qty_" + itemName);
            int orderedQty = (qtyParam != null) ? Integer.parseInt(qtyParam) : 1;
            
            double unitPrice = 0.0;
            for(MenuItem mi : menuList) {
                if(mi.getName().equalsIgnoreCase(itemName)) {
                    unitPrice = mi.getPrice();
                    break;
                }
            }

            displayItems.add(itemName + " (x" + orderedQty + ")");
            itemPrices.add(unitPrice * orderedQty); 

            // Stock Deduction Logic
            List<RecipeItem> recipe = recipeDao.getRecipeForMenu(contextPath, itemName);
            if (!recipe.isEmpty()) {
                for (RecipeItem ingredient : recipe) {
                    for (StockItem s : stockList) {
                        if (s.getItemName().equalsIgnoreCase(ingredient.getStockItemName())) {
                            double totalNeeded = ingredient.getQuantityNeeded() * orderedQty;
                            if (s.getQuantity() < totalNeeded) {
                                response.sendRedirect("index.jsp?error=outofstock&item=" + URLEncoder.encode(ingredient.getStockItemName(), "UTF-8"));
                                return;
                            }
                            s.setQuantity(s.getQuantity() - totalNeeded);
                            break;
                        }
                    }
                }
            } else {
                for (StockItem s : stockList) {
                    if (s.getItemName().equalsIgnoreCase(itemName)) {
                        if (s.getQuantity() < (double)orderedQty) {
                            response.sendRedirect("index.jsp?error=outofstock&item=" + URLEncoder.encode(itemName, "UTF-8"));
                            return;
                        }
                        s.setQuantity(s.getQuantity() - orderedQty);
                        break;
                    }
                }
            }
        }

        // 2. SAVE ORDER
        String id = "AZR-" + System.currentTimeMillis();
        // UPDATED: Added orderType to constructor
        Order newOrder = new Order(id, tableStr, displayItems, total, "Pending", orderType);
        newOrder.itemPrices = itemPrices; 
        
        OrderDAO orderDao = new OrderDAO();
        orderDao.addOrder(contextPath, newOrder);
        invDao.saveAll(contextPath, stockList);

        response.sendRedirect("payment.jsp?orderId=" + id + "&amount=" + total + "&tableNumber=" + tableStr);
    }
}