CREATE TABLE member (
    member_id INT NOT NULL AUTO_INCREMENT,
    rrn CHAR(13) NOT NULL,
    nationality VARCHAR(50) NOT NULL DEFAULT '대한민국',
    name VARCHAR(50) NOT NULL,
    address VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(11) NOT NULL,
    job VARCHAR(50),
    
    PRIMARY KEY (member_id),
    UNIQUE (rrn)
) ENGINE InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE account (
    account_no VARCHAR(20) NOT NULL,
    member_id INT NOT NULL,
    account_type ENUM('CHECKING', 'INSTALLMENT_SAVINGS') NOT NULL,
    balance DECIMAL(15, 0) NOT NULL,
    opened_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    status ENUM('ACTIVE', 'SUSPENDED', 'CLOSED') NOT NULL DEFAULT 'ACTIVE',
    closed_date DATE,

    PRIMARY KEY(account_no),
    UNIQUE(account_no, member_id),
    CONSTRAINT fk_account_member
        FOREIGN KEY (member_id) REFERENCES member(member_id),

    CONSTRAINT chk_account_balance CHECK (
        balance >= 0
    ),
    CONSTRAINT chk_account_closed CHECK (
        (status = 'CLOSED' AND closed_date IS NOT NULL)
        OR
        (status <> 'CLOSED' AND closed_date IS NULL)
    )
) ENGINE InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE card (
    card_no CHAR(16) NOT NULL,
    member_id INT NOT NULL,
    card_type ENUM('DEBIT', 'CREDIT') NOT NULL,
    applied_date DATE NOT NULL,
    issued_date DATE,
    credit_limit DECIMAL(15, 0),
    payment_day TINYINT,
    linked_account_no VARCHAR(20) NOT NULL,
    status ENUM('PENDING','ACTIVE','SUSPENDED','LOST','CLOSED') 
        NOT NULL DEFAULT 'PENDING',
    closed_date DATE,

    PRIMARY KEY(card_no),
    CONSTRAINT fk_card_member
        FOREIGN KEY (member_id) REFERENCES member(member_id),

    CONSTRAINT fk_card_account
        FOREIGN KEY (linked_account_no, member_id) 
        REFERENCES account(account_no, member_id),
    
    CONSTRAINT chk_card_credit_limit CHECK (
        (card_type = 'CREDIT' AND credit_limit IS NOT NULL AND credit_limit >= 0)
        OR
        (card_type = 'DEBIT' AND credit_limit IS NULL)
    ),

    CONSTRAINT chk_card_payment_day CHECK (
        (card_type = 'CREDIT' AND payment_day IS NOT NULL AND payment_day BETWEEN 1 AND 28)
        OR
        (card_type = 'DEBIT' AND payment_day IS NULL)
    ),

    CONSTRAINT chk_card_issued CHECK (
        (status IN ('ACTIVE', 'SUSPENDED', 'LOST', 'CLOSED') AND issued_date IS NOT NULL)
        OR
        (status IN ('PENDING') AND issued_date IS NULL)
    ),

    CONSTRAINT chk_card_closed CHECK (
        (status = 'CLOSED' AND closed_date IS NOT NULL)
        OR
        (status <> 'CLOSED' AND closed_date IS NULL)
    )

) ENGINE InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE transfer (
    transfer_id INT NOT NULL AUTO_INCREMENT,
    from_account_no VARCHAR(20) NOT NULL,
    to_account_no VARCHAR(20) NOT NULL,
    amount DECIMAL(15, 0) NOT NULL,
    transfer_at DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP),
    memo VARCHAR(100),

    PRIMARY KEY(transfer_id),

    CONSTRAINT fk_transfer_from_account
        FOREIGN KEY (from_account_no) REFERENCES account(account_no),

    CONSTRAINT fk_transfer_to_account
        FOREIGN KEY (to_account_no) REFERENCES account(account_no),

    CONSTRAINT chk_transfer_accounts CHECK (
        from_account_no <> to_account_no
    ),

    CONSTRAINT chk_transfer_amount CHECK (
        amount > 0
    )

) ENGINE InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE account_transaction (
    account_no VARCHAR(20) NOT NULL,
    tx_no INT NOT NULL,
    tx_at DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP),
    tx_type ENUM('DEPOSIT', 'WITHDRAWAL') NOT NULL,
    amount DECIMAL(15, 0) NOT NULL,
    description VARCHAR(100),
    balance_after DECIMAL(15, 0) NOT NULL,
    transfer_id INT,
    
    PRIMARY KEY(account_no, tx_no),
    CONSTRAINT fk_transaction_account
        FOREIGN KEY (account_no) REFERENCES account(account_no),
    
    CONSTRAINT fk_transaction_transfer 
        FOREIGN KEY (transfer_id) REFERENCES transfer(transfer_id),

    CONSTRAINT chk_account_amount CHECK (
        amount > 0
    )
) ENGINE InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE card_transaction (
    card_no CHAR(16) NOT NULL,
    tx_no INT NOT NULL,
    tx_at DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP),
    merchant VARCHAR(100) NOT NULL,
    amount DECIMAL(15, 0) NOT NULL,
    installment_months TINYINT NOT NULL DEFAULT 1,

    PRIMARY KEY(card_no, tx_no),
    CONSTRAINT fk_card_transaction
        FOREIGN KEY (card_no) REFERENCES card(card_no),

    CONSTRAINT chk_card_amount CHECK (
        amount > 0
    ),

    CONSTRAINT chk_card_installment CHECK (
        installment_months >= 1 AND installment_months <= 36
    )
) ENGINE InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE card_bill (
    card_no CHAR(16) NOT NULL,
    bill_month CHAR(6) NOT NULL,
    bill_amount DECIMAL(15, 0) NOT NULL,
    due_date DATE NOT NULL,
    paid_amount DECIMAL(15, 0) NOT NULL DEFAULT 0,
    last_paid_date DATE,
    status ENUM('UNPAID', 'PARTIAL', 'PAID') NOT NULL DEFAULT 'UNPAID',

    PRIMARY KEY(card_no, bill_month),
    CONSTRAINT fk_bill_card
        FOREIGN KEY (card_no) REFERENCES card(card_no),

    CONSTRAINT chk_paid_amount CHECK (
        bill_amount > 0 AND paid_amount >= 0 AND paid_amount <= bill_amount
    ),

    CONSTRAINT chk_paid_date CHECK (
        (status = 'PAID' AND last_paid_date IS NOT NULL 
            AND paid_amount = bill_amount)
        OR
        (status = 'PARTIAL' AND last_paid_date IS NOT NULL
            AND paid_amount > 0 
            AND paid_amount < bill_amount)
        OR
        (status = 'UNPAID' AND last_paid_date IS NULL 
            AND paid_amount = 0)
    ),

    CONSTRAINT chk_bill_month CHECK (
        bill_month REGEXP '^[0-9]{4}(0[1-9]|1[0-2])$'
    )
) ENGINE InnoDB DEFAULT CHARSET=utf8mb4;