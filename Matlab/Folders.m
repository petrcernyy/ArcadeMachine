classdef Folders < handle

    properties
        UI
    end

    methods

        function this = Folders(UI)

            this.UI = UI;

            this.UI.GameNames_arr = [];

            folders = dir(this.UI.GamesPath);
            folders = folders([folders.isdir]);
            
            if (~isempty(folders))
                for i = 1:length(folders)
                    folderName = folders(i).name;
                    if ~strcmp(folderName, '.') && ~strcmp(folderName, '..')
                        this.UI.GameNames_arr = [this.UI.GameNames_arr; convertCharsToStrings(folderName)];
                    end
                end
    
                LogoFolder = fullfile(this.UI.GamesPath, this.UI.GameNames_arr(1), "logo");
                imageFiles = dir(fullfile(LogoFolder, '*.jpg'));
                imageFiles = [imageFiles; dir(fullfile(LogoFolder, '*.png'))];
    
                if ~isempty(imageFiles)
                    firstImageFile = fullfile(imageFiles(1).folder, imageFiles(1).name);
                    this.UI.Image = uiimage(this.UI.Panel_Main, "ImageSource", firstImageFile, 'Position', this.UI.Pos_Image, 'Visible', 'off');
                else
                    this.UI.Image = uilabel(this.UI.Panel_Main, "Text", "  No logo found", 'Position', this.UI.Pos_Image, 'Visible', 'off');
                end
    
                dataToSend = [length(this.UI.GameNames_arr); this.UI.GameNames_arr];
                dataToSend = jsonencode(dataToSend);
                sendEventToHTMLSource(this.UI.Html, "ValueChanged", dataToSend);
                this.UI.NoGamesFlag = 1;
            else
                sendEventToHTMLSource(this.UI.Html, "ValueChanged", 0);
                this.UI.NoGamesFlag = 0;
            end

            % this.UI.Timers.startMyTimer(Enums.FoldersTimerE);

        end

        function checkForNewFolder(this)

            folders = dir(this.UI.GamesPath);
            folders = folders([folders.isdir]);

            if (~isempty(folders))

                oldLenght = length(this.UI.GameNames_arr);
                this.UI.GameNames_arr = [];
    
                for i = 1:length(folders)
                    folderName = folders(i).name;
                    if ~strcmp(folderName, '.') && ~strcmp(folderName, '..')
                        this.UI.GameNames_arr = [this.UI.GameNames_arr; convertCharsToStrings(folderName)];
                    end
                end
    
                this.UI.GameNames_arr = unique(this.UI.GameNames_arr);
                
                if oldLenght ~= length(this.UI.GameNames_arr)
                    dataToSend = [length(this.UI.GameNames_arr); this.UI.GameNames_arr];
                    dataToSend = jsonencode(dataToSend);
                    sendEventToHTMLSource(this.UI.Html, "ValueChanged", dataToSend);
                    this.UI.NoGamesFlag = 1;
                end
            else
                this.UI.NoGamesFlag = 0;
                sendEventToHTMLSource(this.UI.Html, "ValueChanged", 0);
            end

        end

        function logoChange(this, name)

            if(~(isempty(this.UI.Image)))
                delete(this.UI.Image);
            end
            if(~(isempty(this.UI.QR)))
                delete(this.UI.QR)
            end

            LogoFolder = fullfile(this.UI.GamesPath, name, "logo");
            imageFiles = dir(fullfile(LogoFolder, '*.jpg'));
            imageFiles = [imageFiles; dir(fullfile(LogoFolder, '*.png'))];

            if ~isempty(imageFiles)
                firstImageFile = fullfile(imageFiles(1).folder, imageFiles(1).name);
                this.UI.Image = uiimage(this.UI.Panel_Main, "ImageSource", firstImageFile, 'Position', this.UI.Pos_Image);
            else
                this.UI.Image = uilabel(this.UI.Panel_Main, "Text", "   No logo found",'Position',...
                                    this.UI.Pos_Image, 'FontSize', 40);
            end

            QrFolder = fullfile(this.UI.GamesPath, name, "qrcode");
            QrimageFiles = dir(fullfile(QrFolder, '*.jpg'));
            QrimageFiles = [QrimageFiles; dir(fullfile(QrFolder, '*.png'))];

            if ~isempty(QrimageFiles)
                firstQRFile = fullfile(QrimageFiles(1).folder, QrimageFiles(1).name);
                this.UI.QR = uiimage(this.UI.Panel_Main, "ImageSource", firstQRFile, 'Position', this.UI.Pos_QR);
            else
                this.UI.QR = uilabel(this.UI.Panel_Main, "Text", "   No QR Code",'Position',...
                                    this.UI.Pos_QR + [30 0 0 0], 'FontSize', 20);
            end
    
            try
                nameOpen = fopen(fullfile(QrFolder, 'author.txt'));
                name = fgetl(nameOpen);
                sendEventToHTMLSource(this.UI.Html, "AuthorChanged", name);
                fclose(nameOpen);
            catch
                sendEventToHTMLSource(this.UI.Html, "AuthorChanged", '-');
            end

        end
    end
end