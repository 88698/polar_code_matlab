clc; clear;

% LL, Sep. 23, 2016
% take care of the numerical limit, limit LR value
block=1000;
SNR=4;
snr=10.^(SNR/10);
% code length 2^n
n = 8;
% code rate
R = 1/2;
N=2^n;
K=floor(N*R);
NF=N-K;
S = block*K; % source bit length
F = block*NF;% frozen bit length
SF= block*N; % total bit length
% get encoding matrix G
G = encoding_matrix2(n); 
% encoding matrix for information bit
Gi = zeros(K,N);
% encoding matrix for frozen bit
Gf = zeros(NF,N);
FER=zeros(1,length(SNR));
err_rate=zeros(1,length(SNR));
% reinitialize RANDI every time
rng('shuffle');
for i=1:length(SNR)
    
    % source bit streams
    source_bits = randi([0 1], 1, S); % Source bit stream
    % frozen bits stream
    frozen_bits = randi([0 1], 1, F);
    
    % encoded bits
    encoded_bits = zeros(1, SF);
    received_sample = zeros(1, SF);
    received_bits = zeros(1, SF);
    % decoded bits: the same length as soure length
    decoded_bits = zeros(1,S);
    % decoding memory blocks: each column has 2^Np LRs
    mem_lr = zeros(N, n+1);

    % error probability assuming AWGN channel with BPSK
    p = qfunc((snr(i))^0.5); 

    noise = snr(i)^(-0.5)*randn(1,SF);
    
    % Polar encoding process
    era=0;
    bec_flag=0;
