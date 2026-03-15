# 프로필 사진(아바타) Storage 버킷

마이페이지 프로필 수정 시 사진 업로드가 동작하려면 Supabase에 **public** 버킷이 필요합니다.

## 설정 방법

1. [Supabase 대시보드](https://supabase.com/dashboard) → 프로젝트 선택
2. **Storage** 메뉴 → **New bucket**
3. Name: `avatars`
4. **Public bucket**: 체크 (프로필 이미지 공개 URL 사용)
5. Create bucket

이미 있으면 그대로 사용하면 됩니다.

## 동작 방식

- 앱에서 프로필 사진 선택 시 이미지를 base64로 `PUT /api/users/me`에 전송
- 백엔드에서 base64를 디코딩해 Storage `avatars` 버킷에 `{userId}/{timestamp}.jpg` 경로로 업로드
- 업로드된 파일의 공개 URL을 `users.profile_image_url`에 저장
