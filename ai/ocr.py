import torch
import cv2 # 카메라 연동을 위한 라이브러리 추가
from transformers import AutoProcessor, AutoModelForImageTextToText
from PIL import Image

# 1. 모델 ID 및 장치 설정
MODEL_ID = "zai-org/GLM-OCR"
device = "cuda" if torch.cuda.is_available() else "cpu"

# 2. 프로세서 및 모델 로드 
processor = AutoProcessor.from_pretrained(MODEL_ID, trust_remote_code=True)
model = AutoModelForImageTextToText.from_pretrained(
    MODEL_ID, 
    dtype=torch.bfloat16, 
    low_cpu_mem_usage=True, 
    trust_remote_code=True
).to(device)

def capture_image_from_camera():
    """카메라를 열어 이미지를 촬영하고 PIL Image 객체로 반환합니다."""
    # 0번(기본 웹캠) 장치 열기
    cap = cv2.VideoCapture(0)
    
    if not cap.isOpened():
        raise Exception("카메라를 열 수 없습니다. 카메라 연결 상태를 확인해주세요.")
        
    print("\n📷 카메라가 켜졌습니다.")
    print("👉 사진을 찍으려면 'Spacebar'를 누르세요.")
    print("👉 촬영을 취소하려면 'q'를 누르세요.\n")
    
    captured_image = None
    
    while True:
        ret, frame = cap.read()
        if not ret:
            print("프레임을 읽을 수 없습니다.")
            break
            
        cv2.imshow("Camera - Press Spacebar to capture", frame)
        
        key = cv2.waitKey(1) & 0xFF
        if key == 32:  # 스페이스바 입력 시
            # OpenCV의 BGR 이미지를 PIL에서 사용하는 RGB로 변환
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            captured_image = Image.fromarray(rgb_frame)
            print("✅ 사진이 성공적으로 촬영되었습니다!")
            break
        elif key == ord('q'): # q 키 입력 시
            print("❌ 촬영을 취소합니다.")
            break
            
    # 자원 해제 및 창 닫기
    cap.release()
    cv2.destroyAllWindows()
    
    return captured_image

def get_text_from_image(image):
    """PIL Image 객체를 받아 OCR 텍스트를 반환합니다."""
    messages = [
        {
            "role": "user",
            "content": [
                {"type": "image"},
                {
                    "type": "text", 
                    "text": "Text Recognition:" # 필요시 이전에 최적화한 프롬프트로 변경 가능
                }
            ]
        }
    ]
    
    # 템플릿 적용 및 입력 데이터 생성
    prompt = processor.apply_chat_template(messages, add_generation_prompt=True, tokenize=False)
    inputs = processor(text=prompt, images=[image], return_tensors="pt").to(device)

    # 텍스트 생성
    with torch.no_grad():
        output_ids = model.generate(
            **inputs, 
            max_new_tokens=2048, 
            do_sample=False
        )
    
    generated_ids = output_ids[:, inputs['input_ids'].shape[1]:]
    return processor.batch_decode(generated_ids, skip_special_tokens=True)[0]

import sys

if __name__ == "__main__":
    try:
        # 인자(sys.argv)가 넘어오면 파일 경로로 열고, 없으면 기존 카메라 웹캠 호출!
        if len(sys.argv) > 1:
            image_path = sys.argv[1]
            img = Image.open(image_path)
            device_print = False
        else:
            img = capture_image_from_camera()
            device_print = True
        
        # Step 3: 이미지가 정상적으로 로드/캡처되었다면 OCR 수행
        if img is not None:
            if device_print:
                print(f"\n[{device.upper()}] 장치에서 OCR 분석을 시작합니다... 잠시만 기다려주세요.")
            result = get_text_from_image(img)
            
            if device_print:
                print("\n" + "=" * 40)
                print("📝 분석 결과")
                print("=" * 40)
            print(result)
            if device_print:
                print("=" * 40)
        else:
            print("이미지가 캡처되지 않아 OCR을 수행하지 않고 종료합니다.")
            
    except Exception as e:
        print(f"에러 발생: {e}")