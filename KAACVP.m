%---------------------------------------------------------------------------------
% KAACVP:           Kurganski Andrew A Computer Vision Processor
% Autor / Автор:    Andrew A Kurganski / Курганский Андрей Андреевич
% e-mail:           k-and92@mail.ru
%---------------------------------------------------------------------------------

% !!!!!!!!!!!
% выделение ROI работает криво, если выделяешь в обратную сторону
% обнаружение лиц криво работает при использовании ROI -беда с абс координатами
% при выводе изображений с keypoint писать в верхнем левом углу число найденных

%%%% ИНИЦИАЛИЗАЦИЯ ПРИЛОЖЕНИЯ
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


% ФУНКЦИЯ ПРИ ОТКРЫТИИ
function KAACVP_OpeningFcn(hObject, ~, handles, varargin)

handles.output = hObject;
guidata(hObject, handles);

% запоминаем начальные координаты осей
setappdata(handles.FileAxes, 'InitPosition',handles.FileAxes.Position);
setappdata(handles.PatternAxes, 'InitPosition',handles.PatternAxes.Position);

% прячем все элементы панели параметров метода обработки
set(handles.ParametersPanel.Children,'Visible','off');

% вставляем картинки в кнопки
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

scr_res = get(0, 'ScreenSize');         % получили разрешение экрана
fig = get(handles.KAACVP,'Position');    % получили координаты окна

% отцентрировали окно
set(handles.KAACVP,'Position',...
    [(scr_res(3)-fig(3))/2 (scr_res(4)-fig(4))/2 fig(3) fig(4)]);

% проверяем наличие тулбоксов нужной версии
WeHaveCV = DoWeHaveThisToolbox('Computer Vision System Toolbox', 7.3);
WeHaveIPT = DoWeHaveThisToolbox('Image Processing Toolbox', 10); 

% по отсутствию пакетов генерируем ошибку
% ставим заглушку языка language = true, т.к.
% сообщения об ошибки при отсутствии необходимых пакетов
% продублированы на двух языках
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

% отключаем предупреждения про графику
% warning('off','all');

% не хватает отображений предобраток (текущих картинок, а не только оригинала)
% исправить в kaaip brisk пределы (30 14000)
% там же поправить в бинаризации - брать 3 канала для rgb2gray, а не 1й
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% МЕНЮ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% "ОТКРЫТЬ ФАЙЛ"
function OpenMenu_Callback(hObject, eventdata, handles)

% Что делает данная функция: 
% - проводит проверки на глупое открытие .fig вместо .m 
% - открывает файл картинку/видео. Если не смогла - информирует 
% - сохраняет удачно открытый файл 
%   в контейнер 'UserData'основного окна KAACVP -
% - размещает картинку/первый кадр в ось FileAxes, создавая объект, для
%   которого будем затем обновлять параметр 'CData' с помощью FrameSlider
% - для видео - настраивает слайдер кадров и открывает кнопки воспроизведения,
%   а для картинки прячет эти кнопки/меню
% - делает видимыми элементы интерфейса
% - устанавливает параметры элементов интерфеса в начальное состояние
% - вызывает отклики элементов интерфейса для внесения изменений, 
%   соответствующим начальному состоянию

if IsFigFileRunned(handles)
   return; 
end

IsRusLanguage = IsFigureLanguageRussian(handles);

UserFile = OpenMultimediaFile(IsRusLanguage);

if isempty(UserFile)       
    return;
end

warning('on','all');

%%%%%%%%%%%%%%%%%%%%% после удачного открытия

% записываю удачно открытый файл в данные фигуры
setappdata(handles.KAACVP,'UserFile',UserFile);

% открываем/блокируем все нужные элементы
if UserFile.IsVideo == true
    
    handles.FrameSlider.Min = 1;
    handles.FrameSlider.Max = size(UserFile.Multimedia, 2);
    handles.FrameSlider.SliderStep = ...
        [1/(size(UserFile.Multimedia, 2)-1) 10/(size(UserFile.Multimedia, 2)-1)];
    
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

% остальное открывается независимо от типа файла
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


% настравием ось под размеры видео/картинки
SetNewAxesPosition(handles.FileAxes, UserFile.Height, UserFile.Width);

% разблокируем кнопку зума, если изображение меньше размера оси
if GetMaxImageToAxesSideRation(handles.FileAxes, UserFile.Height, UserFile.Width) < 1
    
    handles.ZoomButton.Enable = 'on';
else
    handles.ZoomButton.Enable = 'off';
end

% создаю объект-картинку в оси, а FrameSlider потом лишь обновляет 'CData' этого объекта
image(  UserFile.Multimedia(1).Frame,...
        'Parent',handles.FileAxes,...
        'Tag', 'FrameObj');

% настраиваем строки методов списка обработки 
% в зависимости от типа файла: видео/картинка   
SetCVMethodMenuList(handles, UserFile.IsVideo, IsRusLanguage);

% ставим все элементы в начальное положение
handles.ZoomButton.Value = 0;
handles.PlayPauseButton.Value = 0;      % ставим на паузу
handles.ApplyButton.Value = 0;          % отжимаем кнопку обработки
handles.FrameSlider.Value = 1;          % выставляю номер первого кадра  
handles.ApplyButton.String = ReturnRusOrEngString(IsRusLanguage, 'Применить', 'Apply');

% обновляем элементы интерфейса 
ZoomButton_Callback([], [], handles);
PlayPauseButton_Callback(hObject, eventdata, handles);
FrameSlider_Callback(hObject, eventdata, handles);  
CVMethodMenu_Callback(hObject, eventdata, handles);


% "ПОКАЗАТЬ КАДР/ИЗОБРАЖЕНИЕ"
function ShowFrameMenu_Callback(hObject, eventdata, handles)

ImagesToShow = getappdata(handles.KAACVP,'ImagesToShow');

Image = ImagesToShow(handles.ImagesToShowMenu.Value).Images;

try
    imtool(Image);              % для матлаб-версии
catch
    OpenImageOutside(Image);    % для exe-версии
end


% ПРОСМОТР ROI
function ROIShowMenu_Callback(hObject, eventdata, handles)

UserFile = getappdata(handles.KAACVP,'UserFile');

% считываем координаты углов ROI
ROI_X0 = round(str2double(handles.ROIx0.String));
ROI_X1 = round(str2double(handles.ROIx1.String));
ROI_Y0 = round(str2double(handles.ROIy0.String));
ROI_Y1 = round(str2double(handles.ROIy1.String));

% вытаскиваем кадр и ROI из него
Image = UserFile.Multimedia(handles.FrameSlider.Value).Frame;    
ROI = Image(ROI_Y0:ROI_Y1, ROI_X0:ROI_X1, :);

% открываем
try
    imtool(ROI);              % для матлаб-версии
catch
    OpenImageOutside(ROI);    % для exe-версии
end


% "СОХРАНИТЬ КАДР"
function SaveFrameMenu_Callback(hObject, eventdata, handles)

UserFile = getappdata(handles.KAACVP,'UserFile');

FrameNumber = handles.FrameSlider.Value;
Image = UserFile.Multimedia(FrameNumber).Frame;
IsRusLanguage = IsFigureLanguageRussian(handles);

SaveImage(Image, FrameNumber, IsRusLanguage);


% "ПОКАЗАТЬ ШАБЛОН"
function ShowPatternImageMenu_Callback(hObject, eventdata, handles)


% "РУССКИЙ ЯЗЫК"
function RussianLanguageMenu_Callback(hObject, eventdata, handles)

if IsFigFileRunned(handles)
   return; 
end

handles.RussianLanguageMenu.Checked = 'on';
handles.EnglishLanguageMenu.Checked = 'off';

UserFile = getappdata(handles.KAACVP,'UserFile');

IsRusLanguage = IsFigureLanguageRussian(handles);

% переименовываем элементы интерфейса

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

% handles..Label = '';
% handles..Label = '';
% handles..Label = '';

% переименовываем подсказки

% handles..TooltipString = '';

% обновляем отклики, если мультимедиа файл уже был открыт
if ~isempty(UserFile)
    SetCVMethodMenuList(handles, UserFile.IsVideo, IsRusLanguage);    % меняем список методов
    CVMethodMenu_Callback(hObject, eventdata, handles);   % обновляем панель параметров
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

% переименовываем элементы интерфейса

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

% переименовываем подсказки
% handles..TooltipString = '';

% обновляем отклики, если мультимедиа файл уже был открыт
if ~isempty(UserFile)
    SetCVMethodMenuList(handles, UserFile.IsVideo, IsRusLanguage);    % меняем список методов
    CVMethodMenu_Callback(hObject, eventdata, handles);   % обновляем панель параметров
end


%---------------------------------------------------------------------------------

% ВЫБОР МЕТОДА ОБРАБОТКИ
function CVMethodMenu_Callback(hObject, eventdata, handles)

% Что делает функция:
% - сначала прячет все элементы интерефейса на панели выбора параметров обработки ParametersPanel
%   и некоторые меню
% - устанавливает значения выбранных строк списков в 1, чтобы они не слетали
%   при старом выборе пользователем большего значения, чем число строк в меню
% - считываем загруженный пользователем файл и его параметры
% - в зависимости от выбранного метода обработки проводим настройку и отображаем 
%   необходимые элементы интерфейса таким образом, чтобы пользователь 
%   не смог выбрать ни одного некорректного параметра

% прячем и делаем недоступными элементы интерфейса
set(handles.ParametersPanel.Children,'Visible','off');
handles.ROIShowMenu.Enable = 'off';
handles.ShowPatternImageMenu.Visible = 'off';
handles.PatternAxesPanel.Visible = 'off';

% очищаем старые пользовательские данные
setappdata(handles.KAACVP,'Pattern',[]);
delete([handles.PatternAxes.Children handles.PatternAxes.UserData]);
delete(findobj('Parent',handles.FileAxes,'LineStyle','--'));

% устанавливаем все выбранные строки менюшек в 1,
% чтобы они не вылетали в случае Menu.Value > length(Menu.String)
handles.ParMenu1.Value = 1;
handles.ParMenu2.Value = 1;
handles.ParMenu3.Value = 1;
handles.ParMenu4.Value = 1;

handles.ParCheckBox1.Value = 0;
handles.ParCheckBox2.Value = 0;

% очищаем подсказки
handles.ParCheckBox1.TooltipString = '';
handles.ParCheckBox2.TooltipString = '';

%------------------------------------------------------------------------------
UserFile = getappdata(handles.KAACVP,'UserFile');

ImWidth = UserFile.Width;
ImHeight = UserFile.Height; 
MinWidthHeight = min(ImWidth,ImHeight);     % минимальная сторона
MaxWidthHeight = max(ImWidth,ImHeight);     % максимальная сторона

% случайно проверяем массив на монохромность
RandomFrame = randi( size(UserFile,2) );
ImageIsMonochrome = all(all(  UserFile.Multimedia(RandomFrame).Frame(:)== 0 |...
                              UserFile.Multimedia(RandomFrame).Frame(:) == 1));                            

IsRusLanguage = IsFigureLanguageRussian(handles);

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

% нужна для вызова SetParSlidersVisibleStatus и SetParMenusVisibleStatus
ShowIt = true; 
        
