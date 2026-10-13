# Sales Performance Dashboard

An end-to-end Business Intelligence project built on **Superstore Sales** data, using **SQL Server** and **Power BI** to design a dimensional data warehouse and deliver an interactive sales analytics dashboard.

---

## 🎯 Business Question

Where do sales come from, by region, category and customer segment, and how is performance trending year over year? The source data is deliberately messy, so the first question is whether it can be trusted at all.

---

## 🔍 Key Findings

- **Sales are concentrated in the West, not evenly spread.** When region is derived from State, the West accounts for about 39% of sales, and California alone for about 26%. South follows at about 25%, and East, Central and North are about 11–12% each.
- **The source data's own Region field is unreliable.** Every state appears under every region label in roughly equal numbers, so any analysis based on that field shows a false "evenly balanced" picture (see Known Limitations).
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

### Data cleaning summary

The raw extract has 16,000 rows. Issues found and handled in `Table script.sql`:

| Issue | Rows affected | Fix |
|-------|---------------|-----|
| Misspelled or non-standard categories (e.g. `Furnitree`, `Offis Suply`, `Phonesss`) | 1,787 | Mapped to Furniture / Office Supplies / Technology |
| Inconsistent sub-category casing and spacing | 28 variants → 14 | `TRIM` + proper case |
| Placeholder phone numbers (`phone_number_hidden`, `000-000-0000`, …) | 803 | Set to `NULL` |
| Invalid product IDs | 312 | Grouped as `UNKNOWN_PROD` |
| Invalid postal codes (`NULL_ZIP`, `ABCDE`, `0`) | 477 | Grouped as `UNKNOWN_ZIP` |
| Unparseable or out-of-range dates (e.g. year 1900 / 2099) | 31 | `TRY_CAST`; excluded from the date dimension |
| Region labelled `UNKNOWN_SYSTEM_VAL` | 2,394 | Region re-derived from State |

### **Unreliable Source Region Field**

**Problem**

Cross-tabulating State against the source `Region` column showed that every state is spread almost evenly across all five region labels. For example, California rows are labelled East, North, South and West in nearly equal numbers, and Chicago, Illinois appears as "West."

**Solution**

Region is derived from State in `DimTerritory` instead of trusting the source field. This changes the conclusion: sales are concentrated in the West (~39%) rather than evenly balanced.

---

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

## ⚠️ Known Limitations

- **Dashboard region chart:** the "Region Portion of Sales" donut and the "Regions are evenly balanced" insight in the screenshot are based on the unreliable source Region field. The chart is being switched to the State-derived region from `DimTerritory`, which shows sales concentrated in the West.
- **Partial final year:** the dataset contains only partial data for **2026** (through approximately July/August). As a result, Year-over-Year comparisons for 2026 understate performance because the year is incomplete rather than reflecting a true decline.
