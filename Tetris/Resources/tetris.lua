------------------------------------
-----  User Define Variable --------
------------------------------------

-- get screen size
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local origin = CCDirector:sharedDirector():getVisibleOrigin()

-- game layer
local gameLayer

-- max row and col of tetris table 
local MAX_ROW = 20
local MAX_COL = 10

-- start positon of new block
local INIT_ROW = 2
local INIT_COL = 5

local BLOCK_WIDTH = 20
local BLOCK_HEIGHT = 20

-- score per lien
local SCORE_PER_LINE = 1000

-- position index 
local col = 0
local row = 0

-- block reference
local curBlock
local nextBlock
local ghostBlock

-- state table
local stateArray = {}

-- state status
local tBLOCK = 1
local tBLINK = 2
local tGHOST = 3

-- player score
local score = 0

-- player stage
local stage = 0

-- filling rows
local filledRows = {}

-- label
local score_label

-- handing touch events
local touchBeginPoint = nil
local inputDirection = nil
local UP
local DOWN
local LEFT
local RIGHT

-- 8 type of blokcs
-- use coordinates, (0, 0) is original point, and other are offset
local blockType = {
         {{0,0}, {1,0}, {2,0}, {-1,0}}, -- 棒形
         {{0,0}, {0,1}, {1,0}, {1,1}}, -- 正方形
         {{0,0}, {-1,0}, {0,1}, {1,1}}, -- S字
         {{0,0}, {-1,1}, {0,1}, {1,0}}, -- Z字
         {{0,0}, {-1,-1}, {0,-1}, {0,1}}, -- J字
         {{0,0}, {-2,0}, {-1,0}, {0,1}}, -- L字
         {{0,0}, {0,-1}, {0,1}, {1,0}},-- T字
     }

-- Block class
Block = {}
Block.__index = Block
function Block:new(centerRow, centerCol)
    local new_obj = {}
    setmetatable(new_obj, self)
    
    -- init position parameters
    new_obj.centerRow = centerRow
    new_obj.centerCol = centerCol
    new_obj.diffRow = {}
    new_obj.diffCol = {}
    
    -- use random to init type
    local type = math.random(7)
    -- init offset
    for i = 0, 3 do
        new_obj.diffRow[i] = blockType[type][i + 1][1]
        new_obj.diffCol[i] = blockType[type][i + 1][2]
    end

    return new_obj
end

function Block:draw(targetRow, targetCol)

    targetRow = targetRow or self.centerRow
    targetCol = targetCol or self.centerCol
    
    for i = 0, 3 do
        local sprite = CCSprite:create("YellowBlock.png")
        sprite:setPosition(ccp(targetRow * BLOCK_WIDTH + self.diffRow[i] * BLOCK_WIDTH, targetCol * BLOCK_HEIGHT + self.diffCol[i] * BLOCK_HEIGHT))
        gameLayer:addChild(sprite)                            
    end
end

---------------------------------------------
----------       Game Logic     -------------
---------------------------------------------

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(msg) .. "\n")
    print(debug.traceback())
    print("----------------------------------------")
end

local cclog = function(...)
    print(string.format(...))
end

local function resetStateArray()
    for row = 0, MAX_ROW - 1 do
        for col = 1, MAX_COL do
            stateArray[row][col] = 0
        end
    end
end

local function resetGhostBlock() 
    for row = 0, MAX_ROW - 1 do
        for col = 1, MAX_COL do
            if stateArray[row][col] == tGHOST then
                stateArray[row][col] = 0
            end
        end
    end
end

local function initStateArray()
    -- mark top, left and right side to 1 
    -- to make as bound
    for row = 0, MAX_ROW do
        stateArray[row] = {}
        for col = 0, MAX_COL + 1 do
            stateArray[row][col] = 0
        end
    end

    -- top bound
    for i = 0, MAX_COL + 1 do
        stateArray[MAX_ROW][i] = 1
    end

    -- left and right side bound
    for i = 0, MAX_ROW - 1 do
        stateArray[i][0] = 1
        stateArray[i][MAX_COL + 1] = 1
    end
end

local function inField(targetRow, targetCol)
    return targetRow < MAX_ROW and targetRow >=0 and targetCol >= 0 and targetCol <= MAX_COL + 1
