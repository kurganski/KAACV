%---------------------------------------------------------------------------------
% KAACVP:           Kurganski Andrew A Computer Vision Processor
% Autor / �����:    Andrew A Kurganski / ���������� ������ ���������
% e-mail:           k-and92@mail.ru
%---------------------------------------------------------------------------------

% !!!!!!!!!!!
% ��������� ROI �������� �����, ���� ��������� � �������� �������
% ����������� ��� ����� �������� ��� ������������� ROI -���� � ��� ������������
% ��� ������ ����������� � keypoint ������ � ������� ����� ���� ����� ���������

%%%% ������������� ����������
function varargout = KAACVP(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @KAACVP_OpeningFcn, ...
                   'gui_OutputFcn',  @KAACVP_OutputFcn, ...
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
function varargout = KAACVP_OutputFcn(~, ~, handles) 
varargout{1} = handles.output;


% ������� ��� ��������
function KAACVP_OpeningFcn(hObject, ~, handles, varargin)

handles.output = hObject;
guidata(hObject, handles);

% ���������� ��������� ���������� ����
setappdata(handles.FileAxes, 'InitPosition',handles.FileAxes.Position);
setappdata(handles.PatternAxes, 'InitPosition',handles.PatternAxes.Position);

% ������ ��� �������� ������ ���������� ������ ���������
set(handles.ParametersPanel.Children,'Visible','off');

% ��������� �������� � ������
try
    handles.PlayPauseButton.CData = imread([cd '\Icons\Play.png']);
    handles.FrameBackButton.CData = imread([cd '\Icons\FrameBack.png']);
    handles.FrameForwardButton.CData = imread([cd '\Icons\FrameForward.png']);
    handles.ZoomButton.CData = imread([cd '\Icons\Zoom+.png']);
catch
    handles.PlayPauseButton.String = '>';
    handles.FrameBackButton.String = '|<<';
    handles.FrameForwardButton.String = '>>|';
    handles.ZoomButton.String = '+';
end

scr_res = get(0, 'ScreenSize');         % �������� ���������� ������
fig = get(handles.KAACVP,'Position');    % �������� ���������� ����

% �������������� ����
set(handles.KAACVP,'Position',...
    [(scr_res(3)-fig(3))/2 (scr_res(4)-fig(4))/2 fig(3) fig(4)]);

% ��������� ������� ��������� ������ ������
WeHaveCV = DoWeHaveThisToolbox('Computer Vision System Toolbox', 7.3);
WeHaveIPT = DoWeHaveThisToolbox('Image Processing Toolbox', 10); 

% �� ���������� ������� ���������� ������
% ������ �������� ����� language = true, �.�.
% ��������� �� ������ ��� ���������� ����������� �������
% �������������� �� ���� ������
language = true;    

if ~WeHaveCV && ~WeHaveIPT
    
    GenerateError('NoCV_NoIPT', language);
    close(handles.KAACVP);
    return;
    
elseif ~WeHaveCV && WeHaveIPT
    
    GenerateError('NoCV', language);
    close(handles.KAACVP);
    return;
    
elseif WeHaveCV && ~WeHaveIPT
    
    GenerateError('NoIPT', language);
    close(handles.KAACVP);
    return;
end

% ��������� �������������� ��� �������
% warning('off','all');

% �� ������� ����������� ����������� (������� ��������, � �� ������ ���������)
% ��������� � kaaip brisk ������� (30 14000)
% ��� �� ��������� � ����������� - ����� 3 ������ ��� rgb2gray, � �� 1�
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ���� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% "������� ����"
function OpenMenu_Callback(hObject, eventdata, handles)

% ��� ������ ������ �������: 
% - �������� �������� �� ������ �������� .fig ������ .m 
% - ��������� ���� ��������/�����. ���� �� ������ - ����������� 
% - ��������� ������ �������� ���� 
%   � ��������� 'UserData'��������� ���� KAACVP -
% - ��������� ��������/������ ���� � ��� FileAxes, �������� ������, ���
%   �������� ����� ����� ��������� �������� 'CData' � ������� FrameSlider
% - ��� ����� - ����������� ������� ������ � ��������� ������ ���������������,
%   � ��� �������� ������ ��� ������/����
% - ������ �������� �������� ����������
% - ������������� ��������� ��������� ��������� � ��������� ���������
% - �������� ������� ��������� ���������� ��� �������� ���������, 
%   ��������������� ���������� ���������

if IsFigFileRunned(handles)
   return; 
end

IsRusLanguage = IsFigureLanguageRussian(handles);

UserFile = OpenMultimediaFile(IsRusLanguage);

if isempty(UserFile)       
    return;
end

warning('on','all');

%%%%%%%%%%%%%%%%%%%%% ����� �������� ��������

% ��������� ������ �������� ���� � ������ ������
setappdata(handles.KAACVP,'UserFile',UserFile);

% ���������/��������� ��� ������ ��������
if UserFile.IsVideo == true
    
    handles.FrameSlider.Min = 1;
    handles.FrameSlider.Max = size(UserFile.Multimedia, 2);
    handles.FrameSlider.SliderStep = ...
        [1/(size(UserFile.Multimedia, 2)-1) 10/(size(UserFile.Multimedia, 2)-1)];
    
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

% ��������� ����������� ���������� �� ���� �����
set([...
    handles.ParametersPanel;...
    handles.CVMethodMenu;...
    handles.ApplyButton;...
    handles.ZoomButton;...
    handles.FileAxesPanel;...
    ],'Visible','on');

set([...
    handles.ShowFrameMenu;...
    ],'Enable','on');


set([...
    handles.ImagesToShowMenu;...
    handles.StatisticsList;...
    handles.PatternAxes;...
    ],'Visible','off');


% ���������� ��� ��� ������� �����/��������
SetNewAxesPosition(handles.FileAxes, UserFile.Height, UserFile.Width);

% ������������ ������ ����, ���� ����������� ������ ������� ���
if GetMaxImageToAxesSideRation(handles.FileAxes, UserFile.Height, UserFile.Width) < 1
    
    handles.ZoomButton.Enable = 'on';
else
    handles.ZoomButton.Enable = 'off';
end

% ������ ������-�������� � ���, � FrameSlider ����� ���� ��������� 'CData' ����� �������
image(  UserFile.Multimedia(1).Frame,...
        'Parent',handles.FileAxes,...
        'Tag', 'FrameObj');

% ����������� ������ ������� ������ ��������� 
% � ����������� �� ���� �����: �����/��������   
SetCVMethodMenuList(handles, UserFile.IsVideo, IsRusLanguage);

% ������ ��� �������� � ��������� ���������
handles.ZoomButton.Value = 0;
handles.PlayPauseButton.Value = 0;      % ������ �� �����
handles.ApplyButton.Value = 0;          % �������� ������ ���������
handles.FrameSlider.Value = 1;          % ��������� ����� ������� �����  
handles.ApplyButton.String = ReturnRusOrEngString(IsRusLanguage, '���������', 'Apply');

% ��������� �������� ���������� 
ZoomButton_Callback([], [], handles);
PlayPauseButton_Callback(hObject, eventdata, handles);
FrameSlider_Callback(hObject, eventdata, handles);  
CVMethodMenu_Callback(hObject, eventdata, handles);


% "�������� ����/�����������"
function ShowFrameMenu_Callback(hObject, eventdata, handles)

ImagesToShow = getappdata(handles.KAACVP,'ImagesToShow');

Image = ImagesToShow(handles.ImagesToShowMenu.Value).Images;

try
    imtool(Image);              % ��� ������-������
catch
    OpenImageOutside(Image);    % ��� exe-������
end


% �������� ROI
function ROIShowMenu_Callback(hObject, eventdata, handles)

UserFile = getappdata(handles.KAACVP,'UserFile');

% ��������� ���������� ����� ROI
ROI_X0 = round(str2double(handles.ROIx0.String));
ROI_X1 = round(str2double(handles.ROIx1.String));
ROI_Y0 = round(str2double(handles.ROIy0.String));
ROI_Y1 = round(str2double(handles.ROIy1.String));

% ����������� ���� � ROI �� ����
Image = UserFile.Multimedia(handles.FrameSlider.Value).Frame;    
ROI = Image(ROI_Y0:ROI_Y1, ROI_X0:ROI_X1, :);

% ���������
try
    imtool(ROI);              % ��� ������-������
catch
    OpenImageOutside(ROI);    % ��� exe-������
end


% "��������� ����"
function SaveFrameMenu_Callback(hObject, eventdata, handles)

UserFile = getappdata(handles.KAACVP,'UserFile');

FrameNumber = handles.FrameSlider.Value;
Image = UserFile.Multimedia(FrameNumber).Frame;
IsRusLanguage = IsFigureLanguageRussian(handles);

SaveImage(Image, FrameNumber, IsRusLanguage);


% "�������� ������"
function ShowPatternImageMenu_Callback(hObject, eventdata, handles)


% "������� ����"
function RussianLanguageMenu_Callback(hObject, eventdata, handles)

if IsFigFileRunned(handles)
   return; 
end

handles.RussianLanguageMenu.Checked = 'on';
handles.EnglishLanguageMenu.Checked = 'off';

UserFile = getappdata(handles.KAACVP,'UserFile');

IsRusLanguage = IsFigureLanguageRussian(handles);

% ��������������� �������� ����������

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

% handles..Label = '';
% handles..Label = '';
% handles..Label = '';

% ��������������� ���������

% handles..TooltipString = '';

% ��������� �������, ���� ����������� ���� ��� ��� ������
if ~isempty(UserFile)
    SetCVMethodMenuList(handles, UserFile.IsVideo, IsRusLanguage);    % ������ ������ �������
    CVMethodMenu_Callback(hObject, eventdata, handles);   % ��������� ������ ����������
end


% "ENGLISH LANGUAGE"
function EnglishLanguageMenu_Callback(hObject, eventdata, handles)

if IsFigFileRunned(handles)
   return; 
end

handles.EnglishLanguageMenu.Checked = 'on';
handles.RussianLanguageMenu.Checked = 'off';

UserFile = getappdata(handles.KAACVP,'UserFile');

IsRusLanguage = IsFigureLanguageRussian(handles);

% ��������������� �������� ����������

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

% handles..Label = '';
% handles..Label = '';
% handles..Label = '';

% ��������������� ���������
% handles..TooltipString = '';

% ��������� �������, ���� ����������� ���� ��� ��� ������
if ~isempty(UserFile)
    SetCVMethodMenuList(handles, UserFile.IsVideo, IsRusLanguage);    % ������ ������ �������
    CVMethodMenu_Callback(hObject, eventdata, handles);   % ��������� ������ ����������
end


%---------------------------------------------------------------------------------

% ����� ������ ���������
function CVMethodMenu_Callback(hObject, eventdata, handles)

% ��� ������ �������:
% - ������� ������ ��� �������� ����������� �� ������ ������ ���������� ��������� ParametersPanel
%   � ��������� ����
% - ������������� �������� ��������� ����� ������� � 1, ����� ��� �� �������
%   ��� ������ ������ ������������� �������� ��������, ��� ����� ����� � ����
% - ��������� ����������� ������������� ���� � ��� ���������
% - � ����������� �� ���������� ������ ��������� �������� ��������� � ���������� 
%   ����������� �������� ���������� ����� �������, ����� ������������ 
%   �� ���� ������� �� ������ ������������� ���������

% ������ � ������ ������������ �������� ����������
set(handles.ParametersPanel.Children,'Visible','off');
handles.ROIShowMenu.Enable = 'off';
handles.ShowPatternImageMenu.Visible = 'off';
handles.PatternAxesPanel.Visible = 'off';

% ������� ������ ���������������� ������
setappdata(handles.KAACVP,'Pattern',[]);
delete([handles.PatternAxes.Children handles.PatternAxes.UserData]);
delete(findobj('Parent',handles.FileAxes,'LineStyle','--'));

% ������������� ��� ��������� ������ ������� � 1,
% ����� ��� �� �������� � ������ Menu.Value > length(Menu.String)
handles.ParMenu1.Value = 1;
handles.ParMenu2.Value = 1;
handles.ParMenu3.Value = 1;
handles.ParMenu4.Value = 1;

handles.ParCheckBox1.Value = 0;
handles.ParCheckBox2.Value = 0;

% ������� ���������
handles.ParCheckBox1.TooltipString = '';
handles.ParCheckBox2.TooltipString = '';

%------------------------------------------------------------------------------
UserFile = getappdata(handles.KAACVP,'UserFile');

ImWidth = UserFile.Width;
ImHeight = UserFile.Height; 
MinWidthHeight = min(ImWidth,ImHeight);     % ����������� �������
MaxWidthHeight = max(ImWidth,ImHeight);     % ������������ �������

% �������� ��������� ������ �� �������������
RandomFrame = randi( size(UserFile,2) );
ImageIsMonochrome = all(all(  UserFile.Multimedia(RandomFrame).Frame(:)== 0 |...
                              UserFile.Multimedia(RandomFrame).Frame(:) == 1));                            

IsRusLanguage = IsFigureLanguageRussian(handles);

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

% ����� ��� ������ SetParSlidersVisibleStatus � SetParMenusVisibleStatus
ShowIt = true; 
        
switch ComputerVisionMethod
    
    case {'������������� ������','Optical character recognition'}
        
        SetParSlidersVisibleStatus(1, ShowIt, handles);
        SetParMenusVisibleStatus(1:2, ShowIt, handles);        
        SetROI_Visible(handles);
        
        handles.ROIx0.String = num2str(1);
        handles.ROIy0.String = num2str(1);
        handles.ROIx1.String = num2str(ImWidth);
        handles.ROIy1.String = num2str(ImHeight);        
        handles.ROIx0.Value = 1;
        handles.ROIy0.Value = 1;
        handles.ROIx1.Value = ImWidth;
        handles.ROIy1.Value = ImHeight;
        
        % ����� �������������
        handles.ParSlider1.Min              = 0.01;
        handles.ParSlider1.Max              = 1;
        handles.ParSlider1.SliderStep       = [0.01/0.99 0.1/0.99];
        handles.ParSlider1.Value            = 0.5;
        handles.ParSliderValueText1.String  = '0.5';   
        
        if IsRusLanguage 
            handles.ParMenuText1.String = '������������ ������';
            handles.ParMenu1.String = { '����';
                                        '����';
                                        '�����';
                                        '�����'};

            handles.ParMenuText2.String = '�������������� ����';
            
            % ��������� ������� �������������� ����������
            try  
                % ���� ��������� ����� ocr, ����� ���������� ����� 
                ocr(ones(10),'Language','Russian');  

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

            % ��������� ������� �������������� ����������
            try 
                % ���� ��������� ����� ocr, ����� ���������� ����� 
                ocr(ones(10),'Language','Russian');

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
        
        % ��������� ROI / �������       
        ROIPosition = [1 1 ImWidth-1 ImHeight-1];
        X0Y0X1Y1Coords = [1 1 ImWidth ImHeight];        
        RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);
        
    case {'������ �����-����','Barcode reading'} 
        
    case {'����� �������� � �������','Text region detection'}  
        
    case {'������ �����','Blob analysis'}   
        
        SetParSlidersVisibleStatus(1:3, ShowIt, handles);
        SetParMenusVisibleStatus(1, ShowIt, handles);   
        
        if ~ImageIsMonochrome          
            
            SetParSlidersVisibleStatus(4, ShowIt, handles);
            SetParMenusVisibleStatus(2:3, ShowIt, handles);        
        end
        
        handles.ParCheckBox1.Visible = 'on';
        
        % ������������ ���������� �����
        handles.ParSlider1.Min              = 1;
        handles.ParSlider1.Max              = ImWidth * ImHeight;
        handles.ParSlider1.SliderStep       = [1/(ImWidth*ImHeight-1) 10/(ImWidth*ImHeight-1)];
        handles.ParSlider1.Value            = round(ImWidth * ImHeight / 2);
        handles.ParSliderValueText1.String  = num2str(round(ImWidth * ImHeight / 2));         
        
        % ����������� ������� �����
        handles.ParSlider2.Min              = 0;
        handles.ParSlider2.Max              = ImWidth * ImHeight;
        handles.ParSlider2.SliderStep       = [1/(ImWidth*ImHeight) 10/(ImWidth*ImHeight)];
        if ImWidth*ImHeight <= 50            
            handles.ParSlider2.Value            = 0;
            handles.ParSliderValueText2.String  = '0';
        else            
            handles.ParSlider2.Value            = 50;
            handles.ParSliderValueText2.String  = '50';
        end
        
        % ������������ ������� �����
        handles.ParSlider3.Min              = 1;
        handles.ParSlider3.Max              = ImWidth*ImHeight;
        handles.ParSlider3.SliderStep       = [1/(ImWidth*ImHeight-1) 10/(ImWidth*ImHeight-1)];
        handles.ParSlider3.Value            = round(ImWidth * ImHeight / 2);
        handles.ParSliderValueText3.String  = num2str(round(ImWidth * ImHeight / 2)); 
        
        
        % ����������������
        handles.ParSlider4.Min              = 0;
        handles.ParSlider4.Max              = 1;
        handles.ParSlider4.SliderStep       = [0.01 0.1];
        handles.ParSlider4.Value            = 0.5;
        handles.ParSliderValueText4.String  = '0.5';       
        
        % ���������
        handles.ParMenu1.String = { '4';'8';};
        
        handles.ParCheckBox1.Value = 1;        
        
        if IsRusLanguage            
            handles.ParMenuText1.String = '���������';
            handles.ParMenuText2.String = '��� �����������';
            handles.ParMenu2.String = {'����������';'���������� (���)';'����������';};
            handles.ParMenuText3.String = '���';
            handles.ParMenu3.String = {'������';'�����';};
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
            handles.ParMenu2.String = {'Adaptive';'Global (Otsu)';'Global'};
            handles.ParMenuText3.String = 'Foreground';
            handles.ParMenu3.String = {'Dark';'Bright';};
            handles.ParSliderText1.String = 'Maximum number of blobs:'; 
            handles.ParSliderText2.String = 'Minimum blob area: ';
            handles.ParSliderText3.String = 'Maximum blob area: '; 
            handles.ParSliderText4.String = 'Sensitivity / Threshold: '; 
            
            handles.ParCheckBox1.String = 'Border blobs';    
            
            handles.ParCheckBox1.TooltipString = 'Including border blobs';
            handles.ParSlider4.TooltipString = 'Adaptive binarization sensitivity';
        end
                
        
    case {'������������� ���','Face detection'}        
        
        SetParSlidersVisibleStatus(1:6, ShowIt, handles);
        SetParMenusVisibleStatus(1, ShowIt, handles);        
        SetROI_Visible(handles);        
        
        handles.ParMenu1.Visible = 'on';
        handles.ParMenuText1.Visible = 'on';
        
        handles.ROIx0.String = num2str(1);
        handles.ROIy0.String = num2str(1);
        handles.ROIx1.String = num2str(ImWidth);
        handles.ROIy1.String = num2str(ImHeight);        
        handles.ROIx0.Value = 1;
        handles.ROIy0.Value = 1;
        handles.ROIx1.Value = ImWidth;
        handles.ROIy1.Value = ImHeight;
        
        if IsRusLanguage
            
            handles.ParMenuText1.String = '������ �������������';
            handles.ParMenu1.String = { '����� (CART)';...
                                        '����� (LBP)';...
                                        '���� ����';...
                                        '���� ���� (�������)';...
                                        '���� ���� (�����)';...
                                        '����� ����';...
                                        '������ ����';...
                                        '����� ���� (CART)';...
                                        '������ ���� (CART)';...
                                        '�������';...
                                        '���';...
                                        '���';...
                                        };                                    
                                    
            handles.ParSliderText1.String = '����������� ������ �������: '; 
            handles.ParSliderText2.String = '������������ ������ �������: '; 
            handles.ParSliderText3.String = '����������� ������ �������: '; 
            handles.ParSliderText4.String = '������������ ������ �������: '; 
            handles.ParSliderText5.String = '��� ���������������: '; 
            handles.ParSliderText6.String = '����� �������: '; 
            
        else            
            handles.ParMenuText1.String = 'Classification model';
            handles.ParMenu1.String = { 'Frontal face (CART)';...
                                        'Frontal face (LBP)';...
                                        'Upper body';...
                                        'Eye pair (big)';...
                                        'Eye pair (small)';...
                                        'Left eye';...
                                        'Right eye';...
                                        'Left eye (CART)';...
                                        'Right eye (CART)';...
                                        'Profile face';...
                                        'Mouth';...
                                        'Nose';...
                                        };
                                    
            handles.ParSliderText1.String = 'Minimal object height: '; 
            handles.ParSliderText2.String = 'Maximum object height: '; 
            handles.ParSliderText3.String = 'Minimal object width: '; 
            handles.ParSliderText4.String = 'Maximum object width: '; 
            handles.ParSliderText5.String = 'Scale factor: ';
            handles.ParSliderText6.String = 'Merge Threshold: '; 
            
        end     
        
        % ��� ���������������
        handles.ParSlider5.Min              = 1.0001;
        handles.ParSlider5.Max              = 5;
        handles.ParSlider5.SliderStep       = [0.0001/3.9999 0.001/3.9999];
        handles.ParSlider5.Value            = 1.1;
        handles.ParSliderValueText5.String  = '1.1';
        
        % ����� �������
        handles.ParSlider6.Min              = 1;
        handles.ParSlider6.Max              = 1000;
        handles.ParSlider6.SliderStep       = [1/999 10/999];
        handles.ParSlider6.Value            = 4;
        handles.ParSliderValueText6.String  = '4'; 
            
        % ��������� ROI / �������       
        ROIPosition = [1 1 ImWidth-1 ImHeight-1];
        X0Y0X1Y1Coords = [1 1 ImWidth ImHeight];        
        RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);
        
        % ��� ������ ���� ����� ��������� �������� 1-4
        ParMenu1_Callback(hObject, eventdata, handles);
        
    case {'������������� �����','People detection'}
        
    case {'������������� ��������','Object detection'}
        
        SetParSlidersVisibleStatus(5:9, ShowIt, handles);
        SetParMenusVisibleStatus(1:4, ShowIt, handles);        
        SetROI_Visible(handles);    
        
        handles.ShowPatternImageMenu.Visible = 'on';
        handles.PatternAxesPanel.Visible = 'on';
        handles.PatternOpenButton.Visible = 'on';
        
        handles.ParCheckBox2.Visible = 'on';       
        
        handles.ROIx0.String = num2str(1);
        handles.ROIy0.String = num2str(1);
        handles.ROIx1.String = num2str(ImWidth);
        handles.ROIy1.String = num2str(ImHeight);        
        handles.ROIx0.Value = 1;
        handles.ROIy0.Value = 1;
        handles.ROIx1.Value = ImWidth;
        handles.ROIy1.Value = ImHeight;         
        
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
        handles.ParSlider7.SliderStep       = [10/99990 100/99990];
        handles.ParSlider7.Value            = 1000;
        handles.ParSliderValueText7.String  = '1000';  
        
        % ������� �������
        handles.ParSlider8.Min              = 1;
        handles.ParSlider8.Max              = 99.99;
        handles.ParSlider8.SliderStep       = [0.01/98.99 0.1/98.99];
        handles.ParSlider8.Value            = 90;
        handles.ParSliderValueText8.String  = '90';  
        
        % ����. ���������� ����� ������ � ���������
        handles.ParSlider9.Min              = 1;
        handles.ParSlider9.Max              = MinWidthHeight/4;
        handles.ParSlider9.SliderStep       = [1/(MinWidthHeight/4 - 1) 10/(MinWidthHeight/4 - 1)];
        handles.ParSlider9.Value            = 2;
        handles.ParSliderValueText9.String  = '2';          
        
        if IsRusLanguage
                                     
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
                                    
            handles.ParSliderText5.String = 'Match threshold: '; 
            handles.ParSliderText6.String = 'Ratio threshold: '; 
            handles.ParSliderText7.String = 'Maximum number of random trials: '; 
            handles.ParSliderText8.String = 'Confidence: ';            
            handles.ParSliderText9.String = 'Max distance point/projection: '; 
            
            handles.ParCheckBox1.String = 'Use orientation';             
            handles.ParCheckBox2.String = 'Only unique';  
            handles.ParCheckBox2.TooltipString = 'Match results are only unique keypoints';
            handles.ParSlider9.TooltipString = 'Maximum distance from point to projection';
                       
        end         % IsRusLanguage
        
        % ��������� ���������
        ParMenu3_Callback(hObject, eventdata, handles);
        ParCheckBox1_Callback(hObject, eventdata, handles);
        ParCheckBox2_Callback(hObject, eventdata, handles);
        
        % ��������� �������      
        ROIPosition = [1 1 ImWidth-1 ImHeight-1];
        X0Y0X1Y1Coords = [1 1 ImWidth ImHeight];        
        RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);
        
    case {'�������� 3D-�����������','3-D image creation'}        
        
        SetParSlidersVisibleStatus(5:9, ShowIt, handles);
        SetParMenusVisibleStatus(1:4, ShowIt, handles);      
        SetROI_Visible(handles); 
        
        handles.ShowPatternImageMenu.Visible = 'on';
        handles.PatternAxesPanel.Visible = 'on';
        
        handles.ParCheckBox1.Visible = 'on';    
        handles.ParCheckBox2.Visible = 'on';   
        
        % ������������ ����� ��������� ���������
        % NumTrials �� estimateFundamentalMatrix()
        handles.ParSlider1.Min              = 10;
        handles.ParSlider1.Max              = 100000;
        handles.ParSlider1.SliderStep       = [10/99990 100/99990];
        handles.ParSlider1.Value            = 1000;
        handles.ParSliderValueText1.String  = '1000';  
        
        % ������� �������
        % Confidence �� estimateFundamentalMatrix()
        handles.ParSlider2.Min              = 1;
        handles.ParSlider2.Max              = 99.99;
        handles.ParSlider2.SliderStep       = [0.01/98.99 0.1/98.99];
        handles.ParSlider2.Value            = 90;
        handles.ParSliderValueText2.String  = '90';
        
        % ����� ���������� 
        % DistanceThreshold �� estimateFundamentalMatrix() 
        handles.ParSlider3.Min              = 0.001;
        handles.ParSlider3.Max              = 5;
        handles.ParSlider3.SliderStep       = [0.001/4.999 0.01/4.999];
        handles.ParSlider3.Value            = 0.01;
        handles.ParSliderValueText3.String  = '0.01';
        
        % ����������� ������� inlier
        % InlierPercentage �� estimateFundamentalMatrix() 
        handles.ParSlider4.Min              = 1;
        handles.ParSlider4.Max              = 99;
        handles.ParSlider4.SliderStep       = [1/98 10/98];
        handles.ParSlider4.Value            = 50;
        handles.ParSliderValueText4.String  = '50';
        
        % ����� ���������
        % MatchThreshold �� matchFeatures()
        handles.ParSlider5.Min              = 1;
        handles.ParSlider5.Max              = 100;
        handles.ParSlider5.SliderStep       = [1/99 10/99];
        handles.ParSlider5.Value            = 10;
        handles.ParSliderValueText5.String  = '10'; 
        
        % ����� ���������
        % MaxRatio �� matchFeatures()
        handles.ParSlider6.Min              = 0.01;
        handles.ParSlider6.Max              = 1;
        handles.ParSlider6.SliderStep       = [0.01/0.99 0.1/0.99];
        handles.ParSlider6.Value            = 0.1;
        handles.ParSliderValueText6.String  = '0.1';
        
        % ����� (SURF)
        handles.ParSlider7.Min              = 100;
        handles.ParSlider7.Max              = 100000;
        handles.ParSlider7.SliderStep       = [100/999900 1000/999900];
        handles.ParSlider7.Value            = 1000;
        handles.ParSliderValueText7.String  = '1000';
        
        % ����� ������� �������� (SURF)
        handles.ParSlider8.Min              = 3;
        handles.ParSlider8.Max              = 8;
        handles.ParSlider8.SliderStep       = [1/5 1/5];
        handles.ParSlider8.Value            = 4;
        handles.ParSliderValueText8.String  = '4';
        
        % ����� ����� (SURF)
        handles.ParSlider9.Min              = 1;
        handles.ParSlider9.Max              = 6;
        handles.ParSlider9.SliderStep       = [1/5 1/5];
        handles.ParSlider9.Value            = 3;
        handles.ParSliderValueText9.String  = '3';
        
        if IsRusLanguage
            
            handles.ParSliderText1.String = '����� ���������: '; 
            handles.ParSliderText2.String = '������� �������: ';
            handles.ParSliderText3.String = '����� ����������: '; 
            handles.ParSliderText4.String = '���. ����� ���������� �����, %: ';
            
            handles.ParSliderText5.String = '����� ���������: '; 
            handles.ParSliderText6.String = '����� ���������: '; 
            
            handles.ParSliderText7.String = '����� (SURF):';
            handles.ParSliderText8.String = '����� ������� �������� (SURF):';
            handles.ParSliderText9.String = '����� ����� (SURF):';
            
            handles.ParMenuText1.String = '����� ���������';
            handles.ParMenu1.String = { '�������������';...
                                        '���������������';...
                                        };
                                    
            handles.ParMenuText2.String = '������� ���������';
            handles.ParMenu2.String = { '����� ������� ��������';...
                                        '����� ��������� ���������';...
                                        }; 
                                    
            handles.ParMenuText3.String = '����� ���������� ��������������� �������';
            handles.ParMenu3.String = { 'Norm8Point';...
                                        'LMedS';...
                                        'RANSAC';...
                                        'MSAC';...
                                        'LTS';...
                                        }; 
                                    
            handles.ParMenuText4.String = '������� ���������� ��������������� �������';
            handles.ParMenu4.String = { '�������';...
                                        '��������������';...
                                        };
                                    
            handles.ParCheckBox1.String = '���������� (128)'; 
            handles.ParCheckBox1.TooltipString = '������������ ������ SURF ���������� (128)';             
            handles.ParCheckBox2.String = '������ ����������';  
            handles.ParCheckBox2.TooltipString = '��������� ������� - ������ ���������� �������� �����';
            
        else
            
            handles.ParSliderText1.String = 'Number of trials: '; 
            handles.ParSliderText2.String = 'Confidence: ';
            handles.ParSliderText3.String = 'Distance threshold: '; 
            handles.ParSliderText4.String = 'Minimum inlier, %: ';
            
            handles.ParSliderText5.String = 'Match Threshold: '; 
            handles.ParSliderText6.String = 'Ratio threshold: '; 
            
            handles.ParSliderText7.String = 'Threshold (SURF):';
            handles.ParSliderText8.String = 'Number of scale levels (SURF):';
            handles.ParSliderText9.String = 'Octaves number (SURF):';           
            
            handles.ParMenuText1.String = 'Match method';
            handles.ParMenu1.String = { 'Exhaustive';...
                                        'Approximate';...
                                        };
                                    
            handles.ParMenuText2.String = 'Match metric';
            handles.ParMenu2.String = { 'Sum of absolute differences';...
                                        'Sum of squared differences';...
                                        };
                                    
            handles.ParMenuText3.String = '����� ���������� ��������������� �������';
            handles.ParMenu3.String = { 'Norm8Point';...
                                        'LMedS';...
                                        'RANSAC';...
                                        'MSAC';...
                                        'LTS';...
                                        }; 
                                    
            handles.ParMenuText4.String = 'Fundamental matrix distance type';
            handles.ParMenu4.String = { 'Sampson';...
                                        'Algebraic';...
                                        };
                                    
            handles.ParCheckBox1.String = 'Descriptor (128)';     
            handles.ParCheckBox1.TooltipString = 'Use full SURF descriptor (128)';        
            handles.ParCheckBox2.String = 'Only unique';  
            handles.ParCheckBox2.TooltipString = 'Match results are only unique keypoints';
        end
               
        % ��������� ���������
        ParMenu3_Callback(hObject, eventdata, handles);
        ParCheckBox1_Callback(hObject, eventdata, handles);
        ParCheckBox2_Callback(hObject, eventdata, handles);
        
        % ��������� �������      
        ROIPosition = [1 1 ImWidth-1 ImHeight-1];
        X0Y0X1Y1Coords = [1 1 ImWidth ImHeight];        
        RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);        
        
    case {'��������� �����','Video processing'}
        
    case {'�������� ��������','Panorama creation'}
        
    case {'������������� ��������','Motion detection'}
        
    otherwise
        assert(0, '������ � ��������� � ������� ���������');
        
