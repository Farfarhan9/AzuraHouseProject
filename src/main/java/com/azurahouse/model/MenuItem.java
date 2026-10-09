package com.azurahouse.model;

public class MenuItem {
    private String id;
    private String name;
    private double price;
    private String category; // e.g., "Food", "Drink"
    private String image;

    public MenuItem(String id, String name, double price, String category, String image) {
        this.id = id;
        this.name = name;
        this.price = price;
        this.category = category;
        this.image = image;
    }

    // Getters
    public String getId() { return id; }
    public String getName() { return name; }
    public double getPrice() { return price; }
    public String getCategory() { return category; }
    public String getImage() { return image; }
    // Setters
    public void setId(String id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setPrice(double price) { this.price = price; }
    public void setCategory(String category) { this.category = category; }
    public void setImage(String image) { this.image = image; }
}