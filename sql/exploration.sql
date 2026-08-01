-- Number of inventory copies per store
SELECT 
	address.address AS Store_Address,
	COUNT(inventory.inventory_id) AS Inventory_Count
FROM store

LEFT JOIN inventory
ON store.store_id = inventory.store_id

INNER JOIN address
ON store.address_id = address.address_id

GROUP BY address.address_id
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