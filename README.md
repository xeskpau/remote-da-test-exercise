
# Remote.com ─ Data Analyst Test Exercise

## Goal

As a part of the interview process for a Data Analyst position at Remote.com, we want to **provide a solution to 5 data analysis tasks and 3 data visualization**.


## Data overview

Remote.com has shared a spreadsheet with 7 sheets of raw data (see file `Data Analyst Assignment.xlsx`). Each sheet can be considered a separate data table, and their content is summarized as follows (see  section ***Scoping*** below for more information) ─

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

**Findings and notes:**
* The highest transactions for the product  "Sport-100 Helmet, Red" seem to occur in the last 4 days of the month (28th, 29th, 30th, or 31st). Understanding the patterns in our customers' larger purchases can help us better staff our stores and warehouses. As a follow-up exercise, we could look into whether this is a pattern that is prevalent across products, and whether this can help us improve our business operations.
* For a given `ProductName`, there are multiple `ProductKey` values, only one of which has a value of `Status = 'current'`. For `ProductName = 'Sport-100 Helmet, Red'`, there are three keys `212`, `213`, and `214`. The query for this task consolidates all `ProductKey` values under the name `ProductName`.

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

**Assumption:**
 * The prompt is requesting to (1) calculate the lowest revenue-generating product **globally** at **monthly level** in 2012; and (2) for each product, **break down its monthly sales by country**. *For example, in January we might find that product "X" had the lowest global revenue with 100€, which was distributed across US (50€), UK (40€), and France (10€).*
 * An alternative interpretation (which is not addressed here) is that the prompt might be requesting us only to calculate the lowest revenue-generating product by **country for each month in 2012**. *For example, in January we might find that product "X" had the lowest revenue in France (10€).*

**Findings and notes:**
*  The product "LL Headset" had the lowest global sales for the first three months of 2012, and also in the fifth month of the year.
*  "Half-" and "Full-Finger Gloves" of different sizes ("S" and "L") had the lowest global sales during a total of five months of 2012.
*  "LL Road Frame - Red, 52" and "LL Road Seat/Saddle" had the lowest global sales during one month of 2012 each, and they were the only two products the sales of which came from a single country (in both cases, "United States").
*  "LL Road Seat/Saddle" was the product that had the lowest global sales within a single month during 2012: $16.27.

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

**Findings:**
*  Surprisingly, there is no data for the "Forecast Scenario". This might be explained due to actual data already being available, leading to the forecast no longer being relevant (there is possibly no need for its data to be stored).
*  "Assets" and "Liabilities" have the same values. The relationship that related these these two items is `Assets − Liabilities = Equity`. In this case, `Assets = Liabilities`, which suggests that the (un)tangibles owned by the company (i.e. assets) are equal to what the company owes (i.e. liabilitie). As such, the company does not have equity.
*  As for "Revenue", actuals are greater than the budget, which means that the company exceeded expectations. Similarly, for "Expenditures", the actuals exceed expectations, since the actual expenditures were lower than the budgeted expenditures.
*  Finally, "Flow" and "Balances" are positive, which means that overall the company had liquidity.

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

**Assumption:**
 * The prompt is requesting to find all historical data for products that had any sales in 2012. As such, we will show all months of data for any product that had sales during 2012. This means that if a product had sales at any time in 2012, I would present their sales across all history (e.g. 2011, 2013,...).
 * An alternative interpretation (which is not addressed here) is that the prompt might be requesting us only to find data in 2012 (i.e. 12 months only) for products with sales, and their monthly sales breakdown. Here, we would show all months of data for any product that had sales during 2012. This means that we would only present the sales of the product in the year 2012.

**Findings:**
* See the query for details on sales amount on a product basis.
* The `ProductKey = 293` is found in the `FactReellerSales` data, but not in the `DimProduct` table.

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

**Findings:**
  
* There are no customers in the category "Age <35". In the data visualization exercise "Task 8", users can tweak the lower and upper age bounds for the three categories (currently, the lower age bound is 35, and the upper age bound is 50).
* A large fraction of customers (5266 of 18484; 28%) are "Married" and "Male".
* More "Women" are "Single" in the category "Age between 35-50" (2494 of 4338; 57%), and more "Women" are "Married" in the category "Age >50" (2819 of 4745; 59%).

## Visualization tasks

The three data visualization tasks have been addressed via a Tableau Public dashboard, which is [available here](https://public.tableau.com/app/profile/lluc.rullan.sabater/viz/LRSGitHubDAHomeTestExercise/Dashboard) (note: the dashboard is not directly searchable, and only available with the direct link).
  
<details>
  <summary>💡 🖱 Click to see a preview of the Tableau dashboard!</summary>
<div class='tableauPlaceholder' id='viz1651171584582' style='position: relative'><noscript><a href='#'><img alt=' ' src='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;LR&#47;LRSGitHubDAHomeTestExercise&#47;Dashboard1&#47;1_rss.png' style='border: none' /></a></noscript><object class='tableauViz'  style='display:none;'><param name='host_url' value='https%3A%2F%2Fpublic.tableau.com%2F' /> <param name='embed_code_version' value='3' /> <param name='site_root' value='' /><param name='name' value='LRSGitHubDAHomeTestExercise&#47;Dashboard1' /><param name='tabs' value='yes' /><param name='toolbar' value='yes' /><param name='static_image' value='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;LR&#47;LRSGitHubDAHomeTestExercise&#47;Dashboard1&#47;1.png' /> <param name='animate_transition' value='yes' /><param name='display_static_image' value='yes' /><param name='display_spinner' value='yes' /><param name='display_overlay' value='yes' /><param name='display_count' value='yes' /><param name='language' value='en-GB' /></object></div>   

</details>

### Task 6

**Prompt:**
<details>
  <summary>💡 🖱 Click to expand the prompt!</summary>
  
> Based on your results for question #2 above, create a visualization to highlight the sales territories with the lowest sales performances. Are there any territories with consistent low sales performance over time?
</details>

**Findings:**
*  TODO(lluc): Fill out.

### Task 7

**Prompt:**
<details>
  <summary>💡 🖱 Click to expand the prompt!</summary>
  
> Create a visualization based on your results for question #3 above, so that the user can switch between scenarios and account types. Please explain what insight can we gain from these results.
</details>

**Findings:**
*  TODO(lluc): Fill out.

### Task 8

**Prompt:**
<details>
  <summary>💡 🖱 Click to expand the prompt!</summary>
  
> Create a visualization based on your results for question #5 above. Please explain what insight can we gain from these results.
</details>

**Findings:**
*  TODO(lluc): Fill out.
