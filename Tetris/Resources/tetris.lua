------------------------------------
-----  User Define Variable --------
------------------------------------
-- sound
local effectPath
local bgMusicPath

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

local isFirstGrounded = false

-- label
local score_label

-- game running flag
local isRunning = true

-- handing touch events
local touchBeginPoint = nil
local inputDirection = nil
local UP
local DOWN
local LEFT
local RIGHT

-- frame count timer
local frameCount = 0

-- filling line count
local countedFill

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

local function resetFilledRows()
    for i = 0, MAX_ROW do
        filledRows[i] = -1
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

-- whether in the active area
local function inField(targetRow, targetCol)
    return targetRow < MAX_ROW and targetRow >=0 and targetCol >= 1 and targetCol <= MAX_COL
end

-- update state array by state value
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
        isRunning = false
    end
end

local function genNextBlock()
    curBlock = nextBlock
    nextBlock = Block:new(INIT_ROW, INIT_COL)
    checkGameOver()
end

local function drawBlockUnit(row, col, image_name)
    local sprite = CCSprite:create(image_name)
    sprite:setAnchorPoint(ccp(0, 0))
    sprite:setPosition(col * BLOCK_WIDTH, row * BLOCK_HEIGHT)
    gameLayer:addChild(sprite)
end

local function isCollision(targetRow, targetCol, tmpBlock)
    local result = false
    updateStateByBlock(tmpBlock, 0)
	for i = 0, 3 do
	    local tmpRow = targetRow + tmpBlock.diffRow[i]
	    local tmpCol = targetCol + tmpBlock.diffCol[i]
	    if not inField(tmpRow, tmpCol) or stateArray[tmpRow][tmpCol] == 1 then
	        result = true
	        break
	    end
	end    
	updateStateByBlock(tmpBlock, 1)
    return result
end

local function isGrounded() 
    return isCollision(curBlock.centerRow + 1, curBlock.centerCol, curBlock)
end

local function getGroundedCenterRow(curRow, curCol)
    for i = curRow, MAX_ROW - 1 do
        if isCollision(i + 1, curCol, curBlock) then
            return i
        end
    end
    return MAX_ROW - 1
end

local function moveBlock2Position(tmpBlock, toRow, toCol)
    updateStateByBlock (tmpBlock, 0);
    tmpBlock.centerRow = toRow;
    tmpBlock.centerCol = toCol;
    updateStateByBlock (tmpBlock, 1);
end

local function rotation(targetRow, targetCol)
    local originalDiffRow = {}
    local originalDiffCol = {}
    
    -- back diff array
    for i = 0, 3 do
        originalDiffRow[i] = curBlock.diffRow[i]
        originalDiffCol[i] = curBlock.diffCol[i]
    end
    
    -- delete itself
    updateStateByBlock(curBlock, 0)
    
    local newDiffRow = {}
    local newDiffCol = {}
    
    -- rotato diff
    for i = 0, 3 do
        newDiffRow[i] = originalDiffCol[i]
        newDiffCol[i] = -originalDiffRow[i]
    end
    
    -- deteck collisition after rotation
    -- if has collisition, change diff array
    -- if no collisition, use new diff array
    local isCollision = false
    for i = 0, 3 do
        local tmpRow = targetRow + newDiffRow[i]
        local tmpCol = targetCol + newDiffCol[i]
        if not inField(tmpRow, tmpCol) or stateArray[tmpRow][tmpRow] == 1 then
            isCollision = true
        end
    end
    
    if isCollision then
        -- change back diff array
        for i = 0, 3 do
            curBlock.diffRow[i] = originalDiffRow[i]
            curBlock.diffCol[i] = originalDiffCol[i]
        end
    else
        -- use new diff
        for i = 0, 3 do
            curBlock.diffRow[i] = newDiffRow[i]
            curBlock.diffCol[i] = newDiffCol[i]
        end
    end
    
    -- set new block to draw
    updateStateByBlock(curBlock, tBLOCK)
end

local function isFillingLine(row) 
    local flag = true
    for col = 1, MAX_COL do
        if stateArray[row][col] == 0 then
            flag = false
            break
        end
    end
    return flag
end

local function setStateArrayByRow(row, val)
    for col = 1, MAX_COL do
        stateArray[row][col] = val
    end
end

local function cascadeMoveDown(targetRow, offset)
    setStateArrayByRow(targetRow - offset, 0)
    cclog("targetRow is %d, offset is %d\n", targetRow, offset)
    -- move remainder up to recovery
    for row = targetRow - offset, 1, -1 do
        for col = 1, MAX_COL do
            stateArray[row][col] = stateArray[row - 1][col]
            -- cclog("row is %d, col is %d, value is %d\n", row, col, stateArray[row][col])
        end
    end
end

local function cascade()
   local offset = 0
   for row = MAX_ROW - 1, 2, -1 do
       if filledRows[row] == 1 then
           cascadeMoveDown(row, offset)
           offset = offset + 1
       end
   end 
end

local function checkFilledLines() 
    local countLines = 0
    for row = MAX_ROW - 1, 1, -1 do
        if isFillingLine(row) then
            filledRows[row] = 1
            countLines = countLines + 1
        end
    end
    return countLines
end

