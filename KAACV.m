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
setappdata(handles.PatternAxes,'InitPosition',handles.PatternAxes.Position);

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

% �� ������� ����������� ����������� (������� ��������, � �� ������ ���������)
% ��������� � kaaip brisk ������� (30 14000)
% ��� �� ��������� � ����������� - ����� 3 ������ ��� rgb, � �� 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ���� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% "������� ����"
function OpenMenu_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%% ��������

if isempty(handles)       % ������ ������� ������� �������� fig ������ m  
    
    questdlg({  '�� ��������� ���� � ����������� *.fig ������ ���������� *.m.';...
                '������� "OK", � ��� ����� ������';
                'You have started a file with expansion *.fig instead of *.m.';
                'Press "OK" to make it OK'},...
                'KAACV','OK','modal');
       
    close(gcf);
    run('KAACV.m');
    return;
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
    
    UserFile.Data = zeros(size(readFrame(VideoObject)));  % ������ �����
    
    FrameNumber = 1;                                % ������� ������
    NumOfFrames = round(VideoObject.Duration * VideoObject.FrameRate);
    
    if rus     % ����
        Wait = waitbar(0,'�������� �����','WindowStyle','modal');
    else
        Wait = waitbar(0,'Loading','WindowStyle','modal');
    end

    while hasFrame(VideoObject)                         % ���� ���� ����
        UserFile(FrameNumber).Data = readFrame(VideoObject); % ������ � ���������
        FrameNumber = FrameNumber+1;                         
        waitbar(FrameNumber / NumOfFrames, Wait);            % ������ ��������
    end    
    
    delete(Wait);       % ������� ���� �������� 
    
    % ���������� �������� �����
    UserFile(1).FrameRate = VideoObject.FrameRate;  
    
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

% ���������/��������� ��� ������ ��������
if size(UserFile,2) > 1     % ���� �����
    
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
    
else                % ���� ��������
    
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
end

% ��� ����
set([...
    handles.ParametersPanel;...
    handles.MethodMenu;...
    handles.ApplyButton;...
    handles.ZoomButton;...
    ],'Visible','on');

set([...
    handles.ShowFrameMenu;...
    ],'Enable','on');


set([...
    handles.VideoMenu;...
    handles.StatisticsList;...
    handles.PatternAxes;...
    ],'Visible','off');

% ���������� ��� ��� ������� ������ � ���� ����� ��������� - ����� ������
if SetAxesSize(handles.FileAxes,size(UserFile(1).Data,1),size(UserFile(1).Data,2))
    handles.ZoomButton.Enable = 'on';
else
    handles.ZoomButton.Enable = 'off';
end

% ������ ������-��������, � ��������� ����� ���� ��������� CData
image(  UserFile(1).Data,...
        'Parent',handles.FileAxes,...
        'Tag', 'FrameObj');

% ��������� ���� ���������    
MethodMenuSetting(handles.MethodMenu, size(UserFile,2) > 1, rus);

% ������ ���� � ��������� ���������
handles.ZoomButton.Value = 0;
ZoomButton_Callback(hObject, eventdata, handles);

handles.PlayPauseButton.Value = 0;      % ������ �� �����
PlayPauseButton_Callback(hObject, eventdata, handles);  % ������ ��������

handles.ApplyButton.Value = 0;              % �������� ������ ���������
if rus
    handles.ApplyButton.String = '���������';   % �������� ������� �� ���
else
    handles.ApplyButton.String = 'Apply';   % �������� ������� �� ���
end

handles.FrameSlider.Value = 1;          % ��������� ����� ������� �����  
FrameSlider_Callback(hObject, eventdata, handles);  % �������� � ����� � ���

% ��������� ���� � ����������  
MethodMenu_Callback(hObject, eventdata, handles);


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


% �������� ROI
function ROIShowMenu_Callback(hObject, eventdata, handles)

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');

% ����������� ����
Image = UserFile(handles.FrameSlider.Value).Data;

X0 = round(str2double(handles.ROIx0.String));
X1 = round(str2double(handles.ROIx1.String));
Y0 = round(str2double(handles.ROIy0.String));
Y1 = round(str2double(handles.ROIy1.String));
    
Image = Image(Y0:Y1,X0:X1,:);

% ������� ������� ��� ��� ���
try
    fig = imtool(Image);              % ��� ������-������
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
% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');

% ��������������� ��������
if handles.ApplyButton.Value == 1
    handles.ApplyButton.String = '�����������';
else
    handles.ApplyButton.String = '���������';
end
handles.PatternOpenButton.String = '������� �������';

handles.ParametersPanel.Title = '���������';

handles.FileMenu.Label = '����';
handles.OpenMenu.Label = '�������';
handles.ShowFrameMenu.Label = '�������� ����/�����������';
handles.ROIShowMenu.Label = '�������� ROI';
handles.SaveFrameMenu.Label = '��������� ����';
handles.ShowPatternImageMenu.Label = '�������� �������';
handles.SettingsMenu.Label = '���������';
handles.LanguageMenu.Label = '����';

% handles..Label = '';
% handles..Label = '';
% handles..Label = '';

% ��������������� ���������

% handles..TooltipString = '';

% ��������� �������
MethodMenuSetting(handles.MethodMenu, size(UserFile,2) > 1, 1);    % ������ ������ �������
MethodMenu_Callback(hObject, eventdata, handles);   % ��������� ������ ����������


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

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');

% ��������������� ��������
if handles.ApplyButton.Value == 1
    handles.ApplyButton.String = 'Applying';
else
    handles.ApplyButton.String = 'Apply';
end
handles.PatternOpenButton.String = 'Open reference';

handles.ParametersPanel.Title = 'Parameters';

handles.FileMenu.Label = 'File';
handles.OpenMenu.Label = 'Open';
handles.ShowFrameMenu.Label = 'Show frame/image';
handles.ROIShowMenu.Label = 'Show ROI';
handles.SaveFrameMenu.Label = 'Save frame';
handles.ShowPatternImageMenu.Label = 'Show reference image';
handles.SettingsMenu.Label = 'Settings';
handles.LanguageMenu.Label = 'Language';

% handles..Label = '';
% handles..Label = '';
% handles..Label = '';

% ��������������� ���������

% handles..TooltipString = '';

% ��������� �������
MethodMenuSetting(handles.MethodMenu, size(UserFile,2) > 1, 0);    % ������ ������ �������
MethodMenu_Callback(hObject, eventdata, handles);   % ��������� ������ ����������


%
%
% ����� ������ ���������
function MethodMenu_Callback(hObject, eventdata, handles)

% ������ ��� �������� � ��������� ��������� ����
set(handles.ParametersPanel.Children,'Visible','off');

% ���� �������� ������� �������� ������
handles.ROIShowMenu.Enable = 'off';
handles.ShowPatternImageMenu.Visible = 'off';
handles.PatternAxes.Visible = 'off';

% ������� ������ ���������������� ������
setappdata(handles.PatternAxes,'Pattern',[]);
delete([handles.PatternAxes.Children handles.PatternAxes.UserData]);

% ������������� ��� ��������� ������ ������� � 1
handles.ParMenu1.Value = 1;
handles.ParMenu2.Value = 1;
handles.ParMenu3.Value = 1;
handles.ParMenu4.Value = 1;

handles.ParCheckBox1.Value = 0;
handles.ParCheckBox2.Value = 0;

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');
width = size(UserFile(1).Data,2);
heigth = size(UserFile(1).Data,1);
Image = UserFile(round( size(UserFile,2)/2 )).Data;
MinWidthHeigth = min(width,heigth);
MaxWidthHeigth = max(width,heigth);