end

%---------------------------------------------------------------------------------

% ����� ������������� �����/����������� �� ������ ���������
function ImagesToShowMenu_Callback(~, ~, handles)

% � �������� ��������� ���������� ��������� �����������-������ ���������,
% ������� ������������ ����� �������
% ��� ���������� 'ImagesToShow' � �������� � 'UserData' ��������� ����

% ������� ����������� ������ ��������
ShowMultimediaFile(handles);


% ���� � 1 ���������� 
function ParMenu1_Callback(hObject, eventdata, handles)
        
UserFile = getappdata(handles.KAACVP,'UserFile');

ImWidth = UserFile.Width;
ImHeight = UserFile.Height;

ComputerVisionMethod = string(handles.CVMethodMenu.String( handles.CVMethodMenu.Value ));

switch ComputerVisionMethod
    
    case {'������������� ���','Face detection'}        
        
        handles.ParSlider1.Enable = 'on';
        handles.ParSlider2.Enable = 'on';
        handles.ParSlider3.Enable = 'on';
        handles.ParSlider4.Enable = 'on';
        
        % ��������� ������ �����������, �� ������� ������ ������
        % ���� ������ ����� ��������� ��� �����������
        [TrainModelSize, ~] = ReturnFaceDetectorTrainModelAndSize(...
                string( handles.ParMenu1.String( handles.ParMenu1.Value ) ));
        
        %-----------------------------------------------------------
        % ��������� �������� ������������� ������� ����������: �� min � max
        % ����� ��������� ����������� �������� ������ ��������� (����� �� ���� max < min)
        % �� 'Value' ������ ���� ����� ��������������� �������� � ����� ������
        % � �������� ������ ������������ ��������� �� ������� �������� ��� �� ������
                
        % ����������� ������ �������
        handles.ParSlider1.Min              = TrainModelSize(1);            % ������ �����
        handles.ParSlider1.Max              = ImHeight - 1;
        handles.ParSlider1.SliderStep       = [ 1 /(ImHeight-1-TrainModelSize(1))...
                                                10/(ImHeight-1-TrainModelSize(1))];
        handles.ParSlider1.Value            = TrainModelSize(1);            % ��������
        handles.ParSliderValueText1.String  = num2str(TrainModelSize(1));   
        
        % ������������ ������ �������
        handles.ParSlider2.Min              = TrainModelSize(1) + 1;
        handles.ParSlider2.Max              = ImHeight;                     % ������ �����
        handles.ParSlider2.SliderStep       = [ 1 /(ImHeight-TrainModelSize(1)-1)...
                                                10/(ImHeight-TrainModelSize(1)-1)];
        handles.ParSlider2.Value            = ImHeight;                     % ��������
        handles.ParSliderValueText2.String  = num2str(ImHeight);            
        
        % ����������� ������ �������
        handles.ParSlider3.Min              = TrainModelSize(2);            % ������ �����
        handles.ParSlider3.Max              = ImWidth - 1;
        handles.ParSlider3.SliderStep       = [ 1 /(ImWidth-1-TrainModelSize(2))...
                                                10/(ImWidth-1-TrainModelSize(2))];
        handles.ParSlider3.Value            = TrainModelSize(2);            % ��������
        handles.ParSliderValueText3.String  = num2str(TrainModelSize(2));   
        
        % ������������ ������ �������        
        handles.ParSlider4.Min              = TrainModelSize(2) + 1;        
        handles.ParSlider4.Max              = ImWidth;                      % ������ �����
        handles.ParSlider4.SliderStep       = [ 1 /(ImWidth-TrainModelSize(2)-1) ...
                                                10/(ImWidth-TrainModelSize(2)-1)];
        handles.ParSlider4.Value            = ImWidth;                      % ��������
        handles.ParSliderValueText4.String  = num2str(ImWidth);
        
        %-----------------------------------------------------------
        
