DROP table if exists goldusers_signup;

CREATE TABLE goldusers_signup 
(
userid int, gold_signup_date date);

INSERT INTO goldusers_signup VALUES
(1, '2017-09-22'), (3,'2017-04-21');

------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS users;
CREATE TABLE USERS
(
userid int, signup_date date);

INSERT INTO USERS VALUES(1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

-------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS sales;
CREATE TABLE sales ( userid int, created_date date, product_id int);

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);

-------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);
-------------------------------------------------------------------------------------------------------------------------------------------

select * from product;
select * from users;
select * from sales;
select * from goldusers_signup;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 1- what is the total amount each customer spent on Zomato*/

select s.userid, sum(p.price) as amt_spent
FROM
sales as s
join product as p
on s.product_id=p.product_id
Group by 1
order by 2 desc;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 2-How many days has each customer visited zomato*/

select count(distinct created_date) as visited_days, userid
from sales
group by 2
order by 2;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 3-What is the first product purchased by each customer*/

select *
FROM
(select *, rank() over (partition by userid order by created_date) as rnk
FROM sales) a
where a.rnk=1;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 4-What is the most purchased item on the menu and how many times was it purchased by all customers?*/

Select userid, count(userid) as cnt
from sales
where product_id=
(select product_id
from sales
group by 1
order by count(product_id) desc
limit 1)
GROUP BY 1
ORDER BY 2 desc;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 5-Which item was the most popular for each customer?*/

select * from
(select *, rank() over (partition by userid order by cnt desc) as rnk
from
(select userid, product_id, count(product_id) as cnt
from sales
group by 1,2
order by 1,3 desc) a) as b
where rnk=1;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 6-Which item was purchased first by the customer after they became a member*/

select * from
(
select userid, product_id, created_date, rank() over (partition by userid order by created_date) as rnk
from
(
select s.* , gs.gold_signup_date
from sales as s
join goldusers_signup as gs
on s.userid=gs.userid
where s.created_date>= gs.gold_signup_date) as a) as b
where b.rnk=1;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 7-Which item was purchased just before the customer became a member*/

select * from
(
select a.*, rank() over (partition by userid order by created_date desc) as rnk
from
(select s.* , gs.gold_signup_date
from sales as s
join goldusers_signup as gs
on s.userid=gs.userid
where s.created_date<= gs.gold_signup_date) as a) as b
where b.rnk=1;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 8- what is the total orders and amount spent by each user before they became a member*/

select userid, count(a.product_id) as No_of_Products_Purchased , sum(a.price) as Amt_spent
from
(select s.* , gs.gold_signup_date, p.price as price
from sales as s
join goldusers_signup as gs
on s.userid=gs.userid
join product as p
on p.product_id = s.product_id
where s.created_date<= gs.gold_signup_date) as a
group by 1
order by 1;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 9- If buying each product generates points for eg 5rs=2 zomato point and each product has different purchasing points
for ex P1 5rs=1 zomato points, for P2 10rs= 5 zomato points, for P3 5rs = 1 zomato points. 

part a- Calculate points collected by each customer?
part b - For which product most points have been given till now? */

/* part a- Calculate points collected by each customer? */

with t1 as (
select s.userid, s.product_id, p.price as price
from sales as s
join product as p
on p.product_id = s.product_id),

t2 as (
select userid, product_id, sum(t1.price) as amt
from t1
group by 2,1
order by 1,2),

t3 as (
select t2.*, 
case 
	when product_id =1 then t2.amt/5
    when product_id = 2 then t2.amt/2
    when product_id = 3 then t2.amt/5
end as points
from t2)

select t3.userid, sum(t3.points) as total_points_each_user, sum(t3.points)*2.5 as wallet_amt
from t3
group by 1
order by 1;

--------------------------------------------------------------------------------------------------------------------------------------------
/* part b - For which product most points have been given till now? */

with t1 as (
select s.userid, s.product_id, p.price as price
from sales as s
join product as p
on p.product_id = s.product_id),

t2 as (
select userid, product_id, sum(t1.price) as amt
from t1
group by 2,1
order by 1,2),

t3 as (
select t2.*, 
case 
	when product_id =1 then t2.amt/5
    when product_id = 2 then t2.amt/2
    when product_id = 3 then t2.amt/5
end as points
from t2)

Select *
from
(SELECT t3.product_id, sum(t3.points) as total_points_each_product
from t3
group by 1
order by 2 desc) a 
limit 1;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 10 - In the first one year after a customer joins the gold program (including their join date) irrespective of what
the customer has purchased they earn 5 zomato points for every 10 rs spent who earned more 1 or 3? and what are their
points earnings in 1st year? */

select a.userid, sum(price)*0.5 as points
from 
(
select s.userid, s.product_id, s.created_date, gs.gold_signup_date, p.price, datediff(s.created_date, gs.gold_signup_date) as days
from sales as s
join goldusers_signup as gs
on s.userid=gs.userid
join product as p
on s.product_id=p.product_id
where s.created_date>= gs.gold_signup_date
and datediff(s.created_date, gs.gold_signup_date)<365) as a
group by 1
order by 2 desc;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 11- rank all the transactions of the customers*/

select s.*, rank() over (partition by userid order by created_date) as rnk
from sales as s;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 12- rank all the transactions for each member whenever they are gold member for every non gold member transaction mark as na */

select a.userid, a.created_date, a.product_id,
case
    when a.gsid is not null then rank() over (partition by a.userid, a.gsdate is not null order by a.created_date)
    when a.gsid is null then "na"
end as rnk
from
(
select s.*, gs.userid as gsid, gs.gold_signup_date as gsdate
from sales as s
left join goldusers_signup as gs
on s.userid=gs.userid
and s.created_date>= gs.gold_signup_date 
) as a
order by 4;

--------------------------------------------------------------------------------------------------------------------------------------------
/* 13-create a cumulivate spend of each users accross all their transactions */

select s.*, p.price, sum(p.price) over (partition by s.userid order by s.created_date rows between unbounded preceding and current row) as cum
from sales as s
join product as p
on s.product_id=p.product_id;

