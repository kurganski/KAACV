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

% не хватает отображений предобраток (текущих картинок, а не только оригинала)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% МЕНЮ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% "ОТКРЫТЬ ФАЙЛ"
function OpenMenu_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%% ПРОВЕРКИ

if isempty(handles)       % значит неумный человек запустил fig вместо m  
    
    questdlg({  'Вы запустили файл с расширением *.fig вместо расширения *.m.';...
                'Нажмите "OK", и все будет хорошо';
                'You have started a file with expansion *.fig instead of *.m.';
                'Press "OK" to make it OK'},...
                'KAACV','OK','modal');
       
    close(gcf);
    run('KAACV.m');
    return;
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
    
    UserFile.Data = zeros(size(readFrame(VideoObject)));  % размер кадра
    
    FrameNumber = 1;                                % счетчик кадров
    NumOfFrames = round(VideoObject.Duration * VideoObject.FrameRate);
    
    if rus     % язык
        Wait = waitbar(0,'Загрузка видео','WindowStyle','modal');
    else
        Wait = waitbar(0,'Loading','WindowStyle','modal');
    end

    while hasFrame(VideoObject)                         % пока есть кадр
        UserFile(FrameNumber).Data = readFrame(VideoObject); % кидаем в структуру
        FrameNumber = FrameNumber+1;                         
        waitbar(FrameNumber / NumOfFrames, Wait);            % рисуем загрузку
    end    
    
    delete(Wait);       % удаляем окно загрузки 
    
    % записываем свойства видео
    UserFile(1).FrameRate = VideoObject.FrameRate;  
    
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

% открываем/блокируем все нужные элементы
if size(UserFile,2) > 1     % если видео
    
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
    
else                % если картинка
    
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

% для всех
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

% настравием ось под размеры видоса и если можно растянуть - видим кнопку
if SetAxesSize(handles.FileAxes,size(UserFile(1).Data,1),size(UserFile(1).Data,2))
    handles.ZoomButton.Enable = 'on';
else
    handles.ZoomButton.Enable = 'off';
end

% создаю объект-картинку, а слайдером потом лишь обновляем CData
image(  UserFile(1).Data,...
        'Parent',handles.FileAxes,...
        'Tag', 'FrameObj');

% установка меню обработок    
MethodMenuSetting(handles.MethodMenu, size(UserFile,2) > 1, rus);

handles.PlayPauseButton.Value = 0;      % ставим на паузу

handles.ApplyButton.Value = 0;              % отжимаем кнопку обработки
handles.ApplyButton.String = 'Применить';   % поменяем надпись на ней

handles.FrameSlider.Value = 1;          % выставляю номер первого кадра  
FrameSlider_Callback(hObject, eventdata, handles);  % обновляю № кадра и сек

% запускаем меню с обработкой  
MethodMenu_Callback(hObject, eventdata, handles);


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


% ПРОСМОТР ROI
function ROIShowMenu_Callback(hObject, eventdata, handles)

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');

% вытаскиваем кадр
Image = UserFile(handles.FrameSlider.Value).Data;

X0 = round(str2double(handles.ROIx0.String));
X1 = round(str2double(handles.ROIx1.String));
Y0 = round(str2double(handles.ROIy0.String));
Y1 = round(str2double(handles.ROIy1.String));
    
Image = Image(Y0:Y1,X0:X1,:);

% пробуем открыть так или так
try
    fig = imtool(Image);              % для матлаб-версии
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
% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');

% переименовываем элементы
if handles.ApplyButton.Value == 1
    handles.ApplyButton.String = 'Применяется';
else
    handles.ApplyButton.String = 'Применить';
end
handles.PatternOpenButton.String = 'Открыть';

handles.ParametersPanel.Title = 'Параметры';

handles.FileMenu.Label = 'Файл';
handles.OpenMenu.Label = 'Открыть';
handles.ShowFrameMenu.Label = 'Показать кадр/изображение';
handles.ROIShowMenu.Label = 'Показать ROI';
handles.SaveFrameMenu.Label = 'Сохранить кадр';
handles.ShowPatternImageMenu.Label = 'Показать шаблон';
handles.SettingsMenu.Label = 'Настройки';
handles.LanguageMenu.Label = 'Язык';

