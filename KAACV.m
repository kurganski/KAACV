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

% ���������� ��������� ���������� ����
setappdata(handles.FileAxes,'InitPosition',handles.FileAxes.Position);

% ��������� �������� � ������
try
    handles.PlayPauseButton.CData = imread([cd '\Icons\Play.png']);
    handles.FrameBackButton.CData = imread([cd '\Icons\FrameBack.png']);
    handles.FrameForwardButton.CData = imread([cd '\Icons\FrameForward.png']);
    handles.ZoomButton.CData = imread([cd '\Icons\Zoom+.png']);
catch
end

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
       
% ������ ��� �������� ����� ���������� ������ ���������
set(handles.ParametersPanel.Children,'Visible','off');

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

% ���� ������� ���� ������, ����� 1
rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% �������� ���� ��� ��������
if rus
    
    [FileName, PathName] = uigetfile(...
        {'*.jpeg;*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        '����������� (*.jpeg,*.jpg,*.tif,*.tiff,*.bmp,*.png)';...
        '*.avi;*,mj2;*.mpg;*.mp4;*.m4v;*.mov;*.wmv;*.ogg;*.asf;*.asx',...
        '����� (*.avi,*.mj2,*.mpg,*.mp4,*.m4v,*.mov,*.wmv,*.ogg,*.asf,*.asx)';...
        '*.*', 'All Files(*.*)'},...
        '�������� ���� ��� ���������',...
        [cd '\Test Materials']);
else
        [FileName, PathName] = uigetfile(...
        {'*.jpeg;*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        'Image Files (*.jpeg,*.jpg,*.tif,*.tiff,*.bmp,*.png)';...
        '*.avi;*,mj2;*.mpg;*.mp4;*.m4v;*.mov;*.wmv;*.ogg;*.asf;*.asx',...
        'Video Files (*.avi,*.mj2,*.mpg,*.mp4,*.m4v,*.mov,*.wmv,*.ogg,*.asf,*.asx)';...
        '*.*', 'All Files(*.*)'},...
        'Choose a file to process',...
        [cd '\Test Materials']);
end

if ~FileName        % ��������, ��� �� ������ ����
    return;
end

% �������� ������
UserFile = struct('Data',[],'FrameRate',[]);   

try         % ������� ������� ��� ���������
    
    VideoObject = VideoReader([PathName FileName]); % �����������
    VideoInfo = readFrame(VideoObject);             % ������ ������ ����
    
    UserFile.Data = zeros(size(VideoInfo));        % ������� ������ ��� ���������
    
    FrameNumber = 1;                                      % ������� ������
    NumOfFrames = round(VideoObject.Duration * VideoObject.FrameRate);
    
    Wait = waitbar(0,'�������� �����','WindowStyle','modal');

    while hasFrame(VideoObject)                         % ���� ���� ����
        UserFile(FrameNumber).Data = readFrame(VideoObject); % ������ � ���������
        FrameNumber = FrameNumber+1;                                % ������� +
        waitbar(FrameNumber / NumOfFrames, Wait);             % ������ ���������
    end    
    
    delete(Wait);       % ������� �������� ����
    
    % ���������� �������� �����
    UserFile(1).FrameRate = VideoObject.FrameRate;            
    
    handles.FrameSlider.Min = 1;
    handles.FrameSlider.Max = size(UserFile,2);
    handles.FrameSlider.SliderStep = ...
        [1/(size(UserFile,2)-1) 10/(size(UserFile,2)-1)];
    
    % ��������� ������ ���������������
    set([...
        handles.PlayPauseButton;...
        handles.FrameBackButton;...
        handles.FrameForwardButton;...
        handles.FrameSlider;...
        handles.VideoFrameInfo;...
        handles.VideoTimeInfo;...
        ],'Visible','on');    
    
    set([...
        handles.SaveFrameMenu;...
        ],'Enable','on');
    
