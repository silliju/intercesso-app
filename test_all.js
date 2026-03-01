/**
 * Intercesso 전체 기능 TC 자동 테스트
 * 실행: node test_all.js
 */
require('dotenv').config({ path: './backend/.env' });
const http = require('http');

const BASE = 'http://localhost:3000/api';
let passed = 0, failed = 0, warned = 0;
const results = [];

// ── HTTP 헬퍼 ──────────────────────────────────────────
function req(method, path, body, token) {
  return new Promise((resolve) => {
    const data = body ? JSON.stringify(body) : undefined;
    const opts = {
      hostname: 'localhost', port: 3000,
      path: '/api' + path, method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: 'Bearer ' + token } : {}),
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    };
    const r = http.request(opts, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(d) }); }
        catch { resolve({ status: res.statusCode, body: d }); }
      });
    });
    r.on('error', (e) => resolve({ status: 0, body: { error: e.message } }));
    if (data) r.write(data);
    r.end();
  });
}

const post = (p, b, t) => req('POST', p, b, t);
const get  = (p, t)    => req('GET',  p, null, t);
const put  = (p, b, t) => req('PUT',  p, b, t);
const del  = (p, t)    => req('DELETE', p, null, t);

// ── 결과 기록 ──────────────────────────────────────────
function record(id, name, ok, detail = '', warn = false) {
  const icon = ok ? '✅' : (warn ? '⚠️' : '❌');
  const status = ok ? 'PASS' : (warn ? 'WARN' : 'FAIL');
  results.push({ id, name, status, detail });
  if (ok) passed++;
  else if (warn) warned++;
  else failed++;
  console.log(`${icon} [${id}] ${name}${detail ? ' → ' + detail : ''}`);
}

// ═══════════════════════════════════════════════════════
//  테스트 데이터 저장소
// ═══════════════════════════════════════════════════════
let T = {}; // tokens
let U = {}; // user ids
let P = {}; // prayer ids
let G = {}; // group ids
let IC= {}; // intercession ids
let C = {}; // comment ids

// ═══════════════════════════════════════════════════════
//  TC-01~05: 인증
// ═══════════════════════════════════════════════════════
async function testAuth() {
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📋 [인증 테스트]');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // TC-01: 회원가입 (3명)
  const users = [
    { email: 'user_a@test.com', password: 'Test1234!', nickname: '테스트A', church: '테스트교회' },
    { email: 'user_b@test.com', password: 'Test1234!', nickname: '테스트B', church: '믿음교회' },
    { email: 'user_c@test.com', password: 'Test1234!', nickname: '테스트C', church: '소망교회' },
  ];
  for (const u of users) {
    const r = await post('/auth/register', u);
    const ok = r.status === 201 && r.body.success;
    record('TC-01', `회원가입 (${u.nickname})`, ok, ok ? `ID: ${r.body.data?.user?.id?.substring(0,8)}` : r.body.message);
    if (ok) {
      const key = u.nickname.replace('테스트','u');
      T[key] = r.body.data?.token;
      U[key] = r.body.data?.user?.id;
    }
  }

  // TC-02: 중복 이메일 가입 차단
  const r02 = await post('/auth/register', { email: 'user_a@test.com', password: 'Test1234!', nickname: '중복' });
  record('TC-02', '중복 이메일 가입 차단', !r02.body.success, r02.body.message);

  // TC-03: 로그인 성공
  const r03 = await post('/auth/login', { email: 'user_a@test.com', password: 'Test1234!' });
  const loginOk = r03.status === 200 && r03.body.success && r03.body.data?.token;
  record('TC-03', '로그인 성공', loginOk, loginOk ? '토큰 발급됨' : r03.body.message);
  if (loginOk) T['uA'] = r03.body.data.token; // 갱신

  // TC-04: 잘못된 비밀번호 로그인 차단
  const r04 = await post('/auth/login', { email: 'user_a@test.com', password: 'WrongPass!' });
  record('TC-04', '잘못된 비밀번호 차단', r04.status === 401 && !r04.body.success, r04.body.message);

  // TC-05: 내 정보 조회 (/users/me)
  const r05 = await get('/users/me', T['uA']);
  const meOk = r05.status === 200 && r05.body.data?.id === U['uA'];
  record('TC-05', '내 정보 조회 (me)', meOk, meOk ? `닉네임: ${r05.body.data.nickname}` : r05.body.message);

  // TC-05b: 프로필 수정
  const r05b = await put('/users/me', { nickname: '테스트A수정', church_name: '수정교회', bio: '소개글' }, T['uA']);
  const profOk = r05b.status === 200 && r05b.body.success;
  record('TC-05b', '프로필 수정', profOk, profOk ? '닉네임/교회/소개 수정 성공' : r05b.body.message);

  // TC-05c: 토큰 없이 보호 API 접근 차단
  const r05c = await get('/users/me', null);
  record('TC-05c', '인증 없이 접근 차단', r05c.status === 401, `HTTP ${r05c.status}`);
}

