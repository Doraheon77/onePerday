🌿 onePerday AI OCR Module
본 프로젝트의 AI 파트는 GLM-OCR (0.9B) 모델을 활용하여 카메라로 촬영한 영양제 라벨의 텍스트를 분석하고 구조화합니다. 0.9B 경량 모델의 한계를 극복하기 위해 전문 의학 용어 사전 주입(Vocabulary Injection) 기술이 적용되었습니다.

📂 파일 정보
경로: C:\onePerday\ai\ocr.py

주요 기능: 실시간 카메라 촬영, 영양제 라벨 OCR, 한/영 혼용 텍스트 추출, 오인식 자동 교정.

🛠 1. 개발 환경 설정 (Installation)
본 모듈은 GPU(CUDA) 가속 환경에서 최적의 성능을 발휘합니다. 아래 명령어를 순서대로 실행하여 환경을 구축하세요.

1-1. PyTorch 및 CUDA 연동 (v13.0 권장)
Bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130
1-2. 필수 라이브러리 설치
Bash
pip install "transformers>=4.46.0" "accelerate>=0.34.0" opencv-python pillow
🚀 2. 사용 방법 (Usage)
2-1. 단독 실행 및 테스트
카메라 작동 여부와 인식 성능을 즉시 확인하려면 스크립트를 직접 실행하세요.

Bash
python ai/ocr.py
Spacebar: 현재 화면 캡처 및 OCR 분석 시작

q: 카메라 종료 및 프로그램 중단

2-2. 모듈 통합 (API 호출)
다른 서비스 로직에서 OCR 기능을 서브루틴으로 호출할 때의 코드 예시입니다.

Python
from ai.ocr import capture_image_from_camera, get_text_from_image

def analyze_label():
    # 1. 카메라 서브루틴 호출 (이미지 객체 획득)
    img = capture_image_from_camera()
    
    if img:
        # 2. OCR 수행 (최종 텍스트 문자열 반환)
        # 결과값은 Markdown 형식을 포함한 String입니다.
        text_result = get_text_from_image(img)
        return text_result.strip()
    return "촬영 취소"
🧠 3. AI 로직 상세 (Internal Logic)
3-1. 영양제 전용 프롬프트 (Prompt Engineering)
0.9B 모델의 문맥 파악 능력을 보조하기 위해 영어 지시문을 통해 다음과 같은 교정 규칙을 강제합니다:

통증 관련: '근육동', '신경동' 등 시각적 오인식을 '통(Pain)'으로 강제 교정 (e.g., 근육통, 요통).

단위 교정: 알약 단위인 '장', '점'을 '정(Tablet)'으로 자동 보정 (e.g., 180정).

표준 용어: '육체피로', '병중·병후', '뼈 건강' 등 정제된 한국어 의학 용어 우선 출력.

3-2. 이미지 파이프라인
Capture: OpenCV를 통해 BGR 프레임 획득.

Convert: BGR을 RGB로 변환 후 PIL.Image 객체로 래핑하여 모델에 전달.

Inference: bfloat16 정밀도로 GPU 연산 수행 (VRAM 약 2~3GB 소요).

⚠️ 주의 사항
조명 관리: 라벨의 비닐 재질 반사가 심할 경우 글자가 유실될 수 있으니 직접 조명을 피해서 촬영하세요.

최초 실행: 모델 가중치(약 2GB) 다운로드를 위해 최초 실행 시 네트워크 연결이 필요합니다.