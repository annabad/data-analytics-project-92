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
    COUNT(s.sale_date) as operations,
    FLOOR(SUM(s.quantity * p.price)) as income
from
    full_employees as fe
inner join sales as s on fe.employee_id = s.sales_person_id
inner join products as p on s.product_id = p.product_id
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

avg_incomes as (
    select
        fe.seller,
        COUNT(s.sale_date) as operations,
        FLOOR(SUM(s.quantity * p.price)) as income,
        FLOOR(SUM(s.quantity * p.price) / COUNT(s.sale_date)) as average_income
    from
        full_employees as fe
    inner join sales as s on fe.employee_id = s.sales_person_id
    inner join products as p on s.product_id = p.product_id
    group by fe.seller
    order by average_income desc
)

select
    seller,
    average_income
from avg_incomes
where average_income < (select AVG(average_income) from avg_incomes)
order by average_income;

--------------------------------
--отчет об объемах выручки по каждому продавцу и дню недели

with full_employees as (
    select
        employee_id,
        CONCAT(first_name, ' ', last_name) as seller
    from employees
),

sales_with_days as (
    select
        fe.seller,
        s.sale_date,
        EXTRACT(isodow from s.sale_date) as week_day,
        s.quantity * p.price as day_income
    from full_employees as fe
    inner join sales as s on fe.employee_id = s.sales_person_id
    inner join products as p on s.product_id = p.product_id
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
    COUNT(customer_id) as age_count
from customers
where age between 16 and 25

union

select
    '26-40' as age_category,
    COUNT(customer_id) as age_count
from customers
where age between 26 and 40

union

select
    '40+' as age_category,
    COUNT(customer_id) as age_count
from customers
where age > 40
order by age_category;

--------------------------------------------
--отчет о количестве уникальных покупателей и выручке, которую они принесли

with tab as (
    select
        EXTRACT(year from s.sale_date) as year_date,
        EXTRACT(month from s.sale_date) as month_date,
        COUNT(distinct s.customer_id) as total_customers,
        FLOOR(SUM(s.quantity * p.price)) as income
    from sales as s
    inner join products as p on s.product_id = p.product_id
	group by year_date, month_date
	order by year_date, month_date
)

select
	total_customers,
	income,
	case
    	when month_date < 10 then CONCAT(year_date, '-0', month_date)
    	else CONCAT(year_date, '-', month_date)
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

cust_min_dates as (
    select distinct
        customer_id,
        MIN(sale_date)
            over (partition by customer_id order by sale_date)
        as sale_date
    from sales
),

cust_with_0 as (
    select distinct
        sales.customer_id,
        MIN(sales.sale_date)
            over (partition by sales.customer_id order by sales.sale_date)
        as sale_date
    from sales as s
    inner join products as p on s.product_id = p.product_id where price = 0
),



special_customers as (
    select
        t1.customer_id,
        t1.sale_date
    from cust_min_dates as t1
    inner join
        cust_with_0 as t2
        on t1.customer_id = t2.customer_id and t1.sale_date = t2.sale_date
),


tab_full_names as (
    select
        sc.customer_id,
        sc.customer,
        sc.sale_date,
        fe.seller
    from special_customers as sc
    inner join full_customers as fc on sc.customer_id = fc.customer_id
	inner join sales as s on sc.customer_id = s.customer_id 
		and sc.sale_date = s.sale_date
	inner join full_employees as fe on s.sales_person_id = fe.employee_id
)

select distinct
	tfn.customer,
	tfn.sale_date,
	tfn.seller
from tab_full_names as tfn;