// ═══════════════════════════════════════════════════════
//  TC-06~10: 기도 CRUD
// ═══════════════════════════════════════════════════════
async function testPrayers() {
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📋 [기도 CRUD 테스트]');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // TC-06: 기도 작성 (여러 조건)
  const pList = [
    { title: '건강을 위한 기도', content: '몸의 치유를 구합니다', category: '건강', scope: 'public', token: T['uA'], key: 'p1' },
    { title: '진로 기도', content: '취업을 위해 기도합니다', category: '진로', scope: 'friends', token: T['uA'], key: 'p2' },
    { title: 'B의 가정 기도', content: '가정 화목을 구합니다', category: '가정', scope: 'public', token: T['uB'], key: 'p3' },
    { title: '비공개 기도', content: '비밀 내용', category: '영적', scope: 'private', token: T['uA'], key: 'p4' },
  ];
  for (const p of pList) {
    const r = await post('/prayers', { title: p.title, content: p.content, category: p.category, scope: p.scope }, p.token);
    const ok = (r.status === 201 || r.status === 200) && r.body.success;
    P[p.key] = r.body.data?.id || r.body.data?.prayer?.id;
    record('TC-06', `기도 작성 (${p.key}: ${p.title.substring(0,10)})`, ok, ok ? `ID: ${P[p.key]?.substring(0,8)}` : r.body.message);
  }

  // TC-07: 기도 목록 조회 (public)
  const r07 = await get('/prayers?scope=public&limit=10', T['uA']);
  const listOk = r07.status === 200 && r07.body.success;
  const prayers = listOk ? (Array.isArray(r07.body.data) ? r07.body.data : (r07.body.data?.prayers || [])) : [];
  record('TC-07', '공개 기도 목록 조회', listOk, `공개 기도 ${prayers.length}건`);

  // TC-07b: 비공개 기도가 목록에 미포함 확인
  const hasPrivate = prayers.some(p => p.scope === 'private');
  record('TC-07b', '비공개 기도 목록 미포함', !hasPrivate, hasPrivate ? '비공개 기도가 노출됨!' : '비공개 필터링 정상');

  // TC-08: 기도 상세 조회
  if (P.p1) {
    const r08 = await get(`/prayers/${P.p1}`, T['uA']);
    const ok = r08.status === 200 && r08.body.data?.id === P.p1;
    record('TC-08', '기도 상세 조회', ok, ok ? `제목: ${r08.body.data.title}` : r08.body.message);
  }

  // TC-09: 기도 수정 (본인)
  if (P.p1) {
    const r09 = await put(`/prayers/${P.p1}`, { title: '수정된 건강 기도', content: '수정된 내용입니다', scope: 'public' }, T['uA']);
    const ok = r09.status === 200 && r09.body.success;
    record('TC-09', '기도 수정 (본인)', ok, ok ? '수정 성공' : r09.body.message);
  }

  // TC-09b: 타인 기도 수정 차단
  if (P.p3) {
    const r09b = await put(`/prayers/${P.p3}`, { title: '타인 수정 시도', content: '해킹' }, T['uA']);
    record('TC-09b', '타인 기도 수정 차단', r09b.status === 403 || !r09b.body.success, r09b.body.message);
  }

  // TC-10: 기도 상태 변경 (praying → answered)
  if (P.p1) {
    const r10 = await put(`/prayers/${P.p1}/status`, { status: 'answered' }, T['uA']);
    const ok = r10.status === 200 && r10.body.success;
    record('TC-10', '기도 상태 변경 (answered)', ok, ok ? '상태 변경 성공' : r10.body.message);
    // 다시 praying으로 원복
    await put(`/prayers/${P.p1}/status`, { status: 'praying' }, T['uA']);
  }

  // TC-10b: 내 기도 목록 조회
  const r10b = await get('/prayers?scope=mine&limit=20', T['uA']);
  const mineOk = r10b.status === 200 && r10b.body.success;
  const minePrayers = mineOk ? (Array.isArray(r10b.body.data) ? r10b.body.data : (r10b.body.data?.prayers || r10b.body.data?.data || [])) : [];
  record('TC-10b', '내 기도 목록 조회', mineOk, `내 기도 ${minePrayers.length}건`);
}