end

local function updateStateByBlock(tmpBlock, stateVal)
    local tmpRow
    local tmpCol

    for i=0, 3 do
        tmpRow = tmpBlock.centerRow + tmpBlock.diffRow[i]
        tmpCol = tmpBlock.centerCol + tmpBlock.diffCol[i]
        if inField(tmpRow, tmpCol) then
            stateArray[tmpRow][tmpCol] = stateVal
        end
    end
end

local function drawBlockUnit(row, col, image_name)
    local sprite = CCSprite:create(image_name)
    sprite:setAnchorPoint(ccp(0, 0))
    sprite:setPosition(col * BLOCK_WIDTH, row * BLOCK_HEIGHT)
    gameLayer:addChild(sprite)
end

local function blockMove()
    
end

-- create game layer
local function createGameLayer()
    ----------------------------
    ---- method definition -----
    ----------------------------
    
    local function drawNextBlock()
        nextBlock:draw(13.5, 15)
    end

    --フレーム内でチェック
    local function onUpdate(dt)

        -- remove all child
        gameLayer:removeAllChildrenWithCleanup(true)
        
        -- init Label UI
        local score_str_label = CCLabelTTF:create("Score", "Arial", 20)
        score_str_label:setPosition(visibleSize.width - BLOCK_WIDTH * 2, visibleSize.height - BLOCK_WIDTH * 2)
        gameLayer:addChild(score_str_label)

        -- init score label
        score_label = CCLabelTTF:create("0", "Arial", 20)
        score_label:setPosition(visibleSize.width - BLOCK_WIDTH * 2, visibleSize.height - BLOCK_WIDTH * 4)
        gameLayer:addChild(score_label)
    
        local next_str_label = CCLabelTTF:create("Next", "Arial", 20)
        next_str_label:setPosition(visibleSize.width - BLOCK_WIDTH * 2, visibleSize.height - BLOCK_WIDTH * 6)
        gameLayer:addChild(next_str_label)
        -- update score
        score_label:setString(tostring(score))
        
        -- init next block UI
        drawNextBlock()

        -- draw left and right bound
        for i = 0, MAX_ROW - 1 do
            drawBlockUnit(i, MAX_COL + 1, "GrayBlock.png")
            drawBlockUnit(i, 0, "GrayBlock.png")  
        end

        -- draw top bound
        for i = 0, MAX_COL + 1 do
            drawBlockUnit(MAX_ROW, i, "RedBlock.png")
        end

        -- draw current block
        for row = 0, MAX_ROW - 1 do
            for col = 1, MAX_COL do
                if stateArray[row][col] == tBLOCK then
                    drawBlockUnit(row, col, "YellowBlock.png")
                end
            end
        end
        
        -- draw control pad
        UP = CCSprite:create("up.png")
        UP:setPosition(visibleSize.width - BLOCK_WIDTH * 2, visibleSize.height - BLOCK_WIDTH * 15)
        gameLayer:addChild(UP)

        DOWN = CCSprite:create("down.png")
        DOWN:setPosition(visibleSize.width - BLOCK_WIDTH * 2, visibleSize.height - BLOCK_WIDTH * 18)
        gameLayer:addChild(DOWN)

        LEFT = CCSprite:create("left.png")
        LEFT:setPosition(visibleSize.width - BLOCK_WIDTH * 3, visibleSize.height - BLOCK_WIDTH * 16.5)
        gameLayer:addChild(LEFT)

        RIGHT = CCSprite:create("right.png")
        RIGHT:setPosition(visibleSize.width - BLOCK_WIDTH * 1, visibleSize.height - BLOCK_WIDTH * 16.5)
        gameLayer:addChild(RIGHT)
    end 

    local function isGameOver()
        local gameOver = false
        for i = 0, 3 do
            tmpRow = curBlock.centerRow + curBlock.diffRow[i]
            tmpCol = curBlock.centerCol + curBlock.diffCol[i]
            if stateArray[tmpRow][tmpCol] == 1 then
                gameOver = true
                break
            end
        end
        return gameOver
    end

    local function checkGameOver()
        if isGameOver() then
            cclog("game over")
        end
    end

    local function genNextBlock()
        curBlock = nextBlock
        nextBlock = Block:new(INIT_ROW, INIT_COL)
        checkGameOver()
    end

    -- init game
    local function initGame()
        
        -- init state array
        initStateArray()

        ghostBlock = Block:new(INIT_ROW, INIT_COL)
        nextBlock = Block:new(INIT_ROW, INIT_COL)

        -- generate next block
        genNextBlock()

        -- update stateArray
        updateStateByBlock(curBlock, 1)
    end

    -- add touch event callback
    local function onTouchBegan(x, y)
        cclog("onTouchBegan: %0.2f, %0.2f", x, y)
        touchBeginPoint = {x = x, y = y}
        
        -- CCTOUCHBEGAN event must return true
        return true
    end

    local function onTouchMoved(x, y)
        cclog("onTouchMoved: %0.2f, %0.2f", x, y)
        if touchBeginPoint then
            touchBeginPoint = {x = x, y = y}
        end
    end

    local function onTouchEnded(x, y)
        cclog("onTouchEnded: %0.2f, %0.2f", x, y)
        touchBeginPoint = nil
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return onTouchBegan(x, y)
        elseif eventType == "moved" then
            return onTouchMoved(x, y)
        else
            return onTouchEnded(x, y)
        end
    end

    ------------------------
    ---- Game Logic  -------
    ------------------------
    gameLayer = CCLayer:create()
        
    -- add in game layer background
    local bg = CCSprite:create("backscreen00.png")
    bg:setPosition(visibleSize.width / 2, visibleSize.height / 2)
    -- gameLayer:addChild(bg)

    -- init Game
    initGame()

    -- register touch event
    gameLayer:registerScriptTouchHandler(onTouch)
    gameLayer:setTouchEnabled(true)

    -- execute update function per frame
    gameLayer:scheduleUpdateWithPriorityLua(onUpdate, 0)

    return gameLayer
