create database zomato;

-- month over month % revenue growth of Zomato
select m_name, revenue, ((revenue - previous_month)/previous_month)*100 as 'percent_increase'
from
	(
		select *, lag(revenue) over(order by mth) as 'previous_month'
		from 
			(
				select monthname(date) as m_name, month(date) as 'mth' , sum(amount) as 'revenue'
				from orders
				group by monthname(date)
				order by month(date)
			) t1
	)t2 ;

-- month over month % revenue growth of Restaurant
select r_name, m_name, revenue, ((revenue - previous_month)/previous_month)*100 as 'percent_increase'
from
	(
		select *, lag(revenue) over(order by mth) as 'previous_month'
		from 
			(
				select r_name, monthname(date) as m_name, month(date) as 'mth' , sum(amount) as 'revenue'
				from orders o
                join restaurants r on o.r_id = r.r_id
                where o.r_id = 1
				group by monthname(date)
				order by month(date)
			) t1
	)t2 ;
    
-- favourite food of a Customer based on orders
with cte as (
			select name, f_name, count(*) as 'frequency'  from order_details od
			join orders o on od.order_id = o.order_id
			join users u on o.user_id = u.user_id
			join food f on od.f_id = f.f_id
			group by u.user_id, od.f_id
			order by u.user_id, count(*) desc
            )
select * from cte t1 where t1.frequency = (select max(frequency) from cte t2 where t2.name = t1.name);

-- Loyal Customers (repeated customers to a restaurant)
select * from restaurants;
select r_name, name, count(*) as 'no_of_visits' from orders o
join restaurants r on o.r_id = r.r_id
join users u on o.user_id = u.user_id
group by o.r_id, u.user_id having no_of_visits > 1
order by o.r_id , u.user_id desc ;

select r_name, count(name) as 'no_of_loyal_customers'
from
	(
		select r_name, name, count(*) as 'no_of_visits' from orders o
		join restaurants r on o.r_id = r.r_id
		join users u on o.user_id = u.user_id
		group by o.r_id, u.user_id having no_of_visits > 1
		order by o.r_id , u.user_id desc
	) t
group by r_name
order by count(name) desc 
limit 1;

-- 3) return n random records
select * from users order by rand();
select * from users order by rand() limit 5;
-- replicates sample func from pandas

-- 4) find null value rows
select * from orders1 where restaurant_rating is not null;

-- to replace null values with 0
update orders set restaurant_rating = 0 where restaurant_rating is null;

-- 5) find no of orders placed by each customer
select t1.user_id, t1.name, count(*) as 'no_of_orders' from zomato.users t1
join zomato.orders t2
on t1.user_id = t2.user_id
group by t1.user_id;

-- 6) find restaurant with most no of menu items
select t1.r_id, count(*) from zomato.restaurants t1
join zomato.menu t2
on t1.r_id = t2.r_id
group by t1.r_id
order by count(*) desc limit 5;

-- 7) find number of votes and avg rating for all the restaurants
select r_id, count(restaurant_rating) as 'no_of_ratings', avg(restaurant_rating) from zomato.orders
group by r_id;

-- 8) find food that is being sold at most number of restaurants
select t1.f_id, t2.f_name, count(*) from zomato.menu t1
join zomato.food t2
on t1.f_id = t2.f_id
group by t1.f_id
order by count(*) desc limit 1;

-- 9) find restaurant with max revenue in a given month (May)
select t1.r_id, t2.r_name, sum(amount) from zomato.orders t1
join restaurants t2
on t1.r_id = t2.r_id
where monthname(date(date)) = 'May'
group by r_id order by sum(amount) desc;

-- find month by month revenue for a restaurant
select t1.r_id, t2.r_name, monthname(date(date)), sum(t1.amount) from orders t1
join restaurants t2
on t1.r_id = t2.r_id
where t2.r_name = 'kfc'
group by monthname(date(date));

select t1.r_id, t2.r_name, monthname(date(date)), sum(t1.amount) from orders t1
join restaurants t2
on t1.r_id = t2.r_id
group by t1.r_id, monthname(date(date))
order by t2.r_name, monthname(date(date)) desc;


-- 10) find restaurant with sales > x
select t1.r_id, t2.r_name, sum(t1.amount) as 'sales' from zomato.orders t1
join zomato.restaurants t2
on t1.r_id = t2.r_id
group by t1.r_id having sales > 1000;

-- 11) customers who have never ordered
select t2.user_id, t2.name from zomato.orders t1 
right join zomato.users t2
on t1.user_id = t2.user_id
where t1.order_id is null;

-- 12) order details of a particular customer in a given date range
select t1.order_id, t2.name,  t1.amount, t1.date, t4.f_name from zomato.orders t1
join zomato.users t2
on t1.user_id = t2.user_id
join zomato.order_details t3
on t1.order_id = t3.order_id
join zomato.food t4
on t3.f_id = t4.f_id
where t1.user_id = 1 and monthname(date(date)) in ('May','June');

select t1.order_id, t2.name,  t1.amount, t1.date, t4.f_name from zomato.orders t1
join zomato.users t2
on t1.user_id = t2.user_id
join zomato.order_details t3
on t1.order_id = t3.order_id
join zomato.food t4
on t3.f_id = t4.f_id
where t1.user_id = 1 and date between '2022-05-15' and '2022-06-15';

-- 14) most costly restaurants
select t1.r_id, t2.r_name, sum(t1.price)/count(*) as 'avg_price'  from zomato.menu t1
join zomato.restaurants t2
on t1.r_id = t2.r_id
group by t1.r_id
order by avg_price desc;

-- 19) find all veg restaurants
select t1.type, t3.r_id, t4.r_name from zomato.food t1
join zomato.order_details t2
on t1.f_id = t2.f_id
join zomato.orders t3
on t2.order_id = t3.order_id
join zomato.restaurants t4
on t3.r_id = t4.r_id
group by t4.r_name
having min(type) = 'veg' and max(type) = 'veg';

-- 20) find min and max order value for all the customers
select t1.user_id, t2.name, min(t1.amount), max(t1.amount), avg(t1.amount) from zomato.orders t1
join zomato.users t2
on t1.user_id = t2.user_id
group by t1.user_id;

-- Avg Price of a food item
select f_name, avg(price) from menu m 
join food f on m.f_id = f.f_id
group by m.f_id;

-- Restaurant with most number of orders
select r_name, count(*) as 'no_of_orders' from orders o 
join restaurants r on o.r_id = r.r_id
group by o.r_id order by count(*) desc;

-- Restaurant with most number of orders monthwise
select r.r_name, monthname(date), count(*) as 'no_of_orders' from orders o 
join restaurants r on o.r_id = r.r_id
group by o.r_id, month(date)
order by r.r_name, month(date);