% handles..Label = '';
% handles..Label = '';
% handles..Label = '';

% переименовываем подсказки

% handles..TooltipString = '';

% обновляем отклики
MethodMenuSetting(handles.MethodMenu, size(UserFile,2) > 1, 1);    % меняем список методов
MethodMenu_Callback(hObject, eventdata, handles);   % обновляем панель параметров


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

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');

% переименовываем элементы
if handles.ApplyButton.Value == 1
    handles.ApplyButton.String = 'Applying';
else
    handles.ApplyButton.String = 'Apply';
end
handles.PatternOpenButton.String = 'Open';

handles.ParametersPanel.Title = 'Parameters';

handles.FileMenu.Label = 'File';
handles.OpenMenu.Label = 'Open';
handles.ShowFrameMenu.Label = 'Show frame/image';
handles.ROIShowMenu.Label = 'Show ROI';
handles.SaveFrameMenu.Label = 'Save frame';
handles.ShowPatternImageMenu.Label = 'Show pattern';
handles.SettingsMenu.Label = 'Settings';
handles.LanguageMenu.Label = 'Language';

% handles..Label = '';
% handles..Label = '';
% handles..Label = '';

% переименовываем подсказки

% handles..TooltipString = '';

% обновляем отклики
MethodMenuSetting(handles.MethodMenu, size(UserFile,2) > 1, 0);    % меняем список методов
MethodMenu_Callback(hObject, eventdata, handles);   % обновляем панель параметров


%
%
% ВЫБОР МЕТОДА ОБРАБОТКИ
function MethodMenu_Callback(hObject, eventdata, handles)

% прячем все элементы и блокируем некоторые меню
set(handles.ParametersPanel.Children,'Visible','off');

% меню просмотр области интереса
handles.ROIShowMenu.Enable = 'off';

% устанавливаем все выбранные строки менюшек в 1
handles.ParMenu1.Value = 1;
handles.ParMenu2.Value = 1;
handles.ParMenu3.Value = 1;
handles.ParMenu4.Value = 1;

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');
width = size(UserFile(1).Data,2);
heigth = size(UserFile(1).Data,1);
Image = UserFile(round( size(UserFile,2)/2 )).Data;

