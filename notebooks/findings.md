- there's 500 stores, only two stores(ID 1 and ID 2) offer movies for rent - 2270 and 2311 copies
- there's 241 copies that haven't been returned with 182 copies unreturned for 4.5 years. they were rented at the same day and at the same time February 14th, 2022 at 17:16:03+02, not sure for now what is the problem with this.
- in film table there's rental_duration column and I wasn't sure what it's stands for. So I've checked my hyphothesis if it is allowed duration of rent for this specific film and, based on average time every movie was rented, it seems that my hyphothesis is correct
- theres 16 categories of movies in database. all of the movies and copies are spread fairly evenly across 16 categories. Revenue is also relatively balanced, averaging around 25,000 per category.
- The language of movies, revenue and amount of rents don't show any interesting data. the percentage for each is directly proportional to the number of movies. Movie language does not appear to influence rental frequency or revenue. The distribution of rentals and revenue closely follows the distribution of inventory copies across languages.
- in database there are 999 customers. two of them haven't rented anything. Majority has numerous rents of movies on them. The highest amount of rents for one customer is 97.
- discovered that most of the customers do not return movies in time
- found out the overall replacement cost of movies that weren't returned - 4773
- there's 215 unique movies that wasn't returned
- the amounts of not returned movies by category is about equall
- on average there's 750 rents per month(excluding late spring and summer of 2022, when there were unusually large amount of rents)

## Data Quality Issues
- Customers from dozens of countries rent inventory from only two physical stores.
- The same inventory copies are rented by customers living on different continents.
- The dataset appears to be designed for SQL practice rather than to model a realistic rental business.