% ���� ������� ���� ������, rus = 1
rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'������������� ������','Optical character recognition'}
                                    
        handles.ROIShowMenu.Enable = 'on';
        
        handles.ParMenu1.Visible = 'on';
        handles.ParMenu2.Visible = 'on';
        
        handles.ParMenuText1.Visible = 'on';
        handles.ParMenuText2.Visible = 'on';
        
        handles.ParSlider1.Visible = 'on';
        handles.ParSliderText1.Visible = 'on';
        handles.ParSliderValueText1.Visible = 'on';
        
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
        handles.ROIx0.Value = 1;
        handles.ROIy0.Value = 1;
        handles.ROIx1.Value = width;
        handles.ROIy1.Value = heigth;
        
        % ����� �������������
        handles.ParSlider1.Min              = 0.01;
        handles.ParSlider1.Max              = 1;
        handles.ParSlider1.SliderStep       = [0.01/0.99 0.1/0.99];
        handles.ParSlider1.Value            = 0.5;
        handles.ParSliderValueText1.String  = '0.5';   
        
        if rus 
            handles.ParMenuText1.String = '������������ ������';
            handles.ParMenu1.String = { '����';
                                        '����';
                                        '�����';
                                        '�����'};

            handles.ParMenuText2.String = '�������������� ����';
            
            try             % ��������� ������� �������������� ������
                ocr(ones(10),'Language','Russian');  % ���� ���������, �� ����� 

                handles.ParMenu2.String = { '����������';...
                                            '�������';...
                                            '����������';...
                                            '�����������';...
                                            '��������';...
                                            '���������';...
                                            '�������';...
                                            '��������� (������������)';...
                                            '��������'}; 
            catch                                    
                handles.ParMenu2.String = '����������'; 
            end

            handles.ParSliderText1.String = '����� �������������:';             
            handles.ROIButton.TooltipString = ...
                ['������� ��������: �������, ����� ������� �� �����/����������� ������� ��������, '...
                '������� ����� ����������� ���������'];   
            
        else
            handles.ParMenuText1.String = 'Text Layout';
            handles.ParMenu1.String = { 'Auto';
                                        'Block';
                                        'Line';
                                        'Word'};

            handles.ParMenuText2.String = 'Recognition language';

            try             % ��������� ������� �������������� ������
                ocr(ones(10),'Language','Russian');  % ���� ���������, �� ����� 

                handles.ParMenu2.String = { 'English';...
                                            'Russian';...
                                            'Ukrainian';...
                                            'French';...
                                            'Dutch';...
                                            'Spanish';...
                                            'Finnish';...
                                            'Chinese (traditional)';...
                                            'Japanese'}; 
            catch                                    
                handles.ParMenu2.String = 'English'; 
            end

            handles.ParSliderText1.String = 'Recognition threshold:';            
            handles.ROIButton.TooltipString = ...
                'Region of interest: press it to choose area on the frame/image to process';
        end             
        
        ROIButton_Callback(hObject, eventdata, handles);        
        
    case {'������ �����-����','Barcode reading'} 
        
    case {'����� �������� � �������','Text region detection'}  
        
    case {'������ �����','Blob analysis'}   
        
        handles.ParMenu1.Visible = 'on';
        handles.ParMenuText1.Visible = 'on';
        
        handles.ParSlider1.Visible = 'on';
        handles.ParSliderText1.Visible = 'on';
        handles.ParSliderValueText1.Visible = 'on';
        
        handles.ParSlider2.Visible = 'on';
        handles.ParSliderText2.Visible = 'on';
        handles.ParSliderValueText2.Visible = 'on';
        
        handles.ParSlider3.Visible = 'on';
        handles.ParSliderText3.Visible = 'on';
        handles.ParSliderValueText3.Visible = 'on';
        
        if ~all(all(Image == 0 | Image == 1))    % ���� �� �/�
            
            handles.ParSlider4.Visible = 'on';
            handles.ParSliderText4.Visible = 'on';
            handles.ParSliderValueText4.Visible = 'on';
            
            handles.ParMenu2.Visible = 'on';
            handles.ParMenuText2.Visible = 'on';
            
            handles.ParMenu3.Visible = 'on';
            handles.ParMenuText3.Visible = 'on';            
        
        end
        
        handles.ParCheckBox1.Visible = 'on';
        
        % ������������ ���������� �����
        handles.ParSlider1.Min              = 1;
        handles.ParSlider1.Max              = width * heigth;
        handles.ParSlider1.SliderStep       = [1/(width*heigth-1) 10/(width*heigth-1)];
        handles.ParSlider1.Value            = round(width * heigth / 2);
        handles.ParSliderValueText1.String  = num2str(round(width * heigth / 2));         
        
        % ����������� ������� �����
        handles.ParSlider2.Min              = 0;
        handles.ParSlider2.Max              = width * heigth;
        handles.ParSlider2.SliderStep       = [1/(width*heigth) 10/(width*heigth)];
        if width*heigth <= 50            
            handles.ParSlider2.Value            = 0;
            handles.ParSliderValueText2.String  = '0';
        else            
            handles.ParSlider2.Value            = 50;
            handles.ParSliderValueText2.String  = '50';
        end
        
        % ������������ ������� �����
        handles.ParSlider3.Min              = 1;
        handles.ParSlider3.Max              = width*heigth;
        handles.ParSlider3.SliderStep       = [1/(width*heigth-1) 10/(width*heigth-1)];
        handles.ParSlider3.Value            = round(width * heigth / 2);
        handles.ParSliderValueText3.String  = num2str(round(width * heigth / 2)); 
        
        
        % ����������������
        handles.ParSlider4.Min              = 0;
        handles.ParSlider4.Max              = 1;
        handles.ParSlider4.SliderStep       = [0.01 0.1];
        handles.ParSlider4.Value            = 0.5;
        handles.ParSliderValueText4.String  = '0.5';       
        
        % ���������
        handles.ParMenu1.String = { '4';'8';};
        
        handles.ParCheckBox1.Value = 1;        
        
        if rus            
            handles.ParMenuText1.String = '���������';
            handles.ParMenuText2.String = '��� �����������';
            handles.ParMenu2.String = { '����������';'���������� (���)';'����������';};
            handles.ParMenuText3.String = '���';
            handles.ParMenu3.String = { '������';'�����';};
            handles.ParSliderText1.String = '������������ ���������� �����:'; 
            handles.ParSliderText2.String = '����������� ������� �����: ';
            handles.ParSliderText3.String = '������������ ������� �����: '; 
            handles.ParSliderText4.String = '���������������� / �����: '; 
            
            handles.ParCheckBox1.String = '��������� �����';   
            
            handles.ParCheckBox1.TooltipString = '������� ��������� �����';
            handles.ParSlider4.TooltipString = '���������������� ���������� �����������';
        else
            handles.ParMenuText1.String = 'Connectivity';
            handles.ParMenuText2.String = 'Binarization method';
            handles.ParMenu2.String = { 'Adaptive';'Global (Otsu)';'Global'};
            handles.ParMenuText3.String = 'Foreground';
            handles.ParMenu3.String = { 'Dark';'Bright';};
            handles.ParSliderText1.String = 'Maximum number of blobs:'; 
            handles.ParSliderText2.String = 'Minimum blob area: ';
            handles.ParSliderText3.String = 'Maximum blob area: '; 
            handles.ParSliderText4.String = 'Sensitivity / Threshold: '; 
            
            handles.ParCheckBox1.String = 'Border blobs';    
            
            handles.ParCheckBox1.TooltipString = 'Including border blobs';
            handles.ParSlider4.TooltipString = 'Adaptive binarization sensitivity';
        end
        
        
        
    case {'������������� ���','Face detection'}
        
    case {'������������� �����','People detection'}
        
    case {'������������� ��������','Object detection'}        
        
        handles.ROIShowMenu.Enable = 'on';
        handles.PatternOpenButton.Visible = 'on';
        handles.ROIButton.Visible = 'on'; 
        
        handles.ParMenu1.Visible = 'on';
        handles.ParMenuText1.Visible = 'on';
        handles.ParMenu2.Visible = 'on';
        handles.ParMenuText2.Visible = 'on';
        handles.ParMenu3.Visible = 'on';
        handles.ParMenuText3.Visible = 'on';
        handles.ParMenu4.Visible = 'on';
        handles.ParMenuText4.Visible = 'on';
        
        handles.ParSlider5.Visible = 'on';
        handles.ParSliderText5.Visible = 'on';
        handles.ParSliderValueText5.Visible = 'on';
        
        handles.ParSlider6.Visible = 'on';
        handles.ParSliderText6.Visible = 'on';
        handles.ParSliderValueText6.Visible = 'on';
        
        handles.ParSlider7.Visible = 'on';
        handles.ParSliderText7.Visible = 'on';
        handles.ParSliderValueText7.Visible = 'on';
        
        handles.ParSlider8.Visible = 'on';
        handles.ParSliderText8.Visible = 'on';
        handles.ParSliderValueText8.Visible = 'on';
        
        handles.ParSlider9.Visible = 'on';
        handles.ParSliderText9.Visible = 'on';
        handles.ParSliderValueText9.Visible = 'on';        
        
        handles.ParCheckBox2.Visible = 'on';
        
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
        handles.ROIx0.Value = 1;
        handles.ROIy0.Value = 1;
        handles.ROIx1.Value = width;
        handles.ROIy1.Value = heigth;         
        
        % ����� ���������
        handles.ParSlider5.Min              = 1;
        handles.ParSlider5.Max              = 100;
        handles.ParSlider5.SliderStep       = [1/99 10/99];
        handles.ParSlider5.Value            = 10;
        handles.ParSliderValueText5.String  = '10'; 
        
        % ����� ���������
        handles.ParSlider6.Min              = 0.01;
        handles.ParSlider6.Max              = 1;
        handles.ParSlider6.SliderStep       = [0.01/0.99 0.1/0.99];
        handles.ParSlider6.Value            = 0.1;
        handles.ParSliderValueText6.String  = '0.1';  
        
        % ������������ ����� ��������� ���������
        handles.ParSlider7.Min              = 10;
        handles.ParSlider7.Max              = 100000;
        handles.ParSlider7.SliderStep       = [10/99999 100/99999];
        handles.ParSlider7.Value            = 1000;
        handles.ParSliderValueText7.String  = '1000';  
        
        % ������� �������
        handles.ParSlider8.Min              = 1;
        handles.ParSlider8.Max              = 99;
        handles.ParSlider8.SliderStep       = [1/98 10/98];
        handles.ParSlider8.Value            = 50;
        handles.ParSliderValueText8.String  = '50';  
        
        % ����. ���������� ����� ������ � ���������
        handles.ParSlider9.Min              = 1;
        handles.ParSlider9.Max              = MinWidthHeigth/4;
        handles.ParSlider9.SliderStep       = [1/(MinWidthHeigth/4 - 1) 10/(MinWidthHeigth/4 - 1)];
        handles.ParSlider9.Value            = 2;
        handles.ParSliderValueText9.String  = '2';  
        
        
        if rus
                                     
            handles.ParMenuText1.String = '��� ��������������';
            handles.ParMenu1.String = { '�������';...
                                        '��������';...
                                        '�����������';...
                                        };
                                    
            handles.ParMenuText2.String = '����� ���������';
            handles.ParMenu2.String = { '�������������';...
                                        '���������������';...
                                        };
            
            handles.ParMenuText3.String = '��������';
            handles.ParMenu3.String = { 'MSER';...
                                        'BRISK';...
                                        'FAST';...
                                        '�������';...
                                        '������������ ������������ ��������';...
                                        'SURF (������ ����������� 64)';...
                                        'SURF (������ ����������� 128)';...
                                        };
            
            handles.ParSliderText5.String = '����� ���������: '; 
            handles.ParSliderText6.String = '����� ���������: '; 
            handles.ParSliderText7.String = '������������ ����� ��������� ���������: '; 
            handles.ParSliderText8.String = '������� �������: ';            
            handles.ParSliderText9.String = '����. ���������� �����/��������: '; 
            
            handles.ParCheckBox1.String = '���. ����������';             
            handles.ParCheckBox2.String = '������ ����������';  
            handles.ParCheckBox2.TooltipString = '��������� ������� - ������ ���������� �������� �����';
            handles.ParSlider9.TooltipString = '����. ���������� ����� ������ � ���������';
            
        else
            
            handles.ParMenuText1.String = 'Transformation type';
            handles.ParMenu1.String = { 'Similarity';...
                                        'Affine';...
                                        'Projective';...
                                        };
                                    
            handles.ParMenuText2.String = 'Match method';
            handles.ParMenu2.String = { 'Exhaustive';...
                                        'Approximate';...
                                        };
            
            handles.ParMenuText3.String = 'Detector';
            handles.ParMenu3.String = { 'MSER';...
                                        'BRISK';...
                                        'FAST';...
                                        'Harris';...
                                        'Minimum eigen';...
                                        'SURF (64 descriptor size)';...
                                        'SURF (128 descriptor size)';...
                                        };
                                    
            handles.ParSliderText5.String = 'Match Threshold: '; 
            handles.ParSliderText6.String = 'Ratio threshold: '; 
            handles.ParSliderText7.String = 'Maximum number of random trials: '; 
            handles.ParSliderText8.String = 'Confidence: ';            
            handles.ParSliderText9.String = 'Max distance point/projection: '; 
            
            handles.ParCheckBox1.String = 'Use orientation';             
            handles.ParCheckBox2.String = 'Only unique';  
            handles.ParCheckBox2.TooltipString = 'Match results are only unique keypoints';
            handles.ParSlider9.TooltipString = 'Maximum distance from point to projection';
                       
        end
        
        ParMenu3_Callback(hObject, eventdata, handles);
        ROIButton_Callback(hObject, eventdata, handles);  
        ParCheckBox1_Callback(hObject, eventdata, handles);
        ParCheckBox2_Callback(hObject, eventdata, handles);
        
    case {'�������� 3D-�����������','3-D image creation'}
        
    case {'��������� �����','Video processing'}
        
    case {'�������� ��������','Panorama creation'}
        
    case {'������������� ��������','Motion detection'}
        
    otherwise
        assert(0, '������ � ��������� � ������� ���������');
        
