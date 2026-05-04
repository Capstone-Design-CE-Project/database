-- ============================================================
-- 치매 어르신 상담 앱 - DB 스키마 v2
-- PostgreSQL 16
-- 현재 단계: 클로바 없이 .json 파일만 사용
-- ============================================================
-- 1. 어르신 유저 테이블
CREATE TABLE users (
    id           BIGSERIAL    PRIMARY KEY,
    name         VARCHAR(50)  NOT NULL,
    password     CHAR(4)      NOT NULL, -- 4자리 고정 비번
    tele_id      VARCHAR(15)  NOT NULL UNIQUE, -- 묵시적 식별자 (전화번호)
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- 2. 상담사 계정 테이블
CREATE TABLE counselors (
    id           BIGSERIAL    PRIMARY KEY,
    login_id     VARCHAR(50)  NOT NULL UNIQUE,
    password     VARCHAR(255) NOT NULL, -- 해싱된 비밀번호용
    name         VARCHAR(50)  NOT NULL,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- 3. 환자 상세 정보 (환자 정보 테이블)
-- users의 tele_id를 참조하여 확장 정보를 관리
CREATE TABLE patient_profiles (
    user_tele_id         VARCHAR(15)  PRIMARY KEY REFERENCES users(tele_id) ON DELETE CASCADE,
    age                  SMALLINT     CHECK (age >= 0),
    gender               CHAR(1)      CHECK (gender IN ('M', 'F')),
    last_consulted_at    TIMESTAMP,   -- 최근 상담 날짜
    created_at           TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- 4. 상담 예약 정보
CREATE TABLE reserve (
    id               BIGSERIAL    PRIMARY KEY,
    user_tele_id     VARCHAR(15)  NOT NULL REFERENCES users(tele_id) ON DELETE CASCADE,
    appointment_at   TIMESTAMP    NOT NULL,
    counselor_name   VARCHAR(50)  NOT NULL,
    created_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- 5. 상담 세션 (json 파일 단위)
CREATE TABLE session (
    id               BIGSERIAL    PRIMARY KEY,
    user_tele_id     VARCHAR(15)  NOT NULL REFERENCES users(tele_id) ON DELETE CASCADE,
    raw_filename     VARCHAR(255),
    created_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- 6. 대화 원문 로그
CREATE TABLE qa_log (
    id               BIGSERIAL    PRIMARY KEY,
    session_id       BIGINT       NOT NULL REFERENCES session(id) ON DELETE CASCADE,
    type             CHAR(1)      NOT NULL CHECK (type IN ('Q', 'A')),
    text             TEXT         NOT NULL,
    order_index      INT          NOT NULL,
    UNIQUE (session_id, order_index, type)
);

-- 7. 명사 (imagine 객체 단위)
CREATE TABLE noun (
    id               BIGSERIAL    PRIMARY KEY,
    session_id       BIGINT       NOT NULL REFERENCES session(id) ON DELETE CASCADE,
    value            VARCHAR(100) NOT NULL,
    target_noun      VARCHAR(100),
    is_base_noun     BOOLEAN      NOT NULL DEFAULT FALSE
);

-- 8. 형용사 (noun 참조)
CREATE TABLE adjective (
    id               BIGSERIAL    PRIMARY KEY,
    noun_id          BIGINT       NOT NULL REFERENCES noun(id) ON DELETE CASCADE,
    value            VARCHAR(100) NOT NULL
);

-- 9. 동사 (noun 참조)
CREATE TABLE verb (
    id               BIGSERIAL    PRIMARY KEY,
    noun_id          BIGINT       NOT NULL REFERENCES noun(id) ON DELETE CASCADE,
    value            VARCHAR(100) NOT NULL
);

-- 10. 생성 이미지 앨범
CREATE TABLE album (
    id               BIGSERIAL    PRIMARY KEY,
    session_id       BIGINT       NOT NULL REFERENCES session(id) ON DELETE CASCADE,
    image_url        TEXT         NOT NULL,
    prompt           TEXT,
    created_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ── 인덱스 최적화 ───────────────────────────────────────────────
CREATE INDEX idx_session_user_tele    ON session(user_tele_id);
CREATE INDEX idx_reserve_user_tele    ON reserve(user_tele_id);
CREATE INDEX idx_qa_session           ON qa_log(session_id, order_index);
CREATE INDEX idx_noun_session         ON noun(session_id);
CREATE INDEX idx_adj_noun             ON adjective(noun_id);
CREATE INDEX idx_verb_noun            ON verb(noun_id);