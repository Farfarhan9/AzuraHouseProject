package com.azurahouse.dao;

import com.azurahouse.model.MenuItem;



public class MenuDAO extends BaseDAO<MenuItem> {
    public MenuDAO() {
        super("menu.json", MenuItem[].class);
    }
    // You don't need to write any more code! It's all in the parent.
}