%% ��ʼ��
path = '.\\Apr\\img2\\';
img_files = dir([path '*.jpg']);
seq_len = length(img_files(not([img_files.isdir])));
% �õ�ͼƬ��
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
%% ����
T(1) = 0.20;
figure
im_handle = imagesc(uint8(img{1}));
last_pos = [161, 165]; % ��ǰ֡λ��
width = 8;
height = 8;
rect_pos = [last_pos(2)-width/2 last_pos(1)-height/2 width height];
rect_handle = rectangle('Position',rect_pos,'LineWidth',2,'EdgeColor','r');
tex_handle = text(5, 18, strcat('#',num2str(1)), 'Color','y', 'FontWeight','bold', 'FontSize',20);
drawnow;
v_last = [0 0];
v = v_last;
DEBUG = 0;
r = 20; % ���ٳ�ʼ���뾶
lost = 0;
for nums=2:seq_len

    delta = abs(img2hsv2{nums}(:, :, 1) - T(1)); % ����H����
    delta(delta > 0.5) = 0.5 - delta(delta > 0.5); % ��������
    d_intensity = abs(img2hsv2{nums}(:, :, 3)-T(3));
    d_chroma = sqrt(img2hsv2{nums}(:,:,2).^2+T(2).^2-2.*img2hsv2{nums}(:,:,2).*T(2).*cos(delta));
    d_cylin = sqrt(d_intensity.^2+d_chroma.^2); % �������վ���

    temp = zeros(size(d_cylin)); % ��Ŷ�ֵ�����

    temp(d_cylin > T(1)) = 0;
    temp(d_cylin < T(1)) = 1;
    temp(1:60, 1:end) = 0;

    temp = 1 - temp;
    se = strel('disk', 1);
    BW = imclose(temp, se); % ��ȡ���ܵ�
    [L, num] = bwlabel(BW, 8); % ��ͨ����

    t = zeros(1, num);
    pos = zeros(num, 2);
    count = 0;
    for i=1:num
        [row, col, vv] = find(L==i);
        if length(vv) > 4 && length(vv) < 30
            count=count+1;
            pos(count,:) = [int16(mean(row)), int16(mean(col))]; % ������ͨ�������������
        else
                L(L==i) = 0;
        end
    end
    f = 0; % �߼����� ������֡�Ƿ���ٵ�Ŀ��

    pre_pos = [last_pos(1)+v(1) last_pos(2)+v(2)]; % �����ٶ�Ԥ��λ��
    ret = pos(1:count, :) - repmat(pre_pos, count, 1); % ����Ԥ��λ�����������ĵ�
    ret = sqrt(ret(:,1).^2+ret(:,2).^2); % �������
    
    v_last = v;
    k = find(ret==min(ret)); % Ѱ�ҿ��ܵ�λ��
    if isempty(ret) % ���û���ҵ����ܵ�λ�� ֱ����ת��δ�ҵ�����
        k(1) = 1;
        ret(k(1)) = r+5;
    end
    v = [pos(k(1),1)-last_pos(1) pos(k(1),2)-last_pos(2)]; % �����ٶ�v
    
    % ����ʧһ���Ժ� �����ʵ��Ŵ�����
    if ret(k(1)) < r + lost*5 % �����������
        update_pos = [pos(k(1),1) pos(k(1),2)];
        last_pos = update_pos; % 
        f = 1;
        lost = 0;
    else % δ�ҵ�
        v = v_last;
        last_pos = pre_pos;
        lost = min([3 lost+1]);
    end
    set(im_handle, 'CData', img{nums});
    if f % ֻ�е��ҵ��Ժ�Ÿ���     
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