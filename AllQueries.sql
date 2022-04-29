/* TODO(lluc): Add file overview.
 *
 */
 
# Task 1.
WITH
  # Get product key for the product of interest.
  # Note: There are three product keys for this product:
  #       212, 213, 214. Only the last key is set as "current".
  Products AS (
    SELECT DISTINCT ProductKey
    FROM rullansabater.remote.DimProduct
    WHERE ProductName = 'Sport-100 Helmet, Red'
  ),
  ResellerSales AS (
    SELECT DISTINCT
      ProductKey,
      SalesAmount,
      DATE(OrderDate) AS OrderDate,
      EXTRACT(MONTH FROM OrderDate) AS `Month`,
    FROM rullansabater.remote.FactResellerSales
    WHERE EXTRACT(YEAR FROM OrderDate) = 2012
  ),
  SubsetSales AS (
    SELECT
      ResellerSales.`Month`,
      ResellerSales.SalesAmount,
      ResellerSales.OrderDate,
      # Rank the transactions based on sales amount and
      # partitioning by month.
      RANK() OVER (
        PARTITION BY ResellerSales.`Month`
        ORDER BY SalesAmount DESC) AS rank_
    # Use `INNER JOIN` to keep only data for the product
   # of interest, and no other records from either table.
    FROM ResellerSales
    INNER JOIN Products
      ON ResellerSales.ProductKey = Products.ProductKey
  )
SELECT `Month`, SalesAmount, OrderDate
FROM SubsetSales
WHERE SubsetSales.rank_ = 1
ORDER BY SubsetSales.`Month` ASC;

# Task 2.
WITH
  Products AS (
    SELECT DISTINCT ProductKey, ProductName
    FROM rullansabater.remote.DimProduct
  ),
  Territories AS (
    SELECT DISTINCT SalesTerritoryKey, SalesTerritoryCountry
    FROM rullansabater.remote.DimSalesTerritory
  ),
  # Get monthly sales by product & territory.
  ProductTerritorySalesMonthly AS (
    SELECT
      ProductKey,
      SalesTerritoryKey,
      EXTRACT(MONTH FROM OrderDate) AS `Month`,
      SUM(SalesAmount) AS SalesAmount,
    FROM rullansabater.remote.FactResellerSales
    WHERE EXTRACT(YEAR FROM OrderDate) = 2012
    GROUP BY 1, 2, 3
  ),
  # Get monthly sales by product.
  ProductSalesMonthly AS (
    SELECT
      ProductKey,
      `Month`,
      SUM(SalesAmount) AS SalesAmount,
    FROM ProductTerritorySalesMonthly
    GROUP BY 1, 2
  ),
  # Rank monthly sales by product & territory.
  RankedProductSalesMonthly AS (
    SELECT
      ProductKey,
      `Month`,
      RANK() OVER (
        PARTITION BY `Month`
        ORDER BY SalesAmount ASC  # Lowest sales.
        ) AS rank_
    FROM ProductSalesMonthly
  )
SELECT
  Sales.`Month`,
  Territories.SalesTerritoryCountry,
  Products.ProductName,
  SUM(Sales.SalesAmount) AS SalesAmount,
FROM RankedProductSalesMonthly AS Ranked
LEFT JOIN ProductTerritorySalesMonthly AS Sales
  ON
    Ranked.ProductKey =  Sales.ProductKey
    AND Ranked.`Month` =  Sales.`Month`
LEFT JOIN Products
  ON Sales.ProductKey = Products.ProductKey
LEFT JOIN Territories
  ON Sales.SalesTerritoryKey = Territories.SalesTerritoryKey 
# Keep only lowest performing product (i.e. first ranked).
WHERE Ranked.rank_ = 1
GROUP BY 1, 2, 3
ORDER BY `Month` ASC, 2, 3;

# Task 3.
WITH
  # TODO: Review, because the AccountType field contains NULL values.
  # There is only 1 NULL value, which is for `AccountKey = 1`.
  Accounts AS (
    SELECT DISTINCT AccountKey, AccountType
    FROM rullansabater.github.DimAccounts
  ),
  Scenarios AS (
    SELECT DISTINCT ScenarioKey, ScenarioName
    FROM rullansabater.github.DimScenario
  ),
  # TODO: Review, because the AccountType field contains NULL values.
  # Note: `ScenarioKey = 3` (i.e. "Forecast") does not exist.
  Finance AS (
    SELECT ScenarioKey, AccountKey, SUM(Amount) AS FinanceAmount
    FROM rullansabater.github.FactFinance
    WHERE LEFT(CAST(DateKey AS STRING), 4) = '2011'
    GROUP BY 1, 2
  ),
  # Note: The operation below can be done more simply with a PIVOT.
  # However, this function is not available in all SQL implementations.
  # As such, here we are apply a more lengthy solution that will work
  # across SQL dialects.
  # Similarly, a table-valued function (TVF) might help us reduce the
  # redundancy in the code below. However, TVFs are not available
  # across dialects.
  FinanceScenarios AS (
    SELECT
      COALESCE(
        FinanceActual.AccountKey,
        FinanceBudget.AccountKey,
        FinanceForecast.AccountKey) AS AccountKey,
      SUM(FinanceActual.FinanceAmount) AS ActualScenario,
      SUM(FinanceBudget.FinanceAmount) AS BudgetScenario,
      SUM(FinanceForecast.FinanceAmount) AS ForecastScenario
    FROM Scenarios
    LEFT JOIN Finance AS FinanceActual
      ON Scenarios.ScenarioKey = FinanceActual.ScenarioKey
      AND Scenarios.ScenarioName = 'Actual'
    LEFT JOIN Finance AS FinanceBudget
      ON Scenarios.ScenarioKey = FinanceBudget.ScenarioKey
      AND Scenarios.ScenarioName = 'Budget'
    LEFT JOIN Finance AS FinanceForecast
      ON Scenarios.ScenarioKey = FinanceForecast.ScenarioKey
      AND Scenarios.ScenarioName = 'Forecast'
    GROUP BY 1
  )
