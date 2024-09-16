-- Запрос для подсчета общего количества покупателей

select COUNT(customer_id) as customers_count
from customers;
--------------------
--топ-10 лучших продавцов

with full_employees as (select employee_id, CONCAT(first_name,' ', last_name) as seller
from employees)

select fe.seller, count(sale_date) as operations, floor(sum(s.quantity * p.price)) as income
from
full_employees fe
join sales s on fe.employee_id = s.sales_person_id
join products p using (product_id)
group by fe.seller
order by income desc
limit 10;
-----------------------
--отчет с продавцами, чья выручка ниже средней выручки всех продавцов

with full_employees as (select employee_id, CONCAT(first_name,' ', last_name) as seller
from employees),

avg_incoms as (select fe.seller, 
count(sale_date) as operations, 
floor(sum(s.quantity * p.price)) as income,
floor(sum(s.quantity * p.price)/count(sale_date)) as average_income
from
full_employees fe
join sales s on fe.employee_id = s.sales_person_id
join products p using (product_id)
group by fe.seller
order by average_income desc)


select seller, average_income
from avg_incoms
where average_income < (select AVG(average_income) from avg_incoms)
order by average_income;

--------------------------------
--отчет с данными по выручке по каждому продавцу и дню недели

with full_employees as (select employee_id, CONCAT(first_name,' ', last_name) as seller
from employees),


sales_with_days as (select seller, sale_date, 
case extract(dow from sale_date)::int
when 0 then 7
else extract(dow from sale_date)::int
end as week_day, 
s.quantity * p.price as day_income
from full_employees fe
join sales s on fe.employee_id = s.sales_person_id
join products p using (product_id))

select seller, to_char(sale_date, 'day') as day_of_week, floor(sum(day_income)) as income
from sales_with_days
group by seller,to_char(sale_date, 'day'), week_day
order by week_day;

-------------------------------------------
--отчет с данными о количестве покупателей в разных возрастных группах: 16-25, 26-40 и 40+

select '16-25' as age_category, count(customer_id) as age_count
from customers
where age between 16 and 25

union

select '26-40' as age_category, count(customer_id) as age_count
from customers
where age between 26 and 40

union

select '40+' as age_category, count(customer_id) as age_count
from customers
where age > 40
order by age_category;

--------------------------------------------
--отчет о количестве уникальных покупателей и выручке, которую они принесли

with tab as (select extract(year from sale_date) as year_date, extract(month from sale_date) as month_date, 
count(distinct customer_id) as total_customers, 
floor(sum(quantity * price)) as income
from sales s
join products p using (product_id)
group by 1, 2
order by 1, 2)

select case
when  month_date < 10 then concat(year_date,'-0',month_date )
else concat(year_date,'-',month_date)
end as selling_month, total_customers, income
from tab
order by selling_month;

----------------------------------------------
--отчет о покупателях, первая покупка которых состоялась в ходе проведения акций

with full_customers as (select customer_id, CONCAT(first_name,' ', last_name) as customer
from customers),
full_employees as (select employee_id, CONCAT(first_name,' ', last_name) as seller
from employees),
sales_with_0 as (select customer_id, customer, sale_date, seller
from sales s
join full_customers using(customer_id)
join full_employees fe on fe.employee_id = s.sales_person_id 
join products using (product_id) where price = 0),
sales_with_0_min_date as (select distinct customer_id, customer, MIN(sale_date) OVER(partition by customer order by sale_date) as sale_date, seller
from sales_with_0)
select customer, sale_date, seller
from sales_with_0_min_date
order by customer_id
;



