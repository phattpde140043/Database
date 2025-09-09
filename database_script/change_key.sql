-- Connect to pos DB
BEGIN;
Select reencrypt_customers('tranphuphat');
select reencrypt_data('tranphuphat');
COMMIT;

--connect to erp DB
BEGIN;
select reencrypt_data('tranphuphat');
COMMIT;

ALTER SYSTEM SET custom.key_constant TO 'tranphuphat';
SELECT pg_reload_conf();


----------------------- Test -----------------------------------------

Select * from customers WHERE 
    customer_id = 'CUST_000001';
	
SELECT 
    customer_id, 
    name, 
    convert_from(pgp_sym_decrypt(email::bytea, 'my_secret_key')::bytea,'UTF8') AS email, 
    convert_from(pgp_sym_decrypt(phone::bytea, 'my_secret_key')::bytea,'UTF8') AS phone
FROM 
    customers 
WHERE 
    customer_id = 'CUST_000001';

Update customers set email = encrypt_text('hung@gamil.com'), phone= encrypt_text('0869499499')

update employees set email = encrypt_text('hung@gamil.com');
Update suppliers set email = encrypt_text('hung@gamil.com'), phone= encrypt_text('0869499499');

Select * from employees ;
SELECT 
    employee_id, 
    name, 
    pgp_sym_decrypt(email::bytea, 'tranphuphat') AS email
FROM 
    employees ;

	
Select * from employees ;
SELECT 
    supplier_id, 
    name, 
    convert_from(pgp_sym_decrypt(email::bytea, 'my_secret_key')::bytea,'UTF8') AS email, 
    convert_from(pgp_sym_decrypt(phone::bytea, 'my_secret_key')::bytea,'UTF8') AS phone
FROM 
    suppliers ;