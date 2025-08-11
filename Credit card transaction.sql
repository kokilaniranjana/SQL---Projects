create database Transactions;

use transactions;

select * from credit_card_transactions;

RENAME TABLE credit_card_transcations TO credit_card_transactions;

ALTER TABLE credit_card_transactions ADD COLUMN transaction_date_backup VARCHAR(20);
UPDATE credit_card_transactions SET transaction_date_backup = transaction_date;

UPDATE credit_card_transactions
SET transaction_date = DATE_FORMAT(STR_TO_DATE(transaction_date, '%d-%b-%y'), '%Y%m%d');

ALTER TABLE credit_card_transactions
MODIFY COLUMN transaction_date date;

-- Total Spend by City 
SELECT city, SUM(amount) AS total_spent FROM credit_card_transactions GROUP BY city ORDER BY total_spent DESC; 

-- Monthly Spend Trend 
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS month, SUM(amount) AS total_amount 
FROM credit_card_transactions  GROUP BY month ORDER BY month; 

-- Expense Type Distribution 
SELECT exp_type, COUNT(*) AS txn_count, SUM(amount) AS total_spend 
FROM credit_card_transactions GROUP BY exp_type ORDER BY total_spend DESC; 

-- Gender-wise Spending 
SELECT gender, COUNT(*) AS txn_count, SUM(amount) AS total_spend 
FROM credit_card_transactions GROUP BY gender;

-- Card Type Performance 
SELECT card_type, COUNT(*) AS txn_count, AVG(amount) AS avg_spend 
FROM credit_card_transactions GROUP BY card_type;

-- top 5 cities with highest spends and their percentage contribution of total credit card spends 

select city, sum(amount) as total_spend, round(sum(amount)*100.0/ (select sum(amount) from credit_card_transactions),2) as highest_spend from
credit_card_transactions
group by city order by total_spend desc limit 5;

-- write a query to print highest spend month for each year and amount spent in that month for each card type
WITH cte1 as(
	SELECT card_type, YEAR(transaction_date) year,
	MONTH(transaction_date) month, SUM(amount) as total_spend
	FROM credit_card_transactions
	GROUP BY card_type, YEAR(transaction_date), MONTH(transaction_date)
), cte2 as(
	SELECT *, DENSE_RANK() OVER(PARTITION BY card_type ORDER BY total_spend DESC) as rn
	FROM cte1
)
SELECT *
FROM cte2 where rn=1;

-- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
    
    WITH equ1 as(
  SELECT *, SUM(amount) OVER(PARTITION BY card_type ORDER BY transaction_date, transaction_id) as total_spend
  FROM credit_card_transactions
), cte2 as(
  SELECT *, DENSE_RANK() OVER(PARTITION BY card_type ORDER BY total_spend) as rn  
  FROM equ1 WHERE total_spend >= 1000000
)
SELECT *
FROM cte2
WHERE rn=1;

-- write a query to find city which had lowest percentage spend for gold card type
select city, round(sum(amount)*100.0/ (select sum(amount) from credit_card_transactions),2) 
as lowest_percentage from credit_card_transactions where card_type="gold" order by lowest_percentage asc limit 1;

-- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

SELECT
    city,
    MAX(CASE WHEN amount = max_amount THEN exp_type END) AS highest_expense_type,
    Min(CASE WHEN amount = min_amount THEN exp_type END) AS lowest_expense_type
FROM (
    SELECT 
        city,
        exp_type,
        amount,
        MAX(amount) OVER (PARTITION BY city) AS max_amount,
        MIN(amount) OVER (PARTITION BY city) AS min_amount
    FROM credit_card_transactions
) exp
GROUP BY city;

-- write a query to find percentage contribution of spends by females for each expense type
select * from credit_card_transactions;
select exp_type, 
round(sum(case when gender="f" then amount else 0 end)*100.0/ sum(amount) ,2) as percentage from credit_card_transactions
group by exp_type order by percentage desc;


-- during weekends which city has highest total spend to total no of transcations ratio
SELECT city , SUM(amount)*1.0/COUNT(1) as ratio
FROM credit_card_transactions
WHERE DAYNAME(transaction_date) in ('Saturday','Sunday')
GROUP BY city
ORDER BY ratio DESC
LIMIT 1;

-- which city took least number of days to reach its 500th transaction after the first transaction in that city
WITH city_txn_ordered AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY city ORDER BY transaction_date, transaction_id) AS txn_no
    FROM credit_card_transactions
),
city_500th_txn AS (
    SELECT city,
           MIN(CASE WHEN txn_no = 1 THEN transaction_date END) AS first_date,
           MIN(CASE WHEN txn_no = 500 THEN transaction_date END) AS txn_500_date
    FROM city_txn_ordered
    GROUP BY city
    HAVING txn_500_date IS NOT NULL
)
SELECT city,
       DATEDIFF(txn_500_date, first_date) AS days_to_500
FROM city_500th_txn
ORDER BY days_to_500
LIMIT 1;





