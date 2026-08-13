-- Number of inventory copies per store
SELECT 
	address.address AS Store_Address,
	store.store_id  AS Store_ID,
	COUNT(inventory.inventory_id) AS Inventory_Count
FROM store

LEFT JOIN inventory
ON store.store_id = inventory.store_id

LEFT JOIN address
ON store.address_id = address.address_id

GROUP BY address.address_id,store.store_id
ORDER BY Inventory_Count DESC;

--HAVEN'T BEEN RETURNED
SELECT 
	rental.rental_date,
	film.title,
	address.address,
	CONCAT(staff.first_name || ' ' || staff.last_name) AS Staff_Member,
	CONCAT(customer.first_name || ' ' || customer.last_name) AS Customer
FROM rental

LEFT JOIN inventory
	ON rental.inventory_id = inventory.inventory_id

LEFT JOIN film
	ON inventory.film_id = film.film_id

INNER JOIN staff
	ON rental.staff_id = staff.staff_id

INNER JOIN customer
	ON rental.customer_id = customer.customer_id

INNER JOIN store
	ON inventory.store_id = store.store_id

INNER JOIN address
ON store.address_id = address.address_id

WHERE return_date IS NULL
ORDER BY rental.rental_date ASC;

--checking if film.rental_duration stands for time allowed for this film being rented
SELECT 
	film.title AS Movie_Title,
	film.rental_duration AS Duration_Allowed,
	COUNT(rental.rental_id) AS Times_Rented,
	--rental.rental_date AS Start_Rent,
	--rental.return_date AS End_Rent,
	AVG(EXTRACT(EPOCH FROM (rental.return_date - rental.rental_date))) / 86400 AS Time_Rented
FROM film

LEFT JOIN inventory
	ON film.film_id = inventory.film_id

LEFT JOIN rental
	ON inventory.inventory_id = rental.inventory_id

GROUP BY film.title,film.rental_duration
ORDER BY Times_Rented DESC;

--most rented categories
SELECT
	category.name AS Movie_Category,
	COUNT(DISTINCT film.film_id) AS Movie_Count,
	COUNT(DISTINCT inventory.inventory_id) AS Copies_for_Rent,
	COUNT(DISTINCT rental.rental_id) AS Rent_Count,
	SUM(payment.amount) AS Earned
FROM category

LEFT JOIN film_category
	ON category.category_id = film_category.category_id

LEFT JOIN film
	ON film_category.film_id = film.film_id

LEFT JOIN inventory
	ON film.film_id = inventory.film_id

LEFT JOIN rental
	ON inventory.inventory_id = rental.inventory_id

LEFT JOIN payment
	ON rental.rental_id = payment.rental_id

GROUP BY category.name
ORDER BY Earned DESC;

--movie language
SELECT
	film.title AS Movie,
	l1.name AS Movie_Language,
	l2.name AS Original_Language
FROM film

LEFT JOIN language l1
	ON film.language_id = l1.language_id
LEFT JOIN language l2
	ON film.original_language_id = l2.language_id;

--language copies
SELECT
	l.name,
	COUNT(inventory.inventory_id) AS Language_Copies,
	ROUND((100.0 * COUNT(inventory.inventory_id) / (SELECT COUNT(inventory_id) FROM inventory)),2) AS Language_Percentage
FROM "language" l

LEFT JOIN film
	ON l.language_id = film.language_id

LEFT JOIN inventory
	ON film.film_id = inventory.film_id

GROUP BY l.name;

--Correlation between amounts of copies of movies by language
SELECT
	l.name AS Language,
	COUNT(DISTINCT inventory.inventory_id) AS Language_Copies,
	ROUND((100.0 * COUNT( DISTINCT inventory.inventory_id) / (SELECT COUNT(inventory_id) FROM inventory)),2) AS Language_Percentage,
	SUM(payment.amount) AS Revenue,
	ROUND((100.0 * SUM(payment.amount) / (SELECT SUM(amount) FROM payment)),2) AS Revenue_Percentage,
	COUNT(DISTINCT rental.rental_id) AS Amount_Of_Rants,
	ROUND((100.0 * COUNT(DISTINCT rental.rental_id) / (SELECT COUNT(rental_id) FROM rental)),2) AS Rental_Percentage
FROM "language" l

LEFT JOIN film
	ON l.language_id = film.language_id

LEFT JOIN inventory
	ON film.film_id = inventory.film_id

LEFT JOIN rental
	ON inventory.inventory_id = rental.inventory_id

LEFT JOIN payment
	ON rental.rental_id = payment.rental_id

GROUP BY l.language_id;

--customers by amount of rents and overall payments of theirs
SELECT
	CONCAT(customer.first_name || ' ' || customer.last_name) AS Customer_Name,
	COUNT (rental.rental_id) AS Rents_Amount,
	SUM(payment.amount) AS Revenue
FROM customer

LEFT JOIN rental
	ON customer.customer_id = rental.customer_id

LEFT JOIN payment
	ON rental.rental_id = payment.rental_id

GROUP BY customer.customer_id
ORDER BY Rents_Amount DESC;

