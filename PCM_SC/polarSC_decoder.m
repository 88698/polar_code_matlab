function r = polarSC_decoder(n,received_sample,sigma,frozen_idx,frozen_bits,info_index)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
received_bits = zeros(1,2^n);
N = 2^n;
mem_lr = zeros(N, n+1);
%����u1,u2�����Ӧ����Ȼֵ
for ii=0:1:n
    if ii==0
        mem_lr(:,n+1)=exp(-2*received_sample/sigma^2);
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
    received_bits(1) = 1;
end
% if the current bit 1 belongs to the frozen bit set
k= frozen_idx == 1;
received_bits(1) = frozen_bits(k); 

% reverse_index for 2
idx = dec2bin(1);
n_idx = length(idx);
for k=1:n-n_idx
    idx = strcat('0',idx);
end
reverse_idx = bin2dec(fliplr(idx))+1;
mem_lr(reverse_idx,1) = (mem_lr(reverse_idx-2^(n-1),2))^(1-2*received_bits(1)) * ...
            (mem_lr(reverse_idx,2));
% LL, Sep. 23, 2016
mem_lr(reverse_idx,1) = lr_limit(mem_lr(reverse_idx,1), mem_lr(reverse_idx-2^(n-1),2), mem_lr(reverse_idx,2),1);
if mem_lr(reverse_idx,1) < 1
    received_bits(2) = 1;
end
% if the current bit 1 belongs to the frozen bit set
k= frozen_idx == 2;
received_bits(2) = frozen_bits(k);
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
         vec_odd = received_bits(1:2:j);
         vec_even = received_bits(2:2:j);
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
        received_bits(j+1) = 1;
     end
     k=find(frozen_idx == (j+1));
     if size(k) ~= 0
        received_bits(j+1) = frozen_bits(k);
     end
     %����u(j+2)
     mem_lr(node_idx(2,1),1) = (mem_lr(node_idx(1,2),2))^(1-2*received_bits(j+1)) * ...
             (mem_lr(node_idx(2,2),2));
     % LL, Sep. 23, 2016
     mem_lr(node_idx(2,1),1) = lr_limit(mem_lr(node_idx(2,1),1), mem_lr(node_idx(1,2),2), mem_lr(node_idx(2,2),2),1);
     if mem_lr(node_idx(2,1),1) < 1
        received_bits(j+2) = 1;
     end
     k=find(frozen_idx == (j+2));
     if size(k) ~= 0
        received_bits(j+2) = frozen_bits(k); 
     end
end
% ��u1,u2�����Ӧ����Ȼֵ�������
r = received_bits(info_index);
% info_lr = mem_lr(reverse_index(n,info_index),1);