clc
clear

% ������������
n = 8;  % ����λ��
R = 0.5;    % ����

SNR = -1:5;

init_lr_max = 3;    % limit the max LR of the channel to be with [-3 3]
max_iter = 40;
block_num = 1000;

% ��������
snr = 10.^(SNR/10);
esn0 = snr * R;
init_max = init_lr_max * n;
if init_max > 30
    init_max = 30;
end
N = 2^n;
K = floor(N*R);  % information bit length
k_f = N - K;

% get information bits and concatenated bits
load('Pe_snr3p0db_2048_n_8.mat');   % load the channel information
[Ptmp, I] = sort(P);
Info_index = sort(I(K:-1:1));  % ��ѡ�����õ��ŵ�������Ϣλ
Frozen_index = sort(I(end:-1:K+1));   % ���䶳��λ���ŵ�

% get generate matrix
G = encoding_matrix(n);
Gi = G(Info_index,:);
Gf = G(Frozen_index,:);
frozen_bits = randi([0 1],1,k_f);
rng('shuffle')
for i = 1:length(SNR)
    sigma = (2*esn0(i))^(-0.5);
    % set PER and BER counter
    PerNumSC = 0;
    BerNumSC = 0;
    PerNumBP = 0;
    BerNumBP = 0;
    for iter = 1:block_num
        fprintf('\nNow iter: %2d\tNow SNR: %d', iter, SNR(i));
        source_bit = randi([0 1],1,K);
        encode_temp = rem(source_bit*Gi + frozen_bits*Gf,2);
    
        % bpsk modulation
        encode_temp = (-1).^(encode_temp + 1);
        % add noise
        receive_sample = encode_temp + sigma * randn(size(encode_temp));
        % SC decoder
        [receive_bits_SC,~] = polarSC_decoder(n,receive_sample,sigma,Frozen_index,frozen_bits,Info_index);
        
        % BP decoder
        lr_x = -2*receive_sample./(sigma^2);
        % decoding follow
        lr_u = zeros(1,N); % save send sample LR in each iteration
        frozen_index_0 = find(frozen_bits == 0);
        frozen_index_1 = find(frozen_bits == 1);
        lr_u(reverse_index(n,Frozen_index(frozen_index_0))) = init_max;
        lr_u(reverse_index(n,Frozen_index(frozen_index_1))) = -init_max;
        
        receive_bits_BP = polarBP_decoder(n,lr_u,lr_x,max_iter,Info_index);
        
        % calculate BER and PER
        countSC = sum(receive_bits_SC ~= source_bit);
        if countSC ~= 0
            PerNumSC = PerNumSC + 1;
            BerNumSC = BerNumSC + countSC;
        end 
        
        countBP = sum(receive_bits_BP ~= source_bit);
        if countBP ~= 0
            PerNumBP = PerNumBP + 1;
            BerNumBP = BerNumBP + countBP;
        end
    end
    perSC(i) = PerNumSC/block_num;
    berSC(i) = BerNumSC/(K*block_num);
    perBP(i) = PerNumBP/block_num;
    berBP(i) = BerNumBP/(K*block_num);
end
semilogy(SNR,perSC,'k-+',SNR,berSC,'k-*',SNR,perBP,'b-+',SNR,berBP,'b-*');
xlabel('SNR in dB');
ylabel('BER and PER in dB');
title('Cascaded Polar Decoding');
legend('perSC','berSC','perBP','berBP');