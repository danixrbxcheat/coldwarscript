local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- === VARIABLES GLOBALES DE CONFIGURACIÓN ===
local CONFIG = {
    EspGlobal = true,
    MostrarCajas = true,
    MostrarNombres = true,
    MostrarArmas = true,
    MostrarLineas = true,
    MostrarDistancia = true, 
    OcultarTeam = false, 
    DistanciaMaxESP = 500,
    
    AimbotGlobal = false,
    MostrarFov = true,
    TeclaAimbot = Enum.KeyCode.T,
    TeclaMouse = nil, 
    DistanciaMaxAim = 300,
    MaxFovRadio = 150,
    Smoothness = 0.4, 
    
    -- === CONFIGURACIÓN ESPECÍFICA PARA COLD WAR ===
    Prediccion = 0.8, 
    VelocidadBalaEstimada = 800, 
    DistanciaCambioCabeza = 60,

    -- PREFERENCIA DEL AIMBOT
    -- "EN MIRA" = el que esté más cerca del centro de la pantalla
    -- "MAS CERCANO" = el enemigo más cercano a tu personaje
    -- "MAS LEJANO" = el enemigo más lejano dentro del FOV
    ModoApuntado = "EN MIRA",

    -- NUEVO: MODO DE ACTIVACIÓN DEL AIMBOT
    -- "TOGGLE" = presionas la tecla una vez y queda buscando
    -- "MANTENER" = funciona mientras mantienes la tecla presionada
    ModoTeclaAimbot = "TOGGLE"
}

local aimbotActivo = false
local objetivoActual = nil
local amigosCache = {}
local cambiandoKeybind = false
local ESP_Container = {}

-- ESTADO DE CARGA
local cargando = true
local MODOS_APUNTADO = {"EN MIRA", "MAS CERCANO", "MAS LEJANO"}
local MODOS_TECLA = {"TOGGLE", "MANTENER"}

-- Referencias que se crean más abajo
local UIStroke = nil
local FrameCirculo = nil

-- SISTEMA DE CACHÉ DE AMIGOS
local function registrarAmistad(jugador)
    if jugador == LocalPlayer then return end
    pcall(function()
        amigosCache[jugador.UserId] = LocalPlayer:IsFriendsWith(jugador.UserId)
    end)
end

for _, jugador in ipairs(Players:GetPlayers()) do
    registrarAmistad(jugador)
end

Players.PlayerAdded:Connect(registrarAmistad)
Players.PlayerRemoving:Connect(function(jugador)
    amigosCache[jugador.UserId] = nil
end)

-- Contenedores Seguros de UI
local ScreenGuiMaster = Instance.new("ScreenGui")
ScreenGuiMaster.Name = "MasterEngineUI"
ScreenGuiMaster.ResetOnSpawn = false
ScreenGuiMaster.DisplayOrder = 1000

local ScreenGuiESP = Instance.new("ScreenGui")
ScreenGuiESP.Name = "ESPRenderEngine"
ScreenGuiESP.ResetOnSpawn = false
ScreenGuiESP.DisplayOrder = 999

local exito, _ = pcall(function() 
    ScreenGuiMaster.Parent = CoreGui 
    ScreenGuiESP.Parent = CoreGui
end)

if not exito then 
    ScreenGuiMaster.Parent = LocalPlayer:WaitForChild("PlayerGui") 
    ScreenGuiESP.Parent = LocalPlayer:WaitForChild("PlayerGui") 
end

-- =========================================================
-- 🛠️ INTERFAZ GRÁFICA (MENÚ CONEXIÓN DIRECTA)
-- =========================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 460) 
MainFrame.Position = UDim2.new(0.5, -260, 0.4, -230)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGuiMaster

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TitleESP = Instance.new("TextLabel", MainFrame)
TitleESP.Size = UDim2.new(0, 240, 0, 40)
TitleESP.Position = UDim2.new(0, 15, 0, 5)
TitleESP.BackgroundTransparency = 1
TitleESP.Text = "VISUAL / ESP CONFIG"
TitleESP.TextColor3 = Color3.fromRGB(0, 255, 150)
TitleESP.Font = Enum.Font.GothamBold
TitleESP.TextSize = 14

