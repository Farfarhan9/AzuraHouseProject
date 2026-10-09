package com.azurahouse.util;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import java.io.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class JsonUtils {
    // Added Pretty Printing so you can read the JSON easily during testing
    private static final Gson gson = new GsonBuilder().setPrettyPrinting().create();

    public static <T> List<T> readList(String fileName, Class<T[]> clazz) {
        File file = new File(fileName);
        if (!file.exists()) return new ArrayList<>();
        
        try (Reader reader = new FileReader(file)) {
            T[] array = gson.fromJson(reader, clazz);
            return (array != null) ? new ArrayList<>(Arrays.asList(array)) : new ArrayList<>();
        } catch (Exception e) { 
            e.printStackTrace();
            return new ArrayList<>(); 
        }
    }

    public static void writeList(String fileName, List<?> list) {
        try {
            File file = new File(fileName);
            // Ensure the 'data' directory exists
            if (file.getParentFile() != null && !file.getParentFile().exists()) {
                file.getParentFile().mkdirs();
            }
            try (Writer writer = new FileWriter(file)) {
                gson.toJson(list, writer);
                writer.flush(); // Ensure data is actually pushed to the disk
            }
        } catch (Exception e) { 
            e.printStackTrace(); 
        }
    }
}