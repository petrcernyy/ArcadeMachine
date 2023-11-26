clc
clear all
%% definice
m_1=0.059; %[kg] 59g
m_2=0.013; %[kg] 13g
L=0.253;   %[m]  253mm
L_t=0.135; %[m]  135mm
a=0.050;   %[m]  50mm
b=0.018;   %[m]  18mm
a_t=0.09;  %[m]  9mm
%% vypocet
I_1_t=(1/12)*m_1*L^2;
I_1=I_1_t+m_1*L_t^2;

I_2_t=(1/12)*m_2*(a^2+b^2);
I_2=I_2_t+m_2*a_t^2;

I=I_1+I_2 %[kg.m2]