--percentages of people returning rented movies in time
SELECT 
	CONCAT(customer.first_name || ' ' || customer.last_name) AS Customer_Name,
	COUNT (rental.rental_id) AS Rents_Amount,
	SUM(CASE
			WHEN rental.return_date IS NOT NULL AND
			((EXTRACT(EPOCH FROM (rental.return_date - rental.rental_date))) / 86400) <= film.rental_duration THEN 1
			ELSE 0
		END) AS In_Time,
	
	ROUND((SUM(CASE
			WHEN rental.return_date IS NOT NULL AND
			((EXTRACT(EPOCH FROM (rental.return_date - rental.rental_date))) / 86400) <= film.rental_duration THEN 1
			ELSE 0
		END)) * 100.0 / NULLIF(COUNT(rental.rental_id), 0),2) AS Percentage_In_Time
FROM customer

LEFT JOIN rental
ON customer.customer_id = rental.customer_id

LEFT JOIN inventory
ON rental.inventory_id = inventory.inventory_id

LEFT JOIN film
ON inventory.film_id = film.film_id

GROUP BY customer.customer_id
ORDER BY Percentage_In_Time DESC;

--each movie missing with amount and sum of replacement cost
SELECT 
	film.title AS Movie,
	COUNT(film.film_id) AS Number_Of_Missing,
	SUM(film.replacement_cost) AS Replacement_Cost
FROM rental

INNER JOIN inventory
	ON rental.inventory_id = inventory.inventory_id

INNER JOIN film
	ON inventory.film_id = film.film_id



WHERE rental.return_date IS NULL
GROUP BY film.film_id
ORDER BY Number_Of_Missing DESC;

--OVERALL replacement cost
SELECT SUM(Replacement_Cost) FROM
(SELECT 
	film.title AS Movie,
	COUNT(film.film_id) AS Number_Of_Missing,
	SUM(film.replacement_cost) AS Replacement_Cost
FROM rental

INNER JOIN inventory
	ON rental.inventory_id = inventory.inventory_id

INNER JOIN film
	ON inventory.film_id = film.film_id



WHERE rental.return_date IS NULL
GROUP BY film.film_id
ORDER BY Number_Of_Missing DESC);


--missing by category

SELECT 
	category.name AS Category,
	COUNT(rental.rental_id) AS Number_Of_Missing
	--SUM(film.replacement_cost) AS Replacement_Cost
FROM rental

left JOIN inventory
	ON rental.inventory_id = inventory.inventory_id

left JOIN film_category
	ON inventory.film_id = film_category.film_id

left JOIN 	category
	ON film_category.category_id = category.category_id

WHERE rental.return_date IS NULL
GROUP BY category.category_id
ORDER BY Number_Of_Missing DESC;

--rents by month
SELECT 
	DATE_TRUNC('month', rental_date) AS Rent_Month,
	COUNT(rental_id) AS Amount
FROM rental

GROUP BY DATE_TRUNC('month', rental_date)
ORDER BY Rent_Month;

--actors that bring the most money
SELECT
	CONCAT(actor.first_name || ' ' || actor.last_name) AS Actor_Name,
	COUNT(DISTINCT film.film_id) AS Movies_Featured,
	SUM(payment.amount) AS Revenue_of_Featured_Movies,
	SUM(payment.amount)/COUNT(DISTINCT film.film_id) AS Average_Revenue_per_Movie
FROM actor

LEFT JOIN film_actor
	ON actor.actor_id = film_actor.actor_id

INNER JOIN film
	ON film_actor.film_id = film.film_id

LEFT JOIN inventory
	ON film.film_id = inventory.film_id

LEFT JOIN rental 
	ON inventory.inventory_id = rental.inventory_id

LEFT JOIN payment
	ON rental.rental_id = payment.rental_id

GROUP BY actor.actor_id
ORDER BY Revenue_of_Featured_Movies DESC;

--customer address, latest rent, rent location


SELECT 
	CONCAT(customer.first_name || ' ' || customer.last_name) AS Customer,
	country2.country AS Customer_Country,
	city2.city AS Customer_City,
	a2.address AS Customer_Address,
	rental.rental_date AS Last_Rented,
	country1.country AS Store_Country,
	city1.city AS Store_City,
	a1.address AS Store_Address
FROM (
    SELECT
        customer_id,
        MAX(rental_id) AS latest_rental_id
    FROM rental
    GROUP BY customer_id
)  AS latest --latest rental

INNER JOIN rental
	ON latest.latest_rental_id = rental.rental_id
INNER JOIN inventory
	ON rental.inventory_id = inventory.inventory_id
--store location
INNER JOIN store
	ON inventory.store_id = store.store_id
INNER JOIN address a1
	ON store.address_id = a1.address_id
INNER JOIN city city1
	ON a1.city_id = city1.city_id
INNER JOIN country country1
	ON city1.country_id = country1.country_id
--customer location
INNER JOIN customer 
	ON rental.customer_id = customer.customer_id
INNER JOIN address a2
	ON customer.address_id = a2.address_id
INNER JOIN city city2
	ON a2.city_id = city2.city_id
INNER JOIN country country2
	ON city2.country_id = country2.country_id;

-- checked if one specific movie being ranted by clients from different countries

SELECT
	CONCAT(customer.first_name || ' ' || customer.last_name) AS Customer,
	country.country
FROM customer

INNER JOIN 	rental
	ON customer.customer_id = rental.customer_id

