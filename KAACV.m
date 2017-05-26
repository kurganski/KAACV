function varargout = KAACV(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @KAACV_OpeningFcn, ...
                   'gui_OutputFcn',  @KAACV_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
function varargout = KAACV_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function KAACV_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;
guidata(hObject, handles);

% ��������� �������� � ������
handles.PlayPauseButton.CData = imread('Play.png');
handles.FrameBackButton.CData = imread('FrameBack.png');
handles.FrameForwardButton.CData = imread('FrameForward.png');

scr_res = get(0, 'ScreenSize');     % �������� ���������� ������
fig = get(handles.KAACV,'Position');  % �������� ���������� ����

% �������������� ����
set(handles.KAACV,'Position',[(scr_res(3)-fig(3))/2 (scr_res(4)-fig(4))/2 fig(3) fig(4)]);

toolboxes = ver();      % ��������� ������� ���������
warning('off','all');
matlab_version = toolboxes(1).Release;
matlab_version = str2double(matlab_version(3:6));
message_str = {};

if matlab_version < 2017    
    message_str = [ message_str;...
                    '���� ������ Matlab ���� ������ R2017a.';...
                    'Your Matlab version is lower than R2017a.'];
end  

CV = false;     % �������� ���������� Computer Vision System Toolbox
for i = 1:size(toolboxes,2) % ���������� �� �������

    if strcmp('Computer Vision System Toolbox',toolboxes(i).Name) == 1
        CV = true;
    end
end

ImPrTB = false;             % �������� ���������� Image Processing Toolbox
for i = 1:size(toolboxes,2) % ���������� �� ������� ��������

    if strcmp('Image Processing Toolbox',toolboxes(i).Name) == 1
        ImPrTB = true;
    end
end 

if ~ CV 
    message_str = [ message_str;...
                    '����������� ���������� "Computer Vision System Toolbox".';...
                    '"Computer Vision System Toolbox" is missing.'];
end

if ~ ImPrTB 
    message_str = [ message_str;...
                    '����������� ���������� "Image Processing Toolbox".';...
                    '"Image Processing Toolbox" is missing.'];
end
       
% �������� ����� ������
MethodMenu_Callback(hObject, eventdata, handles);

if ~isempty(message_str)    % ����� ���������
    questdlg([message_str; ...
        '...�� �� ��������� �����!';...
        '���������� ����� �������.' ;...
        '��� ����� �������, �������� ���������� � ��������!';
        '� ���������� ���������� ��� ����� ��� ����!';
        'Application will be closed. Good luck to you, buddy'],'KAACV','OK','modal');
    close(gcf);
    return;
end 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ���� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% "������� ����"
function OpenMenu_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%% ��������

if isempty(handles)            % ������ ������� ������� �������� fig ������ m  
    
    questdlg({  '�� ��������� ���� � ����������� *.fig ������ ���������� *.m.';...
                '������� "OK", � ��� ����� ������';
                'You have started a file with expansion *.fig instead of *.m.';
                'Press "OK" to make it OK'},...
                'KAACV','OK','modal');
    
    % ���� ������ � ����� ������, ���� �����, ����� ��������� ������
    if true      
        close(gcf);
        run('KAACV.m');
        return;
    end
end

warning('on','all');

% �������� ���� ��� ��������
if strcmp(handles.RussianLanguageMenu.Checked,'on')      % �� �����
    
    [FileName, PathName] = uigetfile(...
        {'*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        '����������� (*.jpg,*.tif,*.tiff,*.bmp,*.png)';...
        '*.avi;*,mj2;*.mpg;*.mp4;*.m4v;*.mov;*.wmv;*.ogg;*.asf;*.asx',...
        '����� (*.avi,*.mj2,*.mpg,*.mp4,*.m4v,*.mov,*.wmv,*.ogg,*.asf,*.asx)';...
        '*.*', 'All Files(*.*)'},...
        '�������� ���� ��� ���������',...
        [cd '\Test Materials']);
else
        [FileName, PathName] = uigetfile(...
        {'*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        'Image Files (*.jpg,*.tif,*.tiff,*.bmp,*.png)';...
        '*.avi;*,mj2;*.mpg;*.mp4;*.m4v;*.mov;*.wmv;*.ogg;*.asf;*.asx',...
        'Video Files (*.avi,*.mj2,*.mpg,*.mp4,*.m4v,*.mov,*.wmv,*.ogg,*.asf,*.asx)';...
        '*.*', 'All Files(*.*)'},...
        'Choose a file to process',...
        [cd '\Test Materials']);
end

if ~FileName        % ��������, ��� �� ������ ����
    return;
end

UserFile = struct('Video',[],'Image',[],'FrameRate',[]);   % �������� ������

try         % ������� ������� ��� ���������
    
    VideoObject = VideoReader([PathName FileName]); % �����������
    VideoInfo = readFrame(VideoObject);             % ������ ������ ����
    
    UserFile.Video = zeros(size(VideoInfo));        % ������� ������ ��� ���������
    
    frame = 1;                                      % ������� ������
    NumOfFrames = round(VideoObject.Duration * VideoObject.FrameRate);
    
    Wait = waitbar(0,'�������� �����','WindowStyle','modal');

    while hasFrame(VideoObject)                         % ���� ���� ����
        UserFile(frame).Video = readFrame(VideoObject); % ������ � ���������
        frame = frame+1;                                % ������� +
        waitbar(frame / NumOfFrames, Wait);             % ������ ���������
    end    
    
    delete(Wait);       % ������� �������� ����
    
    % ��������� ������ ���� � ���
    image(VideoInfo,'Parent',handles.FileAxes);
    handles.FileAxes.Visible = 'off';
    
    % ���������� �������� �����
    UserFile(1).FrameRate = VideoObject.FrameRate;
    
    % ������������� ������� ������
    handles.FrameSlider.Value = 1;
    handles.FrameSlider.Min = 1;
    handles.FrameSlider.Max = NumOfFrames;
    handles.FrameSlider.SliderStep = [1/(NumOfFrames-1) 10/(NumOfFrames-1)];
    
    % ��������� ������ ���������������
    set([...
        handles.PlayPauseButton;...
        handles.FrameBackButton;...
        handles.FrameForwardButton;...
        handles.FrameSlider;...
        ],'Visible','on');
    
catch       % �� ������ ������� ���������
    
    if exist('Wait','var')          % ���� ������������ ������ ���� ��������
        delete(Wait);               % ������� ����
        return;                     % ������� ������
    end
    
    try     % ������� ������� ��� �����������
        
        [Temp,colors] = imread([PathName FileName]);      
        
        if ~isempty(colors)
            Temp = ind2rgb(Temp,colors);    % ��������������� � RGB
        end  
        
        UserFile.Image = Temp;              % ���������� RGB
        
        % ��������� �����������
        imshow(UserFile.Image,'Parent',handles.FileAxes);
        
        set([...
            handles.PlayPauseButton;...
            handles.FrameBackButton;...
            handles.FrameForwardButton;...
            handles.FrameSlider;...
            ],'Visible','off');
        
    catch    % ��� �������� �������� �����������
        
        if strcmp(handles.RussianLanguageMenu.Checked,'on')     % ����
            h = errordlg('� ������ ���-�� �� ���. �������� ������','KAACV');
        else
            h = errordlg('File is improper. Choose another file','KAACV');
        end
        
        set(h, 'WindowStyle', 'modal');
        return;        
    end
end

% ���������/������������ ��� ������ ��������

set([...
    handles.ParametersPanel;...
    handles.MethodMenu;...
    handles.ApplyButton;...
    ],'Visible','on');

set([...
    handles.ShowFrameMenu;...
    ],'Enable','on');

% ��������� ������ �������� ����

setappdata(handles.FileAxes,'UserFile',UserFile);





% "�������� ����"
function ShowFrameMenu_Callback(hObject, eventdata, handles)


% "�������� ������"
function ShowPatternImageMenu_Callback(hObject, eventdata, handles)


% "������� ����"
function RussianLanguageMenu_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%% ��������

if isempty(handles)            % ������ ������� ������� �������� fig ������ m  
    
    questdlg({  '�� ��������� ���� � ����������� *.fig ������ ���������� *.m.';...
                '������� "OK", � ��� ����� ������'},...
                'KAACV','OK','modal');
    
    if true                    % ���� ������    
        close(gcf);
        run('KAACV.m');
        return;
    end
end

warning('on','all');

handles.RussianLanguageMenu.Checked = 'on';
handles.EnglishLanguageMenu.Checked = 'off';


% "ENGLISH LANGUAGE"
function EnglishLanguageMenu_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%% ��������

if isempty(handles)            % ������ ������� ������� �������� fig ������ m  
    
    questdlg({  'You have started a file with expansion *.fig instead of *.m.';...
                'Press "OK", to make it OK'},...
                'KAACV','OK','modal');    
    
    if true                 % ���� ������ 
        close(gcf);
        run('KAACV.m');
        return;
    end
end

warning('on','all');

handles.EnglishLanguageMenu.Checked = 'on';
handles.RussianLanguageMenu.Checked = 'off';


% ����� ������ ���������
function MethodMenu_Callback(hObject, eventdata, handles)

% ������ ��� ��������
set(handles.ParametersPanel.Children,'Visible','off');


% ����� ������������� �����
function VideoMenu_Callback(hObject, eventdata, handles)


% ���� � 1 ���������� 
function ParMenu1_Callback(hObject, eventdata, handles)


% ���� � 2 ���������� 
function ParMenu2_Callback(hObject, eventdata, handles)


% ���� � 3 ���������� 
function ParMenu3_Callback(hObject, eventdata, handles)


% ���� � 4 ���������� 
function ParMenu4_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ��������������� / �����
function PlayPauseButton_Callback(hObject, eventdata, handles)

% ������ �������� ������ � ��������� �������
if handles.PlayPauseButton.Value == 0
    handles.PlayPauseButton.CData = imread('Play.png');
    handles.FrameBackButton.Enable = 'on';
    handles.FrameForwardButton.Enable = 'on';    
    
else    
    
    handles.PlayPauseButton.CData = imread('Pause.png');
    handles.FrameBackButton.Enable = 'off';
    handles.FrameForwardButton.Enable = 'off';
    
    % ��������� ������� ������
    UserFile = getappdata(handles.FileAxes,'UserFile'); 
    FrameRate = UserFile(1).FrameRate;
    
    % ��������� �����
    for frame = handles.FrameSlider.Value : handles.FrameSlider.Max
        image(UserFile(frame).Video, 'Parent', handles.FileAxes);
        handles.FileAxes.Visible = 'off';
        handles.FrameSlider.Value = frame;  % ��������� ��������
 
        sec = mod(frame / FrameRate, 60);       % ������� � ���.
        min = (frame / FrameRate - sec) / 60;   % ���
        sec = round(sec);                       % ������� � ���.
        
        ShowTimeAndFrame(handles, frame, min, sec);
        
        pause(1/FrameRate);
        
        % ���� �������� �� �����
        if handles.PlayPauseButton.Value == 0   
            handles.PlayPauseButton.CData = imread('Play.png');
            handles.FrameBackButton.Enable = 'on';
            handles.FrameForwardButton.Enable = 'on';
            return;
        end
    end    
end


% ���������� ���� 
function FrameBackButton_Callback(hObject, eventdata, handles)

frame = handles.FrameSlider.Value - 1;  % ��������� ����

if frame < handles.FrameSlider.Min
    frame = handles.FrameSlider.Min;
end

FrameSlider_Callback(hObject, frame, handles)


% ��������� ����
function FrameForwardButton_Callback(hObject, eventdata, handles)

frame = handles.FrameSlider.Value + 1;  % ��������� ����

if frame > handles.FrameSlider.Max
    frame = handles.FrameSlider.Max;
end

FrameSlider_Callback(hObject, frame, handles)


% ���������
function ApplyButton_Callback(hObject, eventdata, handles)

% ����������, ��� ������� ���������� ��������: ��� �������
if handles.ApplyButton.Value == 1
    handles.ApplyButton.String = '�����������';
else
    handles.ApplyButton.String = '���������';
end


% ����� ������� ��������
function ROIButton_Callback(hObject, eventdata, handles)


% ������� ������
function PatternOpenButton_Callback(hObject, eventdata, handles)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%% �������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ������� ������ �����
function FrameSlider_Callback(hObject, eventdata, handles)

% ��������� �����
UserFile = getappdata(handles.FileAxes,'UserFile');

if ~isnumeric(eventdata)
    frame = round(handles.FrameSlider.Value);
else
    frame = eventdata;
end

handles.FrameSlider.Value = frame;      % ��������� ��������

image(UserFile(frame).Video, 'Parent', handles.FileAxes);
handles.FileAxes.Visible = 'off';
 
sec = mod(frame / UserFile(1).FrameRate, 60);       % ������� � ���.
min = (frame / UserFile(1).FrameRate - sec) / 60;   % ���
sec = round(sec);                                   % ������� � ���.

ShowTimeAndFrame(handles, frame, min, sec);         % �����������


% ������� ���������� � 1
function ParSlider1_Callback(hObject, eventdata, handles)


% ������� ���������� � 2
function ParSlider2_Callback(hObject, eventdata, handles)


% ������� ���������� � 3
function ParSlider3_Callback(hObject, eventdata, handles)


% ������� ���������� � 4
function ParSlider4_Callback(hObject, eventdata, handles)


% ������� ���������� � 5
function ParSlider5_Callback(hObject, eventdata, handles)


% ������� ���������� � 6
function ParSlider6_Callback(hObject, eventdata, handles)


% ������� ���������� � 7
function ParSlider7_Callback(hObject, eventdata, handles)


% ������� ���������� � 8
function ParSlider8_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ������ ���������� �� �����������
function StatisticsList_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%% ��������� ���� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function ROIx0_Callback(hObject, eventdata, handles)


function ROIy0_Callback(hObject, eventdata, handles)


function ROIx1_Callback(hObject, eventdata, handles)


function ROIy1_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%% ���-����� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function ParCheckBox1_Callback(hObject, eventdata, handles)


function ParCheckBox2_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ����������� ������� � ������ � ������� �������� �����
function ShowTimeAndFrame(handles, frame, min, sec)

if sec == 60            % ������ 59 ��� ��������
    sec = 0;
    min = min + 1;
end

% ��� �������� sprintf
handles.VideoInfo.String = ...
    [{[num2str(frame) ' ����']}; {[num2str(min) ':' num2str(sec)]}];









