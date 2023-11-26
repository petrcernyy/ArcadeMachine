classdef MeteorShower < handle
    properties
        Axis
        hUI
        Ylimit = 100 %optimal = 100 
        Xlimit = 10 %optimal = 10
        fps = 15 %optimal = 15
        musicVolume = 30
        sfxVolume = 100
        asteroidSpawnRate = 30 %after how many frames does next asteroid spawn
        finalAsteroidSpawnRate = 5 %biggest cadency of asteroids
        intervalDecrease = 0.5 %how fast the game gets harder
        
        laserCooldownTime%speed of shooting
        laserCooldown
        laserOk
        movementCooldownTime %speed of the ship
        movementCooldown
        movementOk

        CAR
        step

        laserObj
        asteroidObj

        score = 0;
        saveScoreFlag = 0
        scoreText
        gameOverText
        gameOver = 0;
        frames = 0;

        fontShape = 'FixedWidth';
        shipShape = {'/\_\\' '/=\\\_/( )\\\_/=\\'};

        gameRunning = 0

        ship
        introText
    end

    methods
        function this = MeteorShower(hUI)
            this.hUI = hUI;
            this.laserCooldownTime = this.fps/5;
            this.laserCooldown = this.laserCooldownTime;
            this.movementCooldownTime = ceil(this.fps/15);
            this.movementCooldown = this.movementCooldownTime;
            
            %soundtrack
            hUI.playSoundtrack('soundtrack.wav')

            this.CAR.posx = this.Xlimit/2;
            this.CAR.posy = this.Ylimit/10;
            this.step = this.Xlimit/10;

            this.laserObj = laser();
            this.asteroidObj = asteroid();

            this.Axis = hUI.Axes;
            set(this.Axis, 'XLim', [0,this.Xlimit], 'YLim', [0,this.Ylimit]);
            set(this.Axis,'xtick',[],'ytick',[],'xcolor', [1 1 1],'ycolor', [1 1 1], 'Color', 'k');

            this.ship = text(this.Axis, this.CAR.posx,this.CAR.posy,this.shipShape,'FontName', this.fontShape,'HorizontalAlignment', 'center', 'Color', [1 1 1],'FontWeight', 'bold');
            this.introText = text(this.Axis, this.Xlimit/2, this.Ylimit/2, 'WELCOME! PRESS SPACE TO START PLAYING...', 'HorizontalAlignment', 'center', 'Color', [1 1 1],'FontWeight', 'bold', 'FontName', 'Monospaced');

            hUI.enableButtonsIRQ([0 0 1 1 1 1]);
            hUI.setTimerFreq(0.01);
        end

        function runFrame(this)
            if (this.gameRunning)
                if (this.gameOver == 0)
                  i = 2;
                  this.frames = this.frames + 1;
                  tic
                  if this.movementCooldown < this.movementCooldownTime
                      this.movementCooldown = this.movementCooldown + 1;
                  else
                      this.movementOk = 1;
                  end
                  if this.laserCooldown < this.laserCooldownTime
                      this.laserCooldown = this.laserCooldown + 1;
                  else
                      this.laserOk = 1;
                  end

                  if mod(this.frames,this.asteroidSpawnRate) == 0
                      this.asteroidObj(end+1) = asteroid();
                      this.asteroidObj(end).posx = 2+ceil(rand(1,1)*7);
                      this.asteroidObj(end).posy = this.Ylimit-(1/10)*this.Ylimit;
                      this.asteroidObj(end).spawn(this.Axis);
                      if this.asteroidSpawnRate > this.finalAsteroidSpawnRate
                        this.asteroidSpawnRate = this.asteroidSpawnRate - this.intervalDecrease;
                      end
                  end
                  while i <= numel(this.laserObj)
                    if this.laserObj(i).posy > this.Ylimit*0.9
                      delete(this.laserObj(i).body);
                      if i ~= numel(this.laserObj)
                        for j = i+1:numel(this.laserObj)
                          this.laserObj(j-1) = this.laserObj(j);
                        end
                      end
                      this.laserObj = this.laserObj(1:end-1);
                      continue
                    end
                    this.laserObj(i).move(this.Axis)
                    i = i + 1;
                  end
                  %moves asteroids and checks if you lost
                  i = 2;
                  while i <= numel(this.asteroidObj)
                    if this.asteroidObj(i).posy < this.CAR.posy + 2 % the 2 is correction
                      this.hUI.playSound('death_sound.wav');
                        delete(this.asteroidObj(i).body);
                        clear this.asteroidObj(i);
                        this.gameOver = 1;
                        for j = i+1:numel(this.asteroidObj)
                          this.asteroidObj(j-1) = this.asteroidObj(j);
                        end
                        this.asteroidObj = this.asteroidObj(1:end-1);
                        continue
                    end
                      this.asteroidObj(i).move(this.Axis);
                      i = i + 1;
                  end
                    %checking collision
                  i = 1;
                  j = 1;
                  while j <= numel(this.asteroidObj)
                    while i <= numel(this.laserObj)
                      if ((abs(this.asteroidObj(j).posy - this.laserObj(i).posy)) < 7) & (this.laserObj(i).posx == this.asteroidObj(j).posx)
                        %increase score and delete hit objects
                        this.hUI.playSound('explosion.wav');
                        this.score = this.score + 10;
                        delete(this.scoreText);
                        this.scoreText = text(this.Axis, this.Xlimit*0.1, this.Ylimit*0.9, sprintf('SCORE: %d', this.score), 'FontWeight', 'bold', 'FontName', 'Monospaced', 'Color', [1 1 1]);
                        delete(this.laserObj(i).body);
                        delete(this.asteroidObj(j).body);
                        if i ~= numel(this.laserObj)
                          for k = i+1:numel(this.laserObj)
                            this.laserObj(k-1) = this.laserObj(k);
                          end
                        end
                        this.laserObj = this.laserObj(1:end-1);
                        if j ~= numel(this.asteroidObj)
                          for l = j+1:numel(this.asteroidObj)
                            this.asteroidObj(l-1) = this.asteroidObj(l);
                          end
                        end
                        this.asteroidObj = this.asteroidObj(1:end-1);
                        i = 1;
                        j = 1;
                      end
                      i = i+1;
                    end
                    i = 1;
                    j = j+1;
                  end
                    % fps correction
                  elapsedFrameTime = toc;
                  if elapsedFrameTime<(1/this.fps)
                    pause((1/this.fps)-elapsedFrameTime)
                  end
                elseif (this.gameOver)
                    this.hUI.stopSoundtrack();
                    this.gameOverText = text(this.Axis, (this.Xlimit/2), (this.Ylimit/2), {sprintf('GAME OVER! YOUR SCORE IS %d.', this.score),'PRESS ESCAPE TO QUIT'}, 'HorizontalAlignment', 'center','FontName','Monospaced', 'Color', [1 1 1], 'FontWeight', 'bold');
                    if(~this.saveScoreFlag)
                        this.saveScoreFlag = 1;
                        this.hUI.saveScore(this.score);
                    end
                end
            elseif (this.gameRunning == 0)
                
            end

        end

        function BtnExitPressed(this)
            this.hUI.backToMainMenu();
        end

        function BtnRightPressed(this)
            if (this.gameRunning)
              if this.movementOk
                  if (this.CAR.posx + this.step) < this.Xlimit
                      this.CAR.posx = this.CAR.posx + this.step;
                      delete(this.ship);
                      this.ship = text(this.Axis, this.CAR.posx,this.CAR.posy,this.shipShape,'FontName', this.fontShape, 'HorizontalAlignment', 'center', 'Color', [1 1 1],'FontWeight', 'bold');
                      this.movementCooldown = 1;
                      this.movementOk = 0;
                  end
              end
            end
        end

        function BtnLeftPressed(this)
            if (this.gameRunning)
              if this.movementOk
                  if (this.CAR.posx - this.step) > 0
                      this.CAR.posx = this.CAR.posx - this.step;
                      delete(this.ship);
                      this.ship = text(this.Axis, this.CAR.posx,this.CAR.posy,this.shipShape,'FontName', this.fontShape, 'HorizontalAlignment', 'center', 'Color', [1 1 1],'FontWeight', 'bold');
                      this.movementCooldown = 1;
                      this.movementOk = 0;
                  end
              end
            end
        end
        function BtnEnterPressed(this)
            if (this.gameRunning == 0)
                this.gameRunning = 1;
                delete(this.introText)
            elseif (this.gameRunning)
              if this.laserOk
                  % The game is lagging
                  % this.hUI.playSound('sfx_sounds_damage2.wav');             
                  this.laserObj(end+1) = laser();
                  this.laserObj(end).posx = this.CAR.posx;
                  this.laserObj(end).posy = this.CAR.posy;
                  this.laserObj(end).spawn(this.Axis);
                  this.laserCooldown = 1;
                  this.laserOk = 0;
              end
            end
        end
    end


end