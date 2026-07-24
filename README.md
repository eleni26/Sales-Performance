# Sales Performance Dashboard

An end-to-end Business Intelligence project built on **Superstore Sales** data, using **SQL Server** and **Power BI** to design a dimensional data warehouse and deliver an interactive sales analytics dashboard.

---

## 📊 Dashboard Preview

![Dashboard](Dashboard.png)

---

## 🗄️ Star Schema

![Star Schema](Star%20Schema.png)

---

## 📐 Architecture

The data warehouse follows a **star schema** consisting of one fact table and five dimensions.

| Object | Type | Description |
|--------|------|-------------|
| `FactSales` | Fact Table | Stores sales transactions and measures |
| `DimDate` | Dimension | Role-playing date dimension built from `Order_Date`, `Ship_Date`, and `Date_Entry` |
| `DimCustomer` | Dimension | Customer information |
| `DimProduct` | Dimension | Product details |
| `DimTerritory` | Dimension | Regional sales hierarchy |
| `DimOrder` | Dimension | Order-level attributes linked by `Order_ID` |

`DimDate` is implemented as a **single-column role-playing dimension** using a `UNION` of **Order_Date**, **Ship_Date**, and **Date_Entry**, allowing all date filtering to be handled through one centralized date table.

---

## 🔍 Data Quality & Modeling Challenges

### **$353K Sales Reconciliation Gap**

**Problem**

Dashboard totals did not match the regional sales breakdown.

**Root Cause**

Blank (`''`) Region values were not captured by the existing `NULL` check, causing the fallback logic to fail.

**Solution**

Applied `NULLIF()` so both blank strings and `NULL` values are handled consistently.

---

### **Ambiguous Model Relationship**

**Problem**

`FactSales` and `DimOrder` were related through both `Order_ID` and `Order_Date`, creating multiple filter paths.

**Solution**

Removed `Order_Date` from `DimOrder`, leaving `Order_ID` as the single relationship key.

---

### **Year-over-Year Growth Measure**

**Problem**

Without a year filter, the YoY measure compared four years of pooled sales against three years of prior-period data due to `SAMEPERIODLASTYEAR()`.

**Solution**

Added a `HASONEVALUE()` guard so YoY calculations only execute when a single year is selected.

---

## ⚠️ Known Limitation

The dataset contains only partial data for **2026** (through approximately July/August). As a result, Year-over-Year comparisons for 2026 understate performance because the year is incomplete rather than reflecting a true decline.
