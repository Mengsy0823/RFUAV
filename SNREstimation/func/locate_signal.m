% 寻找信号和噪声位置
function [idx1,idx2,idx3,idx4,f1, f2] = positionFind(dataIQ, fs, bw, NFFT)
    %% 信号位置检测
    [f1, f2] = dronesOFDMFreqShiftEsti(dataIQ, fs, bw, NFFT);
    f = (f1 + f2) / 2;
    sig = dronesOFDMFreqCompensation(dataIQ, fs, f);
    f11 = f1 - f;   f22 = f2 - f;
    
    
    
    %% 降采样
    refs = fs/2;
    reNfft = NFFT / 2;
    sigResample = resample(sig, refs, fs);
    
    [pxx3, fvec3] = pwelch(sigResample, ...
        hamming(round(length(sigResample)/ 10)), [], reNfft, refs, "centered");
    
    
    %% SNR Esti
    temp11 = abs(fvec3 - f11);
    temp22 = abs(fvec3 - f22);
    [~, idx1] = min(temp11);
    [~, idx2] = min(temp22);
    
    
    bwNoise = 1e6;       % 取一段带宽为1M的信号作为噪声
    f3  = 0.75e6;       
    
    bwNoiseNfft = round(reNfft * (bwNoise / refs));
    idx4 = idx1 - round(reNfft * (f3 / refs));
    idx3 = idx4 - bwNoiseNfft;
end

