-- İlk olarak veritabanınımızı oluşturuyoruz.

create database kaggle_sales

-- Sonrasında tabolalarımızın sütunlarını oluşturup verisetimizi import ediyoruz.

create table sales_info 
(
	ID int primary key,
	ORDERID int,
	ORDERDETAILID int,
	DATE_ date,
	USERID int,
	USERNAME_ varchar,
	NAMESURNAME varchar ,
	STATUS_ int,
	ITEMID int,
	ITEMCODE int,
	ITEMNAME varchar,
	AMOUNT int,
	UNITPRICE varchar,
	PRICE varchar,
	TOTALPRICE varchar,
	CATEGORY1 varchar,
	CATEGORY2 varchar,
	CATEGORY3 varchar,
	CATEGORY4 varchar,
	BRAND varchar,
	USERGENDER varchar,
	USERBIRTHDATE date,
	REGION varchar,
	CITY varchar,
	TOWN varchar ,
	DISTRICT varchar,
	ADDRESSTEXT varchar 
)

----------------------------------------------------------------------------------------------------------

-- RFM ANALİZİ

----------------------------------------------------------------------------------------------------------

-- RFM analizinde ilk harfin açılımı olan Recency değerini bulacağız.

-- İlk olarak en son ne zaman alışveriş yapıldığını buluyor ve buna göre müşterilerin alışveriş sıklığını hesaplayacağız.

-- Recency

with last_order as (
select 
	namesurname as ad_soyad,
	max(date_) as last_orders
from
	sales_info
	group by 1
),

last_order_rec as (
select 
	ad_soyad,
	(select max(date_) from sales_info)-last_orders as recency
from last_order
	order by 2 
)

select
	ad_soyad,
	recency,
	ntile(8) over (order by recency) as recency_score
from last_order_rec

----------------------------------------------------------------------------------------------------------

-- Recency değerini bulduktan sonra şimde bizden şimdiye kadar ne kadar alışveriş yapmış onu buluyoruz.

-- Frequency

with total_orders as (
select 
	namesurname as ad_soyad,
	count(orderid) as frequency
from sales_info 
	group by 1
	order by 2 desc
)

select 
	ad_soyad,
	frequency,
	ntile(8) over (order by frequency desc) frequency_score
from total_orders

----------------------------------------------------------------------------------------------------------

-- Frequencyi de hesapladıktan sonra sıra monetary değerine yani müşterinin bize bugüne kadar ne kadar para kazandırdığını hesaplıyoruz.

-- Ek olarak RFM skorunu hesaplayabilmek adına monetary skorunu da hesapladık.

-- Monetary

with totalprice_num as (
select 
	namesurname as ad_soyad,
	totalprice::numeric as total_price_num
from sales_info
),
total_price as (
select
	ad_soyad,
	sum(total_price_num) as monetary
from totalprice_num 
	group by 1
	order by 2 desc
)

select 
	ad_soyad,
	monetary,
	ntile(8) over (order by monetary desc) as monetary_score
from total_price

----------------------------------------------------------------------------------------------------------

-- RFM skorunun hesaplanması ve müşteri segmentasyonunun yapılması

with recency as (
with last_order as (
select 
	namesurname as ad_soyad,
	max(date_) as last_orders
from
	sales_info
	group by 1
),

last_order_rec as (
select 
	ad_soyad,
	(select max(date_) from sales_info)-last_orders as recency
from last_order
	order by 2 
)

select
	ad_soyad,
	recency,
	ntile(5) over (order by recency) as recency_score
from last_order_rec
),

frequency as (
with total_orders as (
select 
	namesurname as ad_soyad,
	count(orderid) as frequency
from sales_info 
	group by 1
	order by 2 desc
)

select 
	ad_soyad,
	frequency,
	ntile(5) over (order by frequency) frequency_score
from total_orders
),

monetary as (
with totalprice_num as (
select 
	namesurname as ad_soyad,
	totalprice::numeric as total_price_num
from sales_info
),
total_price as (
select
	ad_soyad,
	sum(total_price_num) as monetary
from totalprice_num 
	group by 1
	order by 2 desc
)

select 
	ad_soyad,
	monetary,
	ntile(5) over (order by monetary desc) as monetary_score
from total_price
),

rfm_score as (
select 
	r.ad_soyad,
	recency,
	frequency,
	monetary,
	recency_score,
	frequency_score,
	monetary_score,
	concat(recency_score,frequency_score,monetary_score)::numeric as RFM_score
from 
	monetary m
join frequency f on m.ad_soyad = f.ad_soyad
join recency r on m.ad_soyad = r.ad_soyad
),

customers_segment as (
select 
	ad_soyad,
	recency,
	frequency,
	monetary,
	recency_score,
	frequency_score,
	monetary_score,
	RFM_score,
case when RFM_score between 111 and 222 then 'Champions'
	when RFM_score between 222 and 255 then 'potential_loyalists'
	when RFM_score between 255 and 355 then 'new_customers'
	when RFM_score between 355 and 455 then 'promising'
	else 'loyal_customers' end as customer_segment
from
	rfm_score
)

select * from customers_segment

select 
	count(ad_soyad) total_customers,
	customer_segment
from
	customers_segment
	group by 2