end    


% ���� � 2 ���������� 
function ParMenu2_Callback(hObject, eventdata, handles)

% � ����������� �� ������ ������������ ���������� ����������  
% ��������������� ��������� �������� ����������

ComputerVisionMethod = string(handles.CVMethodMenu.String( handles.CVMethodMenu.Value ));
ParMenu2Method = string(handles.ParMenu2.String( handles.ParMenu2.Value ));

switch ComputerVisionMethod
    
    case {'������ �����','Blob analysis'} 
        
        switch ParMenu2Method
            
            case {'����������', 'Adaptive'}
                
                handles.ParSlider4.Visible = 'on';
                handles.ParSliderText4.Visible = 'on';
                handles.ParSliderValueText4.Visible = 'on';
                
                handles.ParMenu3.Visible = 'on';
                handles.ParMenuText3.Visible = 'on';
            
            case {'���������� (���)', 'Global (Otsu)'}
                
                handles.ParSlider4.Visible = 'off';
                handles.ParSliderText4.Visible = 'off';
                handles.ParSliderValueText4.Visible = 'off';
                
                handles.ParMenu3.Visible = 'off';
                handles.ParMenuText3.Visible = 'off';
            
            case {'����������', 'Global'}
                
                handles.ParSlider4.Visible = 'on';
                handles.ParSliderText4.Visible = 'on';
                handles.ParSliderValueText4.Visible = 'on';
                
                handles.ParMenu3.Visible = 'off';
                handles.ParMenuText3.Visible = 'off';
                
            otherwise
                assert(0,'� ParMethod2 ������� �������������� ������ �� ���� �������');
        
        end     % switch ParMenu2Method 
        
end             % switch ComputerVisionMethod


% ���� � 3 ���������� 
function ParMenu3_Callback(hObject, eventdata, handles)

% � ����������� �� ������ ������������ ���������� ����������  
% ��������������� ��������� �������� ����������

IsRusLanguage = IsFigureLanguageRussian(handles);

UserFile = getappdata(handles.KAACVP,'UserFile');

MaxOfWidthAndHeight = max(UserFile.Width, UserFile.Height);
MinOfWidthAndHeight = min(UserFile.Width, UserFile.Height);

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));
ParMenu3Method = string(handles.ParMenu3.String( handles.ParMenu3.Value ));

switch ComputerVisionMethod
    
%----------------------------------------------------------- 
    case {'������������� ��������','Object detection'}    
                
        ShowIt = true;
        HideIt = false;
        
        % ����� ��� ��������, �������� ����� ������ ������
        SetParSlidersVisibleStatus(1:4, HideIt, handles);
        
        handles.ParCheckBox1.Visible = 'off';
        
        handles.ParSlider1.Enable = 'on';
        handles.ParSlider2.Enable = 'on';
        handles.ParSlider3.Enable = 'on';
        handles.ParSlider4.Enable = 'on';        
        
        % ��������� � ������
        handles.ParMenuText4.Value = 1;
        
        switch ParMenu3Method
            
            case {'MSER'}   
                                    
                handles.ParCheckBox1.Visible = 'on';                
                handles.ParCheckBox1.Visible = 'on';
                
                SetParSlidersVisibleStatus(1:4, ShowIt, handles);
                
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
                
                %-----------------------------------------------------------
                % ��������� �������� ������������� ������� ����������: �� min � max
                % ����� ��������� ����������� �������� ��������� (����� �� ���� max < min)
                % �� 'Value' ������ ���� ����� ��������������� �������� � ����� ������
                % � �������� ������ ������������ ��������� �� ������� ��������� ��������
                
                handles.ParSlider3.Min              = 1;        % ������ �����
                handles.ParSlider3.Max              = MaxOfWidthAndHeight - 1;  
                handles.ParSlider3.SliderStep       = [ 1/(MaxOfWidthAndHeight - 1)...
                                                        1/(MaxOfWidthAndHeight - 1)];
                handles.ParSlider3.Value            = 1;        % ��������
                handles.ParSliderValueText3.String  = '1';      
                
                handles.ParSlider4.Min              = 2;
                handles.ParSlider4.Max              = MaxOfWidthAndHeight;          % ������ �����
                handles.ParSlider4.SliderStep       = [ 1/(MaxOfWidthAndHeight - 1) ...
                                                        1/(MaxOfWidthAndHeight - 1)];
                handles.ParSlider4.Value            = MaxOfWidthAndHeight;          % ��������
                handles.ParSliderValueText4.String  = num2str(MaxOfWidthAndHeight); 
                
                %-----------------------------------------------------------
                        
                if IsRusLanguage 
                    
                    handles.ParSliderText1.String = '������������ �������� �������:';
                    handles.ParSliderText2.String = '��� ������:';
                    handles.ParSliderText3.String = '����������� �������:';
                    handles.ParSliderText4.String = '������������ �������:';
                    
                    handles.ParMenuText4.String = '������� ���������';
                    handles.ParMenu4.String = { '����� ������� ��������';...
                                                '����� ��������� ���������';...
                                                };  
                else
                    handles.ParSliderText1.String = 'Maximum area variation:';
                    handles.ParSliderText2.String = 'Threshold step size:';
                    handles.ParSliderText3.String = 'Minimum area:';
                    handles.ParSliderText4.String = 'Maximum area:';
                    
                    handles.ParMenuText4.String = 'Match metric';
                    handles.ParMenu4.String = { 'Sum of absolute differences';...
                                                'Sum of squared differences';...
                                                };                  
                end
                                
            case {'BRISK'}
                
                handles.ParCheckBox1.Visible = 'on';
                
                SetParSlidersVisibleStatus(1:3, ShowIt, handles);
                
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
                
                if IsRusLanguage 
                    
                    handles.ParSliderText1.String = '����������� �������������:';
                    handles.ParSliderText2.String = '����������� ��������:';
                    handles.ParSliderText3.String = '����� �����:';
                    
                    handles.ParMenuText4.String = '������� ���������';
                    handles.ParMenu4.String = { '��������';...
                                                };                    
                else
                    handles.ParSliderText1.String = 'Minimum contrast:';
                    handles.ParSliderText2.String = 'Minimum quality:';
                    handles.ParSliderText3.String = 'Octaves number:';
                    
                    handles.ParMenuText4.String = 'Match metric';
                    handles.ParMenu4.String = { 'Hamming';...
                                                };                    
                end                
            case {'FAST'}
                             
                SetParSlidersVisibleStatus(1:2, ShowIt, handles);               
                
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
                
                if IsRusLanguage 
                    
                    handles.ParSliderText1.String = '����������� �������������:';
                    handles.ParSliderText2.String = '����������� ��������:';
                    
                    handles.ParMenuText4.String = '������� ���������';
                    handles.ParMenu4.String = {'��������'};                    
                else
                    handles.ParSliderText1.String = 'Minimum contrast:';
                    handles.ParSliderText2.String = 'Minimum quality:';
                    
                    handles.ParMenuText4.String = 'Match metric';
                    handles.ParMenu4.String = {'Hamming'};                    
                end
                
            case {'�������', 'Harris'}
                
                SetParSlidersVisibleStatus(2:3, ShowIt, handles);                
                                
                handles.ParSlider3.Min              = 3;
                handles.ParSlider3.Max              = MinOfWidthAndHeight;
                handles.ParSlider3.SliderStep       = [2/(MinOfWidthAndHeight-3) 2/(MinOfWidthAndHeight-3)];
                handles.ParSlider3.Value            = 3;
                handles.ParSliderValueText3.String  = '3';
                
                handles.ParSlider2.Min              = 0;
                handles.ParSlider2.Max              = 1;
                handles.ParSlider2.SliderStep       = [0.01 0.1];
                handles.ParSlider2.Value            = 0.1;
                handles.ParSliderValueText2.String  = '0.1';
                
                if IsRusLanguage 
                    
                    handles.ParSliderText3.String = '������ ���� �������:';
                    handles.ParSliderText2.String = '����������� ��������:';
                    
                    handles.ParMenuText4.String = '������� ���������';
                    handles.ParMenu4.String = { '��������';...
                                                };
                    
                else
                    handles.ParSliderText3.String = 'Filter dimension:';
                    handles.ParSliderText2.String = 'Minimum quality:';
                    
                    handles.ParMenuText4.String = 'Match metric';
                    handles.ParMenu4.String = { 'Hamming';...
                                                };                    
                end                
                
            case {'������������ ������������ ��������', 'Minimum eigen'}                
                             
                SetParSlidersVisibleStatus(2:3, ShowIt, handles);                
                
                handles.ParSlider3.Min              = 3;
                handles.ParSlider3.Max              = MaxOfWidthAndHeight;
                handles.ParSlider3.SliderStep       = [2/(MaxOfWidthAndHeight-3) 2/(MaxOfWidthAndHeight-3)];
                handles.ParSlider3.Value            = 3;
                handles.ParSliderValueText3.String  = '3';
                
                handles.ParSlider2.Min              = 0;
                handles.ParSlider2.Max              = 1;
                handles.ParSlider2.SliderStep       = [0.01 0.1];
                handles.ParSlider2.Value            = 0.1;
                handles.ParSliderValueText2.String  = '0.1';
                
                if IsRusLanguage 
                    
                    handles.ParSliderText3.String = '������ ���� �������:';
                    handles.ParSliderText2.String = '����������� ��������:';
                    
                    handles.ParMenuText4.String = '������� ���������';
                    handles.ParMenu4.String = { '��������';...
                                                };
                    
                else
                    handles.ParSliderText3.String = 'Filter dimension:';
                    handles.ParSliderText2.String = 'Minimum quality:';
                    
                    handles.ParMenuText4.String = 'Match metric';
                    handles.ParMenu4.String = { 'Hamming';...
                                                };                    
                end
                
            case {  'SURF (������ ����������� 64)',...
                    'SURF (������ ����������� 128)',...
                    'SURF (64 descriptor size)',...
                    'SURF (128 descriptor size)'}
                
                handles.ParCheckBox1.Visible = 'on';  
                SetParSlidersVisibleStatus(2:4, ShowIt, handles);
                
                % �����
                handles.ParSlider2.Min              = 100;
                handles.ParSlider2.Max              = 100000;
                handles.ParSlider2.SliderStep       = [100/999900 1000/999900];
                handles.ParSlider2.Value            = 1000;
                handles.ParSliderValueText2.String  = '1000';
                
                % ����� �����
                handles.ParSlider3.Min              = 1;
                handles.ParSlider3.Max              = 6;
                handles.ParSlider3.SliderStep       = [1/5 1/5];
                handles.ParSlider3.Value            = 3;
                handles.ParSliderValueText3.String  = '3';
                
                % ����� ������� ��������
                handles.ParSlider4.Min              = 3;
                handles.ParSlider4.Max              = 8;
                handles.ParSlider4.SliderStep       = [1/5 1/5];
                handles.ParSlider4.Value            = 4;
                handles.ParSliderValueText4.String  = '4';
                
                if IsRusLanguage 
                    
                    handles.ParSliderText2.String = '�����:';
                    handles.ParSliderText3.String = '����� �����:';
                    handles.ParSliderText4.String = '����� ������� ��������:';
                    
                    handles.ParMenuText4.String = '������� ���������';
                    handles.ParMenu4.String = { '����� ������� ��������';...
                                                '����� ��������� ���������';...
                                                };                    
                else
                    handles.ParSliderText2.String = 'Threshold:';
                    handles.ParSliderText3.String = 'Octaves number:';
                    handles.ParSliderText4.String = 'Number of scale levels:';
                    
                    handles.ParMenuText4.String = 'Match metric';
                    handles.ParMenu4.String = { 'Sum of absolute differences';...
                                                'Sum of squared differences';...
                                                };                    
                end
                
            otherwise
                assert(0,'� ParMethod3 ������� �������������� ������ �� ���� �������');
                
        end             % switch ParMenu3Method
        
%-----------------------------------------------------------        
    case {'�������� 3D-�����������','3-D image creation'}
        
        HideIt = false;
        ShowIt = true;
        % ����� ��������, �������� ����� ������ ������
        SetParSlidersVisibleStatus(1:4, HideIt, handles);
        
        % ��� ���� �� ����� ������ � ������ 'Norm8Point'
        SetParMenusVisibleStatus(4, ShowIt, handles);
        
        switch ParMenu3Method
            
            case 'Norm8Point'
                SetParMenusVisibleStatus(4, HideIt, handles);
                
            case 'LMedS'
                SetParSlidersVisibleStatus(1, ShowIt, handles);
                
            case 'RANSAC'
                SetParSlidersVisibleStatus(1:3, ShowIt, handles);
                
            case 'MSAC'
                SetParSlidersVisibleStatus(1:3, ShowIt, handles);
                
            case 'LTS'
                SetParSlidersVisibleStatus([1 4], ShowIt, handles);
                
            otherwise
                assert(0, '� ParMethod4 �������������� ������ ���� �������');
        end
        
%----------------------------------------------------------- 
        
end                     % switch ComputerVisionMethod


% ���� � 4 ���������� 
function ParMenu4_Callback(hObject, eventdata, handles)

IsRusLanguage = IsFigureLanguageRussian(handles);

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

ParMenu4Method = string(handles.ParMenu4.String( handles.ParMenu4.Value ));

switch ComputerVisionMethod   
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ��������������� / �����
function PlayPauseButton_Callback(hObject, eventdata, handles)