catch       % �� ������ ������� ���������
    
    if exist('Wait','var')          % ���� ������������ ������ ���� ��������
        delete(Wait);               % ������� ����
        return;                     % ������� ������
    end
    
    try     % ������� ������� ��� �����������
        
        [Temp,colors] = imread([PathName FileName]);      
        
        if ~isempty(colors)                 % ���� ��������������� -
            Temp = ind2rgb(Temp,colors);    % ��������������� � RGB
        end  
        
        UserFile.Data = Temp;               % ���������� ��������     
                
        set([...
            handles.PlayPauseButton;...
            handles.FrameBackButton;...
            handles.FrameForwardButton;...
            handles.FrameSlider;...
            handles.VideoFrameInfo;...
            handles.VideoTimeInfo;...
            ],'Visible','off');
        
        set([...
            handles.SaveFrameMenu;...
            ],'Enable','off');        
        
    catch    % ��� �������� �������� �����������
        
        if rus     % ����
            h = errordlg('� ������ ���-�� �� ���. �������� ������','KAACV');
        else
            h = errordlg('File is improper. Choose another file','KAACV');
        end
        
        set(h, 'WindowStyle', 'modal');
        return;        
    end
end

%%%%%%%%%%%%%%%%%%%%% ����� ��������

% ��������� ������ �������� ���� � ������ ���
setappdata(handles.FileAxes,'UserFile',UserFile);

% ������������� ������� ������    
MethodMenu_Callback(hObject, eventdata, handles);

% ���������/������������ ��� ������ ��������
set([...
    handles.ParametersPanel;...
    handles.MethodMenu;...
    handles.ApplyButton;...
    handles.ZoomButton;...
    ],'Visible','on');

set([...
    handles.ShowFrameMenu;...
    ],'Enable','on');

% ���������� ��� ��� ������� ������ � ���� ����� ��������� - ����� ������
if SetAxesSize(handles.FileAxes,size(UserFile(1).Data,1),size(UserFile(1).Data,2))
    handles.ZoomButton.Visible = 'on';
else
    handles.ZoomButton.Visible = 'off';
end

% ������ ������-��������, � ��������� ����� ���� ��������� CData
image(  UserFile(1).Data,...
        'Parent',handles.FileAxes,...
        'Tag', 'FrameObj');

% ��������� ���� ���������    
MethodMenuSetting(handles.MethodMenu, size(UserFile,2) > 1, rus);

handles.PlayPauseButton.Value = 0;      % ������ �� �����
handles.FrameSlider.Value = 1;          % ��������� �� �������� ����� ������� �����   
FrameSlider_Callback(hObject, eventdata, handles);


% "�������� �����/�����������"
function ShowFrameMenu_Callback(hObject, eventdata, handles)

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');

% ����������� ����
Image = UserFile(handles.FrameSlider.Value).Data;

% ������� ������� ��� ��� ���
try
    imtool(Image);              % ��� ������-������
catch
    OpenImageOutside(Image);    % ��� exe-������
end


% "��������� ����"
function SaveFrameMenu_Callback(hObject, eventdata, handles)

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');

% ����������� ����
Image = UserFile(handles.FrameSlider.Value).Data;
FrameNumber = handles.FrameSlider.Value;

if strcmp(handles.RussianLanguageMenu.Checked,'on')      % �� �����
    [FileName, PathName] = uiputfile(['���� � ' num2str(FrameNumber) '.png'],'��������� ����/�����������');
else
    [FileName, PathName] = uiputfile(['frame � ' num2str(FrameNumber) '.png'],'Save frame/image');
end

if FileName~=0
    imwrite(Image,[PathName FileName]);
end


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

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');
width = size(UserFile(1).Data,2);
heigth = size(UserFile(1).Data,1);

switch handles.MethodMenu.Value
    
    case 1      % ������������� ������
        
        set([...
            handles.ROIx0;...
            handles.ROIy0;...
            handles.ROIx1;...
            handles.ROIy1;...
            handles.ROIButton;...
            handles.ROIText;...
            ],'Visible','on');
        
        handles.ROIx0.String = num2str(1);
        handles.ROIy0.String = num2str(1);
        handles.ROIx1.String = num2str(width);
        handles.ROIy1.String = num2str(heigth);
        
        ROIButton_Callback(hObject, eventdata, handles);
        
        
    case 2      % ������ �����-����
        
    case 3      % ����� �������� � �������
        
    case 4      % ������ �����
        
    case 5      % ������������� ���
        
    case 6      % ������������� �����
        
    case 7      % ������������� ��������
        
    case 8      % �������� 3D-�����������
        
    case 9      % ��������� �����
        
    case 10     % �������� ��������
        
    case 11     % ������������� ��������
        
