## 프로젝트 소개
치매 어르신 상담 내용을 STT로 추출하여
형태소 분석 후 AI 이미지를 생성하는 시스템의 DB

## 기술 스택
- PostgreSQL 17

## 테이블 구조
- users     : 어르신 정보
- session   : 상담 세션 (json 파일 하나당 1개)
- qa_log    : Q&A 원문 전체 보존
- noun      : 추출된 명사 (imagine 객체)
- adjective : 명사의 형용사
- verb      : 명사의 동사
- album     : DALL-E 생성 이미지