% если русский язык выбран, rus = 1
rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'Распознавание текста','Optical character recognition'}
                                    
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
        
        % Порог распознавания
        handles.ParSlider1.Min              = 0.01;
        handles.ParSlider1.Max              = 1;
        handles.ParSlider1.SliderStep       = [0.01/0.99 0.1/0.99];
        handles.ParSlider1.Value            = 0.5;
        handles.ParSliderValueText1.String  = '0.5';   
        
        if rus 
            handles.ParMenuText1.String = 'Расположение текста';
            handles.ParMenu1.String = { 'Авто';
                                        'Блок';
                                        'Линия';
                                        'Слово'};

            handles.ParMenuText2.String = 'Распознаваемый язык';
            
            try             % проверяем наличие установленного аддона
                ocr(ones(10),'Language','Russian');  % если сработает, то стоит 

                handles.ParMenu2.String = { 'Английский';...
                                            'Русский';...
                                            'Украинский';...
                                            'Французский';...
                                            'Немецкий';...
                                            'Испанский';...
                                            'Финский';...
                                            'Китайский (традиционный)';...
                                            'Японский'}; 
            catch                                    
                handles.ParMenu2.String = 'Английский'; 
            end

            handles.ParSliderText1.String = 'Порог распознавания:';             
            handles.ROIButton.TooltipString = ...
                ['Область интереса: нажмите, чтобы выбрать на кадре/изображении область интереса, '...
                'которая будет подвергнута обработке'];   
            
        else
            handles.ParMenuText1.String = 'Text Layout';
            handles.ParMenu1.String = { 'Auto';
                                        'Block';
                                        'Line';
                                        'Word'};

            handles.ParMenuText2.String = 'Recognition language';

            try             % проверяем наличие установленного аддона
                ocr(ones(10),'Language','Russian');  % если сработает, то стоит 

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
        
    case {'Чтение штрих-кода','Barcode reading'} 
        
    case {'Поиск областей с текстом','Text region detection'}  
        
    case {'Анализ пятен','Blob analysis'}   
        
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
        
        if ~all(all(Image == 0 | Image == 1))    % если не ч/б
            
            handles.ParSlider4.Visible = 'on';
            handles.ParSliderText4.Visible = 'on';
            handles.ParSliderValueText4.Visible = 'on';
            
            handles.ParMenu2.Visible = 'on';
            handles.ParMenuText2.Visible = 'on';
            
            handles.ParMenu3.Visible = 'on';
            handles.ParMenuText3.Visible = 'on';            
        
        end
        
        handles.ParCheckBox1.Visible = 'on';
        
        % Максимальное количество пятен
        handles.ParSlider1.Min              = 1;
        handles.ParSlider1.Max              = width * heigth;
        handles.ParSlider1.SliderStep       = [1/(width*heigth-1) 10/(width*heigth-1)];
        handles.ParSlider1.Value            = round(width * heigth / 2);
        handles.ParSliderValueText1.String  = num2str(round(width * heigth / 2));         
        
        % Минимальная область пятна
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
        
        % Максимальная область пятна
        handles.ParSlider3.Min              = 1;
        handles.ParSlider3.Max              = width*heigth;
        handles.ParSlider3.SliderStep       = [1/(width*heigth-1) 10/(width*heigth-1)];
        handles.ParSlider3.Value            = round(width * heigth / 2);
        handles.ParSliderValueText3.String  = num2str(round(width * heigth / 2)); 
        
        
        % Чувствительность
        handles.ParSlider4.Min              = 0;
        handles.ParSlider4.Max              = 1;
        handles.ParSlider4.SliderStep       = [0.01 0.1];
        handles.ParSlider4.Value            = 0.5;
        handles.ParSliderValueText4.String  = '0.5';       
        
        % Связность
        handles.ParMenu1.String = { '4';'8';};
        
        handles.ParCheckBox1.Value = 1;        
        
        if rus            
            handles.ParMenuText1.String = 'Связность';
            handles.ParMenuText2.String = 'Тип бинаризации';
            handles.ParMenu2.String = { 'Адаптивная';'Глобальная (Оцу)';'Глобальная';};
            handles.ParMenuText3.String = 'Фон';
            handles.ParMenu3.String = { 'Темный';'Яркий';};
            handles.ParSliderText1.String = 'Максимальное количество пятен:'; 
            handles.ParSliderText2.String = 'Минимальная область пятна: ';
            handles.ParSliderText3.String = 'Максимальная область пятна: '; 
            handles.ParSliderText4.String = 'Чувствительность / Порог: '; 
            handles.ParCheckBox1.String = 'Граничные пятна';   
            
            handles.ParCheckBox1.TooltipString = 'Включая граничные пятна';
            handles.ParSlider4.TooltipString = 'Чувствительность адаптивной бинаризации';
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
        
        
        
    case {'Распознавание лиц','Face detection'}
        
    case {'Распознавание людей','People detection'}
        
    case {'Распознавание объектов','Object detection'}
        
    case {'Создание 3D-изображения','3-D image creation'}
        
    case {'Обработка видео','Video processing'}
        
    case {'Создание панорамы','Panorama creation'}
        
    case {'Распознавание движения','Motion detection'}
        
    otherwise
        assert(0, 'Ошибка в обращении к методам обработки');
        
end

%
%
%

% ВЫБОР ОТОБРАЖАЕМОГО ВИДЕО
function VideoMenu_Callback(hObject, eventdata, handles)

% считываю все изображения-результаты обработки
ProcessedImages = getappdata(handles.FileAxes,'ProcessedImages');

assert(~isempty(ProcessedImages),'В ось не вставили объект с этапами обработки');

assert(size(ProcessedImages,2) == size(handles.VideoMenu.String,1),...
        'Число строк не соответствует числу изображений');
    
% если номер выбранной строки превышает кол-во строк    
if handles.VideoMenu.Value > size(handles.VideoMenu.String,1)
    handles.VideoMenu.Value = 1;
end

% выбираю по требованию пользователя картинку
ImageToView = ProcessedImages(handles.VideoMenu.Value).Images;
FrameObj = findobj('Parent',handles.FileAxes, 'Tag','FrameObj');

