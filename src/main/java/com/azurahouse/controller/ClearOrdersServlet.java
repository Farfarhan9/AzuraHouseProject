package com.azurahouse.controller;

import com.azurahouse.util.JsonUtils;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.ArrayList;

@WebServlet("/ClearOrdersServlet")
public class ClearOrdersServlet extends HttpServlet {
    /**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	@Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String path = getServletContext().getRealPath("/") + "data/orders.json";
        
        // Overwrite orders.json with an empty list
        JsonUtils.writeList(path, new ArrayList<>());
        
        response.sendRedirect("dashboard.jsp?status=cleared");
    }
}