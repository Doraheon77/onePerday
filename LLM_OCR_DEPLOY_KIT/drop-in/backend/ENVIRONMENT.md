# Backend Environment Variables

`backend/.env`에 아래 값을 설정하면 챗봇 RAG, 라벨 인식, 과다섭취/병용금기 API를 실행할 수 있습니다.

```env
PORT=3000

# Supabase / Prisma
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DATABASE"
DIRECT_URL="postgresql://USER:PASSWORD@HOST:PORT/DATABASE"
SUPABASE_URL="https://your-project.supabase.co"
SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"

# 공공데이터포털 DUR 병용금기 API
DUR_API_KEY="your-dur-api-key"

# Gemini LLM
GEMINI_API_KEY="your-gemini-api-key"
GEMINI_MODEL="gemini-3.5-flash"

# CLOVA OCR
CLOVA_OCR_INVOKE_URL="https://your-clova-ocr-invoke-url"
CLOVA_OCR_SECRET="your-clova-ocr-secret"

# YOLO 라벨 crop
# 기본값은 C:\OPD\onePerday-Feature-YOLO-SJ\weights\best.pt 입니다.
YOLO_MODEL_PATH="C:\\OPD\\onePerday-Feature-YOLO-SJ\\weights\\best.pt"
PYTHON_BIN="python"
YOLO_CONF=0.35
YOLO_CROP_PADDING=0.06
```

프론트엔드에서 백엔드 주소를 바꾸려면 Flutter 실행 시 다음 값을 지정합니다.

```bash
flutter run --dart-define=API_BASE_URL=http://<PC-IP>:3000
```

Android 에뮬레이터에서는 기본값 `http://10.0.2.2:3000`을 사용합니다.

YOLO crop 스크립트는 Python에서 실행되므로 서버 환경에 아래 패키지가 필요합니다.

```bash
pip install -r backend/scripts/requirements.txt
```
