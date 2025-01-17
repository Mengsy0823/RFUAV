% 画一种颜色分辨率
%% 单种频率分辨率以及颜色映射画图
clc;clear;close all;
fs = 100e6;                     % 输入采样率
fftpoint = [1024];
time_sec = 0.1;                   % 需要的分割时间/s
dataform = 'float32';           % 输入的数据类型
byte_per = 4;                   % 该数据类型占字节数
datalength = time_sec*fs*byte_per*2;       % 读取数据的长度，单位是字节(时间*采样率*每个数据占字节*iq)

file_input = "E:\Drone_dataset\RFUAV\rawdata\FutabaT14SG\FUtabaT14SG_2440_daifei_80dB(2)_0-2s.iq";
filepathOut = "E:\360MoveData\Users\sam826001\Desktop\研2\无人机数据集论文\数据统计\";
color = ["parula"];
% 读取文件,获取大小
fp = fopen(file_input, 'rb'); 
fseek(fp, 0, 1);
fileSize = ftell(fp);
fclose(fp);
readtime = ceil(fileSize/datalength);

%% 分次读取文件保存
time = 0;
for i =5:readtime
    tic
    fp = fopen(file_input, 'rb'); 
    fseek(fp,(i-1)*datalength,-1);
    data = fread(fp,datalength/4,dataform);
    fclose(fp);
    dataIQ = data(1:2:end-1) + 1i * data(2:2:end);
    clear data;
    for j = 1:length(fftpoint)
        for k = 1:length(color)
            stft(dataIQ,fs,FFTLength=fftpoint(j));
            colormap(color(k));
            yticks([-50 :10:50]);
            yticklabels([5710:10:5810]);
            xticks([0:10:100]);
            xticklabels([0:time_sec/10:time_sec]);
            xlabel("时间(s)");
            title("test");
            title("111");
            clf;
        end
    end
    toc
end