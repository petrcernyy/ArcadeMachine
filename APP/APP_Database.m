classdef APP_Database < handle

    properties
        APP_UI

        CreatingUser = 0;
    end

    methods

        function this = APP_Database(APP_UI)
            this.APP_UI = APP_UI;
        end
         
        function mySaveScore(this, Score)

            if (~isempty(this.APP_UI.Player))

                GamePath = fullfile(this.APP_UI.GamesPath, this.APP_UI.GameNames_arr(this.APP_UI.GameIDX));
                scoreFile = dir(fullfile(GamePath, 'score.txt'));
    
                if (~isempty(scoreFile))
                    
                    fileattrib(fullfile(GamePath, 'score.txt'), '+w');
                    scoreboard = readtable(fullfile(GamePath, 'score.txt'));
                    idx = find(strcmp(this.APP_UI.Player, scoreboard.Name));
                    if (~isempty(idx))
                        if (Score > scoreboard.Score(idx))
                            scoreboard(idx,:) = table({this.APP_UI.Player}, Score);
                        end
                    else
                        scoreboard(height(scoreboard)+1,:) = table({this.APP_UI.Player}, Score);
                    end
                    
                    scoreboard = sortrows(scoreboard, 2, 'descend');
                    scoreboard(10:end,:) = [];
                    sendEventToHTMLSource(this.APP_UI.LeaderBoard, "newData", jsonencode(scoreboard));
                    writetable(scoreboard, fullfile(GamePath, 'score.txt'));
                    fileattrib(fullfile(GamePath, 'score.txt'), '-w');
    
                else
                    
                    Name = {this.APP_UI.Player};
                    scoreboard = table(Name, Score);
                    sendEventToHTMLSource(this.APP_UI.LeaderBoard, "newData", jsonencode(scoreboard));
                    writetable(table(Name, Score), fullfile(GamePath, 'score.txt'));
                    fileattrib(fullfile(GamePath, 'score.txt'), '-w');
    
                end
            end

        end

        function createNewUser(this)

            this.CreatingUser = 1;
            this.APP_UI.newUserWindowName.String = "";
            set(this.APP_UI.Panel_NewUser, 'Visible', 'on');
            set(this.APP_UI.Image, 'Visible', 'off');
            set(this.APP_UI.QR, 'Visible', 'off');

        end

        function saveNewUserName(this)
            databaseFolder = fullfile(pwd,'database');
            fileattrib(fullfile(databaseFolder, 'database.txt'), '+w');
            database = readtable(fullfile(databaseFolder, 'database.txt'));
            database = [database; table({this.APP_UI.Player}, str2double(this.APP_UI.ID), 'VariableNames', {'Name', 'ID'})];
            writetable(database, fullfile(databaseFolder, 'database.txt'));
            fileattrib(fullfile(databaseFolder, 'database.txt'), '-w');
        end

        function databaseNewData(this, data)


            databaseFolder = fullfile(pwd,'database');
            fileattrib(fullfile(databaseFolder, 'database.txt'), '+w');
            database = readtable(fullfile(databaseFolder, 'database.txt'));
            idx = find(strcmp(strrep(string(num2str(database.ID)),' ',''), data),1);
            if (~(isempty(idx)))
                if (~isempty(this.APP_UI.Player) && (strcmp(this.APP_UI.ID, data) == 0))
                    sendEventToHTMLSource(this.APP_UI.Html, "ConsoleMessage", "Goodbye " + this.APP_UI.Player);
                    sendEventToHTMLSource(this.APP_UI.Html, "AccountChange", "");
                    this.APP_UI.Player = [];
                    this.APP_UI.Player = database.Name{idx};
                    this.APP_UI.ID = data;
                    sendEventToHTMLSource(this.APP_UI.Html, "ConsoleMessage", "Welcome " + this.APP_UI.Player);
                    sendEventToHTMLSource(this.APP_UI.Html, "AccountChange", this.APP_UI.Player);
                elseif (isempty(this.APP_UI.Player))
                    this.APP_UI.Player = database.Name{idx};
                    this.APP_UI.ID = data;
                    sendEventToHTMLSource(this.APP_UI.Html, "ConsoleMessage", "Welcome " + this.APP_UI.Player);
                    sendEventToHTMLSource(this.APP_UI.Html, "AccountChange", this.APP_UI.Player);
                else
                    sendEventToHTMLSource(this.APP_UI.Html, "ConsoleMessage", "Goodbye " + this.APP_UI.Player);
                    sendEventToHTMLSource(this.APP_UI.Html, "AccountChange", "");
                    this.APP_UI.ID = [];
                    this.APP_UI.Player = [];
                end
            else
                if (isempty(this.APP_UI.Player))
                    this.APP_UI.ID = data;
                    this.createNewUser()
                else
                    sendEventToHTMLSource(this.APP_UI.Html, "ConsoleMessage", "Goodbye " + this.APP_UI.Player);
                    sendEventToHTMLSource(this.APP_UI.Html, "AccountChange", "");
                    this.APP_UI.Player = [];
                    this.APP_UI.ID = data;
                    this.createNewUser()
                end
            end

        end
    end
end