switch ComputerVisionMethod
    
    case {'Распознавание текста','Optical character recognition'}
        
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
        
        % Порог распознавания
        handles.ParSlider1.Min              = 0.01;
        handles.ParSlider1.Max              = 1;
        handles.ParSlider1.SliderStep       = [0.01/0.99 0.1/0.99];
        handles.ParSlider1.Value            = 0.5;
        handles.ParSliderValueText1.String  = '0.5';   
        
        if IsRusLanguage 
            handles.ParMenuText1.String = 'Расположение текста';
            handles.ParMenu1.String = { 'Авто';
                                        'Блок';
                                        'Линия';
                                        'Слово'};

            handles.ParMenuText2.String = 'Распознаваемый язык';
            
            % проверяем наличие установленного расширения
            try  
                % если сработает метод ocr, тогда расширение стоит 
                ocr(ones(10),'Language','Russian');  

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

            % проверяем наличие установленного расширения
            try 
                % если сработает метод ocr, тогда расширение стоит 
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
        
        % обновляем ROI / образец       
        ROIPosition = [1 1 ImWidth-1 ImHeight-1];
        X0Y0X1Y1Coords = [1 1 ImWidth ImHeight];        
        RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);
        
    case {'Чтение штрих-кода','Barcode reading'} 
        
    case {'Поиск областей с текстом','Text region detection'}  
        
    case {'Анализ пятен','Blob analysis'}   
        
        SetParSlidersVisibleStatus(1:3, ShowIt, handles);
        SetParMenusVisibleStatus(1, ShowIt, handles);   
        
        if ~ImageIsMonochrome          
            
            SetParSlidersVisibleStatus(4, ShowIt, handles);
            SetParMenusVisibleStatus(2:3, ShowIt, handles);        
        end
        
        handles.ParCheckBox1.Visible = 'on';
        
        % Максимальное количество пятен
        handles.ParSlider1.Min              = 1;
        handles.ParSlider1.Max              = ImWidth * ImHeight;
        handles.ParSlider1.SliderStep       = [1/(ImWidth*ImHeight-1) 10/(ImWidth*ImHeight-1)];
        handles.ParSlider1.Value            = round(ImWidth * ImHeight / 2);
        handles.ParSliderValueText1.String  = num2str(round(ImWidth * ImHeight / 2));         
        
        % Минимальная область пятна
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
        
        % Максимальная область пятна
        handles.ParSlider3.Min              = 1;
        handles.ParSlider3.Max              = ImWidth*ImHeight;
        handles.ParSlider3.SliderStep       = [1/(ImWidth*ImHeight-1) 10/(ImWidth*ImHeight-1)];
        handles.ParSlider3.Value            = round(ImWidth * ImHeight / 2);
        handles.ParSliderValueText3.String  = num2str(round(ImWidth * ImHeight / 2)); 
        
        
        % Чувствительность
        handles.ParSlider4.Min              = 0;
        handles.ParSlider4.Max              = 1;
        handles.ParSlider4.SliderStep       = [0.01 0.1];
        handles.ParSlider4.Value            = 0.5;
        handles.ParSliderValueText4.String  = '0.5';       
        
        % Связность
        handles.ParMenu1.String = { '4';'8';};
        
        handles.ParCheckBox1.Value = 1;        
        
        if IsRusLanguage            
            handles.ParMenuText1.String = 'Связность';
            handles.ParMenuText2.String = 'Тип бинаризации';
            handles.ParMenu2.String = {'Адаптивная';'Глобальная (Оцу)';'Глобальная';};
            handles.ParMenuText3.String = 'Фон';
            handles.ParMenu3.String = {'Темный';'Яркий';};
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
                
        
    case {'Распознавание лиц','Face detection'}        
        
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
            
            handles.ParMenuText1.String = 'Модель классификации';
            handles.ParMenu1.String = { 'Анфас (CART)';...
                                        'Анфас (LBP)';...
                                        'Верх тела';...
                                        'Пара глаз (большая)';...
                                        'Пара глаз (малая)';...
                                        'Левый глаз';...
                                        'Правый глаз';...
                                        'Левый глаз (CART)';...
                                        'Правый глаз (CART)';...
                                        'Профиль';...
                                        'Рот';...
                                        'Нос';...
                                        };                                    
                                    
            handles.ParSliderText1.String = 'Минимальная высота объекта: '; 
            handles.ParSliderText2.String = 'Максимальная высота объекта: '; 
            handles.ParSliderText3.String = 'Минимальная ширина объекта: '; 
            handles.ParSliderText4.String = 'Максимальная ширина объекта: '; 
            handles.ParSliderText5.String = 'Шаг масштабирования: '; 
            handles.ParSliderText6.String = 'Порог слияния: '; 
            
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
        
        % Шаг масштабирования
        handles.ParSlider5.Min              = 1.0001;
        handles.ParSlider5.Max              = 5;
        handles.ParSlider5.SliderStep       = [0.0001/3.9999 0.001/3.9999];
        handles.ParSlider5.Value            = 1.1;
        handles.ParSliderValueText5.String  = '1.1';
        
        % Порог слияния
        handles.ParSlider6.Min              = 1;
        handles.ParSlider6.Max              = 1000;
        handles.ParSlider6.SliderStep       = [1/999 10/999];
        handles.ParSlider6.Value            = 4;
        handles.ParSliderValueText6.String  = '4'; 
            
        % обновляем ROI / образец       
        ROIPosition = [1 1 ImWidth-1 ImHeight-1];
        X0Y0X1Y1Coords = [1 1 ImWidth ImHeight];        
        RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);
        
        % при вызове меню будут настроены слайдеры 1-4
        ParMenu1_Callback(hObject, eventdata, handles);
        
    case {'Распознавание людей','People detection'}
        
    case {'Распознавание объектов','Object detection'}
        
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
        handles.ParSlider7.SliderStep       = [10/99990 100/99990];
        handles.ParSlider7.Value            = 1000;
        handles.ParSliderValueText7.String  = '1000';  
        
        % Уровень доверия
        handles.ParSlider8.Min              = 1;
        handles.ParSlider8.Max              = 99.99;
        handles.ParSlider8.SliderStep       = [0.01/98.99 0.1/98.99];
        handles.ParSlider8.Value            = 90;
        handles.ParSliderValueText8.String  = '90';  
        
        % Макс. расстояние между точкой и проекцией
        handles.ParSlider9.Min              = 1;
        handles.ParSlider9.Max              = MinWidthHeight/4;
        handles.ParSlider9.SliderStep       = [1/(MinWidthHeight/4 - 1) 10/(MinWidthHeight/4 - 1)];
        handles.ParSlider9.Value            = 2;
        handles.ParSliderValueText9.String  = '2';          
        
        if IsRusLanguage
                                     
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
        
        % обновляем интерфейс
        ParMenu3_Callback(hObject, eventdata, handles);
        ParCheckBox1_Callback(hObject, eventdata, handles);
        ParCheckBox2_Callback(hObject, eventdata, handles);
        
        % вставляем образец      
        ROIPosition = [1 1 ImWidth-1 ImHeight-1];
        X0Y0X1Y1Coords = [1 1 ImWidth ImHeight];        
        RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);
        
    case {'Создание 3D-изображения','3-D image creation'}        
        
        SetParSlidersVisibleStatus(5:9, ShowIt, handles);
        SetParMenusVisibleStatus(1:4, ShowIt, handles);      
        SetROI_Visible(handles); 
        
        handles.ShowPatternImageMenu.Visible = 'on';
        handles.PatternAxesPanel.Visible = 'on';
        
        handles.ParCheckBox1.Visible = 'on';    
        handles.ParCheckBox2.Visible = 'on';   
        
        % Максимальное число случайных испытаний
        % NumTrials из estimateFundamentalMatrix()
        handles.ParSlider1.Min              = 10;
        handles.ParSlider1.Max              = 100000;
        handles.ParSlider1.SliderStep       = [10/99990 100/99990];
        handles.ParSlider1.Value            = 1000;
        handles.ParSliderValueText1.String  = '1000';  
        
        % Уровень доверия
        % Confidence из estimateFundamentalMatrix()
        handles.ParSlider2.Min              = 1;
        handles.ParSlider2.Max              = 99.99;
        handles.ParSlider2.SliderStep       = [0.01/98.99 0.1/98.99];
        handles.ParSlider2.Value            = 90;
        handles.ParSliderValueText2.String  = '90';
        
        % Порог расстояния 
        % DistanceThreshold из estimateFundamentalMatrix() 
        handles.ParSlider3.Min              = 0.001;
        handles.ParSlider3.Max              = 5;
        handles.ParSlider3.SliderStep       = [0.001/4.999 0.01/4.999];
        handles.ParSlider3.Value            = 0.01;
        handles.ParSliderValueText3.String  = '0.01';
        
        % Минимальный процент inlier
        % InlierPercentage из estimateFundamentalMatrix() 
        handles.ParSlider4.Min              = 1;
        handles.ParSlider4.Max              = 99;
        handles.ParSlider4.SliderStep       = [1/98 10/98];
        handles.ParSlider4.Value            = 50;
        handles.ParSliderValueText4.String  = '50';
        
        % Порог сравнения
        % MatchThreshold из matchFeatures()
        handles.ParSlider5.Min              = 1;
        handles.ParSlider5.Max              = 100;
        handles.ParSlider5.SliderStep       = [1/99 10/99];
        handles.ParSlider5.Value            = 10;
        handles.ParSliderValueText5.String  = '10'; 
        
        % Порог отношения
        % MaxRatio из matchFeatures()
        handles.ParSlider6.Min              = 0.01;
        handles.ParSlider6.Max              = 1;
        handles.ParSlider6.SliderStep       = [0.01/0.99 0.1/0.99];
        handles.ParSlider6.Value            = 0.1;
        handles.ParSliderValueText6.String  = '0.1';
        
        % Порог (SURF)
        handles.ParSlider7.Min              = 100;
        handles.ParSlider7.Max              = 100000;
        handles.ParSlider7.SliderStep       = [100/999900 1000/999900];
        handles.ParSlider7.Value            = 1000;
        handles.ParSliderValueText7.String  = '1000';
        
        % Число уровней масштаба (SURF)
        handles.ParSlider8.Min              = 3;
        handles.ParSlider8.Max              = 8;
        handles.ParSlider8.SliderStep       = [1/5 1/5];
        handles.ParSlider8.Value            = 4;
        handles.ParSliderValueText8.String  = '4';
        
        % Число октав (SURF)
        handles.ParSlider9.Min              = 1;
        handles.ParSlider9.Max              = 6;
        handles.ParSlider9.SliderStep       = [1/5 1/5];
        handles.ParSlider9.Value            = 3;
        handles.ParSliderValueText9.String  = '3';
        
        if IsRusLanguage
            
            handles.ParSliderText1.String = 'Число испытаний: '; 
            handles.ParSliderText2.String = 'Уровень доверия: ';
            handles.ParSliderText3.String = 'Порог расстояния: '; 
            handles.ParSliderText4.String = 'Мин. число корректных точек, %: ';
            
            handles.ParSliderText5.String = 'Порог сравнения: '; 
            handles.ParSliderText6.String = 'Порог отношения: '; 
            
            handles.ParSliderText7.String = 'Порог (SURF):';
            handles.ParSliderText8.String = 'Число уровней масштаба (SURF):';
            handles.ParSliderText9.String = 'Число октав (SURF):';
            
            handles.ParMenuText1.String = 'Метод сравнения';
            handles.ParMenu1.String = { 'Исчерпывающий';...
                                        'Приблизительный';...
                                        };
                                    
            handles.ParMenuText2.String = 'Метрика сравнения';
            handles.ParMenu2.String = { 'Сумма модулей разности';...
                                        'Сумма квадратов разностей';...
                                        }; 
                                    
            handles.ParMenuText3.String = 'Метод вычисления фундаментальной матрицы';
            handles.ParMenu3.String = { 'Norm8Point';...
                                        'LMedS';...
                                        'RANSAC';...
                                        'MSAC';...
                                        'LTS';...
                                        }; 
                                    
            handles.ParMenuText4.String = 'Метрика вычисления фундаментальной матрицы';
            handles.ParMenu4.String = { 'Самсона';...
                                        'Алгебраическая';...
                                        };
                                    
            handles.ParCheckBox1.String = 'Дескриптор (128)'; 
            handles.ParCheckBox1.TooltipString = 'Использовать полный SURF дескриптор (128)';             
            handles.ParCheckBox2.String = 'Только уникальные';  
            handles.ParCheckBox2.TooltipString = 'Результат сравния - только уникальные ключевые точки';
            
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
                                    
            handles.ParMenuText3.String = 'Метод вычисления фундаментальной матрицы';
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
               
        % обновляем интерфейс
        ParMenu3_Callback(hObject, eventdata, handles);
        ParCheckBox1_Callback(hObject, eventdata, handles);
        ParCheckBox2_Callback(hObject, eventdata, handles);
        
        % вставляем образец      
        ROIPosition = [1 1 ImWidth-1 ImHeight-1];
        X0Y0X1Y1Coords = [1 1 ImWidth ImHeight];        
        RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);        
        
    case {'Обработка видео','Video processing'}
        
    case {'Создание панорамы','Panorama creation'}
        
    case {'Распознавание движения','Motion detection'}
        
    otherwise
        assert(0, 'Ошибка в обращении к методам обработки');
        
end

%---------------------------------------------------------------------------------

% ВЫБОР ОТОБРАЖАЕМОГО КАДРА/ИЗОБРАЖЕНИЯ ИЗ ЭТАПОВ ОБРАБОТКИ
function ImagesToShowMenu_Callback(~, ~, handles)

% в процессе обработки появляется несколько изображений-этапов обработки,
% которые пользователь может увидеть
% они называются 'ImagesToShow' и хранятся в 'UserData' основного окна

% провожу отображение нужной картинки
ShowMultimediaFile(handles);


% МЕНЮ № 1 ПАРАМЕТРОВ 
function ParMenu1_Callback(hObject, eventdata, handles)
        
UserFile = getappdata(handles.KAACVP,'UserFile');

ImWidth = UserFile.Width;
ImHeight = UserFile.Height;

ComputerVisionMethod = string(handles.CVMethodMenu.String( handles.CVMethodMenu.Value ));

switch ComputerVisionMethod
    
    case {'Распознавание лиц','Face detection'}        
        
        handles.ParSlider1.Enable = 'on';
        handles.ParSlider2.Enable = 'on';
        handles.ParSlider3.Enable = 'on';
        handles.ParSlider4.Enable = 'on';
        
        % Считываем размер изображений, на которых обучен каскад
        % Этот размер будем минимумом для определения
        [TrainModelSize, ~] = ReturnFaceDetectorTrainModelAndSize(...
                string( handles.ParMenu1.String( handles.ParMenu1.Value ) ));
        
        %-----------------------------------------------------------
        % следующие слайдеры устанавливают пределы интервалов: от min к max
        % чтобы исключить пересечения значений парных слайдеров (чтобы не было max < min)
        % их 'Value' должны быть равны соответствующим пределам в самом начале
        % в откликах парных интервальных слайдеров их пределы меняются при их вызове
                
        % Минимальная высота объекта
        handles.ParSlider1.Min              = TrainModelSize(1);            % предел равен
        handles.ParSlider1.Max              = ImHeight - 1;
        handles.ParSlider1.SliderStep       = [ 1 /(ImHeight-1-TrainModelSize(1))...
                                                10/(ImHeight-1-TrainModelSize(1))];
        handles.ParSlider1.Value            = TrainModelSize(1);            % значению
        handles.ParSliderValueText1.String  = num2str(TrainModelSize(1));   
        
        % Максимальная высота объекта
        handles.ParSlider2.Min              = TrainModelSize(1) + 1;
        handles.ParSlider2.Max              = ImHeight;                     % предел равен
        handles.ParSlider2.SliderStep       = [ 1 /(ImHeight-TrainModelSize(1)-1)...
                                                10/(ImHeight-TrainModelSize(1)-1)];
        handles.ParSlider2.Value            = ImHeight;                     % значению
        handles.ParSliderValueText2.String  = num2str(ImHeight);            
        
        % Минимальная ширина объекта
        handles.ParSlider3.Min              = TrainModelSize(2);            % предел равен
        handles.ParSlider3.Max              = ImWidth - 1;
        handles.ParSlider3.SliderStep       = [ 1 /(ImWidth-1-TrainModelSize(2))...
                                                10/(ImWidth-1-TrainModelSize(2))];
        handles.ParSlider3.Value            = TrainModelSize(2);            % значению
        handles.ParSliderValueText3.String  = num2str(TrainModelSize(2));   
        
        % Максимальная ширина объекта        
        handles.ParSlider4.Min              = TrainModelSize(2) + 1;        
        handles.ParSlider4.Max              = ImWidth;                      % предел равен
        handles.ParSlider4.SliderStep       = [ 1 /(ImWidth-TrainModelSize(2)-1) ...
                                                10/(ImWidth-TrainModelSize(2)-1)];
        handles.ParSlider4.Value            = ImWidth;                      % значению
        handles.ParSliderValueText4.String  = num2str(ImWidth);
        
        %-----------------------------------------------------------
        
