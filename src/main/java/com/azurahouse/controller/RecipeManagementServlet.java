package com.azurahouse.controller;

import com.azurahouse.dao.RecipeDAO;
import com.azurahouse.model.RecipeItem;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.List;

@WebServlet("/RecipeManagementServlet")
public class RecipeManagementServlet extends HttpServlet {
    /**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String path = getServletContext().getRealPath("/");
        String action = request.getParameter("action");
        RecipeDAO dao = new RecipeDAO();
        List<RecipeItem> recipes = dao.getAll(path);

        if ("link".equals(action)) {
            String menuName = request.getParameter("menuItemName");
            String stockName = request.getParameter("stockItemName");
            double qty = Double.parseDouble(request.getParameter("quantity"));
            
            recipes.add(new RecipeItem(menuName, stockName, qty));
        } 
        else if ("remove".equals(action)) {
            String menuName = request.getParameter("menuItemName");
            String stockName = request.getParameter("stockItemName");
            recipes.removeIf(r -> r.getMenuItemId().equals(menuName) && r.getStockItemName().equals(stockName));
        }

        dao.saveAll(path, recipes);
        response.sendRedirect("dashboard.jsp?status=recipeUpdated");
    }
}