
# GitHub ─ Data Analyst Test Exercise


## Goal

As a part of the interview process for a Data Analyst position at GitHub, we want to **provide a solution to 5 data analysis tasks and 3 data visualization**.


## Data overview

GitHub has shared a spreadsheet with 7 sheets of raw data (see file `Data Analyst Assignment.xlsx`; #TODO: Attach file). Each sheet can be considered a separate data table, and their content is summarized as follows (see  section ***Scoping*** below for more information; #TODO: Add link to Scoping.) ─

| # | Table name | Primary key | Candidate key | Comment |
|:--:|:--:|:--:|:--:|:--:|
| 1 | **DimAccounts** | `AccountKey` | ─ | Contains **account** info|
| 2 | **DimCustomer** | `CustomerKey` | `CustomerAlternateKey` | Contains **customer** info |
| 3 | **DimProduct** | `ProductKey` | `ProductAlternateKey` | Contains **product** info |
| 4 | **DimSalesTerritory** | `SalesTerritoryKey` | `SalesTerritory AlternateKey` | Contains **territory** ("geo") info |
| 5 | **DimScenario** | `ScenarioKey` | ─ | Contains **finance scenario** ("geo") info |
| 6 | **FactFinance** | `FinanceKey` | ─ | Contains financial data at account level by scenario|
| 7 | **FactResellerSales** | `ProductKey ` & `SalesOrderNumber` | ─ | Contains detailed sales data |



## Analytical tasks

### Scoping

#### Primary key

The analytical tasks were resolved using SQL by importing the data from its original `xlsx` format into BigQuery, and using "schema autodetect" to recognize the field data types automatically.

The candidate keys for each table were determined replacing the fields into the query below. If the query returns results, then the field is not a primary key because (a) its values do not identify a unique row, or (b) it contains `NULL` values.

<details>
  <summary>💡 🖱 Click to expand the SQL query!</summary>
  
```sql
# If the query returns any results, the ${FIELD_NAME}
# is not a candidate key.
SELECT
  ${FIELD_NAME} AS my_potential_key,
  COUNT(*) AS num_records
FROM ${TABLE_NAME}
GROUP BY 1
HAVING
  # All values in ${FIELD_NAME} are unique.
  COUNT(*) > 1
  # There are no NULL values in ${FIELD_NAME}
  OR my_potential_key IS NULL;
```
</details>

  
All tables contain at least one column that uniquely identifies each row, except the table **FactResellerSales**, which has a composite key: each record is uniquely identified by a combination of the fields `ProductKey` and  `SalesOrderNumber`.

#### Data schema and entity-relation diagram 

After identifying the keys for each table, we can establish the entity-relation diagram. Out of the seven tables, we can establish the following relationships:

* **FactResellerSales**, **DimProduct**, **DimSalesTerritory**; 
* **FactFinance**, **DimAccounts**, **DimScenario**;
* **DimCustomer**.

Below, you can **click** to expand the entity-relation diagram. For higher resolution, please see follow [this link](https://dbdiagram.io/d/6265a7091072ae0b6adcc459) to DB Diagram, which shows the tables with their fields, datatypes, and join keys.

<details>
  <summary>💡 🖱 Click to expand the entity-relation diagram!</summary>
  
![Entity-relation diagram](https://i.imgur.com/EFtXnqO.png)
</details>


### Task 1

**Prompt:**
<details>
  <summary>💡 🖱 Click to expand the prompt!</summary>
  
>  Find the highest transaction of each month in **2012** for the product **Sport-100 Helmet, Red**.
> 
> **Expected Output Columns:**
> | Month | SalesAmount | OrderDate
> |:--:|:--:|:--:|
>
>**Notes:**
> 
> -   Do not use `MAX()` SQL function
> -   Tables containing the information are _DimProduct, FactResellerSales_

</details>


### Task 2

**Prompt:**
<details>
  <summary>💡 🖱 Click to expand the prompt!</summary>
  
> Find the lowest revenue-generating product for each month in **2012**. Include the **Sales Territory Country** as well.
>
> **Expected Output Columns:**
> | Month | SalesTerritoryCountry | ProductName | SalesAmount
> |:--:|:--:|:--:|:--:|
>
> **Notes:**
> 
> -   Tables containing the information are _DimProduct, DimSalesTerritory, FactResellerSales_
> 
</details>

### Task 3


**Prompt:**
<details>
  <summary>💡 🖱 Click to expand the prompt!</summary>
  
> Find the Average Finance Amount for each **Scenario (Actual Scenario, Budget Scenario, Forecast Scenario)** for each **Account Type (Assets, Balances, Liabilities, Flow, Expenditures, Revenue)** in **2011.**
>
> **Expected Output Columns:**
> | AccountType | ActualScenario | BudgetScenario | ForecastScenario
> |:--:|:--:|:--:|:--:|
>
> **Notes:**
>
> -   Tables containing the information are _DimScenario, DimAccount, FactFinance_
</details>

### Task 4


**Prompt:**
<details>
  <summary>💡 🖱 Click to expand the prompt!</summary>
  
> Find all the products and their Total Sales Amount by Month of order which does have sales in **2012.**
>
> **Expected Output Columns:**
> | ProductKey | SalesAmount | OrderMonth
> |:--:|:--:|:--:|
>
>**Notes:**
>
> -   Tables containing the information are _DimProduct, FactResellerSales_
</details>

### Task 5


**Prompt:**
<details>
  <summary>💡 🖱 Click to expand the prompt!</summary>
  
> Write a query to find the age of customers. Bucket them under
>
> **Age Group**:
>
> -   Less than 35
> -   Between 35 and 50
> -   Greater than 50
>
> Segregate the Number of Customers in each age group on **Marital Status** and **Gender**.
>
> **Expected Output Columns**
> | MaritalStatus | Gender | Age <35 | Age between 35-50 | Age > 50
> |:--:|:--:|:--:|:--:|:--:|
> 
> **Notes**
>
> -   Table containing the information is _DimCustomer_
</details>


## Visualization tasks

### Task 6

**Prompt:**
<details>
  <summary>💡 🖱 Click to expand the prompt!</summary>
  
> Based on your results for question #2 above, create a visualization to highlight the sales territories with the lowest sales performances. Are there any territories with consistent low sales performance over time?
</details>

### Task 7

**Prompt:**
<details>
  <summary>💡 🖱 Click to expand the prompt!</summary>
  
> Create a visualization based on your results for question #3 above, so that the user can switch between scenarios and account types. Please explain what insight can we gain from these results.
</details>

### Task 8

**Prompt:**
<details>
  <summary>💡 🖱 Click to expand the prompt!</summary>
  
> Create a visualization based on your results for question #5 above. Please explain what insight can we gain from these results.
</details>
