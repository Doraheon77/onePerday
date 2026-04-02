# 💊 AI OCR 모듈 사용 가이드 (onePerday)

이 모듈은 **GLM-OCR (0.9B)** 모델을 사용하여 카메라로 촬영한 영양제 라벨에서 제품명, 영양 성분, 주의사항 등을 추출합니다. 0.9B 경량 모델의 특성을 고려하여 한국어 의학 용어 및 곡면 왜곡 보정에 최적화된 프롬프트가 적용되어 있습니다.

## 📂 파일 위치
`C:\onePerday\ai\ocr.py`

---

## 🛠 1. 환경 설정 (Prerequisites)

이 모듈은 GPU(CUDA) 가속을 권장합니다. 아래 순서대로 라이브러리를 설치하세요.

### 1-1. 필수 라이브러리 설치
```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130
pip install "transformers>=4.46.0" "accelerate>=0.34.0" opencv-python pillow
```

### 1-2. 하드웨어 체크
GPU가 정상적으로 인식되는지 확인하려면 아래 명령어를 실행하세요.
```bash
python -c "import torch; print(f'GPU 가능 여부: {torch.cuda.is_available()}')"
```

---

## 🚀 2. 사용 방법

### A. 독립 실행 (테스트용)
`ocr.py` 파일을 직접 실행하여 카메라 작동 및 인식 성능을 테스트할 수 있습니다.
```bash
python ai/ocr.py
```
* **Spacebar**: 사진 촬영 및 분석 시작
* **q**: 촬영 취소 및 종료

### B. 서브루틴 호출 (모듈 통합용)
다른 서비스 파일(예: `main.py`)에서 OCR 기능을 가져와 사용할 때의 예시입니다.

```python
from ai.ocr import capture_image_from_camera, get_text_from_image

def process_nutrition_label():
    # 1. 카메라 호출 및 이미지 객체 획득
    img = capture_image_from_camera()
    
    if img:
        # 2. OCR 분석 수행 (텍스트만 반환)
        # 반환값: Markdown 형식의 문자열(String)
        extracted_text = get_text_from_image(img)
        
        print("--- 인식 결과 ---")
        print(extracted_text.strip())
        return extracted_text
    
    return None
```

---

## 📝 3. 주요 함수 설명

| 함수명 | 설명 | 반환값 |
| :--- | :--- | :--- |
| `capture_image_from_camera()` | 웹캠을 활성화하여 사용자가 촬영한 프레임을 반환합니다. | `PIL.Image` 객체 (취소 시 `None`) |
| `get_text_from_image(image)` | 입력받은 이미지를 GLM-OCR 모델로 분석합니다. | 추출된 **텍스트 문자열(String)** |

---

## 💡 4. 기술적 특징 (0.9B 최적화)

* **Vocabulary Injection**: 0.9B 모델의 어휘력 한계를 보완하기 위해 '근육통', '신경통', '병중·병후' 등 영양제 라벨 전용 의학 용어 교정 로직이 프롬프트에 포함되어 있습니다.
* **Curvature Correction**: 약통의 곡면으로 인해 자음/모음이 분리되는 현상을 문맥적으로 재결합하도록 지시합니다.
* **Multilingual**: 한국어와 영어를 동시에 인식하며, 성분표는 Markdown Table 형식으로 구조화합니다.

---

## ⚠️ 주의 사항
1. **조명**: 라벨의 비닐 재질로 인한 빛 반사가 심할 경우 인식률이 떨어질 수 있습니다.
2. **GPU 메모리**: 최소 4GB 이상의 VRAM을 권장합니다. 메모리 부족 시 `ocr.py` 내의 `dtype=torch.bfloat16` 설정을 확인하세요.
3. **최초 실행**: 모델 파일(약 2GB)을 허브에서 다운로드하므로 첫 실행 시 시간이 다소 소요될 수 있습니다.

---
**작성자**: SJ (AI 파트)  
**최종 수정일**: 2026-04-02