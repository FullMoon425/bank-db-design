# 시드 데이터 & 쿼리 작성 가이드

직접 SQL을 작성하며 공부하기 위한 참고 자료. SQL 본문은 없고, 규칙·시나리오·쿼리 목록만 정리한다.
기준 문서: `docs/def_entity.xlsx`, `docs/요구사항정의서.xlsx`

---

## 1. 이름 대응표

### 테이블 / 컬럼

| 한글 | 테이블 | 컬럼 (한글 → 영문) |
|---|---|---|
| 회원 | `member` | 회원id `member_id`, 주민번호 `rrn`, 이름 `name`, 국적 `nationality`, 주소 `address`, 생년월일 `birth_date`, 이메일 `email`, 전화번호 `phone`, 직업 `job` |
| 계좌 | `account` | 계좌번호 `account_no`, 회원id `member_id`, 계좌종류 `account_type`, 잔고 `balance`, 개설일자 `opened_date`, 상태 `status`, 해지일자 `closed_date` |
| 카드 | `card` | 카드번호 `card_no`, 회원id `member_id`, 카드종류 `card_type`, 신청일자 `applied_date`, 발급일자 `issued_date`, 한도 `credit_limit`, 결제일 `payment_day`, 연결계좌번호 `linked_account_no`, 상태 `status`, 해지일자 `closed_date` |
| 계좌거래내역 | `account_transaction` | 계좌번호 `account_no`, 거래번호 `tx_no`, 거래일시 `tx_at`, 거래종류 `tx_type`, 거래금액 `amount`, 적요 `description`, 거래후잔고 `balance_after`, 이체번호 `transfer_id` |
| 카드거래내역 | `card_transaction` | 카드번호 `card_no`, 거래번호 `tx_no`, 거래일시 `tx_at`, 가맹점 `merchant`, 거래금액 `amount`, 할부개월 `installment_months` |
| 계좌이체 | `transfer` | 이체번호 `transfer_id`, 출금계좌번호 `from_account_no`, 입금계좌번호 `to_account_no`, 이체금액 `amount`, 이체일시 `transferred_at`, 메모 `memo` |
| 카드청구서 | `card_bill` | 카드번호 `card_no`, 청구년월 `bill_month`, 청구금액 `bill_amount`, 납부기한 `due_date`, 납부금액 `paid_amount`, 납부일자 `paid_date`, 상태 `status` |

### ENUM 값

| 컬럼 | 값 |
|---|---|
| `account.account_type` | `CHECKING`(보통예금), `INSTALLMENT_SAVINGS`(적금) |
| `account.status` | `ACTIVE`, `SUSPENDED`, `CLOSED` |
| `card.card_type` | `CREDIT`, `DEBIT` |
| `card.status` | `ACTIVE`, `SUSPENDED`, `LOST`, `CLOSED` |
| `account_transaction.tx_type` | `DEPOSIT`, `WITHDRAWAL` |
| `card_bill.status` | `UNPAID`, `PAID` |

---

## 2. 시드 데이터

### 2-1. INSERT 순서 (FK 의존)

1. `member`
2. `account`
3. `card`
4. `transfer`
5. `account_transaction`
6. `card_transaction`
7. `card_bill`

### 2-2. 회원 시나리오

| 회원 | 목적 | account | card |
|---|---|---|---|
| A (일반) | 정상 흐름 전체 | `CHECKING` 2개 (잔고 충분) | `CREDIT` 1, `DEBIT` 1 |
| B (잔고 부족) | 출금·이체·체크결제 거절 | `CHECKING` 1개 (잔고 0 또는 소액) | `DEBIT` 1 |
| C (한도 임박) | 신용결제 한도 초과 거절 | `CHECKING` 1개 | `CREDIT` 1 (한도 거의 소진) |
| D (정지·해지) | 상태 관련 거절 | `SUSPENDED` 1개, `CLOSED` 1개 | `LOST` 1 |
| E (최소 정보) | NULL 허용 컬럼 확인 | 없음 | 없음 (`email`·`job` NULL, 외국인 `nationality`) |

### 2-3. 테이블별 규칙 (어기면 INSERT 실패)

**member**
- `rrn`: 13자리, UNIQUE. 가짜 번호 사용
- `phone`: 하이픈 없이
- `nationality` 기본값 `'대한민국'`