end    


% МЕНЮ № 2 ПАРАМЕТРОВ 
function ParMenu2_Callback(hObject, eventdata, handles)

% в зависимости от выбора пользователя необходимо отображать  
% соответствующие обработке элементы интерфейса

ComputerVisionMethod = string(handles.CVMethodMenu.String( handles.CVMethodMenu.Value ));
ParMenu2Method = string(handles.ParMenu2.String( handles.ParMenu2.Value ));

switch ComputerVisionMethod
    
    case {'Анализ пятен','Blob analysis'} 
        
        switch ParMenu2Method
            
            case {'Адаптивная', 'Adaptive'}
                
                handles.ParSlider4.Visible = 'on';
                handles.ParSliderText4.Visible = 'on';
                handles.ParSliderValueText4.Visible = 'on';
                
                handles.ParMenu3.Visible = 'on';
                handles.ParMenuText3.Visible = 'on';
            
            case {'Глобальная (Оцу)', 'Global (Otsu)'}
                
                handles.ParSlider4.Visible = 'off';
                handles.ParSliderText4.Visible = 'off';
                handles.ParSliderValueText4.Visible = 'off';
                
                handles.ParMenu3.Visible = 'off';
                handles.ParMenuText3.Visible = 'off';
            
            case {'Глобальная', 'Global'}
                
                handles.ParSlider4.Visible = 'on';
                handles.ParSliderText4.Visible = 'on';
                handles.ParSliderValueText4.Visible = 'on';
                
                handles.ParMenu3.Visible = 'off';
                handles.ParMenuText3.Visible = 'off';
                
            otherwise
                assert(0,'в ParMethod2 вызвана несуществующая строка из меню методов');
        
        end     % switch ParMenu2Method 
        
end             % switch ComputerVisionMethod


% МЕНЮ № 3 ПАРАМЕТРОВ 
function ParMenu3_Callback(hObject, eventdata, handles)

% в зависимости от выбора пользователя необходимо отображать  
% соответствующие обработке элементы интерфейса

IsRusLanguage = IsFigureLanguageRussian(handles);

UserFile = getappdata(handles.KAACVP,'UserFile');

MaxOfWidthAndHeight = max(UserFile.Width, UserFile.Height);
MinOfWidthAndHeight = min(UserFile.Width, UserFile.Height);

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));
ParMenu3Method = string(handles.ParMenu3.String( handles.ParMenu3.Value ));

switch ComputerVisionMethod
    
