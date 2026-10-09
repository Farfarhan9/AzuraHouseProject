package com.azurahouse.controller;

import com.azurahouse.dao.MenuDAO;
import com.azurahouse.dao.OrderDAO;
import com.azurahouse.dao.InventoryDAO;
import com.azurahouse.model.MenuItem;
import com.azurahouse.model.Order;
import com.azurahouse.model.StockItem;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.File;
import java.io.IOException;
import java.util.List;

@WebServlet("/MenuManagementServlet")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 1, 
    maxFileSize = 1024 * 1024 * 10,      
    maxRequestSize = 1024 * 1024 * 100   
)
public class MenuManagementServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String path = getServletContext().getRealPath("/");
        String action = request.getParameter("action");
        
        MenuDAO menuDao = new MenuDAO();
        OrderDAO orderDao = new OrderDAO();
        InventoryDAO invDao = new InventoryDAO();

        if ("completeOrder".equals(action)) {
            String orderId = request.getParameter("orderId");
            List<Order> orders = orderDao.getAll(path);
            if (orders != null) {
                for (Order o : orders) {
                    if (o.orderId.equals(orderId)) {
                        o.status = "Completed";
                        break;
                    }
                }
                orderDao.saveAll(path, orders);
            }
        } 
        else {
            List<MenuItem> items = menuDao.getAll(path);

            if ("create".equals(action)) {
                String name = request.getParameter("name");
                String priceStr = request.getParameter("price");
                String category = request.getParameter("category");
                
                // Process Image
                Part filePart = request.getPart("imageFile");
                String image = handleImageUpload(filePart, path);

                // 1. Add to Menu
                items.add(new MenuItem("M-" + System.currentTimeMillis(), name, Double.parseDouble(priceStr), category, image));
                menuDao.saveAll(path, items);

                // 2. AUTO-CONNECTION: Check and add to Inventory if missing
                List<StockItem> stockList = invDao.getAll(path);
                boolean exists = (stockList == null) ? false : stockList.stream().anyMatch(s -> s.getItemName().equalsIgnoreCase(name));
                
                if (!exists && stockList != null) {
                    int nextId = stockList.isEmpty() ? 101 : stockList.get(stockList.size()-1).getStockId() + 1;
                    stockList.add(new StockItem(nextId, name, 0, Double.parseDouble(priceStr)));
                    invDao.saveAll(path, stockList);
                }
            } 
            else if ("update".equals(action)) {
                String id = request.getParameter("id");
                Part filePart = request.getPart("imageFile");

                for (MenuItem m : items) {
                    if (m.getId().equals(id)) {
                        m.setName(request.getParameter("name"));
                        m.setPrice(Double.parseDouble(request.getParameter("price")));
                        m.setCategory(request.getParameter("category"));
                        
                        // Update image only if a new one is provided
                        if (filePart != null && filePart.getSize() > 0) {
                            m.setImage(handleImageUpload(filePart, path));
                        }
                        break;
                    }
                }
                menuDao.saveAll(path, items);
            } 
            else if ("delete".equals(action)) {
                String id = request.getParameter("id");
                items.removeIf(m -> m.getId().equals(id));
                menuDao.saveAll(path, items);
            }
        }
        response.sendRedirect("dashboard.jsp?status=updated");
    }

    private String handleImageUpload(Part filePart, String path) throws IOException {
        if (filePart == null || filePart.getSize() <= 0) {
            return "logo.png";
        }
        String fileName = filePart.getSubmittedFileName();
        String uploadPath = path + "static" + File.separator + "images" + File.separator + "menu";
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists()) uploadDir.mkdirs();
        filePart.write(uploadPath + File.separator + fileName);
        return fileName;
    }
}