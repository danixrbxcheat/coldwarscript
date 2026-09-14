local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera 

-- === CONFIGURACIÓN (TODO APAGADO POR DEFECTO) ===
local CONFIG = {
    EspGlobal = false,
    MostrarCajas = false,
    MostrarNombres = false,
    MostrarArmas = false,
    MostrarLineas = false,
    MostrarDistancia = false, 
    OcultarTeam = false, 
    DistanciaMaxESP = 500,
    
    AimbotGlobal = false,
    MostrarFov = false,
    TeclaAimbot = Enum.KeyCode.T,
    TeclaMouse = nil, 
    DistanciaMaxAim = 300,
    MaxFovRadio = 150,
    Smoothness = 0.4, 
    
    Prediccion = 0.8, 
    VelocidadBalaEstimada = 800, 
    DistanciaCambioCabeza = 60,

    ModoApuntado = "EN MIRA",
    ModoTeclaAimbot = "TOGGLE"
}

local aimbotActivo = false
local objetivoActual = nil
local amigosCache = {}
local cambiandoKeybind = false
local ESP_Container = {}
local interfazCargada = false

local MODOS_APUNTADO = {"EN MIRA", "MAS CERCANO", "MAS LEJANO"}
local MODOS_TECLA = {"TOGGLE", "MANTENER"}

local UIStroke = nil
local FrameCirculo = nil

-- =========================================================
-- CREACIÓN DE GUIs
-- =========================================================
local ScreenGuiMaster = Instance.new("ScreenGui")
ScreenGuiMaster.Name = "MasterEngineUI"
ScreenGuiMaster.ResetOnSpawn = false
ScreenGuiMaster.DisplayOrder = 1000

local ScreenGuiESP = Instance.new("ScreenGui")
ScreenGuiESP.Name = "ESPRenderEngine"
ScreenGuiESP.ResetOnSpawn = false
ScreenGuiESP.DisplayOrder = 999

local LoadingGui1 = Instance.new("ScreenGui")
LoadingGui1.Name = "LoadingGui1"
LoadingGui1.ResetOnSpawn = false
LoadingGui1.DisplayOrder = 3000

local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "KeySystem"
KeyGui.ResetOnSpawn = false
KeyGui.DisplayOrder = 3000
KeyGui.Enabled = false

local LoadingGui2 = Instance.new("ScreenGui")
LoadingGui2.Name = "LoadingGui2"
LoadingGui2.ResetOnSpawn = false
LoadingGui2.DisplayOrder = 3000
LoadingGui2.Enabled = false

local exito, _ = pcall(function() 
    ScreenGuiMaster.Parent = CoreGui 
    ScreenGuiESP.Parent = CoreGui
    LoadingGui1.Parent = CoreGui
    KeyGui.Parent = CoreGui
    LoadingGui2.Parent = CoreGui
end)

if not exito then 
    ScreenGuiMaster.Parent = LocalPlayer:WaitForChild("PlayerGui") 
    ScreenGuiESP.Parent = LocalPlayer:WaitForChild("PlayerGui") 
    LoadingGui1.Parent = LocalPlayer:WaitForChild("PlayerGui")
    KeyGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    LoadingGui2.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- =========================================================
-- ⏳ PANTALLA DE CARGA INICIAL (6 SEGUNDOS) - ACTUALIZADA
-- =========================================================
local LoadingFrame1 = Instance.new("Frame")
LoadingFrame1.Size = UDim2.new(0, 520, 0, 460)
LoadingFrame1.Position = UDim2.new(0.5, -260, 0.5, -230)
LoadingFrame1.BackgroundColor3 = Color3.fromRGB(45, 65, 85)
LoadingFrame1.BorderSizePixel = 0
LoadingFrame1.Parent = LoadingGui1
Instance.new("UICorner", LoadingFrame1).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", LoadingFrame1).Color = Color3.fromRGB(90, 120, 150)
Instance.new("UIStroke", LoadingFrame1).Thickness = 1.5

local LoadingTitle1 = Instance.new("TextLabel")
LoadingTitle1.Size = UDim2.new(1, 0, 0, 60)
LoadingTitle1.Position = UDim2.new(0, 0, 0, 100)
LoadingTitle1.BackgroundTransparency = 1
LoadingTitle1.Text = "COLD WAR SCRIPT"
LoadingTitle1.TextColor3 = Color3.fromRGB(220, 235, 255)
LoadingTitle1.Font = Enum.Font.GothamBlack
LoadingTitle1.TextSize = 36
LoadingTitle1.ZIndex = 10
LoadingTitle1.Parent = LoadingFrame1

local LoadingSub1 = Instance.new("TextLabel")
LoadingSub1.Size = UDim2.new(1, 0, 0, 40)
LoadingSub1.Position = UDim2.new(0, 0, 0, 170)
LoadingSub1.BackgroundTransparency = 1
LoadingSub1.Text = "BY GLOCK19"
LoadingSub1.TextColor3 = Color3.fromRGB(150, 180, 210)
LoadingSub1.Font = Enum.Font.GothamBold
LoadingSub1.TextSize = 18
LoadingSub1.ZIndex = 10
LoadingSub1.Parent = LoadingFrame1

