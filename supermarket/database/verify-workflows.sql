-- Run after schema.sql and seed.sql on the demo. All fixture rows are rolled back.
BEGIN;

DO $$
DECLARE
    product_id bigint := (SELECT id FROM items1 WHERE item_code = 'HH001');
    cashier_id bigint := (SELECT id FROM employees1 WHERE employee_code = 'BH01');
    first_order bigint;
    next_order bigint;
    member_id bigint;
    counter_id bigint;
    challenge_id uuid := '10000000-0000-4000-8000-000000000001';
    new_challenge_id uuid := '10000000-0000-4000-8000-000000000002';
    next_challenge_id uuid := '10000000-0000-4000-8000-000000000003';
    code_digest bytea := sha256(convert_to('QA code proof', 'UTF8'));
    wrong_code_digest bytea := sha256(convert_to('QA wrong proof', 'UTF8'));
    setup_digest bytea := sha256(convert_to('QA setup proof', 'UTF8'));
    sample_password_hash text := 'pbkdf2-sha256$600000$' || repeat('A', 22) || '==$' || repeat('A', 43) || '=';
BEGIN
    first_order := place_online_order1('QA-PHONE-ORDER', 'QA delivery', '0900000551',
        'QA address', ARRAY[product_id], ARRAY[1]);
    SELECT id INTO STRICT member_id FROM customers1
    WHERE phone = '0900000551' AND is_member AND email IS NULL AND password_hash IS NULL;
    ASSERT EXISTS (SELECT 1 FROM online_orders1 WHERE id = first_order AND customer_id = member_id
        AND delivery_name = 'QA delivery' AND status = 'PENDING');
    ASSERT EXISTS (SELECT 1 FROM online_order_details1 WHERE order_id = first_order AND item_id = product_id);

    next_order := place_online_order1('QA-PHONE-REPEAT', 'Second recipient', '+84900000551',
        'Another address', ARRAY[product_id], ARRAY[1]);
    ASSERT EXISTS (SELECT 1 FROM online_orders1 WHERE id = next_order AND customer_id = member_id);
    ASSERT EXISTS (SELECT 1 FROM customers1 WHERE id = member_id
        AND full_name = 'QA delivery' AND address = 'QA address');

    counter_id := record_counter_sale('QA-PHONE-COUNTER', cashier_id, timestamp '2026-11-14 09:00',
        jsonb_build_array(jsonb_build_object('item_id', product_id, 'quantity', 1, 'unit_price', 38000)),
        NULL, '0900000553');
    ASSERT EXISTS (SELECT 1 FROM sale_transactions1 sale JOIN customers1 c ON c.id = sale.customer_id
        WHERE sale.id = counter_id AND c.phone = '0900000553' AND c.is_member AND c.email IS NULL
          AND c.address IS NULL AND c.password_hash IS NULL);
    next_order := place_online_order1('QA-COUNTER-TO-ONLINE', 'Recipient', '+84900000553',
        'QA address', ARRAY[product_id], ARRAY[1]);
    ASSERT EXISTS (SELECT 1 FROM online_orders1 orders JOIN sale_transactions1 sale
        ON orders.customer_id = sale.customer_id WHERE orders.id = next_order AND sale.id = counter_id);
    counter_id := record_counter_sale('QA-ANONYMOUS-COUNTER', cashier_id, timestamp '2026-11-14 09:00',
        jsonb_build_array(jsonb_build_object('item_id', product_id, 'quantity', 1, 'unit_price', 38000)));
    ASSERT EXISTS (SELECT 1 FROM sale_transactions1 WHERE id = counter_id AND customer_id IS NULL);

    ASSERT register_member1('QA web', '0900000554', 'qa-web-member@example.test', 'QA address', 'QA hash') = 1;
    ASSERT register_member1('QA duplicate', '0900000551', 'qa-web-duplicate@example.test', 'QA address', 'QA hash') = 2;

    ASSERT begin_member_account_setup1('0900000554', challenge_id, code_digest) = 'INELIGIBLE';
    ASSERT begin_member_account_setup1('0900000599', challenge_id, code_digest) = 'INELIGIBLE';
    ASSERT begin_member_account_setup1('+84900000551', challenge_id, code_digest) = 'ISSUED';
    ASSERT begin_member_account_setup1('0900000551', new_challenge_id, code_digest) = 'RATE_LIMITED';
    ASSERT complete_member_account_setup1(challenge_id, setup_digest, 'qa-setup@example.test', sample_password_hash)
        = 'INVALID_CHALLENGE';

    FOR attempt IN 1..5 LOOP
        ASSERT verify_member_account_phone1(challenge_id, wrong_code_digest, setup_digest) = 'INCORRECT_CODE';
    END LOOP;
    ASSERT verify_member_account_phone1(challenge_id, code_digest, setup_digest) = 'ATTEMPTS_EXHAUSTED';
    UPDATE member_account_verifications1
    SET issued_at = clock_timestamp() - interval '2 minutes',
        request_window_started_at = clock_timestamp() - interval '6 minutes',
        requests_in_window = 5
    WHERE customer_id = member_id;
    ASSERT begin_member_account_setup1('0900000551', new_challenge_id, code_digest) = 'RATE_LIMITED';
    UPDATE member_account_verifications1
    SET issued_at = clock_timestamp() - interval '6 minutes',
        request_window_started_at = clock_timestamp() - interval '61 minutes'
    WHERE customer_id = member_id;
    ASSERT verify_member_account_phone1(challenge_id, code_digest, setup_digest) = 'EXPIRED';
    ASSERT begin_member_account_setup1('0900000551', new_challenge_id, code_digest) = 'ISSUED';
    ASSERT verify_member_account_phone1(challenge_id, code_digest, setup_digest) = 'INVALID_CHALLENGE';
    ASSERT verify_member_account_phone1(new_challenge_id, code_digest, setup_digest) = 'VERIFIED';
    ASSERT verify_member_account_phone1(new_challenge_id, code_digest, setup_digest) = 'INVALID_CHALLENGE';
    ASSERT complete_member_account_setup1(new_challenge_id, wrong_code_digest, 'qa-setup@example.test',
        sample_password_hash) = 'INVALID_CHALLENGE';
    UPDATE member_account_verifications1
    SET issued_at = clock_timestamp() - interval '12 minutes',
        request_window_started_at = clock_timestamp() - interval '12 minutes 10 seconds',
        verified_at = clock_timestamp() - interval '11 minutes'
    WHERE customer_id = member_id;
    ASSERT complete_member_account_setup1(new_challenge_id, setup_digest, 'qa-setup@example.test', sample_password_hash)
        = 'EXPIRED';
    ASSERT begin_member_account_setup1('0900000551', next_challenge_id, code_digest) = 'ISSUED';
    ASSERT verify_member_account_phone1(next_challenge_id, code_digest, setup_digest) = 'VERIFIED';
    ASSERT complete_member_account_setup1(next_challenge_id, setup_digest, 'QA-Web-Member@example.test',
        sample_password_hash) = 'DUPLICATE_EMAIL';
    ASSERT complete_member_account_setup1(next_challenge_id, setup_digest, 'qa-setup@example.test',
        'not-a-password-hash') = 'INVALID_CREDENTIALS';
    ASSERT complete_member_account_setup1(next_challenge_id, setup_digest, ' QA-Setup@Example.Test ',
        sample_password_hash) = 'COMPLETED';
    ASSERT complete_member_account_setup1(next_challenge_id, setup_digest, 'qa-other@example.test',
        sample_password_hash) = 'INVALID_CHALLENGE';
    ASSERT EXISTS (SELECT 1 FROM customers1 c WHERE c.id = member_id AND c.email = 'qa-setup@example.test'
        AND c.account_setup_at IS NOT NULL AND c.full_name = 'QA delivery' AND c.address = 'QA address');
    ASSERT EXISTS (SELECT 1 FROM find_member_account1(' QA-SETUP@example.test ') account
        WHERE account.customer_id = member_id AND account.password_hash = sample_password_hash);
    ASSERT EXISTS (SELECT 1 FROM online_orders1 WHERE id = first_order AND customer_id = member_id);
    ASSERT NOT EXISTS (SELECT 1 FROM member_account_verifications1 WHERE customer_id = member_id);
    ASSERT begin_member_account_setup1('0900000551', challenge_id, code_digest) = 'INELIGIBLE';

    BEGIN
        PERFORM place_online_order1('QA-PHONE-ORDER', 'QA rollback', '0900000552',
            'QA address', ARRAY[product_id], ARRAY[1]);
        RAISE EXCEPTION 'Duplicate order code was accepted.';
    EXCEPTION WHEN unique_violation THEN
        ASSERT NOT EXISTS (SELECT 1 FROM customers1 WHERE phone = '0900000552');
    END;

    BEGIN
        PERFORM place_online_order1('QA-BAD-PHONE', 'QA invalid', '123',
            'QA address', ARRAY[product_id], ARRAY[1]);
        RAISE EXCEPTION 'An invalid phone number was accepted.';
    EXCEPTION WHEN SQLSTATE 'P1003' THEN
        ASSERT NOT EXISTS (SELECT 1 FROM online_orders1 WHERE order_code = 'QA-BAD-PHONE');
    END;
