-- Calculating weightage of each stock holding in each mutual fund
select temp.scheme_name, temp.stock_name, temp.quantity, 
(quantity::NUMERIC/MAX(total_quantity))*100 as stock_weightage
from
(select df.scheme_name , ffh.stock_name , ffh.quantity,
SUM(ffh.quantity::NUMERIC) over (partition by scheme_name) as total_quantity
from fact_fund_holdings ffh
join dim_fund df
on df.fund_key = ffh.fund_key) temp
group by temp.scheme_name, temp.stock_name, temp.quantity
order by temp.scheme_name asc, temp.quantity desc;


-- Top 10 stocks by scheme_type on the basis of total_value
select *
from
(select df.scheme_type, ffh.stock_name ,ffh.industry , sum(ffh.market_value_in_lacs::NUMERIC) as total_value,
	row_number() over (partition by df.scheme_type order by sum(ffh.market_value_in_lacs::NUMERIC) desc) as num
from fact_fund_holdings ffh
join dim_fund df
on ffh.fund_key = df.fund_key
group by df.scheme_type , ffh.stock_name, ffh.industry) temp
where num <= 10;


-- Overlap between Large & Mid Cap and Mid Cap fund of LIC
with fund_holdings as (
select df.scheme_name, ffh.stock_name,
        (ffh.market_value_in_lacs::numeric / 
         sum(ffh.market_value_in_lacs::numeric) over (partition by df.scheme_name)) * 100 as stock_weightage
from fact_fund_holdings ffh
join dim_fund df on ffh.fund_key = df.fund_key
where df.scheme_name in ('LIC MF Large & Mid Cap Fund', 'LIC MF Mid Cap Fund'))
select a.stock_name, sum(least(a.stock_weightage, b.stock_weightage)) as overlap_pct
from fund_holdings a
join fund_holdings b 
on a.stock_name = b.stock_name
and a.scheme_name = 'LIC MF Large & Mid Cap Fund'
and b.scheme_name = 'LIC MF Mid Cap Fund'
group by a.stock_name
order by overlap_pct desc;


-- CAGR for the year 2024
with cte as (select temp2.fund_key,
    MAX(case when  temp2.val = 1 then temp2.nav::NUMERIC end) AS start_nav,
    MAX(case when  temp2.val = 2 then temp2.nav::NUMERIC end) AS end_nav
from  
(select temp1.*,
    ROW_NUMBER() OVER (PARTITION BY fund_key ORDER BY date ASC) AS val
from 
(select dd.date, ff.fund_key, ff.nav
from fact_fund ff
join dim_date dd
on ff.date_id = dd.date_id
where dd.date in ('2024-01-01', '2024-12-31')) temp1
) temp2
GROUP BY temp2.fund_key)
select df.scheme_name, cte.fund_key, cte.start_nav, cte.end_nav,
((cte.end_nav/cte.start_nav)-1)*100 as CAGR_2024
from cte
join dim_fund df
on cte.fund_key = df.fund_key;


-- Compared CAGR for Mutual funds and tickers for 2024
with ticker_cagr as		 -- ticker_cagr
(with cte as (select temp2.ticker_id,
    MAX(case when  temp2.num = 1 then temp2.value::NUMERIC end) AS start_value,
    MAX(case when  temp2.num = 2 then temp2.value::NUMERIC end) AS end_value
from  
(select temp1.*,
    ROW_NUMBER() OVER (PARTITION BY ticker_id ORDER BY date ASC) AS num
from 
(select dd.date, ft.ticker_id, ft.value
from fact_tickers ft
join dim_date dd
on ft.date_id = dd.date_id
where dd.date in ('2024-01-01', '2024-12-31')) temp1
) temp2
GROUP BY temp2.ticker_id)
select dt.ticker as name,
((cte.end_value/cte.start_value)-1)*100 as CAGR_2024
from cte
join dim_ticker dt
on cte.ticker_id = dt.ticker_id),
fund_cagr as		-- fund_cagr
(with cte as (select temp2.fund_key,
    MAX(case when  temp2.val = 1 then temp2.nav::NUMERIC end) AS start_nav,
    MAX(case when  temp2.val = 2 then temp2.nav::NUMERIC end) AS end_nav
from  
(select temp1.*,
    ROW_NUMBER() OVER (PARTITION BY fund_key ORDER BY date ASC) AS val
from 
(select dd.date, ff.fund_key, ff.nav
from fact_fund ff
join dim_date dd
on ff.date_id = dd.date_id
where dd.date in ('2024-01-01', '2024-12-31')) temp1
) temp2
GROUP BY temp2.fund_key)
select df.scheme_name as name, 
((cte.end_nav/cte.start_nav)-1)*100 as CAGR_2024
from cte
join dim_fund df
on cte.fund_key = df.fund_key )
select * 	-- merging both
from fund_cagr
union all 
select * 
from ticker_cagr
order by cagr_2024 desc;



   
  
  