local LoadingBarBg1 = Instance.new("Frame")
LoadingBarBg1.Size = UDim2.new(0, 380, 0, 8)
LoadingBarBg1.Position = UDim2.new(0.5, -190, 0.75, 0)
LoadingBarBg1.BackgroundColor3 = Color3.fromRGB(35, 50, 70)
LoadingBarBg1.BorderSizePixel = 0
LoadingBarBg1.ZIndex = 10
LoadingBarBg1.Parent = LoadingFrame1
Instance.new("UICorner", LoadingBarBg1).CornerRadius = UDim.new(1, 0)

local LoadingBarFill1 = Instance.new("Frame")
LoadingBarFill1.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill1.BackgroundColor3 = Color3.fromRGB(140, 100, 255)
LoadingBarFill1.BorderSizePixel = 0
LoadingBarFill1.ZIndex = 11
LoadingBarFill1.Parent = LoadingBarBg1
Instance.new("UICorner", LoadingBarFill1).CornerRadius = UDim.new(1, 0)

local LoadingText1 = Instance.new("TextLabel")
LoadingText1.Size = UDim2.new(1, 0, 0, 30)
LoadingText1.Position = UDim2.new(0, 0, 0.75, 15)
LoadingText1.BackgroundTransparency = 1
LoadingText1.Text = "Cargando... 0%"
LoadingText1.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingText1.Font = Enum.Font.Gotham
LoadingText1.TextSize = 14
LoadingText1.ZIndex = 10
LoadingText1.Parent = LoadingFrame1

local tiempoCarga1 = 6
local inicioCarga1 = tick()

RunService.RenderStepped:Connect(function()
    if not LoadingGui1.Enabled then return end
    
    local alpha = math.clamp((tick() - inicioCarga1) / tiempoCarga1, 0, 1)
    LoadingBarFill1.Size = UDim2.new(alpha, 0, 1, 0)
    LoadingText1.Text = "Cargando... " .. tostring(math.floor(alpha * 100)) .. "%"

    if alpha >= 1 then
        LoadingGui1.Enabled = false
        LoadingGui1:Destroy()
        KeyGui.Enabled = true
    end
end)

-- =========================================================
-- 🔑 SISTEMA DE KEY
-- =========================================================
local KeyFrame = Instance.new("Frame")
KeyFrame.Size = UDim2.new(0, 320, 0, 180)
KeyFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
KeyFrame.BackgroundColor3 = Color3.fromRGB(45, 65, 85)
KeyFrame.BorderSizePixel = 0
KeyFrame.Parent = KeyGui
Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", KeyFrame).Color = Color3.fromRGB(90, 120, 150)
Instance.new("UIStroke", KeyFrame).Thickness = 1.5

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Size = UDim2.new(1, 0, 0, 40)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "Ingrese la Key"
KeyTitle.TextColor3 = Color3.fromRGB(220, 235, 255)
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextSize = 18
KeyTitle.ZIndex = 10
KeyTitle.Parent = KeyFrame

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(0, 280, 0, 35)
KeyInput.Position = UDim2.new(0, 20, 0, 50)
KeyInput.BackgroundColor3 = Color3.fromRGB(30, 45, 60)
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.Font = Enum.Font.Gotham
KeyInput.TextSize = 14
KeyInput.PlaceholderText = "Key aquí..."
KeyInput.PlaceholderColor3 = Color3.fromRGB(150, 170, 190)
KeyInput.ClearTextOnFocus = false
KeyInput.ZIndex = 10
KeyInput.Parent = KeyFrame
Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 4)

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Size = UDim2.new(0, 280, 0, 35)
SubmitBtn.Position = UDim2.new(0, 20, 0, 95)
SubmitBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 120)
SubmitBtn.Text = "Verificar"
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.TextSize = 14
SubmitBtn.ZIndex = 10
SubmitBtn.Parent = KeyFrame
Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 4)

local ErrorLabel = Instance.new("TextLabel")
ErrorLabel.Size = UDim2.new(1, 0, 0, 20)
ErrorLabel.Position = UDim2.new(0, 0, 1, 5)
ErrorLabel.BackgroundTransparency = 1
ErrorLabel.Text = "Key incorrecta."
ErrorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
ErrorLabel.Font = Enum.Font.Gotham
ErrorLabel.TextSize = 12
ErrorLabel.Visible = false
ErrorLabel.ZIndex = 10
ErrorLabel.Parent = KeyFrame

local VALID_KEY = "9381371397scriptbyGlock19x"

SubmitBtn.MouseButton1Click:Connect(function()
    if KeyInput.Text == VALID_KEY then
        KeyGui.Enabled = false
        KeyGui:Destroy()
        LoadingGui2.Enabled = true
        inicioCarga2 = tick()
    else
        ErrorLabel.Visible = true
        KeyInput.Text = ""
    end
end)

KeyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then SubmitBtn:Fire() end
end)

-- =========================================================
-- ⏳ SEGUNDA PANTALLA DE CARGA (4 SEGUNDOS)
-- =========================================================
local LoadingFrame2 = Instance.new("Frame")
LoadingFrame2.Size = UDim2.new(0, 520, 0, 460)
LoadingFrame2.Position = UDim2.new(0.5, -260, 0.5, -230)
LoadingFrame2.BackgroundColor3 = Color3.fromRGB(45, 65, 85)
LoadingFrame2.BorderSizePixel = 0
LoadingFrame2.Parent = LoadingGui2
Instance.new("UICorner", LoadingFrame2).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", LoadingFrame2).Color = Color3.fromRGB(90, 120, 150)
Instance.new("UIStroke", LoadingFrame2).Thickness = 1.5

