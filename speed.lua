local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Усиленные настройки прыжков
local SPEED = 86
local PUSH_FORCE = 1
local BASE_JUMP_POWER = 89 -- Увеличенная сила обычного прыжка (было 55)
local AIR_JUMP_POWER = 89 -- Увеличенная сила воздушного прыжка (было 35)
local MAX_AIR_JUMPS = 40 -- Увеличенное количество воздушных прыжков (было 3)
local SLIDE_FACTOR = 0.95
local JUMP_COOLDOWN = 0.2 -- Задержка между прыжками

-- Состояние
local airJumpsUsed = 0
local lastJumpTime = 0
local isOnGround = true
local canJump = true

-- Удаление анимаций
for _,v in pairs(character:GetChildren()) do
    if v:IsA("LocalScript") and v.Name ~= "HealthScript" then
        v:Destroy()
    end
end

-- Функция "пидорения"
local function applyWiggle()
    local randomForce = Vector3.new(
        (math.random() - 0.5) * PUSH_FORCE,
        0,
        (math.random() - 0.5) * PUSH_FORCE
    )
    rootPart.Velocity = rootPart.Velocity + randomForce
end

-- Проверка земли с улучшенной детекцией
local function checkGround()
    local rayOrigin = rootPart.Position
    local rayDirection = Vector3.new(0, -3.5, 0) -- Увеличенная дистанция проверки
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return rayResult ~= nil
end

-- Основной цикл
game:GetService("RunService").Heartbeat:Connect(function()
    local input = game:GetService("UserInputService")
    local camera = workspace.CurrentCamera
    
    -- Обновление состояния
    isOnGround = checkGround()
    if isOnGround then
        airJumpsUsed = 0
        canJump = true
    end
    
    -- Движение
    local moveDir = Vector3.new(0,0,0)
    if input:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
    if input:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
    if input:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
    if input:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
    
    moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit * SPEED
    local currentVelocity = rootPart.Velocity * Vector3.new(1,0,1)
    local newVelocity = currentVelocity:Lerp(moveDir, 0.2)
    rootPart.Velocity = Vector3.new(newVelocity.X, rootPart.Velocity.Y, newVelocity.Z)
    
    applyWiggle()
    
    if moveDir.Magnitude == 0 then
        rootPart.Velocity = Vector3.new(
            rootPart.Velocity.X * SLIDE_FACTOR,
            rootPart.Velocity.Y,
            rootPart.Velocity.Z * SLIDE_FACTOR
        )
    end
end)

-- Улучшенная система прыжков
game:GetService("UserInputService").JumpRequest:Connect(function()
    local now = tick()
    
    if not canJump then return end
    
    -- Обычный прыжок с земли
    if isOnGround then
        rootPart.Velocity = Vector3.new(
            rootPart.Velocity.X,
            BASE_JUMP_POWER,
            rootPart.Velocity.Z
        )
        lastJumpTime = now
    -- Воздушный прыжок
    elseif airJumpsUsed < MAX_AIR_JUMPS then
        rootPart.Velocity = Vector3.new(
            rootPart.Velocity.X,
            AIR_JUMP_POWER,
            rootPart.Velocity.Z
        )
        airJumpsUsed = airJumpsUsed + 1
        lastJumpTime = now
    end
    
    -- Задержка между прыжками
    canJump = false
    task.delay(JUMP_COOLDOWN, function()
        canJump = true
    end)
end)

-- Регулировка скорости
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Equals then
        SPEED = SPEED + 5
    elseif input.KeyCode == Enum.KeyCode.Minus then
        SPEED = math.max(5, SPEED - 5)
    end
end)

