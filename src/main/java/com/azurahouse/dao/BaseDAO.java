package com.azurahouse.dao;

import com.azurahouse.util.JsonUtils;
import java.io.File;
import java.util.List;

public abstract class BaseDAO<T> {
    protected String fileName;
    protected Class<T[]> clazz;

    public BaseDAO(String fileName, Class<T[]> clazz) {
        this.fileName = fileName;
        this.clazz = clazz;
    }

    public List<T> getAll(String contextPath) {
        // Ensure there's a slash between the path and the data folder
        String separator = contextPath.endsWith(File.separator) ? "" : File.separator;
        String fullPath = contextPath + separator + "data" + File.separator + fileName;
        return JsonUtils.readList(fullPath, clazz);
    }

    public void saveAll(String contextPath, List<T> list) {
        String separator = contextPath.endsWith(File.separator) ? "" : File.separator;
        String fullPath = contextPath + separator + "data" + File.separator + fileName;
        JsonUtils.writeList(fullPath, list);
    }
}