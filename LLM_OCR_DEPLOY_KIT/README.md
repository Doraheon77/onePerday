# OnePerDay LLM 챗봇 + YOLO OCR 연동 키트

이 키트는 기존 onePerDay 코드베이스에 그대로 복사해서 적용할 수 있도록 만든 배포용 drop-in 패키지입니다.

## 포함 기능

- LLM 챗봇
  - Gemini 3.5 Flash 기준 프롬프트 엔지니어링
  - PostgreSQL `supplements` DB 기반 RAG 답변
  - 답변은 RAG 검색 결과 안의 DB 제품/필드로만 제한
  - RAG 검색 결과가 없거나 근거 필드가 부족하면 답변 거절
  - 사용자 건강 정보, 질환, 알러지, 현재 복용 영양제를 프롬프트에 포함
  - 알러지/질환과 충돌 가능성이 있는 DB 제품은 추천 후보에서 제외

- 영양제 라벨 자동 인식
  - YOLO `best.pt`로 라벨 영역 crop
  - CLOVA OCR API로 crop 이미지 텍스트 추출
  - Gemini API로 OCR 텍스트 구조화
  - PostgreSQL DB에서 제품명 TOP 1 매칭
  - Flutter 라벨 촬영 화면에 자동 입력

## 적용 방법

기존 프로젝트 루트에서 아래 명령을 실행하면 `drop-in` 안의 파일들이 동일 경로로 복사됩니다.

```powershell
Copy-Item -Path .\LLM_OCR_DEPLOY_KIT\drop-in\* -Destination . -Recurse -Force
```

또는 키트 스크립트를 사용할 수 있습니다.

```powershell
.\LLM_OCR_DEPLOY_KIT\apply-kit.ps1
```

수동으로 붙여넣는 경우에도 `drop-in` 폴더 안의 경로 구조를 그대로 따라가면 됩니다.

## 적용 후 필수 설정

백엔드 `.env`에 다음 값을 설정합니다.

```env
PORT=3000

DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DATABASE"
DIRECT_URL="postgresql://USER:PASSWORD@HOST:PORT/DATABASE"
SUPABASE_URL="https://your-project.supabase.co"
SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"

DUR_API_KEY="your-dur-api-key"

GEMINI_API_KEY="your-gemini-api-key"
GEMINI_MODEL="gemini-3.5-flash"

CLOVA_OCR_INVOKE_URL="https://your-clova-ocr-invoke-url"
CLOVA_OCR_SECRET="your-clova-ocr-secret"

YOLO_MODEL_PATH="C:\\OPD\\onePerday-Feature-YOLO-SJ\\weights\\best.pt"
PYTHON_BIN="python"
YOLO_CONF=0.35
YOLO_CROP_PADDING=0.06
```

프론트엔드 백엔드 주소는 기본값이 Android 에뮬레이터용 `http://10.0.2.2:3000`입니다. 실제 기기 또는 배포 서버에서는 다음처럼 지정합니다.

```bash
flutter run --dart-define=API_BASE_URL=http://<BACKEND_HOST>:3000
```

## 의존성 설치

백엔드:

```bash
cd backend
npm ci
```

YOLO crop Python 런타임:

```bash
pip install -r backend/scripts/requirements.txt
```

프론트엔드:

```bash
cd frontend
flutter pub get
```

## 추가되는 API

### `POST /chatbot/message`

DB 기반 RAG 챗봇 응답을 생성합니다.

```json
{
  "message": "비타민D 추천해줘",
  "userProfile": {
    "age": 24,
    "gender": "여성",
    "healthConditions": ["신장 질환"],
    "allergies": ["생선"]
  },
  "currentSupplements": []
}
```

### `POST /label-recognition/analyze`

multipart form-data로 `image` 파일을 업로드합니다.

응답에는 YOLO confidence, OCR 텍스트, Gemini 구조화 결과, DB TOP 1 매칭 결과가 포함됩니다.

## 적용 후 확인 순서

1. `backend/.env` 값 설정
2. `YOLO_MODEL_PATH`가 실제 `best.pt`를 가리키는지 확인
3. Python에서 `ultralytics`, `Pillow` 설치 확인
4. `npm run build`로 백엔드 컴파일 확인
5. `flutter analyze`로 프론트 정적 분석 확인
6. 챗봇 화면에서 질문 전송
7. 내 영양제 추가 화면에서 라벨 촬영 또는 갤러리 업로드

## 배포 주의사항

- `SUPABASE_SERVICE_ROLE_KEY`, `GEMINI_API_KEY`, `CLOVA_OCR_SECRET`은 프론트엔드에 넣지 않습니다.
- YOLO `.pt` 파일은 서버 파일시스템 또는 모델 저장소에 배치하고 `YOLO_MODEL_PATH`로 지정합니다.
- 라벨 인식 API는 이미지 파일을 처리하므로 업로드 용량, 임시 파일 삭제, 로그 내 개인정보 노출을 점검해야 합니다.
- 현재 키트는 NestJS 백엔드가 Python 스크립트를 subprocess로 호출하는 방식입니다. 트래픽이 늘면 Python 추론 서버를 별도로 분리하는 구성이 더 안정적입니다.
