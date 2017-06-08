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
setappdata(handles.PatternAxes,'InitPosition',handles.PatternAxes.Position);

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
% исправить в kaaip brisk пределы (30 14000)
% там же поправить в бинаризации - брать 3 канала для rgb, а не 1
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

% кнопку зума в начальное положение
handles.ZoomButton.Value = 0;
ZoomButton_Callback(hObject, eventdata, handles);

handles.PlayPauseButton.Value = 0;      % ставим на паузу
PlayPauseButton_Callback(hObject, eventdata, handles);  % меняем картинку

handles.ApplyButton.Value = 0;              % отжимаем кнопку обработки
if rus
    handles.ApplyButton.String = 'Применить';   % поменяем надпись на ней
else
    handles.ApplyButton.String = 'Apply';   % поменяем надпись на ней
end

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
handles.PatternOpenButton.String = 'Открыть образец';

handles.ParametersPanel.Title = 'Параметры';

handles.FileMenu.Label = 'Файл';
handles.OpenMenu.Label = 'Открыть';
handles.ShowFrameMenu.Label = 'Показать кадр/изображение';
handles.ROIShowMenu.Label = 'Показать ROI';
handles.SaveFrameMenu.Label = 'Сохранить кадр';
handles.ShowPatternImageMenu.Label = 'Показать образец';
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

% меню просмотр области интереса прячем
handles.ROIShowMenu.Enable = 'off';
handles.ShowPatternImageMenu.Visible = 'off';
handles.PatternAxes.Visible = 'off';

% очищаем старые пользовательские данные
setappdata(handles.PatternAxes,'Pattern',[]);
delete([handles.PatternAxes.Children handles.PatternAxes.UserData]);

% устанавливаем все выбранные строки менюшек в 1
handles.ParMenu1.Value = 1;
handles.ParMenu2.Value = 1;
handles.ParMenu3.Value = 1;
handles.ParMenu4.Value = 1;

handles.ParCheckBox1.Value = 0;
handles.ParCheckBox2.Value = 0;

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');
width = size(UserFile(1).Data,2);
heigth = size(UserFile(1).Data,1);
Image = UserFile(round( size(UserFile,2)/2 )).Data;
MinWidthHeigth = min(width,heigth);
MaxWidthHeigth = max(width,heigth);

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
        
        % Порог сравнения
        handles.ParSlider5.Min              = 1;
        handles.ParSlider5.Max              = 100;
        handles.ParSlider5.SliderStep       = [1/99 10/99];
        handles.ParSlider5.Value            = 10;
        handles.ParSliderValueText5.String  = '10'; 
        
        % Порог отношения
        handles.ParSlider6.Min              = 0.01;
        handles.ParSlider6.Max              = 1;
        handles.ParSlider6.SliderStep       = [0.01/0.99 0.1/0.99];
        handles.ParSlider6.Value            = 0.1;
        handles.ParSliderValueText6.String  = '0.1';  
        
        % Максимальное число случайных испытаний
        handles.ParSlider7.Min              = 10;
        handles.ParSlider7.Max              = 100000;
        handles.ParSlider7.SliderStep       = [10/99999 100/99999];
        handles.ParSlider7.Value            = 1000;
        handles.ParSliderValueText7.String  = '1000';  
        
        % Уровень доверия
        handles.ParSlider8.Min              = 1;
        handles.ParSlider8.Max              = 99;
        handles.ParSlider8.SliderStep       = [1/98 10/98];
        handles.ParSlider8.Value            = 50;
        handles.ParSliderValueText8.String  = '50';  
        
        % Макс. расстояние между точкой и проекцией
        handles.ParSlider9.Min              = 1;
        handles.ParSlider9.Max              = MinWidthHeigth/4;
        handles.ParSlider9.SliderStep       = [1/(MinWidthHeigth/4 - 1) 10/(MinWidthHeigth/4 - 1)];
        handles.ParSlider9.Value            = 2;
        handles.ParSliderValueText9.String  = '2';  
        
        
        if rus
                                     
            handles.ParMenuText1.String = 'Тип преобразования';
            handles.ParMenu1.String = { 'Подобие';...
                                        'Аффинное';...
                                        'Проективное';...
                                        };
                                    
            handles.ParMenuText2.String = 'Метод сравнения';
            handles.ParMenu2.String = { 'Исчерпывающий';...
                                        'Приблизительный';...
                                        };
            
            handles.ParMenuText3.String = 'Детектор';
            handles.ParMenu3.String = { 'MSER';...
                                        'BRISK';...
                                        'FAST';...
                                        'Харриса';...
                                        'Минимального собственного значения';...
                                        'SURF (размер дескриптора 64)';...
                                        'SURF (размер дескриптора 128)';...
                                        };
            
            handles.ParSliderText5.String = 'Порог сравнения: '; 
            handles.ParSliderText6.String = 'Порог отношения: '; 
            handles.ParSliderText7.String = 'Максимальное число случайных испытаний: '; 
            handles.ParSliderText8.String = 'Уровень доверия: ';            
            handles.ParSliderText9.String = 'Макс. расстояние точка/проекция: '; 
            
            handles.ParCheckBox1.String = 'Исп. ориентацию';             
            handles.ParCheckBox2.String = 'Только уникальные';  
            handles.ParCheckBox2.TooltipString = 'Результат сравния - только уникальные ключевые точки';
            handles.ParSlider9.TooltipString = 'Макс. расстояние между точкой и проекцией';
            
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

