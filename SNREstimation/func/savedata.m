% 根据信噪比估计结果给整个文件依次加噪声
function [] = DoAddNoise(file_out,file_in,fileName,signal_power,noisevalue,target)
%   此处显示详细说明
    
    file = fullfile(file_in,fileName);
    fileInfo = dir(file); % 替换为你的文件名
    fileSize = fileInfo.bytes; % 获取文件大小，单位为字节
    times = fileSize /4/ 3e6;  
    filepathOut = file_out + '\' + fileName(1:end-4) + '-noise' ;
    if ~exist(filepathOut,"dir")
        mkdir(filepathOut);
    end
    filepathOut = filepathOut + '\' + num2str(target)+ "dB.dat";  
    for i = 1:times
        fp = fopen(file,"rb"); 
        fseek(fp,3e6*(i-1),-1);
        data = fread(fp,3e6,"float");
        fclose(fp);
        dataIQ = data(1:2:end) + 1j*data(2:2:end);
%         dataIQ = normalize(dataIQ, "norm");
        % 生成复数白噪声
        noisy_data = awgn1(dataIQ,noisevalue,signal_power);      
%         xinzaobi = snrEsti(noisy_data,100e6,20e6, 409600);
        % 保存  
        if(i == 1)
            fp = fopen(filepathOut,"wb+");
        else
            fp = fopen(filepathOut,"ab+");
        end
        data=zeros(length(dataIQ)*2,1);
        data(1:2:end) = real(noisy_data);
        data(2:2:end) = imag(noisy_data);
        fwrite(fp,data,"float");
        fclose(fp);
    end
end