local LoadingTitle2 = Instance.new("TextLabel")
LoadingTitle2.Size = UDim2.new(1, 0, 0, 60)
LoadingTitle2.Position = UDim2.new(0, 0, 0, 100)
LoadingTitle2.BackgroundTransparency = 1
LoadingTitle2.Text = "script COLD WAR"
LoadingTitle2.TextColor3 = Color3.fromRGB(220, 235, 255)
LoadingTitle2.Font = Enum.Font.GothamBlack
LoadingTitle2.TextSize = 36
LoadingTitle2.ZIndex = 10
LoadingTitle2.Parent = LoadingFrame2

local LoadingSub2 = Instance.new("TextLabel")
LoadingSub2.Size = UDim2.new(1, 0, 0, 30)
LoadingSub2.Position = UDim2.new(0, 0, 0, 170)
LoadingSub2.BackgroundTransparency = 1
LoadingSub2.Text = "by glock19x"
LoadingSub2.TextColor3 = Color3.fromRGB(150, 180, 210)
LoadingSub2.Font = Enum.Font.Gotham
LoadingSub2.TextSize = 14
LoadingSub2.ZIndex = 10
LoadingSub2.Parent = LoadingFrame2

local LoadingBarBg2 = Instance.new("Frame")
LoadingBarBg2.Size = UDim2.new(0, 380, 0, 8)
LoadingBarBg2.Position = UDim2.new(0.5, -190, 0.75, 0)
LoadingBarBg2.BackgroundColor3 = Color3.fromRGB(35, 50, 70)
LoadingBarBg2.BorderSizePixel = 0
LoadingBarBg2.ZIndex = 10
LoadingBarBg2.Parent = LoadingFrame2
Instance.new("UICorner", LoadingBarBg2).CornerRadius = UDim.new(1, 0)

local LoadingBarFill2 = Instance.new("Frame")
LoadingBarFill2.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill2.BackgroundColor3 = Color3.fromRGB(140, 100, 255)
LoadingBarFill2.BorderSizePixel = 0
LoadingBarFill2.ZIndex = 11
LoadingBarFill2.Parent = LoadingBarBg2
Instance.new("UICorner", LoadingBarFill2).CornerRadius = UDim.new(1, 0)

local LoadingText2 = Instance.new("TextLabel")
LoadingText2.Size = UDim2.new(1, 0, 0, 30)
LoadingText2.Position = UDim2.new(0, 0, 0.75, 15)
LoadingText2.BackgroundTransparency = 1
LoadingText2.Text = "Cargando... 0%"
LoadingText2.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingText2.Font = Enum.Font.Gotham
LoadingText2.TextSize = 14
LoadingText2.ZIndex = 10
LoadingText2.Parent = LoadingFrame2

local tiempoCarga2 = 4
local inicioCarga2 = 0

RunService.RenderStepped:Connect(function()
    if not LoadingGui2.Enabled then return end
    
    local alpha = math.clamp((tick() - inicioCarga2) / tiempoCarga2, 0, 1)
    LoadingBarFill2.Size = UDim2.new(alpha, 0, 1, 0)
    LoadingText2.Text = "Cargando... " .. tostring(math.floor(alpha * 100)) .. "%"

    if alpha >= 1 then
        LoadingGui2.Enabled = false
        LoadingGui2:Destroy()
        interfazCargada = true
    end
end)

-- =========================================================
-- 🛠️ INTERFAZ GRÁFICA PRINCIPAL (CON SCROLL)
-- =========================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 480) 
MainFrame.Position = UDim2.new(0.5, -260, 0.4, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 65, 85) 
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGuiMaster

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(90, 120, 150)
Instance.new("UIStroke", MainFrame).Thickness = 1.5

local TitleMain = Instance.new("TextLabel")
TitleMain.Size = UDim2.new(1, 0, 0, 50)
TitleMain.Position = UDim2.new(0, 0, 0, 10)
TitleMain.BackgroundTransparency = 1
TitleMain.Text = "script COLD WAR"
TitleMain.TextColor3 = Color3.fromRGB(220, 235, 255)
TitleMain.Font = Enum.Font.GothamBlack
TitleMain.TextSize = 26
TitleMain.ZIndex = 10
TitleMain.Parent = MainFrame

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, 0, 0, 30)
SubTitle.Position = UDim2.new(0, 0, 0, 50)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "by glock19x"
SubTitle.TextColor3 = Color3.fromRGB(150, 180, 210)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 14
SubTitle.ZIndex = 10
SubTitle.Parent = MainFrame

-- ✨ PARTÍCULAS DE FONDO
local ParticleContainer = Instance.new("Folder")
ParticleContainer.Name = "Particles"
ParticleContainer.Parent = MainFrame