end

%
%
%

% ����� ������������� �����
function VideoMenu_Callback(hObject, eventdata, handles)

% �������� ��� �����������-���������� ���������
ProcessedImages = getappdata(handles.FileAxes,'ProcessedImages');

assert(~isempty(ProcessedImages),'� ��� �� �������� ������ � ������� ���������');

assert(size(ProcessedImages,2) == size(handles.VideoMenu.String,1),...
        '����� ����� �� ������������� ����� �����������');
    
% ���� ����� ��������� ������ ��������� ���-�� �����    
if handles.VideoMenu.Value > size(handles.VideoMenu.String,1)
    handles.VideoMenu.Value = 1;
end

% ������� �� ���������� ������������ ��������
ImageToView = ProcessedImages(handles.VideoMenu.Value).Images;
FrameObj = findobj('Parent',handles.FileAxes, 'Tag','FrameObj');

% ���� ������������� - ����������, �������� ���������� 2 ������ 
if size(ImageToView,3) ~= size(FrameObj.CData,3)
    ImageToView(:,:,2) = ImageToView(:,:,1);
    ImageToView(:,:,3) = ImageToView(:,:,1);
end

set(FrameObj, 'CData',im2double(ImageToView));
handles.FileAxes.Visible = 'off';


% ���� � 1 ���������� 
function ParMenu1_Callback(hObject, eventdata, handles)


% ���� � 2 ���������� 
function ParMenu2_Callback(hObject, eventdata, handles)

% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'������ �����','Blob analysis'} 
        
        switch handles.ParMenu2.Value
            
            case 1  % ���������� �����
                
                handles.ParSlider4.Visible = 'on';
                handles.ParSliderText4.Visible = 'on';
                handles.ParSliderValueText4.Visible = 'on';
                
                handles.ParMenu3.Visible = 'on';
                handles.ParMenuText3.Visible = 'on';
            
            case 2  % ���������� ����� (���)
                
                handles.ParSlider4.Visible = 'off';
                handles.ParSliderText4.Visible = 'off';
                handles.ParSliderValueText4.Visible = 'off';
                
                handles.ParMenu3.Visible = 'off';
                handles.ParMenuText3.Visible = 'off';
            
            case 3  % ���������� �����
                
                handles.ParSlider4.Visible = 'on';
                handles.ParSliderText4.Visible = 'on';
                handles.ParSliderValueText4.Visible = 'on';
                
                handles.ParMenu3.Visible = 'off';
                handles.ParMenuText3.Visible = 'off';
        end
    
end


% ���� � 3 ���������� 
function ParMenu3_Callback(hObject, eventdata, handles)

Value = handles.ParMenu3.Value;

% ���� ������� ���� ������, rus = 1
rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');
width = size(UserFile(1).Data,2);
heigth = size(UserFile(1).Data,1);
maxArea = max(width,heigth);
minArea = min(width,heigth);

% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    case {'������������� ��������','Object detection'}    
        
        % ����� ���, �������� ����� ������ ������        
        handles.ParSlider1.Visible = 'off';
        handles.ParSliderText1.Visible = 'off';
        handles.ParSliderValueText1.Visible = 'off';
        
        handles.ParSlider2.Visible = 'off';
        handles.ParSliderText2.Visible = 'off';
        handles.ParSliderValueText2.Visible = 'off';
        
        handles.ParSlider3.Visible = 'off';
        handles.ParSliderText3.Visible = 'off';
        handles.ParSliderValueText3.Visible = 'off';
        
        handles.ParSlider4.Visible = 'off';
        handles.ParSliderText4.Visible = 'off';
        handles.ParSliderValueText4.Visible = 'off';        
        
        handles.ParCheckBox1.Visible = 'off';        
        
        % ��������� � ������
        handles.ParMenuText4.Value = 1;
        
        switch Value
            
            case 1      % MSER
                                    
                handles.ParCheckBox1.Visible = 'on';
                
                handles.ParCheckBox1.Visible = 'on';
                handles.ParSlider1.Visible = 'on';
                handles.ParSliderText1.Visible = 'on';
                handles.ParSliderValueText1.Visible = 'on';
                
                handles.ParSlider2.Visible = 'on';
                handles.ParSliderText2.Visible = 'on';
                handles.ParSliderValueText2.Visible = 'on';
                
                handles.ParSlider3.Visible = 'on';
                handles.ParSliderText3.Visible = 'on';
                handles.ParSliderValueText3.Visible = 'on';
                
                handles.ParSlider4.Visible = 'on';
                handles.ParSliderText4.Visible = 'on';
                handles.ParSliderValueText4.Visible = 'on';
                
                handles.ParSlider1.Min              = 0.01;
                handles.ParSlider1.Max              = 1;
                handles.ParSlider1.SliderStep       = [0.01/0.99 0.1/0.99];
                handles.ParSlider1.Value            = 0.25;
                handles.ParSliderValueText1.String  = '0.25';
                
                handles.ParSlider2.Min              = 1;
                handles.ParSlider2.Max              = 100;
                handles.ParSlider2.SliderStep       = [1/99 10/99];
                handles.ParSlider2.Value            = 2;
                handles.ParSliderValueText2.String  = '2';
                
                % �������� ����� ������ ���� ������� 
                % � ����������� �� ������ ������������,
                % ����� ��������� ����� ������������ ������� �� ��������
                % �������, ��� ����� ����������� ������� � ��������
                % ������� Value ������ ���� ����� ��������!!!
                handles.ParSlider3.Min              = 1;
                handles.ParSlider3.Max              = maxArea - 1;
                handles.ParSlider3.SliderStep       = [1/(maxArea - 1) 1/(maxArea - 1)];
                handles.ParSlider3.Value            = 1;
                handles.ParSliderValueText3.String  = '1';
                
                handles.ParSlider4.Min              = 2;
                handles.ParSlider4.Max              = maxArea;
                handles.ParSlider4.SliderStep       = [1/(maxArea - 1) 1/(maxArea - 1)];
                handles.ParSlider4.Value            = maxArea;
                handles.ParSliderValueText4.String  = num2str(maxArea);
                
                if rus 
                    
                    handles.ParSliderText1.String = '������������ �������� �������:';
                    handles.ParSliderText2.String = '��� ������:';
                    handles.ParSliderText3.String = '����������� �������:';
                    handles.ParSliderText4.String = '������������ �������:';
                    
                    handles.ParMenuText4.String = '�������';
                    handles.ParMenu4.String = { '����� ������� ��������';...
                                                '����� ��������� ���������';...
                                                };
            
                    
                else
                    handles.ParSliderText1.String = 'Maximum area variation:';
                    handles.ParSliderText2.String = 'Threshold step size:';
                    handles.ParSliderText3.String = 'Minimum area:';
                    handles.ParSliderText4.String = 'Maximum area:';
                    
                    handles.ParMenuText4.String = 'Metric';
                    handles.ParMenu4.String = { 'Sum of absolute differences';...
                                                'Sum of squared differences';...
                                                };
                    
                end
                
                
            case 2      % BRISK
                
                handles.ParCheckBox1.Visible = 'on';
                
                handles.ParSlider1.Visible = 'on';
                handles.ParSliderText1.Visible = 'on';
                handles.ParSliderValueText1.Visible = 'on';
                
                handles.ParSlider2.Visible = 'on';
                handles.ParSliderText2.Visible = 'on';
                handles.ParSliderValueText2.Visible = 'on';
                
                handles.ParSlider3.Visible = 'on';
                handles.ParSliderText3.Visible = 'on';
                handles.ParSliderValueText3.Visible = 'on';
                
                handles.ParSlider1.Min              = 0.01;
                handles.ParSlider1.Max              = 0.99;
                handles.ParSlider1.SliderStep       = [0.01/0.98 0.1/0.98];
                handles.ParSlider1.Value            = 0.2;
                handles.ParSliderValueText1.String  = '0.2';
                
                handles.ParSlider2.Min              = 0;
                handles.ParSlider2.Max              = 1;
                handles.ParSlider2.SliderStep       = [0.01 0.1];
                handles.ParSlider2.Value            = 0.1;
                handles.ParSliderValueText2.String  = '0.1';
                
                handles.ParSlider3.Min              = 0;
                handles.ParSlider3.Max              = 6;
                handles.ParSlider3.SliderStep       = [1/6 1/6];
                handles.ParSlider3.Value            = 4;
                handles.ParSliderValueText3.String  = '4';
                
                if rus 
                    
                    handles.ParSliderText1.String = '����������� �������������:';
                    handles.ParSliderText2.String = '����������� ��������:';
                    handles.ParSliderText3.String = '����� �����:';
                    
                    handles.ParMenuText4.String = '�������';
                    handles.ParMenu4.String = { '��������';...
                                                };
                    
                else
                    handles.ParSliderText1.String = 'Minimum contrast:';
                    handles.ParSliderText2.String = 'Minimum quality:';
                    handles.ParSliderText3.String = 'Octaves number:';
                    
                    handles.ParMenuText4.String = 'Metric';
                    handles.ParMenu4.String = { 'Hamming';...
                                                };
                    
                end
                
            case 3      % FAST
                             
                handles.ParSlider1.Visible = 'on';
                handles.ParSliderText1.Visible = 'on';
                handles.ParSliderValueText1.Visible = 'on';
                
                handles.ParSlider2.Visible = 'on';
                handles.ParSliderText2.Visible = 'on';
                handles.ParSliderValueText2.Visible = 'on';                
                
                handles.ParSlider1.Min              = 0.01;
                handles.ParSlider1.Max              = 0.99;
                handles.ParSlider1.SliderStep       = [0.01/0.98 0.1/0.98];
                handles.ParSlider1.Value            = 0.2;
                handles.ParSliderValueText1.String  = '0.2';
                
                handles.ParSlider2.Min              = 0;
                handles.ParSlider2.Max              = 1;
                handles.ParSlider2.SliderStep       = [0.01 0.1];
                handles.ParSlider2.Value            = 0.1;
                handles.ParSliderValueText2.String  = '0.1';
                
                if rus 
                    
                    handles.ParSliderText1.String = '����������� �������������:';
                    handles.ParSliderText2.String = '����������� ��������:';
                    
                    handles.ParMenuText4.String = '�������';
                    handles.ParMenu4.String = { '��������';...
                                                };
                    
                else
                    handles.ParSliderText1.String = 'Minimum contrast:';
                    handles.ParSliderText2.String = 'Minimum quality:';
                    
                    handles.ParMenuText4.String = 'Metric';
                    handles.ParMenu4.String = { 'Hamming';...
                                                };
                    
                end
                
            case 4      % Harris
                
                handles.ParSlider3.Visible = 'on';
                handles.ParSliderText3.Visible = 'on';
                handles.ParSliderValueText3.Visible = 'on';
                
                handles.ParSlider2.Visible = 'on';
                handles.ParSliderText2.Visible = 'on';
                handles.ParSliderValueText2.Visible = 'on';                
                                
                handles.ParSlider3.Min              = 3;
                handles.ParSlider3.Max              = minArea;
                handles.ParSlider3.SliderStep       = [2/(minArea-3) 2/(minArea-3)];
                handles.ParSlider3.Value            = 3;
                handles.ParSliderValueText3.String  = '3';
                
                handles.ParSlider2.Min              = 0;
                handles.ParSlider2.Max              = 1;
                handles.ParSlider2.SliderStep       = [0.01 0.1];
                handles.ParSlider2.Value            = 0.1;
                handles.ParSliderValueText2.String  = '0.1';
                
                if rus 
                    
                    handles.ParSliderText3.String = '������ ���� �������:';
                    handles.ParSliderText2.String = '����������� ��������:';
                    
                    handles.ParMenuText4.String = '�������';
                    handles.ParMenu4.String = { '��������';...
                                                };
                    
                else
                    handles.ParSliderText3.String = 'Filter dimension:';
                    handles.ParSliderText2.String = 'Minimum quality:';
                    
                    handles.ParMenuText4.String = 'Metric';
                    handles.ParMenu4.String = { 'Hamming';...
                                                };
                    
                end
                
                
            case 5      % Minimum eigen
                
                
                handles.ParSlider3.Visible = 'on';
                handles.ParSliderText3.Visible = 'on';
                handles.ParSliderValueText3.Visible = 'on';
                
                handles.ParSlider2.Visible = 'on';
                handles.ParSliderText2.Visible = 'on';
                handles.ParSliderValueText2.Visible = 'on';                
                
                handles.ParSlider3.Min              = 3;
                handles.ParSlider3.Max              = maxArea;
                handles.ParSlider3.SliderStep       = [2/(maxArea-3) 2/(maxArea-3)];
                handles.ParSlider3.Value            = 3;
                handles.ParSliderValueText3.String  = '3';
                
                handles.ParSlider2.Min              = 0;
                handles.ParSlider2.Max              = 1;
                handles.ParSlider2.SliderStep       = [0.01 0.1];
                handles.ParSlider2.Value            = 0.1;
                handles.ParSliderValueText2.String  = '0.1';
                
                if rus 
                    
                    handles.ParSliderText3.String = '������ ���� �������:';
                    handles.ParSliderText2.String = '����������� ��������:';
                    
                    handles.ParMenuText4.String = '�������';
                    handles.ParMenu4.String = { '��������';...
                                                };
                    
                else
                    handles.ParSliderText3.String = 'Filter dimension:';
                    handles.ParSliderText2.String = 'Minimum quality:';
                    
                    handles.ParMenuText4.String = 'Metric';
                    handles.ParMenu4.String = { 'Hamming';...
                                                };
                    
                end
                
            case {6,7}      % SURF (64/128 descriptor size)
                
                handles.ParCheckBox1.Visible = 'on';                
                
                handles.ParSlider2.Visible = 'on';
                handles.ParSliderText2.Visible = 'on';
                handles.ParSliderValueText2.Visible = 'on';
                
                handles.ParSlider3.Visible = 'on';
                handles.ParSliderText3.Visible = 'on';
                handles.ParSliderValueText3.Visible = 'on';
                
                handles.ParSlider4.Visible = 'on';
                handles.ParSliderText4.Visible = 'on';
                handles.ParSliderValueText4.Visible = 'on';
                
                handles.ParSlider2.Min              = 100;
                handles.ParSlider2.Max              = 100000;
                handles.ParSlider2.SliderStep       = [100/999900 1000/999900];
                handles.ParSlider2.Value            = 1000;
                handles.ParSliderValueText2.String  = '1000';
                
                handles.ParSlider3.Min              = 1;
                handles.ParSlider3.Max              = 6;
                handles.ParSlider3.SliderStep       = [1/5 1/5];
                handles.ParSlider3.Value            = 3;
                handles.ParSliderValueText3.String  = '3';
                
                handles.ParSlider4.Min              = 3;
                handles.ParSlider4.Max              = 8;
                handles.ParSlider4.SliderStep       = [1/5 1/5];
                handles.ParSlider4.Value            = 4;
                handles.ParSliderValueText4.String  = '4';
                
                if rus 
                    
                    handles.ParSliderText2.String = '�����:';
                    handles.ParSliderText3.String = '����� �����:';
                    handles.ParSliderText4.String = '����� ������� ��������:';
                    
                    handles.ParMenuText4.String = '�������';
                    handles.ParMenu4.String = { '����� ������� ��������';...
                                                '����� ��������� ���������';...
                                                };
                    
                else
                    handles.ParSliderText2.String = 'Threshold:';
                    handles.ParSliderText3.String = 'Octaves number:';
                    handles.ParSliderText4.String = 'Number of scale levels:';
                    
                    handles.ParMenuText4.String = 'Metric';
                    handles.ParMenu4.String = { 'Sum of absolute differences';...
                                                'Sum of squared differences';...
                                                };
                    
                end
                
                
        end
end


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
    handles.PatternOpenButton.Enable = 'on';
    
else
    try
        handles.PlayPauseButton.CData = imread([cd '\Icons\Pause.png']);
    catch
    end
    
    handles.FrameBackButton.Enable = 'off';
    handles.FrameForwardButton.Enable = 'off';
    handles.FrameSlider.Enable = 'off';
    handles.PatternOpenButton.Enable = 'off';
    
    % ��������� ���� � ������� ������
    UserFile = getappdata(handles.FileAxes,'UserFile'); 
    FrameRate = UserFile(1).FrameRate;
    
    % ��������� �����
    for FrameNumber = handles.FrameSlider.Value : handles.FrameSlider.Max
        
        tic;
        
        handles.FrameSlider.Value = FrameNumber;
        FrameSlider_Callback(hObject, eventdata, handles);
        
        drawnow;        % ��������� ������������
        
        if toc < (1/FrameRate)  % ���� ������ ������, ��� ����� ��� �������
            pause(1/FrameRate); % �������� �� 
        end
        
        
        % ���� �������� �� �����, ����� �������, ������� �������� ������
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


%
%
% ���������
function ApplyButton_Callback(hObject, eventdata, handles)

% ��������� ������� ����������� 
UserFile = getappdata(handles.FileAxes,'UserFile');
Image = UserFile(handles.FrameSlider.Value).Data;
rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% ����������, ��� ������� ���������� ��� ����� ��������: ��� �������
if size(UserFile,2) > 1
    
    if handles.ApplyButton.Value == 1
        
        if rus
            handles.ApplyButton.String = '�����������';
        else
            handles.ApplyButton.String = 'Applying';
        end
        
    else        % ���� ������ ������ - �� ����� ������������
        
        if rus
            handles.ApplyButton.String = '���������';
        else
            handles.ApplyButton.String = 'Apply';
        end
        
        return;
        
    end
    
else  % ��� ��������
    
    handles.ApplyButton.Value = 0;  % ������� ������� ��������� 
    
end

% ������ ������������ ��������� ��� �������� ������ ��������� �����������
% �������� ���� ����������� (��� ������� �������)
ProcessedImages = struct('Images',im2double(Image));    % ��������� ��������
if rus
    StringOfImages = {'��������'};
