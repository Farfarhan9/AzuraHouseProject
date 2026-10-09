package com.azurahouse.model;

public class RecipeItem {
    private String menuItemId;
    private String stockItemName;
    private double quantityNeeded; // Changed from int to double

    public RecipeItem(String menuItemId, String stockItemName, double quantityNeeded) {
        this.menuItemId = menuItemId;
        this.stockItemName = stockItemName;
        this.quantityNeeded = quantityNeeded;
    }

    public String getMenuItemId() { return menuItemId; }
    public String getStockItemName() { return stockItemName; }
    public double getQuantityNeeded() { return quantityNeeded; }
    public void setQuantityNeeded(double quantityNeeded) { this.quantityNeeded = quantityNeeded; }
}