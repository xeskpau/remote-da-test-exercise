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

# Task 4.

# Task 5.