**account**
- `balance >= 0`, 기본값 0
- `closed_date`는 `status = 'CLOSED'`일 때만 NOT NULL

**card**
- `CREDIT`: `credit_limit`, `payment_day` 필수
- `DEBIT`: `credit_limit`, `payment_day` 모두 NULL
- `payment_day`: **1~28**
- `(linked_account_no, member_id)` → `account(account_no, member_id)`: 카드주 본인 계좌만 연결
- `issued_date` NULL = 미발급(신청만 된 상태)
- `closed_date`는 `status = 'CLOSED'`일 때만 NOT NULL

**account_transaction**
- PK `(account_no, tx_no)`. `tx_no`는 **계좌마다 1부터**
- `balance_after`는 시간순으로 이어져야 하고, 마지막 값 = `account.balance`
- 이체 거래는 `transfer_id`를 넣고 `WITHDRAWAL` 1건 + `DEPOSIT` 1건을 쌍으로
- `amount > 0`

**card_transaction**
- PK `(card_no, tx_no)`. `tx_no`는 **카드마다 1부터**
- `DEBIT` 카드는 `installment_months = 1`
- `DEBIT` 결제는 연결계좌의 `account_transaction`에도 `WITHDRAWAL`로 기록
- `amount > 0`

**transfer**
- `from_account_no <> to_account_no`
- `amount > 0`

**card_bill**
- PK `(card_no, bill_month)`. `CREDIT` 카드만
- `bill_month` 형식: `'202611'`
- `0 <= paid_amount <= bill_amount`
- `PAID`면 `paid_date` NOT NULL, `UNPAID`면 NULL (부분 납부 시 `UNPAID` + `paid_amount > 0`)

### 2-4. 꼭 넣어볼 케이스

- [ ] 같은 회원의 계좌 간 이체 1건
- [ ] 다른 회원 계좌로 이체 1건
- [ ] 3개월 할부 거래 1건
- [ ] `PAID` 청구서 1건, `UNPAID` 청구서 1건
- [ ] 카드대금 납부로 생긴 `account_transaction` 출금 1건
- [ ] 미발급 카드(`issued_date` NULL) 1장

### 2-5. 실패해야 정상인 INSERT (제약 동작 확인)

- `DEBIT` 카드에 `credit_limit` 입력 → CHECK 오류
- `payment_day = 31` → CHECK 오류
- 다른 회원의 계좌를 `linked_account_no`로 연결 → FK 오류
- `balance` 음수 → CHECK 오류
- `from_account_no = to_account_no` 이체 → CHECK 오류
- 같은 `rrn` 회원 2명 → UNIQUE 오류

### 2-6. 남은 한도 검산 예시

```
credit_limit                     3,000,000
− UNPAID 청구서 미납액 (bill_amount − paid_amount)   500,000
− 아직 청구 안 된 사용액                              200,000
= 남은 한도                                        2,300,000
```

---

## 3. 쿼리 목록

표기: **[문법]** 연습 포인트 / **(URQ)** 관련 요구사항

### 3-1. 회원 (URQ001)

| # | 쿼리 | 역할 | 문법 |
|---|---|---|---|
| Q01 | 회원 가입 | `member` INSERT | INSERT, AUTO_INCREMENT |
| Q02 | 회원 정보 수정 | 주소·전화번호·이메일·직업 변경 | UPDATE |
| Q03 | 주민번호로 회원 조회 | 가입 중복 확인·본인 확인 | SELECT + WHERE (UNIQUE 인덱스) |

### 3-2. 계좌 (URQ002, URQ004)

| # | 쿼리 | 역할 | 문법 |
|---|---|---|---|
| Q04 | 계좌 개설 | `account` INSERT | INSERT |
| Q05 | 회원별 계좌 목록 | 내 계좌 화면 | SELECT + WHERE + ORDER BY |
| Q06 | 계좌 해지 | `status='CLOSED'`, `closed_date` 설정 (잔고 0일 때만) | UPDATE + 조건 |
| Q07 | 계좌 거래내역 조회 | 기간 필터 + 최신순 + 페이징 | WHERE BETWEEN, ORDER BY, LIMIT/OFFSET |

### 3-3. 입출금·이체 (URQ002, URQ004, URQ007)