local function crearParticula()
    local p = Instance.new("Frame")
    local size = math.random(4, 12)
    p.Size = UDim2.new(0, size, 0, size)
    p.Position = UDim2.new(math.random(0, 100)/100, 0, math.random(0, 100)/100, 0)
    p.BackgroundColor3 = Color3.fromRGB(120, 160, 200)
    p.BackgroundTransparency = math.random(6, 9) / 10
    p.BorderSizePixel = 0
    p.Active = false
    p.ZIndex = 1
    Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
    p.Parent = ParticleContainer
    
    local tweenInfo = TweenInfo.new(math.random(8, 20), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
    local goal = {
        Position = UDim2.new(math.random(0, 100)/100, 0, math.random(0, 100)/100, 0),
        BackgroundTransparency = math.random(4, 8) / 10
    }
    local tween = TweenService:Create(p, tweenInfo, goal)
    tween:Play()
end

for i = 1, 40 do task.spawn(crearParticula) end

-- 📜 SCROLLING FRAME PARA LAS OPCIONES
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -95)
ScrollFrame.Position = UDim2.new(0, 5, 0, 90)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 130, 160)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 750) -- Alto total del contenido
ScrollFrame.ZIndex = 5
ScrollFrame.Parent = MainFrame

local TitleESP = Instance.new("TextLabel")
TitleESP.Size = UDim2.new(0, 240, 0, 30)
TitleESP.Position = UDim2.new(0, 10, 0, 0)
TitleESP.BackgroundTransparency = 1
TitleESP.Text = "VISUAL / ESP CONFIG"
TitleESP.TextColor3 = Color3.fromRGB(100, 255, 180)
TitleESP.Font = Enum.Font.GothamBold
TitleESP.TextSize = 14
TitleESP.ZIndex = 10
TitleESP.Parent = ScrollFrame

local TitleAim = Instance.new("TextLabel")
TitleAim.Size = UDim2.new(0, 240, 0, 30)
TitleAim.Position = UDim2.new(0, 265, 0, 0)
TitleAim.BackgroundTransparency = 1
TitleAim.Text = "COMBAT / AIMBOT"
TitleAim.TextColor3 = Color3.fromRGB(180, 100, 255)
TitleAim.Font = Enum.Font.GothamBold
TitleAim.TextSize = 14
TitleAim.ZIndex = 10
TitleAim.Parent = ScrollFrame

local function crearBotonConfig(nombre, configKey, xPos, yPos, colorOn)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 235, 0, 35)
    btn.Position = UDim2.new(0, xPos, 0, yPos)
    btn.BackgroundColor3 = CONFIG[configKey] and colorOn or Color3.fromRGB(150, 40, 40)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = nombre .. ": " .. (CONFIG[configKey] and "ON" or "OFF")
    btn.ZIndex = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.Parent = ScrollFrame

    btn.MouseButton1Click:Connect(function()
        CONFIG[configKey] = not CONFIG[configKey]
        btn.BackgroundColor3 = CONFIG[configKey] and colorOn or Color3.fromRGB(150, 40, 40)
        btn.Text = nombre .. ": " .. (CONFIG[configKey] and "ON" or "OFF")
    end)
    return btn
end

-- Botones ESP (con más espacio)
crearBotonConfig("ESP Maestro", "EspGlobal", 15, 40, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Mostrar Cajas", "MostrarCajas", 15, 90, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Mostrar Nombres", "MostrarNombres", 15, 140, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Mostrar Armas", "MostrarArmas", 15, 190, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Mostrar Líneas", "MostrarLineas", 15, 240, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Ocultar Team", "OcultarTeam", 15, 290, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Mostrar Distancia", "MostrarDistancia", 15, 340, Color3.fromRGB(40, 150, 90))

-- Botones Aimbot (con más espacio)
crearBotonConfig("Aimbot Maestro", "AimbotGlobal", 265, 40, Color3.fromRGB(100, 30, 180))

local KeybindBtn = Instance.new("TextButton")
KeybindBtn.Size = UDim2.new(0, 235, 0, 35)
KeybindBtn.Position = UDim2.new(0, 265, 0, 90)
KeybindBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
KeybindBtn.Font = Enum.Font.GothamSemibold
KeybindBtn.TextSize = 12
KeybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KeybindBtn.Text = "Tecla Aimbot: " .. CONFIG.TeclaAimbot.Name
KeybindBtn.ZIndex = 10
Instance.new("UICorner", KeybindBtn).CornerRadius = UDim.new(0, 5)
KeybindBtn.Parent = ScrollFrame

KeybindBtn.MouseButton1Click:Connect(function()
    cambiandoKeybind = true
    KeybindBtn.Text = "Presiona una tecla..."
end)

local ModoTeclaBtn = Instance.new("TextButton")
ModoTeclaBtn.Size = UDim2.new(0, 235, 0, 35)
ModoTeclaBtn.Position = UDim2.new(0, 265, 0, 140)
ModoTeclaBtn.BackgroundColor3 = Color3.fromRGB(100, 30, 180)
ModoTeclaBtn.Font = Enum.Font.GothamSemibold
ModoTeclaBtn.TextSize = 12
ModoTeclaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ModoTeclaBtn.Text = "Activación: " .. CONFIG.ModoTeclaAimbot
ModoTeclaBtn.ZIndex = 10
Instance.new("UICorner", ModoTeclaBtn).CornerRadius = UDim.new(0, 5)
ModoTeclaBtn.Parent = ScrollFrame

local function actualizarBotonModoTecla()
    ModoTeclaBtn.Text = "Activación: " .. CONFIG.ModoTeclaAimbot
end

