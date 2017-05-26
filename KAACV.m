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

% вставляем картинки в кнопки
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
message_str = {};

if matlab_version < 2017    
    message_str = [ message_str;...
                    'Ваша версия Matlab ниже версии R2017a.';...
                    'Your Matlab version is lower than R2017a.'];
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
                    'Отсутствует расширение "Computer Vision System Toolbox".';...
                    '"Computer Vision System Toolbox" is missing.'];
end

if ~ ImPrTB 
    message_str = [ message_str;...
                    'Отсутствует расширение "Image Processing Toolbox".';...
                    '"Image Processing Toolbox" is missing.'];
end
       
% вызываем выбор метода
MethodMenu_Callback(hObject, eventdata, handles);

if ~isempty(message_str)    % вывод сообщения
    questdlg([message_str; ...
        '...Но вы держитесь здесь!';...
        'Приложение будет закрыто.' ;...
        'Вам всего доброго, хорошего настроения и здоровья!';
        'С установкой расширений все будет как надо!';
        'Application will be closed. Good luck to you, buddy'],'KAACV','OK','modal');
    close(gcf);
    return;
end 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% МЕНЮ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% "ОТКРЫТЬ ФАЙЛ"
function OpenMenu_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%% ПРОВЕРКИ

if isempty(handles)            % значит неумный человек запустил fig вместо m  
    
    questdlg({  'Вы запустили файл с расширением *.fig вместо расширения *.m.';...
                'Нажмите "OK", и все будет хорошо';
                'You have started a file with expansion *.fig instead of *.m.';
                'Press "OK" to make it OK'},...
                'KAACV','OK','modal');
    
    % сюда зайдет в любом случае, цикл нужен, чтобы дождаться ответа
    if true      
        close(gcf);
        run('KAACV.m');
        return;
    end
end

warning('on','all');

