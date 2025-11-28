-- Закройте продукт типа КАРТА, который был открыт первым, если у клиента имеется более 20-ти
-- карт с ненулевым остатком. Средства со счета закрываемой карты перечислить на карту, открытую
-- второй.

delimiter $$

create procedure Normalize_Account_Balances()
begin
    declare max_id int;
    declare current_id int;

    -- Удаляем временные таблицы, если они уже существуют
    drop temporary table if exists temp_client_card_count;
    drop temporary table if exists temp_first_second_cards;
    drop temporary table if exists temp_compensation_records;

   
    -- Определение клиентов с более чем 20 картами с ненулевым остатком
	create temporary table temp_client_card_count as
    select a.client_ref as client_id,
    count(a.id) as card_count
    from accounts a
    join products p on a.product_ref = p.id
    join product_type pt on p.product_type_id = pt.id
    where pt.name = 'КАРТА' and a.saldo <> 0
    group by a.client_ref
    having card_count > 20;

    -- Проверка клиентов с более чем 20 картами с ненулевым остатком
    select * from temp_client_card_count;

    --  Определение первой и второй открытых карт для каждого клиента      
	create temporary table temp_first_second_cards as
    select client_id, first_value(account_id) over (partition by client_id order by open_date) as first_card_id,first_value(account_id) over (partition by client_id order by open_date rows between 1 following and 1 following) as second_card_id
    from (select a.id as account_id, a.saldo as current_saldo, a.client_ref as client_id, p.open_date
    from accounts a
    join products p on a.product_ref = p.id
    join product_type pt on p.product_type_id = pt.id
    where pt.name = 'КАРТА' and a.saldo <> 0 and a.client_ref in (select client_id from temp_client_card_count)) as subquery;

    -- Проверка первой и второй открытых карт для каждого клиента
    select * from temp_first_second_cards where second_card_id is not null;

    -- Закрытие первой карты и перечисление средств на вторую карту
    update accounts a1
    join temp_first_second_cards t on a1.id = t.first_card_id
    join accounts a2 on t.second_card_id = a2.id
    set a1.saldo = 0, a1.close_date = curdate(), a2.saldo = a2.saldo + a1.saldo
    where t.first_card_id is not null and t.second_card_id is not null;

    -- Составление записей в таблице records для перечисления средств
    create temporary table temp_compensation_records as
    select t.first_card_id as from_account_id, t.second_card_id as to_account_id, a1.saldo as transfer_amount,  current_id + row_number() over (order by t.client_id) - 1 as new_id
    from temp_first_second_cards t
    join accounts a1 on t.first_card_id = a1.id
    join accounts a2 on t.second_card_id = a2.id
    where t.first_card_id is not null and t.second_card_id is not null and a1.saldo <> 0;

    -- Т.к. заполняю таблицы без автоинкремента, то в ручную устанавлмваю id
    select max(id) into max_id from records;
    set current_id = max_id + 1;

     -- Проверка временной таблицы новых записей
     select * from temp_compensation_records;

    -- Вставка новых записей в таблицу records
    insert into records (id, acc_ref, dt, open_date, sum)
    select new_id, from_account_id, 1 AS dt,  -- Дебет с первой карты
    curdate() as open_date, transfer_amount
    from  temp_compensation_records;

    insert into records (id, acc_ref, dt, open_date, sum)
    select new_id + 1, to_account_id, 0 as dt,  -- Кредит на вторую карту
    curdate() as open_date, transfer_amount
    from temp_compensation_records;

     -- Проверка вставленных записей в таблицу records
     select * from records where id >= max_id + 1;

    -- Удалить временные таблицы
     drop temporary table if exists temp_client_card_count;
     drop temporary table if exists temp_first_second_cards;
	 drop temporary table if exists temp_compensation_records;

end $$

delimiter ;

call Normalize_Account_Balances();