# Note: Interestingly "Assets" and "Liabilities" have the same value for
# the ActualScenario.
SELECT
  IFNULL(Accounts.AccountType, 'Account type not set') AS AccountType,
  SUM(ActualScenario) AS ActualScenario,
  SUM(BudgetScenario) AS BudgetScenario,
  SUM(ForecastScenario) AS ForecastScenario,
FROM FinanceScenarios
LEFT JOIN Accounts
  ON FinanceScenarios.AccountKey = Accounts.AccountKey
GROUP BY 1
ORDER BY 1 DESC;

# Task 4.
# Note:
#   Please see the assumption in the README document.
#   The query below will show all historical sales for
#   products that had sales in 2012.
#   Since we need the `OrderMonth` as an output column,
#   the output field `SalesAmount` may contain data
#   aggregated across multiple years (e.g. Jan'12,
#   Jan'13,... which all correspond to `OrderMonth = 1`).
WITH
  Products AS (
    SELECT DISTINCT
      ProductKey,
      # Obtain the current product key for the product.
      # For example, `ProductKey IN (212, 213, 214) all
      # correspond to the same product. By doing this we
      # will consolidate the SalesAmount of all the product
      # keys that correspond to the same product.
      FIRST_VALUE(ProductKey) OVER (
        PARTITION BY ProductAlternateKey
        ORDER BY Status ASC
        ) AS CurrentProductKey,
    FROM rullansabater.github.DimProduct
  ),
  Sales AS (
    SELECT
      ProductKey,
      EXTRACT(YEAR FROM OrderDate) AS OrderYear,
      EXTRACT(MONTH FROM OrderDate) AS OrderMonth,
      SUM(SalesAmount) AS SalesAmount,
    FROM rullansabater.github.FactResellerSales
    GROUP BY 1, 2, 3
  ),
  # Get the list of ProductKey values with any sales in 2012.
  SalesIn2012 AS (
    SELECT ProductKey
    FROM Sales
    WHERE OrderYear = 2012
    GROUP BY 1
    HAVING SUM(SalesAmount) > 0
  )
  SELECT
    # Note
    #   The Products table is not complete. For example, 
    #   does not contain #293. To circument this issue,
    #   we use `COALESCE()` and we will not lose any sales data.
    COALESCE(Products.CurrentProductKey, Sales.ProductKey) AS ProductKey,
    SUM(Sales.SalesAmount) AS SalesAmount,
    Sales.OrderMonth,
  FROM Sales
  LEFT JOIN Products
    ON Sales.ProductKey = Products.ProductKey
  # Keep only products with sales in 2012.
  WHERE Sales.ProductKey IN (SELECT ProductKey FROM SalesIn2012)
  GROUP BY 1, 3
  ORDER BY 1, 3, 2;

# Task 5.
# TODO: write findings in README.
# Findings: Min age is 36 and max age is 106.
# We should probably adjust the buckets so that 
# there is a roughly equal distribution.
# See the data viz task for this.

WITH
  # Note: Birthday is in format "DD/MM/YY", automatically interpreted as string.
  # Note: MaritalStatus and Gender contain only 2 values each.
  Customers AS (
    SELECT
      MaritalStatus,
      Gender,
      # Difference in years between today and the customer's birthday.
      DATE_DIFF(
        CURRENT_DATE(),
        # Convert the `birthdate` field from `DD/MM/YY` to `YYYY-MM-DD`.
        # TODO: Assumption is all are born in 20th century.
        DATE(CONCAT('19', RIGHT(birthdate, 2), '-', SUBSTR(birthdate, 4, 2), '-', LEFT(birthdate, 2))),
        YEAR) AS age,
    FROM rullansabater.github.DimCustomer
  ),
  CustomerGroups AS (
    SELECT
      MaritalStatus,
      Gender,
      age < 35 AS is_lower_age,
      age BETWEEN 35 AND 50 AS is_middle_age,
      age > 50 AS is_upper_age,
      COUNT(*) AS num_customers
    FROM Customers
    GROUP BY 1, 2, 3, 4, 5
  ),
  # Transform data to desired format.
  # Note: PIVOT not available in all SQL implementations.
  CustomerGroupsPivot AS (
    SELECT 
      MaritalStatus, 
      Gender, 
      num_customers AS `Age <35`,
      0.0 AS `Age between 35-50`,
      0.0 AS `Age > 50`
    FROM CustomerGroups
    WHERE is_lower_age
    UNION ALL
    SELECT 
      MaritalStatus, 
      Gender, 
      0.0 AS `Age <35`,
      num_customers AS `Age between 35-50`,
      0.0 AS `Age > 50`
    FROM CustomerGroups
    WHERE is_middle_age
    UNION ALL
    SELECT 
      MaritalStatus, 
      Gender, 
      0.0 AS `Age <35`,
      0.0 AS `Age between 35-50`,
      num_customers AS `Age > 50`
    FROM CustomerGroups
    WHERE is_upper_age
  )
SELECT
  MaritalStatus,
  Gender,
  SUM(`Age <35`) AS `Age <35`,
  SUM(`Age between 35-50`) AS `Age between 35-50`,
  SUM(`Age > 50`) AS `Age > 50`
FROM CustomerGroupsPivot
GROUP BY 1, 2
ORDER BY 1, 2;