| # | 쿼리 | 역할 | 문법 |
|---|---|---|---|
| Q08 | 계좌 잠금 조회 | 잔고·상태 확인 + 동시 수정 방지 | SELECT ... FOR UPDATE, 트랜잭션 |
| Q09 | 다음 거래번호 구하기 | 계좌별 `MAX(tx_no) + 1` | 집계 함수, COALESCE |
| Q10 | 잔고 변경 | 입금 `+`, 출금 `−` | UPDATE (계산식) |
| Q11 | 계좌거래내역 기록 | `account_transaction` INSERT | INSERT |
| Q12 | 이체 기록 | `transfer` INSERT 후 생성된 `transfer_id` 사용 | INSERT, LAST_INSERT_ID() |
| Q13 | 이체 상세 조회 | 이체 1건 + 출금·입금 거래내역 2건 | JOIN (같은 테이블 2번 / 셀프 조인 형태) |

> 이체 = Q08(출금계좌, 입금계좌) → Q12 → Q09·Q10·Q11 ×2 를 **하나의 트랜잭션**으로

### 3-4. 카드 (URQ003)

| # | 쿼리 | 역할 | 문법 |
|---|---|---|---|
| Q14 | 카드 발급 신청 | `card` INSERT (`issued_date` NULL) | INSERT |
| Q15 | 카드 발급 처리 | `issued_date` 설정 | UPDATE |
| Q16 | 카드 상태 변경 | 정지·분실·해지 | UPDATE |
| Q17 | 회원별 카드 목록 | 카드 + 연결계좌 정보 | INNER JOIN |
| Q18 | 카드 없는 계좌 찾기 | 카드가 연결 안 된 계좌 | LEFT JOIN + IS NULL / NOT EXISTS |

### 3-5. 결제 (URQ005, URQ006)

| # | 쿼리 | 역할 | 문법 |
|---|---|---|---|
| Q19 | 남은 한도 계산 | 한도 − 미납 청구액 − 미청구 사용액 | 서브쿼리, SUM, COALESCE |
| Q20 | 카드거래 기록 | `card_transaction` INSERT | INSERT |
| Q21 | 체크카드 결제 | 연결계좌 잔고 확인 → 출금 → 카드거래 + 계좌거래 기록 | 트랜잭션 (Q08~Q11 재사용) |
| Q22 | 카드 사용내역 조회 | 기간별 사용 내역 | WHERE + ORDER BY |

### 3-6. 청구·납부 (URQ008)

| # | 쿼리 | 역할 | 문법 |
|---|---|---|---|
| Q23 | 월 청구금액 집계 | 일시불 + 할부 회차분(`amount / installment_months`) 합산 | GROUP BY, 날짜 함수, CASE |
| Q24 | 청구서 생성 | 집계 결과로 `card_bill` INSERT | INSERT ... SELECT |
| Q25 | 대금 납부 | `paid_amount`·`paid_date`·`status` 갱신 + 계좌 출금 | UPDATE, 트랜잭션 |
| Q26 | 미납 청구서 목록 | 납부기한 지난 `UNPAID` | WHERE + 날짜 비교 + JOIN(member) |

### 3-7. 통계 연습

| # | 쿼리 | 역할 | 문법 |
|---|---|---|---|
| Q27 | 월별 카드 사용액 | 회원·월별 합계 | GROUP BY + DATE_FORMAT |
| Q28 | 가맹점별 사용 합계 Top N | 많이 쓴 가맹점 | GROUP BY + ORDER BY + LIMIT |
| Q29 | 회원별 총잔고 순위 | 회원별 잔고 합 + 순위 | SUM + RANK() OVER (윈도우 함수) |
| Q30 | 잔고 정합성 검사 | `account.balance` = 마지막 `balance_after`인지 확인 | 상관 서브쿼리 / JOIN |

---

## 4. SQL 문법 레퍼런스 (MySQL 8)

일반 형태 + 짧은 예시. 예시는 Q01~Q30의 정답이 아니라 문법 감 잡기용.

### 4-1. INSERT

```sql
INSERT INTO 테이블 (컬럼1, 컬럼2, ...) VALUES (값1, 값2, ...);

-- 여러 행 한 번에
INSERT INTO 테이블 (컬럼1, 컬럼2) VALUES (a1, a2), (b1, b2);

-- 다른 SELECT 결과로 INSERT
INSERT INTO 테이블 (컬럼1, 컬럼2)
SELECT x, y FROM 다른테이블 WHERE ...;
```
```sql
INSERT INTO member (rrn, name, address, birth_date, phone)
VALUES ('9001011234567', 'Hong', 'Seoul', '1990-01-01', '01012345678');

SELECT LAST_INSERT_ID();   -- 방금 AUTO_INCREMENT로 생성된 값 (같은 커넥션 기준)
```
- 생략한 컬럼은 DEFAULT 값 또는 NULL이 들어간다.

