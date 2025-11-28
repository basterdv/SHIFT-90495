-- Удаляем базу данных если она существует
drop database if exists shift_db;

-- Создаем базу данных
create database if not exists shift_db;

-- Подключаемся к базе данных
use shift_db;

-- Создание таблицы tarifs (Тарифы)
create table tarifs (
    id int primary key,
    name varchar(100) not null,
    cost decimal(10, 2) not null 
);

-- Создание таблицы clients (Клиенты)
create table clients (
    id int primary key,
    name varchar(1000) not null,
    place_of_birth varchar(1000),
    date_of_birth date,
    address varchar(1000),
    passport varchar(100) not null unique
);

-- Создание таблицы product_type (Типы продуктов)
create table  product_type (
    id int primary key,
    name varchar(100) not null,
    begin_date date,
    end_date date,
    tarif_ref int,
    constraint fk_prod_type_tarif
        foreign key (tarif_ref)
        references tarifs (id) -- Внешний ключ на таблицу tarifs
);

-- Создание таблицы products (Продукты)
create table products (
    id int primary key,
    product_type_id int not null,
    name varchar(100) not null,
    client_ref int,
    open_date date,
    close_date date,
    constraint fk_products_type
        foreign key (product_type_id)
        references product_type(id), -- Внешний ключ на таблицу product_type
    constraint fk_products_client
        foreign key (client_ref)
        references clients (id) -- Внешний ключ на таблицу clients
);

-- Создание таблицы accounts (Счета)
create table accounts (
    id int primary key,
    name varchar(100) not null,
    saldo decimal(10, 2) default 0, 
    client_ref int,
    open_date date,
    close_date date,
    product_ref int,
    acc_num varchar(25), 
    constraint fk_accounts_client
        foreign key (client_ref)
        references clients (id), -- Внешний ключ на таблицу clients
        constraint fk_accounts_product
        foreign key (product_ref)
        references products (id) -- Внешний ключ на таблицу PRODUCTS
);

-- Создание таблицы records (Операции по счетам)
create table records (
    id int primary key,
    dt int,
    acc_ref int,
    open_date date ,
    sum decimal(10, 2),
    constraint fk_records_account
        foreign key (acc_ref)
        references accounts (id) -- Внешний ключ на таблицу accounts
);
