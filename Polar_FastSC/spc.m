clc
clear

% ������������
n = 10;  % ����λ��
R = 0.5;    % ����
SNR = [1 2 3 3.5 4];
% ��������
snr = 10.^(SNR/10);
esn0 = snr * R;
N = 2^n;

K = floor(N*R);  % information bit length
k_f = N-K;% frozen_bits length

load('Pe_N1024_snr2.mat');
[~, I] = sort(P);
info_index = I(1:K);
frozen_index = I(K+1:end);
frozen_bits = ones(N,1);
frozen_bits(info_index) = 0;% ��ѡ�����õ��ŵ�������Ϣλ

%Generation matrix
G = spc_encoding(n);
Gaa = G(info_index, info_index);
Gab = G(info_index, frozen_index);

lambda_offset = 2.^(0 : log2(N));
llr_layer_vec = get_llr_layer(N);
bit_layer_vec = get_bit_layer(N);



rng('shuffle');
for i = 1:length(SNR)
    
    sigma = (2*esn0(i))^(-0.5);
    
   

    % set PER and BER counter
    PerNum = 0;
    BerNum = 0;
    iter = 0;
    %counter the number of Re-SC decoding
    % ���²���������¼ÿ��SNR�㣬�������ᵽ��case1-case4��������
 
    while true 
        iter = iter + 1;
        if mod(iter,1000) == 0
            fprintf('\nNow iter: %2d\tNow SNR: %d\tNow PerNum: %2d\tNow Error Bits: %2d',iter,SNR(i),PerNum,BerNum);
        end
        codeword = zeros(N, 1);
        Xa = rand(1,K)>0.5;
        ua = mod(Xa * Gaa, 2);
        Xb = mod(ua * Gab, 2);
        
        codeword(info_index) = Xa;
        codeword(frozen_index) = Xb;

        % bpsk modulation
        encode_temp = 1 - 2 * codeword;

        % add noise
        receive_sample = encode_temp + sigma * randn(size(encode_temp));
        
        llr = 2/sigma^2*receive_sample;
        
        decision_bits = SC_decoder(llr, info_index, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);
        
        Xa_esti = mod(decision_bits' * Gaa, 2);


        count = sum(Xa_esti ~= Xa);
        if count ~= 0
            PerNum = PerNum + 1;
            BerNum = BerNum + count;
        end

        if (PerNum>=100 && iter>=10000)
            break;
        end
        
        if (iter >= 10000000)
           break; 
        end
        
        
    end    
    iterNum(i) = iter;
    per(i) = PerNum/iter;
    ber(i) = BerNum/K/iter;  
end

% recording the results
% path = './results/';
% filename = [path, 'Polar_FastSC_N',num2str(N),'_R',num2str(R),'.mat'];
% save(filename)