### 4-2. SELECT 기본

```sql
SELECT 컬럼1, 컬럼2
FROM 테이블
WHERE 조건
ORDER BY 컬럼 [ASC|DESC]
LIMIT 개수 OFFSET 건너뛸개수;
```
| 조건 | 예시 |
|---|---|
| 비교 | `balance >= 10000` |
| 범위 | `tx_at BETWEEN '2026-11-01' AND '2026-11-30 23:59:59'` |
| 목록 | `status IN ('SUSPENDED', 'CLOSED')` |
| NULL | `issued_date IS NULL` (`= NULL`은 항상 거짓) |
| 패턴 | `merchant LIKE '%커피%'` |
| 논리 | `AND`, `OR`, `NOT` (섞을 땐 괄호) |

- 페이징: 2페이지(페이지당 20건) → `LIMIT 20 OFFSET 20`

### 4-3. UPDATE / DELETE

```sql
UPDATE 테이블 SET 컬럼1 = 값1, 컬럼2 = 값2 WHERE 조건;
DELETE FROM 테이블 WHERE 조건;
```
```sql
UPDATE account SET balance = balance + 50000 WHERE account_no = '110-111-111111';
```
- **WHERE를 빼면 전체 행이 바뀐다.** 실행 전 같은 WHERE로 SELECT 먼저 해보기.
- 이 프로젝트는 금융 기록을 DELETE하지 않고 `status`로 관리한다.

### 4-4. 집계 함수 & GROUP BY

```sql
SELECT 그룹컬럼, COUNT(*), SUM(컬럼), AVG(컬럼), MAX(컬럼), MIN(컬럼)
FROM 테이블
WHERE 행 조건            -- 그룹 만들기 전 필터
GROUP BY 그룹컬럼
HAVING 집계 조건          -- 그룹 만든 후 필터
ORDER BY ...;
```
```sql
SELECT card_no, SUM(amount) AS total
FROM card_transaction
GROUP BY card_no
HAVING SUM(amount) >= 1000000;
```
- SELECT에는 GROUP BY 컬럼 또는 집계 함수만 올 수 있다.
- 행이 없으면 `SUM()`은 NULL → `COALESCE(SUM(amount), 0)`

### 4-5. JOIN

```sql
SELECT a.컬럼, b.컬럼
FROM 테이블A a
[INNER | LEFT] JOIN 테이블B b ON a.키 = b.키;
```
| 종류 | 결과 |
|---|---|
| `INNER JOIN` | 양쪽 모두 매칭되는 행만 |
| `LEFT JOIN` | 왼쪽은 전부 + 오른쪽은 매칭 없으면 NULL |

```sql
-- 회원 + 계좌
SELECT m.name, a.account_no, a.balance
FROM member m
JOIN account a ON a.member_id = m.member_id;

-- 계좌가 없는 회원 (LEFT JOIN + IS NULL 패턴)
SELECT m.name
FROM member m
LEFT JOIN account a ON a.member_id = m.member_id
WHERE a.account_no IS NULL;
```
- 같은 테이블을 두 번 JOIN할 땐 별칭을 다르게: `JOIN account fa ON ...`, `JOIN account ta ON ...`
- 복합키 JOIN: `ON x.card_no = y.card_no AND x.tx_no = y.tx_no`

### 4-6. 서브쿼리

```sql
-- 스칼라 (값 1개)
SELECT name, (SELECT COUNT(*) FROM account a WHERE a.member_id = m.member_id) AS cnt
FROM member m;

-- IN / EXISTS
SELECT * FROM member m
WHERE EXISTS (SELECT 1 FROM card c WHERE c.member_id = m.member_id);

-- FROM 절 (파생 테이블, 별칭 필수)
SELECT t.card_no, t.total
FROM (SELECT card_no, SUM(amount) AS total FROM card_transaction GROUP BY card_no) t
WHERE t.total > 100000;
```
- **상관 서브쿼리**: 바깥 쿼리의 컬럼(`m.member_id`)을 안에서 참조 → 행마다 실행됨