% если одноканальное - отображаем, добавляя одинаковых 2 канала 
if size(ImageToView,3) ~= size(FrameObj.CData,3)
    ImageToView(:,:,2) = ImageToView(:,:,1);
    ImageToView(:,:,3) = ImageToView(:,:,1);
end

set(FrameObj, 'CData',im2double(ImageToView));
handles.FileAxes.Visible = 'off';


% МЕНЮ № 1 ПАРАМЕТРОВ 
function ParMenu1_Callback(hObject, eventdata, handles)


% МЕНЮ № 2 ПАРАМЕТРОВ 
function ParMenu2_Callback(hObject, eventdata, handles)

% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'Анализ пятен','Blob analysis'} 
        
        switch handles.ParMenu2.Value
            
            case 1  % адаптивный порог
                
                handles.ParSlider4.Visible = 'on';
                handles.ParSliderText4.Visible = 'on';
                handles.ParSliderValueText4.Visible = 'on';
                
                handles.ParMenu3.Visible = 'on';
                handles.ParMenuText3.Visible = 'on';
            
            case 2  % глобальный порог (Оцу)
                
                handles.ParSlider4.Visible = 'off';
                handles.ParSliderText4.Visible = 'off';
                handles.ParSliderValueText4.Visible = 'off';
                
                handles.ParMenu3.Visible = 'off';
                handles.ParMenuText3.Visible = 'off';
            
            case 3  % глобальный порог
                
                handles.ParSlider4.Visible = 'on';
                handles.ParSliderText4.Visible = 'on';
                handles.ParSliderValueText4.Visible = 'on';
                
                handles.ParMenu3.Visible = 'off';
                handles.ParMenuText3.Visible = 'off';
        end
    
end


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
        
        tic;
        
        handles.FrameSlider.Value = FrameNumber;
        FrameSlider_Callback(hObject, eventdata, handles);
        
        drawnow;        % отрисовка вычисленного
        
        if toc < (1/FrameRate)  % если успели раньше, чем пауза меж кадрами
            pause(1/FrameRate); % выжидаем ее 
        end
        
        
        % если прервали на паузу, тогда выходим, поменяв картинку кнопки
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


%
%
% ПРИМЕНИТЬ
function ApplyButton_Callback(hObject, eventdata, handles)

% считываем текущее изображение 
UserFile = getappdata(handles.FileAxes,'UserFile');
Image = UserFile(handles.FrameSlider.Value).Data;
rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% показываем, что процесс применения для видео длителен: при нажатии
if size(UserFile,2) > 1
    
    if handles.ApplyButton.Value == 1
        
        if rus
            handles.ApplyButton.String = 'Применяется';
        else
            handles.ApplyButton.String = 'Applying';
        end
        
    else        % если отжали кнопку - не нужно обрабатывать
        
        if rus
            handles.ApplyButton.String = 'Применить';
        else
            handles.ApplyButton.String = 'Apply';
        end
        
        return;
        
    end
    
else  % для картинок
    
    handles.ApplyButton.Value = 0;  % снимаем нажатое состояние 
    
end

% создаю обязательную структуру для харнения этапов обработки изображений
% заполняю меню отображения (над списком которое)
ProcessedImages = struct('Images',im2double(Image));    % запоминаю оригинал
if rus
    StringOfImages = {'Оригинал'};
else
    StringOfImages = {'Original image'}; 
end