else
    StringOfImages = {'Original image'}; 
end


% ������� ������ ��������
delete(findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b'));
handles.StatisticsList.String = '';

% ����� �� ������� ���� - ������ ��������� 1� ������
handles.StatisticsList.Value = 1;


% ��������� ��������� ���� ����� ����������
X0 = round(str2double(handles.ROIx0.String));
X1 = round(str2double(handles.ROIx1.String));
Y0 = round(str2double(handles.ROIy0.String));
Y1 = round(str2double(handles.ROIy1.String));

Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'������������� ������','Optical character recognition'}
        
        
        thresh = handles.ParSlider1.Value;
        textlayout = handles.ParMenu1.Value;
        language = handles.ParMenu2.Value;
        
        switch textlayout       % ������������ ������
            
            case 1
                layout = 'Auto';
            case 2
                layout = 'Block';
            case 3
                layout = 'Line';
            case 4
                layout = 'Word';
        end
        
        switch language       % ���� �������������
            
            case 1
                lang = 'English';
            case 2                            
                lang = 'Russian';
            case 3           
                lang = 'Ukrainian';
            case 4           
                lang = 'French';
            case 5           
                lang = 'Dutch';
            case 6           
                lang = 'Spanish';
            case 7           
                lang = 'Finnish';
            case 8           
                lang = 'ChineseTraditional';
            case 9
                lang = 'Japanese';
        end
                
        results = ocr(  Image(Y0:Y1, X0:X1, :),...
                        'TextLayout',layout,...
                        'Language',lang);
                
        boxes = results.WordBoundingBoxes;                          % ����� 
        boxes = boxes(results.WordConfidences > thresh,:);    % ������� ������
        boxes(:,1) = boxes(:,1) + X0;
        boxes(:,2) = boxes(:,2) + Y0;
        
        words = results.Words;                              % ��������� �����
        words = words(results.WordConfidences > thresh);
        
        if isempty(words)   % ���� ��� �����������
            
            if rus
                words = '��� �����������';
            else
                words = 'no results';
            end
            
        end
        
        handles.StatisticsList.String = words;              % ��������� � ����
        setappdata(handles.StatisticsList,'boxes',boxes);   % ��������� �����
                
        StatisticsList_Callback(hObject, eventdata, handles);   % ����� ����������
        
    case {'������ �����-����','Barcode reading'} 
        
    case {'����� �������� � �������','Text region detection'}  
        
    case {'������ �����','Blob analysis'}         
        
        Conn = handles.ParMenu1.Value * 4;              % ���������
        BinarizationType = handles.ParMenu2.Value;      % ��� �����������        
        ForegroundType = handles.ParMenu3.Value;        % ��� ����
        
        BorderBlobs = ~ handles.ParCheckBox1.Value;     % ���/���� ������ �����  
        
        MaximumCount = handles.ParSlider1.Value;
        MinimumBlobArea = handles.ParSlider2.Value;
        MaximumBlobArea = handles.ParSlider3.Value;
        SensOrThersh = handles.ParSlider4.Value;
        
        switch ForegroundType   % ����� ���� ��� ���������� �����������       
            case 1      
                Foreground = 'bright';                
            case 2      
                Foreground = 'dark';                
        end            
        
        if size(Image,3) > 1            % ���� 3 ������ - ������ 1
            Image = rgb2gray(Image);
        end
        
        if ~all(all(Image == 0 | Image == 1))    % ���� �� �/�
            
            switch BinarizationType   % ����� ���� ������ ��� �/�
                
                case 1      % ����������                    
                    Image = imbinarize( Image,'adaptive',...
                                        'Sensitivity',SensOrThersh,...
                                        'ForegroundPolarity',Foreground);
                                    
                case 2      % ���������� (���)                    
                    Image = imbinarize(Image);
                    
                case 3      % ����������                    
                    Image = imbinarize(Image,SensOrThersh);
                    
            end
            
            % ��������� �����������            
            ProcessedImages(end+1).Images = im2double(Image);
            
            if rus
                StringOfImages{end+1} = {'��������� �����������'};
            else
                StringOfImages{end+1} = {'Binarization result'};
            end
        end
        
        % ������ �������� ������� BlobAnalysis
        hBlob = vision.BlobAnalysis;
        hBlob.AreaOutputPort = true;
        hBlob.CentroidOutputPort = true;
        hBlob.BoundingBoxOutputPort = false;
        
        hBlob.PerimeterOutputPort = true;
        hBlob.LabelMatrixOutputPort = true;
        hBlob.Connectivity = Conn;
        hBlob.MaximumCount = MaximumCount;
        hBlob.MinimumBlobArea = MinimumBlobArea;
        hBlob.MaximumBlobArea = MaximumBlobArea;
        hBlob.ExcludeBorderBlobs = BorderBlobs;
        
        % �������� �������, �����, �������� �����
        [AREA,CENTEROID,PERIMETER,LABEL] = step(hBlob, logical(Image)); 
        
        CENTEROID = round(CENTEROID);
        PERIMETER = round(PERIMETER);
                
        % ������� ������ �����
        BlobList = cell(1,size(AREA,1));
        
        for x = 1:size(AREA,1)
            if rus
                BlobList{x} = ['����� � ' num2str(x) ...
                            ': ������� / �������� = ' num2str(AREA(x))...
                            ' / ' num2str(PERIMETER(x)) ' (����.)']; 
            else
                BlobList{x} = ['Blob � ' num2str(x) ...
                            ': area / perimeter = ' num2str(AREA(x))...
                            ' / ' num2str(PERIMETER(x)) ' (pix.)']; 
            end
        end   
        
        if isempty(AREA)        % ���� �� ����� ����� - �����
            if rus
                BlobList = '��� �����������';
            else
                BlobList = 'no results';
            end
        end
        
        % ��������� ����������� ����������� � �������� � ������� �����
        ProcessedImages(end+1).Images = ...
            insertMarker(im2double(Image), CENTEROID, 'Color', 'blue');
            
        if rus
            StringOfImages{end+1} = {'������������ ����� �� �������� �����������'};
        else
            StringOfImages{end+1} = {'Recognized blobs on binary image'};
        end
        
        
        % ��������� ����������� �������� � �������� � ������� �����
        ProcessedImages(end+1).Images = ...
            insertMarker(ProcessedImages(1).Images, CENTEROID, 'Color', 'blue');
        
        if rus
            StringOfImages{end+1} = {'������������ ����� �� ���������'};
        else
            StringOfImages{end+1} = {'Recognized blobs on original image'};
        end
            
        
        handles.StatisticsList.String = BlobList;           % ��������� � ����
        setappdata(handles.StatisticsList,'LABEL',LABEL);   % ��������� ������
                
        StatisticsList_Callback(hObject, eventdata, handles);   % ����� ����������  
        
        
    case {'������������� ���','Face detection'}
        
    case {'������������� �����','People detection'}
        
    case {'������������� ��������','Object detection'}
        
        % ��������� �������
        Pattern = getappdata(handles.PatternAxes,'Pattern');
        
        % ����� ����������� ��������
        if size(Pattern,3) == 3
            Pattern = rgb2gray(Pattern);
        end
        
        if size(Image,3) == 3
            Image = rgb2gray(Image);
            
            % ��������� ����������� ����������� � �������� � ������� �����
            ProcessedImages(end+1).Images = Image;
            if rus
                StringOfImages{end+1} = {'����������� �����������'};
            else
                StringOfImages{end+1} = {'Grayscale image'};
            end
            
        end 
        
        % ��������� ��������� ���������
        MatchThreshold = handles.ParSlider5.Value;
        MaxRatio = handles.ParSlider6.Value;
        MaxNumTrials = handles.ParSlider7.Value;
        Confidence = handles.ParSlider8.Value;
        MaxDistance = handles.ParSlider9.Value;
         
        switch handles.ParMenu1.Value       % ��� ��������������
            
            case 1
                TransformationType = 'similarity';
            case 2
                TransformationType = 'affine';                
            case 3
                TransformationType = 'projective';  
            otherwise
                assert(0,'��� �� ����� �� ���...������� �� ������������ ������� ����');
        end
        
        switch handles.ParMenu2.Value            % ����� ���������
            case 1
                Method = 'Exhaustive';
            case 2
                Method = 'Approximate';
            otherwise
                assert(0,'��� �� ����� �� ���...������� �� ������������ ������� ����');
        end
        
        switch handles.ParMenu4.Value       % �������
            
            case 1
                Metric = 'SAD';                
            case 2
                Metric = 'SSD';
            otherwise
                assert(0,'��� �� ����� �� ���...������� �� ������������ ������� ����');
        end
        
        UpRight = handles.ParCheckBox1.Value;
        UseUnique = handles.ParCheckBox2.Value;
         
        % ��������� ��� ��������� ��� �������� ����� � ����������� ��
        switch handles.ParMenu3.Value
            
            case 1
                
                PatternPoints = detectMSERFeatures(Pattern,...
                                'MaxAreaVariation',handles.ParSlider1.Value,...
                                'ThresholdDelta',handles.ParSlider2.Value,...
                                'RegionAreaRange',...
                                [handles.ParSlider3.Value handles.ParSlider4.Value]);
                
                ScenePoints = detectMSERFeatures(Image,...
                                'MaxAreaVariation',handles.ParSlider1.Value,...
                                'ThresholdDelta',handles.ParSlider2.Value,...
                                'RegionAreaRange',...
                                [handles.ParSlider3.Value handles.ParSlider4.Value]);
                
            case 2
                
                PatternPoints = detectBRISKFeatures(Pattern,...
                                'MinContrast',handles.ParSlider1.Value,...
                                'NumOctaves',handles.ParSlider3.Value,...
                                'MinQuality',handles.ParSlider2.Value);
                
                ScenePoints = detectBRISKFeatures(Image,...
                                'MinContrast',handles.ParSlider1.Value,...
                                'NumOctaves',handles.ParSlider3.Value,...
                                'MinQuality',handles.ParSlider2.Value);
                
            case 3
                
                PatternPoints = detectFASTFeatures(Pattern,...
                                'MinContrast',handles.ParSlider1.Value,...
                                'MinQuality',handles.ParSlider2.Value);
                
                ScenePoints = detectFASTFeatures(Image,...
                                'MinContrast',handles.ParSlider1.Value,...
                                'MinQuality',handles.ParSlider2.Value);
                
            case 4
                
                PatternPoints = detectHarrisFeatures(Pattern,...
                                'FilterSize',handles.ParSlider3.Value,...
                                'MinQuality',handles.ParSlider2.Value);
                
                ScenePoints = detectHarrisFeatures(Image,...
                                'FilterSize',handles.ParSlider3.Value,...
                                'MinQuality',handles.ParSlider2.Value);
                
            case 5
                
                PatternPoints = detectMinEigenFeatures(Pattern,...
                                'FilterSize',handles.ParSlider3.Value,...
                                'MinQuality',handles.ParSlider2.Value);
                
                ScenePoints = detectMinEigenFeatures(Image,...
                                'FilterSize',handles.ParSlider3.Value,...
                                'MinQuality',handles.ParSlider2.Value);
                
            case 6      
                
                PatternPoints = detectSURFFeatures(Pattern,...
                                'MetricThreshold',handles.ParSlider2.Value,...
                                'NumOctaves',handles.ParSlider3.Value,...
                                'NumScaleLevels',handles.ParSlider4.Value);
                
                ScenePoints = detectSURFFeatures(Image,...
                                'MetricThreshold',handles.ParSlider2.Value,...
                                'NumOctaves',handles.ParSlider3.Value,...
                                'NumScaleLevels',handles.ParSlider4.Value);
                SURFSize = 64;
                
            case 7                  
                
                PatternPoints = detectSURFFeatures(Pattern,...
                                'MetricThreshold',handles.ParSlider2.Value,...
                                'NumOctaves',handles.ParSlider3.Value,...
                                'NumScaleLevels',handles.ParSlider4.Value);
                            
                ScenePoints = detectSURFFeatures(Image,...
                                'MetricThreshold',handles.ParSlider2.Value,...
                                'NumOctaves',handles.ParSlider3.Value,...
                                'NumScaleLevels',handles.ParSlider4.Value);
                SURFSize = 128;
                
            otherwise
                assert(0,'��� �� ����� �� ���...������� �� ������������ ������� ����');
        end
        
        % ��������� ���� ������� � �����
        % ��� surf ��������� �����
        if handles.ParMenu3.Value == 6 || handles.ParMenu3.Value == 7
            
            [PatternFeatures, PatternPoints] = extractFeatures(Pattern,PatternPoints,...
                'Upright',UpRight, 'SURFSize',SURFSize);
            
            [SceneFeatures, ScenePoints] = extractFeatures(Image, ScenePoints,...
                'Upright',UpRight, 'SURFSize',SURFSize);
        else
            
            [PatternFeatures, PatternPoints] = extractFeatures(Pattern,PatternPoints,...
                'Upright',UpRight);
            
            [SceneFeatures, ScenePoints] = extractFeatures(Image, ScenePoints,...
                'Upright',UpRight);
            
        end
        
        % ��������� ����������� ����������� � �������� � ������� �����
        ProcessedImages(end+1).Images = ...
            insertMarker(Image, ScenePoints, 'Color', 'blue');
        
        if rus
            StringOfImages{end+1} = {'��� ��������� �������� �����'};
        else
            StringOfImages{end+1} = {'All found keypoints'};
        end
        
        % ���������� ����, ������� ���� �������
        % ��� �������� ���� ��p�� ��� �������
        if      handles.ParMenu3.Value == 1 ||...
                handles.ParMenu3.Value == 6 || ...
                handles.ParMenu3.Value == 7
            
            Pairs = matchFeatures(PatternFeatures, SceneFeatures, 'Method', Method,...
                        'MatchThreshold',MatchThreshold, 'MaxRatio',MaxRatio,...
                        'Metric',Metric, 'Unique',UseUnique);
                    
        else
            
            Pairs = matchFeatures(PatternFeatures, SceneFeatures, 'Method', Method,...
                        'MatchThreshold',MatchThreshold, 'MaxRatio',MaxRatio,...
                        'Unique',UseUnique);
            
        end
        
        % ��������� ����������� ����������� � �������� � ������� �����
        ProcessedImages(end+1).Images = ...
            insertMarker(Image, ScenePoints(Pairs(:,2),:), 'Color', 'blue');
        
        if rus
            StringOfImages{end+1} = {'����������� �������� �����'};
        else
            StringOfImages{end+1} = {'Matched keypoints'};
        end
        
        % �������� �� ���� ��������� ����� ������ ��������� �� �� ������� � Pairs
        MatchedPatternPoints = PatternPoints(Pairs(:, 1), :);
        MatchedScenePoints = ScenePoints(Pairs(:, 2), :);
        
        % ������� ������ �� �������������� ���������
        [~,~,ResultPoints,~] = estimateGeometricTransform(...
                                MatchedPatternPoints, ...
                                MatchedScenePoints,...
                                TransformationType,... 
                                'MaxNumTrials',MaxNumTrials, ...
                                'Confidence',Confidence,...
                                'MaxDistance', MaxDistance);      
        
        % � ��� ������� �������� ��� �� ����� ����������� ��������� ������� 
        Pattern = insertMarker(Pattern, round(PatternPoints.Location), 'Color', 'blue');        
        image(Pattern,'Parent',handles.PatternAxes);
        handles.PatternAxes.Visible = 'off';        
        
        % ��������� ����������� � ����������� ��������� �������
        ProcessedImages(end+1).Images = ...
            insertMarker(Image, ResultPoints, 'Color', 'blue');
        
        if rus
            StringOfImages{end+1} = {'���������� ����������� �������� ����� (����������� �����������)'};
        else
            StringOfImages{end+1} = {'�orrect matched keypoints (grayscale image)'};
        end        
        
        if size(ProcessedImages(1).Images,3) == 3
            % ��������� ����������� � ����������� ��������� �������
            ProcessedImages(end+1).Images = ...
                insertMarker(ProcessedImages(1).Images, ResultPoints, 'Color', 'blue');
            
            if rus
                StringOfImages{end+1} = {'���������� ����������� �������� ����� (�������� �����������)'};
            else
                StringOfImages{end+1} = {'�orrect matched keypoints (original image)'};
            end
        end
        
    case {'�������� 3D-�����������','3-D image creation'}
        
    case {'��������� �����','Video processing'}
        
    case {'�������� ��������','Panorama creation'}
        
    case {'������������� ��������','Motion detection'}
        
    otherwise
        assert(0, '������ � ��������� � ������� ���������');
        
