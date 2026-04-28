import os
from ultralytics import YOLO
import shutil

def process_images_in_folder():
    # 1. 수정된 경로 설정 (C:\tabletYOLO 프로젝트 내부 기준)
    model_path = r"C:\tabletYOLO\weights\best.pt"
    source_dir = r"C:\tabletYOLO\predict"
    output_dir = r"C:\tabletYOLO\predict_result"
    
    # 2. 프로젝트 내 임시 작업 경로
    temp_predict_dir = r"C:\tabletYOLO\runs\detect\predict_temp"
    
    # 3. 모델 로드
    model = YOLO(model_path)
    
    # 4. 결과 폴더 생성
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created: {output_dir}")
        
    # 5. 소스 폴더 내 JPG 처리
    jpg_files = [f for f in os.listdir(source_dir) if f.lower().endswith('.jpg')]
    if not jpg_files:
        print(f"No JPG files found in {source_dir}")
        return

    print(f"Processing {len(jpg_files)} images...")
    
    # 6. 추론 수행 (모델 결과 저장 위치를 프로젝트 내 temp로 지정)
    model.predict(
        source=source_dir,
        project=r"C:\tabletYOLO\runs\detect",
        name="predict_temp",
        save_crop=True,
        conf=0.5,
        exist_ok=True
    )
    
    # 7. 크롭된 이미지 정리
    crops_dir = os.path.join(temp_predict_dir, "crops", "supplement_label")
    if os.path.exists(crops_dir):
        count = 0
        for filename in os.listdir(crops_dir):
            if filename.lower().endswith('.jpg'):
                src = os.path.join(crops_dir, filename)
                dst = os.path.join(output_dir, filename)
                shutil.copy2(src, dst)
                print(f"Copied: {filename} -> {output_dir}")
                count += 1
        print(f"Successfully processed {count} images to {output_dir}")
    else:
        print("No labels detected or crops found.")

if __name__ == "__main__":
    process_images_in_folder()
