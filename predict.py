import os
from ultralytics import YOLO

def run_prediction():
    # 1. 모델 및 경로 설정
    model_path = r"C:\tabletYOLO\weights\best.pt"
    source_dir = r"C:\tabletYOLO\predict"
    output_dir = r"C:\tabletYOLO\predict_result"
    
    # 2. 모델 로드
    model = YOLO(model_path)
    
    # 3. 결과 저장 폴더 생성 (이미 존재하면 덮어쓰기 위해 project/name 활용)
    # 추론 결과와 크롭 결과 모두 output_dir에 저장하도록 설정
    model.predict(
        source=source_dir,
        project=output_dir,
        name=".",          # 현재 경로(output_dir) 바로 아래에 저장
        save=True,         # 바운딩 박스가 그려진 이미지 저장
        save_crop=True,    # 크롭된 이미지 저장
        conf=0.5,
        exist_ok=True
    )

    print(f"추론 및 결과 저장이 완료되었습니다: {output_dir}")

if __name__ == "__main__":
    run_prediction()