% удаляем старые элементы
delete(findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b'));
handles.StatisticsList.String = '';

% чтобы не вылетал лист - ставим выделение 1й строки
handles.StatisticsList.Value = 1;


% считываем знеачения всех полей параметров
X0 = round(str2double(handles.ROIx0.String));
X1 = round(str2double(handles.ROIx1.String));
Y0 = round(str2double(handles.ROIy0.String));
Y1 = round(str2double(handles.ROIy1.String));

Slider1Value = handles.ParSlider1.Value;
Slider2Value = handles.ParSlider2.Value;
Slider3Value = handles.ParSlider3.Value;
Slider4Value = handles.ParSlider4.Value;
Slider5Value = handles.ParSlider5.Value;
Slider6Value = handles.ParSlider6.Value;
Slider7Value = handles.ParSlider7.Value;
Slider8Value = handles.ParSlider8.Value;

Menu1Value = handles.ParMenu1.Value;
Menu2Value = handles.ParMenu2.Value;
Menu3Value = handles.ParMenu3.Value;
Menu4Value = handles.ParMenu4.Value;

CheckBox1Value = handles.ParCheckBox1.Value;
CheckBox2Value = handles.ParCheckBox2.Value;

Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'Распознавание текста','Optical character recognition'}
        
        
        switch Menu1Value       % расположение текста
            
            case 1
                layout = 'Auto';
            case 2
                layout = 'Block';
            case 3
                layout = 'Line';
            case 4
                layout = 'Word';
        end
        
        switch Menu2Value       % язык распознавания
            
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
                
        boxes = results.WordBoundingBoxes;                          % рамки 
        boxes = boxes(results.WordConfidences > Slider1Value,:);    % убираем слабые
        boxes(:,1) = boxes(:,1) + X0;
        boxes(:,2) = boxes(:,2) + Y0;
        
        words = results.Words;                              % найденные слова
        words = words(results.WordConfidences > Slider1Value);
        
        if isempty(words)   % если нет результатов
            
            if rus
                words = 'нет результатов';
            else
                words = 'no results';
            end
            
        end
        
        handles.StatisticsList.String = words;              % вставляем в поле
        setappdata(handles.StatisticsList,'boxes',boxes);   % сохраняем рамки
                
        StatisticsList_Callback(hObject, eventdata, handles);   % вызов прорисовки
        
    case {'Чтение штрих-кода','Barcode reading'} 
        
    case {'Поиск областей с текстом','Text region detection'}  
        
    case {'Анализ пятен','Blob analysis'}         
        
        Conn = Menu1Value * 4;                      % связность
        BorderBlobs = ~ CheckBox1Value;             % вкл/искл гранич пятна        
        
        switch Menu3Value   % выбор типа порога для ч/б        
            case 1      % глобальный (Оцу)
                Foreground = 'bright';                
            case 2      % адаптивный
                Foreground = 'dark';                
        end            
        
        if size(Image,3) > 1            % если 3 канала - делаем 1
            Image = rgb2gray(Image);
        end
        
        if ~all(all(Image == 0 | Image == 1))    % если не ч/б
            
            switch Menu2Value   % выбор типа порога для ч/б
                
                case 1      % адаптивная                    
                    Image = imbinarize( Image,'adaptive',...
                                        'Sensitivity',Slider4Value,...
                                        'ForegroundPolarity',Foreground);
                                    
                case 2      % глобальный (Оцу)                    
                    Image = imbinarize(Image);
                    
                case 3      % глобальная                    
                    Image = imbinarize(Image,Slider4Value);
                    
            end
            
            % запоминаю изображения            
            ProcessedImages(end+1).Images = im2double(Image);
            
            if rus
                StringOfImages{end+1} = {'Результат бинаризации'};
            else
                StringOfImages{end+1} = {'Binarization result'};
            end
        end
        
        % задаем свойства объекта BlobAnalysis
        hBlob = vision.BlobAnalysis;
        hBlob.AreaOutputPort = true;
        hBlob.CentroidOutputPort = true;
        hBlob.BoundingBoxOutputPort = false;
        
        hBlob.PerimeterOutputPort = true;
        hBlob.LabelMatrixOutputPort = true;
        hBlob.Connectivity = Conn;
        hBlob.MaximumCount = Slider1Value;
        hBlob.MinimumBlobArea = Slider2Value;
        hBlob.MaximumBlobArea = Slider3Value;
        hBlob.ExcludeBorderBlobs = BorderBlobs;
        
        % получаем площадь, центр, периметр пятен
        [AREA,CENTEROID,PERIMETER,LABEL] = step(hBlob, logical(Image)); 
        
        CENTEROID = round(CENTEROID);
        PERIMETER = round(PERIMETER);
                
        % создаем список пятен
        BlobList = cell(1,size(AREA,1));
        
        for x = 1:size(AREA,1)
            if rus
                BlobList{x} = ['Пятно № ' num2str(x) ...
                            ': площадь / периметр = ' num2str(AREA(x))...
                            ' / ' num2str(PERIMETER(x)) ' (пикс.)']; 
            else
                BlobList{x} = ['Blob № ' num2str(x) ...
                            ': area / perimeter = ' num2str(AREA(x))...
                            ' / ' num2str(PERIMETER(x)) ' (pix.)']; 
            end
        end   
        
        if isempty(AREA)        % если не нашли пятен - пишем
            if rus
                BlobList = 'нет результатов';
            else
                BlobList = 'no results';
            end
        end
        
        % запоминаю изображение полутоновое с крестами в центрах пятен
        ProcessedImages(end+1).Images = ...
            insertMarker(im2double(Image), CENTEROID, 'Color', 'blue');
            
        if rus
            StringOfImages{end+1} = {'Обнаруженные пятна на бинарном изображении'};
        else
            StringOfImages{end+1} = {'Recognized blobs on binary image'};
        end
        
        % запоминаю изображение исходное с крестами в центрах пятен
        ProcessedImages(end+1).Images = ...
            insertMarker(ProcessedImages(1).Images, CENTEROID, 'Color', 'blue');
        
        if rus
            StringOfImages{end+1} = {'Обнаруженные пятна на оригинале'};
        else
            StringOfImages{end+1} = {'Recognized blobs on original image'};
        end
            
        handles.StatisticsList.String = BlobList;           % вставляем в поле
        setappdata(handles.StatisticsList,'LABEL',LABEL);   % сохраняем данные
                
        StatisticsList_Callback(hObject, eventdata, handles);   % вызов прорисовки  
        
        
    case {'Распознавание лиц','Face detection'}
        
    case {'Распознавание людей','People detection'}
        
    case {'Распознавание объектов','Object detection'}
        
    case {'Создание 3D-изображения','3-D image creation'}
        
    case {'Обработка видео','Video processing'}
        
    case {'Создание панорамы','Panorama creation'}
        
    case {'Распознавание движения','Motion detection'}
        
    otherwise
        assert(0, 'Ошибка в обращении к методам обработки');
        