%----------------------------------------------------------- 
    case {'Распознавание объектов','Object detection'}    
                
        ShowIt = true;
        HideIt = false;
        
        % прячу все элементы, открываю затем только нужные
        SetParSlidersVisibleStatus(1:4, HideIt, handles);
        
        handles.ParCheckBox1.Visible = 'off';
        
        handles.ParSlider1.Enable = 'on';
        handles.ParSlider2.Enable = 'on';
        handles.ParSlider3.Enable = 'on';
        handles.ParSlider4.Enable = 'on';        
        
        % установка в дефолт
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
                % следующие слайдеры устанавливают пределы интервалов: от min к max
                % чтобы исключить пересечения значений слайдеров (чтобы не было max < min)
                % их 'Value' должны быть равны соответствующим пределам в самом начале
                % в откликах парных интервальных слайдеров их пределы постоянно меняются
                
                handles.ParSlider3.Min              = 1;        % предел равен
                handles.ParSlider3.Max              = MaxOfWidthAndHeight - 1;  
                handles.ParSlider3.SliderStep       = [ 1/(MaxOfWidthAndHeight - 1)...
                                                        1/(MaxOfWidthAndHeight - 1)];
                handles.ParSlider3.Value            = 1;        % значению
                handles.ParSliderValueText3.String  = '1';      
                
                handles.ParSlider4.Min              = 2;
                handles.ParSlider4.Max              = MaxOfWidthAndHeight;          % предел равен
                handles.ParSlider4.SliderStep       = [ 1/(MaxOfWidthAndHeight - 1) ...
                                                        1/(MaxOfWidthAndHeight - 1)];
                handles.ParSlider4.Value            = MaxOfWidthAndHeight;          % значению
                handles.ParSliderValueText4.String  = num2str(MaxOfWidthAndHeight); 
                
                %-----------------------------------------------------------
                        
                if IsRusLanguage 
                    
                    handles.ParSliderText1.String = 'Максимальная вариация области:';
                    handles.ParSliderText2.String = 'Шаг порога:';
                    handles.ParSliderText3.String = 'Минимальная область:';
                    handles.ParSliderText4.String = 'Максимальная область:';
                    
                    handles.ParMenuText4.String = 'Метрика сравнения';
                    handles.ParMenu4.String = { 'Сумма модулей разности';...
                                                'Сумма квадратов разностей';...
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
                    
                    handles.ParSliderText1.String = 'Минимальный контрастность:';
                    handles.ParSliderText2.String = 'Минимальное качество:';
                    handles.ParSliderText3.String = 'Число октав:';
                    
                    handles.ParMenuText4.String = 'Метрика сравнения';
                    handles.ParMenu4.String = { 'Хэмминга';...
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
                    
                    handles.ParSliderText1.String = 'Минимальный контрастность:';
                    handles.ParSliderText2.String = 'Минимальное качество:';
                    
                    handles.ParMenuText4.String = 'Метрика сравнения';
                    handles.ParMenu4.String = {'Хэмминга'};                    
                else
                    handles.ParSliderText1.String = 'Minimum contrast:';
                    handles.ParSliderText2.String = 'Minimum quality:';
                    
                    handles.ParMenuText4.String = 'Match metric';
                    handles.ParMenu4.String = {'Hamming'};                    
                end
                
            case {'Харриса', 'Harris'}
                
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
                    
                    handles.ParSliderText3.String = 'Размер окна фильтра:';
                    handles.ParSliderText2.String = 'Минимальное качество:';
                    
                    handles.ParMenuText4.String = 'Метрика сравнения';
                    handles.ParMenu4.String = { 'Хэмминга';...
                                                };
                    
                else
                    handles.ParSliderText3.String = 'Filter dimension:';
                    handles.ParSliderText2.String = 'Minimum quality:';
                    
                    handles.ParMenuText4.String = 'Match metric';
                    handles.ParMenu4.String = { 'Hamming';...
                                                };                    
                end                
                
            case {'Минимального собственного значения', 'Minimum eigen'}                
                             
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
                    
                    handles.ParSliderText3.String = 'Размер окна фильтра:';
                    handles.ParSliderText2.String = 'Минимальное качество:';
                    
                    handles.ParMenuText4.String = 'Метрика сравнения';
                    handles.ParMenu4.String = { 'Хэмминга';...
                                                };
                    
                else
                    handles.ParSliderText3.String = 'Filter dimension:';
                    handles.ParSliderText2.String = 'Minimum quality:';
                    
                    handles.ParMenuText4.String = 'Match metric';
                    handles.ParMenu4.String = { 'Hamming';...
                                                };                    
                end
                
            case {  'SURF (размер дескриптора 64)',...
                    'SURF (размер дескриптора 128)',...
                    'SURF (64 descriptor size)',...
                    'SURF (128 descriptor size)'}
                
                handles.ParCheckBox1.Visible = 'on';  
                SetParSlidersVisibleStatus(2:4, ShowIt, handles);
                
                % Порог
                handles.ParSlider2.Min              = 100;
                handles.ParSlider2.Max              = 100000;
                handles.ParSlider2.SliderStep       = [100/999900 1000/999900];
                handles.ParSlider2.Value            = 1000;
                handles.ParSliderValueText2.String  = '1000';
                
                % Число октав
                handles.ParSlider3.Min              = 1;
                handles.ParSlider3.Max              = 6;
                handles.ParSlider3.SliderStep       = [1/5 1/5];
                handles.ParSlider3.Value            = 3;
                handles.ParSliderValueText3.String  = '3';
                
                % Число уровней масштаба
                handles.ParSlider4.Min              = 3;
                handles.ParSlider4.Max              = 8;
                handles.ParSlider4.SliderStep       = [1/5 1/5];
                handles.ParSlider4.Value            = 4;
                handles.ParSliderValueText4.String  = '4';
                
                if IsRusLanguage 
                    
                    handles.ParSliderText2.String = 'Порог:';
                    handles.ParSliderText3.String = 'Число октав:';
                    handles.ParSliderText4.String = 'Число уровней масштаба:';
                    
                    handles.ParMenuText4.String = 'Метрика сравнения';
                    handles.ParMenu4.String = { 'Сумма модулей разности';...
                                                'Сумма квадратов разностей';...
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
                assert(0,'в ParMethod3 вызвана несуществующая строка из меню методов');
                
        end             % switch ParMenu3Method
        
%-----------------------------------------------------------        
    case {'Создание 3D-изображения','3-D image creation'}
        
        HideIt = false;
        ShowIt = true;
        % прячу слайдеры, открываю затем только нужные
        SetParSlidersVisibleStatus(1:4, HideIt, handles);
        
        % это меню не нужно только в случае 'Norm8Point'
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
                assert(0, 'в ParMethod4 несуществующая строка меню методов');
        end
        
%----------------------------------------------------------- 
        
end                     % switch ComputerVisionMethod


% МЕНЮ № 4 ПАРАМЕТРОВ 
function ParMenu4_Callback(hObject, eventdata, handles)

IsRusLanguage = IsFigureLanguageRussian(handles);

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

ParMenu4Method = string(handles.ParMenu4.String( handles.ParMenu4.Value ));

switch ComputerVisionMethod   
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%% КНОПКИ  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ВОСПРОИЗВЕДЕНИЕ / ПАУЗА
function PlayPauseButton_Callback(hObject, eventdata, handles)

% Что делает функция:
% - меняет иконку паузы / воспроизведения
% - блокирует кнопки пошагового изменения кадра и FrameSlider
% - обновляет кадр и вызываем слайдер, который и покажет кадр
% - выжидаем паузу, соответствующую скорости воспроизведения видео
% - в момент вызова pause функция может быть прервана другими вызовами элементов интерфейса
%   и если нажали на паузу - прекращаем воспроизведение, поменяв иконку

% при нажатии на кнопку обновляем интерфейс
if handles.PlayPauseButton.Value == 0
    
    try
        handles.PlayPauseButton.CData = imread([cd '\Icons\Play.png']);
    catch
        handles.PlayPauseButton.String = '>';        
    end
    
    % на паузе кнопки доступны
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
    
    % на паузе кнопки недоступны
    handles.FrameBackButton.Enable = 'off';
    handles.FrameForwardButton.Enable = 'off';
    handles.FrameSlider.Enable = 'off';
    handles.PatternOpenButton.Enable = 'off';
    
    UserFile = getappdata(handles.KAACVP,'UserFile'); 
    FrameRate = UserFile.FrameRate;
    
    % прогоняем кадры
    for FrameNumber = handles.FrameSlider.Value : handles.FrameSlider.Max
        
        % заскаем старт обработки
        tic;        
        
        % ставим в слайдер новое значение
        handles.FrameSlider.Value = FrameNumber;            
        
        % обработка или прорисовка в отклике слайдера
        FrameSlider_Callback(hObject, eventdata, handles);          
        drawnow;                        
        
        % если успели раньше, чем пауза меж кадрами, ждем остаток паузы
        if toc < (1/FrameRate)          
            pause(1/FrameRate - toc);
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

FrameNumber = handles.FrameSlider.Value - 1;

if FrameNumber < handles.FrameSlider.Min
    FrameNumber = handles.FrameSlider.Min;
end

% обновили значение слайдера
handles.FrameSlider.Value = FrameNumber;

% отобразили новый кадр
FrameSlider_Callback(hObject, eventdata, handles);


% СЛЕДУЮЩИЙ КАДР
function FrameForwardButton_Callback(hObject, eventdata, handles)

FrameNumber = handles.FrameSlider.Value + 1;

if FrameNumber > handles.FrameSlider.Max
    FrameNumber = handles.FrameSlider.Max;
end

% обновили значение слайдера
handles.FrameSlider.Value = FrameNumber;

% отобразили новый кадр
FrameSlider_Callback(hObject, eventdata, handles);


%---------------------------------------------------------------------------------

% ПРИМЕНИТЬ
function ApplyButton_Callback(hObject, eventdata, handles)

% Что делает функция:
% - блокирует элементы, чтобы пользователь не портил обработку
% - считывает пользовательский файл
% - извлекает из него текущий кадр/изображение
% - меняет строку состояния для видео на "Применяется", что
%   при воспроизведении будет означать непрерывную обработку каждого кадра
% - очищает старые граф. элементы на осях
% - начинаем собирать значения элементов интерефейса панели параметров 
%   для выбранной пользователем обработки
% - запихиваем эти значения в структуру ProcessParameters
% - вызываем обработку для сформированной структуры параметров
% - сохраняем поля структуры в главном окне
% - вызываем обработчики событий элементов интерфейса для обновления интерфейса
% - разблокирует элементы

UserFile = getappdata(handles.KAACVP,'UserFile');

DoyouWantToBlockInterface(true, handles, UserFile.IsVideo);

Image = UserFile.Multimedia( handles.FrameSlider.Value ).Frame;

IsRusLanguage = IsFigureLanguageRussian(handles);

% показываем, что процесс применения для видео длителен: при нажатии
if UserFile.IsVideo
    
    if handles.ApplyButton.Value == 1   % в нажатом состоянии
        
        handles.ApplyButton.String = ReturnRusOrEngString(IsRusLanguage, 'Применяется', 'Applying');
        
    else        % если отжали кнопку - не нужно обрабатывать
        
        handles.ApplyButton.String = ReturnRusOrEngString(IsRusLanguage, 'Применить', 'Apply');        
        return;        
    end
    
else                                % для картинок    
    handles.ApplyButton.Value = 0;  % снимаем нажатое состояние     
end


% удаляем старые элементы
delete(findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b'));
handles.StatisticsList.String = '';

% чтобы не вылетал лист - ставим выделение 1й строки
handles.StatisticsList.Value = 1;

% создаем массив под параметры обработки
ProcessParameters = struct();       

% запоминаем метод обработки, выбранный в выпадающем списке методов
ProcessParameters.ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

% считываем знеачения всех полей параметров
ProcessParameters.X0 = round(str2double(handles.ROIx0.String));
ProcessParameters.X1 = round(str2double(handles.ROIx1.String));
ProcessParameters.Y0 = round(str2double(handles.ROIy0.String));
ProcessParameters.Y1 = round(str2double(handles.ROIy1.String));

% В ЗАВИСИМОСТИ ОТ НАСТРОЕК ЭЛЕМЕНТОВ ИНТЕРЕФЕЙСА 
% И ВЫБРАННОГО МЕТОДОА ОБРАБОТКИ ФОРМИРУЕМ
% СТРУКТУРУ ПАРАМЕТРОВ ОБРАБОТКИ
switch ProcessParameters.ComputerVisionMethod
    
    case {'Распознавание текста','Optical character recognition'}        
        
        ProcessParameters.thresh = handles.ParSlider1.Value;
        ProcessParameters.textlayout = handles.ParMenu1.Value;
        ProcessParameters.language = handles.ParMenu2.Value;
        
        switch ProcessParameters.textlayout       % расположение текста
            
            case 1
                ProcessParameters.layout = 'Auto';
            case 2
                ProcessParameters.layout = 'Block';
            case 3
                ProcessParameters.layout = 'Line';
            case 4
                ProcessParameters.layout = 'Word';
        end
        
        switch ProcessParameters.language       % язык распознавания
            
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
        
    case {'Чтение штрих-кода','Barcode reading'} 
        
    case {'Поиск областей с текстом','Text region detection'}  
        
    case {'Анализ пятен','Blob analysis'}         
        
        % связность
        ProcessParameters.Conn = handles.ParMenu1.Value * 4;              
        ProcessParameters.BinarizationType = string(...
            handles.ParMenu2.String( handles.ParMenu2.Value )); 
        ProcessParameters.ForegroundType = handles.ParMenu3.Value;        
        % вкл/искл гранич пятна
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
        
    case {'Распознавание лиц','Face detection'}
        
        ProcessParameters.MinSize = [handles.ParSlider1.Value handles.ParSlider3.Value];
        ProcessParameters.MaxSize = [handles.ParSlider2.Value handles.ParSlider4.Value];
        ProcessParameters.ScaleFactor = handles.ParSlider5.Value;
        ProcessParameters.MergeThreshold = handles.ParSlider6.Value;
        [~, ProcessParameters.Model] = ReturnFaceDetectorTrainModelAndSize(...
                            string( handles.ParMenu1.String( handles.ParMenu1.Value ) ));
            
    case {'Распознавание людей','People detection'}
        
    case {'Распознавание объектов','Object detection'}
        
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
         
        switch handles.ParMenu1.Value       % тип преобразования
            
            case 1
                ProcessParameters.TransformationType = 'similarity';
            case 2
                ProcessParameters.TransformationType = 'affine';                
            case 3
                ProcessParameters.TransformationType = 'projective';  
            otherwise
                assert(0,'Что то пошло не так...Выбрали не существующую строчку меню');
        end
        
        switch handles.ParMenu2.Value            % Метод сравнения
            case 1
                ProcessParameters.MatchMethod = 'Exhaustive';
            case 2
                ProcessParameters.MatchMethod = 'Approximate';
            otherwise
                assert(0,'Что то пошло не так...Выбрали не существующую строчку меню');
        end
        
        switch handles.ParMenu4.Value       % метрика
            
            case 1
                ProcessParameters.Metric = 'SAD';                
            case 2
                ProcessParameters.Metric = 'SSD';
            otherwise
                assert(0,'Что то пошло не так...Выбрали не существующую строчку меню');
        end               
        
    case {'Создание 3D-изображения','3-D image creation'}
        
    case {'Обработка видео','Video processing'}
        
    case {'Создание панорамы','Panorama creation'}
        
    case {'Распознавание движения','Motion detection'}
        
    otherwise
        assert(0, 'Ошибка в обращении к методам обработки');
        
end

%---------------------------------------------------------------------------------
% ПРОВОДИМ ОБРАБОТКУ В ЗАВИСИМОСТИ ОТ НАСТРОЕК ЭЛЕМЕНТОВ ИНТЕРФЕЙСА
ProcessResults = ComputerVisionProcessing(Image, ProcessParameters, IsRusLanguage);  
%---------------------------------------------------------------------------------

% сохраняем и используем полученные данные                        
setappdata(handles.KAACVP,'LABEL',ProcessResults.LABEL);
setappdata(handles.KAACVP,'Boxes',ProcessResults.Boxes);
setappdata(handles.KAACVP,'ImagesToShow',ProcessResults.ImagesToShow.Images);  

% если образец не пустой он появится о осях
image(ProcessResults.NewPattern,'Parent',handles.PatternAxes);
handles.PatternAxes.Visible = 'off';

handles.StatisticsList.String = string(ProcessResults.StatisticsString);    
handles.ImagesToShowMenu.String = string(ProcessResults.StringOfImages);

% если отображать нужно лишь оригинал, прячем выпадающий список
if length(ProcessResults.StringOfImages) == 1
    handles.ImagesToShowMenu.Visible = 'off';
else
    handles.ImagesToShowMenu.Visible = 'on';
end

% если в результатах обработки нет списка данных - прячем интерфейсный список
if isempty(ProcessResults.StatisticsString)
    handles.StatisticsList.Visible = 'off';
else
    handles.StatisticsList.Visible = 'on';
end

% если картинка, то пусть сразу будет виден результат
if ~UserFile.IsVideo
    handles.ImagesToShowMenu.Value = length(ProcessResults.StringOfImages);
else    % для видео пользователь сам решает
end

% вызов прорисовки интерфейса
StatisticsList_Callback(hObject, eventdata, handles);   
ImagesToShowMenu_Callback(hObject, eventdata, handles);

DoyouWantToBlockInterface(false, handles, UserFile.IsVideo);

%---------------------------------------------------------------------------------

% УВЕЛИЧЕНИЕ РАЗМЕРА ИЗОБРАЖЕНИЙ/ВИДЕО ПОД РАЗМЕР ОСИ
function ZoomButton_Callback(~, ~, handles)

UserFile = getappdata(handles.KAACVP,'UserFile');
Pattern = getappdata(handles.KAACVP,'Pattern');

% если надо уменьшить    
if handles.ZoomButton.Value == 0    
    
    % меняем картинку кнопки зума
    try
        handles.ZoomButton.CData = imread([cd '\Icons\Zoom+.png']);
    catch
        handles.ZoomButton.String = '+';
    end
    
    % запускаем изменение размеров оси
    SetNewAxesPosition(handles.FileAxes, UserFile.Height, UserFile.Width);
    
    if ~isempty(Pattern)    % если есть изображените - образец
        
        % изменяем размер его оси
        SetNewAxesPosition(handles.PatternAxes, size(Pattern,1), size(Pattern,2));
    end
    
else        % увеличить надо оси размер
     
    try
        handles.ZoomButton.CData = imread([cd '\Icons\Zoom-.png']);
    catch
        handles.ZoomButton.String = '-';
    end
    
    % ОСНОВНАЯ ОСЬ
    % считываем начальный размер, выделенный для оси
    FileAxesPosition = getappdata(handles.FileAxes,'InitPosition');
    
    % считаем величину масштабирования
    MinImageToAxesSideRation = min( UserFile.Height/FileAxesPosition(4),...
                                    UserFile.Width/FileAxesPosition(3));
    
    % считаем новые размеры оси
    NewHeight = UserFile.Height / MinImageToAxesSideRation;  
    NewWidth =  UserFile.Width  / MinImageToAxesSideRation;
    
    % запускаем изменение размеров оси
    SetNewAxesPosition(handles.FileAxes, NewHeight, NewWidth);     
    
    % ОСЬ ОБРАЗЦА    
    if ~isempty(Pattern)    % если образец есть
        
        % считываем начальный размер, выделенный для оси
        PatternAxesPosition = getappdata(handles.PatternAxes,'InitPosition');
        
        % считаем величину масштабирования
        MinImageToAxesSideRation = min( size(Pattern,1)/PatternAxesPosition(4),...
                                        size(Pattern,2)/PatternAxesPosition(3));
    
        % выбираем минимум, на который можем растянуть габариты и считаем их
        NewHeight = size(Pattern,1) / MinImageToAxesSideRation;        
        NewWidth = size(Pattern,2) / MinImageToAxesSideRation;
        
        % запускаем изменение размеров оси
        SetNewAxesPosition(handles.PatternAxes, NewHeight, NewWidth);
    end
        
end


% ВЫБОР ОБЛАСТИ ИНТЕРЕСА
function ROIButton_Callback(hObject, eventdata, handles)

% удаляем старую рамку ROI в оси: она всегда пунктирная
delete(findobj('Parent',handles.FileAxes,'LineStyle','--'));

UserFile = getappdata(handles.KAACVP,'UserFile');

% если не пользователь нажал на кнопку ROI
if hObject ~= handles.ROIButton 
    assert(0 , [get(hObject,'Tag') ' вызвал ROI кнопку!']); 
end
    
% даем пользователю с помощью imrect выбрать ROI и считываем координаты
ROI =  imrect(handles.FileAxes);
ROIPosition = round(getPosition(ROI));

% удаляем созданный интерактивный объекта imrect
delete(ROI);

% пересчитваем координаты углов ROI из позиции ROI
X0Y0X1Y1Coords = [  ROIPosition(1) ROIPosition(2)...
                    ROIPosition(1) + ROIPosition(3)...
                    ROIPosition(2) + ROIPosition(4)];

% ограничиваем координаты ROI при выходе за пределы размеров изображения
Limits = [1 1 UserFile.Width UserFile.Height];
AreTopLimits = [false false true true];

% уточненные X0Y0X1Y1Coords и ROIPosition 
X0Y0X1Y1Coords = LimitCheck(X0Y0X1Y1Coords, Limits, AreTopLimits);
ROIPosition(3) = X0Y0X1Y1Coords(3) - X0Y0X1Y1Coords(1);
ROIPosition(4) = X0Y0X1Y1Coords(4) - X0Y0X1Y1Coords(2);

% обновили значения и тектовые стркои полей
handles.ROIx0.String = num2str(X0Y0X1Y1Coords(1));
handles.ROIy0.String = num2str(X0Y0X1Y1Coords(2));
handles.ROIx1.String = num2str(X0Y0X1Y1Coords(3));
handles.ROIy1.String = num2str(X0Y0X1Y1Coords(4));

handles.ROIx0.Value = X0Y0X1Y1Coords(1);
handles.ROIy0.Value = X0Y0X1Y1Coords(2);
handles.ROIx1.Value = X0Y0X1Y1Coords(3);
handles.ROIy1.Value = X0Y0X1Y1Coords(4);

% обновляем ROI / образец
RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);
    

% ОТКРЫТЬ ШАБЛОН
function PatternOpenButton_Callback(~, ~, handles)

IsRusLanguage = IsFigureLanguageRussian(handles);

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod
    
    case {'Распознавание объектов','Object detection'}

        Pattern = OpenPatternImage(IsRusLanguage);

        if isempty(Pattern)
            return;
        end
        
        % размещаем откытую картинку
        image(Pattern, 'Parent',handles.PatternAxes);
        handles.PatternAxes.Visible = 'off';
        
        % сохраняем ее
        setappdata(handles.KAACVP, 'Pattern',Pattern); 
        
        % в зависимоти от статуса кнопки зума изменится размер оси
        ZoomButton_Callback([], [], handles);
        
        handles.ShowPatternImageMenu.Visible = 'on';    
        
        % открыв шаблон мы не можем менять его координаты ROI
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

% СЛАЙДЕР ФОРМИРУЕТ СТРУКТУРУ ОТОБРАЖАЕМЫХ ИЗОБРАЖЕНИЙ 
% И ЗАПУСКАЕТ ОТОБРАЖЕНИЕ, ОБНОВЛЯЕТ СЧЕТЧИК КАДРОВ И ВРЕМЕНИ

UserFile = getappdata(handles.KAACVP,'UserFile');

FrameNumber = round(handles.FrameSlider.Value); % считываем номер кадра
handles.FrameSlider.Value = FrameNumber;        % запоминаем уточненное значение в слайдере
    
if handles.ApplyButton.Value == 1           % если "применяется" обработка 
    
    ApplyButton_Callback(hObject, eventdata, handles); % новые изорбражения сформируются там
    
else    % без обработки           

    % считываем текущий кадр в структуру ImagesToShow
    ImagesToShow(1).Images = UserFile.Multimedia(FrameNumber).Frame;
    
    % и сохраняем структуру
    setappdata(handles.KAACVP,'ImagesToShow',ImagesToShow);
    
    % удаляем старые граф объекты из осей
    delete(findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b'));
    
    % установка меню отображения и списка
    handles.ImagesToShowMenu.Value = 1;
    handles.ImagesToShowMenu.String = ' ';
    handles.ImagesToShowMenu.Visible = 'off';
    handles.StatisticsList.Visible = 'off';
    
end

% отобразили изображение
ShowMultimediaFile(handles);
    
% прописываем кадр и время только для видео
if UserFile.IsVideo
    ShowTimeAndFrame(handles, UserFile.FrameRate, FrameNumber);         
end


% СЛАЙДЕР ПАРАМЕТРОВ № 1
function ParSlider1_Callback(hObject, eventdata, handles)

ParSlider1Value = handles.ParSlider1.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod
    
    case {'Распознавание текста','Optical character recognition'}
        ParSlider1Value = round(ParSlider1Value*100)/100;
        
    case {  'Анализ пятен','Blob analysis',...
            'Создание 3D-изображения','3-D image creation'}   
        ParSlider1Value = round(ParSlider1Value);
    
    case {'Распознавание объектов','Object detection'}    
        ParSlider1Value = round(ParSlider1Value*100)/100;
        
    case {'Распознавание лиц','Face detection'}
        
        % регулируем пределы слайдероов, чтобы пользователь
        % не смог установить максимальную область меньше минимальной
        
        ParSlider1Value = round(ParSlider1Value);
        
        % если слайдеры уперлись друг в друга
        % заблокируем тот, у которого предел достигнут
        % иначе просто изменим предел другого слайдера
        
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
        assert(0,'в ParSlider1 вызвана несуществующая строка из меню методов');
        
        
end

handles.ParSlider1.Value = ParSlider1Value;
handles.ParSliderValueText1.String = num2str(ParSlider1Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 2
function ParSlider2_Callback(hObject, eventdata, handles)

ParSlider2Value = handles.ParSlider2.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));
ParMenu3Method = string(handles.ParMenu3.String( handles.ParMenu3.Value ));

switch ComputerVisionMethod        
    
    case {'Анализ пятен','Blob analysis'}   
        ParSlider2Value = round(ParSlider2Value);
        
    case {'Распознавание объектов','Object detection'}    
        
        
        switch ParMenu3Method  % тип детектора
            
            case {'MSER'}             
                ParSlider2Value = round(ParSlider2Value);
                
            case {'BRISK', 'FAST', 'Харриса', 'Harris',...
                  'Минимального собственного значения', 'Minimum eigen'}
              
                ParSlider2Value = round(ParSlider2Value*100)/100;
                
            case {  'SURF (размер дескриптора 64)',...
                    'SURF (размер дескриптора 128)',...
                    'SURF (64 descriptor size)',...
                    'SURF (128 descriptor size)'}
                
                ParSlider2Value = round(ParSlider2Value/100)*100;
                    
            otherwise
                assert(0,'в ParSlider2 вызвана несуществующая строка из меню детекторов');       
        end                
    
        
    case {'Распознавание лиц','Face detection'}
        
        % регулируем пределы слайдероов, чтобы пользователь
        % не смог установить максимальную область меньше минимальной
        
        ParSlider2Value = round(ParSlider2Value);
        
        % если слайдеры уперлись друг в друга
        % заблокируем тот, у которого предел достигнут
        % иначе просто изменим предел другого слайдера
        
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
        
    case {'Создание 3D-изображения','3-D image creation'}
        
        ParSlider2Value = round(ParSlider2Value * 100) / 100;
        
    otherwise
        assert(0,'в ParSlider2 вызвана несуществующая строка из меню методов');        
end

handles.ParSlider2.Value = ParSlider2Value;
handles.ParSliderValueText2.String = num2str(ParSlider2Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 3
function ParSlider3_Callback(~, ~, handles)

ParSlider3Value = handles.ParSlider3.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));
ParMenu3Method = string(handles.ParMenu3.String( handles.ParMenu3.Value ));

switch ComputerVisionMethod
        
    case {'Анализ пятен','Blob analysis'}   
        ParSlider3Value = round(ParSlider3Value);
        
    case {'Создание 3D-изображения','3-D image creation'}  
        ParSlider3Value = round(ParSlider3Value * 1000) / 1000;
    
    case {'Распознавание объектов','Object detection'} 
        
        switch ParMenu3Method  % тип детектора
            
            case {'MSER'}    
                
                % регулируем пределы слайдероов, чтобы пользователь
                % не смог установить максимальную область меньше минимальной
                
                ParSlider3Value = round(ParSlider3Value);   
                
                % если слайдеры уперлись друг в друга
                % заблокируем тот, у которого предел достигнут
                % иначе просто изменим предел другого слайдера
                
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
                    'SURF (размер дескриптора 64)',...
                    'SURF (размер дескриптора 128)',...
                    'SURF (64 descriptor size)',...
                    'SURF (128 descriptor size)'}
                
                ParSlider3Value = round(ParSlider3Value);
                
            case {'Харриса', 'Harris',...
                  'Минимального собственного значения', 'Minimum eigen'}
              
                ParSlider3Value = round(ParSlider3Value);
                ParSlider3Value = ParSlider3Value - 1 + mod(ParSlider3Value,2);
                          
            otherwise
                assert(0,'в ParSlider3 вызвана несуществующая строка из меню детекторов');
                
        end     % switch ParMenu3Method
           
                
    case {'Распознавание лиц','Face detection'}
        
        % регулируем пределы слайдероов, чтобы пользователь
        % не смог установить максимальную область меньше минимальной
        
        ParSlider3Value = round(ParSlider3Value);
        
        % если слайдеры уперлись друг в друга
        % заблокируем тот, у которого предел достигнут
        % иначе просто изменим предел другого слайдера
        
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
        assert(0,'в ParSlider3 вызвана несуществующая строка из меню методов');
        
end             % switch ComputerVisionMethod

handles.ParSlider3.Value = ParSlider3Value;
handles.ParSliderValueText3.String = num2str(ParSlider3Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 4
function ParSlider4_Callback(~, ~, handles)

ParSlider4Value = handles.ParSlider4.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));
ParMenu3Method = string(handles.ParMenu3.String( handles.ParMenu3.Value ));