end


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

% ����� �� ��������� ���� � �������� �������, ������� � ������� ����

% ������ �������� ������ � ��������� �������
if handles.PlayPauseButton.Value == 0
    
    try
        handles.PlayPauseButton.CData = imread([cd '\Icons\Play.png']);
    catch
    end
    
    handles.FrameBackButton.Enable = 'on';
    handles.FrameForwardButton.Enable = 'on';
    handles.FrameSlider.Enable = 'on';
    
else
    try
        handles.PlayPauseButton.CData = imread([cd '\Icons\Pause.png']);
    catch
    end
    
    handles.FrameBackButton.Enable = 'off';
    handles.FrameForwardButton.Enable = 'off';
    handles.FrameSlider.Enable = 'off';
    
    % ��������� ���� � ������� ������
    UserFile = getappdata(handles.FileAxes,'UserFile'); 
    FrameRate = UserFile(1).FrameRate;
    
    % ��������� �����
    for FrameNumber = handles.FrameSlider.Value : handles.FrameSlider.Max
                
        handles.FrameSlider.Value = FrameNumber;
        FrameSlider_Callback(hObject, eventdata, handles);
        
        pause(1/FrameRate);
        
        % ���� �������� �� �����
        if handles.PlayPauseButton.Value == 0  
            try
                handles.PlayPauseButton.CData = imread([cd '\Icons\Play.png']);
            catch
            end
            
            handles.FrameBackButton.Enable = 'on';
            handles.FrameForwardButton.Enable = 'on';
            return;
        end
    end    
end


% ���������� ���� 
function FrameBackButton_Callback(hObject, eventdata, handles)

FrameNumber = handles.FrameSlider.Value - 1;  % ��������� ����

if FrameNumber < handles.FrameSlider.Min
    FrameNumber = handles.FrameSlider.Min;
end

handles.FrameSlider.Value = FrameNumber;
FrameSlider_Callback(hObject, eventdata, handles);


% ��������� ����
function FrameForwardButton_Callback(hObject, eventdata, handles)

FrameNumber = handles.FrameSlider.Value + 1;  % ��������� ����

if FrameNumber > handles.FrameSlider.Max
    FrameNumber = handles.FrameSlider.Max;
end

handles.FrameSlider.Value = FrameNumber;
FrameSlider_Callback(hObject, eventdata, handles);


% ���������
function ApplyButton_Callback(hObject, eventdata, handles)

% ��������� ���� � ������� ������
UserFile = getappdata(handles.FileAxes,'UserFile');
    
% ����������, ��� ������� ���������� ��������: ��� �������
if size(UserFile,2) > 1             % ��� ����������
    if handles.ApplyButton.Value == 1
        handles.ApplyButton.String = '�����������';
    else
        handles.ApplyButton.String = '���������';
    end
    
else
    handles.ApplyButton.Value = 0;  % ������� ������� ���������    
end


% ���������� ������� ����� ��� ������ ���
function ZoomButton_Callback(hObject, eventdata, handles)

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');

    
if handles.ZoomButton.Value == 0    
    
    try
        handles.ZoomButton.CData = imread([cd '\Icons\Zoom+.png']);
    catch
    end
    
    SetAxesSize(handles.FileAxes,size(UserFile(1).Data,1),size(UserFile(1).Data,2));
    
else
    try
        handles.ZoomButton.CData = imread([cd '\Icons\Zoom-.png']);
    catch
    end
    
    % ��������� ��������� ������, ���������� ��� ���
    AxesSize = getappdata(handles.FileAxes,'InitPosition');
    
    % �������� �������, �� ������� ����� ��������� �������� � ������� ��
    height = size(UserFile(1).Data,1) / ...
        min(size(UserFile(1).Data,1)/AxesSize(4) , size(UserFile(1).Data,2)/AxesSize(3));
    
    width = size(UserFile(1).Data,2) / ...
        min(size(UserFile(1).Data,1)/AxesSize(4) , size(UserFile(1).Data,2)/AxesSize(3));
    
    SetAxesSize(handles.FileAxes, height, width);      
