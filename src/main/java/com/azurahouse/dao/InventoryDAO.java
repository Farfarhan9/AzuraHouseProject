package com.azurahouse.dao;

import com.azurahouse.model.StockItem;
import java.util.List;

public class InventoryDAO extends BaseDAO<StockItem> {
    
    public InventoryDAO() {
        super("inventory.json", StockItem[].class);
    }

    // This makes it easy for the Servlet to call
    public List<StockItem> getAllStockItems(String contextPath) {
        return getAll(contextPath);
    }
}