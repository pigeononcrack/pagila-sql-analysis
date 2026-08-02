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