% ��� ������ �������:
% - ������ ������ ����� / ���������������
% - ��������� ������ ���������� ��������� ����� � FrameSlider
% - ��������� ���� � �������� �������, ������� � ������� ����
% - �������� �����, ��������������� �������� ��������������� �����
% - � ������ ������ pause ������� ����� ���� �������� ������� �������� ��������� ����������
%   � ���� ������ �� ����� - ���������� ���������������, ������� ������

% ��� ������� �� ������ ��������� ���������
if handles.PlayPauseButton.Value == 0
    
    try
        handles.PlayPauseButton.CData = imread([cd '\Icons\Play.png']);
    catch
        handles.PlayPauseButton.String = '>';        
    end
    
    % �� ����� ������ ��������
    handles.FrameBackButton.Enable = 'on';
    handles.FrameForwardButton.Enable = 'on';
    handles.FrameSlider.Enable = 'on';
    handles.PatternOpenButton.Enable = 'on';
    
else
    try
        handles.PlayPauseButton.CData = imread([cd '\Icons\Pause.png']);
    catch
        handles.PlayPauseButton.String = '| |';
    end
    
    % �� ����� ������ ����������
    handles.FrameBackButton.Enable = 'off';
    handles.FrameForwardButton.Enable = 'off';
    handles.FrameSlider.Enable = 'off';
    handles.PatternOpenButton.Enable = 'off';
    
    UserFile = getappdata(handles.KAACVP,'UserFile'); 
    FrameRate = UserFile.FrameRate;
    
    % ��������� �����
    for FrameNumber = handles.FrameSlider.Value : handles.FrameSlider.Max
        
        % ������� ����� ���������
        tic;        
        
        % ������ � ������� ����� ��������
        handles.FrameSlider.Value = FrameNumber;            
        
        % ��������� ��� ���������� � ������� ��������
        FrameSlider_Callback(hObject, eventdata, handles);          
        drawnow;                        
        
        % ���� ������ ������, ��� ����� ��� �������, ���� ������� �����
        if toc < (1/FrameRate)          
            pause(1/FrameRate - toc);
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

FrameNumber = handles.FrameSlider.Value - 1;

if FrameNumber < handles.FrameSlider.Min
    FrameNumber = handles.FrameSlider.Min;
end

% �������� �������� ��������
handles.FrameSlider.Value = FrameNumber;

% ���������� ����� ����
FrameSlider_Callback(hObject, eventdata, handles);


% ��������� ����
function FrameForwardButton_Callback(hObject, eventdata, handles)

FrameNumber = handles.FrameSlider.Value + 1;

if FrameNumber > handles.FrameSlider.Max
    FrameNumber = handles.FrameSlider.Max;
end

% �������� �������� ��������
handles.FrameSlider.Value = FrameNumber;

% ���������� ����� ����
FrameSlider_Callback(hObject, eventdata, handles);


%---------------------------------------------------------------------------------

% ���������
function ApplyButton_Callback(hObject, eventdata, handles)

% ��� ������ �������:
% - ��������� ��������, ����� ������������ �� ������ ���������
% - ��������� ���������������� ����
% - ��������� �� ���� ������� ����/�����������
% - ������ ������ ��������� ��� ����� �� "�����������", ���
%   ��� ��������������� ����� �������� ����������� ��������� ������� �����
% - ������� ������ ����. �������� �� ����
% - �������� �������� �������� ��������� ����������� ������ ���������� 
%   ��� ��������� ������������� ���������
% - ���������� ��� �������� � ��������� ProcessParameters
% - �������� ��������� ��� �������������� ��������� ����������
% - ��������� ���� ��������� � ������� ����
% - �������� ����������� ������� ��������� ���������� ��� ���������� ����������
% - ������������ ��������

UserFile = getappdata(handles.KAACVP,'UserFile');

DoyouWantToBlockInterface(true, handles, UserFile.IsVideo);

Image = UserFile.Multimedia( handles.FrameSlider.Value ).Frame;

IsRusLanguage = IsFigureLanguageRussian(handles);

% ����������, ��� ������� ���������� ��� ����� ��������: ��� �������
if UserFile.IsVideo
    
    if handles.ApplyButton.Value == 1   % � ������� ���������
        
        handles.ApplyButton.String = ReturnRusOrEngString(IsRusLanguage, '�����������', 'Applying');
        
    else        % ���� ������ ������ - �� ����� ������������
        
        handles.ApplyButton.String = ReturnRusOrEngString(IsRusLanguage, '���������', 'Apply');        
        return;        
    end
    
else                                % ��� ��������    
    handles.ApplyButton.Value = 0;  % ������� ������� ���������     
end


% ������� ������ ��������
delete(findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b'));
handles.StatisticsList.String = '';

% ����� �� ������� ���� - ������ ��������� 1� ������
handles.StatisticsList.Value = 1;

% ������� ������ ��� ��������� ���������
ProcessParameters = struct();       

% ���������� ����� ���������, ��������� � ���������� ������ �������
ProcessParameters.ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

% ��������� ��������� ���� ����� ����������
ProcessParameters.X0 = round(str2double(handles.ROIx0.String));
ProcessParameters.X1 = round(str2double(handles.ROIx1.String));
ProcessParameters.Y0 = round(str2double(handles.ROIy0.String));
ProcessParameters.Y1 = round(str2double(handles.ROIy1.String));

% � ����������� �� �������� ��������� ����������� 
% � ���������� ������� ��������� ���������
% ��������� ���������� ���������
switch ProcessParameters.ComputerVisionMethod
    
    case {'������������� ������','Optical character recognition'}        
        
        ProcessParameters.thresh = handles.ParSlider1.Value;
        ProcessParameters.textlayout = handles.ParMenu1.Value;
        ProcessParameters.language = handles.ParMenu2.Value;
        
        switch ProcessParameters.textlayout       % ������������ ������
            
            case 1
                ProcessParameters.layout = 'Auto';
            case 2
                ProcessParameters.layout = 'Block';
            case 3
                ProcessParameters.layout = 'Line';
            case 4
                ProcessParameters.layout = 'Word';
        end
        
        switch ProcessParameters.language       % ���� �������������
            
            case 1
                ProcessParameters.lang = 'English';
            case 2                            
                ProcessParameters.lang = 'Russian';
            case 3           
                ProcessParameters.lang = 'Ukrainian';
            case 4           
                ProcessParameters.lang = 'French';
            case 5           
                ProcessParameters.lang = 'Dutch';
            case 6           
                ProcessParameters.lang = 'Spanish';
            case 7           
                ProcessParameters.lang = 'Finnish';
            case 8           
                ProcessParameters.lang = 'ChineseTraditional';
            case 9
                ProcessParameters.lang = 'Japanese';
        end
        
    case {'������ �����-����','Barcode reading'} 
        
    case {'����� �������� � �������','Text region detection'}  
        
    case {'������ �����','Blob analysis'}         
        
        % ���������
        ProcessParameters.Conn = handles.ParMenu1.Value * 4;              
        ProcessParameters.BinarizationType = string(...
            handles.ParMenu2.String( handles.ParMenu2.Value )); 
        ProcessParameters.ForegroundType = handles.ParMenu3.Value;        
        % ���/���� ������ �����
        ProcessParameters.BorderBlobs = ~ handles.ParCheckBox1.Value;       
        
        ProcessParameters.MaximumCount = handles.ParSlider1.Value;
        ProcessParameters.MinimumBlobArea = handles.ParSlider2.Value;
        ProcessParameters.MaximumBlobArea = handles.ParSlider3.Value;
        ProcessParameters.SensOrThersh = handles.ParSlider4.Value;
        
        switch ProcessParameters.ForegroundType      
            case 1      
                ProcessParameters.Foreground = 'bright';                
            case 2      
                ProcessParameters.Foreground = 'dark';                
        end                   
        
    case {'������������� ���','Face detection'}
        
        ProcessParameters.MinSize = [handles.ParSlider1.Value handles.ParSlider3.Value];
        ProcessParameters.MaxSize = [handles.ParSlider2.Value handles.ParSlider4.Value];
        ProcessParameters.ScaleFactor = handles.ParSlider5.Value;
        ProcessParameters.MergeThreshold = handles.ParSlider6.Value;
        [~, ProcessParameters.Model] = ReturnFaceDetectorTrainModelAndSize(...
                            string( handles.ParMenu1.String( handles.ParMenu1.Value ) ));
            
    case {'������������� �����','People detection'}
        
    case {'������������� ��������','Object detection'}
        
        ProcessParameters.Pattern = getappdata(handles.KAACVP,'Pattern');
               
        ProcessParameters.Slider1Value =    handles.ParSlider1.Value;
        ProcessParameters.Slider2Value =    handles.ParSlider2.Value;
        ProcessParameters.Slider3Value =    handles.ParSlider3.Value;
        ProcessParameters.Slider4Value =    handles.ParSlider4.Value;
        ProcessParameters.MatchThreshold =  handles.ParSlider5.Value;
        ProcessParameters.MaxRatio =        handles.ParSlider6.Value;
        ProcessParameters.MaxNumTrials =    handles.ParSlider7.Value;
        ProcessParameters.Confidence =      handles.ParSlider8.Value;
        ProcessParameters.MaxDistance =     handles.ParSlider9.Value;
        
        ProcessParameters.UpRight =         handles.ParCheckBox1.Value;
        ProcessParameters.UseUnique =       handles.ParCheckBox2.Value;
        
        ProcessParameters.DetectorType =    handles.ParMenu3.Value;
         
        switch handles.ParMenu1.Value       % ��� ��������������
            
            case 1
                ProcessParameters.TransformationType = 'similarity';
            case 2
                ProcessParameters.TransformationType = 'affine';                
            case 3
                ProcessParameters.TransformationType = 'projective';  
            otherwise
                assert(0,'��� �� ����� �� ���...������� �� ������������ ������� ����');
        end
        
        switch handles.ParMenu2.Value            % ����� ���������
            case 1
                ProcessParameters.MatchMethod = 'Exhaustive';
            case 2
                ProcessParameters.MatchMethod = 'Approximate';
            otherwise
                assert(0,'��� �� ����� �� ���...������� �� ������������ ������� ����');
        end
        
        switch handles.ParMenu4.Value       % �������
            
            case 1
                ProcessParameters.Metric = 'SAD';                
            case 2
                ProcessParameters.Metric = 'SSD';
            otherwise
                assert(0,'��� �� ����� �� ���...������� �� ������������ ������� ����');
        end               
        
    case {'�������� 3D-�����������','3-D image creation'}
        
    case {'��������� �����','Video processing'}
        
    case {'�������� ��������','Panorama creation'}
        
    case {'������������� ��������','Motion detection'}
        
    otherwise
        assert(0, '������ � ��������� � ������� ���������');
        
end

%---------------------------------------------------------------------------------
% �������� ��������� � ����������� �� �������� ��������� ����������
ProcessResults = ComputerVisionProcessing(Image, ProcessParameters, IsRusLanguage);  
%---------------------------------------------------------------------------------

% ��������� � ���������� ���������� ������                        
setappdata(handles.KAACVP,'LABEL',ProcessResults.LABEL);
setappdata(handles.KAACVP,'Boxes',ProcessResults.Boxes);
setappdata(handles.KAACVP,'ImagesToShow',ProcessResults.ImagesToShow.Images);  

% ���� ������� �� ������ �� �������� � ����
image(ProcessResults.NewPattern,'Parent',handles.PatternAxes);
handles.PatternAxes.Visible = 'off';

handles.StatisticsList.String = string(ProcessResults.StatisticsString);    
handles.ImagesToShowMenu.String = string(ProcessResults.StringOfImages);

% ���� ���������� ����� ���� ��������, ������ ���������� ������
if length(ProcessResults.StringOfImages) == 1
    handles.ImagesToShowMenu.Visible = 'off';
else
    handles.ImagesToShowMenu.Visible = 'on';
end

% ���� � ����������� ��������� ��� ������ ������ - ������ ������������ ������
if isempty(ProcessResults.StatisticsString)
    handles.StatisticsList.Visible = 'off';
else
    handles.StatisticsList.Visible = 'on';
end

% ���� ��������, �� ����� ����� ����� ����� ���������
if ~UserFile.IsVideo
    handles.ImagesToShowMenu.Value = length(ProcessResults.StringOfImages);
else    % ��� ����� ������������ ��� ������
end

% ����� ���������� ����������
StatisticsList_Callback(hObject, eventdata, handles);   
ImagesToShowMenu_Callback(hObject, eventdata, handles);

DoyouWantToBlockInterface(false, handles, UserFile.IsVideo);

%---------------------------------------------------------------------------------

% ���������� ������� �����������/����� ��� ������ ���
function ZoomButton_Callback(~, ~, handles)

UserFile = getappdata(handles.KAACVP,'UserFile');
Pattern = getappdata(handles.KAACVP,'Pattern');

% ���� ���� ���������    
if handles.ZoomButton.Value == 0    
    
    % ������ �������� ������ ����
    try
        handles.ZoomButton.CData = imread([cd '\Icons\Zoom+.png']);
    catch
        handles.ZoomButton.String = '+';
    end
    
    % ��������� ��������� �������� ���
    SetNewAxesPosition(handles.FileAxes, UserFile.Height, UserFile.Width);
    
    if ~isempty(Pattern)    % ���� ���� ������������ - �������
        
        % �������� ������ ��� ���
        SetNewAxesPosition(handles.PatternAxes, size(Pattern,1), size(Pattern,2));
    end
    
else        % ��������� ���� ��� ������
     
    try
        handles.ZoomButton.CData = imread([cd '\Icons\Zoom-.png']);
    catch
        handles.ZoomButton.String = '-';
    end
    
    % �������� ���
    % ��������� ��������� ������, ���������� ��� ���
    FileAxesPosition = getappdata(handles.FileAxes,'InitPosition');
    
    % ������� �������� ���������������
    MinImageToAxesSideRation = min( UserFile.Height/FileAxesPosition(4),...
                                    UserFile.Width/FileAxesPosition(3));
    
    % ������� ����� ������� ���
    NewHeight = UserFile.Height / MinImageToAxesSideRation;  
    NewWidth =  UserFile.Width  / MinImageToAxesSideRation;
    
    % ��������� ��������� �������� ���
    SetNewAxesPosition(handles.FileAxes, NewHeight, NewWidth);     
    
    % ��� �������    
    if ~isempty(Pattern)    % ���� ������� ����
        
        % ��������� ��������� ������, ���������� ��� ���
        PatternAxesPosition = getappdata(handles.PatternAxes,'InitPosition');
        
        % ������� �������� ���������������
        MinImageToAxesSideRation = min( size(Pattern,1)/PatternAxesPosition(4),...
                                        size(Pattern,2)/PatternAxesPosition(3));
    
        % �������� �������, �� ������� ����� ��������� �������� � ������� ��
        NewHeight = size(Pattern,1) / MinImageToAxesSideRation;        
        NewWidth = size(Pattern,2) / MinImageToAxesSideRation;
        
        % ��������� ��������� �������� ���
        SetNewAxesPosition(handles.PatternAxes, NewHeight, NewWidth);
    end
        
end


% ����� ������� ��������
function ROIButton_Callback(hObject, eventdata, handles)

% ������� ������ ����� ROI � ���: ��� ������ ����������
delete(findobj('Parent',handles.FileAxes,'LineStyle','--'));

UserFile = getappdata(handles.KAACVP,'UserFile');

% ���� �� ������������ ����� �� ������ ROI
if hObject ~= handles.ROIButton 
    assert(0 , [get(hObject,'Tag') ' ������ ROI ������!']); 
end
    
% ���� ������������ � ������� imrect ������� ROI � ��������� ����������
ROI =  imrect(handles.FileAxes);
ROIPosition = round(getPosition(ROI));

% ������� ��������� ������������� ������� imrect
delete(ROI);

% ������������ ���������� ����� ROI �� ������� ROI
X0Y0X1Y1Coords = [  ROIPosition(1) ROIPosition(2)...
                    ROIPosition(1) + ROIPosition(3)...
                    ROIPosition(2) + ROIPosition(4)];

% ������������ ���������� ROI ��� ������ �� ������� �������� �����������
Limits = [1 1 UserFile.Width UserFile.Height];
AreTopLimits = [false false true true];

% ���������� X0Y0X1Y1Coords � ROIPosition 
X0Y0X1Y1Coords = LimitCheck(X0Y0X1Y1Coords, Limits, AreTopLimits);
ROIPosition(3) = X0Y0X1Y1Coords(3) - X0Y0X1Y1Coords(1);
ROIPosition(4) = X0Y0X1Y1Coords(4) - X0Y0X1Y1Coords(2);

% �������� �������� � �������� ������ �����
handles.ROIx0.String = num2str(X0Y0X1Y1Coords(1));
handles.ROIy0.String = num2str(X0Y0X1Y1Coords(2));
handles.ROIx1.String = num2str(X0Y0X1Y1Coords(3));
handles.ROIy1.String = num2str(X0Y0X1Y1Coords(4));

handles.ROIx0.Value = X0Y0X1Y1Coords(1);
handles.ROIy0.Value = X0Y0X1Y1Coords(2);
handles.ROIx1.Value = X0Y0X1Y1Coords(3);
handles.ROIy1.Value = X0Y0X1Y1Coords(4);

% ��������� ROI / �������
RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);
    