INNER JOIN address a --customer address
	ON customer.address_id = a.address_id
INNER JOIN city city
	ON a.city_id = city.city_id
INNER JOIN country country
	ON city.country_id = country.country_id

WHERE inventory_id = 4131


--rents by inventory id
SELECT 
	inventory.inventory_id AS Inv,
	COUNT(rental.rental_id) AS Amount
FROM inventory
	
LEFT JOIN rental
	ON inventory.inventory_id = rental.inventory_id

GROUP BY inventory.inventory_id
ORDER BY Amount DESC;

--discovering customer countries and amount of rents per customer per country

SELECT
	country.country AS Country,
	COUNT(rental.rental_id) AS Rents_Amount,
	COUNT(DISTINCT city.city_id) AS Cities_Amount,
	COUNT(DISTINCT customer.customer_id) AS Customers_Amount,
	COUNT(rental.rental_id)/COUNT(DISTINCT customer.customer_id) AS Rents_Per_Customer
FROM rental

INNER JOIN customer
	ON rental.customer_id = customer.customer_id

INNER JOIN address
	ON customer.address_id = address.address_id

INNER JOIN city
	ON address.city_id = city.city_id

INNER JOIN country
	ON city.country_id = country.country_id

GROUP BY country.country_id
ORDER BY Rents_Per_Customer DESC;

-- checking if there's actor who is a customer also, or at least has the same name
SELECT 
	CONCAT(first_name, ' ', last_name) AS Actor
FROM actor

WHERE EXISTS(
	SELECT	1
	FROM customer
	WHERE customer.first_name = actor.first_name AND customer.last_name = actor.last_name
)


-- categories of movies customer with the highest count of rents rents 
SELECT
	category.name AS Category,
	COUNT(category.category_id) AS Amount
FROM rental

INNER JOIN inventory
	ON rental.inventory_id = inventory.inventory_id

INNER JOIN customer
	ON rental.customer_id = customer.customer_id

INNER JOIN film
	ON inventory.film_id = film.film_id

INNER JOIN film_category
	ON film.film_id = film_category.film_id

INNER JOIN category
	ON film_category.category_id = category.category_id

WHERE customer.first_name = 'RUSSELL' AND customer.last_name = 'BRINSON'

GROUP BY category.name;

--checking specific countries for their taste in movies by category
SELECT
	category.name AS Category,
	COUNT(category.category_id) AS Amount
FROM rental

INNER JOIN inventory
	ON rental.inventory_id = inventory.inventory_id

INNER JOIN customer
	ON rental.customer_id = customer.customer_id

INNER JOIN address
	ON customer.address_id = address.address_id

INNER JOIN city
	ON address.city_id = city.city_id

INNER JOIN country
	ON city.country_id = country.country_id

INNER JOIN film
	ON inventory.film_id = film.film_id

INNER JOIN film_category
	ON film.film_id = film_category.film_id

INNER JOIN category
	ON film_category.category_id = category.category_id

WHERE country.country = 'India'
GROUP BY category.name;

--days of month with most rents
--day to rent

SELECT 
	EXTRACT(DAY FROM rental_date) AS Day_of_Month,
	COUNT(rental_id) AS Amount
FROM rental
GROUP BY EXTRACT(DAY FROM rental_date)
ORDER BY Day_of_Month ASC;

--cte find clients with more rents then average

WITH RentsByCustomer AS (
	SELECT 
		customer_id, 
		COUNT(rental_id) AS Rents_Amount 
	FROM rental

	GROUP BY customer_id
)

SELECT 
	CONCAT(customer.first_name, ' ', customer.last_name) AS Customer_Name, 
	Rents_Amount
FROM RentsByCustomer
JOIN customer ON RentsByCustomer.customer_id = customer.customer_id
WHERE Rents_Amount > (SELECT AVG(Rents_Amount) FROM RentsByCustomer)
ORDER BY Rents_Amount DESC;

--CTE film categories by total revenue when the revenue is higher then average
WITH Total_Revenue AS (
	SELECT 
		category.category_id AS CatID,
		category.name AS Category,
		SUM(payment.amount) AS Revenue
	FROM payment

	INNER JOIN rental
		ON payment.rental_id = rental.rental_id
	INNER JOIN inventory
		ON rental.inventory_id = inventory.inventory_id
	INNER JOIN film_category
		ON inventory.film_id = film_category.film_id
	INNER JOIN category
		ON film_category.category_id = category.category_id
	GROUP BY category.category_id,category.name
),
Average_Revenue AS (
	SELECT 
		AVG(Revenue) AS Avg_Revenue
	FROM Total_Revenue
)
SELECT 
	Category,
	Revenue
FROM Total_Revenue
CROSS JOIN Average_Revenue
WHERE Revenue > Avg_Revenue
ORDER BY Revenue DESC;

--CTE search for customers with more profits then average, also amount of rents

WITH Revenue_Per_Client AS (
	SELECT 
		customer_id,
		SUM(amount) AS Revenue
	FROM payment
	GROUP BY customer_id
),
Average_Revenue AS(
	SELECT 
		AVG(Revenue) AS Avg_Revenue
	FROM Revenue_Per_Client
),
High_Earning_Clients AS(
	SELECT 
		customer_id,
		Revenue
	FROM Revenue_Per_Client
	CROSS JOIN Average_Revenue
	WHERE Avg_Revenue < Revenue
)
SELECT
	High_Earning_Clients.customer_id AS customer_id,
	Revenue,
	country.country AS Country,
	COUNT(rental.rental_id) AS Amount_Rents
