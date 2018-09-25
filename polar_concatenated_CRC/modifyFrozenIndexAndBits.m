function [frozen_index,frozen_bits] = modifyFrozenIndexAndBits(frozen_index,frozen_bits,info_index,k,bits)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% modify frozenbits and informationbits before SC decoder;
%%% k: cascaded information bit length
%%% bits: correct decision bits ti help another polar now
frozen_index = [frozen_index info_index(1:k)];
frozen_bits = [frozen_bits bits(1:k)];