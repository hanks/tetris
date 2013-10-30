------------------------------------
-----  User Define Variable --------
------------------------------------

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
function Block:new(curRow, curCol)
    local new_obj = {}
    setmetable(new_obj, self)
    
    -- init position parameters
    new_obj.curRow = curRow
    new_obj.curCol = curCol
    new_obj.diffRow = {}
    new_obj.diffCol = {}
    
    -- use random to init type
    local type = math.random(7)

    -- init offset
    for i = 1, 4 do
        new_obj.diffRow[i] = blockType[type][i][0]
        new_obj.diffCol[i] = blockType[type][i][1]
    end

    return new_obj
end

-- max row and col of tetris table 
local MAX_ROW = 29
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

-- player score
local score = 0

-- player stage
local stage = 0

-- filling rows
local filledRows = {}


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

local function initStateArray()
    for row = 0, MAX_ROW - 1 do
        stateArray[row] = {}
        for col = 1, MAX_COL do
            stateArray[row][col] = 0
        end
    end
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
            if stateArray[row][col] == 3 then
                stateArray[row][col] = 0
            end
        end
    end
end

-- create game layer
local function createGameLayer()
    local gameLayer = CCLayer:create()

    -- get screen size
    local visibleSize = CCDirector:sharedDirector():getVisibleSize()
    local origin = CCDirector:sharedDirector():getVisibleOrigin()
        
    -- add in game layer background
    local bg = CCSprite:create("backscreen00.png")
    bg:setPosition(visibleSize.width / 2, visibleSize.height / 2)
    gameLayer:addChild(bg)

    -- handing touch events
    local touchBeginPoint = nil

    ----------------------------
    ---- method definition -----
    ----------------------------
    
    --フレーム内でチェック
    local function onUpdate(dt)

    end

    -- init game
    local function initGame()
    
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
    
    -- register touch event
    gameLayer:registerScriptTouchHandler(onTouch)
    gameLayer:setTouchEnabled(true)
    
    -- add update function
    gameLayer:scheduleUpdateWithPriorityLua(onUpdate, 0)
    
    return gameLayer
end

local function main()
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    -- import test
    require "hello2"
    cclog("result is " .. myadd(3, 5))

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

    -- play background music, preload effect
    local bgMusicPath = CCFileUtils:sharedFileUtils():fullPathForFilename("background.mp3")
    --SimpleAudioEngine:sharedEngine():playBackgroundMusic(bgMusicPath, true)
    
    local effectPath = CCFileUtils:sharedFileUtils():fullPathForFilename("effect1.wav")
    SimpleAudioEngine:sharedEngine():preloadEffect(effectPath)

    -- run
    local sceneGame = CCScene:create()

    -- add layer
    sceneGame:addChild(createGameLayer())
    --sceneGame:addChild(createLayerMenu())
    
    -- run game
    CCDirector:sharedDirector():runWithScene(sceneGame)
end

xpcall(main, __G__TRACKBACK__)
