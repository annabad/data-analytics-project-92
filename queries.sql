-- Запрос для подсчета общего количества покупателей

select COUNT(customer_id) as customers_count
from customers;

--Запрос для определения топ-10 лучших продавцов

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
