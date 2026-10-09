package com.azurahouse.model;

public class StockItem {
    private int stockId;
    private String itemName;
    private double quantity; // Changed from int to double
    private double price;

    public StockItem() {}

    public StockItem(int stockId, String itemName, double quantity, double price) {
        this.stockId = stockId;
        this.itemName = itemName;
        this.quantity = quantity;
        this.price = price;
    }

    public int getStockId() { return stockId; }
    public void setStockId(int stockId) { this.stockId = stockId; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public double getQuantity() { return quantity; } // Returns double
    public void setQuantity(double quantity) { this.quantity = quantity; }

    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }
}