FROM High_Earning_Clients

INNER JOIN rental
	ON High_Earning_Clients.customer_id = rental.customer_id

INNER JOIN customer
	ON High_Earning_Clients.customer_id = customer.customer_id

INNER JOIN address 
	ON customer.address_id = address.address_id

INNER JOIN city
	ON address.city_id = city.city_id

INNER JOIN country
	ON city.country_id = country.country_id

GROUP BY High_Earning_Clients.customer_id,Revenue,Country
ORDER BY Amount_Rents DESC;

--CTE DENSE RANK most active months by year

WITH monthly_rental_stats AS (
SELECT
	EXTRACT(year FROM rental_date) AS Year_Rent,
	EXTRACT(month FROM rental_date) AS Month_Rent,
	COUNT(rental_id) AS Amount_Rent,
	DENSE_RANK() OVER (
		PARTITION BY EXTRACT(year FROM rental_date)
		ORDER BY COUNT(rental_id) DESC
	) AS dense_rank_by_year
FROM rental
GROUP BY EXTRACT(year FROM rental_date),EXTRACT(month FROM rental_date)
)
SELECT
	Year_Rent,
	Month_Rent,
	Amount_Rent
FROM monthly_rental_stats
WHERE dense_rank_by_year = 1;

--CTE search for clients who made less then average rents and gave more then average revenue

WITH Rents_Payments_Amount AS(
SELECT
	customer_id,
	SUM(amount) AS Revenue,
	COUNT(rental_id) AS Rents
FROM payment
GROUP BY customer_id
),
Rents_Payments_Average AS(
SELECT	
	AVG(Revenue) AS Average_Revenue,
	AVG(Rents) AS Average_Rents
FROM Rents_Payments_Amount
)

SELECT
	CONCAT(customer.first_name, ' ',customer.last_name) AS Client_Name,
	Revenue,
	Rents
FROM Rents_Payments_Amount

INNER JOIN customer
ON Rents_Payments_Amount.customer_id = customer.customer_id
CROSS JOIN Rents_Payments_Average
WHERE Revenue>Average_Revenue AND Rents<Average_Rents;

--CTE find the clients with the last rent being month ago or more

WITH Rent_Amount AS(
SELECT 
	customer_id,
	COUNT(DISTINCT rental_id) AS Rents
FROM rental
GROUP BY customer_id
),
Rent_Latest_Date AS(
SELECT
	customer_id,
	MAX(rental_date) AS Latest_Rent
FROM rental
GROUP BY customer_id
),
Max_Rental_Date AS(
SELECT
	MAX(rental_date) AS Last_Rental_Day
FROM Rental
)
SELECT
	CONCAT(customer.first_name, ' ', customer.last_name) AS Customer_Name,
	Rents,
	Latest_Rent
FROM Rent_Latest_Date

INNER JOIN Rent_Amount ON Rent_Latest_Date.customer_id = Rent_Amount.customer_id
CROSS JOIN Max_Rental_Date
INNER JOIN customer ON Rent_Latest_Date.customer_id = customer.customer_id

WHERE Last_Rental_Day - INTERVAL '1 month' > Latest_Rent;

--CTE the store with most load per copy(the biggest amount of rents per copy)

WITH Rents AS( --rents per store
	SELECT 
		store.store_id AS StoreID,
		COUNT(payment.rental_id) AS Rents_Amount
	FROM payment

	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
	INNER JOIN store ON inventory.store_id = store.store_id
	GROUP BY store.store_id
),
Invent AS( --inv per store
	SELECT
		store_id AS StoreID,
		COUNT(inventory_id) AS Inventory_Amount
	FROM inventory
	
	GROUP BY store_id
)
	SELECT
		Rents.StoreID AS Store1,
		ROUND(1.0*Rents_Amount/Inventory_Amount,2) AS Store_Load
	FROM Rents

	INNER JOIN Invent ON Rents.StoreID = Invent.StoreID
	ORDER BY Store_Load DESC
	LIMIT 1;

--find 10 movies with the highest revenue and lesser then average copies in inventories

WITH movie_revenue AS(
	SELECT
		inventory.film_id AS Revenue_filmid,
		SUM(payment.amount) AS revenue
	FROM payment

	INNER JOIN rental
		ON payment.rental_id = rental.rental_id
	INNER JOIN inventory
		ON rental.inventory_id = inventory.inventory_id
	GROUP BY inventory.film_id
),
movie_copies AS(
	SELECT 
		film_id AS Copies_filmid,
		COUNT(inventory_id) AS copies
	FROM inventory
	GROUP BY film_id
),
copies_average AS(
	SELECT 
		AVG(copies) AS average
	FROM movie_copies
)
SELECT 
	film.title AS Movie_Name,
	revenue
FROM movie_revenue

INNER JOIN film on Revenue_filmid = film_id
INNER JOIN movie_copies ON Revenue_filmid = Copies_filmid
CROSS JOIN copies_average

WHERE copies < average 
ORDER BY revenue DESC
LIMIT 10;