end

% �������� �������� � ���������
setappdata(handles.FileAxes,'ProcessedImages',ProcessedImages);  

% ��������� �������������� ������
handles.VideoMenu.String = string(StringOfImages');  

% ���� ��������� ��������� - �� ����� �����������, ����� ������
if size(StringOfImages,2) == 1
    handles.VideoMenu.Visible = 'off';
else
    handles.VideoMenu.Visible = 'on';
end

% ���� ������ ���� - ������
%(����� ��� ��������� �� ������ ���������, �� ��� � �������������)
if strcmp(handles.StatisticsList.String,'')
    handles.StatisticsList.Visible = 'off';
else
    handles.StatisticsList.Visible = 'on';
end

%%%%%%%%%%%%%%%%%%%%%%% ��������� � ��� ��������
VideoMenu_Callback(hObject, eventdata, handles);

%
%
%


% ���������� ������� �����������/����� ��� ������ ���
function ZoomButton_Callback(~, ~, handles)

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');
Pattern = getappdata(handles.PatternAxes,'Pattern');

% ���� ���� ���������    
if handles.ZoomButton.Value == 0    
    
    try
        handles.ZoomButton.CData = imread([cd '\Icons\Zoom+.png']);
    catch
    end
    
    SetAxesSize(handles.FileAxes,size(UserFile(1).Data,1),size(UserFile(1).Data,2));
    
    if ~isempty(Pattern) % ���� ���� �������
        SetAxesSize(handles.PatternAxes,size(Pattern,1),size(Pattern,2));
    end
    
else        % ��������� ���� ��� ������
    
    try
        handles.ZoomButton.CData = imread([cd '\Icons\Zoom-.png']);
    catch
    end
    
    % �������� ���
    % ��������� ��������� ������, ���������� ��� ���
    AxesSize = getappdata(handles.FileAxes,'InitPosition');
    
    % �������� �������, �� ������� ����� ��������� �������� � ������� ��
    height = size(UserFile(1).Data,1) / ...
        min(size(UserFile(1).Data,1)/AxesSize(4) , size(UserFile(1).Data,2)/AxesSize(3));
    
    width = size(UserFile(1).Data,2) / ...
        min(size(UserFile(1).Data,1)/AxesSize(4) , size(UserFile(1).Data,2)/AxesSize(3));
    
    SetAxesSize(handles.FileAxes, height, width); 
    
    
    % ��� �������    
    if ~isempty(Pattern)    % ���� �� ����
        
        AxesSize = getappdata(handles.PatternAxes,'InitPosition');
        % �������� �������, �� ������� ����� ��������� �������� � ������� ��
        height = size(Pattern,1) / ...
            min(size(Pattern,1)/AxesSize(4) , size(Pattern,2)/AxesSize(3));
        
        width = size(Pattern,2) / ...
            min(size(Pattern,1)/AxesSize(4) , size(Pattern,2)/AxesSize(3));
        
        SetAxesSize(handles.PatternAxes, height, width);
    end
        
end


% ����� ������� ��������
function ROIButton_Callback(hObject, ~, handles)

% ������� ����� � ���
delete(findobj('Parent',handles.FileAxes,'LineStyle','--'));

% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');
w = size(UserFile(1).Data,2);
h = size(UserFile(1).Data,1);

% ���� ����� �� ������, ������ �������� �������������
if hObject == handles.ROIButton        
    
    ROI =  imrect(handles.FileAxes);    % ���� ������������ �������
    coords = round(getPosition(ROI));   % ��������� ��������� ����������
    delete(ROI);                        % ������� ��������� ������������� ������
    
    coords(3) = coords(3) + coords(1);  % �������� ���������� x1 � y1
    coords(4) = coords(4) + coords(2);
    
    % ��������� ����������
    coords = LimitCheck(coords,[1 1 w h],[false false true true]);    
    
    switch Method
        
        case {'������������� ������','Optical character recognition'} 
            
            handles.ROIx0.String = num2str(coords(1));
            handles.ROIy0.String = num2str(coords(2));
            handles.ROIx1.String = num2str(coords(3));
            handles.ROIy1.String = num2str(coords(4));
            
            handles.ROIx0.Value = coords(1);
            handles.ROIy0.Value = coords(2);
            handles.ROIx1.Value = coords(3);
            handles.ROIy1.Value = coords(4);
            
            coords(3) = coords(3) - coords(1);  % ������������ ���������� x1 � y1
            coords(4) = coords(4) - coords(2);  % � ����� � ������
            
            rectangle(  'Position',coords,...
                'Parent',handles.FileAxes,...
                'EdgeColor','r',...
                'LineStyle','--',...
                'LineWidth',2);
            
        case {'������������� ��������','Object detection'}            
            
            Image = UserFile(handles.FrameSlider.Value).Data;
            Pattern = Image(coords(2):coords(4),coords(1):coords(3),:);
            
            SetAxesSize(handles.PatternAxes,size(Pattern,1),size(Pattern,2));
            
            image(Pattern,'Parent',handles.PatternAxes);
            handles.PatternAxes.Visible = 'off';            
            
            setappdata(handles.PatternAxes,'Pattern',Pattern);
            
            handles.ShowPatternImageMenu.Visible = 'on'; 
            
            set([...
                handles.ROIx0;...
                handles.ROIy0;...
                handles.ROIx1;...
                handles.ROIy1;...
                ],'Enable','on');
            
            handles.ROIx0.String = num2str(coords(1));
            handles.ROIy0.String = num2str(coords(2));
            handles.ROIx1.String = num2str(coords(3));
            handles.ROIy1.String = num2str(coords(4));
            
    end
    
else    % ����� �� ������� ���������� � �����
   
    X0 = round(str2double(handles.ROIx0.String));
    X1 = round(str2double(handles.ROIx1.String));
    Y0 = round(str2double(handles.ROIy0.String));
    Y1 = round(str2double(handles.ROIy1.String));
    
    switch Method
        
        case {'������������� ������','Optical character recognition'}    
    
            rectangle(  'Position',[X0 Y0 X1-X0 Y1-Y0],...
                        'Parent',handles.FileAxes,...
                        'EdgeColor','r',...
                        'LineStyle','--',...
                        'LineWidth',2);
                    
        case {'������������� ��������','Object detection'}        
           
            Image = UserFile(handles.FrameSlider.Value).Data;
            Pattern = Image(Y0:Y1,X0:X1,:);
            
            SetAxesSize(handles.PatternAxes,size(Pattern,1),size(Pattern,2));
            
            image(Pattern,'Parent',handles.PatternAxes);
            handles.PatternAxes.Visible = 'off';
            
            setappdata(handles.PatternAxes,'Pattern',Pattern);
            
            handles.ShowPatternImageMenu.Visible = 'on';
            
            set([...
                handles.ROIx0;...
                handles.ROIy0;...
                handles.ROIx1;...
                handles.ROIy1;...
                ],'Enable','on');
    end
                    
end


% ������� ������
function PatternOpenButton_Callback(hObject, eventdata, handles)

% ���� ������� ���� ������, ����� 1
rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% �������� ���� ��� ��������
if rus
    
    [FileName, PathName] = uigetfile(...
        '*.jpeg;*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        '�������� �����������-�������',...
        [cd '\Test Materials']);
else
    [FileName, PathName] = uigetfile(...
        '*.jpeg;*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        'Choose the reference image',...
        [cd '\Test Materials']);
end

if ~FileName        % ��������, ��� �� ������ ����
    return;
end

try     % ������� ������� ��� �����������
        
    [Temp,colors] = imread([PathName FileName]);
    
    if ~isempty(colors)                 % ���� ��������������� -
        Temp = ind2rgb(Temp,colors);    % ��������������� � RGB
    end
    
    Pattern = im2double(Temp);               % ���������� ��������
    width = size(Pattern,2);
    heigth = size(Pattern,1);
    
catch    % �������� �����������
    
    if rus     % ����
        h = errordlg('� ������ ���-�� �� ���. �������� ������','KAACV');
    else
        h = errordlg('File is improper. Choose another file','KAACV');
    end
    
    set(h, 'WindowStyle', 'modal');
    return;
end
    
% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'������������� ��������','Object detection'}
        
        SetAxesSize(handles.PatternAxes,size(Pattern,1),size(Pattern,2));
        
        image(Pattern,'Parent',handles.PatternAxes);
        handles.PatternAxes.Visible = 'off';
        
        setappdata(handles.PatternAxes,'Pattern',Pattern);
        
        handles.ShowPatternImageMenu.Visible = 'on';    
        
        set([...
            handles.ROIx0;...
            handles.ROIy0;...
            handles.ROIx1;...
            handles.ROIy1;...
            ],'Enable','off');
        
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% �������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ������� ������ �����
function FrameSlider_Callback(hObject, eventdata, handles)

