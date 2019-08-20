%% 初始化
path = '.\\Apr\\img2\\';
img_files = dir([path '*.jpg']);
seq_len = length(img_files(not([img_files.isdir])));
% 得到图片名
if exist([path num2str(1, '%04d.jpg')], 'file'),
    img_files = num2str((1:seq_len)', [path '%04d.jpg']);
else
    error('No image files found in the directory.');
end

need_len = 125;
img = cell(size(img_files, 1), 1);
img2hsv = cell(need_len, 1);
img2hsv2 = cell(size(img_files, 1), 1);
imgT = cell(need_len, 1);

for i = 1:need_len
    img{i} = imread(img_files(i, :));
    img2hsv2{i} = rgb2hsv(img{i});
    img2hsv{i} = rgb2hsv(img{i}(floor(size(img{i}, 1)/2):end, :, :));
%     temp = [0 0 0 ];
%     for j=1:3
%         [counts, centers] = hist(reshape(img2hsv{i}(:,:,j), [], 1), 1000);
%         % 
%         peak = find(counts == max(counts));
%         for k=peak-1:-1:1
%             if counts(k) < 0.2*counts(peak)
%                 left = k;
%             end
%         end
%         for k=peak+1:length(counts)
%             if counts(k) < 0.2*counts(peak)
%                 right = k;
%             end
%         end
%         temp(j) = sum(counts(left:right)/sum(counts(left:right)).*centers(left:right));
%     end
%     imgT{i} = temp;
end
% ret = cell2mat(imgT);
% T = mean(ret);
for i=need_len+1:seq_len
    img{i} = imread(img_files(i, :));
    img2hsv2{i} = rgb2hsv(img{i});
end
ret = cellfun(@(x) [mean(mean(x(:,:,1))), mean(mean(x(:,:,2))), mean(mean(x(:,:,3)))], img2hsv, 'UniformOutput', 0);
T = mean(cell2mat(ret));
%% 测试
T(1) = 0.20;
figure
im_handle = imagesc(uint8(img{1}));
last_pos = [161, 165]; % 当前帧位置
width = 8;
height = 8;
rect_pos = [last_pos(2)-width/2 last_pos(1)-height/2 width height];
rect_handle = rectangle('Position',rect_pos,'LineWidth',2,'EdgeColor','r');
tex_handle = text(5, 18, strcat('#',num2str(1)), 'Color','y', 'FontWeight','bold', 'FontSize',20);
drawnow;
v_last = [0 0];
v = v_last;
DEBUG = 0;
r = 20; % 跟踪初始化半径
lost = 0;
for nums=2:seq_len

    delta = abs(img2hsv2{nums}(:, :, 1) - T(1)); % 计算H距离
    delta(delta > 0.5) = 0.5 - delta(delta > 0.5); % 修正距离
    d_intensity = abs(img2hsv2{nums}(:, :, 3)-T(3));
    d_chroma = sqrt(img2hsv2{nums}(:,:,2).^2+T(2).^2-2.*img2hsv2{nums}(:,:,2).*T(2).*cos(delta));
    d_cylin = sqrt(d_intensity.^2+d_chroma.^2); % 计算最终距离

    temp = zeros(size(d_cylin)); % 存放二值化结果

    temp(d_cylin > T(1)) = 0;
    temp(d_cylin < T(1)) = 1;
    temp(1:60, 1:end) = 0;

    temp = 1 - temp;
    se = strel('disk', 1);
    BW = imclose(temp, se); % 提取可能点
    [L, num] = bwlabel(BW, 8); % 连通区域

    t = zeros(1, num);
    pos = zeros(num, 2);
    count = 0;
    for i=1:num
        [row, col, vv] = find(L==i);
        if length(vv) > 4 && length(vv) < 30
            count=count+1;
            pos(count,:) = [int16(mean(row)), int16(mean(col))]; % 计算连通区域的中心坐标
        else
                L(L==i) = 0;
        end
    end
    f = 0; % 逻辑变量 表明该帧是否跟踪到目标

    pre_pos = [last_pos(1)+v(1) last_pos(2)+v(2)]; % 利用速度预测位置
    ret = pos(1:count, :) - repmat(pre_pos, count, 1); % 利用预测位置搜索附近的点
    ret = sqrt(ret(:,1).^2+ret(:,2).^2); % 计算距离
    
    v_last = v;
    k = find(ret==min(ret)); % 寻找可能的位置
    if isempty(ret) % 如果没有找到可能的位置 直接跳转到未找到处理
        k(1) = 1;
        ret(k(1)) = r+5;
    end
    v = [pos(k(1),1)-last_pos(1) pos(k(1),2)-last_pos(2)]; % 计算速度v
    
    % 当丢失一次以后 可以适当放大区间
    if ret(k(1)) < r + lost*5 % 距离过滤条件
        update_pos = [pos(k(1),1) pos(k(1),2)];
        last_pos = update_pos; % 
        f = 1;
        lost = 0;
    else % 未找到
        v = v_last;
        last_pos = pre_pos;
        lost = min([3 lost+1]);
    end
    set(im_handle, 'CData', img{nums});
    if f % 只有当找到以后才更新     
        rect_pos(1) = update_pos(2)-4;
        rect_pos(2) = update_pos(1)-4;
        set(rect_handle, 'Position', rect_pos);    
    else
        rect_pos(1) = last_pos(2)-4;
        rect_pos(2) = last_pos(1)-4;    
    end
    set(tex_handle, 'string', strcat('#',num2str(nums)))
    pause(0.001);
end