-- CTE ROW NUMBER LAST 3 RENTS BY CUSTOMER

WITH Customer_Rents AS(
	SELECT 
		customer_id,
		rental_date,
		film.title AS Movie
	FROM rental
	INNER JOIN inventory ON rental.inventory_id=inventory.inventory_id
	INNER JOIN film ON inventory.film_id=film.film_id
),
Numbered_Rents AS(	
	SELECT
		customer_id,
		rental_date,
		Movie,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY rental_date DESC) AS rental_row
	FROM Customer_Rents
)
SELECT
	CONCAT(customer.first_name, ' ', customer.last_name) AS Customer_Name,
	rental_date,
	Movie,
	rental_row
FROM Numbered_Rents

INNER JOIN customer ON Numbered_Rents.customer_id = customer.customer_id

WHERE rental_row <=3;

-- CTE RANK top 5 movies by revenue in each category

WITH Movie_Revenue AS(
	SELECT 
		category.name AS Category,
		film.title AS Movie,
		SUM(payment.amount) AS Revenue
	FROM payment

	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
	INNER JOIN film ON inventory.film_id = film.film_id
	INNER JOIN film_category ON film.film_id = film_category.film_id
	INNER JOIN category ON film_category.category_id = category.category_id

	GROUP BY category.name,film.title
),
Categories_Ranked AS(
	SELECT 
		Category,
		Movie,
		Revenue,
		RANK() OVER (
			PARTITION BY category
			ORDER BY Revenue DESC) AS Ranked
	FROM Movie_Revenue
)
SELECT 
	Category,
	Movie,
	Revenue,
	Ranked
FROM Categories_Ranked
WHERE Ranked <=5;

--top 3 most valueable in replacement cost by category

WITH Replacement_Info AS(
	SELECT 
		category.name AS Category,
		film.title AS Movie,
		film.replacement_cost AS Replacement_Cost
	FROM film

	INNER JOIN film_category ON film.film_id = film_category.film_id
	INNER JOIN category ON film_category.category_id = category.category_id
),
Replacement_Ranked AS (
	SELECT 
		Category,
		Movie,
		Replacement_Cost,
		DENSE_RANK() OVER (
			PARTITION BY category
			ORDER BY Replacement_Cost DESC) AS Ranked
	FROM Replacement_Info
)
SELECT
	Category,
	Movie,
	Replacement_Cost,
	Ranked
FROM Replacement_Ranked
WHERE Ranked <= 3;

--CTE LAG revenue by client monthly

WITH customer_revenue AS(
	SELECT
		payment.customer_id AS Customer_id,
		EXTRACT('MONTH' FROM rental.rental_date) AS Rental_Month,
		SUM(payment.amount) AS Payments
	FROM payment
	
	INNER JOIN rental ON payment.rental_id = rental.rental_id
	GROUP BY payment.customer_id, EXTRACT('MONTH' FROM rental.rental_date)
),
lag_revenue AS(
	SELECT
		Customer_id,
		Rental_Month,
		Payments,
		LAG(Payments, 1, NULL) OVER
			(
				PARTITION BY Customer_id
				ORDER BY Rental_Month
			) AS Previous_Payments
	FROM customer_revenue
)

SELECT
	CONCAT(customer.first_name, ' ', customer.last_name) AS Customer_Name,
	Rental_Month,
	Payments,
	Previous_Payments,
	Payments-Previous_Payments AS Difference
FROM lag_revenue

INNER JOIN customer ON lag_revenue.Customer_id = customer.customer_id;

--CTE LAG amount of rents by month

WITH monthly_rents AS (
	SELECT 
		EXTRACT ('MONTH' FROM rental_date) AS Month,
		COUNT(rental_id) AS Rents
	FROM rental

	GROUP BY EXTRACT ('MONTH' FROM rental_date)
),

prev_monthly_rents AS(
	SELECT
		Month,
		Rents,
		LAG(Rents,1,NULL) OVER(ORDER BY Month) AS Prev_Rents
	FROM monthly_rents
)
SELECT 
	Month,
	Rents,
	Prev_Rents,
	Rents-Prev_Rents
FROM prev_monthly_rents;

--CTE LAG Amount of rents per month by customer

WITH Client_Rents AS(
	SELECT 
		customer_id,
		EXTRACT('Month' FROM rental_date) AS Month,
		COUNT(rental_id) AS Rents
	FROM rental

	GROUP BY customer_id,EXTRACT('Month' FROM rental_date)
),
Prev_Client_Rents AS(
	SELECT 
		customer_id,
		Month,
		Rents,
		LAG(Rents, 1, NULL) OVER (PARTITION BY customer_id ORDER BY Month) AS Prev_Rents
	FROM Client_Rents
)
SELECT 	
	CONCAT(customer.first_name, ' ', customer.last_name) AS Customer_Name,
	Month,
	Rents,
	Prev_Rents,
	Rents - Prev_Rents  AS Difference
FROM Prev_Client_Rents
	
INNER JOIN customer ON Prev_Client_Rents.customer_id = customer.customer_id;

--CTE LAG rent dates by clients, with previous rents

