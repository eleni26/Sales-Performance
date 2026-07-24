USE Super_Store;


IF OBJECT_ID('dbo.FactSales', 'U') IS NOT NULL DROP TABLE dbo.FactSales;
IF OBJECT_ID('dbo.DimDate', 'U') IS NOT NULL DROP TABLE dbo.DimDate;
IF OBJECT_ID('dbo.DimCustomer', 'U') IS NOT NULL DROP TABLE dbo.DimCustomer;
IF OBJECT_ID('dbo.DimProduct', 'U') IS NOT NULL DROP TABLE dbo.DimProduct;
IF OBJECT_ID('dbo.DimTerritory', 'U') IS NOT NULL DROP TABLE dbo.DimTerritory;
IF OBJECT_ID('dbo.DimOrder', 'U') IS NOT NULL DROP TABLE dbo.DimOrder;
IF OBJECT_ID('dbo.DimShipment', 'U') IS NOT NULL DROP TABLE dbo.DimShipment;


WITH UniqueDates AS (
    SELECT TRY_CAST([Order_Date] AS DATE) AS RawDate FROM [dbo].[Super_Store] UNION
    SELECT TRY_CAST([Ship_Date] AS DATE)  AS RawDate FROM [dbo].[Super_Store] UNION
    SELECT TRY_CAST([Date_Entry] AS DATE) AS RawDate FROM [dbo].[Super_Store]
)
SELECT 
    RawDate AS [Date_Key],
    RawDate AS [Date],                                    
    YEAR(RawDate) AS [Year],
    'Q' + CAST(DATEPART(QUARTER, RawDate) AS VARCHAR(1)) AS [Quarter],
    MONTH(RawDate) AS [MonthNumber],                       
    DATENAME(MONTH, RawDate) AS [MonthName],              
    DAY(RawDate) AS [Day],
    DATENAME(WEEKDAY, RawDate) AS [DayName],              
    YEAR(RawDate) * 100 + MONTH(RawDate) AS [Month_Year_Sort]
INTO DimDate
FROM UniqueDates
WHERE RawDate IS NOT NULL;



WITH CustomerDedup AS (
    SELECT  
        Customer_ID,
        Customer_Name,
        CASE
             WHEN Customer_Phone IN ('phone_number_hidden', '123-456', '000-000-0000', '(999) 999-9999 ext. 99999999') THEN NULL
             ELSE Customer_Phone
        END AS [Customer_Phone],
        Segment,
        ROW_NUMBER() OVER (
            PARTITION BY Customer_ID
            ORDER BY Customer_Name ASC 
        ) AS rn
    FROM [dbo].[Super_Store]
    WHERE Customer_ID IS NOT NULL
)
SELECT
    Customer_ID,                   
    Customer_Name,
    [Customer_Phone],
    Segment
INTO DimCustomer
FROM CustomerDedup
WHERE rn = 1;


WITH ProductDedup AS (
    SELECT
        CASE WHEN Product_ID LIKE '%INVALID%' OR Product_ID IS NULL THEN 'UNKNOWN_PROD' ELSE Product_ID END AS [Product_ID],
        [Product_Name],
        CASE
              WHEN Category IN ('Furnitree', 'Funiture', 'Furnishingsss','Chairs', 'Tabels')  THEN 'Furniture'
              WHEN Category IN ('Offis Suply', 'Binders_Error','Paperrr', 'Appliances!')      THEN 'Office Supplies'
              WHEN Category IN ('Copier Machine', 'Phonesss','Accessries')                    THEN 'Technology'
              ELSE Category
        END AS [Category],
        UPPER(LEFT(TRIM([Sub_Category]), 1)) +
        LOWER(SUBSTRING(TRIM([Sub_Category]), 2, LEN(TRIM([Sub_Category])))) AS [Sub_Category],
        ROW_NUMBER() OVER (
            PARTITION BY CASE WHEN Product_ID LIKE '%INVALID%' OR Product_ID IS NULL THEN 'UNKNOWN_PROD' ELSE Product_ID END
            ORDER BY [Product_Name] DESC
        ) AS rn
    FROM [dbo].[Super_Store]
)
SELECT
    [Product_ID],
    [Product_Name],
    [Category],
    [Sub_Category]
