BEGIN;

-- Rename existing tables in place, preserving rows, identities and foreign keys.
DO $rename_tables$
DECLARE
    old_name text;
    new_name text;
BEGIN
    FOREACH old_name IN ARRAY ARRAY[
        'customers', 'employees', 'suppliers', 'items', 'goods_receipts',
        'goods_receipt_details', 'online_orders', 'online_order_details', 'sale_transactions', 'sale_transaction_details', 'inventory_movements'
    ]
    LOOP
        new_name := old_name || '1';
        IF to_regclass(format('public.%I', old_name)) IS NOT NULL THEN
            IF to_regclass(format('public.%I', new_name)) IS NOT NULL THEN
                RAISE EXCEPTION 'Both % and % exist. Reconcile the two tables before upgrading.', old_name, new_name;
            END IF;
            EXECUTE format('ALTER TABLE public.%I RENAME TO %I', old_name, new_name);
        END IF;
    END LOOP;
END;
$rename_tables$;

-- Tables and keys
CREATE TABLE IF NOT EXISTS customers1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name varchar(120) NOT NULL CHECK (btrim(full_name) <> ''),
    phone varchar(20) NOT NULL CHECK (btrim(phone) <> ''),
    email varchar(254) UNIQUE CHECK (email = lower(btrim(email)) AND email <> ''),
    address varchar(300) CHECK (btrim(address) <> ''),
    password_hash varchar(255),
    is_member boolean NOT NULL DEFAULT false,
    created_at timestamp NOT NULL DEFAULT LOCALTIMESTAMP
);

-- Phone-only members may have no email, password or address.
ALTER TABLE customers1 ALTER COLUMN email DROP NOT NULL,
    ALTER COLUMN address DROP NOT NULL, DROP CONSTRAINT IF EXISTS customers1_check,
    DROP CONSTRAINT IF EXISTS customers_check;

-- Canonicalize local and international spellings of Vietnamese mobile numbers.
-- Keep other legacy numbers readable and index their compact spelling.
CREATE OR REPLACE FUNCTION normalize_customer_phone(p_phone text) RETURNS text
LANGUAGE sql IMMUTABLE STRICT AS $$
    SELECT regexp_replace(regexp_replace(p_phone, '[[:space:]().-]', '', 'g'),
                          '^(\+84|84)([35789][0-9]{8})$', '0\2');
$$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_member_phone1
    ON customers1 (normalize_customer_phone(phone)) WHERE is_member;

ALTER TABLE customers1 ADD COLUMN IF NOT EXISTS account_setup_at timestamptz;

CREATE TABLE IF NOT EXISTS member_account_verifications1 (
    customer_id bigint PRIMARY KEY REFERENCES customers1(id) ON DELETE CASCADE,
    challenge_id uuid NOT NULL UNIQUE,
    phone varchar(10) NOT NULL CHECK (phone ~ '^0[35789][0-9]{8}$'),
    code_digest bytea CHECK (octet_length(code_digest) = 32),
    issued_at timestamptz NOT NULL,
    failed_attempts smallint NOT NULL DEFAULT 0 CHECK (failed_attempts BETWEEN 0 AND 5),
    request_window_started_at timestamptz NOT NULL CHECK (request_window_started_at <= issued_at),
    requests_in_window smallint NOT NULL CHECK (requests_in_window BETWEEN 1 AND 5),
    verified_at timestamptz,
    setup_token_digest bytea CHECK (octet_length(setup_token_digest) = 32),
    CHECK (
        (verified_at IS NULL AND code_digest IS NOT NULL AND setup_token_digest IS NULL)
        OR (verified_at IS NOT NULL AND verified_at >= issued_at
            AND code_digest IS NULL AND setup_token_digest IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS employees1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_code varchar(30) NOT NULL UNIQUE,
    full_name varchar(120) NOT NULL,
    phone varchar(20) NOT NULL,
    email varchar(254),
    role varchar(20) NOT NULL
        CHECK (role IN ('MANAGEMENT', 'WAREHOUSE', 'SALER', 'DELIVERY'))
);

ALTER TABLE employees1 ADD COLUMN IF NOT EXISTS password_hash varchar(255);
ALTER TABLE employees1 ADD COLUMN IF NOT EXISTS username varchar(30)
    CHECK (username ~ '^[a-z0-9][a-z0-9._-]{2,29}$');
CREATE UNIQUE INDEX IF NOT EXISTS idx_employees_username ON employees1(username) WHERE username IS NOT NULL;

UPDATE employees1
SET username = 'quanly'
WHERE employee_code = 'QL01' AND role = 'MANAGEMENT' AND username IS NULL
    AND NOT EXISTS (SELECT 1 FROM employees1 WHERE username = 'quanly' OR employee_code = 'QUANLY');

CREATE TABLE IF NOT EXISTS suppliers1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_code varchar(30) NOT NULL UNIQUE,
    name varchar(150) NOT NULL,
    phone varchar(20),
    email varchar(254),
    address varchar(300)
);

CREATE TABLE IF NOT EXISTS items1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    item_code varchar(30) NOT NULL UNIQUE,
    name varchar(150) NOT NULL,
    unit varchar(30) NOT NULL,
    current_price numeric(18,2) NOT NULL CHECK (current_price >= 0),
    stock_quantity integer NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    description text NOT NULL DEFAULT '',
    active boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS goods_receipts1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    receipt_code varchar(30) NOT NULL UNIQUE,
    supplier_id bigint NOT NULL REFERENCES suppliers1(id),
    warehouse_staff_id bigint NOT NULL REFERENCES employees1(id),
    received_at timestamp NOT NULL
);

CREATE TABLE IF NOT EXISTS goods_receipt_details1 (
    receipt_id bigint NOT NULL REFERENCES goods_receipts1(id),
    item_id bigint NOT NULL REFERENCES items1(id),
    quantity integer NOT NULL CHECK (quantity > 0),
    unit_cost numeric(18,2) NOT NULL CHECK (unit_cost >= 0),
    line_total numeric(24,2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
    PRIMARY KEY (receipt_id, item_id)
);

CREATE TABLE IF NOT EXISTS online_orders1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_code varchar(30) NOT NULL UNIQUE,
    customer_id bigint NOT NULL REFERENCES customers1(id),
    ordered_at timestamp NOT NULL,
    delivery_address varchar(300) NOT NULL,
    delivery_phone varchar(20) NOT NULL,
    status varchar(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'DISPATCHED', 'COMPLETED', 'CANCELLED')),
    warehouse_staff_id bigint REFERENCES employees1(id),
    delivery_staff_id bigint REFERENCES employees1(id)
);

-- A guest order keeps delivery details on the order itself.
ALTER TABLE online_orders1 ALTER COLUMN customer_id DROP NOT NULL;
ALTER TABLE online_orders1 ADD COLUMN IF NOT EXISTS delivery_name varchar(120);

