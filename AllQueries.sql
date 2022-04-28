/* TODO(lluc): Add file overview.
 *
 */
 
# Task 1.
WITH
  # Get product key for the product of interest.
  # Note: There are three product keys for this product: 212, 213, 214.
  # Only the last key is set as "current".
  Products AS (
    SELECT DISTINCT ProductKey
    FROM rullansabater.github.DimProduct
    WHERE ProductName = 'Sport-100 Helmet, Red'
  ),
  ResellerSales AS (
    SELECT DISTINCT
      ProductKey,
      SalesAmount,
      DATE(OrderDate) AS OrderDate,
      EXTRACT(MONTH FROM OrderDate) AS `Month`,
    FROM rullansabater.github.FactResellerSales
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
    FROM ResellerSales
    # Do `INNER JOIN` to keep only data for the product of interest.
    INNER JOIN Products
      ON ResellerSales.ProductKey = Products.ProductKey
  )
SELECT `Month`, SalesAmount, OrderDate
FROM SubsetSales
WHERE SubsetSales.rank_ = 1
ORDER BY SubsetSales.`Month` ASC;

# Task 2.

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

# Task 5.
