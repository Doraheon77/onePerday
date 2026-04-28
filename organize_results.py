import os
import shutil

def organize_predict_results():
    # 원본 predict 폴더와 새로운 대상 폴더 경로
    predict_base = r"C:\sd-webui-forge-classic\runs\detect\predict"
    crops_dir = os.path.join(predict_base, "crops", "supplement_label")
    result_dir = r"C:\tabletYOLO\predict_result"
    
    # 결과 폴더 생성
    if not os.path.exists(result_dir):
        os.makedirs(result_dir)
        print(f"Created: {result_dir}")
    
    # crops 폴더 내의 모든 jpg 파일을 predict_result로 복사
    if os.path.exists(crops_dir):
        count = 0
        for filename in os.listdir(crops_dir):
            if filename.lower().endswith('.jpg'):
                src = os.path.join(crops_dir, filename)
                dst = os.path.join(result_dir, filename)
                shutil.copy2(src, dst)
                print(f"Copied: {filename} -> {result_dir}")
                count += 1
        print(f"Successfully organized {count} cropped images to {result_dir}")
    else:
        print(f"No crops found in {crops_dir}")

if __name__ == "__main__":
    organize_predict_results()
