# Kit Manifest

## Backend drop-in files

- `backend/src/app.module.ts`
- `backend/src/main.ts`
- `backend/src/supplement-search.service.ts`
- `backend/src/intake/dto/check-intake.dto.ts`
- `backend/src/intake/intake.service.ts`
- `backend/src/ai/ai.module.ts`
- `backend/src/ai/gemini.service.ts`
- `backend/src/chatbot/chatbot.controller.ts`
- `backend/src/chatbot/chatbot.module.ts`
- `backend/src/chatbot/chatbot.service.ts`
- `backend/src/chatbot/dto/chat-message.dto.ts`
- `backend/src/label-recognition/label-recognition.controller.ts`
- `backend/src/label-recognition/label-recognition.module.ts`
- `backend/src/label-recognition/label-recognition.service.ts`
- `backend/scripts/crop_label.py`
- `backend/scripts/requirements.txt`
- `backend/ENVIRONMENT.md`

## Frontend drop-in files

- `frontend/lib/services/api_config.dart`
- `frontend/lib/services/chatbot_api_service.dart`
- `frontend/lib/services/label_recognition_api_service.dart`
- `frontend/lib/services/intake_api_service.dart`
- `frontend/lib/features/chatbot/presentation/chatbot_screen.dart`
- `frontend/lib/features/cabinet/presentation/add_supplement_screen.dart`
- `frontend/pubspec.yaml`
- `frontend/pubspec.lock`

## Main integration points

- 챗봇 화면: `ChatbotApiService.sendMessage()`
- 라벨 촬영 화면: `LabelRecognitionApiService.analyze()`
- 백엔드 챗봇 API: `ChatbotModule`
- 백엔드 라벨 인식 API: `LabelRecognitionModule`
- Gemini 공통 호출: `GeminiService`
- YOLO crop: `backend/scripts/crop_label.py`
