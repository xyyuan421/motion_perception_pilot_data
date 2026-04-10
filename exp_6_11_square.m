% pilot 6/11 adjust center(square shape) to a given location, active intervention(turn dial)
% parameters
% 1) hyperparameters:e
%   Stimuli:
%       v_dist: view distance(cm)   
%       ndots_p: density of center dots(number of dots/s quare   area(°*°))
%       ndots_ring_p: density of surround dots  
%       mon_width: width of monitor(cm) 
%       direction_surround: directions of surround dot(  °)
%       repetition: repetition times per combination condition & retinal motion
%       res_screen1: resolution of 1st screen(large one for experiment) 
%       res_screen2: resolution of 2nd screen(small one)
%       dot_size_deg: diameter of dot(°)
%       center_patch_radius_deg: radius of center patch(°)
%       innerR: radius of inner ring(°) 
%       fix_r: half fixation width(pixels)
%       fix_fram: number of fixation frames 
%       stimuli_time: duration of stimuli(s) 
%       conds_angs: angles between center and surround directions(°) 
%       speed_surround_peak: peak speed of surround(°/s) 
%       ecc: eccentriciy of the stimulus(°) 
%       iti: inter-trial interval
%   Response:
%       angle_inc_coarse: angle increment of pointer for one key press(°)
%       width: width of arrow head(pixels)
% 2) condition parameters:
%       latencies: latency between center and surround motion reversals(frames)
%       outerR: radius of outer ring(°)+
%       block_id: 1=report center; 2= report surround
%       blocks: how many blocks in total(2*n, n is a factor of repetition *
%       length(directioin_surround) * 2(larger/smaller surround)) 