WITH Customer_Rents AS(
	SELECT 
		CONCAT(customer.first_name, ' ',customer.last_name) AS Customer,
		rental.rental_date AS Date,
		film.title AS Movie
	FROM rental

	INNER JOIN customer ON rental.customer_id = customer.customer_id
	INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
	INNER JOIN film ON inventory.film_id = film.film_id
)
	SELECT 
		Customer,
		Date,
		Movie,
		LAG(Date,1,NULL) OVER(PARTITION BY Customer ORDER BY Date)
	FROM Customer_Rents;

-- CTE COMPARISON RANK DENSE_RANK ROW_NUMBER categories replacement costs

WITH Movie_Category AS(
	SELECT 
		category.name AS Category,
		film.title AS Movie,
		film.replacement_cost AS Cost
	FROM film

	INNER JOIN film_category ON film.film_id = film_category.film_id
	INNER JOIN category ON film_category.category_id = category.category_id
)

SELECT 
	Category,
	Movie,
	Cost,
	ROW_NUMBER() OVER( PARTITION BY Category ORDER BY Cost DESC) AS Row_Number,
	RANK() OVER( PARTITION BY Category ORDER BY Cost DESC) AS Rank,
	DENSE_RANK() OVER( PARTITION BY Category ORDER BY Cost DESC) AS Dense_Rank
FROM Movie_Category;

--CTE LEAD finding next rental date

WITH customer_rents AS(
	SELECT 
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		rental.rental_date AS Date,
		film.title AS Movie
	FROM rental

	INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
	INNER JOIN film ON inventory.film_id = film.film_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
)
SELECT 
	Customer,
	Date,
	Movie,
	LEAD(date,1,NULL) OVER(PARTITION BY Customer ORDER BY Date) AS Next_Rental
FROM customer_rents;

--CTE LAG RANK longest gaps between rents

WITH rents AS(
	SELECT 
		customer_id,
		rental_date
	FROM rental
),
prev AS(
	SELECT
		customer_id,
		rental_date,
		LAG(rental_date,1,NULL) OVER (PARTITION BY customer_id ORDER BY rental_date) AS Previous_Rental
	FROM rents
),
ranking AS(
	SELECT 
		customer_id,
		rental_date,
		Previous_Rental,
		rental_date-Previous_Rental AS Difference,
		RANK() OVER(PARTITION BY customer_id ORDER BY rental_date-Previous_Rental DESC NULLS LAST) AS Ranked
	FROM prev
)
SELECT
	customer_id,
	rental_date,
	Previous_Rental,
	Difference
FROM ranking
WHERE Ranked = 1;

--CTE GAPS AND ISLANDS SUM() longest consecutive rents by day by customer

WITH Customer_Rent AS (
    SELECT
        rental.customer_id,
        CAST(rental.rental_date AS date) AS Rental_Date,
        LAG(CAST(rental.rental_date AS date)) OVER (
            PARTITION BY rental.customer_id
            ORDER BY rental.rental_date
        ) AS Previous_Date
    FROM rental
),

Streak_Count AS (
    SELECT
        customer_id,
        Rental_Date,
        Previous_Date,
        CASE
            WHEN Previous_Date IS NULL THEN 1
            WHEN Rental_Date - Previous_Date = 1 THEN 0
            ELSE 1
        END AS New_Streak
    FROM Customer_Rent
),

Streak AS (
    SELECT
        customer_id,
        Rental_Date,
        SUM(New_Streak) OVER (
            PARTITION BY customer_id
            ORDER BY Rental_Date
        ) AS Streak_ID
    FROM Streak_Count
),

Streak_Length AS (
    SELECT
        customer_id,
        Streak_ID,
        COUNT(*) AS Streak_Length
    FROM Streak
    GROUP BY customer_id, Streak_ID
),

Ranked AS (
    SELECT
        customer_id,
        Streak_Length,
        RANK() OVER (
            PARTITION BY customer_id
            ORDER BY Streak_Length DESC
        ) AS Ranked
    FROM Streak_Length
)

SELECT
    CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
    Ranked.Streak_Length AS Longest_Streak
FROM Ranked
INNER JOIN customer
    ON Ranked.customer_id = customer.customer_id
WHERE Ranked = 1
ORDER BY Longest_Streak DESC;

--CTE DENSE_RANK top 3 movies by rent per category

WITH Rents AS (
	SELECT 
		category.name AS Category,
		film.title AS Movie,
		COUNT(rental.rental_id) AS Rents_Amount
	FROM rental

	INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
	INNER JOIN film ON inventory.film_id = film.film_id
	INNER JOIN film_category ON film.film_id = film_category.film_id
	INNER JOIN category ON film_category.category_id = category.category_id

	GROUP BY category.name, film.title
),
Ranked AS(
	SELECT
		Category,
		Movie,
		Rents_Amount,
		DENSE_RANK() OVER (PARTITION BY Category ORDER BY Rents_Amount DESC) AS Ranked
	FROM Rents
)
SELECT
	Category,
	Movie,
	Rents_Amount,
	Ranked
FROM Ranked

WHERE Ranked <= 3;

-- CTE ROW_NUMBER last three rents by customer

