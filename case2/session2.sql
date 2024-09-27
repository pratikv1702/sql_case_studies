
load data infile 'D:/CAMPUSX/case_study-SQL/session 2/my_playstore.csv'
into table playstore
fields terminated by ','
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;

use case_study;
SELECT * FROM case_study.playstore;

-- -----------------------------------------------------------------------------------------------------------------------------
/* 1.You're working as a market analyst for a mobile app development company. 
Your task is to identify the most promising categories(TOP 5) for launching new free apps based on their average ratings.*/

select category, round(avg(rating),2) as 'rat' from playstore where type= 'free'
group by category order by rat desc limit 5;

/* 2. As a business strategist for a mobile app company,
your objective is to pinpoint the three categories that generate the most revenue from paid apps. 
This calculation is based on the product of the app price and its number of installations.
select category, round(sum(revenue),2) as rev from */

select category, round(avg(rev),2) as 'revenue' from
(
select *, (installs * price) as 'rev' from playstore where type = 'paid'
)t group by category order by revenue desc limit 3
; 


/* 3. As a data analyst for a gaming company, 
you're tasked with calculating the percentage of games within each category. 
This information will help the company understand the distribution of gaming apps across different categories. */

select *,(cnt/(select count(*) from playstore))*100 as 'playstore' from
(
select category, count(app) as 'cnt' from playstore group by category
)t
;

/* 4. As a data analyst at a mobile app-focused market research firm,
you'll recommend whether the company should develop paid or free apps for each category based
 on the  ratings of that category.
 */
with t1 as
( 
select category, round(avg(rating),2) as 'paid' from playstore where type='paid' group by category
),
t2 as
(
select category, round(avg(rating),2) as 'free' from playstore where type='free' group by category
)
select *, if(paid > free, 'develop paid apps','develop unpaid apps') as 'decision' from
(
select a.category, paid, free from t1 as a inner join t2 as b on a.category = b.category
)k
;

/* 5.Suppose you're a database administrator, your databases have been hacked  
and hackers are changing price of certain apps on the database , 
its taking long for IT team to neutralize the hack , 
however you as a responsible manager  dont want your data to be changed , 
do some measure where the changes in price can be recorded as you cant stop hackers from making changes */


create table pricechangelog(
app varchar(255),
old_price decimal(10,2),
new_price decimal(10,2),
operation_type varchar(255),
operation_date timestamp
);

select * from pricechangelog;

create table play as select * from playstore;

select * from play;

DELIMITER //
create trigger price_change_log
after update
on play
for each row
begin
	insert into pricechangelog( app, old_price, new_price, operation_type, operation_date)
    values(new.app, old.price, new.price, 'update', current_timestamp);
end;
// DELIMITER ;

SELECT * FROM play;

set sql_safe_updates = 0;

update play
set price = 11
where app ='Sketch - Draw & Paint';

-- DROP TRIGGER price_change_log;  


/* 6. your IT team have neutralize the threat,  
however hacker have made some changes in the prices, 
but becasue of your measure you have noted the changes ,
now you want correct data to be inserted into the database.*/

select * from play as a inner join pricechangelog as b on a.app = b.app   ;

-- drop trigger price_change_log

update play as a 
inner join pricechangelog as b on a.app=b.app
set a.price=b.old_price;

select * from play where app = 'Sketch - Draw & Paint';


/* 7. As a data person you are assigned the task to investigate the correlation between 
 two numeric factors: app ratings and the quantity of reviews.
 */

-- corr = sum ((x-x')*(y-y')) / sum ((sqrt(x-x')^2)*(sqrt(y-y')^2))

select * from playstore;

set @x = (select round(avg(rating),2) from playstore);
set @y = (select round(avg(reviews),2) from playstore);

with t as 
(
select *, (rat*rat) as 'sqr_x', (rev*rev) as 'sqr_y' from
(
select rating, @x, round((rating-@x),2) as 'rat', reviews, @y, round((reviews-@y),2) as 'rev' from playstore
)k
)

-- select *from t

select @numerator := sum((rat*rev)), @deno1 := sum(sqr_x), @deno2:= sum(sqr_y) from t;
select (@numerator/ (sqrt(@deno1 * @deno2))) as 'corr_coef'
;

/* 8. Your boss noticed  that some rows in genres columns have multiple generes in them,
 which was creating issue when developing the  recommendor system from the data 
 he/she asssigned you the task to clean the genres column and make two genres out of it, 
 rows that have only one genre will have other column as blank.*/

select * from playstore;

DELIMITER //
CREATE FUNCTION f_name(a VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    SET @l = LOCATE(';', a);

    SET @s = IF(@l > 0, LEFT(a, @l - 1), a);

    RETURN @s;
END//
DELIMITER ;

select f_name('Art & Design;Pretend Play')


-- function for second genre
DELIMITER //
create function l_name(a varchar(100))
returns varchar(100)
deterministic 
begin
   set @l = locate(';',a);
   set @s = if(@l = 0 ,' ',substring(a,@l+1, length(a)));
   
   return @s;
end //
DELIMITER ;

select app, genres, f_name(genres) as 'gene 1', l_name(genres) as 'gene 2' from playstore

