CREATE TABLE users (
    user_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(100) UNIQUE NOT NULL,
    phone        VARCHAR(15),
    kyc_status   kyc_status_enum DEFAULT 'pending',
    account_tier account_tier_enum DEFAULT 'basic',
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);	


CREATE TABLE wallets (
    wallet_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     INT NOT NULL,
    balance     DECIMAL(12,2) DEFAULT 0.00,
    currency    VARCHAR(5) DEFAULT 'INR',
    is_active   BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

create table transactions (
	txn_id int generated always as identity primary key,
	sender_wallet int not null,
	receiver_wallet int not null,
	amount decimal(12,2) not null,
	txn_type txn_type_enum not null,
	status txn_status_enum not null,
	initiated_at timestamp not null,
	completed_at timestamp,
	failure_reason varchar(200),
	device_id varchar(50),
	ip_address varchar(20),
	foreign key (sender_wallet) references wallets(wallet_id),
	foreign key (receiver_wallet) references wallets(wallet_id)
);

CREATE TYPE txn_type_enum AS ENUM ('p2p', 'bill_pay', 'wallet_load', 'refund');
CREATE TYPE txn_status_enum AS ENUM ('success', 'failed', 'pending', 'flagged');





CREATE TYPE flag_type_enum AS ENUM ('high_value', 'rapid_succession', 'new_device', 'geo_anomaly');

CREATE TABLE risk_flags (
    flag_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    txn_id      INT NOT NULL,
    flag_type   flag_type_enum NOT NULL,
    flag_score  INT DEFAULT 0,
    reviewed    BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (txn_id) REFERENCES transactions(txn_id)
);


---users--

INSERT INTO users (full_name, email, phone, kyc_status, account_tier) VALUES
('Rahul sharma',   'rahul@email.com',   '1235678903', 'verified', 'premium'), -- Fixed spelling here
('Priya Patel',    'priya@email.com',   '9812345678', 'verified', 'basic'),
('Amit Verma',     'amit@email.com',    '9823456789', 'pending',  'basic'),
('Sneha Gupta',    'sneha@email.com',   '9834567890', 'verified', 'enterprise'),
('Karan Mehta',    'karan@email.com',   '9845678901', 'rejected', 'basic'),
('Deepika Singh',  'deepika@email.com', '9856789012', 'verified', 'premium'),
('Rohit Joshi',    'rohit@email.com',   '9867890123', 'verified', 'basic'),
('Nisha Agarwal',  'nisha@email.com',   '9878901234', 'pending',  'basic');


-- ── WALLETS ──

INSERT INTO wallets (user_id, balance, currency, is_active) VALUES
(1, 85000.00,  'INR', TRUE), 
(2, 12000.00,  'INR', TRUE),
(3, 5000.00,   'INR', TRUE), 
(4, 350000.00, 'INR', TRUE),
(5, 800.00,    'INR', FALSE), 
(6, 42000.00,  'INR', TRUE),
(7, 15000.00,  'INR', TRUE), 
(8, 3200.00,   'INR', TRUE);


-- ── TRANSACTIONS ──
INSERT INTO transactions (sender_wallet,receiver_wallet,amount,txn_type,status,initiated_at,completed_at,failure_reason,device_id,ip_address) VALUES
(1,2,  5000,'p2p',    'success', '2024-01-05 09:15:00','2024-01-05 09:15:03',NULL,          'DEV001','103.21.4.5'),
(1,3, 12000,'p2p',    'success', '2024-01-05 09:18:00','2024-01-05 09:18:02',NULL,          'DEV001','103.21.4.5'),
(1,4, 75000,'p2p',    'flagged', '2024-01-05 09:20:00',NULL,                 NULL,          'DEV999','202.54.1.9'),
(2,1,  2500,'bill_pay','success','2024-01-06 14:30:00','2024-01-06 14:30:05',NULL,          'DEV002','103.22.5.6'),
(3,2,  1000,'p2p',    'failed',  '2024-01-07 11:00:00',NULL,                 'Insufficient funds','DEV003','103.23.6.7'),
(4,1, 50000,'p2p',    'success', '2024-01-08 16:45:00','2024-01-08 16:45:04',NULL,          'DEV004','103.24.7.8'),
(6,7,  8000,'p2p',    'success', '2024-01-10 10:00:00','2024-01-10 10:00:03',NULL,          'DEV006','103.26.9.10'),
(7,8,   500,'p2p',    'success', '2024-01-10 10:05:00','2024-01-10 10:05:02',NULL,          'DEV007','103.27.10.11'),
(4,6, 20000,'wallet_load','success','2024-01-12 09:00:00','2024-01-12 09:00:02',NULL,       'DEV004','103.24.7.8'),
(1,2, 30000,'p2p',    'flagged', '2024-01-15 23:55:00',NULL,                 NULL,          'DEV999','202.99.1.1'),
(5,1,  1500,'p2p',    'failed',  '2024-01-16 08:30:00',NULL,'Account inactive','DEV005','103.25.8.9'),
(6,4, 15000,'p2p',    'success', '2024-01-18 13:20:00','2024-01-18 13:20:04',NULL,          'DEV006','103.26.9.10');



-- ── RISK FLAGS ──
INSERT INTO risk_flags (txn_id, flag_type, flag_score, reviewed) VALUES
(3,  'high_value',       85, FALSE),
(3,  'rapid_succession', 70, FALSE),
(3,  'new_device',       60, FALSE),
(10, 'high_value',       90, FALSE),
(10, 'geo_anomaly',      75, TRUE);


select count(*) from transactions;

select * from users
select * from wallets
select * from transactions
select * from risk_flags


-- ── 1. Transaction Volume by Type and Status ──
select txn_type,
	status,
	count(*)	as txn_count,
	sum(amount)	as total_amount,
	avg(amount)	as avg_amount,
	max(amount)	as max_amount
from transactions
group by txn_type, status 
order by total_amount desc;


-- ── 2. Peak Transfer Hours ──
SELECT 
    EXTRACT(HOUR FROM initiated_at) AS hour_of_day, -- Updated this line to match Postgres syntax
    COUNT(*) AS txn_count,
    SUM(amount) AS total_volume,
    ROUND(AVG(amount), 2) AS avg_txn_value
FROM transactions
WHERE status = 'success'
GROUP BY EXTRACT(HOUR FROM initiated_at)
ORDER BY txn_count DESC;


-- ── 3. High-Risk User Detection (Subquery) ──
select u.user_id,
	u.full_name,
	u.kyc_status,
	u.account_tier,
	risk_data.total_flagged,
	risk_data.max_risk_score
from users u 
join wallets w on u.user_id = w.user_id
join(
	select t.sender_wallet,
	count(rf.flag_id) 	as total_flagged,
	max(rf.flag_score)	as max_risk_score
	from transactions t
	join risk_flags rf on t.txn_id = rf.txn_id
	where t.status = 'flagged'	
	group by t.sender_wallet
)as risk_data on w.wallet_id = risk_data.sender_wallet
order by risk_data.max_risk_score desc;

		
-- ── 4. Failure Rate by Wallet ──
SELECT * FROM (
    SELECT 
        w.wallet_id,
        u.full_name,
        COUNT(*) AS total_txns,
        SUM(CASE WHEN t.status = 'failed' THEN 1 ELSE 0 END) AS failed_txns,
        ROUND(
            SUM(CASE WHEN t.status = 'failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
        ) AS failure_rate_pct
    FROM transactions t 
    JOIN wallets w ON t.sender_wallet = w.wallet_id
    JOIN users u ON w.user_id = u.user_id -- 1. Fixed 'user' to 'users' to avoid the reserved keyword conflict
    GROUP BY w.wallet_id, u.full_name
) as wallet_summary
WHERE failure_rate_pct > 0 -- 2. Moved from HAVING to WHERE using a subquery so Postgres recognizes the alias
ORDER BY failure_rate_pct DESC;


-- ── 5. Rolling 7-Day Transaction Volume ──
select t1.initiated_at 	as txn_date,
	t1.txn_id,
	t1.amount,
	sum(t2.amount) 	as rolling_7d_volume,
	count(t2.txn_id) as rolling_7d_count
from transactions t1
join transactions t2
	on t2.initiated_at between
	t1.initiated_at- interval '7 day'
	and t1.initiated_at
and t2.status = 'success'
where t1.status = 'success'
group by t1.txn_id, t1.initiated_at, t1.amount
order by t1.initiated_at;
	