local TitleAim = Instance.new("TextLabel", MainFrame)
TitleAim.Size = UDim2.new(0, 240, 0, 40)
TitleAim.Position = UDim2.new(0, 265, 0, 5)
TitleAim.BackgroundTransparency = 1
TitleAim.Text = "COMBAT / AIMBOT (COLD WAR)"
TitleAim.TextColor3 = Color3.fromRGB(140, 0, 255)
TitleAim.Font = Enum.Font.GothamBold
TitleAim.TextSize = 14

local function crearBotonConfig(nombre, configKey, xPos, yPos, colorOn)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0, 235, 0, 32)
    btn.Position = UDim2.new(0, xPos, 0, yPos)
    btn.BackgroundColor3 = CONFIG[configKey] and colorOn or Color3.fromRGB(150, 40, 40)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = nombre .. ": " .. (CONFIG[configKey] and "ON" or "OFF")
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    btn.MouseButton1Click:Connect(function()
        CONFIG[configKey] = not CONFIG[configKey]
        btn.BackgroundColor3 = CONFIG[configKey] and colorOn or Color3.fromRGB(150, 40, 40)
        btn.Text = nombre .. ": " .. (CONFIG[configKey] and "ON" or "OFF")
    end)

    return btn
end

-- Botones ESP
crearBotonConfig("ESP Maestro", "EspGlobal", 15, 45, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Mostrar Cajas", "MostrarCajas", 15, 82, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Mostrar Nombres", "MostrarNombres", 15, 119, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Mostrar Armas", "MostrarArmas", 15, 156, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Mostrar Líneas", "MostrarLineas", 15, 193, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Ocultar Team (Solo ESP)", "OcultarTeam", 15, 230, Color3.fromRGB(40, 150, 90))
crearBotonConfig("Mostrar Distancia", "MostrarDistancia", 15, 267, Color3.fromRGB(40, 150, 90))

-- Botones Aimbot
crearBotonConfig("Aimbot Maestro", "AimbotGlobal", 265, 45, Color3.fromRGB(100, 30, 180))

local KeybindBtn = Instance.new("TextButton", MainFrame)
KeybindBtn.Size = UDim2.new(0, 235, 0, 32)
KeybindBtn.Position = UDim2.new(0, 265, 0, 82)
KeybindBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
KeybindBtn.Font = Enum.Font.GothamSemibold
KeybindBtn.TextSize = 12
KeybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KeybindBtn.Text = "Tecla Aimbot: " .. CONFIG.TeclaAimbot.Name
Instance.new("UICorner", KeybindBtn).CornerRadius = UDim.new(0, 5)

KeybindBtn.MouseButton1Click:Connect(function()
    cambiandoKeybind = true
    KeybindBtn.Text = "Presiona una tecla o botón del mouse..."
end)

-- NUEVO: BOTÓN MODO DE ACTIVACIÓN DEL AIMBOT
local ModoTeclaBtn = Instance.new("TextButton", MainFrame)
ModoTeclaBtn.Size = UDim2.new(0, 235, 0, 32)
ModoTeclaBtn.Position = UDim2.new(0, 265, 0, 119)
ModoTeclaBtn.BackgroundColor3 = Color3.fromRGB(100, 30, 180)
ModoTeclaBtn.Font = Enum.Font.GothamSemibold
ModoTeclaBtn.TextSize = 12
ModoTeclaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ModoTeclaBtn.Text = "Activación: " .. CONFIG.ModoTeclaAimbot
Instance.new("UICorner", ModoTeclaBtn).CornerRadius = UDim.new(0, 5)

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

    -- Reiniciamos estado del aimbot al cambiar el modo
    aimbotActivo = false
    objetivoActual = nil

    if UIStroke then
        UIStroke.Color = Color3.fromRGB(255, 0, 0)
    end
end)

-- BOTÓN DE PREFERENCIA DEL AIMBOT
local ModoBtn = Instance.new("TextButton", MainFrame)
ModoBtn.Size = UDim2.new(0, 235, 0, 32)
ModoBtn.Position = UDim2.new(0, 265, 0, 156)
ModoBtn.BackgroundColor3 = Color3.fromRGB(100, 30, 180)
ModoBtn.Font = Enum.Font.GothamSemibold
ModoBtn.TextSize = 12
ModoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ModoBtn.Text = "Preferencia: " .. CONFIG.ModoApuntado
Instance.new("UICorner", ModoBtn).CornerRadius = UDim.new(0, 5)

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

    -- Si el aimbot está activo, forzamos re-selección de objetivo
    if aimbotActivo then
        objetivoActual = nil
    end
