% test the geometry of the corridor with lines and circles

%% parameters
distance_from_screen    = 5;
mouse_height            = 1;  % height of mouse above bottom of screen

screen_width            = 30;
screen_height           = 18;

corridor_width          = 5;  % virtual corridor width
corridor_above          = 5;
corridor_below          = -1;

circle_distance         = 6;  % can be vector of values of circle distance along corridor (0=mouse)
circle_height           = -0.5:1:4.5;  % vector of values of circle height above/below mouse
circle_radius           = 0.5;  % scalar


%% init

% parametrization of circles
t_circle = 0:0.01:2*pi;

% lines of top and bottom of corridor
x_line = 0:screen_width;
y_line_up = mouse_height + corridor_above*x_line/(sqrt(2)*corridor_width);
y_line_down = mouse_height + corridor_below*x_line/(sqrt(2)*corridor_width);


%% plot

figure
hold on

% corridor
plot(x_line, y_line_up)
plot(x_line, y_line_down)
plot(-x_line, y_line_up)
plot(-x_line, y_line_down)

% circles
for i = 1 : length(circle_distance)
    for j = 1 : length(circle_height)
        x_circle = 2*corridor_width*distance_from_screen./(corridor_width + circle_distance(i) + circle_radius*cos(t_circle));
        y_circle = mouse_height + (circle_height(j)+circle_radius*sin(t_circle))*sqrt(2)*distance_from_screen./(corridor_width + circle_distance(i) + circle_radius*cos(t_circle));
        plot(x_circle, y_circle)
        plot(-x_circle, y_circle)
    end
end

% set axes
xlim([0, screen_width])
ylim([0, screen_height])
set(gca, 'dataAspectRatio', [1, 1, 1])