switch ComputerVisionMethod
        
    case {'Анализ пятен','Blob analysis'}   
        ParSlider4Value = round(ParSlider4Value*100)/100;
        
    case {'Создание 3D-изображения','3-D image creation'}  
        ParSlider4Value = round(ParSlider4Value);
        
    case {'Распознавание объектов','Object detection'}
        
        switch ParMenu3Method   % тип детектора            
                
            case {'MSER'}
                
                % регулируем пределы слайдероов, чтобы пользователь
                % не смог установить максимальную область меньше минимальной
                
                ParSlider4Value = round(ParSlider4Value);   
                
                % если слайдеры уперлись друг в друга
                % заблокируем тот, у которого предел достигнут
                % иначе просто изменим предел другого слайдера
                
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
                
            case {  'SURF (размер дескриптора 64)',...
                    'SURF (размер дескриптора 128)',...
                    'SURF (64 descriptor size)',...
                    'SURF (128 descriptor size)'}
                
                ParSlider4Value = round(ParSlider4Value);
                
             otherwise
                 assert(0,'в ParSlider4 вызвана несуществующая строка из меню методов');
                 
        end            
        
                
    case {'Распознавание лиц','Face detection'}
       
        % регулируем пределы слайдероов, чтобы пользователь
        % не смог установить максимальную область меньше минимальной
        
        ParSlider4Value = round(ParSlider4Value);
        handles.ParSlider4.Value = ParSlider4Value;
        
        % если слайдеры уперлись друг в друга
        % заблокируем тот, у которого предел достигнут
        % иначе просто изменим предел другого слайдера
        
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
        assert(0,'в ParSlider4 вызвана несуществующая строка из меню методов');
        
end

