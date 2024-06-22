classdef APP_Games < handle

    properties
        APP_UI
    end

    methods

        function this = APP_Games(APP_UI)

            this.APP_UI = APP_UI;

            this.APP_UI.GameNames_arr = [];

            folders = dir(this.APP_UI.GamesPath);
            folders = folders([folders.isdir]);
            
            if (~isempty(folders))
                for i = 1:length(folders)
                    folderName = folders(i).name;
                    if ~strcmp(folderName, '.') && ~strcmp(folderName, '..')
                        this.APP_UI.GameNames_arr = [this.APP_UI.GameNames_arr; convertCharsToStrings(folderName)];
                    end
                end
    
                LogoFolder = fullfile(this.APP_UI.GamesPath, this.APP_UI.GameNames_arr(1), "logo");
                imageFiles = dir(fullfile(LogoFolder, '*.jpg'));
                imageFiles = [imageFiles; dir(fullfile(LogoFolder, '*.png'))];
    
                if ~isempty(imageFiles)
                    firstImageFile = fullfile(imageFiles(1).folder, imageFiles(1).name);
                    this.APP_UI.Image = uiimage(this.APP_UI.Panel_Main, "ImageSource", firstImageFile, 'Position', this.APP_UI.Pos_Image, 'Visible', 'off');
                else
                    this.APP_UI.Image = uilabel(this.APP_UI.Panel_Main, "Text", "  No logo found", 'Position', this.APP_UI.Pos_Image, 'Visible', 'off');
                end
    
                dataToSend = [length(this.APP_UI.GameNames_arr); this.APP_UI.GameNames_arr];
                dataToSend = jsonencode(dataToSend);
                sendEventToHTMLSource(this.APP_UI.Html, "ValueChanged", dataToSend);
                this.APP_UI.NoGamesFlag = 1;
            else
                sendEventToHTMLSource(this.APP_UI.Html, "ValueChanged", 0);
                this.APP_UI.NoGamesFlag = 0;
            end

            % this.APP_UI.Timers.startMyTimer(Enums.FoldersTimerE);

        end

        function checkForNewFolder(this)

            folders = dir(this.APP_UI.GamesPath);
            folders = folders([folders.isdir]);

            if (~isempty(folders))

                oldLenght = length(this.APP_UI.GameNames_arr);
                this.APP_UI.GameNames_arr = [];
    
                for i = 1:length(folders)
                    folderName = folders(i).name;
                    if ~strcmp(folderName, '.') && ~strcmp(folderName, '..')
                        this.APP_UI.GameNames_arr = [this.APP_UI.GameNames_arr; convertCharsToStrings(folderName)];
                    end
                end
    
                this.APP_UI.GameNames_arr = unique(this.APP_UI.GameNames_arr);
                
                if oldLenght ~= length(this.APP_UI.GameNames_arr)
                    dataToSend = [length(this.APP_UI.GameNames_arr); this.APP_UI.GameNames_arr];
                    dataToSend = jsonencode(dataToSend);
                    sendEventToHTMLSource(this.APP_UI.Html, "ValueChanged", dataToSend);
                    this.APP_UI.NoGamesFlag = 1;
                end
            else
                this.APP_UI.NoGamesFlag = 0;
                sendEventToHTMLSource(this.APP_UI.Html, "ValueChanged", 0);
            end

        end

        function logoChange(this, name)

            if(~(isempty(this.APP_UI.Image)))
                delete(this.APP_UI.Image);
            end
            if(~(isempty(this.APP_UI.QR)))
                delete(this.APP_UI.QR)
            end

            LogoFolder = fullfile(this.APP_UI.GamesPath, name, "logo");
            imageFiles = dir(fullfile(LogoFolder, '*.jpg'));
            imageFiles = [imageFiles; dir(fullfile(LogoFolder, '*.png'))];

            if ~isempty(imageFiles)
                firstImageFile = fullfile(imageFiles(1).folder, imageFiles(1).name);
                this.APP_UI.Image = uiimage(this.APP_UI.Panel_Main, "ImageSource", firstImageFile, 'Position', this.APP_UI.Pos_Image);
            else
                this.APP_UI.Image = uilabel(this.APP_UI.Panel_Main, "Text", "   No logo found",'Position',...
                                    this.APP_UI.Pos_Image, 'FontSize', 40);
            end

            QrFolder = fullfile(this.APP_UI.GamesPath, name, "qrcode");
            QrimageFiles = dir(fullfile(QrFolder, '*.jpg'));
            QrimageFiles = [QrimageFiles; dir(fullfile(QrFolder, '*.png'))];

            if ~isempty(QrimageFiles)
                firstQRFile = fullfile(QrimageFiles(1).folder, QrimageFiles(1).name);
                this.APP_UI.QR = uiimage(this.APP_UI.Panel_Main, "ImageSource", firstQRFile, 'Position', this.APP_UI.Pos_QR);
            else
                this.APP_UI.QR = uilabel(this.APP_UI.Panel_Main, "Text", "   No QR Code",'Position',...
                                    this.APP_UI.Pos_QR + [30 0 0 0], 'FontSize', 20);
            end
    
            try
                nameOpen = fopen(fullfile(QrFolder, 'author.txt'));
                name = fgetl(nameOpen);
                sendEventToHTMLSource(this.APP_UI.Html, "AuthorChanged", name);
                fclose(nameOpen);
            catch
                sendEventToHTMLSource(this.APP_UI.Html, "AuthorChanged", '-');
            end

        end
    end
end