AssertOpenGL;
waitframes = 1;
Screen('Preference', 'SkipSyncTests', 1);
try
    %% open screen and hyperparameters setting  
    screens=Screen('Screens');
    screenNumber=max(screens);
    resolution = Screen('Resolution', screenNumber);
    res_screen1=[2560,1440];
    res_screen2=[2048,1152];
    rec_screen = [3024, 1964]/3;
    %[w, rect] = Screen('OpenWindow', screenNumber, 0,[ res_screen1(1),0,res_screen1(1)+res_screen2(1),res_screen2(2)]);
    [w, rect] = Screen('OpenWindow', screenNumber, 0, [0,0,rec_screen(1),rec_screen(2)]);
    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    fps=Screen('FrameRate',w);      % frames per second
    ifi=Screen('GetFlipInterval', w);
    
    % set up hyperparameters  
    v_dist = 50;   % viewing distance (cm)
    mon_width = 60; %width of monitor(cm)
    direction_surround = [0,45,90,135,180,-45,-90,-135];
    %target_directions = [0,90,180,-90];
    direction_surround = [0:20:340]';
    %direction_surround = [0,20];
    repetition = 5;
    repetition_control = 3;
    ppd = 1*(rect(3)-rect(1)) / (2*atand((mon_width/2)/v_dist));
    dot_size       = 0.2 * ppd;  % width of dot (pixel) 
    center_patch_radius_deg = 2;
    center_patch_radius =  center_patch_radius_deg* ppd; % radius of center patch (pixel)
    innerR_deg = 2;
    innerR= innerR_deg*ppd;
    outerR_deg = 4;
    outerR = outerR_deg * ppd;
    generate_R_deg = 2* outerR_deg;
    generate_R = generate_R_deg * ppd;
    ndots_p = 5;
    ndots_ring_p = 5;
    ndots_ring = round(ndots_ring_p * generate_R_deg^2);
    ndots = round(ndots_p * generate_R_deg^2);
    fix_r = 0.1*ppd;
    fix_fram = 0.5 * fps; % fixation frames  
    stimuli_time = 1.5; % s(half a cycle)
    stimuli_frame = stimuli_time * fps;
    conds_angs=[-45,-20,-10,-5,-2.5,-0.1,0,2.5,5,10,20,45]; % relative directions of the center dots
    %conds_angs = [-20,20]; 
    %conds_angs = [-45,-20,-10,-5,-2.5,-0.1];
    speed_surround_peak = 2;
    ecc =7;
    iti = 0.15; % inter trial interval (500ms) 
    center_border_color = [255,0,0];
    surround_border_color = [0,255,0];
    
    % fixation coordinates
    [center(1), center(2)] = RectCenter(rect);
    fix_cord = [center-fix_r center+fix_r];
    new_center_right = [center(1) + ecc*ppd, center(2)];
    white = WhiteIndex(w);
    grey = 1/2 * white;
    aperture_shapes = {'square','circle','oval'};
    aperture_shape = 'square';
    % arrow parameters for response  
    angle_inc_coarse=0.5;   %Angle increment of pointer for one key press
    angle_inc_gain=2;
    angle_inc_fine=1;
    width  = 0.3*ppd;  % width of arrow head
    marker_offset=width+0.25*ppd;
    marker_cardinal_size=0.6*ppd;
    sc_width_px=rect(3)-rect(1);
    sc_height_px=rect(4)-rect(2);
    ann_start_r1=0.01*sc_width_px*0.5;
    ann_inner_r1=0.05*sc_width_px*0.5;
    ann_outer_r1=0.06*sc_width_px*0.5;
    ann_start_r2=0.06*sc_width_px*0.5;
    ann_inner_r2=0.2*sc_width_px*0.5;
    ann_outer_r2=0.2*sc_width_px*0.5;
    nc_pts_ang=[2:2:358];
    nc_pts_ang(nc_pts_ang==90 | nc_pts_ang==180 | nc_pts_ang==270)=0;
    nc_pts_ang=nc_pts_ang(:);
    nc_pts=(0.5*ann_inner_r2+marker_offset+marker_cardinal_size*0.5)*[cosd(nc_pts_ang),sind(nc_pts_ang)];
    
    
    %% set up condition parameters 
    cond_surround= [0,1]; % 0 = incoherent, 1 = coherent
    conds=cartprod(cond_surround,conds_angs, direction_surround); 
    conds = repmat(conds,repetition,1);
    %     conds4 = conds(randperm(size(conds,1)),:);
    blocks = 1;
    block_ids = randperm(blocks);
    velocity_surround = 2 * ppd /fps; % velocity of surround dot(pixel/ frame), 1°/s  e
    stimuli_frame_manipu =0.1*fps; % time between fixating and manipulatin  
    duration_achieve = 0.2*fps; %maitain 0.2m as horizontal 
    tolarance_dir = 5; % range of surrounding horizontal direction
    stimuli_frame = 1.5 * fps;
    width_target = fix_r;
    %% start experiment
    Screen('FillRect', w ,[0,0,0]);
    sc_width_px=rect(3)-rect(1); % screen width (pixel)
    sc_height_px=rect(4)-rect(2);% screen height (pixel) 
    %HideCursor; % Hide the mouse cursor 
    Priority(MaxPriority(w));
    DrawFormattedText(w,WrapString(['This is a motion direction estimation task,a pattern of moving random dots will be shown on the right of the screen, report direction of center dots and press "1" to continue.'],100),'center','center',white);
    vbl=Screen('Flip', w);
    KbStrokeWait
    for block_id = block_ids
        ListenChar(2);
        % pass condition parameters 
        conds4 = conds(randperm(size(conds,1)),:);
        conds4 = [conds4, NaN(size(conds4,1),1)];
        % instruction
        DrawFormattedText(w,WrapString(['Adjust the direction of center to the center of the ring'],100),'center','center',white);
        vbl=Screen('Flip', w);
        KbStrokeWait
        
        %record video  
        % outputVideo = VideoWriter('experiment.mov', 'MPEG-4'); % You can choose other formats
        % outputVideo.FrameRate = fps;
        % open(outputVideo);
        % trials loop start
        for trial = [1,2]%:size(conds4,1)
            if trial ==1
                control =1;
                dir_surround_final = 0;
                dir_surround_initial = dir_surround_final -90;
            else
                control = 0;
                dir_surround_final = 0;
                dir_surround_initial = dir_surround_final;
            end
            %direction = conds4(trial,2);
            direction = 45;
            f = 1;
            velocity_center = velocity_surround/cosd(direction);
            loc_center =generate_center_loc(ndots,generate_R);
            loc_ring = generate_annulus_loc(ndots_ring,generate_R);
            handle = PsychPowerMate('Open');
            dial_press=length(handle);
            if dial_press~=0
                [~, dialPos0] = PsychPowerMate('Get', handle);
            end
            resp_angle=round(360*rand());
            new_surround_loc = [center(1), center(2) - ecc*ppd];
            %dir_surround_final = conds4(trial,3); 
            
            dir_center_final = dir_surround_final + direction - 90;
            tic;
            delta_degree = [];
            % animation start           
            while true
                % img = Screen('GetImage', w);
                % % Write the captured frame to the video 
                % writeVideo(outputVideo, img);
                if f <= fix_fram
                    Screen('DrawDots',w, center, dot_size, [255,255,255]);
                    Screen('FillOval', w, uint8(white), fix_cord);
                    Screen('flip', w);
                    delta_degree(f) = 0;
                else
                    Screen('FillRect', w ,[0,0,0]);
                    %if mod(f-fix_fram,10) == 0
                        if dial_press~=0
                            [~, dialPos1] = PsychPowerMate('Get', handle);
                            resp_angle = resp_angle-4*angle_inc_coarse*(abs(dialPos1-dialPos0)).^angle_inc_gain*sign(dialPos1-dialPos0);
                            delta_degree(f) =- 4*angle_inc_coarse*(abs(dialPos1-dialPos0)).^angle_inc_gain*sign(dialPos1-dialPos0);
                            dialPos0=dialPos1;
                        else
                            delta_degree(f) = 0;
                        end