handles.ParSlider4.Value = ParSlider4Value;
handles.ParSliderValueText4.String = num2str(ParSlider4Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 5
function ParSlider5_Callback(hObject, eventdata, handles)

ParSlider5Value = handles.ParSlider5.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod        
           
    case {  'Распознавание объектов','Object detection',...
            'Создание 3D-изображения','3-D image creation'}
        
        ParSlider5Value = round(ParSlider5Value);
        
    case {'Распознавание лиц','Face detection'}
        ParSlider5Value = round(ParSlider5Value*10000)/10000;
        
    otherwise
        assert(0,'в ParSlider5 вызвана несуществующая строка из меню методов');
        
end

handles.ParSlider5.Value = ParSlider5Value;
handles.ParSliderValueText5.String = num2str(ParSlider5Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 6
function ParSlider6_Callback(hObject, eventdata, handles)

ParSlider6Value = handles.ParSlider6.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod        
           
    case {  'Распознавание объектов','Object detection',...
            'Создание 3D-изображения','3-D image creation'}
        
        ParSlider6Value = round(ParSlider6Value*100)/100;
        
    case {'Распознавание лиц','Face detection'}
        ParSlider6Value = round(ParSlider6Value);
        
    otherwise
        assert(0,'в ParSlider6 вызвана несуществующая строка из меню методов');
        
end

handles.ParSlider6.Value = ParSlider6Value;
handles.ParSliderValueText6.String = num2str(ParSlider6Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 7
function ParSlider7_Callback(hObject, eventdata, handles)

ParSlider7Value = handles.ParSlider7.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod        
           
    case {'Распознавание объектов','Object detection'}
        ParSlider7Value = round(ParSlider7Value/10)*10;
        
    case {'Создание 3D-изображения','3-D image creation'}
        ParSlider7Value = round(ParSlider7Value);        
        
    otherwise
        assert(0,'в ParSlider7 вызвана несуществующая строка из меню методов');
        
end

handles.ParSlider7.Value = ParSlider7Value;
handles.ParSliderValueText7.String = num2str(ParSlider7Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 8
function ParSlider8_Callback(hObject, eventdata, handles)

ParSlider8Value = handles.ParSlider8.Value;
 
ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod        
           
    case {'Распознавание объектов','Object detection'}
        ParSlider8Value = round(ParSlider8Value*100)/100;
        
    case {'Создание 3D-изображения','3-D image creation'}
        ParSlider8Value = round(ParSlider8Value);
        
    otherwise
        assert(0,'в ParSlider8 вызвана несуществующая строка из меню методов');
        
end

handles.ParSlider8.Value = ParSlider8Value;
handles.ParSliderValueText8.String = num2str(ParSlider8Value);


% СЛАЙДЕР ПАРАМЕТРОВ № 9
function ParSlider9_Callback(hObject, eventdata, handles)

ParSlider9Value = handles.ParSlider9.Value;

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod        
           
    case {  'Распознавание объектов','Object detection',...
            'Создание 3D-изображения','3-D image creation'}
        
        ParSlider9Value = round(ParSlider9Value);
        
    otherwise
        assert(0,'в ParSlider9 вызвана несуществующая строка из меню методов');
end

handles.ParSlider9.Value = ParSlider9Value;
handles.ParSliderValueText9.String = num2str(ParSlider9Value);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% СПИСКИ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% СПИСОК СТАТИСТИКИ ПО ИЗОБРАЖЕНИЮ
function StatisticsList_Callback(~, ~, handles)

ChosenString = handles.StatisticsList.Value;

% находим отрисованную графическую фигуру в оси,
% которая показывает найденную информацию на изображении и
% которая всегда имеет штрих-пунктирную линию и синий цвет 
GraphObject = findobj('Parent',handles.FileAxes,'LineStyle','-.','EdgeColor','b');

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod
    
    case {'Распознавание текста','Optical character recognition'}        
        
        % считываем координаты областей найденного тектса
        FoundTextBoxesCoords = getappdata(handles.KAACVP,'Boxes');
        if isempty(FoundTextBoxesCoords)
            return;
        end
        
        % создаем или обновляем графический объект
        if isempty(GraphObject)
                
            rectangle(  'Position',FoundTextBoxesCoords(ChosenString, :),...
                        'Parent',handles.FileAxes,...
                        'EdgeColor','b',...
                        'LineStyle','-.',...
                        'LineWidth',2);
        else                   
            set(GraphObject, 'Position', FoundTextBoxesCoords(ChosenString,:));            
        end
        
    case {'Анализ пятен','Blob analysis'}
        
        % считываем разметку пятен
        LABEL = getappdata(handles.KAACVP,'LABEL');
        if isempty(LABEL)
            return;
        end
        
        % создаем или обновляем графический объект
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%% ТЕКСТОВЫЕ ПОЛЯ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ОТКЛИКИ ПОЛЕЙ ОБЛАСТИ ИНТЕРЕСА
function ROIedit_Callback(hObject, eventdata, handles)

UserFile = getappdata(handles.KAACVP,'UserFile');

IsRusLanguage = strcmp(handles.RussianLanguageMenu.Checked,'on');

ROIeditValue = str2double(get(hObject,'String'));  

% если не число, генерируем ошибку
if isnan(ROIeditValue)    
    
    GenerateError('ShouldBeDigits', IsRusLanguage);   
    
    % вставляем в поле предыдущее корректное число
    set(hObject,'String',num2str( get(hObject,'Value') ));    
    return;
    
end

ROIeditValue = round(ROIeditValue);

% находим максимум и минимум для изменяемой величины
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

% при выходе за пределы присваиваем предельное значение
if ROIeditValue < MinValue     
    ROIeditValue = MinValue;
    
elseif ROIeditValue > MaxValue
    ROIeditValue = MaxValue;
end

% обязательно сохраняем установленное число в свойство 'Value' поля,
% чтобы можно было его затем использовать при некорректном вводе пользователя
set(hObject,'String',num2str(ROIeditValue),'Value',ROIeditValue);

% обновляем ROI / образец
ROI_X0 = round(str2double(handles.ROIx0.String));
ROI_X1 = round(str2double(handles.ROIx1.String));
ROI_Y0 = round(str2double(handles.ROIy0.String));
ROI_Y1 = round(str2double(handles.ROIy1.String));

ROIPosition = [ROI_X0 ROI_Y0 ROI_X1-ROI_X0 ROI_Y1-ROI_Y0];
X0Y0X1Y1Coords = [ROI_X0 ROI_Y0 ROI_X1 ROI_Y1];

RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition);



% ОТКЛИКИ ВСЕХ ПОЛЕЙ ЗНАЧЕНИЙ СЛАЙДЕРОВ
function SliderEdit_Callback(hObject, eventdata, handles)

% отлик поля ввода позволяет менять значения параметра обработки 
% напрямую без слайдера.
% все слайдера и поля имеют одинаковые имена 
% ParSlider1...ParSlider9  и ParSliderValueText1 ...ParSliderValueText9
% поэтому для всех полей один отклик
% Необходимо проверить значение на ввод только чисел
% Если проверка провалится - информировать пользователя и вернуть старое значение
% старое значение содержится в слайдере

ParEditValue = str2double(get(hObject,'String'));  

IsRusLanguage = strcmp(handles.RussianLanguageMenu.Checked,'on');

% получаем имя поля из ParSliderValueText№
EditTag = strsplit( get(hObject,'Tag') , 'ValueText');

% вырезаем имя ответственного слайдера, получая ParSlider№
SliderTag = [EditTag{1} EditTag{2}];                    

% если не число - ошибка
if isnan(ParEditValue)                             
    
    GenerateError('ShouldBeDigits', IsRusLanguage); 
    
    % вставляем в поле значение из слайдера
    set(hObject,'String',num2str( get(eval(['handles.' SliderTag]) , 'Value')));
    return;
end

% считываем параметры ответственного слайдера
MaxValue = get(eval(['handles.' SliderTag]),'Max');
MinValue = get(eval(['handles.' SliderTag]),'Min');
SliderStep = get(eval(['handles.' SliderTag]),'SliderStep');

% для корректного указания введенного значения 
% вычислим до какого знака округляет слайдер
RoundOrder = SliderStep(1) * (MaxValue - MinValue);

% округлил в соответствие слайдеру 
ParEditValue = round(ParEditValue / RoundOrder) * RoundOrder;     

% при выходе за пределы присваиваем предельное значение
if ParEditValue < MinValue     
    ParEditValue = MinValue;
    
elseif ParEditValue > MaxValue
    ParEditValue = MaxValue;
end

% обновляем поле и слайдер
set(hObject,'String',num2str(ParEditValue));            
set(eval(['handles.' SliderTag]),'Value',ParEditValue);

% обновляем интерфейс слайдера
eval([SliderTag '_Callback(hObject, eventdata, handles)']);


%%%%%%%%%%%%%%%%%%%%%%%%%%%% ЧЕК-БОКСЫ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function ParCheckBox1_Callback(hObject, eventdata, handles)

IsRusLanguage = IsFigureLanguageRussian(handles);

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod
    
    case {'Анализ пятен','Blob analysis'}
        
        if handles.ParCheckBox1.Value
            handles.ParCheckBox1.TooltipString = ReturnRusOrEngString(IsRusLanguage,...
                    'Включая граничные пятна', 'Including border blobs');
        else
            handles.ParCheckBox1.TooltipString = ReturnRusOrEngString(IsRusLanguage,...
                    'Исключая граничные пятна', 'Excluding border blobs');
        end
end


function ParCheckBox2_Callback(hObject, eventdata, handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ФУНКЦИИ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ПРОПИСЫВАЕТ СТРОЧКИ С КАДРОМ И ТЕКУЩИМ ВРЕМЕНЕМ ВИДЕО
function ShowTimeAndFrame(handles, FrameRate, FrameNumber)

% handles - массив указателей приложения
% FrameRate - скорость воспроизведения видео
% FrameNumber - номер текущего кадра

assert(isstruct(handles),'Передана не структура элементов интерфейса');
assert(isnumeric(FrameRate) && isnumeric(FrameNumber),...
    'FrameRate и FrameNumber - не числовые параметры');

% делаем целым для страховки
FrameNumber = round(FrameNumber);               

sec = mod(FrameNumber / FrameRate, 60);
min = (FrameNumber / FrameRate - sec) / 60;
sec = round(sec);

% делаем 59 сек крайними, а не 60        
if sec == 60            
    sec = 0;
    min = min + 1;
end

handles.VideoTimeInfo.String = [sprintf('%02d',min) ':' sprintf('%02d',sec)];
handles.VideoFrameInfo.String = [num2str(FrameNumber) ' кадр'];


% НАСТРАИВАЕТ РАЗМЕР ОСИ ПОД ВИДЕО/ИЗОБРАЖЕНИЕ
function SetNewAxesPosition(Axes, ImageHeight, ImageWidth)

% Axes - ось, в которую вставляем кадр/изорбажение
% ImageHeight, ImageWidth - габариты кадра/изорбажения  

assert(isappdata(Axes, 'InitPosition'), 'Axes указана не верно');
assert(isnumeric(ImageHeight), 'Height - не число');
assert(isnumeric(ImageWidth), 'Width - не число');

% вычислим максимум из соотношений сторон изображения к сторонам осей
MaxImageToAxesSideRation = GetMaxImageToAxesSideRation(Axes, ImageHeight, ImageWidth);
        
% считываем начальный размер, выделенный для оси
InitAxesPosition = getappdata(Axes,'InitPosition'); 

% если изображение не влезает в ось - урезаем его
if MaxImageToAxesSideRation > 1
    
    AxesNewWidth = ImageWidth / MaxImageToAxesSideRation ;
    AxesNewHeight = ImageHeight / MaxImageToAxesSideRation ;
else
    AxesNewWidth = ImageWidth;
    AxesNewHeight = ImageHeight;
end

% новая позиция отцентрированной оси
NewAxesPosition = [...
            InitAxesPosition(1) + floor((InitAxesPosition(3) - AxesNewWidth)/2)...
            InitAxesPosition(2) + floor((InitAxesPosition(4) - AxesNewHeight)/2)...
            AxesNewWidth...
            AxesNewHeight];

set(Axes, 'Position', NewAxesPosition);

 
% СЧИТАЕТ МАКСИМУМ ИЗ СООТНОШЕНИЙ СТОРОН ИЗОБРАЖЕНИЯ К СТОРОНАМ ОСЕЙ
function MaxImageToAxesSideRation = GetMaxImageToAxesSideRation(Axes, ImageHeight, ImageWidth)

assert(isappdata(Axes, 'InitPosition'), 'Axes указана не верно');
assert(isnumeric(ImageHeight), 'Height - не число');
assert(isnumeric(ImageWidth), 'Width - не число');

InitAxesPosition = getappdata(Axes,'InitPosition'); 

MaxImageToAxesSideRation = max( ImageWidth / InitAxesPosition(3),...
                                ImageHeight / InitAxesPosition(4));

assert(isfloat(MaxImageToAxesSideRation), 'Возвращает не дубль-число');
assert(isscalar(MaxImageToAxesSideRation), 'Возвращает вектор!');


% НАСТРАИВАЕТ СПИСОК МЕТОДОВ ОБРАБОТКИ
function SetCVMethodMenuList(handles, IsVideo, IsRusLanguage)

% handles.CVMethodMenu - настраиваемая менюшка
% VideoOpened - если открыто видео - тогда истина
% IsRusLanguage - если 1, тогда русский язык стоит

assert(isstruct(handles),'Передана не структура элементов интерфейса');
assert(isfield(handles,'CVMethodMenu'),'В переданном handles нет меню методов');
assert(islogical(IsVideo),'Флаг видео не логический');
assert(islogical(IsRusLanguage),'Флаг языка не логический');

if IsVideo          % для открытого видео-файла
    
    if IsRusLanguage              % на русском
        
        set(handles.CVMethodMenu,'String',{...
            'Распознавание текста';...
            'Чтение штрих-кода';...
            'Поиск областей с текстом';...
            'Анализ пятен';...
            'Распознавание лиц';...
            'Распознавание людей';...
            'Распознавание объектов';...
            'Обработка видео';...
            'Создание панорамы';...
            'Распознавание движения';...
            });       
        
    else                % на английском 
        
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
        
else                    % если открыто изображение
    if IsRusLanguage          % на русском
        
        set(handles.CVMethodMenu,'String',{...
            'Распознавание текста';...
            'Чтение штрих-кода';...
            'Поиск областей с текстом';...
            'Анализ пятен';...
            'Распознавание лиц';...
            'Распознавание людей';...
            'Распознавание объектов';...
            'Создание 3D-изображения';...
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
    

% ЛИМИТИРУЕТ CheckValue ПРИ ВЫХОДЕ ЗА ПРЕДЕЛ Limit
function CorrectValue = LimitCheck(CheckValue, Limit, IsTopLimit)

% CheckValue - проверяемое число
% Limit - предел
% IsTopLimit = true - предел сверху
% IsTopLimit = false - предел снизу
% CorrectValue - откорректированное значение в соответствии с пределом

assert(isnumeric([CheckValue Limit]), 'Value не числовой');            
assert(islogical(IsTopLimit),'Upper не логический');            
assert(isequal(size(CheckValue), size(Limit), size(IsTopLimit)),...
                'Размерности входных данных не равны');

% значение по умолчанию
CorrectValue = CheckValue;

for x = 1:length(CheckValue)         % по всему списку координат пройдемся
    
    if IsTopLimit(x)                	% предел сверху
        
        if CheckValue(x) > Limit(x)  % если выше предела -> значение = пределу
            CorrectValue(x) = Limit(x);
        end
    else                        % предел снизу
        
        if CheckValue(x) < Limit(x)
            CorrectValue(x) = Limit(x);
        end
    end
end

assert(isnumeric(CheckValue),'CheckValue на выходе - не число');
    
    
% ФУНКЦИЯ ОТРЫТИЯ ФАЙЛА    
function UserFile = OpenMultimediaFile(IsRusLanguage)

assert(islogical(IsRusLanguage),'Флаг языка не логический');

UserFile = [];          % создаем пустой файл для возврата в случае ошибок

% выбираем файл для открытия
if IsRusLanguage
    
    [FileName, PathName] = uigetfile(...
        {'*.*', 'All Files(*.*)';...
        '*.avi;*,mj2;*.mpg;*.mp4;*.m4v;*.mov;*.wmv;*.ogg;*.asf;*.asx',...
        'Видео (*.avi,*.mj2,*.mpg,*.mp4,*.m4v,*.mov,*.wmv,*.ogg,*.asf,*.asx)';...
        '*.jpeg;*.jpg;*.tif;*.tiff;*.bmp;*.png',...
        'Изображения (*.jpeg,*.jpg,*.tif,*.tiff,*.bmp,*.png)'},...
        'Выберите файл для обработки',...
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

if ~FileName        % Проверка, был ли выбран файл
    return;
end

try         % пробуем открыть как видеофайл
    
    % видеообъект
    VideoObject = VideoReader([PathName FileName]);

    % создаем структуру для видео
    UserFile = struct(  'Multimedia',[],...
                        'FrameRate',[],...
                        'IsVideo',[],...
                        'Width',[],...
                        'Height',[],...
                        'NumOfChannels',[]); 
    
    % задаем размер кадра            
    UserFile.Multimedia.Frame = zeros(size(readFrame(VideoObject)));  
    
    FrameNumber = 1;                                % счетчик кадров
    NumOfFrames = round(VideoObject.Duration * VideoObject.FrameRate);
    
    if IsRusLanguage     % язык
        Wait = waitbar(0,'Загрузка видео','WindowStyle','modal');
    else
        Wait = waitbar(0,'Loading','WindowStyle','modal');
    end

    while hasFrame(VideoObject)                        
        UserFile.Multimedia(FrameNumber).Frame = im2double(readFrame(VideoObject));
        FrameNumber = FrameNumber+1;                         
        waitbar(FrameNumber / NumOfFrames, Wait);            
    end    
      
    delete(Wait);       
    
catch       % не смогли открыть видеофайл
    
    if exist('Wait','var')          % если пользователь закрыл окно загрузки
        delete(Wait);               % удаляем окно
        return;                     % выходим отсюда
    end
    
    try     % пробуем открыть как изображение
        
        [Temp,colors] = imread([PathName FileName]);      
        
        if ~isempty(colors)                 % если индексированное -
            Temp = ind2rgb(Temp,colors);    % переводим индексированное в RGB
        end 
        
        % создаем структуру для изображения без частоты кадров
        UserFile = struct(  'Multimedia',[],...
                            'IsVideo',[],...
                            'Width',[],...
                            'Height',[],...
                            'NumOfChannels',[]); 
                    
        if size(Temp,3) > 3     % если многоканальное изображение
            UserFile.Multimedia.Frame = im2double(Temp(:,:,1:3));    % берем первые 3 канала
        else
            UserFile.Multimedia.Frame = im2double(Temp);        % иначе берем все
        end
        
        % тестируем открываемое изображение
        CheckImage(UserFile.Multimedia.Frame);

    catch    % оба варианты открытия провалились
        
        GenerateError('MultimediaFileOpenningFailed', IsRusLanguage);
        return;                
    end
end

% запоминаем свойства
UserFile.Height = size(UserFile.Multimedia(1).Frame, 1);
UserFile.Width = size(UserFile.Multimedia(1).Frame, 2);
UserFile.NumOfChannels = size(UserFile.Multimedia(1).Frame, 3);

if size(UserFile.Multimedia,2) > 1                 % если видео
    UserFile.IsVideo = true;
    UserFile.FrameRate = VideoObject.FrameRate;   
else    
    UserFile.IsVideo = false;  
end


% ФУНКЦИЯ ОТКРЫТИЯ ОБРАЗЦОВОГО ИЗОБРАЖЕНИЯ
function Pattern = OpenPatternImage(IsRusLanguage)

assert(islogical(IsRusLanguage),'Флаг языка не логический');

Pattern = [];   % пустой возврат

% выбираем файл для открытия
if IsRusLanguage
    
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
    
    if size(Temp,3) > 3
        Pattern = im2double(Temp(:,:,1:3));    % запиливаем картинку
    else
        Pattern = im2double(Temp);    % запиливаем картинку
    end
    
    % тестируем открываемое изображение
    CheckImage(Pattern);
    
catch    % открытие провалились
    
    GenerateError('MultimediaFileOpenningFailed', IsRusLanguage);
end


% ВОЗВРАЩАЕТ ФЛАГ УСТАНОВКИ РУССКОГО ЯЗЫКА
function IsRusLanguage = IsFigureLanguageRussian(handles)

% вернет true, если установлен русский язык
IsRusLanguage = strcmp(handles.RussianLanguageMenu.Checked,'on');

    
% СОХРАНЯЕТ ДАННЫЕ В ФАЙЛ-ИЗОБРАЖЕНИЕ
function SaveImage(Image, FrameNumber, IsRusLanguage)

assert(islogical(IsRusLanguage),'Флаг языка не логический');
assert(isinteger(FrameNumber),'FrameNumber - не целочисленный параметр');
CheckImage(Image);

if IsRusLanguage    % по языку    
    [FileName, PathName] = uiputfile(['кадр № ' num2str(FrameNumber) '.png'],'Сохранить кадр/изображение');
else
    [FileName, PathName] = uiputfile(['frame № ' num2str(FrameNumber) '.png'],'Save frame/image');
end

if FileName~=0
    imwrite(Image,[PathName FileName]);
end    
    

% ФУНКЦИЯ ОБРАБОТКИ ИЗОБРАЖЕНИЯ/КАДРА
function ProcessResults = ComputerVisionProcessing(Image, ProcessParameters, IsRusLanguage)

assert(islogical(IsRusLanguage),'Флаг языка не логический');
assert(isstruct(ProcessParameters), 'ProcessParameters - не структура');
assert(~isempty(ProcessParameters), 'Передана пустая структура параматеров обработки');
CheckImage(Image);

ProcessResults = struct();

% заполняю 1ое изображение и 1ю строку списка промежуточных результатов
ImagesToShow = struct('Images',Image);   
StringOfImages = ReturnRusOrEngString(IsRusLanguage, 'Оригинал', 'Original image');

% создаем пустышки для выходных аргументов 
NewPattern = [];     
Boxes = []; 
StatisticsString = []; 
LABEL = [];

% использую компактную форму записи
X0 = ProcessParameters.X0;
X1 = ProcessParameters.X1;
Y0 = ProcessParameters.Y0;
Y1 = ProcessParameters.Y1;      

% в зависимости от метода обработки - обрабатываю
switch ProcessParameters.ComputerVisionMethod
    
    case {'Распознавание текста','Optical character recognition'}        
        
        results = ocr(  Image(Y0:Y1, X0:X1, :),...
                        'TextLayout',ProcessParameters.layout,...
                        'Language',ProcessParameters.lang);
        
        % найденный текст и его координаты 
        StatisticsString = results.Words;       
        Boxes = results.WordBoundingBoxes; 
        
        % убираем слабые результаты
        Boxes = Boxes(results.WordConfidences > ProcessParameters.thresh,:);    
        StatisticsString = StatisticsString(results.WordConfidences > ProcessParameters.thresh);
        
        % делаем координаты текста абсолютными для пользовательского файла
        Boxes(:,1) = Boxes(:,1) + X0;
        Boxes(:,2) = Boxes(:,2) + Y0;                          
        
        if isempty(StatisticsString)            
            StatisticsString = ReturnRusOrEngString(IsRusLanguage, 'нет результатов', 'no results');            
        end
        
    case {'Чтение штрих-кода','Barcode reading'} 
        
    case {'Поиск областей с текстом','Text region detection'}  
        
    case {'Анализ пятен','Blob analysis'} 
        
        if size(Image,3) > 1            
            GrayImage = rgb2gray(Image);
        else
            GrayImage = Image;
        end
        
        % если не ч/б, проведем бинаризацию
        if ~all( all( GrayImage == 0 | GrayImage == 1 ))    
            
            switch ProcessParameters.BinarizationType
                
                case {'Адаптивная', 'Adaptive'}      
                    
                    ImageBW = imbinarize(GrayImage,'adaptive',...
                                        'Sensitivity',ProcessParameters.SensOrThersh,...
                                        'ForegroundPolarity',ProcessParameters.Foreground);
                                    
                case {'Глобальная (Оцу)', 'Global (Otsu)'}                     
                    ImageBW = imbinarize(GrayImage);
                    
                case {'Глобальная', 'Global'}                       
                    ImageBW = imbinarize(GrayImage, ProcessParameters.SensOrThersh);   
                
                otherwise
                    assert(0, 'Выбран некорректный метод бинаризации');
            end
        end
        
        % задаем свойства объекта BlobAnalysis
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
        
        % получаем площадь, центр, периметр и разметку пятен
        [AREA,CENTEROID,PERIMETER,LABEL] = step(hBlob, logical(ImageBW)); 
        
        CENTEROID = round(CENTEROID);
        PERIMETER = round(PERIMETER);
                
        % создаем и заполняем список пятен
        StatisticsString = cell(1,size(AREA,1));
        
        for x = 1:size(AREA,1)
            
            StatisticsString{x} = ReturnRusOrEngString(IsRusLanguage,...
                                ['Пятно № ' num2str(x) ...
                                ': площадь / периметр = ' num2str(AREA(x))...
                                ' / ' num2str(PERIMETER(x)) ' (пикс.)'],...
                                ...
                                ['Blob № ' num2str(x) ...
                                ': area / perimeter = ' num2str(AREA(x))...
                                ' / ' num2str(PERIMETER(x)) ' (pix.)']); 
        end   
        
        if isempty(AREA)       
            StatisticsString = ReturnRusOrEngString(IsRusLanguage, ...
                                        'нет результатов', 'no results');
        end 
        
        %-----------------------------------------------------------------------------------
        % заполняю массив ImagesToShow и список операций обработок
        
        ImagesToShow(end+1).Images = im2double(ImageBW);        
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                    'Результат бинаризации',...
                                    'Binarization result');
                                
        % запоминаю изображение полутоновое с крестами в центрах пятен
        ImagesToShow(end+1).Images = ...
            insertMarker(im2double(ImageBW), CENTEROID, 'Color', 'blue');
            
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                'Обнаруженные пятна на бинарном изображении',...
                                'Recognized blobs on binary image');
        
        % запоминаю изображение исходное с крестами в центрах пятен
        ImagesToShow(end+1).Images = ...
            insertMarker(ImagesToShow(1).Images, CENTEROID, 'Color', 'blue');
                
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                'Обнаруженные пятна на оригинале',...
                                'Recognized blobs on original image');         
        
    case {'Распознавание лиц','Face detection'}
        
        % объект-детектор
        faceDetector = vision.CascadeObjectDetector(...
                            'MinSize',ProcessParameters.MinSize,...
                            'MaxSize',ProcessParameters.MaxSize,...    
                            'ScaleFactor',ProcessParameters.ScaleFactor,...    
                            'MergeThreshold',ProcessParameters.MergeThreshold,...    
                            'ClassificationModel',ProcessParameters.Model,...    
                            'UseROI', true);
        
        ROI = [X0 Y0 X1-X0 Y1-Y0];
        
        % извлекаем лица
        Boxes = step(faceDetector, Image, ROI);    % размерность Nx4
        
        % делаем координаты абсолютными для пользовательского файла
        Boxes(:,1) = Boxes(:,1) + X0;
        Boxes(:,2) = Boxes(:,2) + Y0;       
        
        % вставляем прямоугольники с описаниями
        ImageWithFaces = insertShape(Image, 'rectangle', Boxes, ...
                            'LineWidth', 2, 'Color', 'blue', 'Opacity', 1);
        
        % запоминаю картинку 
        ImagesToShow(end+1).Images = ImageWithFaces;                
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                                'Обнаруженные лица',...
                                                'Recognized faces');   
                            
    case {'Распознавание людей','People detection'}
        
    case {'Распознавание объектов','Object detection'}
        
        if size(Image,3) == 3
            GrayImage = rgb2gray(Image);
        end
        
        Pattern = ProcessParameters.Pattern;
        
        % нужны полутоновые картинки
        if size(Pattern,3) == 3
            GrayPattern = rgb2gray(Pattern);
        end
        
        % считываем тип детектора для ключевых точек и детектируем их
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
                assert(0,'Что то пошло не так...Выбрали несуществующую строчку меню');
        end
        
        % извлекаем фичи образца и сцены
        % для surf отдельный вызов
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
        
        % сравниваем фичи, выделяя пары похожих
        % для бинарных точе выpов без метрики
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
        
        % извлекаю из всех доступных точек только совпавшие по их адресам в Pairs
        MatchedPatternPoints = PatternPoints(Pairs(:, 1), :);
        MatchedScenePoints = ScenePoints(Pairs(:, 2), :);
        
        % провожу анализ их геометрических искажений
        [~,~,ResultPoints,~] = estimateGeometricTransform(...
                                MatchedPatternPoints, ...
                                MatchedScenePoints,...
                                ProcessParameters.TransformationType,... 
                                'MaxNumTrials',ProcessParameters.MaxNumTrials, ...
                                'Confidence',ProcessParameters.Confidence,...
                                'MaxDistance', ProcessParameters.MaxDistance);      
        
        % в ось образца вставляю его со всеми отмеченными ключевыми точками 
        NewPattern = insertMarker(GrayPattern, round(PatternPoints.Location), 'Color', 'blue'); 
        
        %-----------------------------------------------------------------------------------
        % заполняю массив ImagesToShow и список операций обработок
        
        if size(Image,3) == 3
            GrayImage = rgb2gray(Image);
            
            ImagesToShow(end+1).Images = GrayImage;
            StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                        'Полутоновое изображение',...
                                        'Grayscale image');
        end         
        
        ImagesToShow(end+1).Images = insertMarker(GrayImage, ScenePoints, 'Color', 'blue');                                    
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                    'Все найденные ключевые точки',...
                                    'All found keypoints');                                
                                         
        ImagesToShow(end+1).Images = insertMarker(GrayImage, ScenePoints(Pairs(:,2),:), 'Color', 'blue');             
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                    'Совпадающие ключевые точки',...
                                    'Matched keypoints');                                
        
        ImagesToShow(end+1).Images = insertMarker(GrayImage, ResultPoints, 'Color', 'blue');             
        StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                                    'Корректные совпадающие ключевые точки (полутоновое изображение)',...
                                    'Сorrect matched keypoints (grayscale image)');
                                
        if size(Image,3) == 3
            
            ImagesToShow(end+1).Images = insertMarker(Image, ResultPoints, 'Color', 'blue');            
            StringOfImages{end+1} = ReturnRusOrEngString(IsRusLanguage,...
                        'Корректные совпадающие ключевые точки (исходное изображение)',...
                        'Сorrect matched keypoints (original image)');
        end
        
    case {'Создание 3D-изображения','3-D image creation'}
        
    case {'Обработка видео','Video processing'}
        
    case {'Создание панорамы','Panorama creation'}
        
    case {'Распознавание движения','Motion detection'}
        
    otherwise
        assert(0, 'Ошибка в обращении к методам обработки');
        
