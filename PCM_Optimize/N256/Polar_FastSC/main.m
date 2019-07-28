clc
clear

% ������������
n = 8;  % ����λ��
N = 2^n;
M = 140;
Ng = 12;
Kp = 10;

K = M-Kp/2;

R = (M-Ng-Kp/2)/N;    % ����
SNR = [1 2 3 4 4.5];
% ��������
snr = 10.^(SNR/10);
esn0 = snr * R;


lambda_offset = 2.^(0 : log2(N));
llr_layer_vec = get_llr_layer(N);
bit_layer_vec = get_bit_layer(N);

k_f = N-K;% frozen_bits length

% get information bits and concatenated bits
load('Pe_N256_snr3.2_R5.mat');
[~, I] = sort(P);
info_index = I(1:K);
% reset the frozen bits and mutual bits
frozen_bits = ones(N,1);
frozen_bits(info_index) = 0;% ��ѡ�����õ��ŵ�������Ϣλ



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
        source_bit = rand(1,K)>0.5;
        u = zeros(N, 1);
        u(info_index) = source_bit;
        encode_temp = polar_encoder(u, lambda_offset, llr_layer_vec);

        % bpsk modulation
        encode_temp = 1 - 2 * encode_temp;

        % add noise
        receive_sample = encode_temp + sigma * randn(size(encode_temp));
        
        llr = 2/sigma^2*receive_sample;
        
        decision_bits = SC_decoder(llr, info_index, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);


        count = sum(decision_bits' ~= source_bit);
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