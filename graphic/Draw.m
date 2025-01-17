% 画一种颜色分辨率
%% 单种频率分辨率以及颜色映射画图
clc;clear;close all;
fs = 100e6;                     % 输入采样率
fftpoint = [1024];
time_sec = 0.1;                   % 需要的分割时间/s
dataform = 'float32';           % 输入的数据类型
byte_per = 4;                   % 该数据类型占字节数
datalength = time_sec*fs*byte_per*2;       % 读取数据的长度，单位是字节(时间*采样率*每个数据占字节*iq)
file_in ={"Z:\RFUAV\UAVDATA\第二批\FutabaT14SG",
          "Z:\RFUAV\UAVDATA\第二批\herelink",
          "Z:\RFUAV\UAVDATA\第二批\SIYI",
          "Z:\RFUAV\UAVDATA\第二批\yunzhuo"};% 输入路径
files = [];
for i = 1:length(file_in)
    % 获取文件夹内所有iq/dat/bin文件
    files_dat = dir(fullfile(file_in{i}, '*.dat'));
    files_iq = dir(fullfile(file_in{i}, '*.iq'));
    files_bin = dir(fullfile(file_in{i}, '*.bin'));
    % 合并两个结果
    files = [files,files_dat; files_iq,files_bin];
    file_num(i) = length(files);
end
fileFlag = 1;
% 一级循环，遍历文件
for ii = 1:length(files)
    fileName{ii} = files(ii).name;
    while(ii > file_num(fileFlag))
        fileFlag = fileFlag + 1;
    end
    file_input = fullvfile(file_in{fileFlag},fileName{ii})
    % 从文件名判断无人机机型，第一个-/_前名称
    myname = char(fileName{ii});
    for i = 1:length(myname)
        if (strcmp(myname(i), '-') || strcmp(myname(i), '_'))
            flytype = string(myname(1:i-1));
            break; % 找到第一个 '-' 后退出循环
        end
    end
    filepathOut = "E:\DataBase\stftFig";
%     filepathOut_get = filepathOut + '\' + fileName{ii}(1:end-4);
    filepathOut = filepathOut + '\' + flytype + '\' + fileName{ii}(1:end-3);
    color = ["parula"];
%     color = ["parula"];
%     ,"parula" 后续添加
    if ~exist(filepathOut,"dir")
        mkdir(filepathOut);
    else
        disp("文件夹已经存在!");
    end
    % 读取文件,获取大小
    fp = fopen(file_input, 'rb');
    fseek(fp, 0, 1);
    fileSize = ftell(fp);
    fclose(fp);
    readtime = ceil(fileSize/datalength);

    %% 分次读取文件保存
    time = 0;
    for i =1:readtime
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
                xticklabels([0:0.1/10:0.1]);
                xlabel("时间(s)");
                title(fileName{ii}(1:end-4));
                title(flytype);
%                 filepathOut = filepathOut_get + '\'+ color(k) + '\'+num2str(fftpoint(j));
%                 if ~exist(filepathOut,"dir")
%                     mkdir(filepathOut);
%                 end
                newFile = fullfile(filepathOut,num2str(i*0.1-0.1+time) + "-" + num2str(i*0.1+time) + "s-" +...
                    color(k) + "-" + num2str(fftpoint(j)) + ".jpg"); % 生成新的文件路径和文件名
                set(gcf, 'Units', 'inches', 'Position', [0, 0, 8, 6]);
                print(gcf, newFile, '-dpng', '-r300');
                clf;
            end
        end
        toc
    end
end