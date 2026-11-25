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
    opened_date DATE NOT NULL DEFAULT 0,
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
        (closed_date = 'CLOSED' AND closed_date IS NOT NULL)
        OR
        (status <> 'CLOSED' AND closed_date IS NULL)
    )
) ENGINE InnoDB DEFAULT CHARSET=utf8mb4;