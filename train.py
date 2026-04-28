from ultralytics import YOLO

def train_model():
    # Nano 모델 로드 (가장 가벼운 모델로 과적합 방지)
    model = YOLO(r"C:\tabletYOLO\yolo26s.pt")

    # 추천 파라미터 적용
    model.train(
        data="C:/tabletYOLO/supplement_label_dataset/supplement_label.yaml",
        epochs=100,
        patience=15,        # 15 epoch 동안 성능 개선 없으면 조기 종료
        freeze=10,          # 백본 레이어 10개 고정 (전이 학습 효율 극대화)
        optimizer="AdamW",  # 소량 데이터에 더 안정적
        lr0=0.001,          # 보수적인 학습률로 가중치 보호
        mosaic=0.0,         # 배경/텍스트 왜곡 방지를 위해 모자이크 비활성화
        imgsz=640,          # 일반적인 해상도
        batch=8             # 데이터가 적으므로 작은 배치 사이즈 권장
    )

if __name__ == "__main__":
    train_model()