end)

crearBotonConfig("Mostrar FOV", "MostrarFov", 265, 193, Color3.fromRGB(100, 30, 180))

local function crearInputNumerico(labelTxt, configKey, xPos, yPos, AlTerminar)
    local lbl = Instance.new("TextLabel", MainFrame)
    lbl.Size = UDim2.new(0, 140, 0, 30)
    lbl.Position = UDim2.new(0, xPos, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelTxt
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", MainFrame)
    box.Size = UDim2.new(0, 85, 0, 28)
    box.Position = UDim2.new(0, xPos + 150, 0, yPos + 1)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.Text = tostring(CONFIG[configKey])
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

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

            if AlTerminar then
                AlTerminar(num)
            end
        else
            box.Text = tostring(CONFIG[configKey])
        end
    end)
end

crearInputNumerico("Distancia Max ESP:", "DistanciaMaxESP", 15, 305)

crearInputNumerico("Distancia Max Aim:", "DistanciaMaxAim", 265, 230)
crearInputNumerico("Radio de FOV:", "MaxFovRadio", 265, 267, function(nuevoRadio)
    local circ = ScreenGuiMaster:FindFirstChild("FOVCircle")
    if circ then
        circ.Size = UDim2.new(0, nuevoRadio * 2, 0, nuevoRadio * 2)
    end
end)
crearInputNumerico("Suavidad (0-0.9):", "Smoothness", 265, 304)
crearInputNumerico("Predicción (0-2):", "Prediccion", 265, 341)
crearInputNumerico("Dist. Cambio Cabeza:", "DistanciaCambioCabeza", 265, 378)

-- ⭕ CÍRCULO FOV
FrameCirculo = Instance.new("Frame", ScreenGuiMaster)
FrameCirculo.Name = "FOVCircle"
FrameCirculo.AnchorPoint = Vector2.new(0.5, 0.5)
FrameCirculo.Size = UDim2.new(0, CONFIG.MaxFovRadio * 2, 0, CONFIG.MaxFovRadio * 2) 
FrameCirculo.Position = UDim2.new(0.5, 0, 0.5, 0)
FrameCirculo.BackgroundTransparency = 1
FrameCirculo.Visible = CONFIG.MostrarFov

Instance.new("UICorner", FrameCirculo).CornerRadius = UDim.new(1, 0)

UIStroke = Instance.new("UIStroke", FrameCirculo)
UIStroke.Color = Color3.fromRGB(255, 0, 0) 
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0.5

-- =========================================================
-- ⏳ PANTALLA DE CARGA PEQUEÑA (TAMAÑO DEL MENÚ)
-- =========================================================
local LoadingFrame = Instance.new("Frame", ScreenGuiMaster)
LoadingFrame.Name = "ColdWarLoading"
LoadingFrame.Size = UDim2.new(0, 520, 0, 460)
LoadingFrame.Position = UDim2.new(0.5, -260, 0.5, -230)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
LoadingFrame.BackgroundTransparency = 0
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Visible = true
LoadingFrame.Active = true
LoadingFrame.ZIndex = 1000

Instance.new("UICorner", LoadingFrame).CornerRadius = UDim.new(0, 8)

local LoadingStroke = Instance.new("UIStroke", LoadingFrame)
LoadingStroke.Color = Color3.fromRGB(140, 0, 255)
LoadingStroke.Thickness = 1.5
LoadingStroke.Transparency = 0.2

local LoadingTitle = Instance.new("TextLabel", LoadingFrame)
LoadingTitle.Size = UDim2.new(0, 460, 0, 80)
LoadingTitle.Position = UDim2.new(0.5, -230, 0.26, -40)
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Text = "MENU COLDWAR BY GLOCK19X"
LoadingTitle.TextColor3 = Color3.fromRGB(140, 0, 255)
LoadingTitle.Font = Enum.Font.GothamBlack
LoadingTitle.TextScaled = true
LoadingTitle.TextWrapped = true
LoadingTitle.ZIndex = 1001

