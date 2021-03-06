clear; close all;

dts=0.025;
z=tf('z',dts);
s=tf('s');

data=csvread("data/id/id000response.csv");
t=data(:,1);

fig=figure; hold on;grid on;
plot(t,data(:,5));

title("Plant input");
ylabel('Motor velocity (rad/s)');
xlabel('time (sec)');
% legend("System input","System output",'Location','best');
% ylim([-1.5 1.5]);
saveas(fig,'fig/idinput','epsc');

fig=figure; hold on;grid on;

plot(t,data(:,4));
title("Plant output");
ylabel('Neck inclination (deg)');
xlabel('time (sec)');
% legend("System input","System output",'Location','best');
% ylim([-1.5 1.5]);
saveas(fig,'fig/idoutput','epsc');


% datan=csvread("data/frasysnum200.csv");
% datad=csvread("data/frasysden200.csv");
datan=csvread("data/id/idsysnum000.csv");
datad=csvread("data/id/idsysden000.csv");

N=size(datan,2);
M=size(datad,2);


t=datan(:,1);
SZ=size(datan,1);


fig=figure; hold on;grid on;
plot(t,datan(:,2:N));
plot(t,datad(:,2:M));
ylabel('RLS parameter result');
xlabel('time (sec)');
legend('b_0', 'a_2', 'a_1', 'a_0','Location','best');
ylim([-1.5 1.5]);
saveas(fig,'fig/avgparameterConverge','epsc');

poles=[];
for i=1:SZ
poles=[poles, roots(datad(i,2:M))]; %#ok<*AGROW>
end



fig=figure;hold on;grid on;
plot(t,poles');
plot(t,datan(:,2:N));

ylabel('Model poles and gain');
xlabel('time (sec)');
legend('Pole 1', 'Pole 2', 'Gain','Location','best');
ylim([-1.5 1.5]);
saveas(fig,'fig/avgpoleConverge','epsc');

%figure;
%plot(imag(poles)');
%ylim([-1 1]);

sys=minreal( tf(mean(datan(100:SZ,2:N)),mean(datad(100:SZ,2:M)),dts) );
[z,p,k]=zpkdata(sys);
S2=zpk(z,round(p{1},3),k,dts);


fig=figure;hold on;
margin(sys);
margin(S2);
grid on;
legend('Average plant', 'Rounded poles plant', 'Location','best');
saveas(fig,'fig/avgsysBode','epsc');


fig=figure;hold on;
F=minreal (sys/(1+sys));
step(F);

step(feedback(S2,1));
grid on;
ylabel('Inclination (deg)');
xlabel('time (sec)');
legend('Average plant', 'Rounded poles plant', 'Location','best');
saveas(fig,'fig/avgsysTR','epsc');