CREATE TABLE IF NOT EXISTS online_order_details1 (
    order_id bigint NOT NULL REFERENCES online_orders1(id),
    item_id bigint NOT NULL REFERENCES items1(id),
    quantity integer NOT NULL CHECK (quantity > 0),
    unit_price numeric(18,2) NOT NULL CHECK (unit_price >= 0),
    line_total numeric(24,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    PRIMARY KEY (order_id, item_id)
);

-- Giao dịch chỉ được tạo khi việc bán hàng đã hoàn tất.
CREATE TABLE IF NOT EXISTS sale_transactions1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_code varchar(30) NOT NULL UNIQUE,
    sold_at timestamp NOT NULL,
    channel varchar(10) NOT NULL CHECK (channel IN ('COUNTER', 'ONLINE')),
    saler_id bigint REFERENCES employees1(id),
    online_order_id bigint UNIQUE REFERENCES online_orders1(id),
    CHECK (
        (channel = 'COUNTER' AND saler_id IS NOT NULL AND online_order_id IS NULL)
        OR (channel = 'ONLINE' AND saler_id IS NULL AND online_order_id IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS sale_transaction_details1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id bigint NOT NULL REFERENCES sale_transactions1(id),
    item_id bigint NOT NULL REFERENCES items1(id),
    quantity integer NOT NULL CHECK (quantity > 0),
    unit_price numeric(18,2) NOT NULL CHECK (unit_price >= 0),
    line_total numeric(24,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    UNIQUE (transaction_id, item_id, unit_price)
);

CREATE INDEX IF NOT EXISTS idx_sales_sold_at ON sale_transactions1(sold_at);
ALTER TABLE sale_transactions1 ADD COLUMN IF NOT EXISTS customer_id bigint REFERENCES customers1(id)
    CHECK (channel = 'COUNTER' OR customer_id IS NULL);
ALTER TABLE sale_transactions1 ADD COLUMN IF NOT EXISTS settlement_revision bigint NOT NULL DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_counter_customer1 ON sale_transactions1(customer_id, sold_at)
    WHERE customer_id IS NOT NULL;
ALTER TABLE online_order_details1 ADD COLUMN IF NOT EXISTS discount_amount numeric(24,2)
    NOT NULL DEFAULT 0 CHECK (discount_amount BETWEEN 0 AND line_total);
ALTER TABLE sale_transaction_details1 ADD COLUMN IF NOT EXISTS discount_amount numeric(24,2)
    NOT NULL DEFAULT 0 CHECK (discount_amount BETWEEN 0 AND line_total);

CREATE TABLE IF NOT EXISTS sale_payments1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_code varchar(60) NOT NULL UNIQUE CHECK (btrim(payment_code) <> ''),
    transaction_id bigint NOT NULL REFERENCES sale_transactions1(id),
    method varchar(20) NOT NULL CHECK (method IN ('CASH', 'CARD', 'BANK_TRANSFER', 'E_WALLET')),
    amount numeric(24,2) NOT NULL CHECK (amount > 0 AND amount <> 'NaN'::numeric),
    requested_at timestamp NOT NULL,
    status varchar(10) NOT NULL CHECK (status IN ('PENDING', 'SUCCEEDED', 'FAILED')),
    resolved_at timestamp,
    external_reference varchar(120),
    CHECK ((status = 'PENDING' AND resolved_at IS NULL)
        OR (status <> 'PENDING' AND resolved_at IS NOT NULL AND resolved_at >= requested_at))
);
CREATE INDEX IF NOT EXISTS idx_sale_payments_transaction1 ON sale_payments1(transaction_id);

CREATE TABLE IF NOT EXISTS sale_refunds1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    refund_code varchar(30) NOT NULL UNIQUE CHECK (btrim(refund_code) <> ''),
    sale_detail_id bigint NOT NULL REFERENCES sale_transaction_details1(id),
    refunded_at timestamp NOT NULL,
    quantity integer NOT NULL CHECK (quantity > 0),
    refund_amount numeric(24,2) NOT NULL CHECK (refund_amount >= 0 AND refund_amount <> 'NaN'::numeric),
    line_sequence bigint NOT NULL,
    UNIQUE (sale_detail_id, line_sequence)
);
CREATE INDEX IF NOT EXISTS idx_sale_refunds_date1 ON sale_refunds1(refunded_at);
ALTER TABLE sale_refunds1 ADD COLUMN IF NOT EXISTS track_payment boolean NOT NULL DEFAULT false;
ALTER TABLE sale_refunds1 ADD COLUMN IF NOT EXISTS status varchar(10) NOT NULL DEFAULT 'SUCCEEDED'
    CHECK (status IN ('PENDING', 'SUCCEEDED', 'FAILED'));
-- Legacy refunds already use refunded_at as their settlement time.
ALTER TABLE sale_refunds1 ADD COLUMN IF NOT EXISTS resolved_at timestamp;
CREATE TABLE IF NOT EXISTS sale_refund_payments1 (
    refund_id bigint NOT NULL REFERENCES sale_refunds1(id),
    payment_id bigint NOT NULL REFERENCES sale_payments1(id),
    amount numeric(24,2) NOT NULL CHECK (amount > 0 AND amount <> 'NaN'::numeric),
    PRIMARY KEY (refund_id, payment_id)
);
CREATE INDEX IF NOT EXISTS idx_refund_payments_payment1 ON sale_refund_payments1(payment_id);

CREATE OR REPLACE VIEW item_revenue_events1 AS
    SELECT d.item_id, t.id AS transaction_id, t.transaction_code, t.channel,
           t.transaction_code AS event_code, t.sold_at AS occurred_at, false AS is_refund,
           d.quantity, d.unit_price, d.line_total AS gross_amount, d.discount_amount,
           0::numeric AS refund_amount
    FROM sale_transactions1 t JOIN sale_transaction_details1 d ON d.transaction_id = t.id
    UNION ALL
    SELECT d.item_id, t.id, t.transaction_code, t.channel,
           r.refund_code, coalesce(r.resolved_at, r.refunded_at), true,
           r.quantity, d.unit_price, 0::numeric, 0::numeric, r.refund_amount
    FROM sale_refunds1 r
    JOIN sale_transaction_details1 d ON d.id = r.sale_detail_id
    JOIN sale_transactions1 t ON t.id = d.transaction_id
    WHERE r.status = 'SUCCEEDED';
CREATE INDEX IF NOT EXISTS idx_sale_details_item ON sale_transaction_details1(item_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON online_orders1(customer_id);
CREATE INDEX IF NOT EXISTS idx_receipts_supplier ON goods_receipts1(supplier_id);

-- Inventory, order and employee role rules
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_attribute
        WHERE attrelid = 'goods_receipts1'::regclass AND attname = 'posted_at' AND NOT attisdropped
    ) THEN
        ALTER TABLE goods_receipts1 ADD COLUMN posted_at timestamp;
        UPDATE goods_receipts1 SET posted_at = received_at;

        ALTER TABLE employees1 ADD CONSTRAINT employees_id_role_key UNIQUE (id, role);
        ALTER TABLE goods_receipts1 ADD COLUMN required_warehouse_role varchar(20)
            GENERATED ALWAYS AS ('WAREHOUSE'::varchar(20)) STORED;
        ALTER TABLE online_orders1 ADD COLUMN required_warehouse_role varchar(20)
            GENERATED ALWAYS AS ('WAREHOUSE'::varchar(20)) STORED;
        ALTER TABLE online_orders1 ADD COLUMN required_delivery_role varchar(20)
            GENERATED ALWAYS AS ('DELIVERY'::varchar(20)) STORED;
        ALTER TABLE sale_transactions1 ADD COLUMN required_saler_role varchar(20)
            GENERATED ALWAYS AS ('SALER'::varchar(20)) STORED;

        ALTER TABLE goods_receipts1 ADD CONSTRAINT receipt_warehouse_role_fk
            FOREIGN KEY (warehouse_staff_id, required_warehouse_role) REFERENCES employees1(id, role);
        ALTER TABLE online_orders1 ADD CONSTRAINT order_warehouse_role_fk
            FOREIGN KEY (warehouse_staff_id, required_warehouse_role) REFERENCES employees1(id, role);
        ALTER TABLE online_orders1 ADD CONSTRAINT order_delivery_role_fk
            FOREIGN KEY (delivery_staff_id, required_delivery_role) REFERENCES employees1(id, role);
        ALTER TABLE sale_transactions1 ADD CONSTRAINT sale_saler_role_fk
            FOREIGN KEY (saler_id, required_saler_role) REFERENCES employees1(id, role);

        IF EXISTS (
            SELECT 1
            FROM online_orders1 o
            LEFT JOIN sale_transactions1 t ON t.online_order_id = o.id
            WHERE (o.status = 'COMPLETED') <> (t.id IS NOT NULL)
        ) THEN
            RAISE EXCEPTION 'Existing orders and online transactions must be reconciled before migration.';
        END IF;
        IF EXISTS (SELECT 1 FROM online_orders1 WHERE status = 'DISPATCHED') THEN
            RAISE EXCEPTION 'Reconcile the stock of existing dispatched orders before enabling inventory tracking.';
        END IF;
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS inventory_movements1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    item_id bigint NOT NULL REFERENCES items1(id),
    kind varchar(20) NOT NULL,
    quantity_delta integer NOT NULL,
    occurred_at timestamp NOT NULL,
    receipt_id bigint REFERENCES goods_receipts1(id),
    order_id bigint REFERENCES online_orders1(id),
    transaction_id bigint REFERENCES sale_transactions1(id),
    CONSTRAINT inventory_movement_source_key
        UNIQUE NULLS NOT DISTINCT (kind, item_id, receipt_id, order_id, transaction_id),
    CHECK (
        (kind = 'OPENING' AND quantity_delta >= 0 AND num_nonnulls(receipt_id, order_id, transaction_id) = 0)
        OR (kind = 'RECEIPT' AND quantity_delta > 0 AND receipt_id IS NOT NULL
            AND order_id IS NULL AND transaction_id IS NULL)
        OR (kind IN ('DISPATCH', 'RETURN') AND order_id IS NOT NULL
            AND receipt_id IS NULL AND transaction_id IS NULL
            AND ((kind = 'DISPATCH' AND quantity_delta < 0) OR (kind = 'RETURN' AND quantity_delta > 0)))
        OR (kind = 'COUNTER_SALE' AND quantity_delta < 0 AND transaction_id IS NOT NULL
            AND receipt_id IS NULL AND order_id IS NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_inventory_item ON inventory_movements1(item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_receipt ON inventory_movements1(receipt_id) WHERE receipt_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_inventory_order ON inventory_movements1(order_id) WHERE order_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_inventory_sale ON inventory_movements1(transaction_id) WHERE transaction_id IS NOT NULL;

-- Existing stock is the starting balance. Historical sample sales are not replayed.
INSERT INTO inventory_movements1 (item_id, kind, quantity_delta, occurred_at)
SELECT i.id, 'OPENING', i.stock_quantity, LOCALTIMESTAMP FROM items1 i
WHERE NOT EXISTS (SELECT 1 FROM inventory_movements1 m WHERE m.item_id = i.id);

CREATE OR REPLACE FUNCTION opening_inventory() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO inventory_movements1 (item_id, kind, quantity_delta, occurred_at)
    VALUES (NEW.id, 'OPENING', NEW.stock_quantity, LOCALTIMESTAMP);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION check_inventory_balance() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM items1 i WHERE i.id = NEW.id AND i.stock_quantity <> (
            SELECT coalesce(sum(m.quantity_delta), 0) FROM inventory_movements1 m WHERE m.item_id = i.id
        )
    ) THEN
        RAISE EXCEPTION 'Stock for item % must match its inventory movements.', NEW.id USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION require_order_transition() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    movement_kind varchar(20);
    direction integer;
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.status <> 'PENDING' THEN
            RAISE EXCEPTION 'New orders must start as PENDING.' USING ERRCODE = '23514';
        END IF;
        RETURN NEW;
    END IF;
    IF OLD.status <> 'PENDING' AND ROW(
        NEW.customer_id, NEW.order_code, NEW.ordered_at, NEW.delivery_address, NEW.delivery_phone, NEW.delivery_name,
        NEW.warehouse_staff_id, NEW.delivery_staff_id
    ) IS DISTINCT FROM ROW(
        OLD.customer_id, OLD.order_code, OLD.ordered_at, OLD.delivery_address, OLD.delivery_phone, OLD.delivery_name,
        OLD.warehouse_staff_id, OLD.delivery_staff_id
    ) THEN
        RAISE EXCEPTION 'The details and staff of a processed order are immutable.' USING ERRCODE = '23514';
    END IF;
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    IF OLD.status = 'PENDING' AND NEW.status = 'DISPATCHED' THEN
        IF NEW.warehouse_staff_id IS NULL OR NEW.delivery_staff_id IS NULL THEN
            RAISE EXCEPTION 'Dispatch requires warehouse and delivery staff.' USING ERRCODE = '23514';
        END IF;
        movement_kind := 'DISPATCH';
        direction := -1;
    ELSIF OLD.status = 'DISPATCHED' AND NEW.status = 'CANCELLED' THEN
        movement_kind := 'RETURN';
        direction := 1;
    ELSIF (OLD.status = 'DISPATCHED' AND NEW.status = 'COMPLETED')
       OR (OLD.status = 'PENDING' AND NEW.status = 'CANCELLED') THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Invalid order transition: % to %.', OLD.status, NEW.status USING ERRCODE = '23514';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM online_order_details1 WHERE order_id = OLD.id)
       OR EXISTS (
        SELECT 1
        FROM (SELECT item_id, quantity FROM online_order_details1 WHERE order_id = OLD.id) d
        FULL JOIN (
            SELECT item_id, quantity_delta FROM inventory_movements1
            WHERE order_id = OLD.id AND kind = movement_kind
        ) m USING (item_id)
        WHERE d.quantity * direction IS DISTINCT FROM m.quantity_delta
    ) THEN
        RAISE EXCEPTION 'Order % inventory movements do not match its lines.', OLD.id USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION check_movement_source() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    valid boolean;
BEGIN
    CASE NEW.kind
        WHEN 'OPENING' THEN
            RETURN NULL;
        WHEN 'RECEIPT' THEN
            SELECT r.posted_at = NEW.occurred_at AND d.quantity = NEW.quantity_delta INTO valid
            FROM goods_receipts1 r JOIN goods_receipt_details1 d ON d.receipt_id = r.id
            WHERE r.id = NEW.receipt_id AND d.item_id = NEW.item_id;
        WHEN 'COUNTER_SALE' THEN
            SELECT t.channel = 'COUNTER' AND t.sold_at = NEW.occurred_at
                AND -sum(d.quantity) = NEW.quantity_delta INTO valid
            FROM sale_transactions1 t JOIN sale_transaction_details1 d ON d.transaction_id = t.id
            WHERE t.id = NEW.transaction_id AND d.item_id = NEW.item_id GROUP BY t.id;
        WHEN 'DISPATCH' THEN
            SELECT d.quantity = -NEW.quantity_delta AND NEW.occurred_at >= o.ordered_at AND (
                o.status IN ('DISPATCHED', 'COMPLETED')
                OR (o.status = 'CANCELLED' AND EXISTS (
                    SELECT 1 FROM inventory_movements1 m WHERE m.order_id = o.id
                    AND m.item_id = NEW.item_id AND m.kind = 'RETURN'
                ))
            ) INTO valid
            FROM online_orders1 o JOIN online_order_details1 d ON d.order_id = o.id
            WHERE o.id = NEW.order_id AND d.item_id = NEW.item_id;
        WHEN 'RETURN' THEN
            SELECT o.status = 'CANCELLED' AND -m.quantity_delta = NEW.quantity_delta
                AND NEW.occurred_at >= m.occurred_at INTO valid
            FROM online_orders1 o JOIN inventory_movements1 m ON m.order_id = o.id
            WHERE o.id = NEW.order_id AND m.item_id = NEW.item_id AND m.kind = 'DISPATCH';
    END CASE;
    IF valid IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'Inventory movement % does not match its source.', NEW.id USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION require_receipt_posting() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.posted_at IS NOT NULL THEN
            RAISE EXCEPTION 'Create receipts as drafts and post them after adding lines.' USING ERRCODE = '23514';
        END IF;
        RETURN NEW;
    END IF;
    IF OLD.posted_at IS NOT NULL THEN
        RAISE EXCEPTION 'A posted receipt is immutable.' USING ERRCODE = '23514';
    END IF;
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    IF NEW.posted_at IS NOT NULL AND (
        NOT EXISTS (SELECT 1 FROM goods_receipt_details1 WHERE receipt_id = OLD.id)
        OR EXISTS (
            SELECT 1
            FROM (SELECT item_id, quantity FROM goods_receipt_details1 WHERE receipt_id = OLD.id) d
            FULL JOIN (
                SELECT item_id, quantity_delta FROM inventory_movements1 WHERE receipt_id = OLD.id
            ) m USING (item_id)
            WHERE d.quantity IS DISTINCT FROM m.quantity_delta
        )
    ) THEN
        RAISE EXCEPTION 'Receipt % inventory movements do not match its lines.', OLD.id USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION protect_document_lines() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    document_ids bigint[];
    document_id bigint;
    editable boolean;
BEGIN
    IF TG_TABLE_NAME = 'online_order_details1' THEN
        document_ids := ARRAY[
            CASE WHEN TG_OP <> 'INSERT' THEN OLD.order_id END,
            CASE WHEN TG_OP <> 'DELETE' THEN NEW.order_id END
        ];
    ELSE
        document_ids := ARRAY[
            CASE WHEN TG_OP <> 'INSERT' THEN OLD.receipt_id END,
            CASE WHEN TG_OP <> 'DELETE' THEN NEW.receipt_id END
        ];
    END IF;

    FOR document_id IN SELECT DISTINCT id FROM unnest(document_ids) AS id WHERE id IS NOT NULL ORDER BY id
    LOOP
        IF TG_TABLE_NAME = 'online_order_details1' THEN
            SELECT status = 'PENDING' INTO editable FROM online_orders1 WHERE id = document_id FOR UPDATE;
        ELSE
            SELECT posted_at IS NULL INTO editable FROM goods_receipts1 WHERE id = document_id FOR UPDATE;
        END IF;
        IF editable IS DISTINCT FROM true THEN
            RAISE EXCEPTION 'Document % no longer accepts line changes.', document_id USING ERRCODE = '23514';
        END IF;
    END LOOP;
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION check_order_sale() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    order_status varchar(20);
    sale_id bigint;
BEGIN
    SELECT status INTO order_status FROM online_orders1 WHERE id = NEW.id;
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    SELECT id INTO sale_id FROM sale_transactions1 WHERE online_order_id = NEW.id;
    IF (order_status = 'COMPLETED') <> (sale_id IS NOT NULL) THEN
        RAISE EXCEPTION 'Order % must have exactly one sale if and only if completed.', NEW.id USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION check_sale_document() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    sale sale_transactions1%ROWTYPE;
    sale_id bigint;
BEGIN
    IF TG_TABLE_NAME = 'sale_transactions1' THEN
        sale_id := NEW.id;
    ELSE
        sale_id := NEW.transaction_id;
    END IF;
    SELECT * INTO STRICT sale FROM sale_transactions1 WHERE id = sale_id;

    IF NOT EXISTS (SELECT 1 FROM sale_transaction_details1 WHERE transaction_id = sale.id) THEN
        RAISE EXCEPTION 'Sale % must contain at least one line.', sale.id USING ERRCODE = '23514';
    END IF;
    IF sale.channel = 'ONLINE' THEN
        IF NOT EXISTS (
            SELECT 1 FROM online_orders1
            WHERE id = sale.online_order_id AND status = 'COMPLETED' AND ordered_at <= sale.sold_at
        ) OR EXISTS (
            SELECT 1 FROM inventory_movements1 WHERE order_id = sale.online_order_id
            AND kind = 'DISPATCH' AND occurred_at > sale.sold_at
        )
           OR EXISTS (
            SELECT 1 FROM (
                SELECT item_id, quantity, unit_price, discount_amount FROM online_order_details1 WHERE order_id = sale.online_order_id
            ) o FULL JOIN (
                SELECT item_id, quantity, unit_price, discount_amount FROM sale_transaction_details1 WHERE transaction_id = sale.id
            ) d USING (item_id, unit_price)
            WHERE o.quantity IS DISTINCT FROM d.quantity OR o.discount_amount IS DISTINCT FROM d.discount_amount
        ) THEN
            RAISE EXCEPTION 'Online sale % must match the completed order and its lines.', sale.id USING ERRCODE = '23514';
        END IF;
    ELSIF EXISTS (
        SELECT 1 FROM (
            SELECT item_id, sum(quantity) AS quantity FROM sale_transaction_details1
            WHERE transaction_id = sale.id GROUP BY item_id
        ) d FULL JOIN (
            SELECT item_id, quantity_delta FROM inventory_movements1 WHERE transaction_id = sale.id
        ) m USING (item_id)
        WHERE -d.quantity IS DISTINCT FROM m.quantity_delta
    ) THEN
        RAISE EXCEPTION 'Counter sale % inventory movements do not match its lines.', sale.id USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION protect_posted_sale() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Recorded sales are append-only.' USING ERRCODE = '23514';
END;
$$;

CREATE OR REPLACE TRIGGER item_opening_inventory AFTER INSERT ON items1
FOR EACH ROW EXECUTE FUNCTION opening_inventory();
DROP TRIGGER IF EXISTS inventory_balance_check ON items1;
CREATE CONSTRAINT TRIGGER inventory_balance_check AFTER INSERT OR UPDATE OF stock_quantity ON items1
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_inventory_balance();

CREATE OR REPLACE TRIGGER order_transition BEFORE INSERT OR UPDATE ON online_orders1
FOR EACH ROW EXECUTE FUNCTION require_order_transition();
CREATE OR REPLACE TRIGGER receipt_posting BEFORE INSERT OR UPDATE OR DELETE ON goods_receipts1
FOR EACH ROW EXECUTE FUNCTION require_receipt_posting();
CREATE OR REPLACE TRIGGER order_lines_lock BEFORE INSERT OR UPDATE OR DELETE ON online_order_details1
FOR EACH ROW EXECUTE FUNCTION protect_document_lines();
CREATE OR REPLACE TRIGGER receipt_lines_lock BEFORE INSERT OR UPDATE OR DELETE ON goods_receipt_details1
FOR EACH ROW EXECUTE FUNCTION protect_document_lines();
CREATE OR REPLACE TRIGGER sale_header_immutable
    BEFORE DELETE OR UPDATE OF id, transaction_code, sold_at, channel, saler_id, online_order_id, customer_id
    ON sale_transactions1
FOR EACH ROW EXECUTE FUNCTION protect_posted_sale();
CREATE OR REPLACE TRIGGER sale_line_immutable BEFORE UPDATE OR DELETE ON sale_transaction_details1
FOR EACH ROW EXECUTE FUNCTION protect_posted_sale();

DROP TRIGGER IF EXISTS completed_order_sale_check ON online_orders1;
CREATE CONSTRAINT TRIGGER completed_order_sale_check AFTER INSERT OR UPDATE OF status ON online_orders1
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_order_sale();
DROP TRIGGER IF EXISTS sale_header_check ON sale_transactions1;
CREATE CONSTRAINT TRIGGER sale_header_check AFTER INSERT ON sale_transactions1
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_sale_document();
DROP TRIGGER IF EXISTS sale_lines_check ON sale_transaction_details1;
CREATE CONSTRAINT TRIGGER sale_lines_check AFTER INSERT ON sale_transaction_details1
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_sale_document();

DROP TRIGGER IF EXISTS inventory_source_check ON inventory_movements1;
CREATE CONSTRAINT TRIGGER inventory_source_check AFTER INSERT ON inventory_movements1
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_movement_source();

-- Call these functions inside a transaction. They lock the source document
-- and touch stock rows in item-id order to serialize competing stock changes.
CREATE OR REPLACE FUNCTION post_goods_receipt(p_receipt_id bigint, p_posted_at timestamp DEFAULT LOCALTIMESTAMP)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    receipt goods_receipts1%ROWTYPE;
BEGIN
    SELECT * INTO STRICT receipt FROM goods_receipts1 WHERE id = p_receipt_id FOR UPDATE;
    IF receipt.posted_at IS NOT NULL THEN
        RETURN receipt.id;
    END IF;
    IF p_posted_at IS NULL OR p_posted_at < receipt.received_at THEN
        RAISE EXCEPTION 'Posting time cannot precede the receipt time.' USING ERRCODE = '23514';
    END IF;

    INSERT INTO inventory_movements1 (item_id, kind, quantity_delta, occurred_at, receipt_id)
    SELECT item_id, 'RECEIPT', quantity, p_posted_at, receipt.id
    FROM goods_receipt_details1 WHERE receipt_id = receipt.id ORDER BY item_id;
    UPDATE goods_receipts1 SET posted_at = p_posted_at WHERE id = receipt.id;
    RETURN receipt.id;
END;
$$;

CREATE OR REPLACE FUNCTION dispatch_online_order(
    p_order_id bigint, p_warehouse_staff_id bigint, p_delivery_staff_id bigint,
    p_dispatched_at timestamp DEFAULT LOCALTIMESTAMP
) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    order_row online_orders1%ROWTYPE;
BEGIN
    SELECT * INTO STRICT order_row FROM online_orders1 WHERE id = p_order_id FOR UPDATE;
    IF order_row.status IN ('DISPATCHED', 'COMPLETED')
       AND order_row.warehouse_staff_id = p_warehouse_staff_id
       AND order_row.delivery_staff_id = p_delivery_staff_id THEN
        RETURN order_row.id;
    END IF;
    IF order_row.status <> 'PENDING' OR p_dispatched_at IS NULL OR p_dispatched_at < order_row.ordered_at THEN
        RAISE EXCEPTION 'Only pending orders can be dispatched, at or after the order time.' USING ERRCODE = '23514';
    END IF;

    INSERT INTO inventory_movements1 (item_id, kind, quantity_delta, occurred_at, order_id)
    SELECT item_id, 'DISPATCH', -quantity, p_dispatched_at, order_row.id
    FROM online_order_details1 WHERE order_id = order_row.id ORDER BY item_id;
    UPDATE online_orders1 SET status = 'DISPATCHED', warehouse_staff_id = p_warehouse_staff_id,
        delivery_staff_id = p_delivery_staff_id WHERE id = order_row.id;
    RETURN order_row.id;
END;
$$;

CREATE OR REPLACE FUNCTION complete_online_order(
    p_order_id bigint, p_transaction_code varchar, p_sold_at timestamp DEFAULT LOCALTIMESTAMP
) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    order_row online_orders1%ROWTYPE;
    sale_id bigint;
    normalized_code varchar := nullif(btrim(p_transaction_code), '');
BEGIN
    SELECT * INTO STRICT order_row FROM online_orders1 WHERE id = p_order_id FOR UPDATE;
    IF order_row.status = 'COMPLETED' THEN
        SELECT id INTO sale_id FROM sale_transactions1
        WHERE online_order_id = order_row.id AND transaction_code = normalized_code;
        IF FOUND THEN
            RETURN sale_id;
        END IF;
        RAISE EXCEPTION 'Order % already has a different transaction code.', p_order_id USING ERRCODE = '23505';
    END IF;
    IF order_row.status <> 'DISPATCHED' OR p_sold_at IS NULL OR p_sold_at < order_row.ordered_at
       OR EXISTS (SELECT 1 FROM inventory_movements1 WHERE order_id = order_row.id
                  AND kind = 'DISPATCH' AND occurred_at > p_sold_at) THEN
        RAISE EXCEPTION 'Complete a dispatched order at or after dispatch.' USING ERRCODE = '23514';
    END IF;

    INSERT INTO sale_transactions1 (transaction_code, sold_at, channel, online_order_id)
    VALUES (normalized_code, p_sold_at, 'ONLINE', order_row.id) RETURNING id INTO sale_id;
    INSERT INTO sale_transaction_details1 (transaction_id, item_id, quantity, unit_price, discount_amount)
    SELECT sale_id, item_id, quantity, unit_price, discount_amount
    FROM online_order_details1 WHERE order_id = order_row.id;
    UPDATE online_orders1 SET status = 'COMPLETED' WHERE id = order_row.id;
    RETURN sale_id;
END;
$$;

-- Calling this for a dispatched order means the goods have been received back.
CREATE OR REPLACE FUNCTION cancel_online_order(p_order_id bigint, p_returned_at timestamp DEFAULT LOCALTIMESTAMP)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    order_row online_orders1%ROWTYPE;
BEGIN
    SELECT * INTO STRICT order_row FROM online_orders1 WHERE id = p_order_id FOR UPDATE;
    IF order_row.status = 'CANCELLED' THEN
        RETURN order_row.id;
    END IF;
    IF order_row.status = 'COMPLETED' THEN
        RAISE EXCEPTION 'A completed order cannot be cancelled.' USING ERRCODE = '23514';
    END IF;
    IF order_row.status = 'DISPATCHED' THEN
        IF p_returned_at IS NULL OR EXISTS (
            SELECT 1 FROM inventory_movements1 WHERE order_id = order_row.id
            AND kind = 'DISPATCH' AND occurred_at > p_returned_at
        ) THEN
            RAISE EXCEPTION 'The return cannot precede dispatch.' USING ERRCODE = '23514';
        END IF;
        INSERT INTO inventory_movements1 (item_id, kind, quantity_delta, occurred_at, order_id)
        SELECT item_id, 'RETURN', quantity, p_returned_at, order_row.id
        FROM online_order_details1 WHERE order_id = order_row.id ORDER BY item_id;
    END IF;
    UPDATE online_orders1 SET status = 'CANCELLED' WHERE id = order_row.id;
    RETURN order_row.id;
END;
$$;

CREATE OR REPLACE FUNCTION record_counter_sale(
    p_transaction_code varchar, p_saler_id bigint, p_sold_at timestamp, p_lines jsonb, p_customer_id bigint
) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    sale_id bigint;
    normalized_code varchar := nullif(btrim(p_transaction_code), '');
BEGIN
    IF jsonb_typeof(p_lines) IS DISTINCT FROM 'array' THEN
        RAISE EXCEPTION 'Sale lines must be a JSON array.' USING ERRCODE = '23514';
    END IF;
    IF jsonb_array_length(p_lines) = 0 OR EXISTS (
        SELECT 1 FROM jsonb_to_recordset(p_lines) AS l(item_id bigint, quantity integer, unit_price numeric, discount_amount numeric)
        WHERE l.item_id IS NULL OR l.quantity IS NULL OR l.quantity <= 0
        OR l.unit_price IS NULL OR l.unit_price < 0 OR l.unit_price <> round(l.unit_price, 2)
        OR l.unit_price >= 'Infinity'::numeric
        OR l.discount_amount NOT BETWEEN 0 AND l.quantity * l.unit_price
        OR l.discount_amount <> round(l.discount_amount, 2)
    ) THEN
        RAISE EXCEPTION 'Each sale line needs an item, positive quantity and valid unit price.' USING ERRCODE = '23514';
    END IF;

    INSERT INTO sale_transactions1 (transaction_code, sold_at, channel, saler_id, customer_id)
    VALUES (normalized_code, p_sold_at, 'COUNTER', p_saler_id, p_customer_id)
    ON CONFLICT (transaction_code) DO NOTHING RETURNING id INTO sale_id;
    IF sale_id IS NULL THEN
        SELECT id INTO sale_id FROM sale_transactions1
        WHERE transaction_code = normalized_code AND channel = 'COUNTER'
        AND saler_id = p_saler_id AND sold_at = p_sold_at AND customer_id IS NOT DISTINCT FROM p_customer_id;
        IF NOT FOUND OR EXISTS (
            SELECT 1 FROM (
                SELECT l.item_id, l.unit_price, sum(l.quantity) AS quantity,
                       sum(coalesce(l.discount_amount, 0)) AS discount_amount
                FROM jsonb_to_recordset(p_lines) AS l(item_id bigint, quantity integer, unit_price numeric, discount_amount numeric)
                GROUP BY l.item_id, l.unit_price
            ) expected FULL JOIN (
                SELECT item_id, unit_price, quantity, discount_amount
                FROM sale_transaction_details1 WHERE transaction_id = sale_id
            ) actual USING (item_id, unit_price)
            WHERE expected.quantity IS DISTINCT FROM actual.quantity
               OR expected.discount_amount IS DISTINCT FROM actual.discount_amount
        ) THEN
            RAISE EXCEPTION 'Transaction code % already has different sale data.', normalized_code USING ERRCODE = '23505';
        END IF;
        RETURN sale_id;
    END IF;

    INSERT INTO sale_transaction_details1 (transaction_id, item_id, quantity, unit_price, discount_amount)
    SELECT sale_id, l.item_id, sum(l.quantity)::integer, l.unit_price, sum(coalesce(l.discount_amount, 0))
    FROM jsonb_to_recordset(p_lines) AS l(item_id bigint, quantity integer, unit_price numeric, discount_amount numeric)
    GROUP BY l.item_id, l.unit_price;

    INSERT INTO inventory_movements1 (item_id, kind, quantity_delta, occurred_at, transaction_id)
    SELECT item_id, 'COUNTER_SALE', -sum(quantity)::integer, p_sold_at, sale_id
    FROM sale_transaction_details1 WHERE transaction_id = sale_id GROUP BY item_id ORDER BY item_id;
    RETURN sale_id;
END;
$$;

CREATE OR REPLACE FUNCTION record_counter_sale(
    p_transaction_code varchar, p_saler_id bigint, p_sold_at timestamp, p_lines jsonb
) RETURNS bigint LANGUAGE sql AS $$
    SELECT record_counter_sale(p_transaction_code, p_saler_id, p_sold_at, p_lines, NULL::bigint);
$$;

CREATE OR REPLACE FUNCTION require_counter_member() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.customer_id IS NOT NULL THEN
        PERFORM id FROM customers1 WHERE id = NEW.customer_id AND is_member FOR SHARE;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'A counter customer must be a registered member.' USING ERRCODE = '23514';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER counter_member_check AFTER INSERT ON sale_transactions1
    FOR EACH ROW EXECUTE FUNCTION require_counter_member();

CREATE OR REPLACE VIEW customer_purchases1 AS
    SELECT coalesce(t.customer_id, o.customer_id) AS customer_id,
           t.id AS transaction_id, t.transaction_code, t.sold_at, t.channel
    FROM sale_transactions1 t LEFT JOIN online_orders1 o ON o.id = t.online_order_id
    WHERE t.customer_id IS NOT NULL OR o.customer_id IS NOT NULL;

CREATE OR REPLACE FUNCTION lock_sale_settlement(p_sale_id bigint) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    -- Write a revision so concurrent changes serialize even with a repeatable-read snapshot.
    UPDATE sale_transactions1 SET settlement_revision = settlement_revision + 1
    WHERE id = p_sale_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sale % does not exist.', p_sale_id USING ERRCODE = '23503';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION validate_sale_payment() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    sale_total numeric;
    other_payments numeric;
BEGIN
    PERFORM lock_sale_settlement(NEW.transaction_id);
    IF TG_OP = 'UPDATE' AND (
        OLD.status <> 'PENDING' OR NEW.status = 'PENDING'
        OR (to_jsonb(NEW) - ARRAY['status', 'resolved_at']) IS DISTINCT FROM
           (to_jsonb(OLD) - ARRAY['status', 'resolved_at'])
    ) THEN
        RAISE EXCEPTION 'Only the result of a pending payment may be updated.' USING ERRCODE = '23514';
    END IF;
    IF NEW.status <> 'FAILED' THEN
        SELECT coalesce(sum(line_total - discount_amount), 0) INTO sale_total
        FROM sale_transaction_details1 WHERE transaction_id = NEW.transaction_id;
        SELECT coalesce(sum(amount), 0) INTO other_payments FROM sale_payments1
        WHERE transaction_id = NEW.transaction_id AND id <> NEW.id AND status IN ('PENDING', 'SUCCEEDED');
        IF NEW.amount + other_payments > sale_total THEN
            RAISE EXCEPTION 'Payment total exceeds the sale amount.' USING ERRCODE = '23514';
        END IF;
        IF EXISTS (
            SELECT 1 FROM sale_refunds1 r JOIN sale_transaction_details1 d ON d.id = r.sale_detail_id
            WHERE d.transaction_id = NEW.transaction_id AND NOT r.track_payment AND r.status = 'SUCCEEDED'
        ) THEN
            RAISE EXCEPTION 'This historical sale has refunds without payment records.' USING ERRCODE = '23514';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER sale_payment_check BEFORE INSERT OR UPDATE ON sale_payments1
    FOR EACH ROW EXECUTE FUNCTION validate_sale_payment();
CREATE OR REPLACE TRIGGER sale_payment_immutable BEFORE DELETE ON sale_payments1
    FOR EACH ROW EXECUTE FUNCTION protect_posted_sale();

CREATE OR REPLACE FUNCTION record_sale_payment(
    p_payment_code varchar, p_sale_id bigint, p_method varchar, p_amount numeric,
    p_requested_at timestamp, p_external_reference varchar DEFAULT NULL
) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    payment sale_payments1%ROWTYPE;
    code varchar := nullif(btrim(p_payment_code), '');
BEGIN
    PERFORM lock_sale_settlement(p_sale_id);
    SELECT * INTO payment FROM sale_payments1 WHERE payment_code = code;
    IF FOUND THEN
        IF ROW(payment.transaction_id, payment.method, payment.amount, payment.requested_at, payment.external_reference)
           IS DISTINCT FROM ROW(p_sale_id, p_method, p_amount, p_requested_at, p_external_reference) THEN
            RAISE EXCEPTION 'Payment code % already has different data.', code USING ERRCODE = '23505';
        END IF;
    ELSE
        IF p_amount <> round(p_amount, 2) THEN
            RAISE EXCEPTION 'Payment amount must have at most two decimal places.' USING ERRCODE = '23514';
        END IF;
        INSERT INTO sale_payments1 (payment_code, transaction_id, method, amount, requested_at, status, external_reference)
        VALUES (code, p_sale_id, p_method, p_amount, p_requested_at, 'PENDING', p_external_reference)
        RETURNING * INTO payment;
    END IF;
    RETURN payment.id;
END;
$$;

CREATE OR REPLACE FUNCTION resolve_sale_payment(p_payment_id bigint, p_status varchar, p_resolved_at timestamp)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    payment sale_payments1%ROWTYPE;
BEGIN
    SELECT * INTO STRICT payment FROM sale_payments1 WHERE id = p_payment_id;
    PERFORM lock_sale_settlement(payment.transaction_id);
    SELECT * INTO STRICT payment FROM sale_payments1 WHERE id = p_payment_id;
    IF p_status IS NULL OR p_status NOT IN ('SUCCEEDED', 'FAILED') THEN
        RAISE EXCEPTION 'A payment can only resolve to SUCCEEDED or FAILED.' USING ERRCODE = '23514';
    END IF;
    IF payment.status IS DISTINCT FROM p_status OR payment.resolved_at IS DISTINCT FROM p_resolved_at THEN
        UPDATE sale_payments1 SET status = p_status, resolved_at = p_resolved_at WHERE id = payment.id;
    END IF;
    RETURN payment.id;
END;
$$;

CREATE OR REPLACE VIEW sale_payment_balances1 AS
    SELECT t.id AS transaction_id, t.transaction_code, lines.sale_total,
           CASE WHEN payments.has_payment_records THEN payments.paid_amount END AS paid_amount,
           CASE WHEN payments.has_payment_records THEN lines.sale_total - payments.paid_amount END AS unpaid_amount,
           CASE WHEN payments.has_payment_records THEN refunds.refunded_amount END AS refunded_amount,
           CASE WHEN payments.has_payment_records THEN payments.paid_amount - refunds.refunded_amount END AS net_collected_amount,
           payments.has_payment_records
    FROM sale_transactions1 t
    CROSS JOIN LATERAL (
        SELECT coalesce(sum(line_total - discount_amount), 0) AS sale_total
        FROM sale_transaction_details1 WHERE transaction_id = t.id
    ) lines
    CROSS JOIN LATERAL (
        SELECT coalesce(sum(amount) FILTER (WHERE status = 'SUCCEEDED'), 0) AS paid_amount,
               count(*) > 0 AS has_payment_records
        FROM sale_payments1 WHERE transaction_id = t.id
    ) payments
    CROSS JOIN LATERAL (
        SELECT coalesce(sum(a.amount), 0) AS refunded_amount
        FROM sale_refund_payments1 a JOIN sale_refunds1 r ON r.id = a.refund_id
        JOIN sale_payments1 p ON p.id = a.payment_id
        WHERE p.transaction_id = t.id AND r.status = 'SUCCEEDED'
    ) refunds;

CREATE OR REPLACE FUNCTION number_sale_refund() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    PERFORM lock_sale_settlement(d.transaction_id) FROM sale_transaction_details1 d WHERE d.id = NEW.sale_detail_id;
    SELECT coalesce(max(line_sequence), 0) + 1 INTO NEW.line_sequence
    FROM sale_refunds1 WHERE sale_detail_id = NEW.sale_detail_id;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION check_sale_refund() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    sale_id bigint;
BEGIN
    SELECT transaction_id INTO STRICT sale_id FROM sale_transaction_details1 WHERE id = NEW.sale_detail_id;
    IF NOT NEW.track_payment THEN
        IF NEW.status <> 'SUCCEEDED' OR NEW.resolved_at IS NOT NULL OR EXISTS (
            SELECT 1 FROM sale_payments1 WHERE transaction_id = sale_id AND status IN ('PENDING', 'SUCCEEDED')
        ) THEN
            RAISE EXCEPTION 'A refund for a tracked sale must reference its payment.' USING ERRCODE = '23514';
        END IF;
    ELSIF NEW.refund_amount <= 0 OR (NEW.status = 'PENDING' AND NEW.resolved_at IS NOT NULL)
          OR (NEW.status <> 'PENDING' AND (NEW.resolved_at IS NULL OR NEW.resolved_at < NEW.refunded_at)) THEN
        RAISE EXCEPTION 'Payment refund needs a positive amount and a valid resolution time.' USING ERRCODE = '23514';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM sale_transaction_details1 d JOIN sale_transactions1 t ON t.id = d.transaction_id
        CROSS JOIN LATERAL (
            SELECT sum(quantity) AS quantity, sum(refund_amount) AS amount
            FROM sale_refunds1 WHERE sale_detail_id = d.id AND status IN ('PENDING', 'SUCCEEDED')
        ) refunds
        WHERE d.id = NEW.sale_detail_id
          AND (NEW.refunded_at < t.sold_at OR refunds.quantity > d.quantity
               OR refunds.amount > d.line_total - d.discount_amount)
    ) THEN
        RAISE EXCEPTION 'Refund cannot precede the sale or exceed the quantity or amount paid.'
            USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION validate_refund_status_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    PERFORM lock_sale_settlement(d.transaction_id) FROM sale_transaction_details1 d WHERE d.id = OLD.sale_detail_id;
    IF NOT OLD.track_payment OR OLD.status <> 'PENDING' OR NEW.status = 'PENDING'
       OR (to_jsonb(NEW) - ARRAY['status', 'resolved_at']) IS DISTINCT FROM
          (to_jsonb(OLD) - ARRAY['status', 'resolved_at']) THEN
        RAISE EXCEPTION 'Only the result of a pending refund may be updated.' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER sale_refund_sequence BEFORE INSERT ON sale_refunds1
    FOR EACH ROW EXECUTE FUNCTION number_sale_refund();
CREATE OR REPLACE TRIGGER sale_refund_check AFTER INSERT OR UPDATE ON sale_refunds1
    FOR EACH ROW EXECUTE FUNCTION check_sale_refund();
CREATE OR REPLACE TRIGGER sale_refund_immutable BEFORE DELETE ON sale_refunds1
    FOR EACH ROW EXECUTE FUNCTION protect_posted_sale();
CREATE OR REPLACE TRIGGER sale_refund_status_check BEFORE UPDATE ON sale_refunds1
    FOR EACH ROW EXECUTE FUNCTION validate_refund_status_change();

CREATE OR REPLACE FUNCTION validate_refund_payment() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    refund sale_refunds1%ROWTYPE;
    payment sale_payments1%ROWTYPE;
    sale_id bigint;
    reserved_amount numeric;
BEGIN
    SELECT d.transaction_id INTO STRICT sale_id FROM sale_refunds1 r
    JOIN sale_transaction_details1 d ON d.id = r.sale_detail_id WHERE r.id = NEW.refund_id;
    PERFORM lock_sale_settlement(sale_id);
    SELECT * INTO STRICT refund FROM sale_refunds1 WHERE id = NEW.refund_id;
    SELECT * INTO STRICT payment FROM sale_payments1 WHERE id = NEW.payment_id;
    IF NOT refund.track_payment OR refund.status <> 'PENDING' OR payment.transaction_id <> sale_id
       OR payment.status <> 'SUCCEEDED' OR refund.refunded_at < payment.resolved_at THEN
        RAISE EXCEPTION 'Refund must follow successful payments of the same sale.' USING ERRCODE = '23514';
    END IF;
    SELECT coalesce(sum(a.amount), 0) INTO reserved_amount FROM sale_refund_payments1 a
    JOIN sale_refunds1 r ON r.id = a.refund_id
    WHERE a.payment_id = payment.id AND r.status IN ('PENDING', 'SUCCEEDED');
    IF reserved_amount + NEW.amount > payment.amount THEN
        RAISE EXCEPTION 'Refund total exceeds the amount collected by this payment.' USING ERRCODE = '23514';
    END IF;
    IF NEW.amount + (SELECT coalesce(sum(amount), 0) FROM sale_refund_payments1 WHERE refund_id = refund.id)
       > refund.refund_amount THEN
        RAISE EXCEPTION 'Allocation exceeds the requested refund amount.' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION check_refund_allocation_total() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.track_payment AND NEW.refund_amount IS DISTINCT FROM (
        SELECT sum(amount) FROM sale_refund_payments1 WHERE refund_id = NEW.id
    ) THEN
        RAISE EXCEPTION 'The sum allocated to payments must match the refund amount.' USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE TRIGGER refund_payment_check BEFORE INSERT ON sale_refund_payments1
    FOR EACH ROW EXECUTE FUNCTION validate_refund_payment();
CREATE OR REPLACE TRIGGER refund_payment_immutable BEFORE UPDATE OR DELETE ON sale_refund_payments1
    FOR EACH ROW EXECUTE FUNCTION protect_posted_sale();
DROP TRIGGER IF EXISTS refund_allocation_total ON sale_refunds1;
CREATE CONSTRAINT TRIGGER refund_allocation_total AFTER INSERT OR UPDATE ON sale_refunds1
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_refund_allocation_total();

-- A financial refund is independent of receiving goods back into sellable stock.
CREATE OR REPLACE FUNCTION record_sale_refund(
    p_refund_code varchar, p_sale_detail_id bigint, p_refunded_at timestamp,
    p_quantity integer, p_refund_amount numeric
) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    normalized_code varchar := nullif(btrim(p_refund_code), '');
    refund_id bigint;
BEGIN
    IF p_refund_amount <> round(p_refund_amount, 2) THEN
        RAISE EXCEPTION 'Refund amount must have at most two decimal places.' USING ERRCODE = '23514';
    END IF;
    INSERT INTO sale_refunds1 (refund_code, sale_detail_id, refunded_at, quantity, refund_amount)
    VALUES (normalized_code, p_sale_detail_id, p_refunded_at, p_quantity, p_refund_amount)
    ON CONFLICT (refund_code) DO NOTHING RETURNING id INTO refund_id;
    IF refund_id IS NULL THEN
        SELECT id INTO refund_id FROM sale_refunds1 WHERE refund_code = normalized_code
            AND sale_detail_id = p_sale_detail_id AND refunded_at = p_refunded_at
            AND quantity = p_quantity AND refund_amount = p_refund_amount AND NOT track_payment;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Refund code % already has different refund data.', normalized_code USING ERRCODE = '23505';
        END IF;
    END IF;
    RETURN refund_id;
END;
$$;

CREATE OR REPLACE FUNCTION record_sale_refund(
    p_refund_code varchar, p_sale_detail_id bigint, p_refunded_at timestamp,
    p_quantity integer, p_refund_amount numeric, p_allocations jsonb
) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    code varchar := nullif(btrim(p_refund_code), '');
    new_refund_id bigint;
BEGIN
    IF jsonb_typeof(p_allocations) IS DISTINCT FROM 'array' THEN
        RAISE EXCEPTION 'Refund allocations must be a JSON array.' USING ERRCODE = '23514';
    END IF;
    IF p_refund_amount <= 0 OR p_refund_amount <> round(p_refund_amount, 2)
       OR p_refund_amount IS DISTINCT FROM (
           SELECT sum(a.amount) FROM jsonb_to_recordset(p_allocations) AS a(payment_id bigint, amount numeric)
       ) OR EXISTS (
           SELECT 1 FROM jsonb_to_recordset(p_allocations) AS a(payment_id bigint, amount numeric)
           WHERE a.payment_id IS NULL OR a.amount IS NULL OR a.amount <= 0 OR a.amount <> round(a.amount, 2)
       ) THEN
        RAISE EXCEPTION 'Allocations must be positive amounts with at most two decimals and match the refund.'
            USING ERRCODE = '23514';
    END IF;
    INSERT INTO sale_refunds1 (refund_code, sale_detail_id, refunded_at, quantity, refund_amount, track_payment, status)
    VALUES (code, p_sale_detail_id, p_refunded_at, p_quantity, p_refund_amount, true, 'PENDING')
    ON CONFLICT (refund_code) DO NOTHING RETURNING id INTO new_refund_id;
    IF new_refund_id IS NULL THEN
        SELECT id INTO new_refund_id FROM sale_refunds1 WHERE refund_code = code
            AND sale_detail_id = p_sale_detail_id AND refunded_at = p_refunded_at
            AND quantity = p_quantity AND refund_amount = p_refund_amount AND track_payment;
        IF NOT FOUND OR EXISTS (
            SELECT 1 FROM jsonb_to_recordset(p_allocations) AS a(payment_id bigint, amount numeric)
            FULL JOIN (SELECT payment_id, amount FROM sale_refund_payments1 WHERE refund_id = new_refund_id)
                stored USING (payment_id)
            WHERE a.amount IS DISTINCT FROM stored.amount
        ) OR jsonb_array_length(p_allocations) <> (
            SELECT count(*) FROM sale_refund_payments1 a WHERE a.refund_id = new_refund_id
        ) THEN
            RAISE EXCEPTION 'Refund code % already has different refund data.', code USING ERRCODE = '23505';
        END IF;
    ELSE
        INSERT INTO sale_refund_payments1 (refund_id, payment_id, amount)
        SELECT new_refund_id, a.payment_id, a.amount
        FROM jsonb_to_recordset(p_allocations) AS a(payment_id bigint, amount numeric);
    END IF;
    RETURN new_refund_id;
END;
$$;

CREATE OR REPLACE FUNCTION resolve_sale_refund(p_refund_id bigint, p_status varchar, p_resolved_at timestamp)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    refund sale_refunds1%ROWTYPE;
BEGIN
    PERFORM lock_sale_settlement(d.transaction_id)
    FROM sale_refunds1 r JOIN sale_transaction_details1 d ON d.id = r.sale_detail_id WHERE r.id = p_refund_id;
    SELECT * INTO STRICT refund FROM sale_refunds1 WHERE id = p_refund_id;
    IF p_status IS NULL OR p_status NOT IN ('SUCCEEDED', 'FAILED') THEN
        RAISE EXCEPTION 'A refund can only resolve to SUCCEEDED or FAILED.' USING ERRCODE = '23514';
    END IF;
    IF refund.status IS DISTINCT FROM p_status OR refund.resolved_at IS DISTINCT FROM p_resolved_at THEN
        UPDATE sale_refunds1 SET status = p_status, resolved_at = p_resolved_at WHERE id = refund.id;
    END IF;
    RETURN refund.id;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_confirmed_refunds_date1
    ON sale_refunds1 ((coalesce(resolved_at, refunded_at))) WHERE status = 'SUCCEEDED';

ALTER TABLE items1 ADD COLUMN IF NOT EXISTS track_lots boolean NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS inventory_lots1 (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    receipt_id bigint NOT NULL,
    item_id bigint NOT NULL,
    lot_code varchar(60) NOT NULL CHECK (btrim(lot_code) <> ''),
    expires_on date NOT NULL,
    received_quantity integer NOT NULL CHECK (received_quantity > 0),
    FOREIGN KEY (receipt_id, item_id) REFERENCES goods_receipt_details1(receipt_id, item_id),
    UNIQUE (receipt_id, item_id, lot_code)
);
CREATE INDEX IF NOT EXISTS idx_inventory_lots_item1 ON inventory_lots1(item_id, expires_on, id);

CREATE TABLE IF NOT EXISTS inventory_lot_movements1 (
    inventory_movement_id bigint NOT NULL REFERENCES inventory_movements1(id),
    lot_id bigint NOT NULL REFERENCES inventory_lots1(id),
    quantity_delta integer NOT NULL CHECK (quantity_delta <> 0),
    PRIMARY KEY (inventory_movement_id, lot_id)
);
CREATE INDEX IF NOT EXISTS idx_lot_movements_lot1 ON inventory_lot_movements1(lot_id);

CREATE OR REPLACE FUNCTION protect_receipt_lots() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP <> 'INSERT' THEN
        PERFORM id FROM goods_receipts1 WHERE id = OLD.receipt_id FOR UPDATE;
        IF EXISTS (SELECT 1 FROM goods_receipts1 WHERE id = OLD.receipt_id AND posted_at IS NOT NULL) THEN
            RAISE EXCEPTION 'Posted receipt lots are immutable.' USING ERRCODE = '23514';
        END IF;
    END IF;
    IF TG_OP <> 'DELETE' THEN
        PERFORM id FROM goods_receipts1 WHERE id = NEW.receipt_id FOR UPDATE;
        IF EXISTS (SELECT 1 FROM goods_receipts1 WHERE id = NEW.receipt_id AND posted_at IS NOT NULL) THEN
            RAISE EXCEPTION 'Add lots before posting the receipt.' USING ERRCODE = '23514';
        END IF;
        RETURN NEW;
    END IF;
    RETURN OLD;
END;
$$;

CREATE OR REPLACE TRIGGER receipt_lots_lock BEFORE INSERT OR UPDATE OR DELETE ON inventory_lots1
    FOR EACH ROW EXECUTE FUNCTION protect_receipt_lots();
CREATE OR REPLACE FUNCTION protect_lot_movement() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP <> 'INSERT' OR pg_trigger_depth() < 2 THEN
        RAISE EXCEPTION 'Lot allocations are recorded by inventory movements only.' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER lot_movement_immutable BEFORE INSERT OR UPDATE OR DELETE ON inventory_lot_movements1
    FOR EACH ROW EXECUTE FUNCTION protect_lot_movement();

CREATE OR REPLACE VIEW inventory_lot_balances1 AS
    SELECT l.id AS lot_id, l.item_id, l.lot_code, l.expires_on, l.received_quantity,
           r.id AS receipt_id, r.receipt_code, r.supplier_id, r.posted_at,
           coalesce(sum(m.quantity_delta), 0) AS quantity_on_hand
    FROM inventory_lots1 l
    JOIN goods_receipts1 r ON r.id = l.receipt_id
    LEFT JOIN inventory_lot_movements1 m ON m.lot_id = l.id
    WHERE r.posted_at IS NOT NULL
    GROUP BY l.id, r.id;

CREATE OR REPLACE FUNCTION apply_inventory_movement() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    new_stock integer;
    lot_tracking boolean;
    tracked_stock bigint;
    receipt_quantity bigint;
    remaining integer;
    allocated integer;
    lot record;
BEGIN
    IF TG_OP <> 'INSERT' THEN
        RAISE EXCEPTION 'Inventory movements are append-only.' USING ERRCODE = '23514';
    END IF;
    IF NEW.kind = 'OPENING' THEN
        RETURN NEW;
    END IF;

    -- Existing stock mutation serializes all lot allocations for the same item.
    UPDATE items1
    SET stock_quantity = (stock_quantity::bigint + NEW.quantity_delta)::integer
    WHERE id = NEW.item_id AND stock_quantity::bigint + NEW.quantity_delta BETWEEN 0 AND 2147483647
    RETURNING stock_quantity, track_lots INTO new_stock, lot_tracking;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stock out of range for item %.', NEW.item_id USING ERRCODE = '23514';
    END IF;

    IF NEW.kind = 'RECEIPT' THEN
        SELECT coalesce(sum(received_quantity), 0) INTO receipt_quantity FROM inventory_lots1
        WHERE receipt_id = NEW.receipt_id AND item_id = NEW.item_id;
        IF (lot_tracking OR receipt_quantity > 0) AND receipt_quantity <> NEW.quantity_delta THEN
            RAISE EXCEPTION 'Lot quantities must match receipt quantities for item %.', NEW.item_id USING ERRCODE = '23514';
        END IF;
        IF EXISTS (
            SELECT 1 FROM inventory_lots1 WHERE receipt_id = NEW.receipt_id AND item_id = NEW.item_id
            AND expires_on < NEW.occurred_at::date
        ) THEN
            RAISE EXCEPTION 'Cannot post expired receipt lots for item %.', NEW.item_id USING ERRCODE = '23514';
        END IF;
        INSERT INTO inventory_lot_movements1 (inventory_movement_id, lot_id, quantity_delta)
        SELECT NEW.id, id, received_quantity FROM inventory_lots1
        WHERE receipt_id = NEW.receipt_id AND item_id = NEW.item_id;
    ELSIF NEW.kind = 'RETURN' THEN
        INSERT INTO inventory_lot_movements1 (inventory_movement_id, lot_id, quantity_delta)
        SELECT NEW.id, l.lot_id, -l.quantity_delta
        FROM inventory_movements1 m JOIN inventory_lot_movements1 l ON l.inventory_movement_id = m.id
        WHERE m.order_id = NEW.order_id AND m.item_id = NEW.item_id AND m.kind = 'DISPATCH';
    ELSE
        SELECT coalesce(sum(quantity_on_hand), 0) INTO tracked_stock FROM inventory_lot_balances1
        WHERE item_id = NEW.item_id;
        remaining := -NEW.quantity_delta;
        FOR lot IN
            SELECT lot_id, quantity_on_hand FROM inventory_lot_balances1
            WHERE item_id = NEW.item_id AND posted_at <= NEW.occurred_at
              AND expires_on >= NEW.occurred_at::date AND quantity_on_hand > 0
            ORDER BY expires_on, posted_at, lot_id
        LOOP
            allocated := least(remaining, lot.quantity_on_hand)::integer;
            INSERT INTO inventory_lot_movements1 (inventory_movement_id, lot_id, quantity_delta)
            VALUES (NEW.id, lot.lot_id, -allocated);
            remaining := remaining - allocated;
            EXIT WHEN remaining = 0;
        END LOOP;
        IF remaining > 0 AND (lot_tracking OR remaining > new_stock::bigint - NEW.quantity_delta - tracked_stock) THEN
            RAISE EXCEPTION 'Insufficient eligible stock for item %.', NEW.item_id USING ERRCODE = '23514';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER inventory_apply AFTER INSERT OR UPDATE OR DELETE ON inventory_movements1
    FOR EACH ROW EXECUTE FUNCTION apply_inventory_movement();

CREATE OR REPLACE VIEW inventory_lot_trace1 AS
    SELECT m.id AS inventory_movement_id, m.kind, m.occurred_at, m.item_id, m.order_id,
           coalesce(m.transaction_id, t.id) AS transaction_id, l.id AS lot_id, l.lot_code,
           l.expires_on, l.receipt_id, r.supplier_id, a.quantity_delta
    FROM inventory_lot_movements1 a
    JOIN inventory_movements1 m ON m.id = a.inventory_movement_id
    JOIN inventory_lots1 l ON l.id = a.lot_id
    JOIN goods_receipts1 r ON r.id = l.receipt_id
    LEFT JOIN sale_transactions1 t ON t.online_order_id = m.order_id;

-- Stored functions used by the JSP/DAO modules.
-- List results use refcursor so PostgreSQL JDBC can read them through CallableStatement.
CREATE OR REPLACE FUNCTION register_member1(
    p_full_name text, p_phone text, p_email text, p_address text, p_password_hash text
) RETURNS integer LANGUAGE plpgsql AS $$
DECLARE
    inserted_count integer;
    violated_constraint text;
BEGIN
    INSERT INTO customers1 (full_name, phone, email, address, password_hash, is_member)
    VALUES (p_full_name, normalize_customer_phone(p_phone), p_email, p_address, p_password_hash, true)
    ON CONFLICT (email) DO NOTHING;
    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    IF inserted_count = 1 THEN
        RETURN 1;
    END IF;
    RETURN 3;
EXCEPTION WHEN unique_violation THEN
    GET STACKED DIAGNOSTICS violated_constraint = CONSTRAINT_NAME;
    IF violated_constraint = 'uq_member_phone1' THEN
        RETURN 2;
    END IF;
    RAISE;
END;
$$;

DROP FUNCTION IF EXISTS issue_membership_code1(bigint, text, text, text);
DROP FUNCTION IF EXISTS register_member1(text, text, text, text, text, text);
ALTER TABLE customers1 DROP COLUMN IF EXISTS membership_code_hash,
    DROP COLUMN IF EXISTS membership_code_expires_at;

CREATE OR REPLACE FUNCTION member_for_sale1(p_full_name text, p_phone text, p_address text)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    phone_number text := normalize_customer_phone(p_phone);
    member_id bigint;
BEGIN
    IF phone_number IS NULL OR phone_number !~ '^0[35789][0-9]{8}$' THEN
        RAISE EXCEPTION 'A valid mobile number is required.' USING ERRCODE = 'P1003';
    END IF;

    INSERT INTO customers1 (full_name, phone, address, is_member)
    VALUES (p_full_name, phone_number, p_address, true)
    ON CONFLICT (normalize_customer_phone(phone)) WHERE is_member
    DO UPDATE SET is_member = true
    RETURNING id INTO member_id;
    RETURN member_id;
END;
$$;

-- The four-argument counter-sale entry point still handles anonymous purchases.
CREATE OR REPLACE FUNCTION record_counter_sale(
    p_transaction_code varchar, p_saler_id bigint, p_sold_at timestamp, p_lines jsonb,
    p_full_name text, p_phone text
) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    member_id bigint;
BEGIN
    IF nullif(btrim(p_phone), '') IS NOT NULL THEN
        member_id := member_for_sale1(coalesce(nullif(btrim(p_full_name), ''), 'Khách hàng'), p_phone, NULL);
    END IF;
    RETURN record_counter_sale(p_transaction_code, p_saler_id, p_sold_at, p_lines, member_id);
END;
$$;

DROP FUNCTION IF EXISTS place_online_order1(text, text, text, text, text, text, bigint, bigint[], integer[]);

CREATE OR REPLACE FUNCTION place_online_order1(
    p_code text, p_full_name text, p_phone text, p_address text,
    p_items bigint[], p_quantities integer[]
) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    v_customer_id bigint;
    v_order_id bigint;
    line record;
    phone text := normalize_customer_phone(p_phone);
BEGIN
    IF cardinality(p_items) IS NULL OR cardinality(p_items) = 0
        OR cardinality(p_items) IS DISTINCT FROM cardinality(p_quantities)
        OR EXISTS (
            SELECT 1 FROM unnest(p_items, p_quantities) AS requested(item_id, quantity)
            WHERE requested.item_id IS NULL OR requested.quantity IS NULL OR requested.quantity NOT BETWEEN 1 AND 99
        )
        OR cardinality(p_items) <> (SELECT count(DISTINCT id) FROM unnest(p_items) AS item(id)) THEN
        RAISE EXCEPTION 'Invalid order lines.' USING ERRCODE = 'P1001';
    END IF;

    FOR line IN SELECT item.id, item.active, item.stock_quantity, selection.quantity
        FROM unnest(p_items, p_quantities) AS selection(id, quantity)
        LEFT JOIN items1 item ON item.id = selection.id
        ORDER BY selection.id
    LOOP
        IF line.id IS NULL OR NOT line.active OR line.stock_quantity < line.quantity THEN
            RAISE EXCEPTION 'Item unavailable.' USING ERRCODE = 'P1001';
        END IF;
    END LOOP;

    v_customer_id := member_for_sale1(p_full_name, phone, p_address);

    INSERT INTO online_orders1 (order_code, customer_id, ordered_at, delivery_name, delivery_address, delivery_phone)
    VALUES (p_code, v_customer_id, clock_timestamp() AT TIME ZONE 'Asia/Ho_Chi_Minh', p_full_name, p_address, phone)
    RETURNING id INTO v_order_id;

    INSERT INTO online_order_details1 (order_id, item_id, quantity, unit_price)
    SELECT v_order_id, item.id, selection.quantity, item.current_price
    FROM unnest(p_items, p_quantities) AS selection(id, quantity)
    JOIN items1 item ON item.id = selection.id
    WHERE item.active AND item.stock_quantity >= selection.quantity
    ORDER BY item.id;
    IF (SELECT count(*) FROM online_order_details1 detail WHERE detail.order_id = v_order_id)
        <> cardinality(p_items) THEN
        RAISE EXCEPTION 'Item unavailable.' USING ERRCODE = 'P1001';
    END IF;
    RETURN v_order_id;
END;
$$;

-- The trusted SMS service generates the code and sends it after the issue transaction commits.
-- The database receives an HMAC of the code bound to the challenge, with the key held by that service.
CREATE OR REPLACE FUNCTION begin_member_account_setup1(
    p_phone text, p_challenge_id uuid, p_code_digest bytea
) RETURNS text LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, pg_temp AS $$
DECLARE
    normalized_phone text := public.normalize_customer_phone(p_phone);
    member_id bigint;
    previous_request public.member_account_verifications1%ROWTYPE;
    issued_time timestamptz;
    window_start timestamptz;
    request_count smallint;
BEGIN
    IF normalized_phone IS NULL OR normalized_phone !~ '^0[35789][0-9]{8}$'
       OR p_challenge_id IS NULL OR octet_length(p_code_digest) IS DISTINCT FROM 32 THEN
        RETURN 'INVALID_REQUEST';
    END IF;

    -- All setup steps serialize on the member row.
    SELECT id INTO member_id FROM public.customers1
    WHERE is_member AND public.normalize_customer_phone(phone) = normalized_phone AND password_hash IS NULL
    FOR UPDATE;
    IF NOT FOUND THEN
        RETURN 'INELIGIBLE';
    END IF;

    SELECT * INTO previous_request FROM public.member_account_verifications1 WHERE customer_id = member_id;
    issued_time := clock_timestamp();
    window_start := issued_time;
    request_count := 1;
    IF FOUND THEN
        IF previous_request.challenge_id = p_challenge_id THEN
            RETURN 'INVALID_REQUEST';
        END IF;
        IF issued_time < previous_request.issued_at + interval '1 minute' THEN
            RETURN 'RATE_LIMITED';
        END IF;
        IF issued_time < previous_request.request_window_started_at + interval '1 hour' THEN
            IF previous_request.requests_in_window = 5 THEN
                RETURN 'RATE_LIMITED';
            END IF;
            window_start := previous_request.request_window_started_at;
            request_count := previous_request.requests_in_window + 1;
        END IF;
    END IF;

    INSERT INTO public.member_account_verifications1 (
        customer_id, challenge_id, phone, code_digest, issued_at, request_window_started_at, requests_in_window
    ) VALUES (member_id, p_challenge_id, normalized_phone, p_code_digest, issued_time, window_start, request_count)
    ON CONFLICT (customer_id) DO UPDATE SET
        challenge_id = EXCLUDED.challenge_id,
        phone = EXCLUDED.phone,
        code_digest = EXCLUDED.code_digest,
        issued_at = EXCLUDED.issued_at,
        request_window_started_at = EXCLUDED.request_window_started_at,
        requests_in_window = EXCLUDED.requests_in_window,
        failed_attempts = 0,
        verified_at = NULL,
        setup_token_digest = NULL;
    RETURN 'ISSUED';
END;
$$;

CREATE OR REPLACE FUNCTION verify_member_account_phone1(
    p_challenge_id uuid, p_code_digest bytea, p_setup_token_digest bytea
) RETURNS text LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, pg_temp AS $$
DECLARE
    member_row public.customers1%ROWTYPE;
    verification public.member_account_verifications1%ROWTYPE;
    verified_time timestamptz;
BEGIN
    IF p_challenge_id IS NULL OR octet_length(p_code_digest) IS DISTINCT FROM 32
       OR octet_length(p_setup_token_digest) IS DISTINCT FROM 32 THEN
        RETURN 'INVALID_REQUEST';
    END IF;

    SELECT c.* INTO member_row
    FROM public.customers1 c JOIN public.member_account_verifications1 v ON v.customer_id = c.id
    WHERE v.challenge_id = p_challenge_id AND c.is_member AND c.password_hash IS NULL
    FOR UPDATE OF c;
    IF NOT FOUND THEN
        RETURN 'INVALID_CHALLENGE';
    END IF;

    SELECT * INTO verification FROM public.member_account_verifications1
    WHERE customer_id = member_row.id AND challenge_id = p_challenge_id;
    IF NOT FOUND OR verification.phone IS DISTINCT FROM public.normalize_customer_phone(member_row.phone)
       OR verification.verified_at IS NOT NULL THEN
        RETURN 'INVALID_CHALLENGE';
    END IF;

    verified_time := clock_timestamp();
    IF verified_time >= verification.issued_at + interval '5 minutes' THEN
        RETURN 'EXPIRED';
    END IF;
    IF verification.failed_attempts >= 5 THEN
        RETURN 'ATTEMPTS_EXHAUSTED';
    END IF;
    IF verification.code_digest <> p_code_digest THEN
        UPDATE public.member_account_verifications1
        SET failed_attempts = failed_attempts + 1 WHERE customer_id = member_row.id;
        RETURN 'INCORRECT_CODE';
    END IF;

    UPDATE public.member_account_verifications1
    SET code_digest = NULL, verified_at = verified_time, setup_token_digest = p_setup_token_digest
    WHERE customer_id = member_row.id;
    RETURN 'VERIFIED';
END;
$$;

CREATE OR REPLACE FUNCTION complete_member_account_setup1(
    p_challenge_id uuid, p_setup_token_digest bytea, p_email text, p_password_hash text
) RETURNS text LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, pg_temp AS $$
DECLARE
    member_row public.customers1%ROWTYPE;
    verification public.member_account_verifications1%ROWTYPE;
    normalized_email text := lower(btrim(p_email));
    completed_time timestamptz;
BEGIN
    IF p_challenge_id IS NULL OR octet_length(p_setup_token_digest) IS DISTINCT FROM 32 THEN
        RETURN 'INVALID_REQUEST';
    END IF;

    SELECT c.* INTO member_row
    FROM public.customers1 c JOIN public.member_account_verifications1 v ON v.customer_id = c.id
    WHERE v.challenge_id = p_challenge_id AND c.is_member AND c.password_hash IS NULL
    FOR UPDATE OF c;
    IF NOT FOUND THEN
        RETURN 'INVALID_CHALLENGE';
    END IF;

    SELECT * INTO verification FROM public.member_account_verifications1
    WHERE customer_id = member_row.id AND challenge_id = p_challenge_id;
    IF NOT FOUND OR verification.phone IS DISTINCT FROM public.normalize_customer_phone(member_row.phone)
       OR verification.setup_token_digest IS DISTINCT FROM p_setup_token_digest THEN
        RETURN 'INVALID_CHALLENGE';
    END IF;

    completed_time := clock_timestamp();
    IF completed_time >= verification.verified_at + interval '10 minutes' THEN
        RETURN 'EXPIRED';
    END IF;
    IF normalized_email IS NULL OR length(normalized_email) > 254
       OR normalized_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
       OR p_password_hash IS NULL
       OR p_password_hash !~ '^pbkdf2-sha256[$]600000[$][A-Za-z0-9+/]{22}==[$][A-Za-z0-9+/]{43}=$' THEN
        RETURN 'INVALID_CREDENTIALS';
    END IF;

    BEGIN
        UPDATE public.customers1
        SET email = normalized_email, password_hash = p_password_hash, account_setup_at = completed_time
        WHERE id = member_row.id;
    EXCEPTION WHEN unique_violation THEN
        RETURN 'DUPLICATE_EMAIL';
    END;

    DELETE FROM public.member_account_verifications1 WHERE customer_id = member_row.id;
    RETURN 'COMPLETED';
END;
$$;

CREATE OR REPLACE FUNCTION find_member_account1(p_email text)
RETURNS TABLE(customer_id bigint, password_hash varchar) LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog, pg_temp AS $$
    SELECT c.id, c.password_hash FROM public.customers1 c
    WHERE c.email = lower(btrim(p_email)) AND c.is_member AND c.password_hash IS NOT NULL;
$$;

REVOKE ALL ON TABLE member_account_verifications1 FROM PUBLIC;
REVOKE ALL ON FUNCTION begin_member_account_setup1(text, uuid, bytea),
    verify_member_account_phone1(uuid, bytea, bytea),
    complete_member_account_setup1(uuid, bytea, text, text), find_member_account1(text) FROM PUBLIC;

CREATE OR REPLACE FUNCTION find_management_account1(p_employee_code text, p_username text)
RETURNS refcursor LANGUAGE plpgsql AS $$
DECLARE
    result_cursor refcursor;
BEGIN
    OPEN result_cursor FOR
        SELECT id, role, password_hash
        FROM employees1
        WHERE employee_code = p_employee_code OR username = p_username
        LIMIT 2;
    RETURN result_cursor;
END;
$$;

CREATE OR REPLACE FUNCTION has_report_access1(p_employee_id bigint)
RETURNS boolean LANGUAGE sql AS $$
    SELECT EXISTS (
        SELECT 1 FROM employees1
        WHERE id = p_employee_id AND role = 'MANAGEMENT' AND password_hash IS NOT NULL
    );
$$;

CREATE OR REPLACE FUNCTION get_item_revenue1(p_from timestamp, p_until timestamp)
RETURNS refcursor LANGUAGE plpgsql AS $$
DECLARE
    result_cursor refcursor;
BEGIN
    OPEN result_cursor FOR
        WITH item_totals AS (
            SELECT item_id, COALESCE(SUM(quantity) FILTER (WHERE NOT is_refund), 0) AS quantity,
                   COALESCE(SUM(quantity) FILTER (WHERE is_refund), 0) AS returned_quantity,
                   COUNT(DISTINCT transaction_id) FILTER (WHERE NOT is_refund) AS transaction_count,
                   SUM(gross_amount) AS gross_amount, SUM(discount_amount) AS discount_amount,
                   SUM(refund_amount) AS refund_amount
            FROM item_revenue_events1
            WHERE occurred_at >= p_from AND occurred_at < p_until
            GROUP BY item_id
        )
        SELECT i.id, i.item_code, i.name, i.unit, totals.quantity, totals.returned_quantity,
               totals.transaction_count, totals.gross_amount, totals.discount_amount, totals.refund_amount,
               ARRAY(
                   SELECT s.supplier_code || ' · ' || s.name
                   FROM suppliers1 s
                   WHERE EXISTS (
                       SELECT 1
                       FROM goods_receipts1 r
                       JOIN goods_receipt_details1 d ON d.receipt_id = r.id
                       WHERE r.supplier_id = s.id AND d.item_id = i.id AND r.posted_at < p_until
                   )
                   ORDER BY s.supplier_code
               ) AS suppliers
        FROM item_totals totals
        JOIN items1 i ON i.id = totals.item_id
        ORDER BY totals.gross_amount - totals.discount_amount - totals.refund_amount DESC, i.item_code;
    RETURN result_cursor;
END;
$$;

CREATE OR REPLACE FUNCTION find_item1(p_item_id bigint)
RETURNS refcursor LANGUAGE plpgsql AS $$
DECLARE
    result_cursor refcursor;
BEGIN
    OPEN result_cursor FOR
        SELECT id, item_code, name, unit, description FROM items1 WHERE id = p_item_id;
    RETURN result_cursor;
END;
$$;

CREATE OR REPLACE FUNCTION get_related_transactions1(
    p_item_id bigint, p_from timestamp, p_until timestamp
) RETURNS refcursor LANGUAGE plpgsql AS $$
DECLARE
    result_cursor refcursor;
BEGIN
    OPEN result_cursor FOR
        WITH selected_events AS (
            SELECT transaction_id, transaction_code, event_code, occurred_at, channel, is_refund,
                   SUM(quantity) AS item_quantity,
                   ARRAY_AGG(DISTINCT unit_price ORDER BY unit_price) AS unit_prices,
                   SUM(gross_amount) AS gross_amount, SUM(discount_amount) AS discount_amount,
                   SUM(refund_amount) AS refund_amount
            FROM item_revenue_events1
            WHERE occurred_at >= p_from AND occurred_at < p_until AND item_id = p_item_id
            GROUP BY transaction_id, transaction_code, event_code, occurred_at, channel, is_refund
        )
        SELECT s.*, CASE WHEN s.is_refund THEN -s.refund_amount ELSE (
            SELECT SUM(d.line_total - d.discount_amount)
            FROM sale_transaction_details1 d WHERE d.transaction_id = s.transaction_id
        ) END AS transaction_total
        FROM selected_events s
        ORDER BY s.occurred_at DESC, s.event_code, s.is_refund;
    RETURN result_cursor;
END;
$$;

COMMIT;