% ������� ������
function PatternOpenButton_Callback(~, ~, handles)

IsRusLanguage = IsFigureLanguageRussian(handles);

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod
    
    case {'������������� ��������','Object detection'}

        Pattern = OpenPatternImage(IsRusLanguage);

        if isempty(Pattern)
            return;
        end
        
        % ��������� ������� ��������
        image(Pattern, 'Parent',handles.PatternAxes);
        handles.PatternAxes.Visible = 'off';
        
        % ��������� ��
        setappdata(handles.KAACVP, 'Pattern',Pattern); 
        
        % � ���������� �� ������� ������ ���� ��������� ������ ���
        ZoomButton_Callback([], [], handles);
        
        handles.ShowPatternImageMenu.Visible = 'on';    
        
        % ������ ������ �� �� ����� ������ ��� ���������� ROI
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

% ������� ��������� ��������� ������������ ����������� 
% � ��������� �����������, ��������� ������� ������ � �������

UserFile = getappdata(handles.KAACVP,'UserFile');

FrameNumber = round(handles.FrameSlider.Value); % ��������� ����� �����
handles.FrameSlider.Value = FrameNumber;        % ���������� ���������� �������� � ��������
    
if handles.ApplyButton.Value == 1           % ���� "�����������" ��������� 
    
    ApplyButton_Callback(hObject, eventdata, handles); % ����� ������������ ������������ ���
    
else    % ��� ���������           

    % ��������� ������� ���� � ��������� ImagesToShow
    ImagesToShow(1).Images = UserFile.Multimedia(FrameNumber).Frame;
    
    % � ��������� ���������
    setappdata(handles.KAACVP,'ImagesToShow',ImagesToShow);
    
    % ������� ������ ���� ������� �� ����
    delete(findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b'));
    
    % ��������� ���� ����������� � ������
    handles.ImagesToShowMenu.Value = 1;
    handles.ImagesToShowMenu.String = ' ';
    handles.ImagesToShowMenu.Visible = 'off';
    handles.StatisticsList.Visible = 'off';
    
end

% ���������� �����������
ShowMultimediaFile(handles);
    
% ����������� ���� � ����� ������ ��� �����
if UserFile.IsVideo
    ShowTimeAndFrame(handles, UserFile.FrameRate, FrameNumber);         
end


% ������� ���������� � 1
function ParSlider1_Callback(hObject, eventdata, handles)

ParSlider1Value = handles.ParSlider1.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod
    
    case {'������������� ������','Optical character recognition'}
        ParSlider1Value = round(ParSlider1Value*100)/100;
        
    case {  '������ �����','Blob analysis',...
            '�������� 3D-�����������','3-D image creation'}   
        ParSlider1Value = round(ParSlider1Value);
    
    case {'������������� ��������','Object detection'}    
        ParSlider1Value = round(ParSlider1Value*100)/100;
        
    case {'������������� ���','Face detection'}
        
        % ���������� ������� ����������, ����� ������������
        % �� ���� ���������� ������������ ������� ������ �����������
        
        ParSlider1Value = round(ParSlider1Value);
        
        % ���� �������� �������� ���� � �����
        % ����������� ���, � �������� ������ ���������
        % ����� ������ ������� ������ ������� ��������
        
        if  handles.ParSlider2.Max == ParSlider1Value + 1
            
            handles.ParSlider2.Enable = 'off';
            handles.ParSliderValueText2.Enable = 'off';
            handles.ParSliderValueText2.String = num2str(ParSlider1Value+1);
        else
            handles.ParSlider2.Enable = 'on';
            handles.ParSliderValueText2.Enable = 'on';
            
            handles.ParSlider2.Min = ParSlider1Value + 1;
            handles.ParSlider2.SliderStep = ...
                [1/(handles.ParSlider2.Max-ParSlider1Value-1) ...
                10/(handles.ParSlider2.Max-ParSlider1Value-1)];
        end
        
        
    otherwise
        assert(0,'� ParSlider1 ������� �������������� ������ �� ���� �������');
        
        
end

handles.ParSlider1.Value = ParSlider1Value;
handles.ParSliderValueText1.String = num2str(ParSlider1Value);


% ������� ���������� � 2
function ParSlider2_Callback(hObject, eventdata, handles)

ParSlider2Value = handles.ParSlider2.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));
ParMenu3Method = string(handles.ParMenu3.String( handles.ParMenu3.Value ));

switch ComputerVisionMethod        
    
    case {'������ �����','Blob analysis'}   
        ParSlider2Value = round(ParSlider2Value);
        
    case {'������������� ��������','Object detection'}    
        
        
        switch ParMenu3Method  % ��� ���������
            
            case {'MSER'}             
                ParSlider2Value = round(ParSlider2Value);
                
            case {'BRISK', 'FAST', '�������', 'Harris',...
                  '������������ ������������ ��������', 'Minimum eigen'}
              
                ParSlider2Value = round(ParSlider2Value*100)/100;
                
            case {  'SURF (������ ����������� 64)',...
                    'SURF (������ ����������� 128)',...
                    'SURF (64 descriptor size)',...
                    'SURF (128 descriptor size)'}
                
                ParSlider2Value = round(ParSlider2Value/100)*100;
                    
            otherwise
                assert(0,'� ParSlider2 ������� �������������� ������ �� ���� ����������');       
        end                
    
        
    case {'������������� ���','Face detection'}
        
        % ���������� ������� ����������, ����� ������������
        % �� ���� ���������� ������������ ������� ������ �����������
        
        ParSlider2Value = round(ParSlider2Value);
        
        % ���� �������� �������� ���� � �����
        % ����������� ���, � �������� ������ ���������
        % ����� ������ ������� ������ ������� ��������
        
        if  handles.ParSlider1.Min == ParSlider2Value - 1
            handles.ParSlider1.Enable = 'off';
            handles.ParSliderValueText1.Enable = 'off';
            handles.ParSliderValueText1.String = num2str(ParSlider2Value-1);
        else
            handles.ParSlider1.Enable = 'on';
            handles.ParSliderValueText1.Enable = 'on';
            handles.ParSlider1.Max = ParSlider2Value - 1;
            handles.ParSlider1.SliderStep = ...
                [1/(ParSlider2Value - handles.ParSlider1.Min-1) ...
                10/(ParSlider2Value - handles.ParSlider1.Min-1)];
        end
        
    case {'�������� 3D-�����������','3-D image creation'}
        
        ParSlider2Value = round(ParSlider2Value * 100) / 100;
        
    otherwise
        assert(0,'� ParSlider2 ������� �������������� ������ �� ���� �������');        
end

handles.ParSlider2.Value = ParSlider2Value;
handles.ParSliderValueText2.String = num2str(ParSlider2Value);


% ������� ���������� � 3
function ParSlider3_Callback(~, ~, handles)

ParSlider3Value = handles.ParSlider3.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));
ParMenu3Method = string(handles.ParMenu3.String( handles.ParMenu3.Value ));

switch ComputerVisionMethod
        
    case {'������ �����','Blob analysis'}   
        ParSlider3Value = round(ParSlider3Value);
        
    case {'�������� 3D-�����������','3-D image creation'}  
        ParSlider3Value = round(ParSlider3Value * 1000) / 1000;
    
    case {'������������� ��������','Object detection'} 
        
        switch ParMenu3Method  % ��� ���������
            
            case {'MSER'}    
                
                % ���������� ������� ����������, ����� ������������
                % �� ���� ���������� ������������ ������� ������ �����������
                
                ParSlider3Value = round(ParSlider3Value);   
                
                % ���� �������� �������� ���� � �����
                % ����������� ���, � �������� ������ ���������
                % ����� ������ ������� ������ ������� ��������
                
                if  handles.ParSlider4.Max == ParSlider3Value + 1
                    
                    handles.ParSlider4.Enable = 'off';
                    handles.ParSliderValueText4.Enable = 'off';
                    handles.ParSliderValueText4.String = num2str(ParSlider3Value+1);                    
                else
                    handles.ParSlider4.Enable = 'on';
                    handles.ParSliderValueText4.Enable = 'on';
                    
                    handles.ParSlider4.Min = ParSlider3Value + 1;
                    handles.ParSlider4.SliderStep = ...
                        [1/(handles.ParSlider4.Max-ParSlider3Value-1) ...
                        10/(handles.ParSlider4.Max-ParSlider3Value-1)];
                end
                
                
            case {  'BRISK',...
                    'SURF (������ ����������� 64)',...
                    'SURF (������ ����������� 128)',...
                    'SURF (64 descriptor size)',...
                    'SURF (128 descriptor size)'}
                
                ParSlider3Value = round(ParSlider3Value);
                
            case {'�������', 'Harris',...
                  '������������ ������������ ��������', 'Minimum eigen'}
              
                ParSlider3Value = round(ParSlider3Value);
                ParSlider3Value = ParSlider3Value - 1 + mod(ParSlider3Value,2);
                          
            otherwise
                assert(0,'� ParSlider3 ������� �������������� ������ �� ���� ����������');
                
        end     % switch ParMenu3Method
           
                
    case {'������������� ���','Face detection'}
        
        % ���������� ������� ����������, ����� ������������
        % �� ���� ���������� ������������ ������� ������ �����������
        
        ParSlider3Value = round(ParSlider3Value);
        
        % ���� �������� �������� ���� � �����
        % ����������� ���, � �������� ������ ���������
        % ����� ������ ������� ������ ������� ��������
        
        if  handles.ParSlider4.Max == ParSlider3Value + 1
            
            handles.ParSlider4.Enable = 'off';
            handles.ParSliderValueText4.Enable = 'off';
            handles.ParSliderValueText4.String = num2str(ParSlider3Value+1);
        else
            handles.ParSlider4.Enable = 'on';
            handles.ParSliderValueText4.Enable = 'on';
            
            handles.ParSlider4.Min = ParSlider3Value + 1;
            handles.ParSlider4.SliderStep = ...
                [1/(handles.ParSlider4.Max-ParSlider3Value-1) ...
                10/(handles.ParSlider4.Max-ParSlider3Value-1)];
        end
        
    otherwise
        assert(0,'� ParSlider3 ������� �������������� ������ �� ���� �������');
        
end             % switch ComputerVisionMethod

handles.ParSlider3.Value = ParSlider3Value;
handles.ParSliderValueText3.String = num2str(ParSlider3Value);


% ������� ���������� � 4
function ParSlider4_Callback(~, ~, handles)

ParSlider4Value = handles.ParSlider4.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));
ParMenu3Method = string(handles.ParMenu3.String( handles.ParMenu3.Value ));

switch ComputerVisionMethod
        
    case {'������ �����','Blob analysis'}   
        ParSlider4Value = round(ParSlider4Value*100)/100;
        
    case {'�������� 3D-�����������','3-D image creation'}  
        ParSlider4Value = round(ParSlider4Value);
        
    case {'������������� ��������','Object detection'}
        
        switch ParMenu3Method   % ��� ���������            
                
            case {'MSER'}
                
                % ���������� ������� ����������, ����� ������������
                % �� ���� ���������� ������������ ������� ������ �����������
                
                ParSlider4Value = round(ParSlider4Value);   
                
                % ���� �������� �������� ���� � �����
                % ����������� ���, � �������� ������ ���������
                % ����� ������ ������� ������ ������� ��������
                
                if  handles.ParSlider3.Min == ParSlider4Value - 1
                    handles.ParSlider3.Enable = 'off';
                    handles.ParSliderValueText3.Enable = 'off';
                    handles.ParSliderValueText3.String = num2str(ParSlider4Value-1);
                else
                    handles.ParSlider3.Enable = 'on';
                    handles.ParSliderValueText3.Enable = 'on';
                    handles.ParSlider3.Max = ParSlider4Value - 1;
                    handles.ParSlider3.SliderStep = ...
                        [1/(ParSlider4Value - handles.ParSlider3.Min-1) ...
                        10/(ParSlider4Value - handles.ParSlider3.Min-1)];
                end
                
            case {  'SURF (������ ����������� 64)',...
                    'SURF (������ ����������� 128)',...
                    'SURF (64 descriptor size)',...
                    'SURF (128 descriptor size)'}
                
                ParSlider4Value = round(ParSlider4Value);
                
             otherwise
                 assert(0,'� ParSlider4 ������� �������������� ������ �� ���� �������');
                 
        end            
        
                
    case {'������������� ���','Face detection'}
       
        % ���������� ������� ����������, ����� ������������
        % �� ���� ���������� ������������ ������� ������ �����������
        
        ParSlider4Value = round(ParSlider4Value);
        handles.ParSlider4.Value = ParSlider4Value;
        
        % ���� �������� �������� ���� � �����
        % ����������� ���, � �������� ������ ���������
        % ����� ������ ������� ������ ������� ��������
        
        if  handles.ParSlider3.Min == ParSlider4Value - 1
            handles.ParSlider3.Enable = 'off';
            handles.ParSliderValueText3.Enable = 'off';
            handles.ParSliderValueText3.String = num2str(ParSlider4Value-1);
        else
            handles.ParSlider3.Enable = 'on';
            handles.ParSliderValueText3.Enable = 'on';
            handles.ParSlider3.Max = ParSlider4Value - 1;
            handles.ParSlider3.SliderStep = ...
                [1/(ParSlider4Value - handles.ParSlider3.Min-1) ...
                10/(ParSlider4Value - handles.ParSlider3.Min-1)];
        end
        
    otherwise
        assert(0,'� ParSlider4 ������� �������������� ������ �� ���� �������');
        
end

handles.ParSlider4.Value = ParSlider4Value;
handles.ParSliderValueText4.String = num2str(ParSlider4Value);


% ������� ���������� � 5
function ParSlider5_Callback(hObject, eventdata, handles)

ParSlider5Value = handles.ParSlider5.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod        
           
    case {  '������������� ��������','Object detection',...
            '�������� 3D-�����������','3-D image creation'}
        
        ParSlider5Value = round(ParSlider5Value);
        
    case {'������������� ���','Face detection'}
        ParSlider5Value = round(ParSlider5Value*10000)/10000;
        
    otherwise
        assert(0,'� ParSlider5 ������� �������������� ������ �� ���� �������');
        
end

handles.ParSlider5.Value = ParSlider5Value;
handles.ParSliderValueText5.String = num2str(ParSlider5Value);


% ������� ���������� � 6
function ParSlider6_Callback(hObject, eventdata, handles)

ParSlider6Value = handles.ParSlider6.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod        
           
    case {  '������������� ��������','Object detection',...
            '�������� 3D-�����������','3-D image creation'}
        
        ParSlider6Value = round(ParSlider6Value*100)/100;
        
    case {'������������� ���','Face detection'}
        ParSlider6Value = round(ParSlider6Value);
        
    otherwise
        assert(0,'� ParSlider6 ������� �������������� ������ �� ���� �������');
        
end

handles.ParSlider6.Value = ParSlider6Value;
handles.ParSliderValueText6.String = num2str(ParSlider6Value);


% ������� ���������� � 7
function ParSlider7_Callback(hObject, eventdata, handles)

ParSlider7Value = handles.ParSlider7.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod        
           
    case {'������������� ��������','Object detection'}
        ParSlider7Value = round(ParSlider7Value/10)*10;
        
    case {'�������� 3D-�����������','3-D image creation'}
        ParSlider7Value = round(ParSlider7Value);        
        
    otherwise
        assert(0,'� ParSlider7 ������� �������������� ������ �� ���� �������');
        
end

handles.ParSlider7.Value = ParSlider7Value;
handles.ParSliderValueText7.String = num2str(ParSlider7Value);


% ������� ���������� � 8
function ParSlider8_Callback(hObject, eventdata, handles)

ParSlider8Value = handles.ParSlider8.Value;
 
ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod        
           
    case {'������������� ��������','Object detection'}
        ParSlider8Value = round(ParSlider8Value*100)/100;
        
    case {'�������� 3D-�����������','3-D image creation'}
        ParSlider8Value = round(ParSlider8Value);
        
    otherwise
        assert(0,'� ParSlider8 ������� �������������� ������ �� ���� �������');
        
end

handles.ParSlider8.Value = ParSlider8Value;
handles.ParSliderValueText8.String = num2str(ParSlider8Value);


