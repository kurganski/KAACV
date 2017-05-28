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

% запоминаем начальные координаты осей
setappdata(handles.FileAxes,'InitPosition',handles.FileAxes.Position);

% вставляем картинки в кнопки
try
    handles.PlayPauseButton.CData = imread([cd '\Icons\Play.png']);
    handles.FrameBackButton.CData = imread([cd '\Icons\FrameBack.png']);
    handles.FrameForwardButton.CData = imread([cd '\Icons\FrameForward.png']);
    handles.ZoomButton.CData = imread([cd '\Icons\Zoom+.png']);
catch
end

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
       
% прячем все элементы панеи параметров метода обработки
set(handles.ParametersPanel.Children,'Visible','off');

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

% если русский язык выбран, будет 1
rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% выбираем файл для открытия
if rus
    
    [FileName, PathName] = uigetfile(...
        {'*.jpeg;*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        'Изображения (*.jpeg,*.jpg,*.tif,*.tiff,*.bmp,*.png)';...
        '*.avi;*,mj2;*.mpg;*.mp4;*.m4v;*.mov;*.wmv;*.ogg;*.asf;*.asx',...
        'Видео (*.avi,*.mj2,*.mpg,*.mp4,*.m4v,*.mov,*.wmv,*.ogg,*.asf,*.asx)';...
        '*.*', 'All Files(*.*)'},...
        'Выберите файл для обработки',...
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

if ~FileName        % Проверка, был ли выбран файл
    return;
end

% выделяем память
UserFile = struct('Data',[],'FrameRate',[]);   

try         % пробуем открыть как видеофайл
    
    VideoObject = VideoReader([PathName FileName]); % видеообъект
    VideoInfo = readFrame(VideoObject);             % читаем первый кадр
    
    UserFile.Data = zeros(size(VideoInfo));        % создаем размер для структуры
    
    FrameNumber = 1;                                      % счетчик кадров
    NumOfFrames = round(VideoObject.Duration * VideoObject.FrameRate);
    
    Wait = waitbar(0,'Загрузка видео','WindowStyle','modal');

    while hasFrame(VideoObject)                         % пока есть кадр
        UserFile(FrameNumber).Data = readFrame(VideoObject); % кидаем в структуру
        FrameNumber = FrameNumber+1;                                % счетчик +
        waitbar(FrameNumber / NumOfFrames, Wait);             % рисуем прогрузку
    end    
    
    delete(Wait);       % удаляем загрузки окно
    
    % записываем свойства видео
    UserFile(1).FrameRate = VideoObject.FrameRate;            
    
    handles.FrameSlider.Min = 1;
    handles.FrameSlider.Max = size(UserFile,2);
    handles.FrameSlider.SliderStep = ...
        [1/(size(UserFile,2)-1) 10/(size(UserFile,2)-1)];
    
    % открываем кнопки воспроизведения
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
    
catch       % не смогли открыть видеофайл
    
    if exist('Wait','var')          % если пользователь закрыл окно загрузки
        delete(Wait);               % удаляем окно
        return;                     % выходим отсюда
    end
    
    try     % пробуем открыть как изображение
        
        [Temp,colors] = imread([PathName FileName]);      
        
        if ~isempty(colors)                 % если индексированное -
            Temp = ind2rgb(Temp,colors);    % индексированное в RGB
        end  
        
        UserFile.Data = Temp;               % запиливаем картинку     
                
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
        
    catch    % оба варианты открытия провалились
        
        if rus     % язык
            h = errordlg('С файлом что-то не так. Откройте другой','KAACV');
        else
            h = errordlg('File is improper. Choose another file','KAACV');
        end
        
        set(h, 'WindowStyle', 'modal');
        return;        
    end
end

%%%%%%%%%%%%%%%%%%%%% после открытия

% записываю удачно открытый файл в данные оси
setappdata(handles.FileAxes,'UserFile',UserFile);

% устанавливаем слайдер кадров    
MethodMenu_Callback(hObject, eventdata, handles);

% открываем/разблокируем все нужные элементы
set([...
    handles.ParametersPanel;...
    handles.MethodMenu;...
    handles.ApplyButton;...
    handles.ZoomButton;...
    ],'Visible','on');

set([...
    handles.ShowFrameMenu;...
    ],'Enable','on');

% настравием ось под размеры видоса и если можно растянуть - видим кнопку
if SetAxesSize(handles.FileAxes,size(UserFile(1).Data,1),size(UserFile(1).Data,2))
    handles.ZoomButton.Visible = 'on';
else
    handles.ZoomButton.Visible = 'off';
end

% создаю объект-картинку, а слайдером потом лишь обновляем CData
image(  UserFile(1).Data,...
        'Parent',handles.FileAxes,...
        'Tag', 'FrameObj');

% установка меню обработок    
MethodMenuSetting(handles.MethodMenu, size(UserFile,2) > 1, rus);

handles.PlayPauseButton.Value = 0;      % ставим на паузу
handles.FrameSlider.Value = 1;          % выставляю на слайдере номер первого кадра   
FrameSlider_Callback(hObject, eventdata, handles);


% "ПОКАЗАТЬ КАДРА/ИЗОБРАЖЕНИЯ"
function ShowFrameMenu_Callback(hObject, eventdata, handles)

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');

% вытаскиваем кадр
Image = UserFile(handles.FrameSlider.Value).Data;

% пробуем открыть так или так
try
    imtool(Image);              % для матлаб-версии
catch
    OpenImageOutside(Image);    % для exe-версии
end


% "СОХРАНИТЬ КАДР"
function SaveFrameMenu_Callback(hObject, eventdata, handles)

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');

% вытаскиваем кадр
Image = UserFile(handles.FrameSlider.Value).Data;
FrameNumber = handles.FrameSlider.Value;

if strcmp(handles.RussianLanguageMenu.Checked,'on')      % по языку
    [FileName, PathName] = uiputfile(['кадр № ' num2str(FrameNumber) '.png'],'Сохранить кадр/изображение');
else
    [FileName, PathName] = uiputfile(['frame № ' num2str(FrameNumber) '.png'],'Save frame/image');
end

if FileName~=0
    imwrite(Image,[PathName FileName]);
end


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

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');
width = size(UserFile(1).Data,2);
heigth = size(UserFile(1).Data,1);

switch handles.MethodMenu.Value
    
    case 1      % Распознавание текста
        
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
        
        
    case 2      % Чтение штрих-кода
        
    case 3      % Поиск областей с текстом
        
    case 4      % Анализ пятен
        
    case 5      % Распознавание лиц
        
    case 6      % Распознавание людей
        
    case 7      % Распознавание объектов
        
    case 8      % Создание 3D-изображения
        
    case 9      % Обработка видео
        
    case 10     % Создание панорамы
        
    case 11     % Распознавание движения
        
end


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

% ЗДЕСЬ МЫ ОБНОВЛЯЕМ КАДР И ВЫЗЫВАЕМ СЛАЙДЕР, КОТОРЫЙ И ПОКАЖЕТ КАДР

% меняем картинку кнопки и блокируем соседей
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
    
    % считываем файл и частоту кадров
    UserFile = getappdata(handles.FileAxes,'UserFile'); 
    FrameRate = UserFile(1).FrameRate;
    
    % прогоняем кадры
    for FrameNumber = handles.FrameSlider.Value : handles.FrameSlider.Max
                
        handles.FrameSlider.Value = FrameNumber;
        FrameSlider_Callback(hObject, eventdata, handles);
        
        pause(1/FrameRate);
        
        % если прервали на паузу
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


% ПРЕДЫДУЩИЙ КАДР 
function FrameBackButton_Callback(hObject, eventdata, handles)

FrameNumber = handles.FrameSlider.Value - 1;  % считываем кадр

if FrameNumber < handles.FrameSlider.Min
    FrameNumber = handles.FrameSlider.Min;
end

handles.FrameSlider.Value = FrameNumber;
FrameSlider_Callback(hObject, eventdata, handles);


% СЛЕДУЮЩИЙ КАДР
function FrameForwardButton_Callback(hObject, eventdata, handles)

FrameNumber = handles.FrameSlider.Value + 1;  % считываем кадр

if FrameNumber > handles.FrameSlider.Max
    FrameNumber = handles.FrameSlider.Max;
end

handles.FrameSlider.Value = FrameNumber;
FrameSlider_Callback(hObject, eventdata, handles);


% ПРИМЕНИТЬ
function ApplyButton_Callback(hObject, eventdata, handles)

% считываем файл и частоту кадров
UserFile = getappdata(handles.FileAxes,'UserFile');
    
% показываем, что процесс применения длителен: при нажатии
if size(UserFile,2) > 1             % для видеофайла
    if handles.ApplyButton.Value == 1
        handles.ApplyButton.String = 'Применяется';
    else
        handles.ApplyButton.String = 'Применить';
    end
    
else
    handles.ApplyButton.Value = 0;  % снимаем нажатое состояние    
end


% УВЕЛИЧЕНИЕ РАЗМЕРА ВИДЕО ПОД РАЗМЕР ОСИ
function ZoomButton_Callback(hObject, eventdata, handles)

% считываем файл
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
    
    % считываем начальный размер, выделенный для оси
    AxesSize = getappdata(handles.FileAxes,'InitPosition');
    
    % выбираем минимум, на который можем растянуть габариты и считаем их
    height = size(UserFile(1).Data,1) / ...
        min(size(UserFile(1).Data,1)/AxesSize(4) , size(UserFile(1).Data,2)/AxesSize(3));
    
    width = size(UserFile(1).Data,2) / ...
        min(size(UserFile(1).Data,1)/AxesSize(4) , size(UserFile(1).Data,2)/AxesSize(3));
    
    SetAxesSize(handles.FileAxes, height, width);      
end


% ВЫБОР ОБЛАСТИ ИНТЕРЕСА
function ROIButton_Callback(hObject, eventdata, handles)

% если надаж на кнопку, значит нарисуем прямоугольник
if hObject == handles.ROIButton     
    
   h =  imrect(handles.FileAxes);
    
else    % иначе он поменял координату в полях
    
end


% ОТКРЫТЬ ШАБЛОН
function PatternOpenButton_Callback(hObject, eventdata, handles)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%% СЛАЙДЕРЫ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% СЛАЙДЕР КАДРОВ ВИДЕО
function FrameSlider_Callback(hObject, eventdata, handles)

% СЛАЙДЕР ЗАНИМАЕТСЯ ОБНОВЛЕНИЕМ ДАННЫХ ОБЪЕКТА-КАРТИНКИ В ОСИ !!!

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');

FrameNumber = round(handles.FrameSlider.Value); % считываем номер кадра

handles.FrameSlider.Value = FrameNumber;      % установка слайдера

% обновили CData, не создавая новый объект
set(findobj('Parent',handles.FileAxes,'Tag', 'FrameObj'),...
    'CData',UserFile(FrameNumber).Data);

handles.FileAxes.Visible = 'off';                                  

% прописываем кадр и время только для видео
if size(UserFile,2) > 1
    ShowTimeAndFrame(handles, UserFile(1).FrameRate, FrameNumber);         
end


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

% ПРОПИСЫВАЕТ СТРОЧКИ С КАДРОМ И ТЕКУЩИМ ВРЕМЕНЕМ ВИДЕО
function ShowTimeAndFrame(handles, FrameRate, FrameNumber)

% handles - массив указателей приложения
% FrameRate - скорость воспроизведения видео
% FrameNumber - номер текущего кадра

sec = mod(FrameNumber / FrameRate, 60);       % остаток в сек.
min = (FrameNumber / FrameRate - sec) / 60;   % мин.
sec = round(sec);
        
if sec == 60            % делаем 59 сек крайними
    sec = 0;
    min = min + 1;
end

handles.VideoTimeInfo.String = [sprintf('%02d',min) ':' sprintf('%02d',sec)];
handles.VideoFrameInfo.String = [num2str(FrameNumber) ' кадр'];


% НАСТРАИВАЕТ РАЗМЕР ОСИ ПОД ВИДЕО/ИЗОБРАЖЕНИЕ
function zoom = SetAxesSize(hObject, height, width)

% hObject - ось, в которую вставляем кадр/изорбажение
% height, width - габариты кадра/изорбажения
% zoom = 1 - можно еще растягивать кадр/изорбажение под ось
% zoom = 0 - некуда растягивать кадр/изорбажение под ось

zoom = true;        
    
% считываем начальный размер, выделенный для оси
AxesSize = getappdata(hObject,'InitPosition');  

% выясняем, ширина или высота страдает больше
% если не влезают в выделенную ось, меняем габариты по страдальцу

if max(width/AxesSize(3), height/AxesSize(4)) > 1
    
    zoom = false;   % нельзя
    width = width / max(width/AxesSize(3), height/AxesSize(4));
    height = height / max(width/AxesSize(3), height/AxesSize(4));
end
    
x = AxesSize(1) + round((AxesSize(3) - width)/2);
y = AxesSize(2) + round((AxesSize(4) - height)/2);

set(hObject, 'Position', [x y width height]);


% НАСТРАИВАЕТ СПИСОК МЕТОДОВ ОБРАБОТКИ
function MethodMenuSetting(MethodMenu, VideoOpened, rus)

% MethodMenu - настраиваемая менюшка
% VideoOpened - если открыто видео - тогда истина
% rus - если 1, тогда русский язык стоит

if VideoOpened          % для открытого видео-файла
    if rus              % на русском
        
        set(MethodMenu,'String',{...
            'Распознавание текста';...
            'Чтение штрих-кода';...
            'Поиск областей с текстом';...
            'Анализ пятен';...
            'Распознавание лиц';...
            'Распознавание людей';...
            'Распознавание объектов';...
            'Создание 3D-изображения';...
            'Обработка видео';...
            'Создание панорамы';...
            'Распознавание движения';...
            });       
        
    else                % на английском
        
    end
        
else                    % если открыто изображение
    
        set(MethodMenu,'String',{...
            'Распознавание текста';...
            'Чтение штрих-кода';...
            'Поиск областей с текстом';...
            'Анализ пятен';...
            'Распознавание лиц';...
            'Распознавание людей';...
            'Распознавание объектов';...
            'Создание 3D изображения';...
            });
end
    


