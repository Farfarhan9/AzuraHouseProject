package com.azurahouse.model;

import java.util.List;
import java.util.ArrayList;

public class Order {
    public String orderId;
    public String tableNumber;
    public List<String> items;
    public List<Double> itemPrices; 
    public double totalPrice;
    public String status;
    public String type; // NEW: Field to store "Dine-In" or "Takeout"

    // Updated constructor to include the 'type' parameter
    public Order(String orderId, String tableNumber, List<String> items, double totalPrice, String status, String type) {
        this.orderId = orderId;
        this.tableNumber = tableNumber;
        this.items = items != null ? items : new ArrayList<>();
        this.itemPrices = new ArrayList<>(); 
        this.totalPrice = totalPrice;
        this.status = status;
        this.type = type; // NEW: Assign the type
    }
}