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

handles.PlayPauseButton.CData = imread('Play.png');
handles.FrameBackButton.CData = imread('FrameBack.png');
handles.FrameForwardButton.CData = imread('FrameForward.png');

scr_res = get(0, 'ScreenSize');     % получили разрешение экрана
fig = get(handles.KAACV,'Position');  % получили координаты окна

% отцентрировали окно
set(handles.KAACV,'Position',[(scr_res(3)-fig(3))/2 (scr_res(4)-fig(4))/2 fig(3) fig(4)]);

toolboxes = ver();      % считываем наличие тулбоксов
warning('off','all');
matlab_version = toolboxes(1).Release;
matlab_version = str2double(matlab_version(3:6));

if matlab_version < 2017    
    message_str = { 'Ваша версия Matlab ниже версии R2017a';...
                    'Возможны ошибки и некорректное поведение программы'};
end  

CV = false;     % проверка расширения Computer Vision System Toolbox
for i = 1:size(toolboxes,2) % проходимся по каждому

    if strcmp('Computer Vision System Toolbox',toolboxes(i).Name) == 1
        CV = true;
    end
end

ImPrTB = false;             % проверка расширения Image Processing Toolbox
for i = 1:size(toolboxes,2) % проходимся по каждому тулбоксу

    if strcmp('Image Processing Toolbox',toolboxes(i).Name) == 1
        ImPrTB = true;
    end
end 

if ~ CV 
    message_str = [ message_str;...
                    'Отсутствует расширение "Computer Vision System Toolbox":';...
                    'В списке обработок детекторы ключевых точек недоступны'];
end

if ~ ImPrTB 
    message_str = [ message_str;...
                    'Отсутствует расширение "Image Processing Toolbox":';...
                    'Вряд ли что-то заработает...'];
end
                        
if exist('message_str') > 0    % вывод сообщения
    questdlg(message_str,'KAACV','OK','modal');
end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% МЕНЮ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% "ОТКРЫТЬ ФАЙЛ"
function OpenMenu_Callback(hObject, eventdata, handles)


% "ПОКАЗАТЬ КАДР"
function ShowFrameMenu_Callback(hObject, eventdata, handles)


% "ПОКАЗАТЬ ШАБЛОН"
function ShowPatternImageMenu_Callback(hObject, eventdata, handles)


% "РУССКИЙ ЯЗЫК"
function RussianLanguageMenu_Callback(hObject, eventdata, handles)


% "ENGLISH LANGUAGE"
function EnglishLanguageMenu_Callback(hObject, eventdata, handles)


% ВЫБОР МЕТОДА ОБРАБОТКИ
function MethodMenu_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% КНОПКИ  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ВОПСРОИЗВЕДЕНИЕ / ПАУЗА
function PlayPauseButton_Callback(hObject, eventdata, handles)

% меняем картинку кнопки и блокируем соседей
if handles.PlayPauseButton.Value == 0
    handles.PlayPauseButton.CData = imread('Play.png');
    handles.FrameBackButton.Enable = 'on';
    handles.FrameForwardButton.Enable = 'on';
else
    handles.PlayPauseButton.CData = imread('Pause.png');
    handles.FrameBackButton.Enable = 'off';
    handles.FrameForwardButton.Enable = 'off';    
end


% ПРЕДЫДУЩИЙ КАДР 
function FrameBackButton_Callback(hObject, eventdata, handles)


% СЛЕДУЮЩИЙ КАДР
function FrameForwardButton_Callback(hObject, eventdata, handles)


% ПРИМЕНИТЬ
function ApplyButton_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% СПИСКИ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% СПИСОК СТАТИСТИКИ ПО ИЗОБРАЖЕНИЮ
function StatisticsList_Callback(hObject, eventdata, handles)


function ParMenu1_Callback(hObject, eventdata, handles)


function ParMenu2_Callback(hObject, eventdata, handles)


function ROIButton_Callback(hObject, eventdata, handles)


function ROIx0_Callback(hObject, eventdata, handles)


function ROIy0_Callback(hObject, eventdata, handles)


function ROIx1_Callback(hObject, eventdata, handles)


function ROIy1_Callback(hObject, eventdata, handles)


function ParMenu3_Callback(hObject, eventdata, handles)


function PatternOpenButton_Callback(hObject, eventdata, handles)


function ParMenu4_Callback(hObject, eventdata, handles)


function VideoMenu_Callback(hObject, eventdata, handles)


function popupmenu7_Callback(hObject, eventdata, handles)


function popupmenu7_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slider2_Callback(hObject, eventdata, handles)


function slider2_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slider3_Callback(hObject, eventdata, handles)


function slider3_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slider4_Callback(hObject, eventdata, handles)


function slider4_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slider6_Callback(hObject, eventdata, handles)


function slider6_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slider7_Callback(hObject, eventdata, handles)


function slider7_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slider8_Callback(hObject, eventdata, handles)


function slider8_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function ParSlider2_Callback(hObject, eventdata, handles)


function ParSlider2_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function checkbox2_Callback(hObject, eventdata, handles)


function checkbox3_Callback(hObject, eventdata, handles)


function slider11_Callback(hObject, eventdata, handles)


function slider11_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