END;
$$;

DO $$
DECLARE
    warehouse_id bigint := (SELECT id FROM employees1 WHERE employee_code = 'KHO01');
    delivery_id bigint := (SELECT id FROM employees1 WHERE employee_code = 'GH01');
    saler_id bigint := (SELECT id FROM employees1 WHERE employee_code = 'BH01');
    customer_id bigint := (SELECT id FROM customers1 WHERE email = 'khachmau@example.test');
    supplier_id bigint := (SELECT id FROM suppliers1 WHERE supplier_code = 'NCC01');
    test_time timestamp := TIMESTAMP '2026-11-05 09:00:00';
    product_id bigint;
    scarce_id bigint;
    test_receipt_id bigint;
    order_id bigint;
    other_order_id bigint;
    short_order_id bigint;
    sale_id bigint;
    counter_id bigint;
    counter_detail_id bigint;
    refund_id bigint;
    refund_time timestamp := test_time + interval '2 days';
    lines jsonb;
BEGIN
    IF num_nonnulls(warehouse_id, delivery_id, saler_id, customer_id, supplier_id) <> 5 THEN
        RAISE EXCEPTION 'Run this verification on the seeded demo database.';
    END IF;

    ASSERT normalize_customer_phone('+84 (98) 555-0199') = '0985550199';
    INSERT INTO customers1 (full_name, phone, email, address, password_hash, is_member)
    VALUES ('QA member', '0985550199', 'qa-member-1@example.test', 'QA address', 'QA', true);
    BEGIN
        INSERT INTO customers1 (full_name, phone, email, address, password_hash, is_member)
        VALUES ('QA duplicate', '+84 (98) 555-0199', 'qa-member-2@example.test', 'QA address', 'QA', true);
        RAISE EXCEPTION 'Duplicate member phone was accepted.';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    INSERT INTO items1 (item_code, name, unit, current_price, stock_quantity)
    VALUES ('QA-STOCK', 'QA stock', 'unit', 10000, 5) RETURNING id INTO product_id;
    INSERT INTO items1 (item_code, name, unit, current_price, stock_quantity)
    VALUES ('QA-SCARCE', 'QA scarce', 'unit', 10000, 1) RETURNING id INTO scarce_id;

    BEGIN
        INSERT INTO goods_receipts1 (receipt_code, supplier_id, warehouse_staff_id, received_at)
        VALUES ('QA-WRONG-ROLE', supplier_id, saler_id, test_time);
        RAISE EXCEPTION 'Wrong warehouse role was accepted.';
    EXCEPTION WHEN foreign_key_violation THEN
        NULL;
    END;

    INSERT INTO goods_receipts1 (receipt_code, supplier_id, warehouse_staff_id, received_at)
    VALUES ('QA-RECEIPT', supplier_id, warehouse_id, test_time) RETURNING id INTO test_receipt_id;
    INSERT INTO goods_receipt_details1 (receipt_id, item_id, quantity, unit_cost)
    VALUES (test_receipt_id, product_id, 4, 8000);
    PERFORM post_goods_receipt(test_receipt_id, test_time);
    PERFORM post_goods_receipt(test_receipt_id, test_time);
    ASSERT (SELECT stock_quantity = 9 FROM items1 WHERE id = product_id), 'Receipt must increase stock once';
    BEGIN
        UPDATE goods_receipt_details1 d SET quantity = 10 WHERE d.receipt_id = test_receipt_id;
        RAISE EXCEPTION 'Posted receipt lines could be edited.';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    INSERT INTO online_orders1 (order_code, customer_id, ordered_at, delivery_address, delivery_phone)
    VALUES ('QA-ORDER', customer_id, test_time, 'QA address', '0900000000') RETURNING id INTO order_id;
    INSERT INTO online_order_details1 (order_id, item_id, quantity, unit_price, discount_amount)
    VALUES (order_id, product_id, 3, 12000, 3000);
    BEGIN
        PERFORM dispatch_online_order(order_id, warehouse_id, saler_id, test_time);
        RAISE EXCEPTION 'Wrong delivery role was accepted.';
    EXCEPTION WHEN foreign_key_violation THEN
        NULL;
    END;
    ASSERT (SELECT stock_quantity = 9 FROM items1 WHERE id = product_id), 'Wrong role must roll back stock';
    PERFORM dispatch_online_order(order_id, warehouse_id, delivery_id, test_time);
    PERFORM dispatch_online_order(order_id, warehouse_id, delivery_id, test_time);
    ASSERT (SELECT stock_quantity = 6 FROM items1 WHERE id = product_id), 'Dispatch must decrease stock once';

    BEGIN
        UPDATE online_orders1 SET status = 'COMPLETED' WHERE id = order_id;
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'An order completed without a transaction.';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;
    sale_id := complete_online_order(order_id, 'QA-ONLINE', test_time);
    ASSERT complete_online_order(order_id, 'QA-ONLINE', test_time) = sale_id, 'Completion must return the original sale';
    ASSERT (SELECT status = 'COMPLETED' FROM online_orders1 WHERE id = order_id), 'Order must be completed';
    ASSERT (SELECT count(*) = 1 FROM sale_transactions1 WHERE online_order_id = order_id), 'Exactly one online sale';
    ASSERT (
        SELECT quantity = 3 AND unit_price = 12000 AND line_total = 36000 AND discount_amount = 3000
        FROM sale_transaction_details1 WHERE transaction_id = sale_id
    ), 'Online sale lines must keep original quantities, prices and discounts';
    ASSERT (SELECT stock_quantity = 6 FROM items1 WHERE id = product_id), 'Completion must not decrease stock again';

    INSERT INTO online_orders1 (order_code, customer_id, ordered_at, delivery_address, delivery_phone)
    VALUES ('QA-RETURN', customer_id, test_time, 'QA address', '0900000000') RETURNING id INTO other_order_id;
    INSERT INTO online_order_details1 (order_id, item_id, quantity, unit_price)
    VALUES (other_order_id, product_id, 2, 11000);
    PERFORM dispatch_online_order(other_order_id, warehouse_id, delivery_id, test_time);
    ASSERT (SELECT stock_quantity = 4 FROM items1 WHERE id = product_id), 'Second dispatch must decrease stock';
    PERFORM cancel_online_order(other_order_id, test_time);
    PERFORM cancel_online_order(other_order_id, test_time);
    ASSERT (SELECT stock_quantity = 6 FROM items1 WHERE id = product_id), 'Return must increase stock once';
    ASSERT NOT EXISTS (SELECT 1 FROM sale_transactions1 WHERE online_order_id = other_order_id), 'Cancelled order must not generate revenue';

    lines := jsonb_build_array(
        jsonb_build_object('item_id', product_id, 'quantity', 2, 'unit_price', 10000, 'discount_amount', 2000),
        jsonb_build_object('item_id', product_id, 'quantity', 1, 'unit_price', 9000)
    );
    BEGIN
        PERFORM record_counter_sale('QA-INVALID-COUNTER', warehouse_id, test_time, lines);
        RAISE EXCEPTION 'Wrong saler role was accepted.';
    EXCEPTION WHEN foreign_key_violation THEN
        NULL;
    END;
    counter_id := record_counter_sale('QA-COUNTER', saler_id, test_time, lines);
    ASSERT record_counter_sale('QA-COUNTER', saler_id, test_time, lines) = counter_id, 'Counter sale retry must be idempotent';
    ASSERT (SELECT stock_quantity = 3 FROM items1 WHERE id = product_id), 'Counter sale must decrease stock once across prices';
    ASSERT (SELECT sum(line_total) = 29000 FROM sale_transaction_details1 WHERE transaction_id = counter_id),
        'Counter sale must retain multiple unit prices';
    BEGIN
        PERFORM record_counter_sale('QA-COUNTER', saler_id, test_time, lines #- '{0,discount_amount}');
        RAISE EXCEPTION 'A retry changed the original discount.';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;
    SELECT id INTO STRICT counter_detail_id FROM sale_transaction_details1
    WHERE transaction_id = counter_id AND unit_price = 10000;
    refund_id := record_sale_refund('QA-REFUND', counter_detail_id, refund_time, 1, 9000);
    ASSERT record_sale_refund('QA-REFUND', counter_detail_id, refund_time, 1, 9000) = refund_id;
    BEGIN
        PERFORM record_sale_refund('QA-REFUND-AMOUNT', counter_detail_id, refund_time, 1, 9001);
        RAISE EXCEPTION 'A refund exceeding the amount paid was accepted.';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;
    BEGIN
        PERFORM record_sale_refund('QA-REFUND-QUANTITY', counter_detail_id, refund_time, 2, 1);
        RAISE EXCEPTION 'A refund exceeding the quantity sold was accepted.';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;
    BEGIN
        PERFORM record_sale_refund('QA-REFUND-DATE', counter_detail_id, test_time - interval '1 day', 1, 1);
        RAISE EXCEPTION 'A refund before its sale was accepted.';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;
    ASSERT (SELECT sum(gross_amount - discount_amount - refund_amount) = 27000
            FROM item_revenue_events1 WHERE transaction_id = counter_id AND occurred_at = test_time);
    ASSERT (SELECT sum(gross_amount - discount_amount - refund_amount) = -9000 AND count(*) = 1
            FROM item_revenue_events1 WHERE transaction_id = counter_id AND occurred_at = refund_time);
    ASSERT (SELECT stock_quantity = 3 FROM items1 WHERE id = product_id), 'Refund must not restock automatically';

    INSERT INTO online_orders1 (order_code, customer_id, ordered_at, delivery_address, delivery_phone)
    VALUES ('QA-SHORT', customer_id, test_time, 'QA address', '0900000000') RETURNING id INTO short_order_id;
    INSERT INTO online_order_details1 (order_id, item_id, quantity, unit_price)
    VALUES (short_order_id, product_id, 1, 10000), (short_order_id, scarce_id, 2, 10000);
    BEGIN
        PERFORM dispatch_online_order(short_order_id, warehouse_id, delivery_id, test_time);
        RAISE EXCEPTION 'Dispatch without enough stock was accepted.';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;
    ASSERT (SELECT status = 'PENDING' FROM online_orders1 WHERE id = short_order_id), 'Failed dispatch must keep order pending';
    ASSERT NOT EXISTS (SELECT 1 FROM inventory_movements1 WHERE inventory_movements1.order_id = short_order_id),
        'Failed dispatch must leave no stock movements';
    ASSERT (SELECT stock_quantity = 3 FROM items1 WHERE id = product_id), 'Failed dispatch must roll back all item updates';

    BEGIN
        UPDATE items1 SET stock_quantity = 99 WHERE id = product_id;
        SET CONSTRAINTS ALL IMMEDIATE;
        RAISE EXCEPTION 'Stock changed without a movement.';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;

    -- Evaluate all deferred constraints, including transaction/detail and balance consistency.
    SET CONSTRAINTS ALL IMMEDIATE;
    RAISE NOTICE 'Workflow verification passed.';
END;
$$;

SET CONSTRAINTS ALL DEFERRED;

DO $$
DECLARE
    warehouse_id bigint := (SELECT id FROM employees1 WHERE employee_code = 'KHO01');
    delivery_id bigint := (SELECT id FROM employees1 WHERE employee_code = 'GH01');
    saler_id bigint := (SELECT id FROM employees1 WHERE employee_code = 'BH01');
    qa_supplier_id bigint := (SELECT id FROM suppliers1 WHERE supplier_code = 'NCC01');
    member_id bigint := (SELECT id FROM customers1 WHERE email = 'qa-member-1@example.test');
    guest_id bigint := (SELECT id FROM customers1 WHERE email = 'khachmau@example.test');
    stocked_at timestamp := TIMESTAMP '2026-11-10 09:00';
    sold_at timestamp := TIMESTAMP '2026-11-11 09:00';
    requested_at timestamp := TIMESTAMP '2026-11-12 09:00';
    resolved_at timestamp := TIMESTAMP '2026-11-13 09:00';
    product_id bigint;
    receipt_id bigint;
    dispatched_order_id bigint;
    sale_id bigint;
    detail_id bigint;
    cash_id bigint;
    card_id bigint;
    failed_payment_id bigint;
    refund_id bigint;
    failed_refund_id bigint;
    lines jsonb;
    allocations jsonb;
BEGIN
    INSERT INTO items1 (item_code, name, unit, current_price, track_lots)
    VALUES ('QA-LOT', 'QA lot product', 'unit', 10000, true) RETURNING id INTO product_id;
    INSERT INTO goods_receipts1 (receipt_code, supplier_id, warehouse_staff_id, received_at)
    VALUES ('QA-LOT-RECEIPT', qa_supplier_id, warehouse_id, stocked_at) RETURNING id INTO receipt_id;
    INSERT INTO goods_receipt_details1 (receipt_id, item_id, quantity, unit_cost)
    VALUES (receipt_id, product_id, 5, 8000);
    BEGIN
        PERFORM post_goods_receipt(receipt_id, stocked_at);
        RAISE EXCEPTION 'A tracked item receipt without lots was accepted.';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    INSERT INTO inventory_lots1 (receipt_id, item_id, lot_code, expires_on, received_quantity) VALUES
        (receipt_id, product_id, 'LATE', DATE '2026-11-20', 3),
        (receipt_id, product_id, 'EARLY', DATE '2026-11-12', 2);
    PERFORM post_goods_receipt(receipt_id, stocked_at);
    PERFORM post_goods_receipt(receipt_id, stocked_at);
    ASSERT (SELECT sum(quantity_on_hand) = 5 FROM inventory_lot_balances1 WHERE item_id = product_id);
    lines := jsonb_build_array(jsonb_build_object('item_id', product_id, 'quantity', 1, 'unit_price', 10000));
    BEGIN
        PERFORM record_counter_sale('QA-GUEST-LINK', saler_id, sold_at, lines, guest_id);
        RAISE EXCEPTION 'A guest was accepted as a counter member.';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    sale_id := record_counter_sale('QA-PAID-COUNTER', saler_id, sold_at, lines, member_id);
    ASSERT sale_id = record_counter_sale('QA-PAID-COUNTER', saler_id, sold_at, lines, member_id);
    ASSERT (SELECT customer_id = member_id FROM customer_purchases1 WHERE transaction_id = sale_id);
    ASSERT (SELECT l.lot_code = 'EARLY' AND l.quantity_delta = -1 AND l.supplier_id = qa_supplier_id
            FROM inventory_lot_trace1 l WHERE l.transaction_id = sale_id);
    SELECT id INTO STRICT detail_id FROM sale_transaction_details1 WHERE transaction_id = sale_id;

    INSERT INTO online_orders1 (order_code, customer_id, ordered_at, delivery_address, delivery_phone)
    VALUES ('QA-LOT-ORDER', member_id, sold_at, 'QA address', '0900000000') RETURNING id INTO dispatched_order_id;
    INSERT INTO online_order_details1 (order_id, item_id, quantity, unit_price)
    VALUES (dispatched_order_id, product_id, 1, 10000);
    PERFORM dispatch_online_order(dispatched_order_id, warehouse_id, delivery_id, sold_at);
    ASSERT (SELECT quantity_on_hand = 0 FROM inventory_lot_balances1 WHERE item_id = product_id AND lot_code = 'EARLY');
    PERFORM cancel_online_order(dispatched_order_id, sold_at);
    ASSERT (SELECT quantity_on_hand = 1 FROM inventory_lot_balances1 WHERE item_id = product_id AND lot_code = 'EARLY');
    BEGIN
        PERFORM record_counter_sale('QA-EXPIRED-STOCK', saler_id, resolved_at,
            jsonb_build_array(jsonb_build_object('item_id', product_id, 'quantity', 4, 'unit_price', 10000)));
        RAISE EXCEPTION 'Expired stock was used for a sale.';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    ASSERT (SELECT stock_quantity = 4 FROM items1 WHERE id = product_id);
    ASSERT (SELECT quantity_on_hand = 3 FROM inventory_lot_balances1 WHERE item_id = product_id AND lot_code = 'LATE');

    failed_payment_id := record_sale_payment('QA-PAY-FAILED', sale_id, 'CARD', 10000, sold_at);
    PERFORM resolve_sale_payment(failed_payment_id, 'FAILED', sold_at);
    cash_id := record_sale_payment('QA-PAY-CASH', sale_id, 'CASH', 4000, sold_at);
    card_id := record_sale_payment('QA-PAY-CARD', sale_id, 'CARD', 6000, sold_at);
    ASSERT cash_id = record_sale_payment('QA-PAY-CASH', sale_id, 'CASH', 4000, sold_at);
    ASSERT (SELECT paid_amount = 0 FROM sale_payment_balances1 WHERE transaction_id = sale_id);
    PERFORM resolve_sale_payment(cash_id, 'SUCCEEDED', sold_at);
    PERFORM resolve_sale_payment(card_id, 'SUCCEEDED', sold_at);
    PERFORM resolve_sale_payment(card_id, 'SUCCEEDED', sold_at);
    ASSERT (SELECT paid_amount = 10000 AND unpaid_amount = 0 FROM sale_payment_balances1 WHERE transaction_id = sale_id);
    BEGIN
        PERFORM record_sale_payment('QA-PAY-OVER', sale_id, 'CASH', 1, sold_at);
        RAISE EXCEPTION 'An overpayment was accepted.';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    BEGIN
        PERFORM record_sale_refund('QA-REFUND-OVER', detail_id, requested_at, 1, 4001,
            jsonb_build_array(jsonb_build_object('payment_id', cash_id, 'amount', 4001)));
        RAISE EXCEPTION 'A refund exceeding a payment was accepted.';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    allocations := jsonb_build_array(jsonb_build_object('payment_id', cash_id, 'amount', 4000),
                                    jsonb_build_object('payment_id', card_id, 'amount', 6000));
    failed_refund_id := record_sale_refund('QA-PAY-REFUND-FAIL', detail_id, requested_at, 1, 10000, allocations);
    PERFORM resolve_sale_refund(failed_refund_id, 'FAILED', resolved_at);
    refund_id := record_sale_refund('QA-PAY-REFUND', detail_id, requested_at, 1, 10000, allocations);
    ASSERT refund_id = record_sale_refund('QA-PAY-REFUND', detail_id, requested_at, 1, 10000, allocations);
    ASSERT NOT EXISTS (SELECT 1 FROM item_revenue_events1 WHERE transaction_id = sale_id AND is_refund);
    PERFORM resolve_sale_refund(refund_id, 'SUCCEEDED', resolved_at);
    PERFORM resolve_sale_refund(refund_id, 'SUCCEEDED', resolved_at);
    ASSERT (SELECT net_collected_amount = 0 AND refunded_amount = 10000
            FROM sale_payment_balances1 WHERE transaction_id = sale_id);
    ASSERT (SELECT count(*) = 1 AND sum(refund_amount) = 10000 AND min(occurred_at) = resolved_at
            FROM item_revenue_events1 WHERE transaction_id = sale_id AND is_refund);

    SET CONSTRAINTS ALL IMMEDIATE;
    RAISE NOTICE 'Payment, member and lot verification passed.';
END;
$$;

ROLLBACK;