% ������� ���������� � 9
function ParSlider9_Callback(hObject, eventdata, handles)

ParSlider9Value = handles.ParSlider9.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod        
           
    case {  '������������� ��������','Object detection',...
            '�������� 3D-�����������','3-D image creation'}
        
        ParSlider9Value = round(ParSlider9Value);
        
    otherwise
        assert(0,'� ParSlider9 ������� �������������� ������ �� ���� �������');
end

handles.ParSlider9.Value = ParSlider9Value;
handles.ParSliderValueText9.String = num2str(ParSlider9Value);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ������ ���������� �� �����������
function StatisticsList_Callback(~, ~, handles)

ChosenString = handles.StatisticsList.Value;

% ������� ������������ ����������� ������ � ���,
% ������� ���������� ��������� ���������� �� ����������� �
% ������� ������ ����� �����-���������� ����� � ����� ���� 
GraphObject = findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b');

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod
    
    case {'������������� ������','Optical character recognition'}        
        
        % ��������� ���������� �������� ���������� ������
        FoundTextBoxesCoords = getappdata(handles.KAACVP,'Boxes');
        if isempty(FoundTextBoxesCoords)
            return;
        end
        
        % ������� ��� ��������� ����������� ������
        if isempty(GraphObject)
                
            rectangle(  'Position',FoundTextBoxesCoords(ChosenString, :),...
                        'Parent',handles.FileAxes,...
                        'EdgeColor','b',...
                        'LineStyle','-.',...
                        'LineWidth',2);
        else                   
            set(GraphObject, 'Position', FoundTextBoxesCoords(ChosenString,:));            
        end
        
    case {'������ �����','Blob analysis'}
        
        % ��������� �������� �����
        LABEL = getappdata(handles.KAACVP,'LABEL');
        if isempty(LABEL)
            return;
        end
        
        % ������� ��� ��������� ����������� ������
        if isempty(GraphObject)
            
            [y,x] = find(LABEL == ChosenString);
            
            patch(x,y,'b',...
                'Parent',handles.FileAxes,...
                'EdgeColor','b',...
                'LineStyle','-.',...
                'LineWidth',2);            
        else                         
            [y,x] = find(LABEL == ChosenString);
            set(GraphObject, 'XData',x,'YData',y);
        end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%% ��������� ���� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ������� ����� ������� ��������
function ROIedit_Callback(hObject, eventdata, handles)

UserFile = getappdata(handles.KAACVP,'UserFile');

IsRusLanguage = strcmp(handles.RussianLanguageMenu.Checked,'on');

ROIeditValue = str2double(get(hObject,'String'));  

% ���� �� �����, ���������� ������
if isnan(ROIeditValue)    
    
    GenerateError('ShouldBeDigits', IsRusLanguage);   
    
    % ��������� � ���� ���������� ���������� �����
    set(hObject,'String',num2str( get(hObject,'Value') ));    
    return;
    
end

ROIeditValue = round(ROIeditValue);

% ������� �������� � ������� ��� ���������� ��������
switch hObject
    
    case handles.ROIy0
        MaxValue = str2double(handles.ROIy1.String);
        MinValue = 1;
        
    case handles.ROIy1
        MaxValue = UserFile.Height;
        MinValue = str2double(handles.ROIy0.String);
        
    case handles.ROIx0
        MaxValue = str2double(handles.ROIx1.String);
        MinValue = 1;
        
    case handles.ROIx1
        MaxValue = UserFile.Width;
        MinValue = str2double(handles.ROIx0.String);
end

% ��� ������ �� ������� ����������� ���������� ��������
if ROIeditValue < MinValue     
    ROIeditValue = MinValue;
    
elseif ROIeditValue > MaxValue
    ROIeditValue = MaxValue;
end

% ����������� ��������� ������������� ����� � �������� 'Value' ����,
% ����� ����� ���� ��� ����� ������������ ��� ������������ ����� ������������
set(hObject,'String',num2str(ROIeditValue),'Value',ROIeditValue);

% ��������� ROI / �������
ROI_X0 = round(str2double(handles.ROIx0.String));
ROI_X1 = round(str2double(handles.ROIx1.String));
ROI_Y0 = round(str2double(handles.ROIy0.String));
ROI_Y1 = round(str2double(handles.ROIy1.String));

ROIPosition = [ROI_X0 ROI_Y0 ROI_X1-ROI_X0 ROI_Y1-ROI_Y0];
X0Y0X1Y1Coords = [ROI_X0 ROI_Y0 ROI_X1 ROI_Y1];

RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);



% ������� ���� ����� �������� ���������
function SliderEdit_Callback(hObject, eventdata, handles)

% ����� ���� ����� ��������� ������ �������� ��������� ��������� 
% �������� ��� ��������.
% ��� �������� � ���� ����� ���������� ����� 
% ParSlider1...ParSlider9  � ParSliderValueText1 ...ParSliderValueText9
% ������� ��� ���� ����� ���� ������
% ���������� ��������� �������� �� ���� ������ �����
% ���� �������� ���������� - ������������� ������������ � ������� ������ ��������
% ������ �������� ���������� � ��������

ParEditValue = str2double(get(hObject,'String'));  

IsRusLanguage = strcmp(handles.RussianLanguageMenu.Checked,'on');

% �������� ��� ���� �� ParSliderValueText�
EditTag = strsplit( get(hObject,'Tag') , 'ValueText');

% �������� ��� �������������� ��������, ������� ParSlider�
SliderTag = [EditTag{1} EditTag{2}];                    

% ���� �� ����� - ������
if isnan(ParEditValue)                             
    
    GenerateError('ShouldBeDigits', IsRusLanguage); 
    
    % ��������� � ���� �������� �� ��������
    set(hObject,'String',num2str( get(eval(['handles.' SliderTag]) , 'Value')));
    return;
end

% ��������� ��������� �������������� ��������
MaxValue = get(eval(['handles.' SliderTag]),'Max');
MinValue = get(eval(['handles.' SliderTag]),'Min');
SliderStep = get(eval(['handles.' SliderTag]),'SliderStep');

% ��� ����������� �������� ���������� �������� 
% �������� �� ������ ����� ��������� �������
RoundOrder = SliderStep(1) * (MaxValue - MinValue);

% �������� � ������������ �������� 
ParEditValue = round(ParEditValue / RoundOrder) * RoundOrder;     

% ��� ������ �� ������� ����������� ���������� ��������
if ParEditValue < MinValue     
    ParEditValue = MinValue;
    
elseif ParEditValue > MaxValue
    ParEditValue = MaxValue;
end

% ��������� ���� � �������
set(hObject,'String',num2str(ParEditValue));            
set(eval(['handles.' SliderTag]),'Value',ParEditValue);

% ��������� ��������� ��������
eval([SliderTag '_Callback(hObject, eventdata, handles)']);


%%%%%%%%%%%%%%%%%%%%%%%%%%%% ���-����� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function ParCheckBox1_Callback(hObject, eventdata, handles)

IsRusLanguage = IsFigureLanguageRussian(handles);

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod
    
    case {'������ �����','Blob analysis'}
        
        if handles.ParCheckBox1.Value
            handles.ParCheckBox1.TooltipString = ReturnRusOrEngString(IsRusLanguage,...
                    '������� ��������� �����', 'Including border blobs');
        else
            handles.ParCheckBox1.TooltipString = ReturnRusOrEngString(IsRusLanguage,...
                    '�������� ��������� �����', 'Excluding border blobs');
        end
end


function ParCheckBox2_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ����������� ������� � ������ � ������� �������� �����
function ShowTimeAndFrame(handles, FrameRate, FrameNumber)

% handles - ������ ���������� ����������
% FrameRate - �������� ��������������� �����
% FrameNumber - ����� �������� �����

assert(isstruct(handles),'�������� �� ��������� ��������� ����������');
assert(isnumeric(FrameRate) && isnumeric(FrameNumber),...
    'FrameRate � FrameNumber - �� �������� ���������');

% ������ ����� ��� ���������
FrameNumber = round(FrameNumber);               

sec = mod(FrameNumber / FrameRate, 60);
min = (FrameNumber / FrameRate - sec) / 60;
sec = round(sec);

% ������ 59 ��� ��������, � �� 60        
if sec == 60            
    sec = 0;
    min = min + 1;
end

handles.VideoTimeInfo.String = [sprintf('%02d',min) ':' sprintf('%02d',sec)];
handles.VideoFrameInfo.String = [num2str(FrameNumber) ' ����'];


% ����������� ������ ��� ��� �����/�����������
function SetNewAxesPosition(Axes, ImageHeight, ImageWidth)

% Axes - ���, � ������� ��������� ����/�����������
% ImageHeight, ImageWidth - �������� �����/�����������  

assert(isappdata(Axes, 'InitPosition'), 'Axes ������� �� �����');
assert(isnumeric(ImageHeight), 'Height - �� �����');
assert(isnumeric(ImageWidth), 'Width - �� �����');

% �������� �������� �� ����������� ������ ����������� � �������� ����
MaxImageToAxesSideRation = GetMaxImageToAxesSideRation(Axes, ImageHeight, ImageWidth);
        
% ��������� ��������� ������, ���������� ��� ���
InitAxesPosition = getappdata(Axes,'InitPosition'); 

% ���� ����������� �� ������� � ��� - ������� ���
if MaxImageToAxesSideRation > 1
    
    AxesNewWidth = ImageWidth / MaxImageToAxesSideRation ;
    AxesNewHeight = ImageHeight / MaxImageToAxesSideRation ;
else
    AxesNewWidth = ImageWidth;
    AxesNewHeight = ImageHeight;
end

% ����� ������� ���������������� ���
NewAxesPosition = [...
            InitAxesPosition(1) + floor((InitAxesPosition(3) - AxesNewWidth)/2)...
            InitAxesPosition(2) + floor((InitAxesPosition(4) - AxesNewHeight)/2)...
            AxesNewWidth...
            AxesNewHeight];

set(Axes, 'Position', NewAxesPosition);

 
% ������� �������� �� ����������� ������ ����������� � �������� ����
function MaxImageToAxesSideRation = GetMaxImageToAxesSideRation(Axes, ImageHeight, ImageWidth)

assert(isappdata(Axes, 'InitPosition'), 'Axes ������� �� �����');
assert(isnumeric(ImageHeight), 'Height - �� �����');
assert(isnumeric(ImageWidth), 'Width - �� �����');

InitAxesPosition = getappdata(Axes,'InitPosition'); 

MaxImageToAxesSideRation = max( ImageWidth / InitAxesPosition(3),...
                                ImageHeight / InitAxesPosition(4));

assert(isfloat(MaxImageToAxesSideRation), '���������� �� �����-�����');
assert(isscalar(MaxImageToAxesSideRation), '���������� ������!');


% ����������� ������ ������� ���������
function SetCVMethodMenuList(handles, IsVideo, IsRusLanguage)

% handles.CVMethodMenu - ������������� �������
% VideoOpened - ���� ������� ����� - ����� ������
% IsRusLanguage - ���� 1, ����� ������� ���� �����

assert(isstruct(handles),'�������� �� ��������� ��������� ����������');
assert(isfield(handles,'CVMethodMenu'),'� ���������� handles ��� ���� �������');
assert(islogical(IsVideo),'���� ����� �� ����������');
assert(islogical(IsRusLanguage),'���� ����� �� ����������');

if IsVideo          % ��� ��������� �����-�����
    
    if IsRusLanguage              % �� �������
        
        set(handles.CVMethodMenu,'String',{...
            '������������� ������';...
            '������ �����-����';...
            '����� �������� � �������';...
            '������ �����';...
            '������������� ���';...
            '������������� �����';...
            '������������� ��������';...
            '��������� �����';...
            '�������� ��������';...
            '������������� ��������';...
            });       
        
    else                % �� ���������� 
        
        set(handles.CVMethodMenu,'String',{...
            'Optical character recognition';...
            'Barcode reading';...
            'Text region detection';...
            'Blob analysis';...
            'Face detection';...
            'People detection';...
            'Object detection';...
            'Video processing';...
            'Panorama creation';...
            'Motion detection';...
            });        
    end
        