// ═══════════════════════════════════════════════════════
//  TC-11~14: 댓글/참여/기도응답
// ═══════════════════════════════════════════════════════
async function testCommentsAndMore() {
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📋 [댓글/참여/기도응답 테스트]');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // TC-11: 댓글 작성
  if (P.p1) {
    const r11 = await post(`/prayers/${P.p1}/comments`, { content: '함께 기도합니다 🙏' }, T['uB']);
    const ok = (r11.status === 201 || r11.status === 200) && r11.body.success;
    C.c1 = r11.body.data?.id;
    record('TC-11', '댓글 작성', ok, ok ? `댓글ID: ${C.c1?.substring(0,8)}` : r11.body.message);
  }

  // TC-11b: 댓글 포함 기도 상세 조회 (created_at 확인)
  if (P.p1) {
    const r11b = await get(`/prayers/${P.p1}`, T['uA']);
    const comments = r11b.body.data?.comments || [];
    const hasTime = comments.length > 0 && comments[0].created_at;
    record('TC-11b', '댓글 created_at 포함 여부', hasTime, hasTime ? `일시: ${comments[0].created_at}` : '댓글에 created_at 없음');
  }

  // TC-12: 댓글 삭제 (본인)
  if (P.p1 && C.c1) {
    const r12 = await del(`/prayers/${P.p1}/comments/${C.c1}`, T['uB']);
    const ok = r12.status === 200 && r12.body.success;
    record('TC-12', '댓글 삭제 (본인)', ok, ok ? '삭제 성공' : r12.body.message);
  }

  // TC-13: 함께 기도 (참여)
  if (P.p3) {
    const r13 = await post(`/prayers/${P.p3}/participate`, {}, T['uA']);
    const ok = (r13.status === 200 || r13.status === 201) && r13.body.success;
    record('TC-13', '함께 기도 참여', ok, ok ? '참여 성공' : r13.body.message);
  }

  // TC-13b: 중복 참여 차단
  if (P.p3) {
    const r13b = await post(`/prayers/${P.p3}/participate`, {}, T['uA']);
    const blocked = !r13b.body.success || r13b.status === 409;
    record('TC-13b', '중복 참여 차단', blocked, r13b.body.message || r13b.body.error?.code);
  }

  // TC-13c: 참여 취소
  if (P.p3) {
    const r13c = await del(`/prayers/${P.p3}/participate`, T['uA']);
    const ok = r13c.status === 200 && r13c.body.success;
    record('TC-13c', '함께 기도 참여 취소', ok, ok ? '취소 성공' : r13c.body.message);
  }

  // TC-14: 기도 응답 등록
  if (P.p2) {
    const r14 = await post(`/prayers/${P.p2}/answer`, { content: '취업이 되었습니다! 하나님 감사합니다 🙌', scope: 'public' }, T['uA']);
    const ok = (r14.status === 201 || r14.status === 200) && r14.body.success;
    record('TC-14', '기도 응답 등록', ok, ok ? '응답 등록 성공' : r14.body.message);
  }

  // TC-14b: 응답 댓글 작성
  if (P.p2) {
    const detail = await get(`/prayers/${P.p2}`, T['uA']);
    const answerId = detail.body.data?.answer?.id;
    if (answerId) {
      const r14b = await post(`/prayers/${P.p2}/answer/comments`, { content: '축하드려요! 🎉' }, T['uB']);
      const ok = (r14b.status === 200 || r14b.status === 201) && r14b.body.success;
      record('TC-14b', '응답 댓글 작성', ok, ok ? '응답 댓글 성공' : r14b.body.message);
    } else {
      record('TC-14b', '응답 댓글 작성', false, '응답 ID 없음', true);
    }
  }
}