WITH Rent_Dates AS(
	SELECT 
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		rental.rental_date AS Date,
		film.title AS Movie
	FROM rental

	INNER JOIN customer ON rental.customer_id = customer.customer_id
	INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
	INNER JOIN film ON inventory.film_id = film.film_id
),
Numbered AS(
	SELECT 	
		Customer,
		Date,
		Movie,
		ROW_NUMBER() OVER (PARTITION BY Customer ORDER BY Date DESC) AS Row_Number
	FROM Rent_Dates
)
SELECT 
	Customer,
		Date,
		Movie,
		Row_Number
FROM Numbered
WHERE Row_Number <= 3;

-- CTE LEAD ROW_NUMBER first rent by customer and days in between first and second

WITH First_Rental AS(
	SELECT
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		rental.rental_date AS Date
	FROM rental
	
	INNER JOIN customer ON rental.customer_id = customer.customer_id
),
Second_Rental AS(
	SELECT
		Customer,
		Date,
		LEAD(Date,1,NULL) OVER(PARTITION BY Customer ORDER BY Date) AS Next_Date
	FROM First_Rental
),
Numbered AS(
	SELECT 
		Customer,
		Date,
		Next_Date,
		ROW_NUMBER() OVER(PARTITION BY Customer ORDER BY Date) AS Row_Numbered
	FROM Second_Rental
)
SELECT 
	Customer,
	Date,
	Next_Date,
	Next_Date-Date AS Days_Between
FROM Numbered
WHERE Row_Numbered = 1 AND Next_Date IS NOT NULL;

--CTE max avg payments by client

WITH All_Payments AS(
	SELECT
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		payment.amount AS Payment
	FROM payment
	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
),
Average_Payment AS(
	SELECT 
		Customer,
		AVG(Payment) AS Payment
	FROM All_Payments
	
	GROUP BY Customer
),
Max_Payment AS(
	SELECT
		Customer,
		MAX(Payment) AS Payment
	FROM All_Payments

	GROUP BY Customer
)

SELECT
	Max_Payment.Customer,
	Max_Payment.Payment AS Max_Payment,
	Average_Payment.Payment AS Average_Payment,
	Max_Payment.Payment-Average_Payment.Payment AS Difference
FROM Max_Payment
INNER JOIN Average_Payment ON Max_Payment.Customer = Average_Payment.Customer

ORDER BY Max_Payment DESC;

--CTE AGG WINDOW FUNC Customer | Payment | Average_Payment | Max_Payment | Total_Payments

WITH Customer_Payment AS(
	SELECT 	
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		payment.amount AS Payment
	FROM payment

	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
)
	SELECT 
		Customer,
		Payment,
		AVG(Payment) OVER(PARTITION BY Customer) AS Average_Payment,
		MAX(Payment) OVER(PARTITION BY Customer) AS Maximum_Payment,
		SUM(Payment) OVER(PARTITION BY Customer) AS Total_Payment

	FROM Customer_Payment;
	
--CTE RUNNING TOTAL SUM payments by clients

WITH Payments AS (
	SELECT 	
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		payment_date AS Date,
		amount AS Amount
	FROM payment
	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
)

SELECT 
	Customer,
	Date, 
	Amount,
	SUM(Amount) OVER (PARTITION BY Customer ORDER BY Date) AS Running_Total
FROM Payments;

--CTE SUM () ROWS BETWEEN every payment with previous

