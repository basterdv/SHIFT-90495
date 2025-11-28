-- В модель данных добавьте сумму договора по продукту. Заполните поле для всех продуктов
-- суммой минимальной дебетовой операции по счету для продукта типа КРЕДИТ, и суммой средней
-- кредитовой операции по счету продукта для продукта типа ДЕПОЗИТ или КАРТА.


-- Добавление поля sum_contract в таблицу products
alter table products add column sum_contract decimal(10, 2);

-- Проверяем что колонка добавлена
select * from products;

-- Заполнение поля sum_contract для продуктов типа КРЕДИТ
update products p
join product_type pt on p.product_type_id = pt.id
join accounts a on p.id = a.product_ref
join (select acc_ref, min(sum) as min_sum
from records
where dt = 1
group by acc_ref) r on a.id = r.acc_ref
set p.sum_contract = r.min_sum
where pt.name = 'КРЕДИТ';

-- Заполнение поля sum_contract для продуктов типа ДЕПОЗИТ или КАРТА
update products p
join product_type pt on p.product_type_id = pt.id
join accounts a on p.id = a.product_ref
join (select acc_ref, avg(sum) as avg_sum
from records
where dt = 0
group by acc_ref) r on a.id = r.acc_ref
set p.sum_contract = coalesce(r.avg_sum, 0)
where pt.name in ('ДЕПОЗИТ', 'КАРТА');


-- Проверяем что заполненно
select * from products;