end   

% проверяем выходные изображения
for x = 1:size(ImagesToShow,2)
    CheckImage(ImagesToShow(x).Images);
end

if ~isempty(NewPattern)
    CheckImage(NewPattern);
end

% заполняем выходную структуру данными
ProcessResults.ImagesToShow.Images = ImagesToShow;
ProcessResults.StringOfImages = StringOfImages;
ProcessResults.NewPattern = NewPattern;
ProcessResults.StatisticsString = StatisticsString;
ProcessResults.LABEL = LABEL;
ProcessResults.Boxes = Boxes;


% ФУНКЦИЯ ОТОБРАЖЕНИЯ ПОЛЬЗОВАТЕЛЬСКОГО ФАЙЛА
function ShowMultimediaFile(handles)

assert(isstruct(handles),'Передана не структура элементов интерфейса');

% ищу созданный объект-картинку в осях
FrameObj = findobj('Parent',handles.FileAxes, 'Tag','FrameObj');

% считваем кадры, которые можно отобразить
ImagesToShow = getappdata(handles.KAACVP,'ImagesToShow');

% проверяем его
assert(~isempty(ImagesToShow),...
        'В ось не вставили объект с этапами обработки');

assert(size(ImagesToShow, 2) == size(handles.ImagesToShowMenu.String, 1),...
        'Число строк не соответствует числу изображений'); 
    