INTO DimProduct
FROM ProductDedup
WHERE rn = 1;


WITH TerritoryCleaned AS (
    SELECT
        [City],
        [State],
        CASE WHEN Postal_Code IN ('NULL_ZIP', 'ABCDE', '0') OR Postal_Code IS NULL THEN 'UNKNOWN_ZIP' ELSE Postal_Code END AS [Postal_Code],
        CASE 
            WHEN [State] IN ('Kentucky', 'Tennessee') THEN 'North'
            WHEN [State] IN ('California', 'Washington', 'Oregon', 'Arizona', 'Nevada', 'Colorado', 'Utah', 'New Mexico', 'Idaho', 'Montana', 'Wyoming', 'Alaska', 'Hawaii') THEN 'West'
            WHEN [State] IN ('Texas', 'Florida', 'Georgia', 'North Carolina', 'South Carolina', 'Virginia', 'Louisiana', 'Alabama', 'Mississippi', 'Arkansas') THEN 'South'
            WHEN [State] IN ('New York', 'Pennsylvania', 'Massachusetts', 'New Jersey', 'Maryland', 'Connecticut', 'Delaware', 'Rhode Island', 'New Hampshire', 'Vermont', 'Maine') THEN 'East'
            WHEN [State] IN ('Illinois', 'Ohio', 'Michigan', 'Indiana', 'Wisconsin', 'Minnesota', 'Missouri', 'Iowa', 'Kansas', 'Oklahoma', 'Nebraska', 'North Dakota', 'South Dakota') THEN 'Central'
            ELSE 'Other'
        END AS [Region]
    FROM [dbo].[Super_Store]
),
TerritoryDedup AS (
    SELECT
        [City],
        [State],
        [Postal_Code],
        [Region],
        ROW_NUMBER() OVER (
            PARTITION BY [Postal_Code] 
            ORDER BY [City] ASC, [State] ASC 
        ) AS rn
    FROM TerritoryCleaned
)
SELECT
    [City],
    [State],
    [Postal_Code],
    [Region]
INTO DimTerritory
FROM TerritoryDedup
WHERE rn = 1;



WITH OrderDedup AS (
    SELECT
        Order_Id,
        TRY_CAST([Order_Date] AS DATE) AS [Order_Date],
        Source_System,
        ROW_NUMBER() OVER (
            PARTITION BY Order_Id
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM [dbo].[Super_Store]
    WHERE Order_Id IS NOT NULL
)
SELECT
    Order_Id,
    [Order_Date],
    Source_System
INTO DimOrder
FROM OrderDedup
WHERE rn = 1;



WITH ShipmentDedup AS (
    SELECT
        Ship_Mode,
        ROW_NUMBER() OVER (
            PARTITION BY Ship_Mode
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM [dbo].[Super_Store]
    WHERE Ship_Mode IS NOT NULL
)
SELECT
    Ship_Mode
INTO DimShipment
FROM ShipmentDedup
WHERE rn = 1;



SELECT 
    Order_Id,
    [Customer_ID],                 
    CASE WHEN Product_ID LIKE '%INVALID%' OR Product_ID IS NULL THEN 'UNKNOWN_PROD' ELSE Product_ID END AS [Product_ID],
    TRY_CAST([Order_Date] AS DATE)  AS [Order_Date], 
    TRY_CAST([Ship_Date]  AS DATE)  AS [Ship_Date],  
    TRY_CAST([Date_Entry] AS DATE)  AS [Date_Entry], 
    CASE WHEN Postal_Code IN ('NULL_ZIP', 'ABCDE', '0') OR Postal_Code IS NULL THEN 'UNKNOWN_ZIP' ELSE Postal_Code END AS [Postal_Code], -- Connects to DimTerritory
    Ship_Mode,
    Sales,
    CASE WHEN [Quantity] < 0 THEN 0 ELSE Quantity END AS Quantity,
    Discount,
    Profit
INTO FactSales
FROM [dbo].[Super_Store];