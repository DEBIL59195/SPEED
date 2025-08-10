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
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- Конфигурация
local ESP_SETTINGS = {
    UpdateInterval = 0.5,
    MaxDistance = 500,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    PartColors = {
        Color3.new(1, 1, 1),    -- Белый
        Color3.new(0.2, 0.6, 1),-- Синий
        Color3.new(1, 0.2, 0.2) -- Красный
    },
    SoundId = "rbxassetid://130785805",
    SoundVolume = 1.5,
    PlaySoundOnce = false
}

-- Список объектов с эмодзи
local OBJECT_EMOJIS = {
    ["La Vacca Saturno Saturnita"] = "🐮",
    ["Chimpanzini Spiderini"] = "🕷",
    ["Los Tralaleritos"] = "🐟",
    ["Las Tralaleritas"] = "🌸",
    ["Graipuss Medussi"] = "🦑",
    ["Torrtuginni Dragonfrutini"] = "🐉",
    ["Pot Hotspot"] = "📱",
    ["La Grande Combinasion"] = "❗️",
    ["Garama and Madundung"] = "🥫",
    ["Secret Lucky Block"] = "⬛️",
    ["Brainrot God Lucky Block"] = "🟦",
    ["Nuclearo Dinossauro"] = "🦕",
    ["Las Vaquitas Saturnitas"] = "👦",
    ["Chicleteira Bicicleteira"] = "🚲",
    ["Los Combinasionas"] = "⚒️",
    ["Agarrini la Palini"] = "🥄"
}

-- Список отслеживаемых объектов
local OBJECT_NAMES = {
    "La Vacca Saturno Saturnita",
    "Chimpanzini Spiderini",
    "Los Tralaleritos",
    "Las Tralaleritas",
    "Graipuss Medussi",
    "Torrtuginni Dragonfrutini",
    "Pot Hotspot",
    "La Grande Combinasion",
    "Garama and Madundung",
    "Secret Lucky Block",
    "Brainrot God Lucky Block",
    "Nuclearo Dinossauro",
    "Las Vaquitas Saturnitas",
    "Chicleteira Bicicleteira",
    "Los Combinasionas",
    "Agarrini la Palini"
}

-- Системные переменные
local camera = workspace.CurrentCamera
local espCache = {}
local lastUpdate = 0
local foundObjects = {}

-- Создаем ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleESP"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

-- Создаем индикатор ESP: ON
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "ESPStatus"
statusLabel.Text = "ESP: ON"
statusLabel.TextColor3 = Color3.fromRGB(50, 200, 50) -- Зеленый цвет
statusLabel.TextSize = 20
statusLabel.Font = Enum.Font.GothamBold
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 10, 0, 10)
statusLabel.Size = UDim2.new(0, 100, 0, 30)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
statusLabel.TextStrokeTransparency = 0.5
statusLabel.Parent = screenGui

-- Функция воспроизведения звука обнаружения
local function playDetectionSound()
    local sound = Instance.new("Sound")
    sound.SoundId = ESP_SETTINGS.SoundId
    sound.Volume = ESP_SETTINGS.SoundVolume
    sound.Parent = workspace
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 3)
end

-- Функция создания цветного текста
local function createColoredText(name)
    local emoji = OBJECT_EMOJIS[name] or "🔹"
    local displayName = emoji .. " " .. name
    
    local parts = {}
    for part in displayName:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextSize = ESP_SETTINGS.TextSize
    textLabel.Font = ESP_SETTINGS.Font
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.TextStrokeTransparency = 0.3
    
    local richText = ""
    for i, part in ipairs(parts) do
        local colorIndex = math.min(i, #ESP_SETTINGS.PartColors)
        local color = ESP_SETTINGS.PartColors[colorIndex]
        local hexColor = string.format(
            "rgb(%d,%d,%d)", 
            math.floor(color.r * 255),
            math.floor(color.g * 255),
            math.floor(color.b * 255)
        )
        richText = richText .. string.format('<font color="%s"><b>%s</b></font> ', hexColor, part)
    end
    
    textLabel.Text = richText
    textLabel.RichText = true
    
    return textLabel
end

-- Функция создания элемента ESP
local function createESPElement(obj)
    local rootPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj
    if not rootPart then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 350, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = ESP_SETTINGS.MaxDistance
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    
    local textLabel = createColoredText(obj.Name)
    textLabel.Parent = billboard
    
    billboard.Adornee = rootPart
    billboard.Parent = screenGui
    
    return {
        labelGui = billboard,
        label = textLabel,
        rootPart = rootPart,
        object = obj
    }
end

-- Функция обновления ESP
local function updateESP(deltaTime)
    lastUpdate = lastUpdate + deltaTime
    if lastUpdate < ESP_SETTINGS.UpdateInterval then return end
    lastUpdate = 0

    -- Очистка несуществующих объектов
    for obj, data in pairs(espCache) do
        if not obj.Parent or not data.rootPart.Parent then
            data.labelGui:Destroy()
            espCache[obj] = nil
            foundObjects[obj] = nil
        end
    end

    -- Поиск новых объектов
    for _, obj in ipairs(workspace:GetDescendants()) do
        if table.find(OBJECT_NAMES, obj.Name) and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local rootPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj
            if not rootPart then continue end

            local distance = (rootPart.Position - camera.CFrame.Position).Magnitude
            if distance > ESP_SETTINGS.MaxDistance then
                if espCache[obj] then
                    espCache[obj].labelGui.Enabled = false
                end
                continue
            end

            local isNewObject = not foundObjects[obj]
            foundObjects[obj] = true

            if not espCache[obj] then
                espCache[obj] = createESPElement(obj)
                if isNewObject then
                    playDetectionSound()
                end
            end

            local data = espCache[obj]
            local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            data.labelGui.Enabled = onScreen
        end
    end
end

-- Запуск системы
RunService.Heartbeat:Connect(updateESP)

-- Обработка новых игроков
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        updateESP(0)
    end)
end)

-- Первоначальное сканирование
updateESP(0)

print("Simple ESP System активирован!")
print("Отслеживается объектов: "..#OBJECT_NAMES)
