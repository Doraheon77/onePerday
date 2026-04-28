import os
import xml.etree.ElementTree as ET

def convert_voc_to_yolo(xml_file, txt_file):
    tree = ET.parse(xml_file)
    root = tree.getroot()
    
    size = root.find('size')
    w = int(size.find('width').text)
    h = int(size.find('height').text)
    
    if w == 0 or h == 0:
        print(f"Skipping {xml_file}: zero dimension")
        return
    
    with open(txt_file, 'w') as f:
        for obj in root.findall('object'):
            cls = obj.find('name').text
            if cls != 'supplement_label':
                continue
            
            xmlbox = obj.find('bndbox')
            b = (float(xmlbox.find('xmin').text), float(xmlbox.find('xmax').text),
                 float(xmlbox.find('ymin').text), float(xmlbox.find('ymax').text))
            
            # YOLO format
            dw = 1./w
            dh = 1./h
            x = (b[0] + b[1]) / 2.0 - 1
            y = (b[2] + b[3]) / 2.0 - 1
            w_norm = b[1] - b[0]
            h_norm = b[3] - b[2]
            x = x * dw
            y = y * dh
            w_norm = w_norm * dw
            h_norm = h_norm * dh
            
            f.write(f"0 {x:.6f} {y:.6f} {w_norm:.6f} {h_norm:.6f}\n")

base_dir = r"C:\tabletYOLO\supplement_label_dataset"
for split in ['train', 'val', 'test']:
    img_dir = os.path.join(base_dir, 'images', split)
    lbl_dir = os.path.join(base_dir, 'labels', split)
    os.makedirs(lbl_dir, exist_ok=True)
    
    for filename in os.listdir(img_dir):
        if filename.endswith('.xml'):
            convert_voc_to_yolo(os.path.join(img_dir, filename), 
                               os.path.join(lbl_dir, filename.replace('.xml', '.txt')))
            print(f"Converted: {filename}")

print("Conversion complete.")
