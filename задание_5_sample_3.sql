-- Найдите клиентов, у которых открыт продукт типа КРЕДИТ, и у которых сумма всех дебетовых
-- операций по таким продуктам превышает сумму всех кредитовых операций.

select  c.id as client_id, c.name as client_name, sum(case when r.dt = 1 then r.sum else 0 end) as total_debit, sum(case when r.dt = 0 then r.sum else 0 end) as total_debit
from clients c
join products p on c.id = p.client_ref
join product_type pt on p.product_type_id = pt.id
join accounts a on p.id = a.product_ref
join records r on a.id = r.acc_ref
where pt.name = 'КРЕДИТ' and p.close_date is null -- Только открытые продукты
group by c.id, c.name
having sum(case when r.dt = 1 then r.sum else 0 end) > sum(case when r.dt = 0 then r.sum else 0 end);

