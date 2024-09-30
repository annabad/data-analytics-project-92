--запрос для подсчета общего количества покупателей

select COUNT(customer_id) as customers_count
from customers;
--------------------
--отчет о топ-10 лучших продавцов и объеме их выручки

select
    CONCAT(e.first_name, ' ', e.last_name) as seller,
    COUNT(s.sale_date) as operations,
    FLOOR(SUM(s.quantity * p.price)) as income
from
    employees as e
inner join sales as s on e.employee_id = s.sales_person_id
inner join products as p on s.product_id = p.product_id
group by e.employee_id
order by income desc
limit 10;

-----------------------
--отчет о продавцах, чья выручка ниже средней выручки среди всех продавцов

select
    CONCAT(e.first_name, ' ', e.last_name) as seller,
    FLOOR(AVG(s.quantity * p.price)) as average_income
from employees as e 
inner join sales as s on e.employee_id = s.sales_person_id
inner join products as p on s.product_id = p.product_id
group by e.employee_id
having AVG(s.quantity * p.price) < (
    select AVG(sales.quantity * products.price)
    from sales
    inner join products on sales.product_id = products.product_id
    )
order by average_income;

--------------------------------
--отчет об объемах выручки по каждому продавцу и дню недели

select
    CONCAT(e.first_name, ' ', e.last_name) as seller,
    TO_CHAR(s.sale_date, 'day') as day_of_week,
    FLOOR(SUM(s.quantity * p.price)) as income
from employees as e
inner join sales as s on e.employee_id = s.sales_person_id
inner join products as p on s.product_id = p.product_id
group by seller, day_of_week, EXTRACT(isodow from s.sale_date)
order by EXTRACT(isodow from s.sale_date), seller;

-------------------------------------------
--отчет о количестве покупателей в разных возрастных группах: 16-25, 26-40 и 40+

select 
case 
	when age between 16 and 25 then '16-25'
	when age between 26 and 40 then '26-40'
	when age > 40 then '40+'
end as age_category,
COUNT(customer_id) as age_count
from customers
group by age_category
order by age_category;

--------------------------------------------
--отчет о количестве уникальных покупателей и суммарной выручке по месяцам 

select
    COUNT(distinct s.customer_id) as total_customers,
    FLOOR(SUM(s.quantity * p.price)) as income,
    CONCAT(to_char(s.sale_date, 'YYYY'), '-', to_char(s.sale_date, 'MM')) as selling_month 
from sales as s
inner join products as p on s.product_id = p.product_id
group by selling_month 
order by selling_month;

----------------------------------------------
--отчет о покупателях, первая покупка которых состоялась в ходе проведения акций

select DISTINCT ON (customer)
    CONCAT(c.first_name, ' ', c.last_name) as customer,
    s.sale_date,
    CONCAT(e.first_name, ' ', e.last_name) as seller

from customers as c
inner join sales as s on c.customer_id = s.customer_id
inner join employees as e on s.sales_person_id = e.employee_id
inner join products as p on s.product_id = p.product_id 
where p.price = 0
group by 1, 2, 3;