else                    % ���� ������� �����������
    if IsRusLanguage          % �� �������
        
        set(handles.CVMethodMenu,'String',{...
            '������������� ������';...
            '������ �����-����';...
            '����� �������� � �������';...
            '������ �����';...
            '������������� ���';...
            '������������� �����';...
            '������������� ��������';...
            '�������� 3D-�����������';...
            });
    else
        set(handles.CVMethodMenu,'String',{...
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
    

% ���������� CheckValue ��� ������ �� ������ Limit
function CorrectValue = LimitCheck(CheckValue, Limit, IsTopLimit)

% CheckValue - ����������� �����
% Limit - ������
% IsTopLimit = true - ������ ������
% IsTopLimit = false - ������ �����
% CorrectValue - ������������������ �������� � ������������ � ��������

assert(isnumeric([CheckValue Limit]), 'Value �� ��������');            
assert(islogical(IsTopLimit),'Upper �� ����������');            
assert(isequal(size(CheckValue), size(Limit), size(IsTopLimit)),...
                '����������� ������� ������ �� �����');

% �������� �� ���������
CorrectValue = CheckValue;

for x = 1:length(CheckValue)         % �� ����� ������ ��������� ���������
    
    if IsTopLimit(x)                	% ������ ������
        
        if CheckValue(x) > Limit(x)  % ���� ���� ������� -> �������� = �������
            CorrectValue(x) = Limit(x);
        end
    else                        % ������ �����
        
        if CheckValue(x) < Limit(x)
            CorrectValue(x) = Limit(x);
        end
    end
end

assert(isnumeric(CheckValue),'CheckValue �� ������ - �� �����');
    
    
% ������� ������� �����    
function UserFile = OpenMultimediaFile(IsRusLanguage)

assert(islogical(IsRusLanguage),'���� ����� �� ����������');

UserFile = [];          % ������� ������ ���� ��� �������� � ������ ������

% �������� ���� ��� ��������
if IsRusLanguage
    
    [FileName, PathName] = uigetfile(...
        {'*.*', 'All Files(*.*)';...
        '*.avi;*,mj2;*.mpg;*.mp4;*.m4v;*.mov;*.wmv;*.ogg;*.asf;*.asx',...
        '����� (*.avi,*.mj2,*.mpg,*.mp4,*.m4v,*.mov,*.wmv,*.ogg,*.asf,*.asx)';...
        '*.jpeg;*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        '����������� (*.jpeg,*.jpg,*.tif,*.tiff,*.bmp,*.png)'},...
        '�������� ���� ��� ���������',...
        [cd '\Test Materials']);
else
        [FileName, PathName] = uigetfile(...
        {'*.*', 'All Files(*.*)';...
        '*.avi;*,mj2;*.mpg;*.mp4;*.m4v;*.mov;*.wmv;*.ogg;*.asf;*.asx',...
        'Video Files (*.avi,*.mj2,*.mpg,*.mp4,*.m4v,*.mov,*.wmv,*.ogg,*.asf,*.asx)';...
        '*.jpeg;*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        'Image Files (*.jpeg,*.jpg,*.tif,*.tiff,*.bmp,*.png)'},...
        'Choose a file to process',...
        [cd '\Test Materials']);
end

if ~FileName        % ��������, ��� �� ������ ����
    return;
end

try         % ������� ������� ��� ���������
    
    % �����������
    VideoObject = VideoReader([PathName FileName]);

    % ������� ��������� ��� �����
    UserFile = struct(  'Multimedia',[],...
                        'FrameRate',[],...
                        'IsVideo',[],...
                        'Width',[],...
                        'Height',[],...
                        'NumOfChannels',[]); 
    
    % ������ ������ �����            
    UserFile.Multimedia.Frame = zeros(size(readFrame(VideoObject)));  
    
    FrameNumber = 1;                                % ������� ������
    NumOfFrames = round(VideoObject.Duration * VideoObject.FrameRate);
    
    if IsRusLanguage     % ����
        Wait = waitbar(0,'�������� �����','WindowStyle','modal');
    else
        Wait = waitbar(0,'Loading','WindowStyle','modal');
    end

    while hasFrame(VideoObject)                        
        UserFile.Multimedia(FrameNumber).Frame = im2double(readFrame(VideoObject));
        FrameNumber = FrameNumber+1;                         
        waitbar(FrameNumber / NumOfFrames, Wait);            
    end    
      
    delete(Wait);       
    
catch       % �� ������ ������� ���������
    
    if exist('Wait','var')          % ���� ������������ ������ ���� ��������
        delete(Wait);               % ������� ����
        return;                     % ������� ������
    end
    
    try     % ������� ������� ��� �����������
        
        [Temp,colors] = imread([PathName FileName]);      
        
        if ~isempty(colors)                 % ���� ��������������� -
            Temp = ind2rgb(Temp,colors);    % ��������� ��������������� � RGB
        end 
        
        % ������� ��������� ��� ����������� ��� ������� ������
        UserFile = struct(  'Multimedia',[],...
                            'IsVideo',[],...
                            'Width',[],...
                            'Height',[],...
                            'NumOfChannels',[]); 
                    
        if size(Temp,3) > 3     % ���� �������������� �����������
            UserFile.Multimedia.Frame = im2double(Temp(:,:,1:3));    % ����� ������ 3 ������
        else
            UserFile.Multimedia.Frame = im2double(Temp);        % ����� ����� ���
        end
        
        % ��������� ����������� �����������
        CheckImage(UserFile.Multimedia.Frame);

    catch    % ��� �������� �������� �����������
        
        GenerateError('MultimediaFileOpenningFailed', IsRusLanguage);
        return;                
    end
end

% ���������� ��������
UserFile.Height = size(UserFile.Multimedia(1).Frame, 1);
UserFile.Width = size(UserFile.Multimedia(1).Frame, 2);
UserFile.NumOfChannels = size(UserFile.Multimedia(1).Frame, 3);

if size(UserFile.Multimedia,2) > 1                 % ���� �����
    UserFile.IsVideo = true;
    UserFile.FrameRate = VideoObject.FrameRate;   
else    
    UserFile.IsVideo = false;  
end


% ������� �������� ����������� �����������
function Pattern = OpenPatternImage(IsRusLanguage)

assert(islogical(IsRusLanguage),'���� ����� �� ����������');

Pattern = [];   % ������ �������

% �������� ���� ��� ��������
if IsRusLanguage
    
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
    
    if size(Temp,3) > 3
        Pattern = im2double(Temp(:,:,1:3));    % ���������� ��������
    else
        Pattern = im2double(Temp);    % ���������� ��������
    end
    
    % ��������� ����������� �����������
    CheckImage(Pattern);
    
catch    % �������� �����������
    
    GenerateError('MultimediaFileOpenningFailed', IsRusLanguage);
end


% ���������� ���� ��������� �������� �����
function IsRusLanguage = IsFigureLanguageRussian(handles)

% ������ true, ���� ���������� ������� ����
IsRusLanguage = strcmp(handles.RussianLanguageMenu.Checked,'on');

    
% ��������� ������ � ����-�����������
function SaveImage(Image, FrameNumber, IsRusLanguage)

assert(islogical(IsRusLanguage),'���� ����� �� ����������');
assert(isinteger(FrameNumber),'FrameNumber - �� ������������� ��������');
CheckImage(Image);

if IsRusLanguage    % �� �����    
    [FileName, PathName] = uiputfile(['���� � ' num2str(FrameNumber) '.png'],'��������� ����/�����������');
else
    [FileName, PathName] = uiputfile(['frame � ' num2str(FrameNumber) '.png'],'Save frame/image');
end

if FileName~=0
    imwrite(Image,[PathName FileName]);
end    
    

% ������� ��������� �����������/�����
function ProcessResults = ComputerVisionProcessing(Image, ProcessParameters, IsRusLanguage)

assert(islogical(IsRusLanguage),'���� ����� �� ����������');
assert(isstruct(ProcessParameters), 'ProcessParameters - �� ���������');
assert(~isempty(ProcessParameters), '�������� ������ ��������� ����������� ���������');
CheckImage(Image);

ProcessResults = struct();

% �������� 1�� ����������� � 1� ������ ������ ������������� �����������
ImagesToShow = struct('Images',Image);   
StringOfImages = ReturnRusOrEngString(IsRusLanguage, '��������', 'Original image');

% ������� �������� ��� �������� ���������� 
NewPattern = [];     
Boxes = []; 
StatisticsString = []; 
LABEL = [];

% ��������� ���������� ����� ������
X0 = ProcessParameters.X0;
X1 = ProcessParameters.X1;
Y0 = ProcessParameters.Y0;
Y1 = ProcessParameters.Y1;      

% � ����������� �� ������ ��������� - �����������
switch ProcessParameters.ComputerVisionMethod
    
    case {'������������� ������','Optical character recognition'}        
        
        results = ocr(  Image(Y0:Y1, X0:X1, :),...
                        'TextLayout',ProcessParameters.layout,...
                        'Language',ProcessParameters.lang);
        
        % ��������� ����� � ��� ���������� 
        StatisticsString = results.Words;       
        Boxes = results.WordBoundingBoxes; 
        
        % ������� ������ ����������
        Boxes = Boxes(results.WordConfidences > ProcessParameters.thresh,:);    
        StatisticsString = StatisticsString(results.WordConfidences > ProcessParameters.thresh);
        
        % ������ ���������� ������ ����������� ��� ����������������� �����
        Boxes(:,1) = Boxes(:,1) + X0;
        Boxes(:,2) = Boxes(:,2) + Y0;                          
        
        if isempty(StatisticsString)            
            StatisticsString = ReturnRusOrEngString(IsRusLanguage, '��� �����������', 'no results');            
        end
        
    case {'������ �����-����','Barcode reading'} 
        
    case {'����� �������� � �������','Text region detection'}  
        
    case {'������ �����','Blob analysis'} 
        
        if size(Image,3) > 1            
            GrayImage = rgb2gray(Image);
        else
            GrayImage = Image;
        end
        
        % ���� �� �/�, �������� �����������
        if ~all( all( GrayImage == 0 | GrayImage == 1 ))    
            
            switch ProcessParameters.BinarizationType
                
                case {'����������', 'Adaptive'}      
                    
                    ImageBW = imbinarize(GrayImage,'adaptive',...
                                        'Sensitivity',ProcessParameters.SensOrThersh,...
                                        'ForegroundPolarity',ProcessParameters.Foreground);
                                    
                case {'���������� (���)', 'Global (Otsu)'}                     
                    ImageBW = imbinarize(GrayImage);
                    
                case {'����������', 'Global'}                       
                    ImageBW = imbinarize(GrayImage, ProcessParameters.SensOrThersh);   
                
                otherwise
                    assert(0, '������ ������������ ����� �����������');
            end
        end
        
        % ������ �������� ������� BlobAnalysis
        hBlob = vision.BlobAnalysis;
        hBlob.AreaOutputPort = true;
        hBlob.CentroidOutputPort = true;
        hBlob.BoundingBoxOutputPort = false;
        
        hBlob.PerimeterOutputPort = true;
        hBlob.LabelMatrixOutputPort = true;
        hBlob.Connectivity =        ProcessParameters.Conn;
        hBlob.MaximumCount =        ProcessParameters.MaximumCount;
        hBlob.MinimumBlobArea =     ProcessParameters.MinimumBlobArea;
        hBlob.MaximumBlobArea =     ProcessParameters.MaximumBlobArea;
        hBlob.ExcludeBorderBlobs =  ProcessParameters.BorderBlobs;
        
        % �������� �������, �����, �������� � �������� �����
        [AREA,CENTEROID,PERIMETER,LABEL] = step(hBlob, logical(ImageBW)); 
        
        CENTEROID = round(CENTEROID);
        PERIMETER = round(PERIMETER);
                
        % ������� � ��������� ������ �����
        StatisticsString = cell(1,size(AREA,1));
        
        for x = 1:size(AREA,1)
            
            StatisticsString{x} = ReturnRusOrEngString(IsRusLanguage,...
                                ['����� � ' num2str(x) ...
                                ': ������� / �������� = ' num2str(AREA(x))...
                                ' / ' num2str(PERIMETER(x)) ' (����.)'],...
                                ...
                                ['Blob � ' num2str(x) ...
                                ': area / perimeter = ' num2str(AREA(x))...
                                ' / ' num2str(PERIMETER(x)) ' (pix.)']); 
        end   
        
        if isempty(AREA)       
            StatisticsString = ReturnRusOrEngString(IsRusLanguage, ...
                                        '��� �����������', 'no results');
        end 
        
        %-----------------------------------------------------------------------------------
        % �������� ������ ImagesToShow � ������ �������� ���������
        
        ImagesToShow(end+1).Images = im2double(ImageBW);        
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                    '��������� �����������',...
                                    'Binarization result');
                                
        % ��������� ����������� ����������� � �������� � ������� �����
        ImagesToShow(end+1).Images = ...
            insertMarker(im2double(ImageBW), CENTEROID, 'Color', 'blue');
            
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                '������������ ����� �� �������� �����������',...
                                'Recognized blobs on binary image');
        
        % ��������� ����������� �������� � �������� � ������� �����
        ImagesToShow(end+1).Images = ...
            insertMarker(ImagesToShow(1).Images, CENTEROID, 'Color', 'blue');
                
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                '������������ ����� �� ���������',...
                                'Recognized blobs on original image');         
        
    case {'������������� ���','Face detection'}
        
        % ������-��������
        faceDetector = vision.CascadeObjectDetector(...
                            'MinSize',ProcessParameters.MinSize,...
                            'MaxSize',ProcessParameters.MaxSize,...    
                            'ScaleFactor',ProcessParameters.ScaleFactor,...    
                            'MergeThreshold',ProcessParameters.MergeThreshold,...    
                            'ClassificationModel',ProcessParameters.Model,...    
                            'UseROI', true);
        
        ROI = [X0 Y0 X1-X0 Y1-Y0];
        
        % ��������� ����
        Boxes = step(faceDetector, Image, ROI);    % ����������� Nx4
        
        % ������ ���������� ����������� ��� ����������������� �����
        Boxes(:,1) = Boxes(:,1) + X0;
        Boxes(:,2) = Boxes(:,2) + Y0;       
        
        % ��������� �������������� � ����������
        ImageWithFaces = insertShape(Image, 'rectangle', Boxes, ...
                            'LineWidth', 2, 'Color', 'blue', 'Opacity', 1);
        
        % ��������� �������� 
        ImagesToShow(end+1).Images = ImageWithFaces;                
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                                '������������ ����',...
                                                'Recognized faces');   
                            
    case {'������������� �����','People detection'}
        
    case {'������������� ��������','Object detection'}
        
        if size(Image,3) == 3
            GrayImage = rgb2gray(Image);
        end
        
        Pattern = ProcessParameters.Pattern;
        
        % ����� ����������� ��������
        if size(Pattern,3) == 3
            GrayPattern = rgb2gray(Pattern);
        end
        
        % ��������� ��� ��������� ��� �������� ����� � ����������� ��
        switch ProcessParameters.DetectorType
            
            case 1
                
                PatternPoints = detectMSERFeatures(GrayPattern,...
                                'MaxAreaVariation',ProcessParameters.Slider1Value,...
                                'ThresholdDelta',ProcessParameters.Slider2Value,...
                                'RegionAreaRange',...
                                [ProcessParameters.Slider3Value ProcessParameters.Slider4Value]);
                
                ScenePoints = detectMSERFeatures(GrayImage,...
                                'MaxAreaVariation',ProcessParameters.Slider1Value,...
                                'ThresholdDelta',ProcessParameters.Slider2Value,...
                                'RegionAreaRange',...
                                [ProcessParameters.Slider3Value ProcessParameters.Slider4Value]);
                
            case 2
                
                PatternPoints = detectBRISKFeatures(GrayPattern,...
                                'MinContrast',ProcessParameters.Slider1Value,...
                                'NumOctaves',ProcessParameters.Slider3Value,...
                                'MinQuality',ProcessParameters.Slider2Value);
                
                ScenePoints = detectBRISKFeatures(GrayImage,...
                                'MinContrast',ProcessParameters.Slider1Value,...
                                'NumOctaves',ProcessParameters.Slider3Value,...
                                'MinQuality',ProcessParameters.Slider2Value);
                
            case 3
                
                PatternPoints = detectFASTFeatures(GrayPattern,...
                                'MinContrast',ProcessParameters.Slider1Value,...
                                'MinQuality',ProcessParameters.Slider2Value);
                
                ScenePoints = detectFASTFeatures(GrayImage,...
                                'MinContrast',ProcessParameters.Slider1Value,...
                                'MinQuality',ProcessParameters.Slider2Value);
                
            case 4
                
                PatternPoints = detectHarrisFeatures(GrayPattern,...
                                'FilterSize',ProcessParameters.Slider3Value,...
                                'MinQuality',ProcessParameters.Slider2Value);
                
                ScenePoints = detectHarrisFeatures(GrayImage,...
                                'FilterSize',ProcessParameters.Slider3Value,...
                                'MinQuality',ProcessParameters.Slider2Value);
                
            case 5
                
                PatternPoints = detectMinEigenFeatures(GrayPattern,...
                                'FilterSize',ProcessParameters.Slider3Value,...
                                'MinQuality',ProcessParameters.Slider2Value);
                
                ScenePoints = detectMinEigenFeatures(GrayImage,...
                                'FilterSize',ProcessParameters.Slider3Value,...
                                'MinQuality',ProcessParameters.Slider2Value);
                
            case 6      
                
                PatternPoints = detectSURFFeatures(GrayPattern,...
                                'MetricThreshold',ProcessParameters.Slider2Value,...
                                'NumOctaves',ProcessParameters.Slider3Value,...
                                'NumScaleLevels',ProcessParameters.Slider4Value);
                
                ScenePoints = detectSURFFeatures(GrayImage,...
                                'MetricThreshold',ProcessParameters.Slider2Value,...
                                'NumOctaves',ProcessParameters.Slider3Value,...
                                'NumScaleLevels',ProcessParameters.Slider4Value);
                SURFSize = 64;
                
            case 7                  
                
                PatternPoints = detectSURFFeatures(GrayPattern,...
                                'MetricThreshold',ProcessParameters.Slider2Value,...
                                'NumOctaves',ProcessParameters.Slider3Value,...
                                'NumScaleLevels',ProcessParameters.Slider4Value);
                            
                ScenePoints = detectSURFFeatures(GrayImage,...
                                'MetricThreshold',ProcessParameters.Slider2Value,...
                                'NumOctaves',ProcessParameters.Slider3Value,...
                                'NumScaleLevels',ProcessParameters.Slider4Value);
                SURFSize = 128;
                
            otherwise
                assert(0,'��� �� ����� �� ���...������� �������������� ������� ����');
        end
        
        % ��������� ���� ������� � �����
        % ��� surf ��������� �����
        if ProcessParameters.DetectorType == 6 || ProcessParameters.DetectorType == 7
            
            [PatternFeatures, PatternPoints] = extractFeatures(...
                GrayPattern,PatternPoints,...
                'Upright',ProcessParameters.UpRight, 'SURFSize',SURFSize);
            
            [SceneFeatures, ScenePoints] = extractFeatures(GrayImage, ScenePoints,...
                'Upright',ProcessParameters.UpRight, 'SURFSize',SURFSize);
        else
            
            [PatternFeatures, PatternPoints] = extractFeatures(...
                GrayPattern,PatternPoints,'Upright',ProcessParameters.UpRight);
            
            [SceneFeatures, ScenePoints] = extractFeatures(GrayImage, ScenePoints,...
                'Upright',ProcessParameters.UpRight);
            
        end
        
        % ���������� ����, ������� ���� �������
        % ��� �������� ���� ��p�� ��� �������
        if      ProcessParameters.DetectorType == 1 ||...
                ProcessParameters.DetectorType == 6 || ...
                ProcessParameters.DetectorType == 7
            
            Pairs = matchFeatures(PatternFeatures, SceneFeatures, ...
                        'Method', ProcessParameters.MatchMethod,...
                        'MatchThreshold',ProcessParameters.MatchThreshold,...
                        'MaxRatio',ProcessParameters.MaxRatio,...
                        'Metric',ProcessParameters.Metric, 'Unique',...
                        ProcessParameters.UseUnique);
                    
        else
            
            Pairs = matchFeatures(PatternFeatures, SceneFeatures, ...
                        'ComputerVisionMethod', ProcessParameters.MatchMethod,...
                        'MatchThreshold',ProcessParameters.MatchThreshold,...
                        'MaxRatio',ProcessParameters.MaxRatio,...
                        'Unique',ProcessParameters.UseUnique);
            
        end
        
        % �������� �� ���� ��������� ����� ������ ��������� �� �� ������� � Pairs
        MatchedPatternPoints = PatternPoints(Pairs(:, 1), :);
        MatchedScenePoints = ScenePoints(Pairs(:, 2), :);
        
        % ������� ������ �� �������������� ���������
        [~,~,ResultPoints,~] = estimateGeometricTransform(...
                                MatchedPatternPoints, ...
                                MatchedScenePoints,...
                                ProcessParameters.TransformationType,... 
                                'MaxNumTrials',ProcessParameters.MaxNumTrials, ...
                                'Confidence',ProcessParameters.Confidence,...
                                'MaxDistance', ProcessParameters.MaxDistance);      
        
        % � ��� ������� �������� ��� �� ����� ����������� ��������� ������� 
        NewPattern = insertMarker(GrayPattern, round(PatternPoints.Location), 'Color', 'blue'); 
        
        %-----------------------------------------------------------------------------------
        % �������� ������ ImagesToShow � ������ �������� ���������
        
        if size(Image,3) == 3
            GrayImage = rgb2gray(Image);
            
            ImagesToShow(end+1).Images = GrayImage;
            StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                        '����������� �����������',...
                                        'Grayscale image');
        end         
        
        ImagesToShow(end+1).Images = insertMarker(GrayImage, ScenePoints, 'Color', 'blue');                                    
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                    '��� ��������� �������� �����',...
                                    'All found keypoints');                                
                                         
        ImagesToShow(end+1).Images = insertMarker(GrayImage, ScenePoints(Pairs(:,2),:), 'Color', 'blue');             
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                    '����������� �������� �����',...
                                    'Matched keypoints');                                
        
        ImagesToShow(end+1).Images = insertMarker(GrayImage, ResultPoints, 'Color', 'blue');             
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                    '���������� ����������� �������� ����� (����������� �����������)',...
                                    '�orrect matched keypoints (grayscale image)');
                                
        if size(Image,3) == 3
            
            ImagesToShow(end+1).Images = insertMarker(Image, ResultPoints, 'Color', 'blue');            
            StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                        '���������� ����������� �������� ����� (�������� �����������)',...
                        '�orrect matched keypoints (original image)');
        end
        
    case {'�������� 3D-�����������','3-D image creation'}
        
    case {'��������� �����','Video processing'}
        
    case {'�������� ��������','Panorama creation'}
        
    case {'������������� ��������','Motion detection'}
        
    otherwise
        assert(0, '������ � ��������� � ������� ���������');
        
