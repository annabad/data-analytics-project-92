--запрос для подсчета общего количества покупателей

select COUNT(customer_id) as customers_count
from customers;
--------------------
--отчет о топ-10 лучших продавцов и объеме их выручки

with full_employees as (
    select
        employee_id,
        CONCAT(first_name, ' ', last_name) as seller
    from employees
)

select
    fe.seller,
    COUNT(sale_date) as operations,
    FLOOR(SUM(s.quantity * p.price)) as income
from
    full_employees as fe
inner join sales as s on fe.employee_id = s.sales_person_id
inner join products as p using (product_id)
group by fe.seller
order by income desc
limit 10;

-----------------------
--отчет о продавцах, чья выручка ниже средней выручки среди всех продавцов

with full_employees as (
    select
        employee_id,
        CONCAT(first_name, ' ', last_name) as seller
    from employees
),

avg_incoms as (
    select
        fe.seller,
        COUNT(sale_date) as operations,
        FLOOR(SUM(s.quantity * p.price)) as income,
        FLOOR(SUM(s.quantity * p.price) / COUNT(sale_date)) as average_income
    from
        full_employees as fe
    inner join sales as s on fe.employee_id = s.sales_person_id
    inner join products as p using (product_id)
    group by fe.seller
    order by average_income desc
)

select
    seller,
    average_income
from avg_incoms
where average_income < (select AVG(average_income) from avg_incoms)
order by average_income;

--------------------------------
--отчет об объеме выручки по каждому продавцу и дню недели

with full_employees as (
    select
        employee_id,
        CONCAT(first_name, ' ', last_name) as seller
    from employees
),

sales_with_days as (
    select
        seller,
        sale_date,
        EXTRACT(isodow from sale_date) as week_day,
        s.quantity * p.price as day_income
    from full_employees as fe
    inner join sales as s on fe.employee_id = s.sales_person_id
    inner join products as p using (product_id)
)

select
    seller,
    TO_CHAR(sale_date, 'day') as day_of_week,
    FLOOR(SUM(day_income)) as income
from sales_with_days
group by seller, TO_CHAR(sale_date, 'day'), week_day
order by week_day;


-------------------------------------------
--отчет о количестве покупателей в разных возрастных группах: 16-25, 26-40 и 40+

select
    '16-25' as age_category,
    count(customer_id) as age_count
from customers
where age between 16 and 25

union

select
    '26-40' as age_category,
    count(customer_id) as age_count
from customers
where age between 26 and 40

union

select
    '40+' as age_category,
    count(customer_id) as age_count
from customers
where age > 40
order by age_category;

--------------------------------------------
--отчет о количестве уникальных покупателей и выручке, которую они принесли

with tab as (
    select
        extract(year from sale_date) as year_date,
        extract(month from sale_date) as month_date,
        count(distinct customer_id) as total_customers,
        floor(sum(quantity * price)) as income
    from sales
    inner join products on sales.product_id = products.product_id
group by 1, 2
order by 1, 2
)

select
total_customers,
income,
case
    when month_date < 10 then concat(year_date, '-0', month_date)
    else concat(year_date, '-', month_date)
end as selling_month
from tab
order by selling_month;

----------------------------------------------
--отчет о покупателях, первая покупка которых состоялась в ходе проведения акций

with full_customers as (
    select
        customer_id,
        CONCAT(first_name, ' ', last_name) as customer
    from customers
),

full_employees as (
    select
        employee_id,
        CONCAT(first_name, ' ', last_name) as seller
    from employees
),

sales_with_0 as (
    select
        s.customer_id,
        customer,
        sale_date,
        seller
    from sales as s
    inner join full_customers on s.customer_id = full_customers.customer_id
inner join full_employees as fe on s.sales_person_id = fe.employee_id
inner join products using (product_id) where price = 0
),

sales_with_0_min_date as (
select distinct
    customer_id,
    customer,
    seller,
    MIN(sale_date) over (partition by customer order by sale_date) as sale_date
from sales_with_0
)

select
	customer,
	sale_date,
	seller
from sales_with_0_min_date
order by customer_id;