% ������� ���������� ����������� ������ �������-�������� � ��� !!!

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');

FrameNumber = round(handles.FrameSlider.Value); % ��������� ����� �����
handles.FrameSlider.Value = FrameNumber;        % ���������� ���������� �������� � ��������


% ���� "�����������" ���������
if handles.ApplyButton.Value == 1
    
    ApplyButton_Callback(hObject, eventdata, handles);        
else
    % �������� CData, �� �������� ����� ������
    set(findobj('Parent',handles.FileAxes,'Tag', 'FrameObj'),...
        'CData',UserFile(FrameNumber).Data);
    
    handles.FileAxes.Visible = 'off';    
    % ������� ������ �������� ��������� � ���
    delete(findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b'));
end

% ����������� ���� � ����� ������ ��� �����
if size(UserFile,2) > 1
    ShowTimeAndFrame(handles, UserFile(1).FrameRate, FrameNumber);         
end


% ������� ���������� � 1
function ParSlider1_Callback(hObject, eventdata, handles)

Value = handles.ParSlider1.Value;

% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'������������� ������','Optical character recognition'}
        Value = round(Value*100)/100;
        
    case {'������ �����','Blob analysis'}   
        Value = round(Value);
    
    case {'������������� ��������','Object detection'}    
        Value = round(Value*100)/100;
        
    otherwise
        assert(0,'� ParSlider1 ������� �������������� ������ �� ���� �������');
        
        
end

handles.ParSlider1.Value = Value;
handles.ParSliderValueText1.String = num2str(Value);


% ������� ���������� � 2
function ParSlider2_Callback(hObject, eventdata, handles)

Value = handles.ParSlider2.Value;

% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method        
    
    case {'������ �����','Blob analysis'}   
        Value = round(Value);
        
    case {'������������� ��������','Object detection'}    
        
        switch handles.ParMenu3.Value   % ��� ���������
            
            case 1 % MSER                
                Value = round(Value);
                
            case {2,3,4,5} % BRISK, FAST, Harris, Minimum eigen
                Value = round(Value*100)/100;
                
            case {6,7}     % SURF  
                Value = round(Value/100)*100;
                
            otherwise
                assert(0,'� ParSlider2 ������� �������������� ������ �� ���� ����������');
        end
                
        
    otherwise
        assert(0,'� ParSlider2 ������� �������������� ������ �� ���� �������');
end

handles.ParSlider2.Value = Value;
handles.ParSliderValueText2.String = num2str(Value);


% ������� ���������� � 3
function ParSlider3_Callback(hObject, eventdata, handles)

Value = handles.ParSlider3.Value;

% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
    case {'������ �����','Blob analysis'}   
        Value = round(Value);
    
    case {'������������� ��������','Object detection'} 
        
        switch handles.ParMenu3.Value   % ��� ���������
            
            case 1 % MSER    
                
                % ���������� ������� ����������, 
                % ����� ������������ �� ����� ���������� ������������ ������� 
                % ���� ������ �����������
                Value = round(Value);                          
                handles.ParSlider3.Value = Value;
                
                if  handles.ParSlider4.Max == Value+1
                    handles.ParSlider4.Enable = 'off';
                    handles.ParSliderValueText4.Enable = 'off';
                    handles.ParSliderValueText4.String = num2str(Value+1);                    
                else
                    handles.ParSlider4.Enable = 'on';
                    handles.ParSliderValueText4.Enable = 'on';
                    
                    handles.ParSlider4.Min = Value + 1;
                    handles.ParSlider4.SliderStep = ...
                        [1/(handles.ParSlider4.Max-Value-1) ...
                        10/(handles.ParSlider4.Max-Value-1)];
                end
                
                
            case {2,6,7} % BRISK, SURF            
                Value = round(Value);
                
            case {4,5} % Harris, Minimum eigen
                Value = round(Value);
                Value = Value - 1 + mod(Value,2);
                          
            otherwise
                assert(0,'� ParSlider3 ������� �������������� ������ �� ���� ����������');
        end
        
    otherwise
        assert(0,'� ParSlider3 ������� �������������� ������ �� ���� �������');
end

handles.ParSlider3.Value = Value;
handles.ParSliderValueText3.String = num2str(Value);


% ������� ���������� � 4
function ParSlider4_Callback(hObject, eventdata, handles)

