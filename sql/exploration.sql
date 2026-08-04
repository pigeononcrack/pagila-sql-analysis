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