local LoadingSub = Instance.new("TextLabel", LoadingFrame)
LoadingSub.Size = UDim2.new(0, 360, 0, 32)
LoadingSub.Position = UDim2.new(0.5, -180, 0.54, -16)
LoadingSub.BackgroundTransparency = 1
LoadingSub.Text = "Cargando... 0%"
LoadingSub.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingSub.Font = Enum.Font.Gotham
LoadingSub.TextScaled = true
LoadingSub.ZIndex = 1001

local LoadingBarBg = Instance.new("Frame", LoadingFrame)
LoadingBarBg.Size = UDim2.new(0, 380, 0, 8)
LoadingBarBg.Position = UDim2.new(0.5, -190, 0.66, 0)
LoadingBarBg.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
LoadingBarBg.BorderSizePixel = 0
LoadingBarBg.ZIndex = 1001

Instance.new("UICorner", LoadingBarBg).CornerRadius = UDim.new(1, 0)

local LoadingBarFill = Instance.new("Frame", LoadingBarBg)
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill.BackgroundColor3 = Color3.fromRGB(140, 0, 255)
LoadingBarFill.BorderSizePixel = 0
LoadingBarFill.ZIndex = 1002

Instance.new("UICorner", LoadingBarFill).CornerRadius = UDim.new(1, 0)

local tiempoCarga = 6
local inicioCarga = tick()
local conexionCarga

conexionCarga = RunService.RenderStepped:Connect(function()
    if not cargando then
        if conexionCarga then
            conexionCarga:Disconnect()
        end
        return
    end

    local alpha = math.clamp((tick() - inicioCarga) / tiempoCarga, 0, 1)
    LoadingBarFill.Size = UDim2.new(alpha, 0, 1, 0)
    LoadingSub.Text = "Cargando... " .. tostring(math.floor(alpha * 100)) .. "%"

    if alpha >= 1 then
        cargando = false

        if conexionCarga then
            conexionCarga:Disconnect()
        end

        LoadingFrame.Visible = false
        LoadingFrame:Destroy()
    end
end)

-- =========================================================
-- 🔫 DETECTOR DE ARMAS PERSONALIZADO
-- =========================================================
local function obtenerArmaEnMano(character)
    local herramienta = character:FindFirstChildOfClass("Tool")
    if herramienta then
        return herramienta.Name
    end
    
    for _, objeto in ipairs(character:GetChildren()) do
        if objeto:IsA("Model") then
            local objName = objeto.Name:lower()

            if not objName:match("torso")
                and not objName:match("arm")
                and not objName:match("leg")
                and not objName:match("head")
                and not objName:match("package")
                and objeto.Name ~= "Body Colors" then

                if objeto:FindFirstChild("Handle")
                    or objeto:FindFirstChild("Muzzle")
                    or objeto:FindFirstChild("Grip")
                    or objName:match("glock")
                    or objName:match("m4")
                    or objName:match("ak")
                    or objName:match("remington")
                    or objName:match("pistol")
                    or objName:match("gun")
                    or objName:match("rifle")
                    or objName:match("knife")
                    or objName:match("bat") then

                    return objeto.Name
                end
            end
        end
    end

    return "Ninguna"
end

-- =========================================================
-- 🛡️ FUNCIONES DE FILTRADO (TEAM Y AMIGOS)
-- =========================================================
local function esCompaneroDeTeam(jugador)
    if not CONFIG.OcultarTeam then
        return false
    end

    local miTeam = LocalPlayer.Team
    if not miTeam then
        return false
    end

    return jugador.Team == miTeam
end

local function esEnemigo(jugador)
    local miTeam = LocalPlayer.Team
    if not miTeam then
        return true 
    end

    return jugador.Team ~= miTeam
end

-- =========================================================
-- 👁️ FUNCIÓN: VERIFICAR SI EL OBJETIVO ESTÁ VISIBLE
-- =========================================================
local function objetivoEsVisible(targetPart, targetChar, localCharacter)
    Camera = workspace.CurrentCamera or Camera

    if not Camera or not targetPart or not targetChar then
        return false
    end

    local cameraPos = Camera.CFrame.Position
    local direction = targetPart.Position - cameraPos
    local distance = direction.Magnitude

    if distance <= 0 then
        return true
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local filtros = {targetChar}
    if localCharacter then
        table.insert(filtros, localCharacter)
    end

    rayParams.FilterDescendantsInstances = filtros

    local result = workspace:Raycast(cameraPos, direction.Unit * distance, rayParams)

    if not result then
        return true
    end

    return result.Instance:IsDescendantOf(targetChar)
