package com.azurahouse.dao;

import com.azurahouse.model.Order;
import java.util.List;
import java.util.ArrayList;

public class OrderDAO extends BaseDAO<Order> {
    
    public OrderDAO() {
        // Tells BaseDAO to use orders.json and the Order array class
        super("orders.json", Order[].class);
    }

    public void addOrder(String contextPath, Order newOrder) {
        // Get the list from the parent BaseDAO
        List<Order> list = getAll(contextPath);
        
        // If file is empty/new, initialize a new list
        if (list == null) {
            list = new ArrayList<>();
        }
        
        list.add(newOrder);
        
        // Save using the parent BaseDAO method
        saveAll(contextPath, list);
    }
}