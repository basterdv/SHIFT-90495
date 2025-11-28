-- Сформируйте выборку, которая содержит информацию о клиентах, которые полностью погасили
-- кредит, но при этом не закрыли продукт (по продукту есть операция новой выдачи кредита).
-- Выведите в выборке наименование продукта и сумму кредита и количество операций его
-- гашения.

select c.id, c.name as client_name, p.name as product_name, first_credit.credit_sum, 
payments.payment_count,payments.total_payments,  new_credit.new_credit_sum
from clients c
join products p on c.id = p.client_ref
join product_type pt on p.product_type_id = pt.id

-- Первая выдача кредита
join (select a.product_ref,sum(r.sum) as credit_sum
from records r
join accounts a on r.acc_ref = a.id
where r.dt = 1
and r.open_date = (
select min(r2.open_date)
from records r2
join accounts a2 on r2.acc_ref = a2.id
where a2.product_ref = a.product_ref and r2.dt = 1)
group by a.product_ref) first_credit on p.id = first_credit.product_ref

-- Операции погашения
join (select  a.product_ref,count(*) as payment_count,sum(r.sum) as total_payments
from records r
join accounts a on r.acc_ref = a.id
where  r.dt = 0
group by a.product_ref) payments on p.id = payments.product_ref

-- Новая выдача кредита (после полного погашения)
join (select a.product_ref,sum(r.sum) as new_credit_sum
from records r
join accounts a on r.acc_ref = a.id
where r.dt = 1
and r.open_date = (select max(r2.open_date) 
from records r2 
join accounts a2 on r2.acc_ref = a2.id
where a2.product_ref = a.product_ref and r2.dt = 1)
group by a.product_ref) new_credit on p.id = new_credit.product_ref
where pt.name = 'КРЕДИТ'
and p.close_date is null   
and payments.total_payments >= first_credit.credit_sum -- Проверяем, что сумма погашений не меньше суммы первоначального кредита   
and new_credit.product_ref = first_credit.product_ref; -- Проверяем, что дата новой выдачи позже даты первоначального кредита

