package com.azurahouse.dao;

import com.azurahouse.model.RecipeItem;
import java.util.ArrayList;
import java.util.List;

public class RecipeDAO extends BaseDAO<RecipeItem> {
    public RecipeDAO() {
        super("recipes.json", RecipeItem[].class);
    }

    public List<RecipeItem> getRecipeForMenu(String contextPath, String menuName) {
        List<RecipeItem> all = getAll(contextPath);
        List<RecipeItem> found = new ArrayList<>();
        if (all != null) {
            for (RecipeItem r : all) {
                // We match by Menu Item Name
                if (r.getMenuItemId().equalsIgnoreCase(menuName)) {
                    found.add(r);
                }
            }
        }
        return found;
    }
}