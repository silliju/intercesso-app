# Intercesso App Design Plan

## Brand Identity
- **App Name**: Intercesso (중보기도 & 감사일기 앱)
- **Primary Color**: #2563EB (Deep Blue - 신뢰, 영성)
- **Accent Color**: #F59E0B (Warm Amber - 감사, 따뜻함)
- **Background**: #F8FAFF (Very Light Blue-White)
- **Surface**: #FFFFFF (White cards)
- **Text Primary**: #1E293B (Deep Slate)
- **Text Secondary**: #64748B (Muted Slate)
- **Success**: #10B981 (Emerald)

## Screen List

1. **Home (홈)** - 오늘의 말씀, 기도/감사 버튼, 피드 탭 (기도/감사)
2. **Prayer (기도)** - 기도 제목 목록, 기도 작성
3. **Intercession (중보)** - 중보기도 요청 목록, 중보 참여
4. **Gratitude (감사)** - 감사일기 목록, 감사 작성
5. **Group (그룹)** - 기도 그룹 목록, 그룹 참여

## Primary Content and Functionality

### Home Screen
- **Header**: 앱 로고 + "My" 프로필 버튼 + 알림 벨 아이콘
- **오늘의 말씀 카드**: 성경 구절 + 출처 (아이콘 포함, 고급스러운 카드 디자인)
- **액션 버튼 2개**: 
  - "기도 제목 쓰기" (파란색, 연필 아이콘)
  - "감사일기 쓰기" (황색, 꽃 아이콘)
- **피드 탭**: "기도 피드" / "감사 피드" 토글
- **피드 카드**: 사용자 아바타 + 이름 + 기도/감사 내용 리스트

### Prayer Screen
- 기도 제목 목록 (카드 형태)
- 기도 작성 버튼 (FAB)
- 기도 상태 표시 (응답됨/진행중)

### Intercession Screen
- 중보기도 요청 목록
- 중보 참여 버튼
- 기도 횟수 표시

### Gratitude Screen
- 감사일기 목록 (날짜별)
- 감사 작성 버튼 (FAB)
- 감사 내용 미리보기

### Group Screen
- 그룹 목록 카드
- 그룹 참여/생성 버튼
- 그룹 멤버 수 표시

## Key User Flows

1. **기도 제목 작성**: 홈 → "기도 제목 쓰기" 탭 → 제목 입력 → 저장
2. **감사일기 작성**: 홈 → "감사일기 쓰기" 탭 → 내용 입력 → 저장
3. **피드 보기**: 홈 → 기도/감사 피드 탭 전환 → 전체보기
4. **중보기도 참여**: 중보 탭 → 요청 선택 → 기도 버튼 탭

## Color Choices

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| primary | #2563EB | #3B82F6 | 기도 버튼, 강조 |
| accent | #F59E0B | #FBBF24 | 감사 버튼, 하이라이트 |
| background | #F8FAFF | #0F172A | 화면 배경 |
| surface | #FFFFFF | #1E293B | 카드 배경 |
| foreground | #1E293B | #F1F5F9 | 주요 텍스트 |
| muted | #64748B | #94A3B8 | 보조 텍스트 |
| border | #E2E8F0 | #334155 | 구분선 |

## Design Principles

- **iOS HIG 준수**: SF Symbols 스타일 아이콘, 네이티브 느낌의 탭바
- **카드 기반 레이아웃**: 둥근 모서리(16px), 미묘한 그림자
- **타이포그래피**: 제목 Bold, 본문 Regular, 충분한 줄간격
- **여백**: 16px 기본 패딩, 카드 간 12px 간격
- **색상 대비**: 접근성 AA 기준 준수

---

## 검토 노트 (가이드 vs 구현 정합성)

### 색상 불일치
| 항목 | 가이드 | theme.dart 현재값 | 제안 |
|------|--------|------------------|------|
| Primary | #2563EB | #2F6FED | 가이드에 맞추려면 theme 수정 또는 가이드를 "대표 Primary"로 통일 |
| Background | #F8FAFF | #F4F6FB | 가이드 쪽이 더 밝음. 통일 권장 |
| Text Secondary | #64748B | #6B7C93 | 유사하나 가이드 값으로 통일 시 일관성 확보 |
| Accent / 감사 | #F59E0B | #F59E08 | 거의 동일, 유지 가능 |

### 라운드/간격
- 가이드: 카드 **16px** 라운드, 16px 패딩, 카드 간 **12px**.
- 구현: 버튼/인풋 **12px**, 카드 **14~18px** 혼용. → 카드만 16px로 고정하면 가이드와 일치.

### 문서 보완 제안
- **찬양대(Choir)**: 앱에 찬양대 기능이 있으므로 Screen List 또는 "마이페이지 하위"로 명시.
- **에러/경고 색**: 가이드에 Success만 있음. Error(#EF4444), Warning 명시 시 접근성·일관성 좋아짐.
- **다크 모드**: Color 테이블에 Dark 값 있음. "다크 테마 적용 정책(언제 활성화할지)" 한 줄 추가 권장.
- **타이포 스케일**: "제목 Bold, 본문 Regular" 외에 폰트 크기 스케일(예: 24/18/15/13) 정의 시 유지보수에 유리.
