import os
import xml.etree.ElementTree as ET
from PIL import Image

def fix_xml_dimensions(xml_path, img_path):
    try:
        # 이미지 크기 추출
        with Image.open(img_path) as img:
            w, h = img.size
        
        # XML 수정
        tree = ET.parse(xml_path)
        root = tree.getroot()
        size = root.find('size')
        
        if size is None:
            size = ET.SubElement(root, 'size')
            ET.SubElement(size, 'width')
            ET.SubElement(size, 'height')
            ET.SubElement(size, 'depth').text = '3'
            
        size.find('width').text = str(w)
        size.find('height').text = str(h)
        
        tree.write(xml_path)
        return True
    except Exception as e:
        print(f"Error processing {xml_path}: {e}")
        return False

base_dir = r"C:\tabletYOLO\supplement_label_dataset"
for split in ['train', 'val', 'test']:
    img_dir = os.path.join(base_dir, 'images', split)
    
    for filename in os.listdir(img_dir):
        if filename.endswith('.xml'):
            base_name = filename.replace('.xml', '')
            img_path = os.path.join(img_dir, base_name + '.jpg')
            xml_path = os.path.join(img_dir, filename)
            
            # XML의 width/height가 0인 경우만 수정
            tree = ET.parse(xml_path)
            size = tree.getroot().find('size')
            if int(size.find('width').text) == 0 or int(size.find('height').text) == 0:
                print(f"Fixing dimensions for {filename}")
                fix_xml_dimensions(xml_path, img_path)

print("XML dimension fix complete.")
