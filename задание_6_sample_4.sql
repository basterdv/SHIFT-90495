-- В результате сбоя в базе данных разъехалась информация между остатками и операциями по
-- счетам. Напишите нормализацию (процедуру выравнивающую данные), которая найдет такие
-- счета и восстановит остатки по счету. Необходимо таким клиентам выплатить компенсацию в
-- размере 1% от восстановленного остатка счета (для счетов, относящихся к продукту типа
-- ДЕПОЗИТ).

-- Процедура для восстановления остатков по 
delimiter $$ 

create procedure Normalize_Account_Balances()
begin
    declare max_id int;
    declare current_id int;

    -- Удаляем временные таблицы, если они уже существуют
    drop temporary table if exists  temp_account_balance_diff;
    drop temporary table if exists temp_compensation;
    drop temporary table if exists temp_new_records;

    --  Определяем разницу между остатками и суммами операций
    create temporary table temp_account_balance_diff as
    select a.id as account_id, a.saldo as current_saldo,
    coalesce(sum(case when r.dt = 0 then r.sum else -r.sum end), 0) as recalculated_saldo,
    (a.saldo - coalesce(sum(case when r.dt = 0 then r.sum else -r.sum end), 0)) as saldo_diff
    from accounts a left join records r on a.id = r.acc_ref
    group by a.id, a.saldo;

    -- Проверяем разницу между остатками и пересчитанными остатками
    select * from temp_account_balance_diff;

    --  Восстонавливаем остатки по счетам
    update accounts a
    join temp_account_balance_diff t on a.id = t.account_id
    set a.saldo = t.recalculated_saldo;

    -- Проверяем обновление остатков по счетам
    select * from accounts where id in (select account_id from temp_account_balance_diff);

    -- Выполняем компенсацию для счетов, относящихся к продукту типа 'ДЕПОЗИТ'
    create temporary table temp_compensation as
    select a.id as account_id, a.client_ref as client_id, t.saldo_diff * -0.01 as compensation_amount  -- Компенсация 1% от восстановленного остатка
    from accounts a
    join temp_account_balance_diff t on a.id = t.account_id
    join products p on a.product_ref = p.id
    join product_type pt on p.product_type_id = pt.id
    where pt.name = 'ДЕПОЗИТ'
    and t.saldo_diff < 0;  -- Проверяем чтобы компенсация была если остаток был меньше, чем должно быть

    -- Проверка временной таблицы компенсации
    select * from temp_compensation;

    -- Т.к. заполняю таблицы без автоинкремента, то в ручную устанавлмваю id
    select max(id) into max_id from records;
    set current_id = max_id + 1;

    --  Обновляем остатки по счетам с учетом компенсации
    update accounts a
    join temp_compensation t on a.id = t.account_id
    set a.saldo = a.saldo - t.compensation_amount;

    -- Проверка обновленных остатков по счетам после компенсации
    select * from accounts where id in (select account_id from temp_compensation);

    -- Создаем записи о выплате компенсации в таблице records
    create temporary table temp_new_records as
    select current_id + row_number() over (order by t.account_id) - 1 as new_id, t.account_id, 0 as dt,  -- Компенсация считается кредитом
	curdate() as open_date, t.compensation_amount
    from temp_compensation t;

    -- Проверка временной таблицы новых записей
    select * from temp_new_records;

    -- Вставляем новые записи в таблицу records
    insert into records (id, acc_ref, dt, open_date, sum)
    select new_id, account_id, dt, open_date, compensation_amount
    from temp_new_records;

    -- Проверка вставленных записей в таблицу records
    select * from records where id >= max_id + 1;

    -- Удаляем временные таблицы
    drop temporary table if exists temp_account_balance_diff;
    drop temporary table if exists temp_compensation;
    drop temporary table if exists temp_new_records;
end $$

delimiter ;

-- Вызов процедуры
call Normalize_Account_Balances();