// ═══════════════════════════════════════════════════════
//  TC-15~19: 중보기도
// ═══════════════════════════════════════════════════════
async function testIntercession() {
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📋 [중보기도 테스트]');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // TC-15: 전체 공개 중보기도 요청
  if (P.p1) {
    const r15 = await post('/intercessions', { prayer_id: P.p1, target_type: 'public', recipient_id: U['uA'], message: '기도 부탁드려요' }, T['uA']);
    const ok = (r15.status === 201 || r15.status === 200) && r15.body.success;
    record('TC-15', '전체 공개 중보기도 요청', ok, ok ? `요청ID: ${r15.body.data?.id?.substring(0,8)}` : r15.body.message);
  }

  // TC-16: 개인 중보기도 요청 (A→B)
  if (P.p1) {
    const r16 = await post('/intercessions', { prayer_id: P.p1, target_type: 'individual', recipient_id: U['uB'], message: '친구여 기도해줘요' }, T['uA']);
    const ok = (r16.status === 201 || r16.status === 200) && r16.body.success;
    IC.ic1 = r16.body.data?.id;
    record('TC-16', '개인 중보기도 요청 (A→B)', ok, ok ? `요청ID: ${IC.ic1?.substring(0,8)}` : r16.body.message);
  }

  // TC-16b: 개인 중보기도 요청 (A→C 도 동시에)
  if (P.p1) {
    const r16b = await post('/intercessions', { prayer_id: P.p1, target_type: 'individual', recipient_id: U['uC'], message: 'C에게도 요청' }, T['uA']);
    const ok = (r16b.status === 201 || r16b.status === 200) && r16b.body.success;
    record('TC-16b', '개인 중보기도 다중 요청 (A→C)', ok, ok ? '다중 요청 성공' : r16b.body.message);
  }

  // TC-17: 중복 요청 차단 (A→B 재요청)
  if (P.p1) {
    const r17 = await post('/intercessions', { prayer_id: P.p1, target_type: 'individual', recipient_id: U['uB'], message: '중복 요청' }, T['uA']);
    const blocked = r17.status === 409 && !r17.body.success;
    record('TC-17', '중복 중보기도 요청 차단', blocked, r17.body.message);
  }

  // TC-18: 받은 요청 목록 조회 (B가 받은 요청)
  const r18 = await get('/intercessions/received', T['uB']);
  const recvOk = r18.status === 200 && r18.body.success;
  const recvItems = recvOk ? (Array.isArray(r18.body.data) ? r18.body.data : []) : [];
  record('TC-18', '받은 중보기도 요청 목록', recvOk, `${recvItems.length}건 수신`);

  // TC-18b: 보낸 요청 목록 조회 (A가 보낸 요청)
  const r18b = await get('/intercessions/sent', T['uA']);
  const sentOk = r18b.status === 200 && r18b.body.success;
  const sentItems = sentOk ? (Array.isArray(r18b.body.data) ? r18b.body.data : []) : [];
  record('TC-18b', '보낸 중보기도 요청 목록', sentOk, `${sentItems.length}건 발송`);

  // TC-18c: 전체 공개 목록 조회
  const r18c = await get('/intercessions/public', null);
  const pubOk = r18c.status === 200 && r18c.body.success;
  record('TC-18c', '전체 공개 중보기도 목록', pubOk, pubOk ? `${(Array.isArray(r18c.body.data)?r18c.body.data:[]).length}건` : r18c.body.message);

  // TC-19: 중보기도 수락 (B가 수락)
  if (IC.ic1) {
    const r19 = await put(`/intercessions/${IC.ic1}/respond`, { status: 'accepted' }, T['uB']);
    const ok = r19.status === 200 && r19.body.success;
    record('TC-19', '중보기도 수락', ok, ok ? '수락 성공' : r19.body.message);
  }

  // TC-19b: 중보기도 거절 (C가 거절) - C에게 보낸 요청 ID 찾기
  const sentList = await get('/intercessions/sent', T['uA']);
  const cReq = (Array.isArray(sentList.body.data) ? sentList.body.data : []).find(r => r.recipient_id === U['uC']);
  if (cReq) {
    const r19b = await put(`/intercessions/${cReq.id}/respond`, { status: 'rejected' }, T['uC']);
    const ok = r19b.status === 200 && r19b.body.success;
    record('TC-19b', '중보기도 거절', ok, ok ? '거절 성공' : r19b.body.message);
  }

  // TC-19c: 사용자 검색 (중보기도)
  const r19c = await get('/intercessions/search-users?q=테스트', T['uA']);
  const searchOk = r19c.status === 200 && r19c.body.success;
  const searchUsers = Array.isArray(r19c.body.data) ? r19c.body.data : [];
  record('TC-19c', '중보기도 사용자 검색', searchOk, `"테스트" 검색 → ${searchUsers.length}명`);
}

