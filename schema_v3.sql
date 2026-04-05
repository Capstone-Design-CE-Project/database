-- ============================================================
-- 치매 어르신 상담 앱 - DB 스키마 v3
-- PostgreSQL 16
-- 수정: noun 테이블에 형용사/동사 배열로 통합
-- ============================================================

-- ── 어르신 유저 ───────────────────────────────────────────────
CREATE TABLE users (
    id            BIGSERIAL    PRIMARY KEY,
    code          VARCHAR(20)  NOT NULL UNIQUE,              -- 고유코드 (예: "USR-0001")
    name          VARCHAR(50)  NOT NULL,
    birth_date    DATE,                                      -- 생년월일
    gender        CHAR(1)      CHECK (gender IN ('M', 'F')), -- M: 남성, F: 여성
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ── 상담 세션 ─────────────────────────────────────────────────
CREATE TABLE session (
    id              BIGSERIAL    PRIMARY KEY,
    user_id         BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    raw_filename    VARCHAR(255),                            -- 원본 json 파일명
    session_date    DATE         NOT NULL DEFAULT CURRENT_DATE,
    topic           VARCHAR(100),                            -- 상담 주제 (예: "어린시절", "고향")
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ── 대화 원문 (턴 단위로 Q&A 쌍 저장) ──────────────────────────
CREATE TABLE qa_log (
    id          BIGSERIAL   PRIMARY KEY,
    session_id  BIGINT      NOT NULL REFERENCES session(id) ON DELETE CASCADE,
    turn        INT         NOT NULL,                        -- 대화 턴 번호 (1, 2, 3...)
    question    TEXT        NOT NULL,                        -- 상담사 질문
    answer      TEXT,                                        -- 어르신 답변
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    UNIQUE (session_id, turn)
);

-- ── 명사 (이미지 요소 단위) ────────────────────────────────────
-- Python imagine 클래스와 1:1 매핑
CREATE TABLE noun (
    id            BIGSERIAL    PRIMARY KEY,
    session_id    BIGINT       NOT NULL REFERENCES session(id) ON DELETE CASCADE,
    value         VARCHAR(100) NOT NULL,                     -- 명사 (예: "개", "고양이")
    adjectives    TEXT[]       DEFAULT '{}',                 -- 형용사 배열 (예: {"하얀", "큰"})
    verbs         TEXT[]       DEFAULT '{}',                 -- 동사 배열 (예: {"뛰다", "짖다"})
    target        VARCHAR(100),                              -- 대상 명사 (배→등대)
    position      TEXT[]       DEFAULT '{}',                 -- 위치 배열 (예: {"왼쪽", "앞"})
    is_base       BOOLEAN      NOT NULL DEFAULT FALSE,       -- 기준(배경) 명사 여부
    source_turn   INT,                                       -- 추출된 턴 번호
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ── 생성된 이미지 앨범 ─────────────────────────────────────────
CREATE TABLE album (
    id          BIGSERIAL   PRIMARY KEY,
    session_id  BIGINT      NOT NULL REFERENCES session(id) ON DELETE CASCADE,
    image_url   TEXT        NOT NULL,                        -- 생성된 이미지 URL
    prompt      TEXT,                                        -- 사용된 프롬프트
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- ── 인덱스 ───────────────────────────────────────────────────
CREATE INDEX idx_users_code      ON users(code);
CREATE INDEX idx_session_user    ON session(user_id);
CREATE INDEX idx_session_date    ON session(session_date);
CREATE INDEX idx_qa_session      ON qa_log(session_id, turn);
CREATE INDEX idx_noun_session    ON noun(session_id);
CREATE INDEX idx_noun_value      ON noun(value);
CREATE INDEX idx_album_session   ON album(session_id);

-- ── 코멘트 ───────────────────────────────────────────────────
COMMENT ON TABLE users   IS '어르신 사용자 정보';
COMMENT ON TABLE session IS '상담 세션 - json 파일 하나당 1개';
COMMENT ON TABLE qa_log  IS 'Q&A 턴 단위 저장 (질문-답변 쌍)';
COMMENT ON TABLE noun    IS '추출된 명사 + 수식어(형용사/동사) - imagine 클래스 매핑';
COMMENT ON TABLE album   IS '생성된 이미지 저장';


-- ============================================================
-- 예시 데이터 (회상치료 상담 - 김순자 어르신)
-- ============================================================

-- 어르신 등록
INSERT INTO users (code, name, birth_date, gender) VALUES 
('USR-0001', '김순자', '1946-03-15', 'F');

-- 상담 세션
INSERT INTO session (user_id, raw_filename, topic) VALUES 
(1, 'session_20240401.json', '어린시절/고향');

-- 대화 원문 (턴 단위)
INSERT INTO qa_log (session_id, turn, question, answer) VALUES
(1, 1, '어르신, 오늘 날씨가 참 좋죠? 요즘 따뜻해지니까 어떠세요?', '응, 좋지. 이런 날이면... 뭔가 생각나는 것 같기도 하고.'),
(1, 2, '어떤 게 생각나세요? 천천히 말씀해 주셔도 돼요.', '음... 우리 고향. 논에 물 대던 때? 그때쯤이었나.'),
(1, 3, '아, 고향 논에 물 대시던 때요? 어르신 고향이 어디셨어요?', '충청도. 예산 쪽이야. 거기 우리 집이 있었어. 초가집.'),
(1, 4, '초가집이요! 지붕이 볏짚으로 된 집 말씀이시죠?', '그럼, 그럼. 가을 되면 아버지가 지붕 새로 올리셨어. 나는 밑에서 볏짚 날랐지. 냄새가... 볏짚 냄새가 좋았어.'),
(1, 5, '볏짚 냄새요. 어떤 냄새였는지 기억나세요?', '음... 햇볕 냄새? 따끈따끈하고, 고소한 거. 그 위에 누우면 잠이 솔솔 왔어.'),
(1, 6, '와, 볏짚 위에 누워서 낮잠도 주무셨어요?', '일하다 말고 누웠다가 어머니한테 혼났지. 이년아, 일 안 하고 뭐 하냐! 하시면서.'),
(1, 7, '어르신 어렸을 때 동네에서 뭐 하고 노셨어요?', '놀기는. 일했지, 일. 소 풀 먹이고, 동생 업고 다니고.'),
(1, 8, '소를 키우셨어요?', '누렁이. 우리 누렁이. 순했어, 그 소가. 내가 풀 뜯기러 가면 졸졸 따라왔어.'),
(1, 9, '누렁이라고 이름도 있었네요. 소가 어르신을 잘 따랐나 봐요.', '내가 제일 잘 다뤘어. 오빠들은 못 했는데, 나만 부르면 와.'),
(1, 10, '동네에 개울도 있었어요?', '있었지! 집 앞에. 여름에는 거기서 멱 감았어.'),
(1, 11, '개울에서 멱 감으셨구나. 물이 시원했겠어요.', '차가웠어, 엄청. 발 담그면 아이고! 소리 나오고. 근데 더우니까 들어가는 거야. 동네 애들이랑 물장구치고.'),
(1, 12, '친구들이랑 같이요?', '응. 복순이, 영희... 영희는 옆 마을 살았는데, 맨날 우리 동네로 왔어. 걔 엄마가 두부 만들어서 팔러 오거든.'),
(1, 13, '아, 두부 팔러 오시면 영희도 따라오고, 그러면 같이 놀았군요.', '그렇지. 두부 사러 줄 서 있으면 우리는 개울가서 놀고.'),
(1, 14, '어르신, 오늘 정말 좋은 이야기 많이 들려주셨어요. 초가집이랑 누렁이, 개울가 이야기.', '내가 그런 얘기 했어?'),
(1, 15, '네, 해주셨어요. 볏짚 냄새가 햇볕 냄새 같다고 하신 것도요.', '그랬구나. 오랜만에 생각났네, 그것들이.');

-- 명사 (형용사/동사 배열 포함)
INSERT INTO noun (session_id, value, adjectives, verbs, target, position, is_base, source_turn) VALUES
(1, '고향', '{}', '{}', NULL, '{}', TRUE, 2),
(1, '초가집', '{}', '{}', NULL, '{}', FALSE, 3),
(1, '볏짚', '{"따끈따끈한", "고소한"}', '{}', '초가집', '{"위"}', FALSE, 4),
(1, '아버지', '{}', '{"올리다"}', '지붕', '{}', FALSE, 4),
(1, '누렁이', '{"순한", "누런"}', '{"따라오다"}', NULL, '{}', FALSE, 8),
(1, '개울', '{"차가운"}', '{}', NULL, '{"집 앞"}', FALSE, 10),
(1, '동네 애들', '{}', '{"물장구치다"}', NULL, '{"개울"}', FALSE, 11),
(1, '영희', '{}', '{"오다"}', NULL, '{"옆 마을"}', FALSE, 12),
(1, '두부', '{}', '{"팔다"}', NULL, '{}', FALSE, 12);


-- ============================================================
-- 유용한 조회 쿼리 예시
-- ============================================================

-- 세션의 모든 명사와 수식어 조회
-- SELECT value, adjectives, verbs, target, position 
-- FROM noun 
-- WHERE session_id = 1;

-- 특정 명사의 형용사 펼쳐서 조회
-- SELECT value, unnest(adjectives) AS adj 
-- FROM noun 
-- WHERE session_id = 1;

-- 이미지 프롬프트 생성용 조회
-- SELECT 
--     value,
--     array_to_string(adjectives, ', ') AS adj_str,
--     array_to_string(verbs, ', ') AS verb_str,
--     target,
--     array_to_string(position, ', ') AS pos_str
-- FROM noun 
-- WHERE session_id = 1;