end


% ����� ������� ��������
function ROIButton_Callback(hObject, eventdata, handles)

% ���� ����� �� ������, ������ �������� �������������
if hObject == handles.ROIButton     
    
   h =  imrect(handles.FileAxes);
    
else    % ����� �� ������� ���������� � �����
    
end


% ������� ������
function PatternOpenButton_Callback(hObject, eventdata, handles)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%% �������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ������� ������ �����
function FrameSlider_Callback(hObject, eventdata, handles)

% ������� ���������� ����������� ������ �������-�������� � ��� !!!

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');

FrameNumber = round(handles.FrameSlider.Value); % ��������� ����� �����

handles.FrameSlider.Value = FrameNumber;      % ��������� ��������

% �������� CData, �� �������� ����� ������
set(findobj('Parent',handles.FileAxes,'Tag', 'FrameObj'),...
    'CData',UserFile(FrameNumber).Data);

handles.FileAxes.Visible = 'off';                                  

% ����������� ���� � ����� ������ ��� �����
if size(UserFile,2) > 1
    ShowTimeAndFrame(handles, UserFile(1).FrameRate, FrameNumber);         
end


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
function ShowTimeAndFrame(handles, FrameRate, FrameNumber)

% handles - ������ ���������� ����������
% FrameRate - �������� ��������������� �����
% FrameNumber - ����� �������� �����

sec = mod(FrameNumber / FrameRate, 60);       % ������� � ���.
min = (FrameNumber / FrameRate - sec) / 60;   % ���.
sec = round(sec);
        
if sec == 60            % ������ 59 ��� ��������
    sec = 0;
    min = min + 1;
end

handles.VideoTimeInfo.String = [sprintf('%02d',min) ':' sprintf('%02d',sec)];
handles.VideoFrameInfo.String = [num2str(FrameNumber) ' ����'];


% ����������� ������ ��� ��� �����/�����������
function zoom = SetAxesSize(hObject, height, width)

% hObject - ���, � ������� ��������� ����/�����������
% height, width - �������� �����/�����������
% zoom = 1 - ����� ��� ����������� ����/����������� ��� ���
% zoom = 0 - ������ ����������� ����/����������� ��� ���

zoom = true;        
    
% ��������� ��������� ������, ���������� ��� ���
AxesSize = getappdata(hObject,'InitPosition');  

% ��������, ������ ��� ������ �������� ������
% ���� �� ������� � ���������� ���, ������ �������� �� ����������

if max(width/AxesSize(3), height/AxesSize(4)) > 1
    
    zoom = false;   % ������
    width = width / max(width/AxesSize(3), height/AxesSize(4));
    height = height / max(width/AxesSize(3), height/AxesSize(4));
end
    
x = AxesSize(1) + round((AxesSize(3) - width)/2);
y = AxesSize(2) + round((AxesSize(4) - height)/2);

set(hObject, 'Position', [x y width height]);


% ����������� ������ ������� ���������
function MethodMenuSetting(MethodMenu, VideoOpened, rus)

% MethodMenu - ������������� �������
% VideoOpened - ���� ������� ����� - ����� ������
% rus - ���� 1, ����� ������� ���� �����

if VideoOpened          % ��� ��������� �����-�����
    if rus              % �� �������
        
        set(MethodMenu,'String',{...
            '������������� ������';...
            '������ �����-����';...
            '����� �������� � �������';...
            '������ �����';...
            '������������� ���';...
            '������������� �����';...
            '������������� ��������';...
            '�������� 3D-�����������';...
            '��������� �����';...
            '�������� ��������';...
            '������������� ��������';...
            });       
        
    else                % �� ����������
        
    end
        
else                    % ���� ������� �����������
    
        set(MethodMenu,'String',{...
            '������������� ������';...
            '������ �����-����';...
            '����� �������� � �������';...
            '������ �����';...
            '������������� ���';...
            '������������� �����';...
            '������������� ��������';...
            '�������� 3D �����������';...
            });
end
    