end

local function main()
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    -- import other module
    require "hello2"
    cclog("result is " .. myadd(3, 5))

    -- play background music, preload effect
    local bgMusicPath = CCFileUtils:sharedFileUtils():fullPathForFilename("background.mp3")
    --SimpleAudioEngine:sharedEngine():playBackgroundMusic(bgMusicPath, true)
    
    local effectPath = CCFileUtils:sharedFileUtils():fullPathForFilename("effect1.wav")
    SimpleAudioEngine:sharedEngine():preloadEffect(effectPath)

    local sceneGame = CCScene:create()

    -- add layer
    sceneGame:addChild(createGameLayer())
    --sceneGame:addChild(createLayerMenu())
    
    -- run game
    CCDirector:sharedDirector():runWithScene(sceneGame)
end

xpcall(main, __G__TRACKBACK__)










    -- add the moving dog
    local function creatDog()
        local frameWidth = 105
        local frameHeight = 95

        -- create dog animate
        local textureDog = CCTextureCache:sharedTextureCache():addImage("dog.png")
        local rect = CCRectMake(0, 0, frameWidth, frameHeight)
        local frame0 = CCSpriteFrame:createWithTexture(textureDog, rect)
        rect = CCRectMake(frameWidth, 0, frameWidth, frameHeight)
        local frame1 = CCSpriteFrame:createWithTexture(textureDog, rect)

        local spriteDog = CCSprite:createWithSpriteFrame(frame0)
        spriteDog.isPaused = false
        spriteDog:setPosition(origin.x, origin.y + visibleSize.height / 4 * 3)

        local animFrames = CCArray:create()

        animFrames:addObject(frame0)
        animFrames:addObject(frame1)

        local animation = CCAnimation:createWithSpriteFrames(animFrames, 0.5)
        local animate = CCAnimate:create(animation);
        spriteDog:runAction(CCRepeatForever:create(animate))

        -- moving dog at every frame
        local function tick()
            if spriteDog.isPaused then return end
            local x, y = spriteDog:getPosition()
            if x > origin.x + visibleSize.width then
                x = origin.x
            else
                x = x + 1
            end

            spriteDog:setPositionX(x)
        end

        CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(tick, 0, false)

        return spriteDog
    end
    
    
    -- create farm
    local function createLayerFarm()
        local layerFarm = CCLayer:create()

        -- add in farm background
        local bg = CCSprite:create("farm.jpg")
        bg:setPosition(origin.x + visibleSize.width / 2 + 80, origin.y + visibleSize.height / 2)
        layerFarm:addChild(bg)

        -- add land sprite
        for i = 0, 3 do
            for j = 0, 1 do
                local spriteLand = CCSprite:create("land.png")
                spriteLand:setPosition(200 + j * 180 - i % 2 * 90, 10 + i * 95 / 2)
                layerFarm:addChild(spriteLand)
            end
        end

        -- add crop
        local frameCrop = CCSpriteFrame:create("crop.png", CCRectMake(0, 0, 105, 95))
        for i = 0, 3 do
            for j = 0, 1 do
                local spriteCrop = CCSprite:createWithSpriteFrame(frameCrop);
                spriteCrop:setPosition(10 + 200 + j * 180 - i % 2 * 90, 30 + 10 + i * 95 / 2)
                layerFarm:addChild(spriteCrop)
            end
        end

        -- add moving dog
        local spriteDog = creatDog()
        layerFarm:addChild(spriteDog)

        -- handing touch events
        local touchBeginPoint = nil

        local function onTouchBegan(x, y)
            cclog("onTouchBegan: %0.2f, %0.2f", x, y)
            touchBeginPoint = {x = x, y = y}
            spriteDog.isPaused = true
            -- CCTOUCHBEGAN event must return true
            return true
        end

        local function onTouchMoved(x, y)
            cclog("onTouchMoved: %0.2f, %0.2f", x, y)
            if touchBeginPoint then
                local cx, cy = layerFarm:getPosition()
                layerFarm:setPosition(cx + x - touchBeginPoint.x,
                                      cy + y - touchBeginPoint.y)
                touchBeginPoint = {x = x, y = y}
            end
        end

        local function onTouchEnded(x, y)
            cclog("onTouchEnded: %0.2f, %0.2f", x, y)
            touchBeginPoint = nil
            spriteDog.isPaused = false
        end

        local function onTouch(eventType, x, y)
            if eventType == "began" then   
                return onTouchBegan(x, y)
            elseif eventType == "moved" then
                return onTouchMoved(x, y)
            else
                return onTouchEnded(x, y)
            end
        end
          
        layerFarm:registerScriptTouchHandler(onTouch)
        layerFarm:setTouchEnabled(true)

 

        return layerFarm
    end


    -- create menu
    local function createLayerMenu()
        local layerMenu = CCLayer:create()

        local menuPopup, menuTools, effectID

        local function menuCallbackClosePopup()
            -- stop test sound effect
            SimpleAudioEngine:sharedEngine():stopEffect(effectID)
            menuPopup:setVisible(false)
        end

        local function menuCallbackOpenPopup()
            -- loop test sound effect
            local effectPath = CCFileUtils:sharedFileUtils():fullPathForFilename("effect1.wav")
            effectID = SimpleAudioEngine:sharedEngine():playEffect(effectPath)
            menuPopup:setVisible(true)
        end

        -- add a popup menu
        local menuPopupItem = CCMenuItemImage:create("menu2.png", "menu2.png")
        menuPopupItem:setPosition(0, 0)
        menuPopupItem:registerScriptTapHandler(menuCallbackClosePopup)
        menuPopup = CCMenu:createWithItem(menuPopupItem)
        menuPopup:setPosition(origin.x + visibleSize.width / 2, origin.y + visibleSize.height / 2)
        menuPopup:setVisible(false)
        layerMenu:addChild(menuPopup)

        -- add the left-bottom "tools" menu to invoke menuPopup
        local menuToolsItem = CCMenuItemImage:create("menu1.png", "menu1.png")
        menuToolsItem:setPosition(0, 0)
        menuToolsItem:registerScriptTapHandler(menuCallbackOpenPopup)
        menuTools = CCMenu:createWithItem(menuToolsItem)
        local itemWidth = menuToolsItem:getContentSize().width
        local itemHeight = menuToolsItem:getContentSize().height
        menuTools:setPosition(origin.x + itemWidth/2, origin.y + itemHeight/2)
        layerMenu:addChild(menuTools)

        return layerMenu
    end

