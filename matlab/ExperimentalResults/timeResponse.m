
data=csvread("data/id000response.csv")
t=data(:,1);
incli=data(:,2);
motor=data(:,3);


fig=figure; hold on;grid on;

plot(t,incli);
plot(t,motor);

ylabel(' Position (rad)          Inclination (deg)      ');
xlabel('time (s)');
legend('Neck inclination', 'Motor position','Location','best');
saveas(fig,'fig/avgtimeResponse','epsc');


data=csvread("data/000response.csv")
t=data(:,1);
incli=data(:,2);
motor=data(:,3);


fig=figure; hold on;grid on;

plot(t,incli);
plot(t,motor);

ylabel(' Position (rad)          Inclination (deg)      ');
xlabel('time (s)');
legend('Neck inclination', 'Motor position','Location','best');
saveas(fig,'fig/avgtimeResponse','epsc');