Value = handles.ParMenu3.Value;

% если русский язык выбран, rus = 1
rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');
width = size(UserFile(1).Data,2);
heigth = size(UserFile(1).Data,1);
maxArea = max(width,heigth);
minArea = min(width,heigth);

% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    case {'Распознавание объектов','Object detection'}    
        
        % прячу все, открываю затем только нужные        
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
        
        % установка в дефолт
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
                
                % слайдеры будут менять свои пределы 
                % в зависимости от выбора пользователя,
                % чтобы исключить выход максимальной области за значенее
                % меньшее, чем выбор минимальной области и наоборот
                % поэтому Value должны быть равны пределам!!!
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
                    
                    handles.ParSliderText1.String = 'Максимальная вариация области:';
                    handles.ParSliderText2.String = 'Шаг порога:';
                    handles.ParSliderText3.String = 'Минимальная область:';
                    handles.ParSliderText4.String = 'Максимальная область:';
                    
                    handles.ParMenuText4.String = 'Метрика';
                    handles.ParMenu4.String = { 'Сумма модулей разности';...
                                                'Сумма квадратов разностей';...
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
                    
                    handles.ParSliderText1.String = 'Минимальный контрастность:';
                    handles.ParSliderText2.String = 'Минимальное качество:';
                    handles.ParSliderText3.String = 'Число октав:';
                    
                    handles.ParMenuText4.String = 'Метрика';
                    handles.ParMenu4.String = { 'Хэмминга';...
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
                    
                    handles.ParSliderText1.String = 'Минимальный контрастность:';
                    handles.ParSliderText2.String = 'Минимальное качество:';
                    
                    handles.ParMenuText4.String = 'Метрика';
                    handles.ParMenu4.String = { 'Хэмминга';...
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
                    
                    handles.ParSliderText3.String = 'Размер окна фильтра:';
                    handles.ParSliderText2.String = 'Минимальное качество:';
                    
                    handles.ParMenuText4.String = 'Метрика';
                    handles.ParMenu4.String = { 'Хэмминга';...
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
                    
                    handles.ParSliderText3.String = 'Размер окна фильтра:';
                    handles.ParSliderText2.String = 'Минимальное качество:';
                    
                    handles.ParMenuText4.String = 'Метрика';
                    handles.ParMenu4.String = { 'Хэмминга';...
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
                    
                    handles.ParSliderText2.String = 'Порог:';
                    handles.ParSliderText3.String = 'Число октав:';
                    handles.ParSliderText4.String = 'Число уровней масштаба:';
                    
                    handles.ParMenuText4.String = 'Метрика';
                    handles.ParMenu4.String = { 'Сумма модулей разности';...
                                                'Сумма квадратов разностей';...
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

Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'Распознавание текста','Optical character recognition'}
        
        
        thresh = handles.ParSlider1.Value;
        textlayout = handles.ParMenu1.Value;
        language = handles.ParMenu2.Value;
        
        switch textlayout       % расположение текста
            
            case 1
                layout = 'Auto';
            case 2
                layout = 'Block';
            case 3
                layout = 'Line';
            case 4
                layout = 'Word';
        end
        
        switch language       % язык распознавания
            
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
        boxes = boxes(results.WordConfidences > thresh,:);    % убираем слабые
        boxes(:,1) = boxes(:,1) + X0;
        boxes(:,2) = boxes(:,2) + Y0;
        
        words = results.Words;                              % найденные слова
        words = words(results.WordConfidences > thresh);
        
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
        
        Conn = handles.ParMenu1.Value * 4;              % связность
        BinarizationType = handles.ParMenu2.Value;      % тип бинаризации        
        ForegroundType = handles.ParMenu3.Value;        % тип фона
        
        BorderBlobs = ~ handles.ParCheckBox1.Value;     % вкл/искл гранич пятна  
        
        MaximumCount = handles.ParSlider1.Value;
        MinimumBlobArea = handles.ParSlider2.Value;
        MaximumBlobArea = handles.ParSlider3.Value;
        SensOrThersh = handles.ParSlider4.Value;
        
        switch ForegroundType   % выбор фона для адаптивной бинаризации       
            case 1      
                Foreground = 'bright';                
            case 2      
                Foreground = 'dark';                
        end            
        
        if size(Image,3) > 1            % если 3 канала - делаем 1
            Image = rgb2gray(Image);
        end
        
        if ~all(all(Image == 0 | Image == 1))    % если не ч/б
            
            switch BinarizationType   % выбор типа порога для ч/б
                
                case 1      % адаптивная                    
                    Image = imbinarize( Image,'adaptive',...
                                        'Sensitivity',SensOrThersh,...
                                        'ForegroundPolarity',Foreground);
                                    
                case 2      % глобальный (Оцу)                    
                    Image = imbinarize(Image);
                    
                case 3      % глобальная                    
                    Image = imbinarize(Image,SensOrThersh);
                    
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
        hBlob.MaximumCount = MaximumCount;
        hBlob.MinimumBlobArea = MinimumBlobArea;
        hBlob.MaximumBlobArea = MaximumBlobArea;
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
        
        % считываем образец
        Pattern = getappdata(handles.PatternAxes,'Pattern');
        
        % нужны полутоновые картинки
        if size(Pattern,3) == 3
            Pattern = rgb2gray(Pattern);
        end
        
        if size(Image,3) == 3
            Image = rgb2gray(Image);
            
            % запоминаю изображение полутоновое с крестами в центрах пятен
            ProcessedImages(end+1).Images = Image;
            if rus
                StringOfImages{end+1} = {'Полутоновое изображение'};
            else
                StringOfImages{end+1} = {'Grayscale image'};
            end
            
        end 
        
        % считываем показания слайдеров
        MatchThreshold = handles.ParSlider5.Value;
        MaxRatio = handles.ParSlider6.Value;
        MaxNumTrials = handles.ParSlider7.Value;
        Confidence = handles.ParSlider8.Value;
        MaxDistance = handles.ParSlider9.Value;
         
        switch handles.ParMenu1.Value       % тип преобразования
            
            case 1
                TransformationType = 'similarity';
            case 2
                TransformationType = 'affine';                
            case 3
                TransformationType = 'projective';  
            otherwise
                assert(0,'Что то пошло не так...Выбрали не существующую строчку меню');
        end
        
        switch handles.ParMenu2.Value            % Метод сравнения
            case 1
                Method = 'Exhaustive';
            case 2
                Method = 'Approximate';
            otherwise
                assert(0,'Что то пошло не так...Выбрали не существующую строчку меню');
        end
        
        switch handles.ParMenu4.Value       % метрика
            
            case 1
                Metric = 'SAD';                
            case 2
                Metric = 'SSD';
            otherwise
                assert(0,'Что то пошло не так...Выбрали не существующую строчку меню');
        end
        
        UpRight = handles.ParCheckBox1.Value;
        UseUnique = handles.ParCheckBox2.Value;
         
        % считываем тип детектора для ключевых точек и детектируем их
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
                assert(0,'Что то пошло не так...Выбрали не существующую строчку меню');
        end
        
        % извлекаем фичи образца и сцены
        % для surf отдельный вызов
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
        
        % запоминаю изображение полутоновое с крестами в центрах пятен
        ProcessedImages(end+1).Images = ...
            insertMarker(Image, ScenePoints, 'Color', 'blue');
        
        if rus
            StringOfImages{end+1} = {'Все найденные ключевые точки'};
        else
            StringOfImages{end+1} = {'All found keypoints'};
        end
        
        % сравниваем фичи, выделяя пары похожих
        % для бинарных точе выpов без метрики
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
        
        % запоминаю изображение полутоновое с крестами в центрах пятен
        ProcessedImages(end+1).Images = ...
            insertMarker(Image, ScenePoints(Pairs(:,2),:), 'Color', 'blue');
        
        if rus
            StringOfImages{end+1} = {'Совпадающие ключевые точки'};
        else
            StringOfImages{end+1} = {'Matched keypoints'};
        end
        
        % извлекаю из всех доступных точек только совпавшие по их адресам в Pairs
        MatchedPatternPoints = PatternPoints(Pairs(:, 1), :);
        MatchedScenePoints = ScenePoints(Pairs(:, 2), :);
        
        % провожу анализ их геометрических искажений
        [~,~,ResultPoints,~] = estimateGeometricTransform(...
                                MatchedPatternPoints, ...
                                MatchedScenePoints,...
                                TransformationType,... 
                                'MaxNumTrials',MaxNumTrials, ...
                                'Confidence',Confidence,...
                                'MaxDistance', MaxDistance);      
        
        % в ось образца вставляю его со всеми отмеченными ключевыми точками 
        Pattern = insertMarker(Pattern, round(PatternPoints.Location), 'Color', 'blue');        
        image(Pattern,'Parent',handles.PatternAxes);
        handles.PatternAxes.Visible = 'off';        
        
        % запоминаю изображение с корректными ключевыми точками
        ProcessedImages(end+1).Images = ...
            insertMarker(Image, ResultPoints, 'Color', 'blue');
        
        if rus
            StringOfImages{end+1} = {'Корректные совпадающие ключевые точки (полутоновое изображение)'};
        else
            StringOfImages{end+1} = {'Сorrect matched keypoints (grayscale image)'};
        end        
        
        if size(ProcessedImages(1).Images,3) == 3
            % запоминаю изображение с корректными ключевыми точками
            ProcessedImages(end+1).Images = ...
                insertMarker(ProcessedImages(1).Images, ResultPoints, 'Color', 'blue');
            
            if rus
                StringOfImages{end+1} = {'Корректные совпадающие ключевые точки (исходное изображение)'};
            else
                StringOfImages{end+1} = {'Сorrect matched keypoints (original image)'};
            end
        end
        
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


% УВЕЛИЧЕНИЕ РАЗМЕРА ИЗОБРАЖЕНИЙ/ВИДЕО ПОД РАЗМЕР ОСИ
function ZoomButton_Callback(~, ~, handles)

% считываем файл
UserFile = getappdata(handles.FileAxes,'UserFile');
Pattern = getappdata(handles.PatternAxes,'Pattern');

% если надо уменьшить    
if handles.ZoomButton.Value == 0    
    
    try
        handles.ZoomButton.CData = imread([cd '\Icons\Zoom+.png']);
    catch
    end
    
    SetAxesSize(handles.FileAxes,size(UserFile(1).Data,1),size(UserFile(1).Data,2));
    
    if ~isempty(Pattern) % если есть образец
        SetAxesSize(handles.PatternAxes,size(Pattern,1),size(Pattern,2));
    end
    
else        % увеличить надо оси размер
    
    try
        handles.ZoomButton.CData = imread([cd '\Icons\Zoom-.png']);
    catch
    end
    
    % ОСНОВНАЯ ОСЬ
    % считываем начальный размер, выделенный для оси
    AxesSize = getappdata(handles.FileAxes,'InitPosition');
    
    % выбираем минимум, на который можем растянуть габариты и считаем их
    height = size(UserFile(1).Data,1) / ...
        min(size(UserFile(1).Data,1)/AxesSize(4) , size(UserFile(1).Data,2)/AxesSize(3));
    
    width = size(UserFile(1).Data,2) / ...
        min(size(UserFile(1).Data,1)/AxesSize(4) , size(UserFile(1).Data,2)/AxesSize(3));
    
    SetAxesSize(handles.FileAxes, height, width); 
    
    
    % ОСЬ ОБРАЗЦА    
    if ~isempty(Pattern)    % если он есть
        
        AxesSize = getappdata(handles.PatternAxes,'InitPosition');
        % выбираем минимум, на который можем растянуть габариты и считаем их
        height = size(Pattern,1) / ...
            min(size(Pattern,1)/AxesSize(4) , size(Pattern,2)/AxesSize(3));
        
        width = size(Pattern,2) / ...
            min(size(Pattern,1)/AxesSize(4) , size(Pattern,2)/AxesSize(3));
        
        SetAxesSize(handles.PatternAxes, height, width);
    end
        
end


% ВЫБОР ОБЛАСТИ ИНТЕРЕСА
function ROIButton_Callback(hObject, ~, handles)

% удаляем рамку в оси
delete(findobj('Parent',handles.FileAxes,'LineStyle','--'));

% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

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
    coords = LimitCheck(coords,[1 1 w h],[false false true true]);    
    
    switch Method
        
        case {'Распознавание текста','Optical character recognition'} 
            
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
            
        case {'Распознавание объектов','Object detection'}            
            
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
    
else    % иначе он поменял координату в полях
   
    X0 = round(str2double(handles.ROIx0.String));
    X1 = round(str2double(handles.ROIx1.String));
    Y0 = round(str2double(handles.ROIy0.String));
    Y1 = round(str2double(handles.ROIy1.String));
    
    switch Method
        
        case {'Распознавание текста','Optical character recognition'}    
    
            rectangle(  'Position',[X0 Y0 X1-X0 Y1-Y0],...
                        'Parent',handles.FileAxes,...
                        'EdgeColor','r',...
                        'LineStyle','--',...
                        'LineWidth',2);
                    
        case {'Распознавание объектов','Object detection'}        
           
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


% ОТКРЫТЬ ШАБЛОН
function PatternOpenButton_Callback(hObject, eventdata, handles)

% если русский язык выбран, будет 1
rus = strcmp(handles.RussianLanguageMenu.Checked,'on');

% выбираем файл для открытия
if rus
    
    [FileName, PathName] = uigetfile(...
        '*.jpeg;*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        'Выберите изображение-образец',...
        [cd '\Test Materials']);
else
    [FileName, PathName] = uigetfile(...
        '*.jpeg;*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        'Choose the reference image',...
        [cd '\Test Materials']);
end

if ~FileName        % Проверка, был ли выбран файл
    return;
end

try     % пробуем открыть как изображение
        
    [Temp,colors] = imread([PathName FileName]);
    
    if ~isempty(colors)                 % если индексированное -
        Temp = ind2rgb(Temp,colors);    % индексированное в RGB
    end
    
    Pattern = im2double(Temp);               % запиливаем картинку
    width = size(Pattern,2);
    heigth = size(Pattern,1);
    
catch    % открытие провалились
    
    if rus     % язык
        h = errordlg('С файлом что-то не так. Откройте другой','KAACV');
    else
        h = errordlg('File is improper. Choose another file','KAACV');
    end
    
    set(h, 'WindowStyle', 'modal');
    return;
end
    
% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
    
    case {'Распознавание объектов','Object detection'}
        
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
    
    case {'Распознавание объектов','Object detection'}    
        Value = round(Value*100)/100;
        
    otherwise
        assert(0,'в ParSlider1 вызвана несуществующая строка из меню методов');
        
        
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
        
    case {'Распознавание объектов','Object detection'}    
        
        switch handles.ParMenu3.Value   % тип детектора
            
            case 1 % MSER                
                Value = round(Value);
                
            case {2,3,4,5} % BRISK, FAST, Harris, Minimum eigen
                Value = round(Value*100)/100;
                
            case {6,7}     % SURF  
                Value = round(Value/100)*100;
                
            otherwise
                assert(0,'в ParSlider2 вызвана несуществующая строка из меню детекторов');
        end
                
        
    otherwise
        assert(0,'в ParSlider2 вызвана несуществующая строка из меню методов');
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
    
    case {'Распознавание объектов','Object detection'} 
        
        switch handles.ParMenu3.Value   % тип детектора
            
            case 1 % MSER    
                
                % регулируем пределы слайдероов, 
                % чтобы пользователь не смогу установить максимальную область 
                % выше меньше минимальной
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
                assert(0,'в ParSlider3 вызвана несуществующая строка из меню детекторов');
        end
        
    otherwise
        assert(0,'в ParSlider3 вызвана несуществующая строка из меню методов');
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
        
    case {'Распознавание объектов','Object detection'}
        
        switch handles.ParMenu3.Value   % тип детектора
            
            % регулируем пределы слайдероов, 
            % чтобы пользователь не смогу установить максимальную область 
            % выше меньше минимальной
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
                 assert(0,'в ParSlider4 вызвана несуществующая строка из меню методов');
        end                
        
    otherwise
        assert(0,'в ParSlider4 вызвана несуществующая строка из меню методов');
        
end

handles.ParSlider4.Value = Value;
handles.ParSliderValueText4.String = num2str(Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 5
function ParSlider5_Callback(hObject, eventdata, handles)

Value = handles.ParSlider5.Value;
% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
           
    case {'Распознавание объектов','Object detection'}
        Value = round(Value);
        
    otherwise
        assert(0,'в ParSlider5 вызвана несуществующая строка из меню методов');
        
end

handles.ParSlider5.Value = Value;
handles.ParSliderValueText5.String = num2str(Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 6
function ParSlider6_Callback(hObject, eventdata, handles)

Value = handles.ParSlider6.Value;
% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
           
    case {'Распознавание объектов','Object detection'}
        Value = round(Value*100)/100;
        
    otherwise
        assert(0,'в ParSlider6 вызвана несуществующая строка из меню методов');
        
end

handles.ParSlider6.Value = Value;
handles.ParSliderValueText6.String = num2str(Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 7
function ParSlider7_Callback(hObject, eventdata, handles)

Value = handles.ParSlider7.Value;
% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
           
    case {'Распознавание объектов','Object detection'}
        Value = round(Value/10)*10;
        
    otherwise
        assert(0,'в ParSlider7 вызвана несуществующая строка из меню методов');
        
end

handles.ParSlider7.Value = Value;
handles.ParSliderValueText7.String = num2str(Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 8
function ParSlider8_Callback(hObject, eventdata, handles)

Value = handles.ParSlider8.Value;
% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
           
    case {'Распознавание объектов','Object detection'}
        Value = round(Value);
        
    otherwise
        assert(0,'в ParSlider8 вызвана несуществующая строка из меню методов');
        
end

handles.ParSlider8.Value = Value;
handles.ParSliderValueText8.String = num2str(Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 9
function ParSlider9_Callback(hObject, eventdata, handles)

Value = handles.ParSlider9.Value;
% строка с названием метода обработки 
Method = string(handles.MethodMenu.String(handles.MethodMenu.Value));

switch Method
        
           
    case {'Распознавание объектов','Object detection'}
        Value = round(Value);
        
    otherwise
        assert(0,'в ParSlider9 вызвана несуществующая строка из меню методов');
        
end

handles.ParSlider9.Value = Value;
handles.ParSliderValueText9.String = num2str(Value);


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
    
    
    
    
    
    
    


