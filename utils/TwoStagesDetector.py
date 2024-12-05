import os
import glob
from PIL import Image
import cv2
from graphic.RawDataProcessor import generate_images
import imageio
from logger import colorful_logger
import json

from benchmark import Classify_Model, Detection_Model, is_valid_file, raw_data_ext, image_ext


# 二阶段模型的一个数据流处理类，提供公共接口
class TwoStagesDetector:

    def __init__(self, cfg: str = ''):
        """解析一个统一cfg的方法，并按照方法选模型
        1.选设备
        2.解析cfg，初始化模型
        """
        self.logger = colorful_logger('Inference')
        det, cla, save_path, target_dir = load_model_from_json(cfg)
        self.det = det
        self.cla = cla
        self.save_path = save_path
        self.target_dir = target_dir

        if not cla and det:
            self.DroneDetector(cfg=det)
        elif not det and cla:
            self.DroneClassifier(cfg=cla['cfg'], weight_path=cla['weight_path'], save=True)
        elif det and cla:
            self.DroneDetector(cfg=det)
            self.DroneClassifier(cfg=cla['cfg'], weight_path=cla['weight_path'], save=True)
        else:
            raise ValueError("No model is selected")

        if not os.path.exists(save_path):
            os.mkdir(save_path)
        self.logger.log_with_color(f"Saving results to: {save_path}")

        if not os.path.exists(target_dir):
            raise ValueError(f"Source {target_dir} dose not exit")

        # dir detect
        if os.path.isdir(target_dir):
            data_list = glob.glob(os.path.join(target_dir, '*'))

            for data in data_list:
                # detect images in dir
                if is_valid_file(data, image_ext):
                    self.ImgProcessor(data)
                # detect raw datas in dir
                elif is_valid_file(data, raw_data_ext):
                    self.RawdataProcess(data)
                else:
                    continue

        # detect single image
        elif is_valid_file(target_dir, image_ext):
            self.ImgProcessor(target_dir)

        # detect single pack of raw data
        elif is_valid_file(target_dir, raw_data_ext):
            self.RawdataProcess(target_dir)

    def ImgProcessor(self, source, save=True):

        if self.S1.S1model:
            res = self.S1.S1model.inference(source=source, save_dir='buffer')
            if not self.S2model:
                if save:
                    cv2.imwrite(self.save_path, res)
                else:
                    return res

        if self.S2model:
            name = os.path.basename(source)[:-4]
            origin_image = Image.open(source).convert('RGB')
            preprocessed_image = self.S2model.preprocess(source)

            probability, predicted_class_name = self.S2model.forward(preprocessed_image)

            if not self.S1.S1model:
                res = self.S2model.add_result(res=predicted_class_name,
                                              probability=predicted_class_name,
                                              image=origin_image)
                if save:
                    res.save(os.path.join(self.save_path, name + '.jpg'))
                else:
                    return res

            else:
                # 加一个opencv格式图像到PIL图像的过程
                res = put_res_on_img(res, predicted_class_name, probability=probability)

                cv2.imshow('res', res)
                cv2.waitKey(0)
                cv2.destroyAllWindows()

                print('test')
                if save:
                    cv2.imwrite(self.save_path, res)
                else:
                    return res

    def RawdataProcess(self, source):
        """
        Transforming raw data into a video and performing inference on video.

        Parameters:
        - source (str): Path to the raw data.
        """
        res = []
        images = generate_images(source)
        name = os.path.splitext(os.path.basename(source))

        for image in images:
            _ = self.ImgProcessor(image, save=False)
            res.append(_)

        imageio.mimsave(os.path.join(self.save_path, name + '.mp4'), res, fps=5)

    def DroneDetector(self, cfg):
        """第一阶段模型初始化

        :return:
        """
        self.S1 = Detection_Model(cfg)


    def DroneClassifier(self, cfg, weight_path, save=True):
        """第二阶段模型初始化

        :return:
        """
        self.S2model = Classify_Model(cfg=cfg, weight_path=weight_path)
        # self.S2model._inference()


    @property
    def set_logger(self):
        """
        Sets up the logger.

        Returns:
        - logger (colorful_logger): Logger instance.
        """
        logger = colorful_logger('Inference')
        return logger


def load_model_from_json(cfg):
    """load cfg from .json
    :return:
    """
    with open(cfg, 'r') as f:
        _ = json.load(f)
        return _['detector'] if 'detector' in _ else None, _['classifier'] if 'classifier' in _ else None, _['save_dir'], _['target_dir']


def put_res_on_img(img,
                   text,
                   probability=0.0,
                   position=(20, 60),
                   font_scale=1,
                   color=(0, 0, 0),
                   thickness=3):

    # 在图片上添加文字
    cv2.putText(img=img,
                text=text + f" {probability:.2f}%",
                org=position,
                fontFace=cv2.FONT_HERSHEY_SIMPLEX,
                fontScale=font_scale,
                color=color,
                thickness=thickness,
                lineType=cv2.LINE_AA)

    return img


# for test ------------------------------------------------------------------------------------------------------------
def main():
    cfg_path = '../example/two_stage/sample.json'
    TwoStagesDetector(cfg=cfg_path)


if __name__ == '__main__':
    main()