local function blockMove()
    resetFilledRows()
    resetGhostBlock()
    
    local toRow = -1
    local toCol = -1
    
    if inputDirection == 'down' then
        toRow = curBlock.centerRow
        toCol = curBlock.centerCol
        rotation(toRow, toCol)
    elseif inputDirection == 'up' then
        toRow = getGroundedCenterRow(curBlock.centerRow, curBlock.centerCol)
        toCol = curBlock.centerCol
    elseif inputDirection == 'left' then
        toRow = curBlock.centerRow
        toCol = curBlock.centerCol - 1
    elseif inputDirection == 'right' then
        toRow = curBlock.centerRow
        toCol = curBlock.centerCol + 1
    end
    -- clear input
    inputDirection = ''
    
    -- auto move one step one second
    frameCount = frameCount + 1
    if frameCount > 60 then
    	toRow = curBlock.centerRow + 1
        toCol = curBlock.centerCol
        frameCount = 0
    end
    
    -- move block
    collision = isCollision(toRow, toCol, curBlock)
    if collision == false then
        moveBlock2Position(curBlock, toRow, toCol)
    end
    
    -- is ground
    if isGrounded() then
    	if isFirstGrounded == false then
    	    isFirstGrounded = true
    	    -- record time
    	end
    	
    	-- count score
    	countedFill = checkFilledLines()
    	if countedFill > 0 then
    	    -- player sound effect
    	    SimpleAudioEngine:sharedEngine():playEffect(effectPath)
    	    score = score + countedFill * SCORE_PER_LINE
    	end
    	
    	-- delete line
    	cascade()
    	
    	-- create new block
    	genNextBlock()
    else
        -- update ghost block postion
        ghostBlock.centerRow = getGroundedCenterRow(curBlock.centerRow, curBlock.centerCol);
        ghostBlock.centerCol = curBlock.centerCol;
        ghostBlock.diffRow = curBlock.diffRow;
        ghostBlock.diffCol = curBlock.diffCol;
        updateStateByBlock(ghostBlock, 3);
        isFirstGrounded = false;
    end
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
        if isRunning then
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
	        
	        -- draw ghost block
	        for row = 0, MAX_ROW - 1 do
	            for col = 1, MAX_COL do
	                if stateArray[row][col] == tGHOST then
	                    drawBlockUnit(row, col, "GrayBlock.png")
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
	
	        -- update block movement
	        blockMove()
	        
	    end
    end 

    -- detect touch on sprite or not    
    local function containsTouchLocation(sprite, point)
        local position = ccp(sprite:getPosition())
        local s = sprite:getTexture():getContentSize()
        local touchRect = CCRectMake(-s.width / 2 + position.x, -s.height / 2 + position.y, s.width, s.height)
        local b = touchRect:containsPoint(point)
        return b
    end

    -- init game
    local function initGame()
        
        -- init state array
        initStateArray()

        ghostBlock = Block:new(INIT_ROW, INIT_COL)
        nextBlock = Block:new(INIT_ROW, INIT_COL)

		frameCount = 0
		score = 0	
        
        isRunning = true
        
        -- generate next block
        genNextBlock()

        -- update stateArray
        updateStateByBlock(curBlock, 1)
    end

    -- add touch event callback
    local function onTouchBegan(x, y)
        cclog("onTouchBegan: %0.2f, %0.2f", x, y)
        touchBeginPoint = ccp(x, y)

        if containsTouchLocation(UP, touchBeginPoint) == true then
            cclog("UP")
            inputDirection = 'up'
        end

        if containsTouchLocation(DOWN, touchBeginPoint) == true then
            cclog("DOWN")
            inputDirection = 'down'
        end

        if containsTouchLocation(LEFT, touchBeginPoint) == true then
            cclog("LEFT")
            inputDirection = 'left'
        end

        if containsTouchLocation(RIGHT, touchBeginPoint) == true then
            cclog("RIGHT")
            inputDirection = 'right'
        end
        
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

local function createMainLayer()
    local mainLayer = CCLayer:create()
    local bg = CCSprite:create("top.png")
    bg:setPosition(visibleSize.width / 2, visibleSize.height / 2)
    mainLayer:addChild(bg)
    
    -- start action call back function
    local function onStartMenu(sender)
    	cclog("start game")
    	local nextScene = CCScene:create()
    	nextScene:addChild(createGameLayer())
    	CCDirector:sharedDirector():replaceScene(CCTransitionFade:create(0.5, nextScene))
    end
    
    -- add start menu
    local item = CCMenuItemImage:create("start_button.png", "start_button.png")
    item:registerScriptTapHandler(onStartMenu)
    local menu = CCMenu:create()
    menu:addChild(item)
    cclog("%d %d", visibleSize.width, visibleSize.height)
    menu:setPosition(visibleSize.width / 2, visibleSize.height / 2 - 150)
    mainLayer:addChild(menu)

    return mainLayer
end

local function main()
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    -- import other module
    require "hello2"
    cclog("result is " .. myadd(3, 5))

    -- play background music, preload effect
    bgMusicPath = CCFileUtils:sharedFileUtils():fullPathForFilename("background.mp3")
    SimpleAudioEngine:sharedEngine():playBackgroundMusic(bgMusicPath, true)
    SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(1)
    
    effectPath = CCFileUtils:sharedFileUtils():fullPathForFilename("effect1.wav")
    SimpleAudioEngine:sharedEngine():preloadEffect(effectPath)

    local sceneGame = CCScene:create()

    -- add layer
    sceneGame:addChild(createMainLayer())
    
    -- run game
    CCDirector:sharedDirector():runWithScene(sceneGame)
end

xpcall(main, __G__TRACKBACK__)