end

% сохраняю картинки с обработки
setappdata(handles.FileAxes,'ProcessedImages',ProcessedImages);  

% вставляем сформированные строки
handles.VideoMenu.String = string(StringOfImages');  

% если результат обработки - не новое изображение, тогда прячем
if size(StringOfImages,2) == 1
    handles.VideoMenu.Visible = 'off';
else
    handles.VideoMenu.Visible = 'on';
end

% если список пуст - прячем
%(когда при обработке не найден результат, то так и прописывается)
if strcmp(handles.StatisticsList.String,'')
    handles.StatisticsList.Visible = 'off';
else
    handles.StatisticsList.Visible = 'on';
end

%%%%%%%%%%%%%%%%%%%%%%% вставляем в оси картинку
VideoMenu_Callback(hObject, eventdata, handles);


%
%
%

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
function ROIButton_Callback(hObject, ~, handles)

% удаляем рамку в оси
delete(findobj('Parent',handles.FileAxes,'LineStyle','--'));

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');
w = size(UserFile(1).Data,2);
h = size(UserFile(1).Data,1);

% если надаж на кнопку, значит нарисуем прямоугольник
if hObject == handles.ROIButton         
    
    ROI =  imrect(handles.FileAxes);    % даем пользователю выбрать
    coords = round(getPosition(ROI));   % считываем выбранные координаты
    delete(ROI);                        % удаляем созданный интерактивный объект
    
    coords(3) = coords(3) + coords(1);  % получаем координаты x1 и y1
    coords(4) = coords(4) + coords(2);
    
    % проверяем координаты
    coords = LimitCheck(coords,...
                [1 1 w h],...
                [false false true true]);
    
    handles.ROIx0.String = num2str(coords(1));    
    handles.ROIy0.String = num2str(coords(2));    
    handles.ROIx1.String = num2str(coords(3));    
    handles.ROIy1.String = num2str(coords(4)); 
    
    handles.ROIx0.Value = coords(1);
    handles.ROIy0.Value = coords(2);
    handles.ROIx1.Value = coords(3);
    handles.ROIy1.Value = coords(4);   
    
    coords(3) = coords(3) - coords(1);  % прпеобразуем координаты x1 и y1
    coords(4) = coords(4) - coords(2);  % в длину и ширину
    
    rectangle(  'Position',coords,...
                'Parent',handles.FileAxes,...
                'EdgeColor','r',...
                'LineStyle','--',...
                'LineWidth',2);     
    
else    % иначе он поменял координату в полях
   
    X0 = round(str2double(handles.ROIx0.String));
    X1 = round(str2double(handles.ROIx1.String));
    Y0 = round(str2double(handles.ROIy0.String));
    Y1 = round(str2double(handles.ROIy1.String));
    
    rectangle(  'Position',[X0 Y0 X1-X0 Y1-Y0],...
                'Parent',handles.FileAxes,...
                'EdgeColor','r',...
                'LineStyle','--',...
                'LineWidth',2);
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
handles.FrameSlider.Value = FrameNumber;        % запоминаем уточненное значение в слайдере


% если "применяется" обработка
if handles.ApplyButton.Value == 1
    
    ApplyButton_Callback(hObject, eventdata, handles);        
else
    % обновили CData, не создавая новый объект
    set(findobj('Parent',handles.FileAxes,'Tag', 'FrameObj'),...
        'CData',UserFile(FrameNumber).Data);
    
    handles.FileAxes.Visible = 'off';    
    % удаляем старые элементы обработки в оси
    delete(findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b'));
end

% прописываем кадр и время только для видео
if size(UserFile,2) > 1
    ShowTimeAndFrame(handles, UserFile(1).FrameRate, FrameNumber);         
end


% СЛАЙДЕР ПАРАМЕТРОВ № 1
function ParSlider1_Callback(hObject, eventdata, handles)

Value = handles.ParSlider1.Value;

% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'Распознавание текста','Optical character recognition'}
        Value = round(Value*100)/100;
        
    case {'Анализ пятен','Blob analysis'}   
        Value = round(Value);
end

handles.ParSlider1.Value = Value;
handles.ParSliderValueText1.String = num2str(Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 2
function ParSlider2_Callback(hObject, eventdata, handles)

Value = handles.ParSlider2.Value;

% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method        
    
    case {'Анализ пятен','Blob analysis'}   
        Value = round(Value);
end

handles.ParSlider2.Value = Value;
handles.ParSliderValueText2.String = num2str(Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 3
function ParSlider3_Callback(hObject, eventdata, handles)

Value = handles.ParSlider3.Value;

% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
    case {'Анализ пятен','Blob analysis'}   
        Value = round(Value);
end

handles.ParSlider3.Value = Value;
handles.ParSliderValueText3.String = num2str(Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 4
function ParSlider4_Callback(hObject, eventdata, handles)

Value = handles.ParSlider4.Value;
% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
    case {'Анализ пятен','Blob analysis'}   
        Value = round(Value*100)/100;
end

handles.ParSlider4.Value = Value;
handles.ParSliderValueText4.String = num2str(Value);


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

Value = handles.StatisticsList.Value;

% находим отрисованную фигуру
GraphObject = findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b');

% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'Распознавание текста','Optical character recognition'}        
        
        BoxesCoords = getappdata(handles.StatisticsList,'boxes');
        
        % если нет объекта, тогда создаем
        if isempty(GraphObject)
        
            if ~isempty(BoxesCoords)
                rectangle(  'Position',BoxesCoords(Value,:),...
                    'Parent',handles.FileAxes,...
                    'EdgeColor','b',...
                    'LineStyle','-.',...
                    'LineWidth',2);
            end            
        else        % иначе обновляем данные
            
            set(GraphObject, 'Position', BoxesCoords(Value,:));
            
        end
        
    case {'Анализ пятен','Blob analysis'}
        
        LABEL = getappdata(handles.StatisticsList,'LABEL');
        
        % если нет объекта, тогда создаем
        if isempty(GraphObject)
        
            if ~isempty(LABEL)
                [y,x] = find(LABEL == Value);
                
                patch(x,y,'b',...
                    'Parent',handles.FileAxes,...
                    'EdgeColor','b',...
                    'LineStyle','-.',...
                    'LineWidth',2);
            end
        else              % иначе обновляем данные      
            [y,x] = find(LABEL == Value);
            set(GraphObject, 'XData',x,'YData',y);
        end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%% ТЕКСТОВЫЕ ПОЛЯ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ОТКЛИКИ ПОЛЕЙ ОБЛАСТИ ИНТЕРЕСА
function ROIedit_Callback(hObject, eventdata, handles)

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');

Value = str2double(get(hObject,'String'));  % считал значение вызываемого поля 

if isnan(Value)                             % если не число - ошибка
    
    if strcmp(handles.RussianLanguageMenu.Checked,'on')
        errordlg('Введите в строку числовое значение','KAACV');
    else
        errordlg('Use digits only in this field','KAACV');
    end
    
    set(gcf,'WindowStyle', 'modal');
    
    set(hObject,'String',num2str(get(hObject,'Value')));
    return;
end

Value = round(Value);               % округлим

% находим максимум и минимум для изменяемой величины
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

if Value < MinValue     % при выходе за пределы присваиваем предельное значение
    Value = MinValue;
    
elseif Value > MaxValue
    Value = MaxValue;
end

set(hObject,'String',num2str(Value),'Value',Value);
ROIButton_Callback(hObject, eventdata, handles);


% ОТКЛИКИ ПОЛЕЙ ЗНАЧЕНИЙ СЛАЙДЕРОВ
function SliderEdit_Callback(hObject, eventdata, handles)

Value = str2double(get(hObject,'String'));  % считал значение вызываемого поля

EditTag = strsplit(get(hObject,'Tag'),'ValueText');     % получаем имя поля
SliderTag = [EditTag{1} EditTag{2}];                    % вырезаем имя ответственного слайдера

if isnan(Value)                             % если не число - ошибка
    
    if strcmp(handles.RussianLanguageMenu.Checked,'on')
        errordlg('Введите в строку числовое значение','KAACV');
    else
        errordlg('Use digits only in this field','KAACV');
    end
    
    set(gcf,'WindowStyle', 'modal');
    
    set(hObject,'String',num2str(get(eval(['handles.' SliderTag]),'Value')));
    return;
end

% считываем параметры слайдера
MaxValue = get(eval(['handles.' SliderTag]),'Max');
MinValue = get(eval(['handles.' SliderTag]),'Min');
SliderStep = get(eval(['handles.' SliderTag]),'SliderStep');

Step = SliderStep(1) * (MaxValue - MinValue);   % шаг для округления
Value = round(Value * 1/Step) * Step;         % округлил соответствующе слайдеру 

if Value < MinValue     % при выходе за пределы присваиваем предельное значение
    Value = MinValue;
    
elseif Value > MaxValue
    Value = MaxValue;
end

set(hObject,'String',num2str(Value));           % прописываю значение в поле
set(eval(['handles.' SliderTag]),'Value',Value);% и слайдер

%%%%%%%%%%%%%%%%%%%%%%%%%%%% ЧЕК-БОКСЫ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function ParCheckBox1_Callback(hObject, eventdata, handles)

rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'Анализ пятен','Blob analysis'}
        
        if handles.ParCheckBox1.Value
            
            if  rus
                handles.ParCheckBox1.TooltipString = 'Включая граничные пятна';
            else
                handles.ParCheckBox1.TooltipString = 'Including border blobs';
            end
        else
            
            if rus
                handles.ParCheckBox1.TooltipString = 'Исключая граничные пятна';
            else
                handles.ParCheckBox1.TooltipString = 'Excluding border blobs';
            end
        end
end


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
        
else                    % если открыто изображение
    if rus              % на русском
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
    

% проверяет выход за предел
function value = LimitCheck(number,limit,upper)

assert(isnumeric([number limit]) && islogical(upper),...
                'Некорректные входные данные');
            
assert(length(number) == length(limit) && length(limit) == length(upper),...
                'Размерности входных данных не равны');

% number - проверяемое число
% limit - предел
% upper = true - предел сверху
% upper = false - предел снизу

value = number;

for x = 1:length(number)
    
    if upper(x)                % предел сверху
        if number(x) > limit(x)
            value(x) = limit(x);
        end
    else                    % предел снизу
        if number(x) < limit(x)
            value(x) = limit(x);
        end
    end
end
    
    
    
    
    
    
    