Value = handles.ParSlider4.Value;
% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
    case {'������ �����','Blob analysis'}   
        Value = round(Value*100)/100;
        
    case {'������������� ��������','Object detection'}
        
        switch handles.ParMenu3.Value   % ��� ���������
            
            % ���������� ������� ����������, 
            % ����� ������������ �� ����� ���������� ������������ ������� 
            % ���� ������ �����������
            case 1 % MSER
                
                Value = round(Value);                                
                handles.ParSlider4.Value = Value;
                
                if  handles.ParSlider3.Min == Value-1
                    handles.ParSlider3.Enable = 'off';
                    handles.ParSliderValueText3.Enable = 'off';
                    handles.ParSliderValueText3.String = num2str(Value-1);
                else
                    handles.ParSlider3.Enable = 'on';
                    handles.ParSliderValueText3.Enable = 'on';
                    handles.ParSlider3.Max = Value - 1;
                    handles.ParSlider3.SliderStep = ...
                        [1/(Value - handles.ParSlider3.Min-1) ...
                        10/(Value - handles.ParSlider3.Min-1)];
                end
                
            case {6,7} % SURF
                Value = round(Value);
                
             otherwise
                 assert(0,'� ParSlider4 ������� �������������� ������ �� ���� �������');
        end                
        
    otherwise
        assert(0,'� ParSlider4 ������� �������������� ������ �� ���� �������');
        
end

handles.ParSlider4.Value = Value;
handles.ParSliderValueText4.String = num2str(Value);


% ������� ���������� � 5
function ParSlider5_Callback(hObject, eventdata, handles)

Value = handles.ParSlider5.Value;
% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
           
    case {'������������� ��������','Object detection'}
        Value = round(Value);
        
    otherwise
        assert(0,'� ParSlider5 ������� �������������� ������ �� ���� �������');
        
end

handles.ParSlider5.Value = Value;
handles.ParSliderValueText5.String = num2str(Value);


% ������� ���������� � 6
function ParSlider6_Callback(hObject, eventdata, handles)

Value = handles.ParSlider6.Value;
% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
           
    case {'������������� ��������','Object detection'}
        Value = round(Value*100)/100;
        
    otherwise
        assert(0,'� ParSlider6 ������� �������������� ������ �� ���� �������');
        
end

handles.ParSlider6.Value = Value;
handles.ParSliderValueText6.String = num2str(Value);


% ������� ���������� � 7
function ParSlider7_Callback(hObject, eventdata, handles)

Value = handles.ParSlider7.Value;
% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
           
    case {'������������� ��������','Object detection'}
        Value = round(Value/10)*10;
        
    otherwise
        assert(0,'� ParSlider7 ������� �������������� ������ �� ���� �������');
        
end

handles.ParSlider7.Value = Value;
handles.ParSliderValueText7.String = num2str(Value);


% ������� ���������� � 8
function ParSlider8_Callback(hObject, eventdata, handles)

Value = handles.ParSlider8.Value;
% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
           
    case {'������������� ��������','Object detection'}
        Value = round(Value);
        
    otherwise
        assert(0,'� ParSlider8 ������� �������������� ������ �� ���� �������');
        
end

handles.ParSlider8.Value = Value;
handles.ParSliderValueText8.String = num2str(Value);


% ������� ���������� � 9
function ParSlider9_Callback(hObject, eventdata, handles)

Value = handles.ParSlider9.Value;
% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
           
    case {'������������� ��������','Object detection'}
        Value = round(Value);
        
    otherwise
        assert(0,'� ParSlider9 ������� �������������� ������ �� ���� �������');
        
end

handles.ParSlider9.Value = Value;
handles.ParSliderValueText9.String = num2str(Value);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ������ ���������� �� �����������
function StatisticsList_Callback(hObject, eventdata, handles)

Value = handles.StatisticsList.Value;

% ������� ������������ ������
GraphObject = findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b');

% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'������������� ������','Optical character recognition'}        
        
        BoxesCoords = getappdata(handles.StatisticsList,'boxes');
        
        % ���� ��� �������, ����� �������
        if isempty(GraphObject)
        
            if ~isempty(BoxesCoords)
                rectangle(  'Position',BoxesCoords(Value,:),...
                    'Parent',handles.FileAxes,...
                    'EdgeColor','b',...
                    'LineStyle','-.',...
                    'LineWidth',2);
            end            
        else        % ����� ��������� ������
            
            set(GraphObject, 'Position', BoxesCoords(Value,:));
            
        end
        
    case {'������ �����','Blob analysis'}
        
        LABEL = getappdata(handles.StatisticsList,'LABEL');
        
        % ���� ��� �������, ����� �������
        if isempty(GraphObject)
        
            if ~isempty(LABEL)
                [y,x] = find(LABEL == Value);
                
                patch(x,y,'b',...
                    'Parent',handles.FileAxes,...
                    'EdgeColor','b',...
                    'LineStyle','-.',...
                    'LineWidth',2);
            end
        else              % ����� ��������� ������      
            [y,x] = find(LABEL == Value);
            set(GraphObject, 'XData',x,'YData',y);
        end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%% ��������� ���� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ������� ����� ������� ��������
function ROIedit_Callback(hObject, eventdata, handles)

% ��������� ����
UserFile = getappdata(handles.FileAxes,'UserFile');

Value = str2double(get(hObject,'String'));  % ������ �������� ����������� ���� 

if isnan(Value)                             % ���� �� ����� - ������
    
    if strcmp(handles.RussianLanguageMenu.Checked,'on')
        errordlg('������� � ������ �������� ��������','KAACV');
    else
        errordlg('Use digits only in this field','KAACV');
    end
    
    set(gcf,'WindowStyle', 'modal');
    
    set(hObject,'String',num2str(get(hObject,'Value')));
    return;
end

Value = round(Value);               % ��������

% ������� �������� � ������� ��� ���������� ��������
switch hObject
    
    case handles.ROIy0
        MaxValue = str2double(handles.ROIy1.String);
        MinValue = 1;
        
    case handles.ROIy1
        MaxValue = size(UserFile(1).Data,1);
        MinValue = str2double(handles.ROIy0.String);
        
    case handles.ROIx0
        MaxValue = str2double(handles.ROIx1.String);
        MinValue = 1;
        
    case handles.ROIx1
        MaxValue = size(UserFile(1).Data,2);
        MinValue = str2double(handles.ROIx0.String);
end

if Value < MinValue     % ��� ������ �� ������� ����������� ���������� ��������
    Value = MinValue;
    
elseif Value > MaxValue
    Value = MaxValue;
end

set(hObject,'String',num2str(Value),'Value',Value);
ROIButton_Callback(hObject, eventdata, handles);


% ������� ����� �������� ���������
function SliderEdit_Callback(hObject, eventdata, handles)

Value = str2double(get(hObject,'String'));  % ������ �������� ����������� ����

EditTag = strsplit(get(hObject,'Tag'),'ValueText');     % �������� ��� ����
SliderTag = [EditTag{1} EditTag{2}];                    % �������� ��� �������������� ��������

if isnan(Value)                             % ���� �� ����� - ������
    
    if strcmp(handles.RussianLanguageMenu.Checked,'on')
        errordlg('������� � ������ �������� ��������','KAACV');
    else
        errordlg('Use digits only in this field','KAACV');
    end
    
    set(gcf,'WindowStyle', 'modal');
    
    set(hObject,'String',num2str(get(eval(['handles.' SliderTag]),'Value')));
    return;
end

% ��������� ��������� ��������
MaxValue = get(eval(['handles.' SliderTag]),'Max');
MinValue = get(eval(['handles.' SliderTag]),'Min');
SliderStep = get(eval(['handles.' SliderTag]),'SliderStep');

Step = SliderStep(1) * (MaxValue - MinValue);   % ��� ��� ����������
Value = round(Value * 1/Step) * Step;         % �������� �������������� �������� 

if Value < MinValue     % ��� ������ �� ������� ����������� ���������� ��������
    Value = MinValue;
    
elseif Value > MaxValue
    Value = MaxValue;
end

set(hObject,'String',num2str(Value));           % ���������� �������� � ����
set(eval(['handles.' SliderTag]),'Value',Value);% � �������

%%%%%%%%%%%%%%%%%%%%%%%%%%%% ���-����� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function ParCheckBox1_Callback(hObject, eventdata, handles)

rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% ������ � ��������� ������ ��������� 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'������ �����','Blob analysis'}
        
        if handles.ParCheckBox1.Value
            
            if  rus
                handles.ParCheckBox1.TooltipString = '������� ��������� �����';
            else
                handles.ParCheckBox1.TooltipString = 'Including border blobs';
            end
        else
            
            if rus
                handles.ParCheckBox1.TooltipString = '�������� ��������� �����';
            else
                handles.ParCheckBox1.TooltipString = 'Excluding border blobs';
            end
        end
end


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
        
        set(MethodMenu,'String',{...
            'Optical character recognition';...
            'Barcode reading';...
            'Text region detection';...
            'Blob analysis';...
            'Face detection';...
            'People detection';...
            'Object detection';...
            '3-D image creation';...
            'Video processing';...
            'Panorama creation';...
            'Motion detection';...
            });
        
    end
        
else                    % ���� ������� �����������
    if rus              % �� �������
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
    else
        set(MethodMenu,'String',{...
            'Optical character recognition';...
            'Barcode reading';...
            'Text region detection';...
            'Blob analysis';...
            'Face detection';...
            'People detection';...
            'Object detection';...
            '3-D image creation';...
            });
    end
end
    

% ��������� ����� �� ������
function value = LimitCheck(number,limit,upper)

assert(isnumeric([number limit]) && islogical(upper),...
                '������������ ������� ������');
            
assert(length(number) == length(limit) && length(limit) == length(upper),...
                '����������� ������� ������ �� �����');

% number - ����������� �����
% limit - ������
% upper = true - ������ ������
% upper = false - ������ �����

value = number;

for x = 1:length(number)
    
    if upper(x)                % ������ ������
        if number(x) > limit(x)
            value(x) = limit(x);
        end
    else                    % ������ �����
        if number(x) < limit(x)
            value(x) = limit(x);
        end
    end
end
    
    
    
    
    
    
    