end

-- =========================================================
-- 🧠 FILTRADO Y SELECCIÓN DE OBJETIVOS (APUNTADO DINÁMICO)
-- =========================================================
local function obtenerObjetivoValido()
    if not CONFIG.AimbotGlobal then
        return nil
    end

    Camera = workspace.CurrentCamera or Camera
    if not Camera then
        return nil
    end

    local character = LocalPlayer.Character
    if not character then
        return nil
    end

    local rootLocal = character:FindFirstChild("HumanoidRootPart")
    if not rootLocal then
        return nil
    end
    
    local posicionLocal = rootLocal.Position
    
    local mejorObjetivo = nil
    local mejorPrimario = nil
    local mejorSecundario = nil

    for _, jugador in ipairs(Players:GetPlayers()) do
        if jugador ~= LocalPlayer 
            and not amigosCache[jugador.UserId] 
            and esEnemigo(jugador) then
            
            local char = jugador.Character
            if not char then
                continue
            end
            
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            
            if humanoid and humanoid.Health > 0 and root then
                local distanciaMundo = (posicionLocal - root.Position).Magnitude
                
                if distanciaMundo <= CONFIG.DistanciaMaxAim then
                    local targetPartName = distanciaMundo <= CONFIG.DistanciaCambioCabeza and "Head" or "HumanoidRootPart"
                    local targetPart = char:FindFirstChild(targetPartName) or root
                    
                    local posicionPart = targetPart.Position
                    local posicionPantalla, enPantalla = Camera:WorldToViewportPoint(posicionPart)
                    
                    if enPantalla then
                        local centroPantalla = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local dist2D = (centroPantalla - Vector2.new(posicionPantalla.X, posicionPantalla.Y)).Magnitude
                        
                        if dist2D <= CONFIG.MaxFovRadio then
                            -- Solo aceptar objetivos visibles
                            if objetivoEsVisible(targetPart, char, character) then
                                local seleccionar = false

                                if CONFIG.ModoApuntado == "MAS CERCANO" then
                                    if mejorPrimario == nil
                                        or distanciaMundo < mejorPrimario
                                        or (distanciaMundo == mejorPrimario and dist2D < mejorSecundario) then
                                        seleccionar = true
                                    end

                                elseif CONFIG.ModoApuntado == "MAS LEJANO" then
                                    if mejorPrimario == nil
                                        or distanciaMundo > mejorPrimario
                                        or (distanciaMundo == mejorPrimario and dist2D < mejorSecundario) then
                                        seleccionar = true
                                    end

                                else
                                    -- EN MIRA / CROSSHAIR
                                    if mejorPrimario == nil
                                        or dist2D < mejorPrimario
                                        or (dist2D == mejorPrimario and distanciaMundo < mejorSecundario) then
                                        seleccionar = true
                                    end
                                end

                                if seleccionar then
                                    if CONFIG.ModoApuntado == "MAS CERCANO" or CONFIG.ModoApuntado == "MAS LEJANO" then
                                        mejorPrimario = distanciaMundo
                                        mejorSecundario = dist2D
                                    else
                                        mejorPrimario = dist2D
                                        mejorSecundario = distanciaMundo
                                    end

                                    mejorObjetivo = targetPart
                                end
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
-- 🗑️ LIMPIADOR EXCLUSIVO DE OBJETOS ESP
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
-- 👁️ MOTOR DE RENDERIZADO CENTRALIZADO (ESP)
-- =========================================================
local function gestionarESP()
    if not CONFIG.EspGlobal then
        for pName, _ in pairs(ESP_Container) do
            limpiarESPPlayer(pName)
        end
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

                local esValido = char and root and head and hum and hum.Health > 0 

                if esValido and rootLocal then
                    local distancia = (rootLocal.Position - root.Position).Magnitude

                    if distancia <= CONFIG.DistanciaMaxESP then
                        
                        if not ESP_Container[pName] then
                            local colorEfecto = amigosCache[player.UserId] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(140, 0, 255)
                            
                            local bGui = Instance.new("BillboardGui", ScreenGuiESP)
                            bGui.Name = "Box_" .. pName
                            bGui.Size = UDim2.new(4.5, 0, 6, 0)
                            bGui.AlwaysOnTop = true

                            local bFrame = Instance.new("Frame", bGui)
                            bFrame.Size = UDim2.new(1, 0, 1, 0)
                            bFrame.BackgroundTransparency = 1

                            local stroke = Instance.new("UIStroke", bFrame)
                            stroke.Color = colorEfecto
                            stroke.Thickness = 2
                            
                            local nGui = Instance.new("BillboardGui", ScreenGuiESP)
                            nGui.Name = "Name_" .. pName
                            nGui.Size = UDim2.new(0, 200, 0, 80)
                            nGui.StudsOffset = Vector3.new(0, 3.5, 0)
                            nGui.AlwaysOnTop = true

                            local lbl = Instance.new("TextLabel", nGui)
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.TextColor3 = colorEfecto
                            lbl.TextStrokeTransparency = 0
                            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextSize = 13
                            lbl.TextWrapped = true
                            
                            local beam = Instance.new("Beam")
                            beam.Color = ColorSequence.new(colorEfecto)
                            beam.Width0 = 0.04
                            beam.Width1 = 0.04
                            beam.FaceCamera = true
                            
                            local attEnemy = Instance.new("Attachment", root)
                            attEnemy.Name = "ESP_AttEnemy"

                            ESP_Container[pName] = {
                                BoxGui = bGui,
                                NameGui = nGui,
                                TextLabel = lbl,
                                Tracer = beam,
                                EnemyAtt = attEnemy,
                                Stroke = stroke
                            }
                        end

                        local data = ESP_Container[pName]
                        
                        if not data.EnemyAtt or not data.EnemyAtt.Parent then
                            if data.EnemyAtt then
                                pcall(function()
                                    data.EnemyAtt:Destroy()
                                end)
                            end

                            data.EnemyAtt = Instance.new("Attachment", root)
                            data.EnemyAtt.Name = "ESP_AttEnemy"
                        end
                        
                        local colorEfecto = amigosCache[player.UserId] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(140, 0, 255)
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
                            
                            local textoFinal = ""
                            if CONFIG.MostrarNombres then
                                textoFinal = player.Name
                            end

                            textoFinal = textoFinal .. armaText .. distText
                            data.TextLabel.Text = textoFinal
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
        if not Players:FindFirstChild(pName) then
            limpiarESPPlayer(pName)
        end
    end