%     [coding_idx,frozen_idx]=coding_index(SNR(i),n,R,era,bec_flag);
    % LL, Sep. 20, 2016. Loading coding_idx and frozen_idx from file
    load('./block_256/Pe_snr3p0db_2048_n_8.mat');
    [Ps,I] = sort(P);
    coding_idx = I(1:K);
    frozen_idx = I(K+1:end);
    coding_idx= sort(coding_idx);
    frozen_idx = sort(frozen_idx);
    
    % (5) form the encoding matrix for information bits
    Gi = G(coding_idx,:);
    % (6) form the encoding matrix for frozen bits
    Gf = G(frozen_idx,:);
    % encoding the source bits: 
    % source bits are divided into chunks of Np*R
    % frozen bits are divided into chunsk of Np*(1-R)
    for j=1:length(source_bits)/K
        encoded_bits(1,(j-1)*N+1:j*N) = source_bits((j-1)*K+1:j*K)*Gi...
            + frozen_bits((j-1)*NF+1:j*NF)*Gf;
    end
    % BPSK modulation
    encoded_bits=mod(encoded_bits,2);
    encoded_bits=2*encoded_bits-1;
    % received bits: noise is added
    received_sample = encoded_bits + noise;
    
   
    for r_idx = 1:block % each group of source bits
        mem_lr = zeros(N, n+1);
        %����u1,u2�����Ӧ����Ȼֵ
        for ii=0:1:n
            if ii==0
                for j=1:2^n
                    mem_lr(j,n+1)=exp(-2*received_sample((r_idx-1)*N+j)*snr(i));
                end
            else
                for j=1:2^(n-ii)
                    mem_lr(2^ii*(j-1)+1,n+1-ii) = (mem_lr(2^ii*(j-1)+1,n-ii+2) * mem_lr(2^ii*(j-1)+1+2^(ii-1),n-ii+2) + 1) / ...
                        (mem_lr(2^ii*(j-1)+1,n-ii+2) + mem_lr(2^ii*(j-1)+2^(ii-1)+1,n-ii+2));
                    % LL, Sep 23, 2016
                     mem_lr(2^ii*(j-1)+1,n+1-ii)  = lr_limit(mem_lr(2^ii*(j-1)+1,n+1-ii), mem_lr(2^ii*(j-1)+1,n-ii+2), mem_lr(2^ii*(j-1)+1+2^(ii-1),n-ii+2), 0);
                end
            end
        end
    
       
        if mem_lr(1,1) < 1
            received_bits((r_idx-1)*N+1) = 1;
        end
        % if the current bit 1 belongs to the frozen bit set
        k=find(frozen_idx == 1);
        received_bits((r_idx-1)*N+1) = frozen_bits((r_idx-1)*NF+1); 
        idx = dec2bin(1);
        n_idx = length(idx);
        for k=1:n-n_idx
            idx = strcat('0',idx);
        end
        reverse_idx = bin2dec(fliplr(idx))+1;
        mem_lr(reverse_idx,1) = (mem_lr(reverse_idx-2^(n-1),2))^(1-2*received_bits((r_idx-1)*N+1)) * ...
                    (mem_lr(reverse_idx,2));
        % LL, Sep. 23, 2016
        mem_lr(reverse_idx,1) = lr_limit(mem_lr(reverse_idx,1), mem_lr(reverse_idx-2^(n-1),2), mem_lr(reverse_idx,2),1);
        if mem_lr(reverse_idx,1) < 1
            received_bits((r_idx-1)*N+2) = 1;
        end
        % if the current bit 1 belongs to the frozen bit set
        k=find(frozen_idx == 2);
        received_bits((r_idx-1)*N+2) = frozen_bits((r_idx-1)*NF+k);
        % u1,u2�����Ӧ����Ȼֵ������� 
    
        %�����u1,u2�����Ӧ����Ȼֵ
        for j=2:2:(N-2) 
            idx2 = dec2bin(j);
            n_idx2 = length(idx2);
            for k=1:n-n_idx2
                idx2 = strcat('0',idx2);
            end
            reverse_idx = bin2dec(fliplr(idx2))+1;
            
            %ǰ�󼶽ڵ�֮��Ĺ�ϵ
            %�ж���Ȼֵ����Ҫ���е���һ�У��жϷ�����ͼƬ���Ѹ���
            node_idx = zeros(N,n+1);
            node_idx(1,1) = reverse_idx;
            node_idx(2,1) = reverse_idx+2^(n-1);
            temp=0;
            for jj=2:1:n+1 
                for jjj=1:1:2^(jj-2)
                    %�ж�ǰ�󼶽ڵ�֮��Ĺ�ϵ�ķ�����������ppt���Ѹ���
                    if mod(floor((node_idx(jjj,jj-1)-1)/2^(n-jj+1)),2)==0
                        node_idx(2*jjj-1,jj) = node_idx(jjj,jj-1);
                        node_idx(2*jjj,jj) = node_idx(jjj,jj-1)+2^(n-jj+1);
                    else
                        temp=1;
                        node_idx(2*jjj-1,jj) = node_idx(jjj,jj-1)-2^(n-jj+1);
                        node_idx(2*jjj,jj) = node_idx(jjj,jj-1);
                    end
                end
                if temp==1 %��Ϊ���µ�����ǰ���ѱ������������ѭ��
                    break
                end
            end
            k=jj;
            
            %ָ����ļ���
            %ָ����ļ���ķ�����ppt���Ѹ���
            %�����һ�м��㵹���ڶ��е���Ȼֵ
            for jjj = 1:1:2^(k-2)
                 vec_odd = received_bits(((r_idx-1)*N+1):2:((r_idx-1)*N+j));
                 vec_even = received_bits(((r_idx-1)*N+2):2:((r_idx-1)*N+j));
                 idx1 = dec2bin(node_idx(jjj,k-1)-1);
                 n_idx1 = length(idx1);
                 for kk=1:n-n_idx1
                     idx1 = strcat('0',idx1);
                 end
                 %0��1�ֱ��Ӧ��Ӧ�Ĳ�����ppt���Ѹ���
                 for kk=1:1:k-2
                     if idx1(kk)=='0'
                          vec_sum = (vec_odd ~= vec_even);
                     else
                          vec_sum = vec_even;
                     end
                     vec_odd=vec_sum(1:2:length(vec_sum));
                     vec_even=vec_sum(2:2:length(vec_sum));
                 end
                 %Arikan����Ȼֵ���ƹ�ʽ
                 vec_bit=vec_sum(end);
                 mem_lr(node_idx(jjj,k-1),k-1)= (mem_lr(node_idx(2*jjj-1,k),k))^(1-2*vec_bit) * ...
                     (mem_lr(node_idx(2*jjj,k),k));
                 % LL, Sep. 23, 2016
                 mem_lr(node_idx(jjj,k-1),k-1) = lr_limit(mem_lr(node_idx(jjj,k-1),k-1), mem_lr(node_idx(2*jjj-1,k),k),mem_lr(node_idx(2*jjj,k),k),1);
            end
             %�����һ�м��㵹���ڶ��е���Ȼֵ����
             
             %�ӵ����ڶ��м��㵽��һ�е���Ȼֵ
             for jj=(k-1):-1:2
                 for jjj = 1:1:2^(jj-2)
                      mem_lr(node_idx(jjj,jj-1),jj-1) = (mem_lr(node_idx(2*jjj-1,jj),jj) * mem_lr(node_idx(2*jjj,jj),jj) + 1) / ...
                     (mem_lr(node_idx(2*jjj-1,jj),jj) + mem_lr(node_idx(2*jjj,jj),jj));
                 % LL, Sep. 23, 2016
                 mem_lr(node_idx(jjj,jj-1),jj-1) = lr_limit(mem_lr(node_idx(jjj,jj-1),jj-1),mem_lr(node_idx(2*jjj-1,jj),jj), mem_lr(node_idx(2*jjj,jj),jj),0);
                 end
             end
             %�ӵ����ڶ��м��㵽��һ�е���Ȼֵ
             
             %�ж�u(j+1)
             if mem_lr(node_idx(1,1),1) < 1
                received_bits((r_idx-1)*N+j+1) = 1;
             end
             k=find(frozen_idx == (j+1));
             if size(k) ~= 0
                received_bits((r_idx-1)*N+j+1) = frozen_bits((r_idx-1)*NF+k); 
             end
             %����u(j+2)
             mem_lr(node_idx(2,1),1) = (mem_lr(node_idx(1,2),2))^(1-2*received_bits((r_idx-1)*N+j+1)) * ...
                     (mem_lr(node_idx(2,2),2));
             % LL, Sep. 23, 2016
             mem_lr(node_idx(2,1),1) = lr_limit(mem_lr(node_idx(2,1),1), mem_lr(node_idx(1,2),2), mem_lr(node_idx(2,2),2),1);
             if mem_lr(node_idx(2,1),1) < 1
                received_bits((r_idx-1)*N+j+2) = 1;
             end
             k=find(frozen_idx == (j+2));
             if size(k) ~= 0
                received_bits((r_idx-1)*N+j+2) = frozen_bits((r_idx-1)*NF+k); 
             end
        end
        % ��u1,u2�����Ӧ����Ȼֵ�������
        for jj=1:K
            decoded_bits((r_idx-1)*K+jj) = received_bits((r_idx-1)*N+coding_idx(jj));
        end
        x=0;
        for jj=1:K
            if decoded_bits((r_idx-1)*K+jj) ~= source_bits((r_idx-1)*K+jj)
                x=1;
            end
        end
        FER(i)=FER(i)+x;
    end
    err_rate(i) = sum((source_bits ~= decoded_bits))/S;
    FER(i)=FER(i)/block;
    i
end

err_rate
FER
