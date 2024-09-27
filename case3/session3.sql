use case_study;

load data infile 'D:/CAMPUSX/case_study-SQL/session 3/sharktank2.csv'
INTO TABLE sharktank
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

select * from sharktank;

/* 1 Your Team have to  promote shark Tank India  season 4, 
The senior come up with the idea to show highest funding domain wise  
and you were assigned the task to  show the same.
 */

select industry,total_deal_amount_in_lakhs_ from
(
select industry, total_deal_amount_in_lakhs_, 
row_number() over(partition by industry order by total_deal_amount_in_lakhs_ desc) as 'rnk'
from sharktank group by industry, total_deal_amount_in_lakhs_
)t where rnk = 1
;

/* 2 You have been assigned the role of finding the domain 
where female as pitchers have female to male pitcher ratio >70%
 */
select * from sharktank;

select *, round(((female/male)*100),2) as 'percentage' from
(
select industry, sum(female_presenters) as 'female', sum(male_presenters) as 'male' 
from sharktank group by industry having female > 0 and male>0
)t where round(((female/male)*100),2) > 70
;

/* 3 You are working at marketing firm of Shark Tank India, 
you have got the task to determine volume of per year sale pitch made, 
pitches who received offer and pitches that were converted. 
Also show the percentage of pitches converted and percentage of pitches received. */
select * from sharktank;

select a.season_number, total, received, ((received/total)*100) as 'received_%',
accepted,((accepted/total)*100) as 'accepted_%' from
(
select season_number, count(startup_name) as 'total' from sharktank group by season_number
)a 
inner join
(
select season_number, count(startup_name) as 'received' from sharktank 
where received_offer = 'Yes' group by season_number 
)b on a.season_number = b.season_number 
inner join
(
select season_number, count(startup_name) as 'accepted' from sharktank 
where accepted_offer = 'Yes' group by season_number 
)c on b.season_number = c.season_number
;

/* 4 As a venture capital firm specializing in investing in startups 
featured on a renowned entrepreneurship TV show, 
how would you determine the season with the highest average monthly sales 
and identify the top 5 industries with the highest average monthly sales 
during that season to optimize investment decisions? */

select * from sharktank;

set @seas= (select season_number from 
(
select season_number, round(avg(monthly_sales_in_lakhs_),2) as 'avg_monthly_sales' from sharktank group by season_number
order by avg_monthly_sales desc limit 1
)a);

select @seas;

select industry, round(avg(monthly_sales_in_lakhs_),2) as 'avg_' from sharktank 
where season_number = @seas group by industry order by avg_ desc limit 5
;

/* 5.As a data scientist at our firm, your role involves solving real-world challenges 
like identifying industries with consistent increases in funds raised over multiple seasons. 
This requires focusing on industries where data is available across all three years.
Once these industries are pinpointed, your task is to delve into the specifics, 
analyzing the number of pitches made, offers received, and offers converted per season within each industry. */
select * from sharktank;

with valids as
(
select industry, 
max(case when season_number =1 then total_deal_amount_in_lakhs_ end) as season1,
max(case when season_number =2 then total_deal_amount_in_lakhs_ end) as season2,
max(case when season_number =3 then total_deal_amount_in_lakhs_ end) as season3
from sharktank group by industry having season2 > season1 and season3 > season2 and season1 != 0 
)
-- select * from valids

select b.season_number, a.industry, 
count(b.startup_name) as 'total',
count(case when b.received_offer='Yes' then b.startup_name end) as 'received',
count(case when b.accepted_offer='Yes' then b.startup_name end) as 'accepted' 
from valids as a inner join sharktank as b on a.industry=b.industry
group by b.season_number, a.industry
;

/* 6. Every shark want to  know in how much year their investment will be returned, 
so you have to create a system for them , where shark will enter the name of the startup's  
and the based on the total deal and quity given in how many years their principal amount will be returned.
 */

select * from sharktank;
delimiter //
create procedure tot (in startup varchar(100))
begin
	case
		when(select accepted_offer = 'No' from sharktank where startup_name = startup)
			then select 'TOT time cannot be calculated as startup didnt accept offer';
		when (select accepted_offer = 'Yes' and yearly_revenue_in_lakhs_='Not Mentioned' from sharktank where startup_name=startup)
			then select 'TOT cannot calculated as past data is not available';
		else
        select `startup_name`, `yearly_revenue_in_lakhs_`,`total_deal_amount_in_lakhs_`,`total_deal_equity_%_`,
		`total_deal_amount_in_lakhs_`/(`total_deal_equity_%_`*100)*`yearly_revenue_in_lakhs_` as 'years' from sharktank
        where startup_name = startup;
	end case;
    end;
// delimiter ;

drop procedure tot;

call tot('FirstBudOrganics');

/* 7. In the world of startup investing, we're curious to know which big-name investor, 
often referred to as "sharks," tends to put the most money into each deal on average. 
This comparison helps us see who's the most generous with their investments and how they measure up against their fellow investors.
 */

select * from sharktank;

