%Ҫ֤������3�Ƿ������ֻҪ֤�����һ�е���Ȼֵ�Ƿ��Ѿ������
clc;clear;
Np=9;
mem_lr = zeros(2^Np, Np+1);
for n=0:1:Np
    for j=1:1:2^(Np-n)
        mem_lr(2^n*(j-1)+1,Np+1-n) =1;
    end
end
mem_lr(2^(Np-1)+1,1)=1;

for j=2:2:(2^Np-2)
   idx2 = dec2bin(j);
   n_idx2 = length(idx2);
   for k=1:Np-n_idx2
       idx2 = strcat('0',idx2);
   end
   reverse_idx = bin2dec(fliplr(idx2))+1;
   node_idx = zeros(2^Np,Np+1);
   node_idx(1,1) = reverse_idx;
   node_idx(2,1) = reverse_idx+2^(Np-1);
   temp=0;
   for jj=2:1:Np+1 
        for jjj=1:1:2^(jj-2)
             %�ж�ǰ�󼶽ڵ�֮��Ĺ�ϵ�ķ�����������ppt���Ѹ���
             if mod(floor((node_idx(jjj,jj-1)-1)/2^(Np-jj+1)),2)==0
                  node_idx(2*jjj-1,jj) = node_idx(jjj,jj-1);
                  node_idx(2*jjj,jj) = node_idx(jjj,jj-1)+2^(Np-jj+1);
                  mem_lr(node_idx(2*jjj-1,jj),jj)=1;
                  mem_lr(node_idx(2*jjj,jj),jj)=1;
             else
                  temp=1;
                  node_idx(2*jjj-1,jj) = node_idx(jjj,jj-1)-2^(Np-jj+1);
                  node_idx(2*jjj,jj) = node_idx(jjj,jj-1);
             end
        end
        if temp==1 %��Ϊ���µ�����ǰ���ѱ������������ѭ��
            break
        end
   end
   k=jj;
   x=1;
   for jjj = 1:1:2^(k-1)
       if mem_lr(node_idx(jjj,k),k)==0
           x=0;
       end
   end
   if x==0
       break;
   end
end
if x==1
   disp('����Npֵ������3����ȷ�ġ�');
else
   disp('����Npֵ������3�Ǵ���ġ�');
end