%                     else
%                         delta_degree(f) = 0;
%                     end
                    delta_degree_acc = sum(delta_degree);
                    dir_center = dir_center_final + delta_degree_acc;
                    new_center_loc = [ecc*ppd * cosd(delta_degree_acc), - ecc*ppd * sind(delta_degree_acc)]+center  ;
                    if control == 1
                        dir_surround = dir_surround_initial + delta_degree_acc;
                        new_surround_loc = new_center_loc ;

                    end
                    if control == 1
                        delta_surround = delta_degree_acc;
                    else
                        delta_surround = 0;
                    end
                    Screen('FillOval', w, uint8(white), fix_cord);
                    %Screen('FillOval', w, uint8(white), target_cord);    
                    %
                    % update location 
                    loc_center(1,:) = loc_center(1,:) + velocity_center * cosd(dir_center);
                    loc_center(2,:) = loc_center(2,:) - velocity_center * sind(dir_center);
                    loc_ring(1,:) = loc_ring(1,:) + velocity_surround * cosd(dir_surround);
                    loc_ring(2,:) = loc_ring(2,:) - velocity_surround * sind(dir_surround);
                    % update dots 
                    for i = 1:size(loc_center,2)
                        loc_center(:,i) = trans_original2rotate(loc_center(:,i), dir_center, 1);
                        if abs(loc_center(1,i)) > generate_R
                            loc_center(1,i) = - sign(loc_center(1,i))* generate_R;
                            loc_center(2,i) = unifrnd(-generate_R, + generate_R);
                        elseif abs(loc_center(2,i)) > generate_R
                            loc_center(2,i) =  - sign(loc_center(1,i))* generate_R;
                            loc_center(1,i) = unifrnd(-generate_R, + generate_R);
                        end
                    end
                    for i = 1:size(loc_center,2)
                        loc_center(:,i) = trans_original2rotate(loc_center(:,i), dir_center, 0);
                    end
                    color_center = repmat([255,0,0,255],ndots,1);
                    distancescenter = sqrt((loc_center(1,:)).^2 + (loc_center(2,:)).^2);
                    switch aperture_shape
                        case 'circle'
                            for i = 1:size(loc_center,2)
                                loc_center(:,i) = trans_original2rotate(loc_center(:,i), delta_degree_acc, 1);
                                if distancescenter(i) > center_patch_radius
                                    color_center(i,4) = 0; 
                                end
                                loc_center(:,i) = trans_original2rotate(loc_center(:,i), delta_degree_acc, 0);
                            end
                        case 'square'
                            for i = 1:size(loc_center,2)
                                loc_center(:,i) = trans_original2rotate(loc_center(:,i), delta_degree_acc, 1);
                                if abs(loc_center(1,i)) > center_patch_radius | abs(loc_center(2,i)) > center_patch_radius
                                    color_center(i,4) = 0;
                                end
                                loc_center(:,i) = trans_original2rotate(loc_center(:,i), delta_degree_acc, 0);
                            end
                    end
                    for i = 1:size(loc_ring,2)
                        loc_ring(:,i) = trans_original2rotate(loc_ring(:,i), dir_surround, 1);
                        if abs(loc_ring(1,i)) > generate_R
                            %loc_ring(1,i) = loc_ring(1,i) -  
                            %sign(loc_ring(1,i))* 2* outerR;   
                            loc_ring(1,i) =  - sign(loc_ring(1,i))* generate_R;
                            loc_ring(2,i) = unifrnd(-generate_R,  generate_R);
                        elseif abs(loc_ring(2,i)) > generate_R
                            %loc_ring(2,i) = loc_ring(2,i) -  
                            %sign(loc_ring(2,i))* 2* outerR;     
                            loc_ring(2,i) =  - sign(loc_ring(2,i))* generate_R;
                            loc_ring(1,i) = unifrnd(-generate_R,generate_R);
                        end
                    end
                    color_ring = repmat([0,255,0,255],ndots_ring,1);
                    distancesRing = sqrt(loc_ring(1,:).^2 + loc_ring(2,:).^2);
                    for i = 1:size(loc_ring,2)
                        loc_ring(:,i) = trans_original2rotate(loc_ring(:,i), dir_surround, 0);
                    end
                    switch aperture_shape
                        case 'circle'
                            for i = 1:size(loc_ring,2)
                                loc_ring(:,i) = trans_original2rotate(loc_ring(:,i), delta_surround, 1);
                                if distancesRing(i) >outerR | distancesRing(i) < innerR
                                    color_ring(i,4) = 0;
                                end
                                loc_ring(:,i) = trans_original2rotate(loc_ring(:,i), delta_surround, 0);
                            end
                        case 'square'
                            for i = 1:size(loc_ring,2)
                                loc_ring(:,i) = trans_original2rotate(loc_ring(:,i), delta_surround, 1);
                                if (abs(loc_ring(1,i)) < innerR& abs(loc_ring(2,i)) < innerR) |  abs(loc_ring(1,i)) > outerR| abs(loc_ring(2,i)) > outerR
                                    color_ring(i,4) = 0;  
                                end
                                loc_ring(:,i) = trans_original2rotate(loc_ring(:,i), delta_surround, 0);
                            end
                    end

                    % draw borders    
                    % rotated location       
                    vertices_center = [-1/2 * dot_size - center_patch_radius, - 1/2 * dot_size - center_patch_radius;
                         1/2 * dot_size + center_patch_radius, - 1/2 * dot_size - center_patch_radius;
                         1/2 * dot_size + center_patch_radius,  1/2 * dot_size + center_patch_radius;
                        - 1/2 * dot_size - center_patch_radius,  1/2 * dot_size + center_patch_radius];
                    vertices_surround_inner = [-1/2 * dot_size - innerR, - 1/2 * dot_size - innerR;
                         1/2 * dot_size + innerR, - 1/2 * dot_size - innerR;
                         1/2 * dot_size + innerR,  1/2 * dot_size + innerR;
                        - 1/2 * dot_size - innerR,  1/2 * dot_size + innerR];
                    vertices_surround_outer = [-1/2 * dot_size - outerR, - 1/2 * dot_size - outerR;
                         1/2 * dot_size + outerR, - 1/2 * dot_size - outerR;
                         1/2 * dot_size + outerR,  1/2 * dot_size + outerR;
                        - 1/2 * dot_size - outerR,  1/2 * dot_size + outerR];
                    center_rotated =trans_original2rotate(vertices_center', delta_degree_acc, 0); 
                    center_rotated = center_rotated' + new_center_loc; 
                    surround1_rotated = trans_original2rotate(vertices_surround_inner', delta_surround, 0);
                    surround1_rotated = surround1_rotated' + new_surround_loc;
                    surround2_rotated = trans_original2rotate(vertices_surround_outer', delta_surround, 0);
                    surround2_rotated = surround2_rotated' + new_surround_loc;
                    switch aperture_shape
                        case 'circle'
                            Screen('FrameOval', w,center_border_color, [new_center_loc- 1/2 * dot_size - center_patch_radius, new_center_loc + 1/2 * dot_size + center_patch_radius],4);
                            Screen('FrameOval', w,surround_border_color, [new_surround_loc - 1/2 * dot_size - outerR, new_surround_loc + 1/2 * dot_size + outerR],4);
                        case 'square'
                            %Screen('FrameRect', w, center_border_color,[new_center_loc - 1/2 * dot_size - center_patch_radius, new_center_loc + 1/2 * dot_size + center_patch_radius],4);
                            Screen('FramePoly', w,center_border_color,center_rotated,4); 
                            % Screen('FrameRect', w,surround_border_color, surround1_rotated,4);
                            Screen('FramePoly', w,surround_border_color, surround2_rotated,4);
                    end
                    Screen('DrawDots', w, loc_center, dot_size, color_center',new_center_loc,1);
                    Screen('DrawDots', w,loc_ring, dot_size, color_ring',new_surround_loc,1);
                    vbl=Screen('Flip', w);
                    
                end
                f = f+1;
                [a,b,keyCode] = KbCheck;
                keyCode = find(keyCode, 1);
                if a
                    resp=KbName(keyCode);
                    if iscell(resp)==1
                        resp=resp{1};
                    end
                    if resp == 'e'
                        crash=1;
                        KbReleaseWait();
                        ListenChar;
                        Screen('CloseAll');
                        break;
                    end
                    if keyCode == 88
                        t = toc;
                        RT(trial) = t;
                        conds4(trial,size(conds4,2)) = wrapTo180(dir_center);
                        break;
                    end
                    if resp == 'i'
                        break;
                    end
                end
                f_all(trial) = f;
            end
            f = 0;
            WaitSecs(iti);

%             while f < stimuli_frame  
%                 Screen('FillOval', w, [255,0,0], fix_cord);
%                 color_center = repmat([255,0,0,255],ndots,1);
%                 distancescenter = sqrt((loc_center(1,:)).^2 + (loc_center(2,:)).^2);
%                 for i = 1:size(loc_center,2)
%                     if distancescenter(i) > center_patch_radius
%                         color_center(i,4) = 0;
%                     end
%                 end
%                 color_ring = repmat([0,255,0,255],ndots_ring,1);
%                 distancesRing = sqrt(loc_ring(1,:).^2 + loc_ring(2,:).^2);
%                 for i = 1:size(loc_ring,2)
%                     if distancesRing(i) < innerR | distancesRing(i) > outerR
%                         color_ring(i,4) = 0;
%                     end
%                 end
%                 Screen('DrawDots', w, loc_center, dot_size, color_center',new_center_right,1);
%                 Screen('DrawDots', w,loc_ring, dot_size, color_ring',new_center_right,1);
%                 loc_center(1,:) = loc_center(1,:) + velocity_center * cosd(dir_center);
%                 loc_center(2,:) = loc_center(2,:) - velocity_center * sind(dir_center);
%                 loc_ring(1,:) = loc_ring(1,:) + velocity_surround * cosd(dir_surround);
%                 loc_ring(2,:) = loc_ring(2,:) - velocity_surround * sind(dir_surround);
%                 for i = 1:size(loc_center,2)
%                     loc_center(:,i) = trans_original2rotate(loc_center(:,i), dir_center, 1);
%                     if abs(loc_center(1,i)) > center_patch_radius
%                         loc_center(1,i) = - sign(loc_center(1,i))* center_patch_radius;
%                         loc_center(2,i) = unifrnd(-center_patch_radius, + center_patch_radius);
%                     elseif abs(loc_center(2,i)) > center_patch_radius
%                         loc_center(2,i) =  - sign(loc_center(1,i))* center_patch_radius;
%                         loc_center(1,i) = unifrnd(-center_patch_radius, + center_patch_radius);
%                     end
%                     loc_center(:,i) = trans_original2rotate(loc_center(:,i), dir_center, 0);
%                 end
%                 for i = 1:size(loc_ring,2)
%                     loc_ring(:,i) = trans_original2rotate(loc_ring(:,i), dir_surround, 1);
%                     if abs(loc_ring(1,i)) > outerR
%                         %loc_ring(1,i) = loc_ring(1,i) - sign(loc_ring(1,i))* 2* outerR;
%                         loc_ring(1,i) =  - sign(loc_ring(1,i))* outerR;
%                         loc_ring(2,i) = unifrnd(-outerR,  outerR);
%                     elseif abs(loc_ring(2,i)) > outerR
%                         %loc_ring(2,i) = loc_ring(2,i) - sign(loc_ring(2,i))* 2* outerR;
%                         loc_ring(2,i) =  - sign(loc_ring(2,i))* outerR;
%                         loc_ring(1,i) = unifrnd(-outerR, outerR);
%                     end
%                     loc_ring(:,i) = trans_original2rotate(loc_ring(:,i), dir_surround, 0);
%                 end
%                 vbl=Screen('Flip', w);
%                 f = f+1;
%             end
%             %response
%             while true
%                 Screen('FillOval', w, uint8(white), fix_cord);
%                 Screen('DrawLine', w, uint8(white), center(1)+marker_offset+0.5*ann_inner_r2,center(2),center(1)+marker_offset+0.5*ann_inner_r2+marker_cardinal_size,center(2),4);
%                 Screen('DrawLine', w, uint8(white), center(1)-marker_offset-0.5*ann_inner_r2-marker_cardinal_size,center(2),center(1)-marker_offset-0.5*ann_inner_r2,center(2),4);
%                 Screen('DrawLine', w, uint8(white), center(1),center(2)-marker_offset-0.5*ann_inner_r2-marker_cardinal_size,center(1),center(2)-marker_offset-0.5*ann_inner_r2,4);
%                 Screen('DrawLine', w, uint8(white), center(1),center(2)+marker_offset+0.5*ann_inner_r2,center(1),center(2)+marker_offset+0.5*ann_inner_r2+marker_cardinal_size,4);
%                 Screen('DrawDots', w, nc_pts', 0.05*ppd, [255,255,255,255], center, 1);
%                 Screen('DrawLine', w, [255,0,0], center(1),center(2),center(1)+0.5*ann_inner_r2*cosd(resp_angle),center(2)-0.5*ann_inner_r2*sind(resp_angle),4);
%                 head   = [center(1)+0.5*ann_inner_r2*cosd(resp_angle),center(2)-0.5*ann_inner_r2*sind(resp_angle)]; % coordinates of head
%                 points = head+[ [-width*sind(resp_angle),-width*cosd(resp_angle)];[width*sind(resp_angle),width*cosd(resp_angle)];[width*cosd(resp_angle),-width*sind(resp_angle)] ];
%                 Screen('FillPoly', w,[255,0,0], points,1);
%                 Screen('flip',w);
%                 if dial_press~=0
%                     [~, dialPos1] = PsychPowerMate('Get', handle);
%                     resp_angle = resp_angle-4*angle_inc_coarse*(abs(dialPos1-dialPos0)).^angle_inc_gain*sign(dialPos1-dialPos0);
%                     dialPos0=dialPos1;
%                 end
%                 [a,b,keyCode] = KbCheck;
%                 keyCode = find(keyCode, 1);
%                 if a
%                     resp=KbName(keyCode);
%                     if iscell(resp)==1
%                         resp=resp{1};
%                     end
%                     if keyCode == 89 | resp == "i"
%                         resp_angle = wrapTo180(resp_angle);
%                         conds4(trial,size(conds4,2)) = resp_angle;
%                         %conds3(trial_id,7) = 1;
%                         break;
%                     end
%                     if resp == 'e'
%                         crash=1;
%                         KbReleaseWait();
%                         ListenChar;
%                         Screen('CloseAll');
%                         break;
%                     end
%                     break;
%                 end
%             end
        % close(outputVideo);
        end
        % conds_all{block_id} = conds4;
        % RTs{block_id} = RT;  
    end
    ListenChar
    Screen('CloseAll');
catch er
    Priority(0);
    ShowCursor;
    sca;
    ListenChar
    rethrow(er);
end
function loc = generate_annulus_loc(num,outerR)
loc = unifrnd(-outerR,outerR,2,num);
end
function loc = generate_center_loc(num, centerR)
loc = unifrnd(-centerR,centerR,2,num);
end

function loc_after = trans_original2rotate(loc_before, theta, coo) % function to transform coordinate, loc_before is the [x,y] coordinate, theta is the pi/2  - rotational degree(moving direction), coo = 1:from normal to rotated
if coo == 1
%rotation_matrix = [sind(theta), -cosd(theta);cosd(theta), sind(theta)]; 
%rotation_matrix = [sind(theta), cosd(theta);cosd(theta), -sind(theta)];
rotation_matrix = [cosd(theta), -sind(theta);sind(theta), cosd(theta)];
elseif coo == 0
%rotation_matrix = inv([sind(theta), -cosd(theta);cosd(theta), sind(theta)]);
%rotation_matrix = inv([sind(theta), cosd(theta);cosd(theta), -sind(theta)]);
rotation_matrix = inv([cosd(theta), -sind(theta);sind(theta), cosd(theta)]);
end
loc_after = rotation_matrix*loc_before;

end
