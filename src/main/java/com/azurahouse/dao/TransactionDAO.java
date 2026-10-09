package com.azurahouse.dao;

import com.azurahouse.model.Transaction;
import java.util.List;
import java.util.ArrayList;

public class TransactionDAO extends BaseDAO<Transaction> {
    
    public TransactionDAO() {
        super("transactions.json", Transaction[].class);
    }

    public void addTransaction(String contextPath, Transaction t) {
        List<Transaction> list = getAll(contextPath);
        if (list == null) list = new ArrayList<>();
        list.add(t);
        saveAll(contextPath, list);
    }
}