select sharkname, round(avg(investment),2)  as 'average' from
(
SELECT `namita_investment_amount_in lakhs_` AS investment, 'Namita' AS sharkname FROM sharktank WHERE `namita_investment_amount_in lakhs_` > 0
union all
SELECT `vineeta_investment_amount_in_lakhs_` AS investment, 'Vineeta' AS sharkname FROM sharktank WHERE `vineeta_investment_amount_in_lakhs_` > 0
union all
SELECT `anupam_investment_amount_in_lakhs_` AS investment, 'Anupam' AS sharkname FROM sharktank WHERE `anupam_investment_amount_in_lakhs_` > 0
union all
SELECT `aman_investment_amount_in_lakhs_` AS investment, 'Aman' AS sharkname FROM sharktank WHERE `aman_investment_amount_in_lakhs_` > 0
union all
SELECT `peyush_investment_amount__in_lakhs_` AS investment, 'peyush' AS sharkname FROM sharktank WHERE `peyush_investment_amount__in_lakhs_` > 0
union all
SELECT `amit_investment_amount_in_lakhs_` AS investment, 'Amit' AS sharkname FROM sharktank WHERE `amit_investment_amount_in_lakhs_` > 0
union all
SELECT `ashneer_investment_amount` AS investment, 'Ashneer' AS sharkname FROM sharktank WHERE `ashneer_investment_amount` > 0
)k group by sharkname
;


/* 8. Develop a system that accepts inputs for the season number and the name of a shark. 
The procedure will then provide detailed insights into the total investment made by  that specific shark 
across different industries during the specified season. 
Additionally, it will calculate the percentage of their investment in each sector relative to the total investment 
in that year, giving a comprehensive understanding of the shark's investment distribution and impact. */

select * from sharktank;

delimiter //
create procedure getseasoninvestment(in season int, sharkname varchar (100))
begin
	case
		when sharkname= 'namita'
        then
        set @total = (select sum(`namita_investment_amount_in lakhs_`) from sharktank  where season_number=season) ;
        select industry, sum(`namita_investment_amount_in lakhs_`) as 'summ' ,
        round(((sum(`namita_investment_amount_in lakhs_`)/@total)*100),2) as 'percent_invested'
        from sharktank 
        where season_number= season and `namita_investment_amount_in lakhs_` > 0
        group by industry;
	
		
        when sharkname= 'vineeta'
        then
        set @total = (select sum(`vineeta_investment_amount_in_lakhs_`) from sharktank  where season_number=season) ;
        select industry, sum(`vineeta_investment_amount_in_lakhs_`) as 'summ' ,
        round(((sum(`vineeta_investment_amount_in_lakhs_`)/@total)*100),2) as 'percent_invested'
        from sharktank 
        where season_number= season and `vineeta_investment_amount_in_lakhs_` > 0
        group by industry;
        
        
        when sharkname= 'anupam'
        then
        set @total = (select sum(`anupam_investment_amount_in_lakhs_`) from sharktank  where season_number=season) ;
        select industry, sum(`anupam_investment_amount_in_lakhs_`) as 'summ' ,
        round(((sum(`anupam_investment_amount_in_lakhs_`)/@total)*100),2) as 'percent_invested'
        from sharktank 
        where season_number= season and `anupam_investment_amount_in_lakhs_` > 0
        group by industry;
        
        
        when sharkname= 'aman'
        then
        set @total = (select sum(`aman_investment_amount_in_lakhs_`) from sharktank  where season_number=season) ;
        select industry, sum(`aman_investment_amount_in_lakhs_`) as 'summ' ,
        round(((sum(`aman_investment_amount_in_lakhs_`)/@total)*100),2) as 'percent_invested'
        from sharktank 
        where season_number= season and `aman_investment_amount_in_lakhs_` > 0
        group by industry;
        
        
        when sharkname= 'peyush'
        then
        set @total = (select sum(`peyush_investment_amount__in_lakhs_`) from sharktank  where season_number=season) ;
        select industry, sum(`peyush_investment_amount__in_lakhs_`) as 'summ' ,
        round(((sum(`peyush_investment_amount__in_lakhs_`)/@total)*100),2) as 'percent_invested'
        from sharktank 
        where season_number= season and `peyush_investment_amount__in_lakhs_` > 0
        group by industry;
        
        when sharkname= 'amit'
        then
        set @total = (select sum(`amit_investment_amount_in_lakhs_`) from sharktank  where season_number=season) ;
        select industry, sum(`amit_investment_amount_in_lakhs_`) as 'summ' ,
        round(((sum(`amit_investment_amount_in_lakhs_`)/@total)*100),2) as 'percent_invested'
        from sharktank 
        where season_number= season and `amit_investment_amount_in_lakhs_` > 0
        group by industry;
        
        
        when sharkname= 'ashneer'
        then
        set @total = (select sum(`ashneer_investment_amount`) from sharktank  where season_number=season) ;
        select industry, sum(`ashneer_investment_amount`) as 'summ' ,
        round(((sum(`ashneer_investment_amount`)/@total)*100),2) as 'percent_invested'
        from sharktank 
        where season_number= season and `ashneer_investment_amount` > 0
        group by industry;
        
        
		else
			select 'Incorrect input';
	end case ;
end; //
delimiter ;

-- drop procedure getseasoninvestment;

call getseasoninvestment (1,'anupam')