// ═══════════════════════════════════════════════════════
//  TC-20~23: 그룹
// ═══════════════════════════════════════════════════════
async function testGroups() {
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📋 [그룹 테스트]');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // TC-20: 그룹 생성
  const r20 = await post('/groups', { name: '테스트 기도 모임', description: '함께 기도하는 모임', group_type: 'public' }, T['uA']);
  const ok20 = (r20.status === 201 || r20.status === 200) && r20.body.success;
  G.g1 = r20.body.data?.id || r20.body.data?.group?.id;
  record('TC-20', '그룹 생성', ok20, ok20 ? `그룹ID: ${G.g1?.substring(0,8)}` : r20.body.message);

  // TC-21: 그룹 목록 조회
  const r21 = await get('/groups', T['uA']);
  const listOk = r21.status === 200 && r21.body.success;
  const groups = listOk ? (Array.isArray(r21.body.data) ? r21.body.data : (r21.body.data?.groups || [])) : [];
  record('TC-21', '그룹 목록 조회', listOk, `${groups.length}개 그룹`);

  // TC-22: 그룹 가입 (B가 가입)
  if (G.g1) {
    const r22 = await post(`/groups/${G.g1}/join`, {}, T['uB']);
    const ok = (r22.status === 200 || r22.status === 201) && r22.body.success;
    record('TC-22', '그룹 가입 (B)', ok, ok ? '가입 성공' : r22.body.message);
  }

  // TC-22b: 중복 가입 차단
  if (G.g1) {
    const r22b = await post(`/groups/${G.g1}/join`, {}, T['uB']);
    const blocked = !r22b.body.success;
    record('TC-22b', '중복 그룹 가입 차단', blocked, r22b.body.message);
  }

  // TC-22c: 그룹 상세 조회 (멤버 수 확인)
  if (G.g1) {
    const r22c = await get(`/groups/${G.g1}`, T['uA']);
    const ok = r22c.status === 200 && r22c.body.success;
    const memberCount = r22c.body.data?.member_count || r22c.body.data?.members?.length;
    record('TC-22c', '그룹 상세 조회 (멤버 수)', ok, ok ? `멤버 ${memberCount}명` : r22c.body.message);
  }

  // TC-23: 그룹 중보기도 요청
  if (G.g1 && P.p3) {
    const r23 = await post('/intercessions', { prayer_id: P.p3, target_type: 'group', group_id: G.g1, recipient_id: U['uB'], message: '그룹 기도 요청' }, T['uB']);
    const ok = (r23.status === 201 || r23.status === 200) && r23.body.success;
    record('TC-23', '그룹 중보기도 요청', ok, ok ? '그룹 요청 성공' : r23.body.message);
  }

  // TC-23b: 그룹 탈퇴 (B)
  if (G.g1) {
    const r23b = await del(`/groups/${G.g1}/leave`, T['uB']);
    const ok = r23b.status === 200 && r23b.body.success;
    record('TC-23b', '그룹 탈퇴 (B)', ok, ok ? '탈퇴 성공' : r23b.body.message);
  }
}

