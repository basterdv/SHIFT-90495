-- Сформируйте выборку, которая содержит счета, относящиеся к продуктам типа ДЕПОЗИТ или
-- КАРТА, по которым были операции внесения средств на счет в рамках одного произвольного дня.

select a.id, a.name, a.saldo, a.acc_num, p.name as product_name
from accounts a
join products p on  a.product_ref = p.id
join records r on a.id = r.acc_ref
join product_type pt on p.product_type_id = pt.id
where pt.name in ('ДЕПОЗИТ', 'КАРТА')
and r.dt = 0
and date(r.open_date) = '2024-12-12';

