-- Сформируйте отчет, который содержит все счета, относящиеся к продуктам типа
-- ДЕПОЗИТ, принадлежащих клиентам, у которых имеется более одного открытого продукта

select a.id, a.name, a.saldo, a.acc_num, p.name as product_name
from accounts a
join products p on a.product_ref = p.id
join product_type pt on p.product_type_id = pt.id
join (
    select client_ref
    from products
    group by client_ref
    having count(*) > 1
) sub on p.client_ref = sub.client_ref
where pt.name = 'ДЕПОЗИТ';
