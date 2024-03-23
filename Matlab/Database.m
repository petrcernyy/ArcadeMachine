classdef Database < handle

    properties
        UI

        CreatingUser = 0;
    end

    methods

        function this = Database(UI)
            this.UI = UI;
        end
         
        function mySaveScore(this, Score)

            if (~isempty(this.UI.Player))

                GamePath = fullfile(this.UI.GamesPath, this.UI.GameNames_arr(this.UI.GameIDX));
                scoreFile = dir(fullfile(GamePath, 'score.txt'));
    
                if (~isempty(scoreFile))
                    
                    fileattrib(fullfile(GamePath, 'score.txt'), '+w');
                    scoreboard = readtable(fullfile(GamePath, 'score.txt'));
                    idx = find(strcmp(this.UI.Player, scoreboard.Name));
                    if (~isempty(idx))
                        if (Score > scoreboard.Score(idx))
                            scoreboard(idx,:) = table({this.UI.Player}, Score);
                        end
                    else
                        scoreboard(height(scoreboard)+1,:) = table({this.UI.Player}, Score);
                    end
                    
                    scoreboard = sortrows(scoreboard, 2, 'descend');
                    scoreboard(10:end,:) = [];
                    sendEventToHTMLSource(this.UI.LeaderBoard, "newData", jsonencode(scoreboard));
                    writetable(scoreboard, fullfile(GamePath, 'score.txt'));
                    fileattrib(fullfile(GamePath, 'score.txt'), '-w');
    
                else
                    
                    Name = {this.UI.Player};
                    scoreboard = table(Name, Score);
                    sendEventToHTMLSource(this.UI.LeaderBoard, "newData", jsonencode(scoreboard));
                    writetable(table(Name, Score), fullfile(GamePath, 'score.txt'));
                    fileattrib(fullfile(GamePath, 'score.txt'), '-w');
    
                end
            end

        end

        function createNewUser(this)

            this.CreatingUser = 1;
            set(this.UI.newUserWindowPanel, 'Visible', 'on');
            set(this.UI.Image, 'Visible', 'off');
            set(this.UI.QR, 'Visible', 'off');

        end

        function saveNewUserName(this)
            databaseFolder = fullfile(pwd,'database');
            fileattrib(fullfile(databaseFolder, 'database.txt'), '+w');
            database = readtable(fullfile(databaseFolder, 'database.txt'));
            database = [database; table({this.UI.Player}, str2double(this.UI.ID), 'VariableNames', {'Name', 'ID'})];
            writetable(database, fullfile(databaseFolder, 'database.txt'));
            fileattrib(fullfile(databaseFolder, 'database.txt'), '-w');
        end

        function databaseNewData(this, data)


            databaseFolder = fullfile(pwd,'database');
            fileattrib(fullfile(databaseFolder, 'database.txt'), '+w');
            database = readtable(fullfile(databaseFolder, 'database.txt'));
            idx = find(strcmp(strrep(string(num2str(database.ID)),' ',''), data),1);
            if (~(isempty(idx)))
                if (~isempty(this.UI.Player) && (strcmp(this.UI.ID, data) == 0))
                    sendEventToHTMLSource(this.UI.Html, "ConsoleMessage", "Goodbye " + this.UI.Player);
                    this.UI.Player = [];
                    this.UI.Player = database.Name{idx};
                    this.UI.ID = data;
                    sendEventToHTMLSource(this.UI.Html, "ConsoleMessage", "Welcome " + this.UI.Player);
                elseif (isempty(this.UI.Player))
                    this.UI.Player = database.Name{idx};
                    this.UI.ID = data;
                    sendEventToHTMLSource(this.UI.Html, "ConsoleMessage", "Welcome " + this.UI.Player);
                else
                    sendEventToHTMLSource(this.UI.Html, "ConsoleMessage", "Goodbye " + this.UI.Player);
                    this.UI.ID = [];
                    this.UI.Player = [];
                end
            else
                if (isempty(this.UI.Player))
                    this.UI.ID = data;
                    this.createNewUser()
                else
                    sendEventToHTMLSource(this.UI.Html, "ConsoleMessage", "Goodbye " + this.UI.Player);
                    this.UI.Player = [];
                    this.UI.ID = data;
                    this.createNewUser()
                end
            end

        end
    end
end