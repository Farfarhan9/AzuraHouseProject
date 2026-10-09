package com.azurahouse.model;

public class Transaction {
    private String transactionId;
    private String orderId;
    private double amount;
    private String paymentMethod;
    private String timestamp;

    public Transaction() {} // Required for JSON

    public Transaction(String tId, String oId, double amt, String method, String time) {
        this.transactionId = tId;
        this.orderId = oId;
        this.amount = amt;
        this.paymentMethod = method;
        this.timestamp = time;
    }

    // Getters
    public String getTransactionId() { return transactionId; }
    public String getOrderId() { return orderId; }
    public double getAmount() { return amount; }
    public String getPaymentMethod() { return paymentMethod; }
    public String getTimestamp() { return timestamp; }
}