end   

% ��������� �������� �����������
for x = 1:size(ImagesToShow,2)
    CheckImage(ImagesToShow(x).Images);
end

if ~isempty(NewPattern)
    CheckImage(NewPattern);
end

% ��������� �������� ��������� �������
ProcessResults.ImagesToShow.Images = ImagesToShow;
ProcessResults.StringOfImages = StringOfImages;
ProcessResults.NewPattern = NewPattern;
ProcessResults.StatisticsString = StatisticsString;
ProcessResults.LABEL = LABEL;
ProcessResults.Boxes = Boxes;


% ������� ����������� ����������������� �����
function ShowMultimediaFile(handles)

assert(isstruct(handles),'�������� �� ��������� ��������� ����������');

% ��� ��������� ������-�������� � ����
FrameObj = findobj('Parent',handles.FileAxes, 'Tag','FrameObj');

% �������� �����, ������� ����� ����������
ImagesToShow = getappdata(handles.KAACVP,'ImagesToShow');

% ��������� ���
assert(~isempty(ImagesToShow),...
        '� ��� �� �������� ������ � ������� ���������');

assert(size(ImagesToShow, 2) == size(handles.ImagesToShowMenu.String, 1),...
        '����� ����� �� ������������� ����� �����������'); 
    
% ������� �� ���������� ������������ ����
ImageToView = ImagesToShow(handles.ImagesToShowMenu.Value).Images;

% ���� ����������� - ����������, �������� ���������� 2 ������ 
if size(ImageToView, 3) ~= size(FrameObj.CData, 3)
    
    ImageToView(:,:,2) = ImageToView(:,:,1);
    ImageToView(:,:,3) = ImageToView(:,:,1);
end

% �������� ������ ������ � ����� ������� ����
set(FrameObj, 'CData', ImageToView);
handles.FileAxes.Visible = 'off';


% ����������� ��� ��� ���� ������ � ����������� �� ����� ����������
function String = ReturnRusOrEngString(IsRusLanguage, RusString, EngString)

% ������ 2� (���� IsRusLanguage == true) 
% ��� 3� �������� (���� IsRusLanguage == false)

assert(islogical(IsRusLanguage),'���� ����� �� ����������');
assert(iscell(RusString) || ischar(RusString), '2� ������� �������� �� ���������');
assert(iscell(EngString) || ischar(EngString), '3� ������� �������� �� ���������');

if IsRusLanguage
    String = {RusString};
else
    String = {EngString}; 
end


% �������� �������� ��� ������������
function CheckImage(Image)

assert(isfloat(Image),'Image ����� ������ �������� �� double');
assert(~isempty(Image), 'Image - ������ ������');
assert(size(Image,1) > 1 || size(Image,2) > 1, 'Image - ������, � �� �����������');
assert(size(Image,3) < 4, 'Image - �������������� �����������');
assert(all(Image(:) <= 1 & Image(:) >= 0), 'Image ����� �������� ��� ��������� [0 1]');


% ���������� ������ � ������������ � �� ����� � ������
function GenerateError(ErrorCode, IsRusLanguage)

assert(islogical(IsRusLanguage), 'IsRusLanguage �� ����������');

% �� ���� ������ ����������� �������������� ������
% � ����������� �� ����� ������������ ������������ �������
switch ErrorCode    
    
    case 'FigFIleOpened'
        
        InfoStirng = {  '�� ��������� ���� � ����������� *.fig ������ ���������� *.m.';...
                        '������� "OK", � ��� ����� ������!';
                        'You have started a file with expansion *.fig instead of *.m.';
                        'Press "OK" to make it OK.'};
    
    case 'ShouldBeDigits'
        
        InfoStirng = ReturnRusOrEngString(IsRusLanguage,...
                                '������� � ������ �������� ��������',...
                                'Use digits only in this field');
    
    case 'MultimediaFileOpenningFailed'        
        
        InfoStirng = ReturnRusOrEngString(IsRusLanguage,...
                                '� ������ ���-�� �� ���. �������� ������',...
                                'File is improper. Choose another file');  
                            
    case 'NoCV_NoIPT'
        
        InfoStirng = [  '����������� ���������� "Computer Vision System Toolbox 7.3".';...
                        '����������� ���������� "Image Processing Toolbox 10.0".';...
                        '...�� �� ��������� �����!';...
                        '���������� ����� �������.';...
                        '��� ����� �������, �������� ���������� � ��������!';...
                        '� ���������� ���������� ��� ����� ��� ����!';...
                        {' '};...
                        '"Computer Vision System Toolbox 7.3" is missing.'; ...
                        '"Image Processing Toolbox 10.0" is missing.';...
                        'Application will be closed. Good luck to you, buddy.';...
                        'Set up these toolboxes to run application.'];
             
    case 'NoIPT'
        
        InfoStirng = [  '����������� ���������� "Image Processing Toolbox 10.0".';...
                        '...�� �� ��������� �����!';...
                        '���������� ����� �������.';...
                        '��� ����� �������, �������� ���������� � ��������!';...
                        '� ���������� ���������� ��� ����� ��� ����!';...
                        {' '};...
                        '"Image Processing Toolbox 10.0" is missing.'; ...
                        'Application will be closed. Good luck to you, buddy.';...
                        'Set up this toolbox to run application.'];
    case 'NoCV'
        
        InfoStirng = [  '����������� ���������� "Computer Vision System Toolbox 7.3".';...
                        '...�� �� ��������� �����!';...
                        '���������� ����� �������.';...
                        '��� ����� �������, �������� ���������� � ��������!';...
                        '� ���������� ���������� ��� ����� ��� ����!';...
                        {' '};...
                        '"Computer Vision System Toolbox 7.3" is missing.'; ...
                        'Application will be closed. Good luck to you, buddy.';...
                        'Set up this toolbox to run application.'];
    
    otherwise
        
        assert(0, '������� ������ ��� ������!');
        
end

% ���������� ��������� ���� ������
errordlg(InfoStirng,'KAACVP','modal');


% ��������� ������� ��������� �������� ����������� ������
function ToolboxPresence = DoWeHaveThisToolbox(ThisToolbox, NecessaryToolboxVersion)

assert(ischar(ThisToolbox),'������� �� �������� �������');
assert(isnumeric(NecessaryToolboxVersion), 'NecessaryToolboxVersion - �� �����');

ToolboxPresence = false;
toolboxes = ver();          % ��������� ���������� �� ������������� �������

for i = 1:size(toolboxes,2) % ���������� �� �������

    if strcmp(ThisToolbox,toolboxes(i).Name) == 1 % ���� �����  
        
        % � ��� ������ ������������� ��� ���� �����������
        if str2double(toolboxes(i).Version) >= NecessaryToolboxVersion            
            ToolboxPresence = true;
        end        
    end
end

assert(islogical(ToolboxPresence), 'ToolboxPresence �� ������ �� ����������');


% ��������� ������� FIG- ��� M-����
function IsFigFile = IsFigFileRunned(handles)

IsFigFile = false;          % �� ��������� ������ "���"

if isempty(handles)         % ������ �������� fig ������ m  
    
    IsFigFile = true;
    GenerateError('FigFIleOpened', true);  
    uiwait(gcf);        % ���� �������� ���� ������
    close(gcf);         % ��������� fig-����
    run('KAACVP.m');     % ��������� ���������� ����
    return;
end

warning('on','all');


% ���������� ������ ����������� ��������������� ��� ���������� ��������� � �������� ������
function [TrainModelSize, FaceDetectorModel] = ReturnFaceDetectorTrainModelAndSize(ClassificationModel)

assert(isstring(ClassificationModel), 'ClassificationModel �� ������');

switch ClassificationModel
    case {'Frontal face (CART)','����� (CART)'}
        TrainModelSize = [20 20];
        FaceDetectorModel = 'FrontalFaceCART';
        
    case {'Frontal face (LBP)','����� (LBP)'}
        TrainModelSize = [24 24];
        FaceDetectorModel = 'FrontalFaceLBP';
        
    case {'Upper body','���� ����'}
        TrainModelSize = [20 22];
        FaceDetectorModel = 'UpperBody';
        
    case {'Eye pair (big)','���� ���� (�������)'}
        TrainModelSize = [11 45];
        FaceDetectorModel = 'EyePairBig';
        
    case {'Eye pair (small)','���� ���� (�����)'}
        TrainModelSize = [5 22];
        FaceDetectorModel = 'EyePairSmall';
        
    case {'Left eye','����� ����'}
        TrainModelSize = [12 18];
        FaceDetectorModel = 'LeftEye';
        
    case {'Right eye','������ ����'}
        TrainModelSize = [12 18];
        FaceDetectorModel = 'RightEye';
        
    case {'Left eye (CART)','����� ���� (CART)'}
        TrainModelSize = [20 20];
        FaceDetectorModel = 'LeftEyeCART';
        
    case {'Right eye (CART)','������ ���� (CART)'}
        TrainModelSize = [20 20];
        FaceDetectorModel = 'RightEyeCART';
        
    case {'Profile face','�������'}
        TrainModelSize = [20 30];
        FaceDetectorModel = 'ProfileFace';
        
    case {'Mouth','���'}
        TrainModelSize = [15 25];
        FaceDetectorModel = 'Mouth';
        
    case {'Nose','���'}
        TrainModelSize = [15 18]; 
        FaceDetectorModel = 'Nose'; 
        
    otherwise
        assert(0, '������� �������������� ������ ������������� ��������� ���');
end


% ��������� ROI / �������
function RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition)

delete(findobj('Parent',handles.FileAxes,'LineStyle','--'));

UserFile = getappdata(handles.KAACVP,'UserFile');

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod
    
    case {  '������������� ������','Optical character recognition',...
            '������������� ���','Face detection'}
        
        rectangle(  'Position',ROIPosition,...
            'Parent',handles.FileAxes,...
            'EdgeColor','r',...
            'LineStyle','--',...
            'LineWidth',2);
        
    case {  '������������� ��������','Object detection',...
            '�������� 3D-�����������','3-D image creation'}
        
        % ����� ROI ������������ � �������� ����������� �����������-�������        
        Image = UserFile.Multimedia(handles.FrameSlider.Value).Frame;        
        Pattern = Image(X0Y0X1Y1Coords(2):X0Y0X1Y1Coords(4), X0Y0X1Y1Coords(1):X0Y0X1Y1Coords(3), :);
        
        image(Pattern,'Parent',handles.PatternAxes);
        handles.PatternAxes.Visible = 'off';
        
        setappdata(handles.KAACVP,'Pattern',Pattern);
        
        % ������ ��� ����� ���������� � ������������ �� �������� ������
        ZoomButton_Callback([], [], handles);
        
        % ������������ ��������, ����� ����� ���� ������� �������� ��������� ROI        
        set([...
            handles.ROIx0;...
            handles.ROIy0;...
            handles.ROIx1;...
            handles.ROIy1;...
            ],'Enable','on');       
        
        handles.ShowPatternImageMenu.Visible = 'on';
end


% ��������� �������� ����������
function DoyouWantToBlockInterface(WantToBlockIt, handles, IsVideo)

% ��������� ����������� ��������� ��� ����� - ������ ����...
assert(islogical(IsVideo), 'BlockIt �� ����� �� ����������');
if IsVideo
    return;
end

assert(isstruct(handles),'�������� �� ��������� ��������� ����������');
assert(islogical(WantToBlockIt), 'BlockIt �� ����� �� ����������');
IsRusLanguage = IsFigureLanguageRussian(handles);
    
if WantToBlockIt
    
    set(findobj('Parent', handles.KAACVP, '-not', 'Type', 'uipanel'), 'Enable', 'off');
    set(handles.ParametersPanel.Children, 'Enable', 'off'); 
    
    handles.KAACVP.Name = string(ReturnRusOrEngString(IsRusLanguage,...
                        'KAACVP: ���� ��������� ... �� ����� ���������...',...
                        'KAACVP: processing is running ... it tries so hard...'));
else
    set(findobj('Parent', handles.KAACVP, '-not', 'Type', 'uipanel'), 'Enable', 'on');
    set(handles.ParametersPanel.Children, 'Enable', 'on');
    handles.KAACVP.Name = 'KAACVP';
end

drawnow;


% ������ ������� ������������ ������� ���������
function SetParSlidersVisibleStatus(ParSliderNumbersList, ShowIt, handles)

% ����� ��������� ���������� � ����������
NumOfParSliders = 9;

assert(all(ParSliderNumbersList <= NumOfParSliders),['��������� ��������� ����� ' num2str(NumOfParSliders)]);
assert(all(ParSliderNumbersList > 0), '������� ��������� ���������� � 1!');
assert(isnumeric(ParSliderNumbersList), 'ParSliderNumbersList ����� - �� �����');
assert(isstruct(handles),'�������� �� ��������� ��������� ����������');

ParSliderNumbersList = uint8(ParSliderNumbersList);

if ShowIt
    Status = 'on'; 
else
    Status = 'off'; 
end

for x = 1 : length(ParSliderNumbersList)
   set(eval(['handles.ParSlider' num2str( ParSliderNumbersList(x) )]), 'Visible', Status);
   set(eval(['handles.ParSliderText' num2str( ParSliderNumbersList(x) )]), 'Visible', Status);
   set(eval(['handles.ParSliderValueText' num2str( ParSliderNumbersList(x) )]), 'Visible', Status);
end


% ������ ������� ������������ ���� ���������
function SetParMenusVisibleStatus(ParMenuNumbersList, ShowIt, handles)

% ����� ���� ���������� ����������
NumOfParMenu = 4;

assert(all(ParMenuNumbersList <= NumOfParMenu),['���� ��������� �����' num2str(NumOfParMenu)]);
assert(all(ParMenuNumbersList > 0), '������� ��������� ���������� � 1!');
assert(isnumeric(ParMenuNumbersList), 'ParMenuNumbersList ����� - �� �����');
assert(isstruct(handles),'�������� �� ��������� ��������� ����������');

ParMenuNumbersList = uint8(ParMenuNumbersList);

if ShowIt
    Status = 'on'; 
else
    Status = 'off'; 
end

for x = 1 : length(ParMenuNumbersList)
   set(eval(['handles.ParMenu' num2str( ParMenuNumbersList(x) )]), 'Visible', Status);
   set(eval(['handles.ParMenuText' num2str( ParMenuNumbersList(x) )]), 'Visible', Status);
end


% ������ ������� �������� ROI
function SetROI_Visible(handles)
                            
handles.ROIShowMenu.Enable = 'on';

set([...
    handles.ROIx0;...
    handles.ROIy0;...
    handles.ROIx1;...
    handles.ROIy1;...
    handles.ROIButton;...
    handles.ROIText;...
    ],'Visible','on');