### 4-7. CASE / COALESCE

```sql
CASE WHEN 조건1 THEN 값1
     WHEN 조건2 THEN 값2
     ELSE 기본값 END

COALESCE(값1, 값2, ...)   -- 처음으로 NULL이 아닌 값
```
```sql
SELECT tx_no,
       CASE WHEN tx_type = 'DEPOSIT' THEN amount ELSE -amount END AS signed_amount
FROM account_transaction;
```

### 4-8. 날짜 함수

| 함수 | 예시 | 결과 |
|---|---|---|
| `NOW()` | | 현재 일시 |
| `CURDATE()` | | 오늘 날짜 |
| `DATE_FORMAT(d, fmt)` | `DATE_FORMAT(tx_at, '%Y%m')` | `'202611'` |
| `DATE_ADD(d, INTERVAL n unit)` | `DATE_ADD('2026-11-15', INTERVAL 1 MONTH)` | `2026-12-15` |
| `TIMESTAMPDIFF(unit, a, b)` | `TIMESTAMPDIFF(MONTH, '2026-09-10', '2026-11-10')` | `2` |
| `LAST_DAY(d)` | `LAST_DAY('2026-11-15')` | `2026-11-30` |
| `STR_TO_DATE(s, fmt)` | `STR_TO_DATE('20261115', '%Y%m%d')` | `2026-11-15` |

- 할부 회차 계산에 `TIMESTAMPDIFF(MONTH, 거래월, 청구월)`이 유용하다.

### 4-9. 트랜잭션 & 잠금

```sql
START TRANSACTION;
  SELECT ... FROM account WHERE account_no = ? FOR UPDATE;  -- 이 행을 잠금
  UPDATE account SET balance = ... WHERE account_no = ?;
  INSERT INTO account_transaction ...;
COMMIT;      -- 전부 반영
-- ROLLBACK; -- 문제 생기면 전부 취소
```
- `FOR UPDATE`: 트랜잭션이 끝날 때까지 다른 트랜잭션이 같은 행을 수정·잠금 못 함 → 잔고 동시 변경 방지
- 두 계좌를 잠글 땐 **항상 같은 순서**(예: 계좌번호 오름차순)로 잠가야 데드락을 피한다.
- 스프링에서는 `@Transactional`이 START/COMMIT/ROLLBACK을 대신한다.

### 4-10. 윈도우 함수

```sql
함수() OVER ([PARTITION BY 그룹컬럼] ORDER BY 정렬컬럼)
```
| 함수 | 역할 |
|---|---|
| `ROW_NUMBER()` | 1, 2, 3, 4 (동점도 다른 번호) |
| `RANK()` | 1, 2, 2, 4 |
| `DENSE_RANK()` | 1, 2, 2, 3 |
| `SUM(x) OVER (...)` | 누적합 |

```sql
-- 계좌별 최신 거래 1건
SELECT * FROM (
  SELECT t.*, ROW_NUMBER() OVER (PARTITION BY account_no ORDER BY tx_no DESC) AS rn
  FROM account_transaction t
) x
WHERE rn = 1;
```
- GROUP BY와 달리 행이 줄어들지 않는다.

### 4-11. DDL에서 쓰는 제약 (참고)

```sql
CREATE TABLE 테이블 (
  컬럼 타입 NOT NULL DEFAULT 값,
  ...,
  PRIMARY KEY (컬럼1, 컬럼2),
  UNIQUE (컬럼),
  FOREIGN KEY (컬럼) REFERENCES 부모(컬럼) ON DELETE RESTRICT,
  CONSTRAINT 이름 CHECK (조건)
);
```
```sql
CONSTRAINT chk_card_credit CHECK (
  (card_type = 'CREDIT' AND credit_limit IS NOT NULL AND payment_day BETWEEN 1 AND 28)
  OR
  (card_type = 'DEBIT'  AND credit_limit IS NULL     AND payment_day IS NULL)
)
```
- CHECK는 **같은 행의 컬럼만** 참조 가능. 다른 테이블을 봐야 하면 트리거나 애플리케이션에서 처리.

### 4-12. 실행 계획

```sql
EXPLAIN SELECT ...;
```
- `type`이 `ALL`이면 전체 스캔 → 인덱스 확인
- `key` 컬럼에 사용된 인덱스 이름이 나온다
