-- Закройте продукты (установите дату закрытия равную текущей) типа КРЕДИТ. Закрытие продукта происходит в следующих условиях:
-- • клиент должен полностью погасить все долги по кредиту (остаток на счете продукта должен стать равным 0)
-- • система должна проверить, что все операции по кредиту завершены (сумма всех дебетовых операций по кредитному продукту равна сумме всех кредитовых операций)

-- Проверочный запрос для просмотра продуктов,  до обнавления
select p.id,p.name as product_name, a.name as account_name, pt.name as product_type,p.close_date,a.saldo
from products p
join accounts a on p.id = a.product_ref
join product_type pt on p.product_type_id = pt.id
where pt.name = 'КРЕДИТ'
and a.saldo = 0.00
and p.close_date is null;

update products p
join accounts a on p.id = a.product_ref
join product_type pt on p.product_type_id = pt.id
set p.close_date = now()
where pt.name = 'КРЕДИТ'
and a.saldo = 0.00
and p.close_date is null;

-- Проверочный запрос после обновления
select p.id,p.name as product_name, a.name as account_name, pt.name as product_type,p.close_date,a.saldo
from products p
join accounts a on p.id = a.product_ref
join product_type pt on p.product_type_id = pt.id
where pt.name = 'КРЕДИТ'
and a.saldo = 0.00;