end

-- =========================================================
-- 🔄 EVENTOS DE ENTRADA DE USUARIO (INPUTS)
-- =========================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    Camera = workspace.CurrentCamera or Camera

    -- Bloquear inputs mientras carga
    if cargando then
        return
    end

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

    if gameProcessed and UserInputService:GetFocusedTextBox() then
        return
    end

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

                if UIStroke then
                    UIStroke.Color = objetivoActual and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 150, 0)
                end

                pcall(function()
                    StarterGui:SetCore("SendNotification", {
                        Title = "Sistema",
                        Text = "Aimbot MANTENER activo",
                        Duration = 1
                    })
                end)
            end
        else
            -- TOGGLE
            aimbotActivo = not aimbotActivo

            if aimbotActivo then
                objetivoActual = obtenerObjetivoValido()

                if UIStroke then
                    UIStroke.Color = objetivoActual and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 150, 0)
                end

                pcall(function()
                    StarterGui:SetCore("SendNotification", {
                        Title = "Sistema",
                        Text = "Aimbot ON: buscando enemigos",
                        Duration = 1
                    })
                end)
            else
                objetivoActual = nil

                if UIStroke then
                    UIStroke.Color = Color3.fromRGB(255, 0, 0)
                end

                pcall(function()
                    StarterGui:SetCore("SendNotification", {
                        Title = "Sistema",
                        Text = "Aimbot OFF",
                        Duration = 1
                    })
                end)
            end
        end
    end
end)

-- NUEVO: DETECTAR CUANDO SE SUELTA LA TECLA EN MODO MANTENER
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    Camera = workspace.CurrentCamera or Camera

    if cargando then
        return
    end

    if cambiandoKeybind then
        return
    end

    if not CONFIG.AimbotGlobal then
        return
    end

    if CONFIG.ModoTeclaAimbot ~= "MANTENER" then
        return
    end

    local esTeclaAimbot = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.TeclaAimbot)
    local esMouseAimbot = (CONFIG.TeclaMouse and input.UserInputType == CONFIG.TeclaMouse)

    if esTeclaAimbot or esMouseAimbot then
        aimbotActivo = false
        objetivoActual = nil

        if UIStroke then
            UIStroke.Color = Color3.fromRGB(255, 0, 0)
        end

        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Sistema",
                Text = "Aimbot MANTENER apagado",
                Duration = 1
            })
        end)
    end
