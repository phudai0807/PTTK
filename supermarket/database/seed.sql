BEGIN;

INSERT INTO employees1 (employee_code, full_name, phone, role, username) VALUES
    ('QL01', 'Nguyễn Minh Anh', '0900000101', 'MANAGEMENT', 'quanly'),
    ('KHO01', 'Trần Văn Kho', '0900000102', 'WAREHOUSE', NULL),
    ('BH01', 'Lê Thu Hà', '0900000103', 'SALER', NULL),
    ('GH01', 'Phạm Thanh Bình', '0900000104', 'DELIVERY', NULL)
ON CONFLICT (employee_code) DO NOTHING;

INSERT INTO suppliers1 (supplier_code, name, phone, address) VALUES
    ('NCC01', 'Nhà cung cấp Thực phẩm Mẫu', '0900000105', 'Hà Nội')
ON CONFLICT (supplier_code) DO NOTHING;

INSERT INTO items1 (item_code, name, unit, current_price, stock_quantity, description) VALUES
    ('HH001', 'Sữa tươi 1 lít', 'Hộp', 38000, 0, 'Sữa tươi tiệt trùng, dung tích 1 lít.'),
    ('HH002', 'Gạo thơm 5 kg', 'Túi', 145000, 0, 'Gạo thơm đóng túi 5 kg.'),
    ('HH003', 'Nước cam 350 ml', 'Chai', 15000, 0, 'Nước cam đóng chai 350 ml.'),
    ('HH004', 'Mì gói vị rau củ', 'Gói', 8000, 100, 'Hàng hóa chưa phát sinh giao dịch mẫu.')
ON CONFLICT (item_code) DO NOTHING;

INSERT INTO customers1 (full_name, phone, email, address) VALUES
    ('Khách hàng mẫu', '0900000200', 'khachmau@example.test', 'Hà Nội')
ON CONFLICT (email) DO NOTHING;


INSERT INTO goods_receipts1 (receipt_code, supplier_id, warehouse_staff_id, received_at)
SELECT 'PN001', s.id, e.id, TIMESTAMP '2026-10-28 09:00'
FROM suppliers1 s CROSS JOIN employees1 e
WHERE s.supplier_code = 'NCC01' AND e.employee_code = 'KHO01'
ON CONFLICT (receipt_code) DO NOTHING;

INSERT INTO goods_receipt_details1 (receipt_id, item_id, quantity, unit_cost)
SELECT r.id, i.id, v.quantity, v.unit_cost
FROM (VALUES ('HH001', 86, 30000), ('HH002', 43, 115000), ('HH003', 112, 10000))
    AS v(item_code, quantity, unit_cost)
JOIN items1 i ON i.item_code = v.item_code
JOIN goods_receipts1 r ON r.receipt_code = 'PN001'
WHERE r.posted_at IS NULL
ON CONFLICT DO NOTHING;

SELECT post_goods_receipt(id, TIMESTAMP '2026-10-28 09:00')
FROM goods_receipts1 WHERE receipt_code = 'PN001' AND posted_at IS NULL;

INSERT INTO online_orders1 (order_code, customer_id, ordered_at, delivery_address, delivery_phone)
SELECT 'DH001', c.id, TIMESTAMP '2026-11-01 11:30', c.address, c.phone
FROM customers1 c WHERE c.email = 'khachmau@example.test'
ON CONFLICT (order_code) DO NOTHING;

INSERT INTO online_order_details1 (order_id, item_id, quantity, unit_price)
SELECT o.id, i.id, v.quantity, v.unit_price
FROM (VALUES ('HH001', 1, 38000), ('HH003', 2, 15000)) AS v(item_code, quantity, unit_price)
JOIN items1 i ON i.item_code = v.item_code
JOIN online_orders1 o ON o.order_code = 'DH001'
WHERE o.status = 'PENDING'
ON CONFLICT DO NOTHING;

SELECT dispatch_online_order(o.id, w.id, d.id, TIMESTAMP '2026-11-02 09:00')
FROM online_orders1 o CROSS JOIN employees1 w CROSS JOIN employees1 d
WHERE o.order_code = 'DH001' AND o.status = 'PENDING'
AND w.employee_code = 'KHO01' AND d.employee_code = 'GH01';

SELECT complete_online_order(id, 'GD102', TIMESTAMP '2026-11-02 13:30')
FROM online_orders1 WHERE order_code = 'DH001' AND status = 'DISPATCHED';

WITH sale_lines (code, sold_at, item_code, quantity, unit_price) AS (
    VALUES
        ('GD100', TIMESTAMP '2026-10-31 23:59:59', 'HH001', 1, 37000),
        ('GD101', TIMESTAMP '2026-11-01 00:00:00', 'HH001', 2, 36000),
        ('GD101', TIMESTAMP '2026-11-01 00:00:00', 'HH002', 1, 145000),
        ('GD103', TIMESTAMP '2026-11-03 23:59:59', 'HH001', 1, 38000),
        ('GD103', TIMESTAMP '2026-11-03 23:59:59', 'HH002', 2, 140000),
        ('GD104', TIMESTAMP '2026-11-04 00:00:00', 'HH001', 1, 38000)
)
SELECT record_counter_sale(v.code, e.id, v.sold_at, jsonb_agg(
    jsonb_build_object('item_id', i.id, 'quantity', v.quantity, 'unit_price', v.unit_price)))
FROM sale_lines v
JOIN items1 i ON i.item_code = v.item_code
JOIN employees1 e ON e.employee_code = 'BH01'
WHERE NOT EXISTS (SELECT 1 FROM sale_transactions1 s WHERE s.transaction_code = v.code)
GROUP BY v.code, e.id, v.sold_at
ORDER BY v.sold_at;

-- Demo of a discounted sale and a partial refund posted on a later day.
SELECT record_counter_sale('GD105-MAU', e.id, TIMESTAMP '2026-11-05 10:00',
    jsonb_build_array(jsonb_build_object(
        'item_id', i.id, 'quantity', 2, 'unit_price', 50000, 'discount_amount', 10000
    )))
FROM items1 i CROSS JOIN employees1 e
WHERE i.item_code = 'HH001' AND e.employee_code = 'BH01'
AND NOT EXISTS (SELECT 1 FROM sale_transactions1 WHERE transaction_code = 'GD105-MAU');

SELECT record_sale_refund('HT105-MAU', d.id, TIMESTAMP '2026-11-07 09:00', 1, 45000)
FROM sale_transaction_details1 d
JOIN sale_transactions1 t ON t.id = d.transaction_id
JOIN items1 i ON i.id = d.item_id
WHERE t.transaction_code = 'GD105-MAU' AND i.item_code = 'HH001';

COMMIT;
