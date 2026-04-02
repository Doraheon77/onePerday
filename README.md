🌿 onePerday AI OCR Module
본 프로젝트의 AI 파트는 GLM-OCR (0.9B) 모델을 활용하여 카메라로 촬영한 이미지에서 텍스트를 추출하는 기능을 담당합니다. 현재 버전은 AI 모듈의 기본 구조를 잡고 카메라 인터페이스를 연동한 초기 세팅(Initial Setting) 단계입니다.

📂 파일 정보
로컬 경로: C:\onePerday\ai\ocr.py

주요 기능: 웹캠 실시간 캡처, PIL 이미지 변환, GLM-OCR 기본 텍스트 추출.

🛠 1. 개발 환경 설정 (Installation)
이 모듈은 GPU(CUDA) 가속을 통해 실시간에 가까운 속도로 동작합니다. 아래 명령어를 순서대로 실행하여 환경을 구축하세요.

1-1. PyTorch 및 CUDA 연동 (v13.0 대응)
Bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130
1-2. 필수 라이브러리 설치
Bash
pip install "transformers>=4.46.0" "accelerate>=0.34.0" opencv-python pillow
🚀 2. 사용 방법 (Usage)
2-1. 단독 실행 테스트
모듈의 작동 여부를 즉시 확인하려면 해당 스크립트를 직접 실행합니다.

Bash
python ai/ocr.py
Spacebar: 현재 카메라 화면을 캡처하고 OCR 분석을 시작합니다.

q: 카메라를 종료하고 프로그램을 중단합니다.

2-2. 모듈 호출 (API)
타 파트에서 OCR 기능을 호출하여 결과 텍스트만 반환받고 싶을 때 사용합니다.

Python
from ai.ocr import capture_image_from_camera, get_text_from_image

def run_ocr_process():
    # 1. 카메라 서브루틴 호출 (이미지 객체 획득)
    img = capture_image_from_camera()
    
    if img:
        # 2. OCR 분석 수행 (최종 텍스트 문자열 반환)
        # 결과값은 모델이 생성한 순수 Markdown/Text String입니다.
        result_text = get_text_from_image(img)
        return result_text.strip()
    return None
🧠 3. AI 로직 구조 (System Logic)
3-1. 기본 프롬프트 구성
현재 버전은 모델의 순수한 인식 능력을 테스트하기 위해 최소한의 지시문을 사용합니다.

Prompt: "Text Recognition:"

3-2. 이미지 파이프라인
OpenCV Capture: 웹캠에서 BGR 색상 체계의 프레임을 획득합니다.

Format Conversion: OpenCV의 BGR 이미지를 PIL의 RGB 형식으로 변환하여 모델 입력 규격에 맞춥니다.

GPU Inference: bfloat16 정밀도로 모델을 로드하여 VRAM 효율을 최적화합니다.

⚠️ 주의 사항
라이팅 환경: 별도의 보정 로직이 포함되지 않은 초기 버전이므로, 선명한 텍스트 인식을 위해 조명이 충분한 환경에서 촬영을 권장합니다.

모델 다운로드: 최초 실행 시 약 2GB 규모의 모델 가중치 파일 다운로드를 위해 네트워크 연결이 필수적입니다.