% выбираем файл для открытия
if strcmp(handles.RussianLanguageMenu.Checked,'on')      % по языку
    
    [FileName, PathName] = uigetfile(...
        {'*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        'Изображения (*.jpg,*.tif,*.tiff,*.bmp,*.png)';...
        '*.avi;*,mj2;*.mpg;*.mp4;*.m4v;*.mov;*.wmv;*.ogg;*.asf;*.asx',...
        'Видео (*.avi,*.mj2,*.mpg,*.mp4,*.m4v,*.mov,*.wmv,*.ogg,*.asf,*.asx)';...
        '*.*', 'All Files(*.*)'},...
        'Выберите файл для обработки',...
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

if ~FileName        % Проверка, был ли выбран файл
    return;
end

UserFile = struct('Video',[],'Image',[],'FrameRate',[]);   % выделяем память

try         % пробуем открыть как видеофайл
    
    VideoObject = VideoReader([PathName FileName]); % видеообъект
    VideoInfo = readFrame(VideoObject);             % читаем первый кадр
    
    UserFile.Video = zeros(size(VideoInfo));        % создаем размер для структуры
    
    frame = 1;                                      % счетчик кадров
    NumOfFrames = round(VideoObject.Duration * VideoObject.FrameRate);
    
    Wait = waitbar(0,'Загрузка видео','WindowStyle','modal');

    while hasFrame(VideoObject)                         % пока есть кадр
        UserFile(frame).Video = readFrame(VideoObject); % кидаем в структуру
        frame = frame+1;                                % счетчик +
        waitbar(frame / NumOfFrames, Wait);             % рисуем прогрузку
    end    
    
    delete(Wait);       % удаляем загрузки окно
    
    % вставляем первый кадр в ось
    image(VideoInfo,'Parent',handles.FileAxes);
    handles.FileAxes.Visible = 'off';
    
    % записываем свойства видео
    UserFile(1).FrameRate = VideoObject.FrameRate;
    
    % устанавливаем слайдер кадров
    handles.FrameSlider.Value = 1;
    handles.FrameSlider.Min = 1;
    handles.FrameSlider.Max = NumOfFrames;
    handles.FrameSlider.SliderStep = [1/(NumOfFrames-1) 10/(NumOfFrames-1)];
    
    % открываем кнопки воспроизведения
    set([...
        handles.PlayPauseButton;...
        handles.FrameBackButton;...
        handles.FrameForwardButton;...
        handles.FrameSlider;...
        ],'Visible','on');
    
catch       % не смогли открыть видеофайл
    
    if exist('Wait','var')          % если пользователь закрыл окно загрузки
        delete(Wait);               % удаляем окно
        return;                     % выходим отсюда
    end
    
    try     % пробуем открыть как изображение
        
        [Temp,colors] = imread([PathName FileName]);      
        
        if ~isempty(colors)
            Temp = ind2rgb(Temp,colors);    % индексированное в RGB
        end  
        
        UserFile.Image = Temp;              % запиливаем RGB
        
        % вставляем изображение
        imshow(UserFile.Image,'Parent',handles.FileAxes);
        
        set([...
            handles.PlayPauseButton;...
            handles.FrameBackButton;...
            handles.FrameForwardButton;...
            handles.FrameSlider;...
            ],'Visible','off');
        
    catch    % оба варианты открытия провалились
        
        if strcmp(handles.RussianLanguageMenu.Checked,'on')     % язык
            h = errordlg('С файлом что-то не так. Откройте другой','KAACV');
        else
            h = errordlg('File is improper. Choose another file','KAACV');
        end
        
        set(h, 'WindowStyle', 'modal');
        return;        
    end
end

% открываем/разблокируем все нужные элементы

set([...
    handles.ParametersPanel;...
    handles.MethodMenu;...
    handles.ApplyButton;...
    ],'Visible','on');

set([...
    handles.ShowFrameMenu;...
    ],'Enable','on');

% записываю удачно открытый файл

setappdata(handles.FileAxes,'UserFile',UserFile);





% "ПОКАЗАТЬ КАДР"
function ShowFrameMenu_Callback(hObject, eventdata, handles)


% "ПОКАЗАТЬ ШАБЛОН"
function ShowPatternImageMenu_Callback(hObject, eventdata, handles)


% "РУССКИЙ ЯЗЫК"
function RussianLanguageMenu_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%% ПРОВЕРКА

if isempty(handles)            % значит неумный человек запустил fig вместо m  
    
    questdlg({  'Вы запустили файл с расширением *.fig вместо расширения *.m.';...
                'Нажмите "OK", и все будет хорошо'},...
                'KAACV','OK','modal');
    
    if true                    % ждем ответа    
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

%%%%%%%%%%%%% ПРОВЕРКА

if isempty(handles)            % значит неумный человек запустил fig вместо m  
    
    questdlg({  'You have started a file with expansion *.fig instead of *.m.';...
                'Press "OK", to make it OK'},...
                'KAACV','OK','modal');    
    
    if true                 % ждем ответа 
        close(gcf);
        run('KAACV.m');
        return;
    end
end

warning('on','all');

handles.EnglishLanguageMenu.Checked = 'on';
handles.RussianLanguageMenu.Checked = 'off';


% ВЫБОР МЕТОДА ОБРАБОТКИ
function MethodMenu_Callback(hObject, eventdata, handles)

% прячем все элементы
set(handles.ParametersPanel.Children,'Visible','off');


% ВЫБОР ОТОБРАЖАЕМОГО ВИДЕО
function VideoMenu_Callback(hObject, eventdata, handles)


% МЕНЮ № 1 ПАРАМЕТРОВ 
function ParMenu1_Callback(hObject, eventdata, handles)


% МЕНЮ № 2 ПАРАМЕТРОВ 
function ParMenu2_Callback(hObject, eventdata, handles)


% МЕНЮ № 3 ПАРАМЕТРОВ 
function ParMenu3_Callback(hObject, eventdata, handles)


% МЕНЮ № 4 ПАРАМЕТРОВ 
function ParMenu4_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% КНОПКИ  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ВОСПРОИЗВЕДЕНИЕ / ПАУЗА
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
    
    % считываем частоту кадров
    UserFile = getappdata(handles.FileAxes,'UserFile'); 
    FrameRate = UserFile(1).FrameRate;
    
    % прогоняем кадры
    for frame = handles.FrameSlider.Value : handles.FrameSlider.Max
        image(UserFile(frame).Video, 'Parent', handles.FileAxes);
        handles.FileAxes.Visible = 'off';
        handles.FrameSlider.Value = frame;  % установка слайдера
 
        sec = mod(frame / FrameRate, 60);       % остаток в сек.
        min = (frame / FrameRate - sec) / 60;   % мин
        sec = round(sec);                       % остаток в сек.
        
        ShowTimeAndFrame(handles, frame, min, sec);
        
        pause(1/FrameRate);
        
        % если прервали на паузу
        if handles.PlayPauseButton.Value == 0   
            handles.PlayPauseButton.CData = imread('Play.png');
            handles.FrameBackButton.Enable = 'on';
            handles.FrameForwardButton.Enable = 'on';
            return;
        end
    end    
end


% ПРЕДЫДУЩИЙ КАДР 
function FrameBackButton_Callback(hObject, eventdata, handles)

frame = handles.FrameSlider.Value - 1;  % считываем кадр

if frame < handles.FrameSlider.Min
    frame = handles.FrameSlider.Min;
end

FrameSlider_Callback(hObject, frame, handles)


% СЛЕДУЮЩИЙ КАДР
function FrameForwardButton_Callback(hObject, eventdata, handles)

frame = handles.FrameSlider.Value + 1;  % считываем кадр

if frame > handles.FrameSlider.Max
    frame = handles.FrameSlider.Max;
end

FrameSlider_Callback(hObject, frame, handles)


% ПРИМЕНИТЬ
function ApplyButton_Callback(hObject, eventdata, handles)

% показываем, что процесс применения длителен: при нажатии
if handles.ApplyButton.Value == 1
    handles.ApplyButton.String = 'Применяется';
else
    handles.ApplyButton.String = 'Применить';
end


% ВЫБОР ОБЛАСТИ ИНТЕРЕСА
function ROIButton_Callback(hObject, eventdata, handles)


% ОТКРЫТЬ ШАБЛОН
function PatternOpenButton_Callback(hObject, eventdata, handles)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%% СЛАЙДЕРЫ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% СЛАЙДЕР КАДРОВ ВИДЕО
function FrameSlider_Callback(hObject, eventdata, handles)

% считываем видос
UserFile = getappdata(handles.FileAxes,'UserFile');

if ~isnumeric(eventdata)
    frame = round(handles.FrameSlider.Value);
else
    frame = eventdata;
end

handles.FrameSlider.Value = frame;      % установка слайдера

image(UserFile(frame).Video, 'Parent', handles.FileAxes);
handles.FileAxes.Visible = 'off';
 
sec = mod(frame / UserFile(1).FrameRate, 60);       % остаток в сек.
min = (frame / UserFile(1).FrameRate - sec) / 60;   % мин
sec = round(sec);                                   % остаток в сек.

ShowTimeAndFrame(handles, frame, min, sec);         % прописываем


% СЛАЙДЕР ПАРАМЕТРОВ № 1
function ParSlider1_Callback(hObject, eventdata, handles)


% СЛАЙДЕР ПАРАМЕТРОВ № 2
function ParSlider2_Callback(hObject, eventdata, handles)


% СЛАЙДЕР ПАРАМЕТРОВ № 3
function ParSlider3_Callback(hObject, eventdata, handles)


% СЛАЙДЕР ПАРАМЕТРОВ № 4
function ParSlider4_Callback(hObject, eventdata, handles)


% СЛАЙДЕР ПАРАМЕТРОВ № 5
function ParSlider5_Callback(hObject, eventdata, handles)


% СЛАЙДЕР ПАРАМЕТРОВ № 6
function ParSlider6_Callback(hObject, eventdata, handles)


% СЛАЙДЕР ПАРАМЕТРОВ № 7
function ParSlider7_Callback(hObject, eventdata, handles)


% СЛАЙДЕР ПАРАМЕТРОВ № 8
function ParSlider8_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% СПИСКИ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% СПИСОК СТАТИСТИКИ ПО ИЗОБРАЖЕНИЮ
function StatisticsList_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%% ТЕКСТОВЫЕ ПОЛЯ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function ROIx0_Callback(hObject, eventdata, handles)


function ROIy0_Callback(hObject, eventdata, handles)


function ROIx1_Callback(hObject, eventdata, handles)


function ROIy1_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%% ЧЕК-БОКСЫ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function ParCheckBox1_Callback(hObject, eventdata, handles)


function ParCheckBox2_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ФУНКЦИИ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ПРОПИСЫВАЕТ СТРОЧКУ С КАДРОМ И ТЕКУЩИМ ВРЕМЕНЕМ ВИДЕО
function ShowTimeAndFrame(handles, frame, min, sec)

if sec == 60            % делаем 59 сек крайними
    sec = 0;
    min = min + 1;
end

% тут вставить sprintf
handles.VideoInfo.String = ...
    [{[num2str(frame) ' кадр']}; {[num2str(min) ':' num2str(sec)]}];