ModoTeclaBtn.MouseButton1Click:Connect(function()
    for i, modo in ipairs(MODOS_TECLA) do
        if modo == CONFIG.ModoTeclaAimbot then
            CONFIG.ModoTeclaAimbot = MODOS_TECLA[(i % #MODOS_TECLA) + 1]
            break
        end
    end
    actualizarBotonModoTecla()
    aimbotActivo = false
    objetivoActual = nil
    if UIStroke then UIStroke.Color = Color3.fromRGB(255, 0, 0) end
end)

local ModoBtn = Instance.new("TextButton")
ModoBtn.Size = UDim2.new(0, 235, 0, 35)
ModoBtn.Position = UDim2.new(0, 265, 0, 190)
ModoBtn.BackgroundColor3 = Color3.fromRGB(100, 30, 180)
ModoBtn.Font = Enum.Font.GothamSemibold
ModoBtn.TextSize = 12
ModoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ModoBtn.Text = "Preferencia: " .. CONFIG.ModoApuntado
ModoBtn.ZIndex = 10
Instance.new("UICorner", ModoBtn).CornerRadius = UDim.new(0, 5)
ModoBtn.Parent = ScrollFrame

local function actualizarBotonModo()
    ModoBtn.Text = "Preferencia: " .. CONFIG.ModoApuntado
end

ModoBtn.MouseButton1Click:Connect(function()
    for i, modo in ipairs(MODOS_APUNTADO) do
        if modo == CONFIG.ModoApuntado then
            CONFIG.ModoApuntado = MODOS_APUNTADO[(i % #MODOS_APUNTADO) + 1]
            break
        end
    end
    actualizarBotonModo()
    if aimbotActivo then objetivoActual = nil end
end)

crearBotonConfig("Mostrar FOV", "MostrarFov", 265, 240, Color3.fromRGB(100, 30, 180))

local function crearInputNumerico(labelTxt, configKey, xPos, yPos, AlTerminar)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 140, 0, 30)
    lbl.Position = UDim2.new(0, xPos, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelTxt
    lbl.TextColor3 = Color3.fromRGB(200, 220, 240)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 10
    lbl.Parent = ScrollFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 85, 0, 28)
    box.Position = UDim2.new(0, xPos + 150, 0, yPos + 1)
    box.BackgroundColor3 = Color3.fromRGB(30, 45, 60)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.Text = tostring(CONFIG[configKey])
    box.ZIndex = 10
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    box.Parent = ScrollFrame

    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num and num >= 0 then 
            if configKey == "Smoothness" then
                num = math.clamp(num, 0, 0.99)
            elseif configKey == "Prediccion" then
                num = math.clamp(num, 0, 2.0)
            end
            CONFIG[configKey] = num
            box.Text = tostring(num)
            if AlTerminar then AlTerminar(num) end
        else
            box.Text = tostring(CONFIG[configKey])
        end
    end)
end

crearInputNumerico("Distancia Max ESP:", "DistanciaMaxESP", 15, 390)
crearInputNumerico("Distancia Max Aim:", "DistanciaMaxAim", 265, 290)
crearInputNumerico("Radio de FOV:", "MaxFovRadio", 265, 340, function(nuevoRadio)
    local circ = ScreenGuiMaster:FindFirstChild("FOVCircle")
    if circ then circ.Size = UDim2.new(0, nuevoRadio * 2, 0, nuevoRadio * 2) end
end)
crearInputNumerico("Suavidad (0-0.9):", "Smoothness", 265, 390)
crearInputNumerico("Predicción (0-2):", "Prediccion", 265, 440)
crearInputNumerico("Dist. Cambio Cabeza:", "DistanciaCambioCabeza", 265, 490)

FrameCirculo = Instance.new("Frame")
FrameCirculo.Name = "FOVCircle"
FrameCirculo.AnchorPoint = Vector2.new(0.5, 0.5)
FrameCirculo.Size = UDim2.new(0, CONFIG.MaxFovRadio * 2, 0, CONFIG.MaxFovRadio * 2) 
FrameCirculo.Position = UDim2.new(0.5, 0, 0.5, 0)
FrameCirculo.BackgroundTransparency = 1
FrameCirculo.Visible = CONFIG.MostrarFov
FrameCirculo.Parent = ScreenGuiMaster

Instance.new("UICorner", FrameCirculo).CornerRadius = UDim.new(1, 0)
UIStroke = Instance.new("UIStroke", FrameCirculo)
UIStroke.Color = Color3.fromRGB(255, 0, 0) 
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0.5

-- =========================================================
-- 🔫 DETECTOR DE ARMAS PERSONALIZADO
-- =========================================================
local function obtenerArmaEnMano(character)
    local herramienta = character:FindFirstChildOfClass("Tool")
    if herramienta then return herramienta.Name end
    
    for _, objeto in ipairs(character:GetChildren()) do
        if objeto:IsA("Model") then
            local objName = objeto.Name:lower()
            if not objName:match("torso") and not objName:match("arm") and not objName:match("leg") 
               and not objName:match("head") and not objName:match("package") and objeto.Name ~= "Body Colors" then
                if objeto:FindFirstChild("Handle") or objeto:FindFirstChild("Muzzle") or objeto:FindFirstChild("Grip") 
                   or objName:match("glock") or objName:match("m4") or objName:match("ak") or objName:match("remington") 
                   or objName:match("pistol") or objName:match("gun") or objName:match("rifle") or objName:match("knife") or objName:match("bat") then
                    return objeto.Name
                end
            end
        end
    end
    return "Ninguna"
end

-- =========================================================
-- 🛡️ FUNCIONES DE FILTRADO
-- =========================================================
local function esCompaneroDeTeam(jugador)
    if not CONFIG.OcultarTeam then return false end
    local miTeam = LocalPlayer.Team
    if not miTeam then return false end
    return jugador.Team == miTeam
end

local function esEnemigo(jugador)
    local miTeam = LocalPlayer.Team
    if not miTeam then return true end
    return jugador.Team ~= miTeam
end

-- =========================================================
-- 👁️ VERIFICAR VISIBILIDAD
-- =========================================================
local function objetivoEsVisible(targetPart, targetChar, localCharacter)
    Camera = workspace.CurrentCamera or Camera
    if not Camera or not targetPart or not targetChar then return false end

    local cameraPos = Camera.CFrame.Position
    local direction = targetPart.Position - cameraPos
    local distance = direction.Magnitude
    if distance <= 0 then return true end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local filtros = {targetChar}
    if localCharacter then table.insert(filtros, localCharacter) end
    rayParams.FilterDescendantsInstances = filtros

    local result = workspace:Raycast(cameraPos, direction.Unit * distance, rayParams)
    if not result then return true end
    return result.Instance:IsDescendantOf(targetChar)
end

-- =========================================================
-- 🧠 SELECCIÓN DE OBJETIVOS
-- =========================================================
local function obtenerObjetivoValido()
    if not CONFIG.AimbotGlobal then return nil end
    Camera = workspace.CurrentCamera or Camera
    if not Camera then return nil end

    local character = LocalPlayer.Character
    if not character then return nil end
    local rootLocal = character:FindFirstChild("HumanoidRootPart")
    if not rootLocal then return nil end
    
    local posicionLocal = rootLocal.Position
    local mejorObjetivo, mejorPrimario, mejorSecundario = nil, nil, nil

    for _, jugador in ipairs(Players:GetPlayers()) do
        if jugador ~= LocalPlayer and not amigosCache[jugador.UserId] and esEnemigo(jugador) then
            local char = jugador.Character
            if not char then continue end
            
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            
            if humanoid and humanoid.Health > 0 and root then
                local distanciaMundo = (posicionLocal - root.Position).Magnitude
                
                if distanciaMundo <= CONFIG.DistanciaMaxAim then
                    local targetPartName = distanciaMundo <= CONFIG.DistanciaCambioCabeza and "Head" or "HumanoidRootPart"
                    local targetPart = char:FindFirstChild(targetPartName) or root
                    local posicionPantalla, enPantalla = Camera:WorldToViewportPoint(targetPart.Position)
                    
                    if enPantalla then
                        local centroPantalla = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local dist2D = (centroPantalla - Vector2.new(posicionPantalla.X, posicionPantalla.Y)).Magnitude
                        
                        if dist2D <= CONFIG.MaxFovRadio and objetivoEsVisible(targetPart, char, character) then
                            local seleccionar = false

                            if CONFIG.ModoApuntado == "MAS CERCANO" then
                                if mejorPrimario == nil or distanciaMundo < mejorPrimario or (distanciaMundo == mejorPrimario and dist2D < mejorSecundario) then
                                    seleccionar = true
                                end
                            elseif CONFIG.ModoApuntado == "MAS LEJANO" then
                                if mejorPrimario == nil or distanciaMundo > mejorPrimario or (distanciaMundo == mejorPrimario and dist2D < mejorSecundario) then
                                    seleccionar = true
                                end
                            else
                                if mejorPrimario == nil or dist2D < mejorPrimario or (dist2D == mejorPrimario and distanciaMundo < mejorSecundario) then
                                    seleccionar = true
                                end
                            end

                            if seleccionar then
                                if CONFIG.ModoApuntado == "MAS CERCANO" or CONFIG.ModoApuntado == "MAS LEJANO" then
                                    mejorPrimario, mejorSecundario = distanciaMundo, dist2D
                                else
                                    mejorPrimario, mejorSecundario = dist2D, distanciaMundo
                                end
                                mejorObjetivo = targetPart
                            end
                        end
                    end
                end
            end
        end
    end
    return mejorObjetivo
end

-- =========================================================
-- 🗑️ LIMPIADOR ESP
-- =========================================================
local function limpiarESPPlayer(pName)
    if ESP_Container[pName] then
        pcall(function() ESP_Container[pName].BoxGui:Destroy() end)
        pcall(function() ESP_Container[pName].NameGui:Destroy() end)
        pcall(function() ESP_Container[pName].Tracer:Destroy() end)
        pcall(function() ESP_Container[pName].EnemyAtt:Destroy() end)
        ESP_Container[pName] = nil
    end
end

-- =========================================================
-- 👁️ MOTOR DE RENDERIZADO (ESP)
-- =========================================================
local function gestionarESP()
    if not CONFIG.EspGlobal then
        for pName, _ in pairs(ESP_Container) do limpiarESPPlayer(pName) end
        return
    end

    local charLocal = LocalPlayer.Character
    local rootLocal = charLocal and charLocal:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local pName = player.Name
            
            if esCompaneroDeTeam(player) then
                limpiarESPPlayer(pName)
            else
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local head = char and char:FindFirstChild("Head")
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if char and root and head and hum and hum.Health > 0 and rootLocal then
                    local distancia = (rootLocal.Position - root.Position).Magnitude

                    if distancia <= CONFIG.DistanciaMaxESP then
                        if not ESP_Container[pName] then
                            local colorEfecto = amigosCache[player.UserId] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(140, 100, 255)
                            
                            local bGui = Instance.new("BillboardGui")
                            bGui.Name = "Box_" .. pName
                            bGui.Size = UDim2.new(4.5, 0, 6, 0)
                            bGui.AlwaysOnTop = true
                            bGui.Parent = ScreenGuiESP

                            local bFrame = Instance.new("Frame")
                            bFrame.Size = UDim2.new(1, 0, 1, 0)
                            bFrame.BackgroundTransparency = 1
                            bFrame.Parent = bGui

                            local stroke = Instance.new("UIStroke")
                            stroke.Color = colorEfecto
                            stroke.Thickness = 2
                            stroke.Parent = bFrame
                            
                            local nGui = Instance.new("BillboardGui")
                            nGui.Name = "Name_" .. pName
                            nGui.Size = UDim2.new(0, 200, 0, 80)
                            nGui.StudsOffset = Vector3.new(0, 3.5, 0)
                            nGui.AlwaysOnTop = true
                            nGui.Parent = ScreenGuiESP

                            local lbl = Instance.new("TextLabel")
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.TextColor3 = colorEfecto
                            lbl.TextStrokeTransparency = 0
                            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextSize = 13
                            lbl.TextWrapped = true
                            lbl.Parent = nGui
                            
                            local beam = Instance.new("Beam")
                            beam.Color = ColorSequence.new(colorEfecto)
                            beam.Width0 = 0.04
                            beam.Width1 = 0.04
                            beam.FaceCamera = true
                            
                            local attEnemy = Instance.new("Attachment", root)
                            attEnemy.Name = "ESP_AttEnemy"

                            ESP_Container[pName] = {
                                BoxGui = bGui, NameGui = nGui, TextLabel = lbl,
                                Tracer = beam, EnemyAtt = attEnemy, Stroke = stroke
                            }
                        end

                        local data = ESP_Container[pName]
                        if not data.EnemyAtt or not data.EnemyAtt.Parent then
                            if data.EnemyAtt then pcall(function() data.EnemyAtt:Destroy() end) end
                            data.EnemyAtt = Instance.new("Attachment", root)
                            data.EnemyAtt.Name = "ESP_AttEnemy"
                        end
                        
                        local colorEfecto = amigosCache[player.UserId] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(140, 100, 255)
                        data.Stroke.Color = colorEfecto
                        data.TextLabel.TextColor3 = colorEfecto
                        data.Tracer.Color = ColorSequence.new(colorEfecto)

                        data.BoxGui.Adornee = root
                        data.NameGui.Adornee = head
                        data.BoxGui.Enabled = CONFIG.MostrarCajas
                        
                        local mostrarAlgo = CONFIG.MostrarNombres or CONFIG.MostrarArmas or CONFIG.MostrarDistancia
                        data.NameGui.Enabled = mostrarAlgo
                        
                        if mostrarAlgo then
                            local armaName = CONFIG.MostrarArmas and obtenerArmaEnMano(char) or nil
                            local distText = CONFIG.MostrarDistancia and ("\n[" .. math.floor(distancia) .. "m]") or ""
                            local armaText = armaName and ("\n[" .. armaName .. "]") or ""
                            local textoFinal = CONFIG.MostrarNombres and player.Name or ""
                            data.TextLabel.Text = textoFinal .. armaText .. distText
                        end

                        local myAtt = rootLocal:FindFirstChild("ESP_AttLocal")
                        if not myAtt then
                            myAtt = Instance.new("Attachment", rootLocal)
                            myAtt.Name = "ESP_AttLocal"
                        end

                        if CONFIG.MostrarLineas and myAtt and data.EnemyAtt then
                            data.Tracer.Attachment0 = myAtt
                            data.Tracer.Attachment1 = data.EnemyAtt
                            data.Tracer.Parent = rootLocal
                            data.Tracer.Enabled = true
                        else
                            data.Tracer.Enabled = false
                        end
                    else
                        limpiarESPPlayer(pName)
                    end
                else
                    limpiarESPPlayer(pName)
                end
            end
        end
    end

    for pName, _ in pairs(ESP_Container) do
        if not Players:FindFirstChild(pName) then limpiarESPPlayer(pName) end
    end
end

-- =========================================================
-- 🔄 EVENTOS DE ENTRADA (INPUTS)
-- =========================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not interfazCargada then return end
    
    Camera = workspace.CurrentCamera or Camera

    if cambiandoKeybind then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            CONFIG.TeclaAimbot = input.KeyCode
            CONFIG.TeclaMouse = nil
            KeybindBtn.Text = "Tecla Aimbot: " .. input.KeyCode.Name
        elseif input.UserInputType.Name:match("MouseButton") then
            CONFIG.TeclaAimbot = Enum.KeyCode.Unknown
            CONFIG.TeclaMouse = input.UserInputType
            local nombresMouse = {
                [Enum.UserInputType.MouseButton1] = "Clic Izq",
                [Enum.UserInputType.MouseButton2] = "Clic Der",
                [Enum.UserInputType.MouseButton3] = "Clic Medio",
                [Enum.UserInputType.MouseButton4] = "Mouse Lat 1",
                [Enum.UserInputType.MouseButton5] = "Mouse Lat 2"
            }
            KeybindBtn.Text = "Tecla Aimbot: " .. (nombresMouse[input.UserInputType] or input.UserInputType.Name)
        end
        cambiandoKeybind = false
        return
    end

    if gameProcessed and UserInputService:GetFocusedTextBox() then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end

    local esTeclaAimbot = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.TeclaAimbot)
    local esMouseAimbot = (CONFIG.TeclaMouse and input.UserInputType == CONFIG.TeclaMouse)

    if CONFIG.AimbotGlobal and (esTeclaAimbot or esMouseAimbot) then
        if CONFIG.ModoTeclaAimbot == "MANTENER" then
            if not aimbotActivo then
                aimbotActivo = true
                objetivoActual = obtenerObjetivoValido()
                if UIStroke then UIStroke.Color = objetivoActual and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 150, 0) end
                pcall(function() StarterGui:SetCore("SendNotification", {Title = "Sistema", Text = "Aimbot MANTENER activo", Duration = 1}) end)
            end
        else
            aimbotActivo = not aimbotActivo
            if aimbotActivo then
                objetivoActual = obtenerObjetivoValido()
                if UIStroke then UIStroke.Color = objetivoActual and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 150, 0) end
                pcall(function() StarterGui:SetCore("SendNotification", {Title = "Sistema", Text = "Aimbot ON: buscando enemigos", Duration = 1}) end)
            else
                objetivoActual = nil
                if UIStroke then UIStroke.Color = Color3.fromRGB(255, 0, 0) end
                pcall(function() StarterGui:SetCore("SendNotification", {Title = "Sistema", Text = "Aimbot OFF", Duration = 1}) end)
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not interfazCargada or cambiandoKeybind or not CONFIG.AimbotGlobal or CONFIG.ModoTeclaAimbot ~= "MANTENER" then return end

    local esTeclaAimbot = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.TeclaAimbot)
    local esMouseAimbot = (CONFIG.TeclaMouse and input.UserInputType == CONFIG.TeclaMouse)

    if esTeclaAimbot or esMouseAimbot then
        aimbotActivo = false
        objetivoActual = nil
        if UIStroke then UIStroke.Color = Color3.fromRGB(255, 0, 0) end
        pcall(function() StarterGui:SetCore("SendNotification", {Title = "Sistema", Text = "Aimbot MANTENER apagado", Duration = 1}) end)
    end