-- Респавн
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    airJumpsUsed = 0
end)
-- Скрипт для отображения игроков через стены с улучшенной видимостью

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Настройки визуализации
local SETTINGS = {
    BOX_COLOR = Color3.fromRGB(255, 50, 50), -- Ярко-красный цвет для лучшей заметности
    BOX_SIZE = Vector3.new(3, 5, 3), -- Размер коробки (ширина, высота, глубина)
    BOX_TRANSPARENCY = 0.2, -- Прозрачность коробки
    
    TEXT_COLOR = Color3.fromRGB(255, 255, 255), -- Белый текст
    TEXT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0), -- Черная обводка
    TEXT_SIZE = 18, -- Размер текста
    TEXT_OFFSET = Vector3.new(0, 3.5, 0), -- Смещение текста над коробкой
    
    SEE_THROUGH_WALLS = true, -- Видимость через стены
    UPDATE_RATE = 0.1 -- Частота обновления (в секундах)
}

-- Создаем визуализацию для игрока
local function createPlayerIndicator(player)
    if player == Players.LocalPlayer then return end -- Пропускаем себя

    -- Создаем коробку
    local box = Instance.new("Part")
    box.Name = "PlayerIndicator_"..player.Name
    box.Anchored = true
    box.CanCollide = false
    box.CanTouch = false
    box.CanQuery = false
    box.Transparency = SETTINGS.BOX_TRANSPARENCY
    box.Color = SETTINGS.BOX_COLOR
    box.Size = SETTINGS.BOX_SIZE
    box.Material = Enum.Material.Neon
    box.TopSurface = Enum.SurfaceType.Smooth
    box.BottomSurface = Enum.SurfaceType.Smooth

    -- Настройка видимости через стены
    if SETTINGS.SEE_THROUGH_WALLS then
        box.LocalTransparencyModifier = 0
    end

    -- Создаем текст с ником
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerNameTag"
    billboard.Size = UDim2.new(4, 0, 1, 0)
    billboard.StudsOffset = SETTINGS.TEXT_OFFSET
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 999999
    billboard.SizeOffset = Vector2.new(0, 0)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = player.Name
    textLabel.TextColor3 = SETTINGS.TEXT_COLOR
    textLabel.TextSize = SETTINGS.TEXT_SIZE
    textLabel.TextStrokeTransparency = 0.3
    textLabel.TextStrokeColor3 = SETTINGS.TEXT_OUTLINE_COLOR
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextScaled = false
    textLabel.Parent = billboard

    -- Функция обновления позиции
    local function updatePosition(character)
        if not character or not character.PrimaryPart then return end
        
        local rootPart = character.PrimaryPart
        local lastUpdate = time()
        
        -- Соединение для обновления позиции
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not rootPart or not rootPart.Parent then
                connection:Disconnect()
                return
            end
            
            -- Оптимизация: обновляем позицию с заданной частотой
            if time() - lastUpdate >= SETTINGS.UPDATE_RATE then
                box.CFrame = rootPart.CFrame * CFrame.new(0, 0, 0)
                
                -- Прикрепляем текст если еще не прикреплен
                if not billboard.Parent then
                    billboard.Adornee = rootPart
                    billboard.Parent = box
                end
                
                lastUpdate = time()
            end
        end)
    end

    -- Обработка персонажа
    local function handleCharacter(character)
        -- Удаляем старые индикаторы если есть
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "PlayerIndicator_"..player.Name then
                obj:Destroy()
            end
        end

        updatePosition(character)
        box.Parent = workspace
    end

    -- Подключаем обработчики
    player.CharacterAdded:Connect(handleCharacter)
    player.CharacterRemoving:Connect(function()
        box:Destroy()
    end)

    -- Инициализация для существующего персонажа
    if player.Character then
        handleCharacter(player.Character)
    end
end

-- Инициализация для всех игроков
Players.PlayerAdded:Connect(createPlayerIndicator)

for _, player in ipairs(Players:GetPlayers()) do
    createPlayerIndicator(player)
end

-- Очистка при выходе игрока
Players.PlayerRemoving:Connect(function(player)
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "PlayerIndicator_"..player.Name then
            obj:Destroy()
        end
    end
end)