% выбираю по требованию пользователя кадр
ImageToView = ImagesToShow(handles.ImagesToShowMenu.Value).Images;

% если полутоновое - отображаем, добавляя одинаковых 2 канала 
if size(ImageToView, 3) ~= size(FrameObj.CData, 3)
    
    ImageToView(:,:,2) = ImageToView(:,:,1);
    ImageToView(:,:,3) = ImageToView(:,:,1);
end

% заменяем массив данных и пряем засечки осей
set(FrameObj, 'CData', ImageToView);
handles.FileAxes.Visible = 'off';


% ПРОПИСЫВАЕТ РУС ИЛИ АНГЛ СТРОКУ В ЗАВИСИМОСТИ ОТ ЯЗЫКА ИНТЕРФЕЙСА
function String = ReturnRusOrEngString(IsRusLanguage, RusString, EngString)

% ВЫДАЕТ 2й (если IsRusLanguage == true) 
% ИЛИ 3й АРГУМЕНТ (если IsRusLanguage == false)

assert(islogical(IsRusLanguage),'Флаг языка не логический');
assert(iscell(RusString) || ischar(RusString), '2й входной аргумент не строковый');
assert(iscell(EngString) || ischar(EngString), '3й входной аргумент не строковый');

if IsRusLanguage
    String = {RusString};
else
    String = {EngString}; 
end


% ПРОВОДИТ ПРОВЕРКИ НАД ИЗОБРАЖЕНИЕМ
function CheckImage(Image)

assert(isfloat(Image),'Image имеет формат отличный от double');
assert(~isempty(Image), 'Image - пустой массив');
assert(size(Image,1) > 1 || size(Image,2) > 1, 'Image - вектор, а не изображение');
assert(size(Image,3) < 4, 'Image - многоканальное изображение');
assert(all(Image(:) <= 1 & Image(:) >= 0), 'Image имеет значения вне интервала [0 1]');


% ГЕНЕРИРУЕТ ОШИБКУ В СООТВЕТСТВИИ С ЕЕ КОДОМ И ЯЗЫКОМ
function GenerateError(ErrorCode, IsRusLanguage)

assert(islogical(IsRusLanguage), 'IsRusLanguage не логический');

% по коду ошибки прописываем информационную строку
% в зависимости от языка возвращается определенная строчка
switch ErrorCode    
    
    case 'FigFIleOpened'
        
        InfoStirng = {  'Вы запустили файл с расширением *.fig вместо расширения *.m.';...
                        'Нажмите "OK", и все будет хорошо!';
                        'You have started a file with expansion *.fig instead of *.m.';
                        'Press "OK" to make it OK.'};
    
    case 'ShouldBeDigits'
        
        InfoStirng = ReturnRusOrEngString(IsRusLanguage,...
                                'Введите в строку числовое значение',...
                                'Use digits only in this field');
    
    case 'MultimediaFileOpenningFailed'        
        
        InfoStirng = ReturnRusOrEngString(IsRusLanguage,...
                                'С файлом что-то не так. Откройте другой',...
                                'File is improper. Choose another file');  
                            
    case 'NoCV_NoIPT'
        
        InfoStirng = [  'Отсутствует расширение "Computer Vision System Toolbox 7.3".';...
                        'Отсутствует расширение "Image Processing Toolbox 10.0".';...
                        '...Но вы держитесь здесь!';...
                        'Приложение будет закрыто.';...
                        'Вам всего доброго, хорошего настроения и здоровья!';...
                        'С установкой расширений все будет как надо!';...
                        {' '};...
                        '"Computer Vision System Toolbox 7.3" is missing.'; ...
                        '"Image Processing Toolbox 10.0" is missing.';...
                        'Application will be closed. Good luck to you, buddy.';...
                        'Set up these toolboxes to run application.'];
             
    case 'NoIPT'
        
        InfoStirng = [  'Отсутствует расширение "Image Processing Toolbox 10.0".';...
                        '...Но вы держитесь здесь!';...
                        'Приложение будет закрыто.';...
                        'Вам всего доброго, хорошего настроения и здоровья!';...
                        'С установкой расширений все будет как надо!';...
                        {' '};...
                        '"Image Processing Toolbox 10.0" is missing.'; ...
                        'Application will be closed. Good luck to you, buddy.';...
                        'Set up this toolbox to run application.'];
    case 'NoCV'
        
        InfoStirng = [  'Отсутствует расширение "Computer Vision System Toolbox 7.3".';...
                        '...Но вы держитесь здесь!';...
                        'Приложение будет закрыто.';...
                        'Вам всего доброго, хорошего настроения и здоровья!';...
                        'С установкой расширений все будет как надо!';...
                        {' '};...
                        '"Computer Vision System Toolbox 7.3" is missing.'; ...
                        'Application will be closed. Good luck to you, buddy.';...
                        'Set up this toolbox to run application.'];
    
    otherwise
        
        assert(0, 'Неверно указан код ошибки!');
        
end

% генерируем модальное окно ошибки
errordlg(InfoStirng,'KAACVP','modal');


% ПРОВЕРЯЕТ НАЛИЧИЕ УСТАНОВКИ ТУЛБОКСА НЕОБХОДИМОЙ ВЕРСИИ
function ToolboxPresence = DoWeHaveThisToolbox(ThisToolbox, NecessaryToolboxVersion)

assert(ischar(ThisToolbox),'Тулбокс не прописан строкой');
assert(isnumeric(NecessaryToolboxVersion), 'NecessaryToolboxVersion - не число');

ToolboxPresence = false;
toolboxes = ver();          % считываем информацию по установленным пакетам

for i = 1:size(toolboxes,2) % проходимся по каждому

    if strcmp(ThisToolbox,toolboxes(i).Name) == 1 % если нашли  
        
        % и его версия соответствует или выше необходимой
        if str2double(toolboxes(i).Version) >= NecessaryToolboxVersion            
            ToolboxPresence = true;
        end        
    end
end

assert(islogical(ToolboxPresence), 'ToolboxPresence на выходе не логический');


% ПРОВЕРЯЕТ ЗАПУЩЕН FIG- ИЛИ M-ФАЙЛ
function IsFigFile = IsFigFileRunned(handles)

IsFigFile = false;          % по умолчанию вернен "нет"

if isempty(handles)         % значит запустил fig вместо m  
    
    IsFigFile = true;
    GenerateError('FigFIleOpened', true);  
    uiwait(gcf);        % ждем закрытия окна ошибки
    close(gcf);         % закрываем fig-файл
    run('KAACVP.m');     % запускаем корректное окно
    return;
end

warning('on','all');


% ВОЗВРАЩАЕТ РАЗМЕР ИЗОБРАЖЕНИЯ ИСПОЛЬЗОВАННОГО ДЛЯ ТРЕНИРОВКИ ДЕТЕКТОРА И НАЗВАНИЕ МОДЕЛИ
function [TrainModelSize, FaceDetectorModel] = ReturnFaceDetectorTrainModelAndSize(ClassificationModel)

assert(isstring(ClassificationModel), 'ClassificationModel не строка');

switch ClassificationModel
    case {'Frontal face (CART)','Анфас (CART)'}
        TrainModelSize = [20 20];
        FaceDetectorModel = 'FrontalFaceCART';
        
    case {'Frontal face (LBP)','Анфас (LBP)'}
        TrainModelSize = [24 24];
        FaceDetectorModel = 'FrontalFaceLBP';
        
    case {'Upper body','Верх тела'}
        TrainModelSize = [20 22];
        FaceDetectorModel = 'UpperBody';
        
    case {'Eye pair (big)','Пара глаз (большая)'}
        TrainModelSize = [11 45];
        FaceDetectorModel = 'EyePairBig';
        
    case {'Eye pair (small)','Пара глаз (малая)'}
        TrainModelSize = [5 22];
        FaceDetectorModel = 'EyePairSmall';
        
    case {'Left eye','Левый глаз'}
        TrainModelSize = [12 18];
        FaceDetectorModel = 'LeftEye';
        
    case {'Right eye','Правый глаз'}
        TrainModelSize = [12 18];
        FaceDetectorModel = 'RightEye';
        
    case {'Left eye (CART)','Левый глаз (CART)'}
        TrainModelSize = [20 20];
        FaceDetectorModel = 'LeftEyeCART';
        
    case {'Right eye (CART)','Правый глаз (CART)'}
        TrainModelSize = [20 20];
        FaceDetectorModel = 'RightEyeCART';
        
    case {'Profile face','Профиль'}
        TrainModelSize = [20 30];
        FaceDetectorModel = 'ProfileFace';
        
    case {'Mouth','Рот'}
        TrainModelSize = [15 25];
        FaceDetectorModel = 'Mouth';
        
    case {'Nose','Нос'}
        TrainModelSize = [15 18]; 
        FaceDetectorModel = 'Nose'; 
        
    otherwise
        assert(0, 'Вызвана несуществующая модель классификации детектора лиц');
end


% ОТРИСОВКА ROI / ОБРАЗЦА
function RefreshROIrect(handles, X0Y0X1Y1Coords, ROIPosition)

delete(findobj('Parent',handles.FileAxes,'LineStyle','--'));

UserFile = getappdata(handles.KAACVP,'UserFile');

ComputerVisionMethod = string(handles.CVMethodMenu.String(handles.CVMethodMenu.Value));

switch ComputerVisionMethod
    
    case {  'Распознавание текста','Optical character recognition',...
            'Распознавание лиц','Face detection'}
        
        rectangle(  'Position',ROIPosition,...
            'Parent',handles.FileAxes,...
            'EdgeColor','r',...
            'LineStyle','--',...
            'LineWidth',2);
        
    case {  'Распознавание объектов','Object detection',...
            'Создание 3D-изображения','3-D image creation'}
        
        % здесь ROI используется в качестве определения изображения-образца        
        Image = UserFile.Multimedia(handles.FrameSlider.Value).Frame;        
        Pattern = Image(X0Y0X1Y1Coords(2):X0Y0X1Y1Coords(4), X0Y0X1Y1Coords(1):X0Y0X1Y1Coords(3), :);
        
        image(Pattern,'Parent',handles.PatternAxes);
        handles.PatternAxes.Visible = 'off';
        
        setappdata(handles.KAACVP,'Pattern',Pattern);
        
        % размер оси будет установлен в соответствие со статусом кнопки
        ZoomButton_Callback([], [], handles);
        
        % разблокируем элементы, чтобы можно было вручную задавать изменения ROI        
        set([...
            handles.ROIx0;...
            handles.ROIy0;...
            handles.ROIx1;...
            handles.ROIy1;...
            ],'Enable','on');       
        
        handles.ShowPatternImageMenu.Visible = 'on';
end


% БЛОКИРУЕТ ЭЛЕМЕНТЫ ИНТЕРФЕЙСА
function DoyouWantToBlockInterface(WantToBlockIt, handles, IsVideo)

% постоянно блокировать интерфейс для видео - гиблое дело...
assert(islogical(IsVideo), 'BlockIt на входе не логический');
if IsVideo
    return;
end

assert(isstruct(handles),'Передана не структура элементов интерфейса');
assert(islogical(WantToBlockIt), 'BlockIt на входе не логический');
IsRusLanguage = IsFigureLanguageRussian(handles);
    
if WantToBlockIt
    
    set(findobj('Parent', handles.KAACVP, '-not', 'Type', 'uipanel'), 'Enable', 'off');
    set(handles.ParametersPanel.Children, 'Enable', 'off'); 
    
    handles.KAACVP.Name = string(ReturnRusOrEngString(IsRusLanguage,...
                        'KAACVP: идет обработка ... он очень старается...',...
                        'KAACVP: processing is running ... it tries so hard...'));
else
    set(findobj('Parent', handles.KAACVP, '-not', 'Type', 'uipanel'), 'Enable', 'on');
    set(handles.ParametersPanel.Children, 'Enable', 'on');
    handles.KAACVP.Name = 'KAACVP';
end

drawnow;


% ДЕЛАЕТ ВИДИМЫМ ИНТЕРФЕЙСНЫЙ СЛАЙДЕР ПАРАМЕТРА
function SetParSlidersVisibleStatus(ParSliderNumbersList, ShowIt, handles)

% число слайдеров параметров в интерфейса
NumOfParSliders = 9;

assert(all(ParSliderNumbersList <= NumOfParSliders),['Слайдеров параметра всего ' num2str(NumOfParSliders)]);
assert(all(ParSliderNumbersList > 0), 'Слайдер параметра начинается с 1!');
assert(isnumeric(ParSliderNumbersList), 'ParSliderNumbersList входе - не число');
assert(isstruct(handles),'Передана не структура элементов интерфейса');

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


% ДЕЛАЕТ ВИДИМЫМ ИНТЕРФЕЙСНОЕ МЕНЮ ПАРАМЕТРА
function SetParMenusVisibleStatus(ParMenuNumbersList, ShowIt, handles)

% число меню параметров интерфейса
NumOfParMenu = 4;

assert(all(ParMenuNumbersList <= NumOfParMenu),['Меню параметра всего' num2str(NumOfParMenu)]);
assert(all(ParMenuNumbersList > 0), 'Слайдер параметра начинается с 1!');
assert(isnumeric(ParMenuNumbersList), 'ParMenuNumbersList входе - не число');
assert(isstruct(handles),'Передана не структура элементов интерфейса');

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


% ДЕЛАЕТ ВИДИМЫМ ЭЛЕМЕНТЫ ROI
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