// ═══════════════════════════════════════════════════════
//  TC-24~26: 통계/알림/기타
// ═══════════════════════════════════════════════════════
async function testStatsAndMore() {
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📋 [통계/알림 테스트]');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // TC-24: 대시보드 통계 (내 기도 수 정확성)
  const r24 = await get('/statistics/dashboard', T['uA']);
  const statsOk = r24.status === 200 && r24.body.success;
  const stats = r24.body.data?.stats;
  const totalOk = statsOk && stats?.total_prayers >= 2; // A는 2개 이상 작성
  record('TC-24', '대시보드 통계 (내기도 수)', totalOk, statsOk ? `내기도: ${stats?.total_prayers}, 응답: ${stats?.answered_prayers}, 함께: ${stats?.total_participations}` : r24.body.message);

  // TC-24b: 연속 기도 일수 계산
  const streakOk = statsOk && typeof stats?.streak_days === 'number';
  record('TC-24b', '연속 기도 일수 계산', streakOk, streakOk ? `${stats?.streak_days}일` : '연속 일수 없음');

  // TC-25: 알림 목록 조회
  const r25 = await get('/notifications', T['uB']);
  const notifOk = r25.status === 200 && r25.body.success;
  const notifs = Array.isArray(r25.body.data) ? r25.body.data : (r25.body.data?.notifications || []);
  record('TC-25', '알림 목록 조회', notifOk, `${notifs.length}개 알림`);

  // TC-25b: 읽지 않은 알림 수 조회
  const r25b = await get('/notifications/unread-count', T['uB']);
  const unreadOk = r25b.status === 200 && r25b.body.success;
  record('TC-25b', '읽지 않은 알림 수', unreadOk, unreadOk ? `미읽음: ${r25b.body.data?.unread_count}` : r25b.body.message);

  // TC-26: 기도 삭제 (본인)
  if (P.p4) {
    const r26 = await del(`/prayers/${P.p4}`, T['uA']);
    const ok = r26.status === 200 && r26.body.success;
    record('TC-26', '기도 삭제 (본인)', ok, ok ? '삭제 성공' : r26.body.message);

    // TC-26b: 삭제된 기도 조회 차단
    const r26b = await get(`/prayers/${P.p4}`, T['uA']);
    const blocked = r26b.status === 404 || !r26b.body.success;
    record('TC-26b', '삭제된 기도 접근 차단', blocked, `HTTP ${r26b.status}`);
  }

  // TC-26c: 타인 기도 삭제 차단
  if (P.p3) {
    const r26c = await del(`/prayers/${P.p3}`, T['uA']);
    const blocked = r26c.status === 403 || !r26c.body.success;
    record('TC-26c', '타인 기도 삭제 차단', blocked, r26c.body.message || `HTTP ${r26c.status}`);
  }
}

// ═══════════════════════════════════════════════════════
//  메인 실행 + 결과 요약
// ═══════════════════════════════════════════════════════
async function main() {
  console.log('╔══════════════════════════════════════════╗');
  console.log('║   Intercesso 전체 기능 TC 자동 테스트     ║');
  console.log('╚══════════════════════════════════════════╝');
  console.log(`실행 시각: ${new Date().toLocaleString('ko-KR')}\n`);

  await testAuth();
  await testPrayers();
  await testCommentsAndMore();
  await testIntercession();
  await testGroups();
  await testStatsAndMore();

  // ── 최종 결과 출력 ──
  const total = passed + failed + warned;
  console.log('\n╔══════════════════════════════════════════╗');
  console.log('║             최종 테스트 결과               ║');
  console.log('╠══════════════════════════════════════════╣');
  console.log(`║  전체: ${String(total).padEnd(3)} | ✅PASS: ${String(passed).padEnd(3)} | ❌FAIL: ${String(failed).padEnd(3)} | ⚠️WARN: ${String(warned).padEnd(3)} ║`);
  console.log(`║  통과율: ${Math.round((passed/total)*100)}%${' '.repeat(33)}║`);
  console.log('╚══════════════════════════════════════════╝');

  if (failed > 0) {
    console.log('\n❌ 실패 목록:');
    results.filter(r => r.status === 'FAIL').forEach(r => {
      console.log(`   [${r.id}] ${r.name}: ${r.detail}`);
    });
  }
  if (warned > 0) {
    console.log('\n⚠️  경고 목록:');
    results.filter(r => r.status === 'WARN').forEach(r => {
      console.log(`   [${r.id}] ${r.name}: ${r.detail}`);
    });
  }

  return { total, passed, failed, warned, results };
}

main().catch(console.error);