end)

-- =========================================================
-- 🚀 BUCLE SÍNCRONO (RENDERSTEPPED)
-- =========================================================
RunService.RenderStepped:Connect(function()
    if not interfazCargada then return end
    
    Camera = workspace.CurrentCamera or Camera

    if FrameCirculo then
        FrameCirculo.Position = UDim2.new(0.5, 0, 0.5, 0)
        FrameCirculo.Visible = CONFIG.MostrarFov
    end
    
    gestionarESP()

    if not CONFIG.AimbotGlobal or not aimbotActivo then
        if UIStroke then UIStroke.Color = Color3.fromRGB(255, 0, 0) end
        return
    end

    if not objetivoActual or not objetivoActual.Parent then
        objetivoActual = obtenerObjetivoValido()
    end

    if not objetivoActual or not objetivoActual.Parent then
        if UIStroke then UIStroke.Color = Color3.fromRGB(255, 150, 0) end
        return
    end

    local targetPlayer = Players:GetPlayerFromCharacter(objetivoActual.Parent)
    if targetPlayer and (amigosCache[targetPlayer.UserId] or not esEnemigo(targetPlayer)) then
        objetivoActual = nil
        if UIStroke then UIStroke.Color = Color3.fromRGB(255, 150, 0) end
        return
    end

    local targetChar = objetivoActual.Parent
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        objetivoActual = nil
        if UIStroke then UIStroke.Color = Color3.fromRGB(255, 150, 0) end
        return
    end

    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    local localCharacter = LocalPlayer.Character
    local rootLocal = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

    if not targetRoot or not rootLocal then
        objetivoActual = nil
        if UIStroke then UIStroke.Color = Color3.fromRGB(255, 150, 0) end
        return
    end
    
    local distanciaMundo = (rootLocal.Position - targetRoot.Position).Magnitude
    local targetPartName = distanciaMundo <= CONFIG.DistanciaCambioCabeza and "Head" or "HumanoidRootPart"
    local targetPart = targetChar:FindFirstChild(targetPartName) or targetRoot
    objetivoActual = targetPart 
    
    local targetPos = targetPart.Position

    if CONFIG.Prediccion > 0 then
        local velocity = targetRoot.AssemblyLinearVelocity
        local dist3D = (rootLocal.Position - targetPos).Magnitude
        local timeToTarget = dist3D / CONFIG.VelocidadBalaEstimada
        targetPos = targetPos + (velocity * timeToTarget * CONFIG.Prediccion)
    end

    local posicionPantalla, enPantalla = Camera:WorldToViewportPoint(targetPos)
    local centroPantalla = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local dist2D = enPantalla and (centroPantalla - Vector2.new(posicionPantalla.X, posicionPantalla.Y)).Magnitude or math.huge

    local visible = enPantalla and objetivoEsVisible(targetPart, targetChar, localCharacter)

    if visible and dist2D <= CONFIG.MaxFovRadio and distanciaMundo <= CONFIG.DistanciaMaxAim then
        local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        local lerpAlpha = 1 - CONFIG.Smoothness 
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, lerpAlpha)
        if UIStroke then UIStroke.Color = Color3.fromRGB(0, 255, 0) end
    else
        objetivoActual = nil
        if UIStroke then UIStroke.Color = Color3.fromRGB(255, 150, 0) end
    end
end)