end)

-- =========================================================
-- 🚀 BUCLE SÍNCRONO DEFINITIVO (RENDERSTEPPED)
-- =========================================================
RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera or Camera

    -- Mientras carga, no renderizamos ESP ni aimbot
    if cargando then
        if FrameCirculo then
            FrameCirculo.Visible = false
        end
        return
    end

    if FrameCirculo then
        FrameCirculo.Position = UDim2.new(0.5, 0, 0.5, 0)
        FrameCirculo.Visible = CONFIG.MostrarFov
    end
    
    gestionarESP()

    if not CONFIG.AimbotGlobal then
        aimbotActivo = false
        objetivoActual = nil

        if UIStroke then
            UIStroke.Color = Color3.fromRGB(255, 0, 0)
        end

        return
    end

    if not aimbotActivo then
        if UIStroke then
            UIStroke.Color = Color3.fromRGB(255, 0, 0)
        end
        return
    end

    -- MODO BÚSQUEDA CONSTANTE
    if not objetivoActual or not objetivoActual.Parent then
        objetivoActual = obtenerObjetivoValido()
    end

    if not objetivoActual or not objetivoActual.Parent then
        if UIStroke then
            UIStroke.Color = Color3.fromRGB(255, 150, 0)
        end
        return
    end

    local targetPlayer = Players:GetPlayerFromCharacter(objetivoActual.Parent)
    
    if targetPlayer and (amigosCache[targetPlayer.UserId] or not esEnemigo(targetPlayer)) then
        objetivoActual = nil

        if UIStroke then
            UIStroke.Color = Color3.fromRGB(255, 150, 0)
        end

        return
    end

    local targetChar = objetivoActual.Parent
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        objetivoActual = nil

        if UIStroke then
            UIStroke.Color = Color3.fromRGB(255, 150, 0)
        end

        return
    end

    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    local localCharacter = LocalPlayer.Character
    local rootLocal = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

    if not targetRoot or not rootLocal then
        objetivoActual = nil

        if UIStroke then
            UIStroke.Color = Color3.fromRGB(255, 150, 0)
        end

        return
    end
    
    local distanciaMundo = (rootLocal.Position - targetRoot.Position).Magnitude
    
    local targetPartName = distanciaMundo <= CONFIG.DistanciaCambioCabeza and "Head" or "HumanoidRootPart"
    local targetPart = targetChar:FindFirstChild(targetPartName) or targetRoot
    
    objetivoActual = targetPart 
    
    local posicionReal = targetPart.Position
    local targetPos = posicionReal

    -- PREDICCIÓN DE MOVIMIENTO (LEADING)
    if CONFIG.Prediccion > 0 then
        local velocity = targetRoot.AssemblyLinearVelocity
        local dist3D = (rootLocal.Position - posicionReal).Magnitude
        local timeToTarget = dist3D / CONFIG.VelocidadBalaEstimada
        targetPos = targetPos + (velocity * timeToTarget * CONFIG.Prediccion)
    end

    local posicionPantalla, enPantalla = Camera:WorldToViewportPoint(targetPos)
    local centroPantalla = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local dist2D = enPantalla and (centroPantalla - Vector2.new(posicionPantalla.X, posicionPantalla.Y)).Magnitude or math.huge

    -- Verificación continua de visibilidad
    local visible = enPantalla and objetivoEsVisible(targetPart, targetChar, localCharacter)

    if visible and dist2D <= CONFIG.MaxFovRadio and distanciaMundo <= CONFIG.DistanciaMaxAim then
        local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        local lerpAlpha = 1 - CONFIG.Smoothness 
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, lerpAlpha)

        if UIStroke then
            UIStroke.Color = Color3.fromRGB(0, 255, 0)
        end
    else
        -- Si el enemigo se oculta, sale del FOV o deja de ser válido,
        -- se suelta el objetivo pero el aimbot sigue buscando.
        objetivoActual = nil

        if UIStroke then
            UIStroke.Color = Color3.fromRGB(255, 150, 0)
        end
    end
end)