WITH Payments AS (
	SELECT 	
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		payment_date AS Date,
		amount AS Payment
	FROM payment
	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
)
SELECT 
	Customer,
	Date,
	Payment,
	SUM(Payment) OVER(PARTITION BY Customer ORDER BY Date ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
FROM Payments;

--Customer | Payment_Date | Payment | Avg_Last_3

WITH Payments AS (
	SELECT 	
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		payment_date AS Date,
		amount AS Payment
	FROM payment
	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
)
SELECT 
	Customer,
	Date,
	Payment,
	AVG(Payment) OVER(PARTITION BY Customer ORDER BY Date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
FROM Payments;

--CTE FIRST_VALUE
--Customer | Payment_Date | Payment | First_Payment

WITH Payments AS (
	SELECT 	
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		payment_date AS Date,
		amount AS Payment
	FROM payment
	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
)
SELECT
	Customer,
	Date,
	Payment,
	FIRST_VALUE(Payment) OVER(PARTITION BY Customer ORDER BY Date) 
FROM Payments;

--CTE LAST_VALUE()
--Customer | Payment_Date | Payment | First_Payment

WITH Payments AS (
	SELECT 	
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		payment_date AS Date,
		amount AS Payment
	FROM payment
	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
)
SELECT
	Customer,
	Date,
	Payment,
	LAST_VALUE(Payment) OVER(PARTITION BY Customer ORDER BY Date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) 
FROM Payments;

--CTE NTH_VALUE()
--Customer | Payment_Date | Payment | First_Payment

WITH Payments AS (
	SELECT 	
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		payment_date AS Date,
		amount AS Payment
	FROM payment
	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
)
SELECT
	Customer,
	Date,
	Payment,
	NTH_VALUE(Payment,2) OVER(PARTITION BY Customer ORDER BY Date) 
FROM Payments;

--CTE NTILE()
--Customer | Payment_Date | Payment | Quartile

WITH Payments AS (
	SELECT 	
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		payment_date AS Date,
		amount AS Payment
	FROM payment
	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
)
SELECT
	Customer,
	Date,
	Payment,
	NTILE(4) OVER (PARTITION BY Customer ORDER BY Payment) AS Quartile 
FROM Payments;

--CTE RANK
--Customer | Payment_Date | Payment | Payment_Rank

WITH Payments AS (
	SELECT 	
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		payment_date AS Date,
		amount AS Payment
	FROM payment
	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
)
SELECT
	Customer,
	Date,
	Payment,
	RANK() OVER (PARTITION BY Customer ORDER BY Payment DESC) AS Payment_Rank 
FROM Payments;

--CTE  SUM percentage of payment by customer
--Customer | Payment_Date | Payment | Percentage

WITH Payments AS (
	SELECT 	
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		payment_date AS Date,
		amount AS Payment
	FROM payment
	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
),
Total_Payment AS(
	SELECT
		Customer,
		Date,
		Payment,
		SUM(Payment) OVER(PARTITION BY Customer) AS Total
	FROM Payments
		
)
SELECT
	Customer,
	Date,
	Payment,
	ROUND(100.0*Payment/Total,2) AS Percentage
FROM Total_Payment;

--CTE LAG days since prev rent
--Customer | Rental_Date | Movie | Days_Since_Previous

WITH Movie_Rent AS(
	SELECT 
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		rental.rental_date AS Date,
		film.title AS Movie
	FROM rental

	INNER JOIN customer ON rental.customer_id = customer.customer_id
	INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
	INNER JOIN film ON inventory.film_id = film.film_id
),
Previous_Rent AS(
	SELECT
		Customer,
		Date,
		Movie,
		LAG(Date, 1, NULL) OVER(PARTITION BY Customer ORDER BY Date) AS Previous
	FROM Movie_Rent
)
SELECT
	Customer,
	Date,
	Movie,
	Date-Previous
FROM Previous_Rent;

--CTE RANK() categories by rents per movie

WITH Movie_Rents AS(
	SELECT 
		category.name AS Category,
		film.title AS Movie,
		COUNT(rental.rental_id) AS Rentals
	FROM rental

	INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
	INNER JOIN film ON inventory.film_id = film.film_id
	INNER JOIN film_category ON film.film_id = film_category.film_id
	INNER JOIN category ON film_category.category_id = category.category_id

	GROUP BY category.name, film.title
)
SELECT
	Category,
	Movie,
	Rentals,
	RANK() OVER (PARTITION BY Category ORDER BY Rentals DESC) AS Ranked
FROM Movie_Rents;

-- CTE RANK() ALL RENTS, CLIENTS RANKED BY AMOUNT OF REVENUE
--Customer | Rentals | Total_Payments | Avg_Payment | Max_Payment | Revenue_Rank

WITH Client_Rents AS(
	SELECT 
		CONCAT(customer.first_name, ' ', customer.last_name) AS Customer,
		COUNT(rental.rental_id) AS Rents,
		SUM(payment.amount) AS Total_Payments,
		AVG(payment.amount) AS Average_Payment,
		MAX(payment.amount) AS Max_Payment
	FROM payment

	INNER JOIN rental ON payment.rental_id = rental.rental_id
	INNER JOIN customer ON rental.customer_id = customer.customer_id
	
	GROUP BY customer.customer_id
)
SELECT
	Customer,
	Rents,
	Total_Payments,
	Average_Payment,
	Max_Payment,
	RANK() OVER(ORDER BY Total_Payments DESC) AS Rank
FROM Client_Rents;

--CTE RANK AVG movies by category with most rents
--Category | Top_Movie | Top_Movie_Rentals | Avg_Movie_Rentals

WITH Movie_Rents AS(
	SELECT 
		category.name AS Category,
		film.title AS Movie,
		COUNT(rental.rental_id) AS Rents
	FROM rental
	
	INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
	INNER JOIN film ON inventory.film_id = film.film_id
	INNER JOIN film_category ON film.film_id = film_category.film_id
	INNER JOIN category ON film_category.category_id = category.category_id

	GROUP BY category.name, film.title
),
Ranked_Rents AS(
	SELECT 	
		Category,
		Movie,
		Rents,
		RANK() OVER(PARTITION BY Category ORDER BY Rents DESC) AS Ranked,
		AVG(Rents) OVER(PARTITION BY Category) AS Average_Rents
	FROM Movie_Rents

	GROUP BY Category,Movie,Rents
)
SELECT 	
	Category,
	Movie,
	Ranked,
	Average_Rents
FROM Ranked_Rents
WHERE Ranked = 1;

--CTE CROSS JOIN staff percentages
--Staff | Payments | Revenue | Revenue_Percentage

WITH Staff_Payments AS(
	SELECT
		CONCAT(staff.first_name, ' ', staff.last_name) AS Staff,
		COUNT(payment.payment_id) AS Payments,
		SUM(payment.amount) AS Revenue
	FROM payment
	INNER JOIN staff ON payment.staff_id = staff.staff_id

	GROUP BY Staff
),
Total_Revenue AS(
	SELECT 
		SUM(Revenue) AS Total
	FROM Staff_Payments
)
SELECT
	Staff,
	Payments,
	Revenue,
	ROUND(100.0 * Revenue/Total_Revenue.Total,2) AS Percentage
FROM Staff_Payments
CROSS JOIN Total_Revenue;
