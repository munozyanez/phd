clear;close all;s=tf('s');
dts=0.01;
z=tf('z',dts);


%This file tunes a fractional controller based on the following:
%%%%%%%%%%%% controller specification
wgc=1;pm=110;Ts=dts;caso=1; %
dsys=1/ ( s );

%%%%%%%%%%%


%jw array
r0=2; N = 1000; Nm=fix(N/2);
w=logspace(-r0+log10(wgc),r0+log10(wgc),(N));
jw = 1i*w;
dg=1;ng=2;


exp=-1.4;
s1=jw.^exp;

fig=figure;hold on;
l1=['Normal loop gain'];
cbode(s1,w);

for g=1+dg:dg:1+dg*ng
    cbode(s1*g,w);
    l1=[l1; ['Loop gain * ' num2str(g,'%.2f')]];
    cbode(s1/g,w);
    l1=[l1; ['Loop gain / ' num2str(g,'%.2f')]];

end
grid on;

legend(l1, 'Location','best');

subplot(2,1,1)
subplot(2,1,2)

saveas(fig,'fig/s1Bodes','epsc');



% weights=[1:N/2 N/2:-1:1]./(0.5*N); %center
weights=[zeros(1,N/4) 1:N/4 N/4:-1:1 zeros(1,N/4)]./(0.5*N); %center sharp
% weights=[1:N/4 N/4:-1:1 zeros(1,N/2)]./(0.5*N); %low freqs
%weights=[zeros(1,N/2) 1:N/4 N/4:-1:1 ]./(0.5*N); %high freqs

appo=10;
warning ('off','all');
[Cn, Cd]=invfreqs(s1,w,appo+fix(exp),appo,weights)%,100);
warning ('on','all');
S1=minreal(tf(Cn,Cd));

% fig=figure;hold on;
% bode(S1);



% figure;hold on


fig=figure;hold on;
tstep=20%/sqrt(wgc);
% t=0:Ts:tstep;
% lsim(H,ones(size(t)),t)
%dg=0.2;ng=3;
l1=['Normal loop gain'];
step(feedback(S1,1));
for g=1+dg:dg:1+dg*ng
    step(feedback(S1*g,1));
    l1=[l1; ['Loop gain * ' num2str(g,'%.2f')]];
    step(feedback(S1/g,1));
    l1=[l1; ['Loop gain / ' num2str(g,'%.2f')]];

end
grid on;
legend(l1, 'Location','best');

saveas(fig,'fig/s1timeResps','epsc');



% sys = exp(-dsys.InputDelay*jw).*polyval(dsys.Numerator{1},jw)./polyval(dsys.Denominator{1},jw);
% figure;cbode(sys,w);
% 
% 
% 
% %find system phase and slope
% dm=1; %width of array positions to include in slope calculation
% %ps=angle(sys(Nm))*180/pi;
% ps = mod(angle(sys(Nm))*180/pi, -360);
% m= - ( angle(sys(Nm+dm))-angle(sys(Nm-dm)) ) / ( log10(w(Nm+dm))-log10(w(Nm-dm)) );
% 
% %find required controller phi
% phi=-180+pm-ps; %phase required at new frequency
% % if (ps>0)
% % ps=ps-360;
% % else
% % phi=-180+pm-ps; %phase required at new frequency
% % end
% 
% 
% 
% tgp=tan(phi*pi/180);
% 
% %find exponent
% ed=0.01:0.01:2;
% % ed=-ed;%for negative exponents
% ms=zeros(size(ed));
% a=ed(1)*pi/2;ms(1)=log(10)*ed(1)*(1-tgp/tan(a))*0.5/csc(2*phi*pi/180); %(tgp+1/tgp);
% for i=2:size(ed,2)
%     a=ed(i)*pi/2;
%     %m1=-(log(10)*cos(a)*ed*tgp^2-log(10)*sin(a)*ed*tgp)/(sin(a)*tgp^2+sin(a))
%     m1=log(10)*ed(i)*(1-tgp/tan(a))*0.5/csc(2*phi*pi/180); %(tgp+1/tgp);
%     ms(i)=m1;
%     if(m1>m && m1>0)
%     %if(sign(ms(i)+m) ~= sign(ms(i-1)+m))
%     %if(abs(m1-m) < tol)
%         im=i-1;
%         break;
%     end
%     
% end
% 
% m*180/pi
% ps
% phi
% 
% alpha=ed(im);
% tx=1/(tgp/(sin(a)-tgp*cos(a)));
% taua=1/(tx*wgc^alpha);
% 
% one=ones(1,N);
% con=(one+taua*jw.^alpha);
% cs=con.*sys;
% k=1/abs(cs(Nm));
% %con=newk*con;
% 
% kp=k;
% ka=k*taua;
% 
% % kp=0.4671; ka=0.6120; alpha=0.4900;
% 
% kp_ka_alpha=[kp ka alpha]
% 
% % con=k*(1+taua*jw.^alpha);
% con=kp+ka*jw.^alpha;
% 
% cs=sys.*con;
% 
% figure;cbode(cs,w);
% %figure; step(ol/((lo+1)),20);
% %figure; step(ol/(lo+1),5);
% %SaveCurPlotUnitsTsize(5,"sysStep","time (s)","Postion (m)");
% 
% 
% %fig=figure;cbode(cs,w);
% %saveas(fig,'Loop Bode','epsc');
% 
% %clf()
% %figure;cbode(cs,w);
% %SaveCurPlotTsize(5,"isomBode");
% 
% 

function y = cbode(cfresp,freq)
    
% Magnitude
m = 20 * log10(abs(cfresp));
% Phase
phase = mod(angle(cfresp)*180/pi, -360);
%phase = angle(cfresp)*180/pi;
%phase = atan2(imag(cfresp),real(cfresp))*180/(2*pi);
hold on;
Nc = round(size(cfresp,2)/2);
ycenter = mod(angle( cfresp(Nc) )*180/pi, -360);
% Plot
subplot(2,1,1)
semilogx(freq,m);
grid on;
title("Bode Diagram",'FontSize',12);
ylabel('Magnitude (dB)','FontSize',12);

hold on;
subplot(2,1,2)
semilogx(freq,phase);
grid on
ylabel('Phase (deg)','FontSize',12);
xlabel('Frequency (rad/sec)','FontSize',12);
ylim([ycenter-90 ycenter+45])
%yticks([0 0.5 0.8 1])
y=0;

end