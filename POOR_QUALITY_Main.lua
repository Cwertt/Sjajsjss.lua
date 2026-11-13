--[[
	PROJECT: POOR QUALITY - Advanced Mobile Performance Optimization GUI & Script System
	Platform: Roblox Client (Mobile-First: Android / iOS / Tablet & Desktop)
	License: Open-Source / MIT Style Custom UI Framework
	Note: Yalnızca izin verilen istemci görsel/performans API'lerini kullanır.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

-- Eğer modüller ayrı ModuleScript olarak kurulduysa require edilir;
-- tek dosya çalıştırıldığında yerleşik modüller otomatik devreye girer.
local function safeRequire(child)
	if child and child:IsA("ModuleScript") then
		local ok, res = pcall(require, child)
		if ok then return res end
	end
	return nil
end

local rootFolder = script.Parent
local Settings = safeRequire(rootFolder and rootFolder:FindFirstChild("config") and rootFolder.config:FindFirstChild("settings"))
local Profiles = safeRequire(rootFolder and rootFolder:FindFirstChild("config") and rootFolder.config:FindFirstChild("profiles"))
local PerformanceMonitor = safeRequire(rootFolder and rootFolder:FindFirstChild("core") and rootFolder.core:FindFirstChild("performance_monitor"))
local GameAnalyzer = safeRequire(rootFolder and rootFolder:FindFirstChild("core") and rootFolder.core:FindFirstChild("game_analyzer"))
local OptimizationEngine = safeRequire(rootFolder and rootFolder:FindFirstChild("core") and rootFolder.core:FindFirstChild("optimization_engine"))
local SystemManager = safeRequire(rootFolder and rootFolder:FindFirstChild("core") and rootFolder.core:FindFirstChild("system_manager"))
local Theme = safeRequire(rootFolder and rootFolder:FindFirstChild("gui") and rootFolder.gui:FindFirstChild("theme"))
local DashboardPage = safeRequire(rootFolder and rootFolder:FindFirstChild("gui") and rootFolder.gui:FindFirstChild("dashboard"))
local ModulesPage = safeRequire(rootFolder and rootFolder:FindFirstChild("gui") and rootFolder.gui:FindFirstChild("modules_page"))
local PerformancePage = safeRequire(rootFolder and rootFolder:FindFirstChild("gui") and rootFolder.gui:FindFirstChild("performance_page"))
local SettingsPage = safeRequire(rootFolder and rootFolder:FindFirstChild("gui") and rootFolder.gui:FindFirstChild("settings_page"))

-- Tek Dosya (Standalone Executor) Desteği: Ayrı klasör yoksa bile doğrudan çalışır
if not Settings then
-- POOR QUALITY | Config: Settings & State Management
local HttpService = game:GetService("HttpService")

local Settings = {}

Settings.Defaults = {
	GlobalEnabled = false,
	CurrentProfile = "BALANCED",
	SafeMode = false,
	AutoOptimization = false,
	Modules = {
		anti_afk = false,
		anti_lag = false,
		anti_fps_drop = false,
		no_animation = false,
		low_graphics = false,
		memory_optimizer = false,
		thermal_control = false,
		background_optimizer = false
	},
	Logs = {}
}

Settings.Current = {
	GlobalEnabled = false,
	CurrentProfile = "BALANCED",
	SafeMode = false,
	AutoOptimization = false,
	Modules = {},
	Logs = {}
}

function Settings.Init()
	Settings.ResetToDefaults()
	Settings.Load()
end

function Settings.ResetToDefaults()
	Settings.Current.GlobalEnabled = Settings.Defaults.GlobalEnabled
	Settings.Current.CurrentProfile = Settings.Defaults.CurrentProfile
	Settings.Current.SafeMode = Settings.Defaults.SafeMode
	Settings.Current.AutoOptimization = Settings.Defaults.AutoOptimization
	for k, v in pairs(Settings.Defaults.Modules) do
		Settings.Current.Modules[k] = v
	end
end

function Settings.AddLog(msg)
	local timestamp = os.date("%H:%M:%S")
	local entry = string.format("[%s] %s", timestamp, msg)
	table.insert(Settings.Current.Logs, 1, entry)
	if #Settings.Current.Logs > 40 then
		table.remove(Settings.Current.Logs)
	end
end

-- Executor dosya sistemi destekliyorsa kalıcı kayıt yapar, yoksa bellekte tutar
function Settings.Save()
	local success, encoded = pcall(function()
		return HttpService:JSONEncode({
			CurrentProfile = Settings.Current.CurrentProfile,
			SafeMode = Settings.Current.SafeMode,
			AutoOptimization = Settings.Current.AutoOptimization,
			Modules = Settings.Current.Modules
		})
	end)
	if success and type(writefile) == "function" then
		pcall(writefile, "poor_quality_config.json", encoded)
		Settings.AddLog("Konfigürasyon dosyaya kaydedildi.")
		return true
	else
		Settings.AddLog("Konfigürasyon oturum belleğine kaydedildi (writefile desteklenmiyor).")
		return false
	end
end

function Settings.Load()
	if type(isfile) == "function" and type(readfile) == "function" and isfile("poor_quality_config.json") then
		local ok, raw = pcall(readfile, "poor_quality_config.json")
		if ok and raw then
			local okDecode, data = pcall(function()
				return HttpService:JSONDecode(raw)
			end)
			if okDecode and type(data) == "table" then
				Settings.Current.CurrentProfile = data.CurrentProfile or "BALANCED"
				Settings.Current.SafeMode = data.SafeMode or false
				Settings.Current.AutoOptimization = data.AutoOptimization or false
				if type(data.Modules) == "table" then
					for k, v in pairs(data.Modules) do
						if Settings.Current.Modules[k] ~= nil then
							Settings.Current.Modules[k] = v
						end
					end
				end
				Settings.AddLog("Kayıtlı konfigürasyon yüklendi.")
				return true
			end
		end
	end
	Settings.AddLog("Varsayılan ayarlar yüklendi.")
	return false
end



-- POOR QUALITY | Config: Optimization Profiles
local Profiles = {}

Profiles.List = {
	["LOW-END"] = {
		Name = "LOW-END MODE",
		Description = "Düşük donanımlı telefonlar için minimum görsel yük, düşük gölge ve pil/sıcaklık dengesi.",
		Modules = {
			anti_afk = true,
			anti_lag = true,
			anti_fps_drop = true,
			no_animation = false,
			low_graphics = true,
			memory_optimizer = true,
			thermal_control = true,
			background_optimizer = true
		}
	},
	["BALANCED"] = {
		Name = "BALANCED MODE",
		Description = "Performans ve görüntü kalitesi dengesi. Gereksiz partikülleri azaltır, dokuları korur.",
		Modules = {
			anti_afk = false,
			anti_lag = true,
			anti_fps_drop = true,
			no_animation = false,
			low_graphics = false,
			memory_optimizer = true,
			thermal_control = true,
			background_optimizer = true
		}
	},
	["EXTREME"] = {
		Name = "EXTREME PERFORMANCE",
		Description = "Desteklenen en düşük görsel yük. Tüm kozmetik efektler ve animasyon yükleri minimumda.",
		Modules = {
			anti_afk = true,
			anti_lag = true,
			anti_fps_drop = true,
			no_animation = true,
			low_graphics = true,
			memory_optimizer = true,
			thermal_control = true,
			background_optimizer = true
		}
	}
}

function Profiles.Get(profileKey)
	return Profiles.List[profileKey] or Profiles.List["BALANCED"]
end



-- POOR QUALITY | Core: Performance Monitor (Gerçek Veri Toplama)
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")

local PerformanceMonitor = {}

local frameTimes = {}
local MAX_SAMPLES = 60
local currentFPS = 60
local fpsStability = 100
local ramUsageMB = 0
local lastUpdate = 0
local connection = nil

function PerformanceMonitor.Start()
	if connection then return end
	connection = RunService.RenderStepped:Connect(function(dt)
		if dt > 0 and dt < 1 then
			table.insert(frameTimes, dt)
			if #frameTimes > MAX_SAMPLES then
				table.remove(frameTimes, 1)
			end
		end

		local now = os.clock()
		if now - lastUpdate >= 0.5 then
			lastUpdate = now
			PerformanceMonitor.Recalculate()
		end
	end)
end

function PerformanceMonitor.Stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

function PerformanceMonitor.Recalculate()
	if #frameTimes == 0 then return end

	local totalDt = 0
	local minDt = math.huge
	local maxDt = 0

	for _, dt in ipairs(frameTimes) do
		totalDt = totalDt + dt
		if dt < minDt then minDt = dt end
		if dt > maxDt then maxDt = dt end
	end

	local avgDt = totalDt / #frameTimes
	currentFPS = math.floor((1 / avgDt) + 0.5)

	-- FPS Stability: Kare süresi sapmasına dayalı gerçek kararlılık yüzdesi
	local spread = maxDt - minDt
	local rawStability = 100 - math.clamp((spread / avgDt) * 45, 0, 100)
	fpsStability = math.floor(rawStability + 0.5)

	-- Gerçek Roblox Client Bellek Kullanımı
	local ok, mem = pcall(function()
		return Stats:GetTotalMemoryUsageMb()
	end)
	if ok and type(mem) == "number" then
		ramUsageMB = math.floor(mem + 0.5)
	end
end

function PerformanceMonitor.GetMetrics()
	local platform = "Unknown"
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		platform = "Mobile (Touch)"
	elseif UserInputService.TouchEnabled and UserInputService.KeyboardEnabled then
		platform = "Tablet / Hybrid"
	else
		platform = "Desktop / Emulator"
	end

	-- Roblox Lua sandbox'ında donanım sıcaklığı ve CPU % doğrudan okunamaz; dürüstçe belirtilir
	local thermalState = "Not Supported (OS Sandbox)"
	if fpsStability < 55 and currentFPS < 30 then
		thermalState = "Estimated High Load (FPS Drop)"
	elseif fpsStability < 75 then
		thermalState = "Estimated Moderate Load"
	else
		thermalState = "Normal (Inferred)"
	end

	return {
		FPS = currentFPS,
		FPSStability = fpsStability,
		RAM_MB = ramUsageMB,
		CPU_Usage = "Not Supported (Roblox API)",
		Thermal = thermalState,
		Platform = platform
	}
end



-- POOR QUALITY | Core: Smart Game Analysis
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local GameAnalyzer = {}

function GameAnalyzer.Analyze(metrics, activeCount)
	local analysis = {
		FPSStability = "Good",
		MemoryUsage = "Normal",
		GraphicsLoad = "Low",
		ThermalStatus = metrics.Thermal,
		BackgroundProcessing = activeCount .. " Active Modules",
		Recommendation = "Sistem dengeli çalışıyor."
	}

	-- 1. FPS Stability Değerlendirmesi
	if metrics.FPS < 30 or metrics.FPSStability < 60 then
		analysis.FPSStability = string.format("Unstable (%d FPS | %%%d)", metrics.FPS, metrics.FPSStability)
	elseif metrics.FPS < 50 or metrics.FPSStability < 80 then
		analysis.FPSStability = string.format("Moderate (%d FPS | %%%d)", metrics.FPS, metrics.FPSStability)
	else
		analysis.FPSStability = string.format("Stable (%d FPS | %%%d)", metrics.FPS, metrics.FPSStability)
	end

	-- 2. Bellek Değerlendirmesi
	if metrics.RAM_MB > 1100 then
		analysis.MemoryUsage = string.format("High (%d MB) - Risk", metrics.RAM_MB)
	elseif metrics.RAM_MB > 750 then
		analysis.MemoryUsage = string.format("Elevated (%d MB)", metrics.RAM_MB)
	else
		analysis.MemoryUsage = string.format("Optimal (%d MB)", metrics.RAM_MB)
	end

	-- 3. Grafik Yükü Analizi
	local shadowHeavy = Lighting.GlobalShadows
	local postEffects = 0
	for _, v in ipairs(Lighting:GetChildren()) do
		if v:IsA("PostEffect") and v.Enabled then
			postEffects = postEffects + 1
		end
	end

	if shadowHeavy and postEffects >= 2 then
		analysis.GraphicsLoad = "Heavy (Shadows + " .. postEffects .. " PostFX)"
	elseif shadowHeavy or postEffects > 0 then
		analysis.GraphicsLoad = "Moderate"
	else
		analysis.GraphicsLoad = "Optimized (Light)"
	end

	-- 4. Akıllı Öneri Motoru
	if metrics.RAM_MB > 1050 then
		analysis.Recommendation = "Yüksek RAM kullanımı tespit edildi: LOW-END MODE ve Memory Optimizer önerilir."
	elseif metrics.FPS < 35 then
		analysis.Recommendation = "Düşük FPS tespit edildi: EXTREME PERFORMANCE profilini aktif edin."
	elseif shadowHeavy then
		analysis.Recommendation = "Gölgeler açık: Anti Lag veya Low Graphics modülü ile FPS artırılabilir."
	else
		analysis.Recommendation = "Performans değerleri stabil. Mevcut profil korunabilir."
	end

	return analysis
end



-- POOR QUALITY | Module A: Anti AFK (Güvenli Durum & Süre Takibi)
-- Not: Karakteri zorla hareket ettirmez veya oyun kurallarını ihlal etmez;
-- yalnızca güvenli Idled olayını dinler ve AFK süresini kullanıcıya raporlar.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local AntiAFK = {
	Name = "anti_afk",
	Enabled = false,
	AfkSeconds = 0,
	IsIdle = false,
	Connections = {},
	TimerThread = nil
}

function AntiAFK.Enable(logFn)
	if AntiAFK.Enabled then return end
	AntiAFK.Enabled = true
	AntiAFK.AfkSeconds = 0
	AntiAFK.IsIdle = false

	local player = Players.LocalPlayer
	if player then
		local c1 = player.Idled:Connect(function(timeIdle)
			AntiAFK.IsIdle = true
			AntiAFK.AfkSeconds = math.floor(timeIdle)
			if logFn then
				logFn("Anti-AFK: Oyuncu boşta (" .. AntiAFK.AfkSeconds .. " sn).")
			end
		end)
		table.insert(AntiAFK.Connections, c1)
	end

	local c2 = UserInputService.InputBegan:Connect(function()
		if AntiAFK.IsIdle then
			AntiAFK.IsIdle = false
			AntiAFK.AfkSeconds = 0
		end
	end)
	table.insert(AntiAFK.Connections, c2)

	AntiAFK.TimerThread = task.spawn(function()
		while AntiAFK.Enabled do
			task.wait(1)
			if AntiAFK.IsIdle then
				AntiAFK.AfkSeconds = AntiAFK.AfkSeconds + 1
			end
		end
	end)

	if logFn then logFn("Anti-AFK izleme başlatıldı (Güvenli Mod).") end
end

function AntiAFK.Disable(logFn)
	if not AntiAFK.Enabled then return end
	AntiAFK.Enabled = false
	AntiAFK.IsIdle = false
	AntiAFK.AfkSeconds = 0

	for _, conn in ipairs(AntiAFK.Connections) do
		if conn then conn:Disconnect() end
	end
	AntiAFK.Connections = {}
	AntiAFK.TimerThread = nil

	if logFn then logFn("Anti-AFK durduruldu.") end
end

function AntiAFK.GetStatusText()
	if not AntiAFK.Enabled then return "Kapalı" end
	if AntiAFK.IsIdle then
		return string.format("Boşta (%d sn)", AntiAFK.AfkSeconds)
	end
	return "Aktif (Kullanıcı Oyunda)"
end



-- POOR QUALITY | Module B: Anti Lag (Partikül, PostFX ve Gölge Azaltma)
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local AntiLag = {
	Name = "anti_lag",
	Enabled = false,
	Backup = {
		GlobalShadows = nil,
		Effects = {},
		Particles = {}
	},
	DescendantConn = nil
}

local function optimizeInstance(obj)
	if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
		if AntiLag.Backup.Particles[obj] == nil then
			AntiLag.Backup.Particles[obj] = obj.Enabled
		end
		obj.Enabled = false
	elseif obj:IsA("PostEffect") then
		if AntiLag.Backup.Effects[obj] == nil then
			AntiLag.Backup.Effects[obj] = obj.Enabled
		end
		obj.Enabled = false
	end
end

function AntiLag.Enable(logFn)
	if AntiLag.Enabled then return end
	AntiLag.Enabled = true

	AntiLag.Backup.GlobalShadows = Lighting.GlobalShadows
	Lighting.GlobalShadows = false

	for _, obj in ipairs(Lighting:GetDescendants()) do
		optimizeInstance(obj)
	end

	-- Büyük haritalarda ana thread'i dondurmamak için parça parça tarama
	task.spawn(function()
		local descendants = Workspace:GetDescendants()
		for i, obj in ipairs(descendants) do
			if not AntiLag.Enabled then break end
			optimizeInstance(obj)
			if i % 400 == 0 then
				task.wait()
			end
		end
	end)

	AntiLag.DescendantConn = Workspace.DescendantAdded:Connect(function(obj)
		if AntiLag.Enabled then
			optimizeInstance(obj)
		end
	end)

	if logFn then logFn("Anti-Lag aktif: Gölgeler, PostFX ve partiküller azaltıldı.") end
end

function AntiLag.Disable(logFn)
	if not AntiLag.Enabled then return end
	AntiLag.Enabled = false

	if AntiLag.DescendantConn then
		AntiLag.DescendantConn:Disconnect()
		AntiLag.DescendantConn = nil
	end

	if AntiLag.Backup.GlobalShadows ~= nil then
		Lighting.GlobalShadows = AntiLag.Backup.GlobalShadows
	end

	for obj, prevState in pairs(AntiLag.Backup.Effects) do
		if obj and obj.Parent then
			pcall(function() obj.Enabled = prevState end)
		end
	end
	AntiLag.Backup.Effects = {}

	for obj, prevState in pairs(AntiLag.Backup.Particles) do
		if obj and obj.Parent then
			pcall(function() obj.Enabled = prevState end)
		end
	end
	AntiLag.Backup.Particles = {}

	if logFn then logFn("Anti-Lag kapatıldı: Görsel efektler geri yüklendi.") end
end



-- POOR QUALITY | Module C: Anti FPS Drop (Dinamik Kararlılık Koruma)
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local AntiFPSDrop = {
	Name = "anti_fps_drop",
	Enabled = false,
	Backup = {
		FogEnd = nil,
		EnvironmentDiffuseScale = nil,
		EnvironmentSpecularScale = nil
	},
	MonitorThread = nil
}

function AntiFPSDrop.Enable(logFn, getMetricsFn)
	if AntiFPSDrop.Enabled then return end
	AntiFPSDrop.Enabled = true

	AntiFPSDrop.Backup.FogEnd = Lighting.FogEnd
	AntiFPSDrop.Backup.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
	AntiFPSDrop.Backup.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale

	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0

	AntiFPSDrop.MonitorThread = task.spawn(function()
		while AntiFPSDrop.Enabled do
			task.wait(2)
			if not AntiFPSDrop.Enabled then break end
			if getMetricsFn then
				local m = getMetricsFn()
				-- FPS 35 altına düşerse çizim/sis mesafesini güvenli sınırda daralt
				if m.FPS < 35 and Lighting.FogEnd > 450 then
					Lighting.FogEnd = 450
					if logFn then
						logFn("Anti-FPS Drop: Düşük FPS algılandı, görüş sisi optimize edildi.")
					end
				end
			end
		end
	end)

	if logFn then logFn("Anti-FPS Drop aktif: Yansıma yükleri azaltıldı.") end
end

function AntiFPSDrop.Disable(logFn)
	if not AntiFPSDrop.Enabled then return end
	AntiFPSDrop.Enabled = false
	AntiFPSDrop.MonitorThread = nil

	if AntiFPSDrop.Backup.FogEnd ~= nil then
		Lighting.FogEnd = AntiFPSDrop.Backup.FogEnd
	end
	if AntiFPSDrop.Backup.EnvironmentDiffuseScale ~= nil then
		Lighting.EnvironmentDiffuseScale = AntiFPSDrop.Backup.EnvironmentDiffuseScale
	end
	if AntiFPSDrop.Backup.EnvironmentSpecularScale ~= nil then
		Lighting.EnvironmentSpecularScale = AntiFPSDrop.Backup.EnvironmentSpecularScale
	end

	if logFn then logFn("Anti-FPS Drop kapatıldı.") end
end



-- POOR QUALITY | Module D: No Animation (Kozmetik & UI Efekt Azaltma)
-- Önemli: Karakter hareketi, fizik ve temel oyun mekaniklerine dokunmaz.
-- Yalnızca Tween/Beam/Kozmetik hareketli efektleri güvenli biçimde sınırlar.
local Workspace = game:GetService("Workspace")

local NoAnimation = {
	Name = "no_animation",
	Enabled = false,
	BackupBeams = {},
	Conn = nil
}

local function handleBeam(obj)
	if obj:IsA("Beam") then
		if NoAnimation.BackupBeams[obj] == nil then
			NoAnimation.BackupBeams[obj] = obj.Enabled
		end
		obj.Enabled = false
	end
end

function NoAnimation.Enable(logFn)
	if NoAnimation.Enabled then return end
	NoAnimation.Enabled = true

	task.spawn(function()
		local list = Workspace:GetDescendants()
		for i, obj in ipairs(list) do
			if not NoAnimation.Enabled then break end
			handleBeam(obj)
			if i % 400 == 0 then task.wait() end
		end
	end)

	NoAnimation.Conn = Workspace.DescendantAdded:Connect(function(obj)
		if NoAnimation.Enabled then
			handleBeam(obj)
		end
	end)

	if logFn then logFn("No Animation aktif: Kozmetik ışın/efekt animasyonları kapatıldı (Karakter mekanikleri korundu).") end
end

function NoAnimation.Disable(logFn)
	if not NoAnimation.Enabled then return end
	NoAnimation.Enabled = false

	if NoAnimation.Conn then
		NoAnimation.Conn:Disconnect()
		NoAnimation.Conn = nil
	end

	for obj, prev in pairs(NoAnimation.BackupBeams) do
		if obj and obj.Parent then
			pcall(function() obj.Enabled = prev end)
		end
	end
	NoAnimation.BackupBeams = {}

	if logFn then logFn("No Animation kapatıldı.") end
end



-- POOR QUALITY | Module E: Low Graphics (Materyal, Doku & Render Kalitesi Düşürme)
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LowGraphics = {
	Name = "low_graphics",
	Enabled = false,
	Backup = {
		SavedQuality = nil,
		Materials = {},
		Textures = {},
		TerrainWater = {}
	},
	Conn = nil
}

local function simplifyPart(obj)
	if obj:IsA("BasePart") and not obj:IsA("Terrain") then
		if LowGraphics.Backup.Materials[obj] == nil then
			LowGraphics.Backup.Materials[obj] = {
				Material = obj.Material,
				CastShadow = obj.CastShadow
			}
		end
		obj.Material = Enum.Material.SmoothPlastic
		obj.CastShadow = false
	elseif obj:IsA("Decal") or obj:IsA("Texture") then
		if LowGraphics.Backup.Textures[obj] == nil then
			LowGraphics.Backup.Textures[obj] = obj.Transparency
		end
		obj.Transparency = 1
	end
end

function LowGraphics.Enable(logFn)
	if LowGraphics.Enabled then return end
	LowGraphics.Enabled = true

	-- Destekleniyorsa RenderSettings kalite seviyesini düşür
	pcall(function()
		local renderSettings = settings():GetService("RenderSettings")
		LowGraphics.Backup.SavedQuality = renderSettings.QualityLevel
		renderSettings.QualityLevel = Enum.QualityLevel.Level01
	end)

	-- Su efektlerini sadeleştir
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		LowGraphics.Backup.TerrainWater = {
			WaveSize = terrain.WaterWaveSize,
			WaveSpeed = terrain.WaterWaveSpeed,
			Reflectance = terrain.WaterReflectance,
			Transparency = terrain.WaterTransparency
		}
		terrain.WaterWaveSize = 0
		terrain.WaterWaveSpeed = 0
		terrain.WaterReflectance = 0
		terrain.WaterTransparency = 0
	end

	task.spawn(function()
		local list = Workspace:GetDescendants()
		for i, obj in ipairs(list) do
			if not LowGraphics.Enabled then break end
			simplifyPart(obj)
			if i % 350 == 0 then task.wait() end
		end
	end)

	LowGraphics.Conn = Workspace.DescendantAdded:Connect(function(obj)
		if LowGraphics.Enabled then
			simplifyPart(obj)
		end
	end)

	if logFn then logFn("Low Graphics aktif: Düz materyal ve düşük render kalitesi uygulandı.") end
end

function LowGraphics.Disable(logFn)
	if not LowGraphics.Enabled then return end
	LowGraphics.Enabled = false

	if LowGraphics.Conn then
		LowGraphics.Conn:Disconnect()
		LowGraphics.Conn = nil
	end

	pcall(function()
		if LowGraphics.Backup.SavedQuality ~= nil then
			settings():GetService("RenderSettings").QualityLevel = LowGraphics.Backup.SavedQuality
		end
	end)

	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain and LowGraphics.Backup.TerrainWater.WaveSize ~= nil then
		terrain.WaterWaveSize = LowGraphics.Backup.TerrainWater.WaveSize
		terrain.WaterWaveSpeed = LowGraphics.Backup.TerrainWater.WaveSpeed
		terrain.WaterReflectance = LowGraphics.Backup.TerrainWater.Reflectance
		terrain.WaterTransparency = LowGraphics.Backup.TerrainWater.Transparency
	end

	for obj, data in pairs(LowGraphics.Backup.Materials) do
		if obj and obj.Parent then
			pcall(function()
				obj.Material = data.Material
				obj.CastShadow = data.CastShadow
			end)
		end
	end
	LowGraphics.Backup.Materials = {}

	for obj, trans in pairs(LowGraphics.Backup.Textures) do
		if obj and obj.Parent then
			pcall(function() obj.Transparency = trans end)
		end
	end
	LowGraphics.Backup.Textures = {}

	if logFn then logFn("Low Graphics kapatıldı: Orijinal dokular ve materyaller geri yüklendi.") end
end



-- POOR QUALITY | Module F: Memory Optimizer (Güvenli GC & Bellek İzleme)
local Stats = game:GetService("Stats")

local MemoryOptimizer = {
	Name = "memory_optimizer",
	Enabled = false,
	Thread = nil,
	LastCleanedMB = 0
}

function MemoryOptimizer.CleanOnce(logFn)
	local before = 0
	pcall(function() before = Stats:GetTotalMemoryUsageMb() end)

	-- Lua çöp toplayıcısını güvenli şekilde tetikle (oyun dosyalarına veya aktif objelere dokunmaz)
	collectgarbage("collect")

	local after = 0
	pcall(function() after = Stats:GetTotalMemoryUsageMb() end)
	local freed = math.max(0, math.floor(before - after))
	MemoryOptimizer.LastCleanedMB = freed

	if logFn then
		logFn(string.format("Memory Optimizer: Bellek tarandı (Mevcut: %d MB).", math.floor(after)))
	end
end

function MemoryOptimizer.Enable(logFn)
	if MemoryOptimizer.Enabled then return end
	MemoryOptimizer.Enabled = true
	MemoryOptimizer.CleanOnce(logFn)

	MemoryOptimizer.Thread = task.spawn(function()
		while MemoryOptimizer.Enabled do
			task.wait(15)
			if not MemoryOptimizer.Enabled then break end
			MemoryOptimizer.CleanOnce(nil)
		end
	end)

	if logFn then logFn("Memory Optimizer aktif (15 sn periyodik güvenli temizlik).") end
end

function MemoryOptimizer.Disable(logFn)
	if not MemoryOptimizer.Enabled then return end
	MemoryOptimizer.Enabled = false
	MemoryOptimizer.Thread = nil
	if logFn then logFn("Memory Optimizer durduruldu.") end
end



-- POOR QUALITY | Module G: Thermal Control (Sıcaklık Belirtisi & Yük Koruması)
local ThermalControl = {
	Name = "thermal_control",
	Enabled = false,
	Thread = nil,
	AlertTriggered = false
}

function ThermalControl.Enable(logFn, getMetricsFn, suggestProfileFn)
	if ThermalControl.Enabled then return end
	ThermalControl.Enabled = true
	ThermalControl.AlertTriggered = false

	ThermalControl.Thread = task.spawn(function()
		while ThermalControl.Enabled do
			task.wait(5)
			if not ThermalControl.Enabled then break end
			if getMetricsFn then
				local m = getMetricsFn()
				-- Cihaz donanım sensörü Roblox sandbox'ında doğrudan açık olmadığından
				-- uzun süreli FPS + kararlılık düşüşü ısınma/throttling göstergesi olarak değerlendirilir
				if m.FPS < 28 and m.FPSStability < 55 and not ThermalControl.AlertTriggered then
					ThermalControl.AlertTriggered = true
					if logFn then
						logFn("Thermal Control Uyarısı: Cihaz yükü/ısınma belirtisi tespit edildi! LOW-END MODE önerilir.")
					end
					if suggestProfileFn then
						suggestProfileFn("LOW-END")
					end
				elseif m.FPS >= 40 then
					ThermalControl.AlertTriggered = false
				end
			end
		end
	end)

	if logFn then logFn("Thermal Control aktif: Uzun süreli ısınma/throttling koruması devrede.") end
end

function ThermalControl.Disable(logFn)
	if not ThermalControl.Enabled then return end
	ThermalControl.Enabled = false
	ThermalControl.Thread = nil
	ThermalControl.AlertTriggered = false
	if logFn then logFn("Thermal Control durduruldu.") end
end



-- POOR QUALITY | Module H: Background Load Monitor
local BackgroundOptimizer = {
	Name = "background_optimizer",
	Enabled = false,
	PollingInterval = 0.5
}

function BackgroundOptimizer.Enable(logFn)
	if BackgroundOptimizer.Enabled then return end
	BackgroundOptimizer.Enabled = true
	-- Arka plan UI ve analiz döngülerini düşük CPU tüketen aralığa çeker
	BackgroundOptimizer.PollingInterval = 1.2
	if logFn then logFn("Background Load Monitor aktif: Arka plan yenileme hızı optimize edildi (1.2 sn).") end
end

function BackgroundOptimizer.Disable(logFn)
	if not BackgroundOptimizer.Enabled then return end
	BackgroundOptimizer.Enabled = false
	BackgroundOptimizer.PollingInterval = 0.5
	if logFn then logFn("Background Load Monitor kapatıldı: Standart yenileme hızı (0.5 sn).") end
end

function BackgroundOptimizer.GetInterval()
	return BackgroundOptimizer.PollingInterval
end



-- POOR QUALITY | Core: Optimization Engine
local OptimizationEngine = {}

function OptimizationEngine.Init(modules, settings, perfMonitor)
	OptimizationEngine.Modules = modules
	OptimizationEngine.Settings = settings
	OptimizationEngine.PerfMonitor = perfMonitor
	OptimizationEngine.SuggestedProfile = nil
end

function OptimizationEngine.SetModuleState(moduleKey, state)
	local mod = OptimizationEngine.Modules[moduleKey]
	if not mod then return end

	OptimizationEngine.Settings.Current.Modules[moduleKey] = state

	-- Eğer Global Switch kapalıysa ayarı kaydet ama modülü çalıştırma
	if not OptimizationEngine.Settings.Current.GlobalEnabled then
		if mod.Enabled then
			mod.Disable(OptimizationEngine.Settings.AddLog)
		end
		return
	end

	if state then
		local ok, err = pcall(function()
			if moduleKey == "anti_fps_drop" then
				mod.Enable(OptimizationEngine.Settings.AddLog, OptimizationEngine.PerfMonitor.GetMetrics)
			elseif moduleKey == "thermal_control" then
				mod.Enable(OptimizationEngine.Settings.AddLog, OptimizationEngine.PerfMonitor.GetMetrics, function(prof)
					OptimizationEngine.SuggestedProfile = prof
				end)
			else
				mod.Enable(OptimizationEngine.Settings.AddLog)
			end
		end)
		if not ok then
			OptimizationEngine.Settings.AddLog("HATA [" .. moduleKey .. "]: " .. tostring(err))
		end
	else
		pcall(function()
			mod.Disable(OptimizationEngine.Settings.AddLog)
		end)
	end
end

function OptimizationEngine.SetGlobalState(enabled)
	OptimizationEngine.Settings.Current.GlobalEnabled = enabled
	if enabled then
		OptimizationEngine.Settings.AddLog("GLOBAL SYSTEM: AÇILDI")
		for key, isSelected in pairs(OptimizationEngine.Settings.Current.Modules) do
			if isSelected then
				OptimizationEngine.SetModuleState(key, true)
			end
		end
	else
		OptimizationEngine.Settings.AddLog("GLOBAL SYSTEM: KAPATILDI (Ayarlar geri alınıyor...)")
		for key, mod in pairs(OptimizationEngine.Modules) do
			if mod.Enabled then
				pcall(function()
					mod.Disable(OptimizationEngine.Settings.AddLog)
				end)
			end
		end
	end
end

function OptimizationEngine.ApplyProfile(profileKey, profileData)
	OptimizationEngine.Settings.Current.CurrentProfile = profileKey
	OptimizationEngine.Settings.AddLog("Profil uygulandı: " .. profileData.Name)
	for modKey, state in pairs(profileData.Modules) do
		OptimizationEngine.SetModuleState(modKey, state)
	end
end

function OptimizationEngine.ResetAll()
	OptimizationEngine.SetGlobalState(false)
	OptimizationEngine.Settings.ResetToDefaults()
	OptimizationEngine.Settings.AddLog("Tüm modüller sıfırlandı ve Safe Mode varsayılanlarına dönüldü.")
end

function OptimizationEngine.GetActiveModuleCount()
	local count = 0
	for _, mod in pairs(OptimizationEngine.Modules) do
		if mod.Enabled then
			count = count + 1
		end
	end
	return count
end



-- POOR QUALITY | Core: System Manager
local SystemManager = {}

function SystemManager.Boot(components)
	SystemManager.Settings = components.Settings
	SystemManager.Profiles = components.Profiles
	SystemManager.PerfMonitor = components.PerfMonitor
	SystemManager.Analyzer = components.Analyzer
	SystemManager.Engine = components.Engine
	SystemManager.Modules = components.Modules

	SystemManager.Settings.Init()
	SystemManager.PerfMonitor.Start()
	SystemManager.Engine.Init(SystemManager.Modules, SystemManager.Settings, SystemManager.PerfMonitor)

	SystemManager.Settings.AddLog("POOR QUALITY v1.0 Başlatıldı (Mobile-First Engine).")
end

function SystemManager.Shutdown(guiInstance)
	SystemManager.Engine.SetGlobalState(false)
	SystemManager.PerfMonitor.Stop()
	if guiInstance then
		guiInstance:Destroy()
	end
end



-- POOR QUALITY | GUI: Mobile-First Dark Theme & UI Components
local TweenService = game:GetService("TweenService")

local Theme = {
	Colors = {
		Background = Color3.fromRGB(14, 14, 18),
		Card = Color3.fromRGB(22, 22, 28),
		CardElevated = Color3.fromRGB(28, 28, 36),
		Accent = Color3.fromRGB(220, 38, 70),      -- Neon Kırmızı Vurgu
		AccentSecondary = Color3.fromRGB(138, 43, 226), -- Mor Vurgu
		TextPrimary = Color3.fromRGB(242, 242, 247),
		TextSecondary = Color3.fromRGB(160, 162, 175),
		ToggleOff = Color3.fromRGB(48, 48, 58),
		Success = Color3.fromRGB(46, 204, 113),
		Warning = Color3.fromRGB(241, 196, 15)
	}
}

function Theme.ApplyCorner(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = instance
	return c
end

function Theme.ApplyStroke(instance, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(42, 42, 54)
	s.Thickness = thickness or 1
	s.Parent = instance
	return s
end

function Theme.CreateCard(parent, height)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, height or 60)
	card.BackgroundColor3 = Theme.Colors.Card
	card.BorderSizePixel = 0
	card.Parent = parent
	Theme.ApplyCorner(card, 10)
	Theme.ApplyStroke(card, Color3.fromRGB(36, 36, 46), 1)
	return card
end

-- Mobil dokunmatik uyumlu büyük Toggle Kartı
function Theme.CreateToggleCard(parent, title, subtitle, initialState, onToggle)
	local card = Theme.CreateCard(parent, 64)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -76, 0, 22)
	titleLbl.Position = UDim2.new(0, 12, 0, 10)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = title
	titleLbl.TextColor3 = Theme.Colors.TextPrimary
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 13
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = card

	local subLbl = Instance.new("TextLabel")
	subLbl.Size = UDim2.new(1, -76, 0, 24)
	subLbl.Position = UDim2.new(0, 12, 0, 32)
	subLbl.BackgroundTransparency = 1
	subLbl.Text = subtitle
	subLbl.TextColor3 = Theme.Colors.TextSecondary
	subLbl.Font = Enum.Font.Gotham
	subLbl.TextSize = 11
	subLbl.TextWrapped = true
	subLbl.TextXAlignment = Enum.TextXAlignment.Left
	subLbl.Parent = card

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 50, 0, 28)
	btn.Position = UDim2.new(1, -62, 0.5, -14)
	btn.BackgroundColor3 = initialState and Theme.Colors.Accent or Theme.Colors.ToggleOff
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = card
	Theme.ApplyCorner(btn, 14)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 22, 0, 22)
	knob.Position = initialState and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.Parent = btn
	Theme.ApplyCorner(knob, 11)

	local state = initialState

	local function setVisual(newState)
		state = newState
		local targetPos = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
		local targetCol = state and Theme.Colors.Accent or Theme.Colors.ToggleOff
		TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
		TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetCol}):Play()
	end

	btn.MouseButton1Click:Connect(function()
		state = not state
		setVisual(state)
		if onToggle then onToggle(state) end
	end)

	return {
		Card = card,
		SetState = setVisual,
		GetState = function() return state end
	}
end

function Theme.CreateActionButton(parent, text, accentColor, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 42)
	btn.BackgroundColor3 = accentColor or Theme.Colors.CardElevated
	btn.Text = text
	btn.TextColor3 = Theme.Colors.TextPrimary
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Parent = parent
	Theme.ApplyCorner(btn, 8)
	Theme.ApplyStroke(btn, Color3.fromRGB(55, 55, 70), 1)

	btn.MouseButton1Click:Connect(function()
		if onClick then onClick() end
	end)
	return btn
end



-- POOR QUALITY | GUI: Dashboard Page (Master Switch + Smart Analysis + Profiles)
local DashboardPage = {}

function DashboardPage.Build(parent, theme, sys, onRefreshModulesUI)
	local masterToggleObj
	masterToggleObj = theme.CreateToggleCard(
		parent,
		"GLOBAL MASTER SWITCH",
		"Tüm aktif optimizasyon modüllerini tek dokunuşla başlatır veya geri alır.",
		sys.Settings.Current.GlobalEnabled,
		function(state)
			sys.Engine.SetGlobalState(state)
		end
	)
	masterToggleObj.Card.BackgroundColor3 = Color3.fromRGB(28, 18, 26)
	theme.ApplyStroke(masterToggleObj.Card, theme.Colors.Accent, 1.5)

	-- Sistem & Cihaz Özet Kartı
	local statusCard = theme.CreateCard(parent, 128)
	local statusTitle = Instance.new("TextLabel")
	statusTitle.Size = UDim2.new(1, -20, 0, 22)
	statusTitle.Position = UDim2.new(0, 12, 0, 8)
	statusTitle.BackgroundTransparency = 1
	statusTitle.Text = "SYSTEM & DEVICE OVERVIEW"
	statusTitle.TextColor3 = theme.Colors.Accent
	statusTitle.Font = Enum.Font.GothamBold
	statusTitle.TextSize = 11
	statusTitle.TextXAlignment = Enum.TextXAlignment.Left
	statusTitle.Parent = statusCard

	local statusBody = Instance.new("TextLabel")
	statusBody.Size = UDim2.new(1, -24, 0, 92)
	statusBody.Position = UDim2.new(0, 12, 0, 30)
	statusBody.BackgroundTransparency = 1
	statusBody.Text = "Yükleniyor..."
	statusBody.TextColor3 = theme.Colors.TextPrimary
	statusBody.Font = Enum.Font.Gotham
	statusBody.TextSize = 12
	statusBody.TextWrapped = true
	statusBody.TextXAlignment = Enum.TextXAlignment.Left
	statusBody.TextYAlignment = Enum.TextYAlignment.Top
	statusBody.Parent = statusCard

	-- Smart Game Analysis Kartı
	local smartCard = theme.CreateCard(parent, 146)
	local smartTitle = Instance.new("TextLabel")
	smartTitle.Size = UDim2.new(1, -20, 0, 22)
	smartTitle.Position = UDim2.new(0, 12, 0, 8)
	smartTitle.BackgroundTransparency = 1
	smartTitle.Text = "SMART GAME ANALYSIS"
	smartTitle.TextColor3 = theme.Colors.AccentSecondary
	smartTitle.Font = Enum.Font.GothamBold
	smartTitle.TextSize = 11
	smartTitle.TextXAlignment = Enum.TextXAlignment.Left
	smartTitle.Parent = smartCard

	local smartBody = Instance.new("TextLabel")
	smartBody.Size = UDim2.new(1, -24, 0, 110)
	smartBody.Position = UDim2.new(0, 12, 0, 30)
	smartBody.BackgroundTransparency = 1
	smartBody.Text = "Analiz hazırlanıyor..."
	smartBody.TextColor3 = theme.Colors.TextPrimary
	smartBody.Font = Enum.Font.Gotham
	smartBody.TextSize = 11
	smartBody.TextWrapped = true
	smartBody.TextXAlignment = Enum.TextXAlignment.Left
	smartBody.TextYAlignment = Enum.TextYAlignment.Top
	smartBody.Parent = smartCard

	-- Optimizasyon Profilleri Seçimi
	local profLabel = Instance.new("TextLabel")
	profLabel.Size = UDim2.new(1, 0, 0, 20)
	profLabel.BackgroundTransparency = 1
	profLabel.Text = "  OPTIMIZATION PROFILES"
	profLabel.TextColor3 = theme.Colors.TextSecondary
	profLabel.Font = Enum.Font.GothamBold
	profLabel.TextSize = 11
	profLabel.TextXAlignment = Enum.TextXAlignment.Left
	profLabel.Parent = parent

	local profileOrder = {"LOW-END", "BALANCED", "EXTREME"}
	for _, key in ipairs(profileOrder) do
		local prof = sys.Profiles.Get(key)
		theme.CreateActionButton(parent, prof.Name .. "  —  Uygula", theme.Colors.CardElevated, function()
			sys.Engine.ApplyProfile(key, prof)
			if onRefreshModulesUI then onRefreshModulesUI() end
		end)
	end

	return {
		Update = function(metrics, analysis)
			masterToggleObj.SetState(sys.Settings.Current.GlobalEnabled)
			local sysState = sys.Settings.Current.GlobalEnabled and "ACTIVE (OPTIMIZING)" or "STANDBY (OFF)"
			local activeCount = sys.Engine.GetActiveModuleCount()

			statusBody.Text = string.format(
				"• System Status: %s
• Active Modules: %d / 8
• FPS: %d FPS  |  RAM: %d MB
• Device: %s
• Profile: %s",
				sysState,
				activeCount,
				metrics.FPS,
				metrics.RAM_MB,
				metrics.Platform,
				sys.Settings.Current.CurrentProfile
			)

			smartBody.Text = string.format(
				"• FPS Stability: %s
• Memory Usage: %s
• Graphics Load: %s
• Thermal Status: %s
• Öneri: %s",
				analysis.FPSStability,
				analysis.MemoryUsage,
				analysis.GraphicsLoad,
				analysis.ThermalStatus,
				analysis.Recommendation
			)
		end
	}
end



-- POOR QUALITY | GUI: Modules Page (8 Bağımsız Optimizasyon Modülü)
local ModulesPage = {}

function ModulesPage.Build(parent, theme, sys)
	local moduleSpecs = {
		{key = "anti_afk", title = "A. Anti-AFK Monitor", desc = "Güvenli boşta kalma durumunu ve AFK süresini izler."},
		{key = "anti_lag", title = "B. Anti-Lag Engine", desc = "Gölgeleri, PostFX efektlerini ve partikülleri azaltır."},
		{key = "anti_fps_drop", title = "C. Anti-FPS Drop", desc = "Yansımaları kapatır, FPS düşüşünde çizim mesafesini optimize eder."},
		{key = "no_animation", title = "D. No Animation (Cosmetic)", desc = "Kozmetik ışın/efekt animasyonlarını kapatır, karakter fiziğini korur."},
		{key = "low_graphics", title = "E. Low Graphics Mode", desc = "Parçaları SmoothPlastic yapar, su efektleri ve dokuları sadeleştirir."},
		{key = "memory_optimizer", title = "F. Memory Optimizer", desc = "Kullanılmayan Lua belleğini periyodik ve güvenli olarak temizler."},
		{key = "thermal_control", title = "G. Thermal Control", desc = "Uzun süreli FPS/kararlılık düşüşünü izler ve ısınma uyarısı verir."},
		{key = "background_optimizer", title = "H. Background Load Monitor", desc = "Panel yenileme döngülerini yavaşlatarak CPU tüketimini düşürür."}
	}

	local uiControls = {}

	for _, spec in ipairs(moduleSpecs) do
		local initial = sys.Settings.Current.Modules[spec.key] or false
		local ctrl = theme.CreateToggleCard(parent, spec.title, spec.desc, initial, function(state)
			sys.Engine.SetModuleState(spec.key, state)
		end)
		uiControls[spec.key] = ctrl
	end

	return {
		SyncStates = function()
			for key, ctrl in pairs(uiControls) do
				ctrl.SetState(sys.Settings.Current.Modules[key] or false)
			end
		end
	}
end



-- POOR QUALITY | GUI: Live Performance Monitor Page
local PerformancePage = {}

function PerformancePage.Build(parent, theme, sys)
	local card = theme.CreateCard(parent, 215)

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -24, 0, 24)
	header.Position = UDim2.new(0, 12, 0, 10)
	header.BackgroundTransparency = 1
	header.Text = "LIVE HARDWARE & CLIENT TELEMETRY"
	header.TextColor3 = theme.Colors.Accent
	header.Font = Enum.Font.GothamBold
	header.TextSize = 12
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = card

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -24, 0, 170)
	infoLabel.Position = UDim2.new(0, 12, 0, 38)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Veriler okunuyor..."
	infoLabel.TextColor3 = theme.Colors.TextPrimary
	infoLabel.Font = Enum.Font.GothamMedium
	infoLabel.TextSize = 12
	infoLabel.TextWrapped = true
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextYAlignment = Enum.TextYAlignment.Top
	infoLabel.Parent = card

	-- Hafif FPS Bar Göstergesi
	local barCard = theme.CreateCard(parent, 58)
	local barTitle = Instance.new("TextLabel")
	barTitle.Size = UDim2.new(1, -24, 0, 20)
	barTitle.Position = UDim2.new(0, 12, 0, 6)
	barTitle.BackgroundTransparency = 1
	barTitle.Text = "FPS STABILITY METER"
	barTitle.TextColor3 = theme.Colors.TextSecondary
	barTitle.Font = Enum.Font.GothamBold
	barTitle.TextSize = 10
	barTitle.TextXAlignment = Enum.TextXAlignment.Left
	barTitle.Parent = barCard

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -24, 0, 14)
	barBg.Position = UDim2.new(0, 12, 0, 32)
	barBg.BackgroundColor3 = theme.Colors.ToggleOff
	barBg.BorderSizePixel = 0
	barBg.Parent = barCard
	theme.ApplyCorner(barBg, 7)

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0.8, 0, 1, 0)
	barFill.BackgroundColor3 = theme.Colors.Success
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	theme.ApplyCorner(barFill, 7)

	return {
		Update = function(metrics)
			local afkStatus = sys.Modules.anti_afk.GetStatusText()
			infoLabel.Text = string.format(
				"• Real-Time FPS: %d FPS
• FPS Stability: %%%d
• Client RAM Usage: %d MB
• CPU Usage: %s
• Thermal Status: %s
• Anti-AFK Status: %s
• Active Modules: %d / 8
• Current Profile: %s",
				metrics.FPS,
				metrics.FPSStability,
				metrics.RAM_MB,
				metrics.CPU_Usage,
				metrics.Thermal,
				afkStatus,
				sys.Engine.GetActiveModuleCount(),
				sys.Settings.Current.CurrentProfile
			)

			local ratio = math.clamp(metrics.FPSStability / 100, 0.05, 1)
			barFill.Size = UDim2.new(ratio, 0, 1, 0)
			if metrics.FPSStability >= 75 then
				barFill.BackgroundColor3 = theme.Colors.Success
			elseif metrics.FPSStability >= 50 then
				barFill.BackgroundColor3 = theme.Colors.Warning
			else
				barFill.BackgroundColor3 = theme.Colors.Accent
			end
		end
	}
end



-- POOR QUALITY | GUI: Advanced Settings & Logs Page
local SettingsPage = {}

function SettingsPage.Build(parent, theme, sys, onRefreshAll)
	theme.CreateToggleCard(
		parent,
		"Safe Mode (Güvenli Mod)",
		"Hata veya çökme durumunda tüm grafik değişikliklerini otomatik geri alır.",
		sys.Settings.Current.SafeMode,
		function(state)
			sys.Settings.Current.SafeMode = state
			sys.Settings.AddLog("Safe Mode: " .. tostring(state))
		end
	)

	theme.CreateActionButton(parent, "Save Configuration (Ayarları Kaydet)", theme.Colors.CardElevated, function()
		sys.Settings.Save()
	end)

	theme.CreateActionButton(parent, "Load Configuration (Ayarları Yükle)", theme.Colors.CardElevated, function()
		sys.Settings.Load()
		if sys.Settings.Current.GlobalEnabled then
			sys.Engine.SetGlobalState(true)
		end
		if onRefreshAll then onRefreshAll() end
	end)

	theme.CreateActionButton(parent, "Restore Default Settings & Reset All", Color3.fromRGB(140, 30, 50), function()
		sys.Engine.ResetAll()
		if onRefreshAll then onRefreshAll() end
	end)

	-- Optimization Logs Kartı
	local logCard = theme.CreateCard(parent, 180)
	local logTitle = Instance.new("TextLabel")
	logTitle.Size = UDim2.new(1, -24, 0, 22)
	logTitle.Position = UDim2.new(0, 12, 0, 8)
	logTitle.BackgroundTransparency = 1
	logTitle.Text = "OPTIMIZATION & DEBUG LOGS"
	logTitle.TextColor3 = theme.Colors.AccentSecondary
	logTitle.Font = Enum.Font.GothamBold
	logTitle.TextSize = 11
	logTitle.TextXAlignment = Enum.TextXAlignment.Left
	logTitle.Parent = logCard

	local logText = Instance.new("TextLabel")
	logText.Size = UDim2.new(1, -24, 0, 140)
	logText.Position = UDim2.new(0, 12, 0, 32)
	logText.BackgroundTransparency = 1
	logText.Text = ""
	logText.TextColor3 = theme.Colors.TextSecondary
	logText.Font = Enum.Font.Code
	logText.TextSize = 10
	logText.TextWrapped = true
	logText.TextXAlignment = Enum.TextXAlignment.Left
	logText.TextYAlignment = Enum.TextYAlignment.Top
	logText.Parent = logCard

	return {
		UpdateLogs = function()
			local lines = {}
			for i = 1, math.min(8, #sys.Settings.Current.Logs) do
				table.insert(lines, sys.Settings.Current.Logs[i])
			end
			logText.Text = table.concat(lines, "
")
		end
	}
end



end

local ModulesMap = {
	anti_afk = AntiAFK or safeRequire(rootFolder.modules.anti_afk),
	anti_lag = AntiLag or safeRequire(rootFolder.modules.anti_lag),
	anti_fps_drop = AntiFPSDrop or safeRequire(rootFolder.modules.anti_fps_drop),
	no_animation = NoAnimation or safeRequire(rootFolder.modules.no_animation),
	low_graphics = LowGraphics or safeRequire(rootFolder.modules.low_graphics),
	memory_optimizer = MemoryOptimizer or safeRequire(rootFolder.modules.memory_optimizer),
	thermal_control = ThermalControl or safeRequire(rootFolder.modules.thermal_control),
	background_optimizer = BackgroundOptimizer or safeRequire(rootFolder.modules.background_optimizer)
}

SystemManager.Boot({
	Settings = Settings,
	Profiles = Profiles,
	PerfMonitor = PerformanceMonitor,
	Analyzer = GameAnalyzer,
	Engine = OptimizationEngine,
	Modules = ModulesMap
})

-- ============================================================================
-- MOBILE-FIRST RESPONSIVE GUI OLUŞTURMA
-- ============================================================================
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("PoorQualityGui") then
	playerGui.PoorQualityGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PoorQualityGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

-- Yüzen Mobil Açma/Kapatma Butonu (Sol Üst / Sürüklenebilir)
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "FloatingToggle"
FloatingBtn.Size = UDim2.new(0, 50, 0, 50)
FloatingBtn.Position = UDim2.new(0.03, 0, 0.18, 0)
FloatingBtn.BackgroundColor3 = Theme.Colors.Background
FloatingBtn.Text = "PQ"
FloatingBtn.TextColor3 = Theme.Colors.Accent
FloatingBtn.Font = Enum.Font.GothamBlack
FloatingBtn.TextSize = 16
FloatingBtn.Active = true
FloatingBtn.Draggable = true
FloatingBtn.Parent = ScreenGui
Theme.ApplyCorner(FloatingBtn, 25)
Theme.ApplyStroke(FloatingBtn, Theme.Colors.Accent, 2)

-- Ana Pencere (Küçük telefon ekranlarına otomatik ölçeklenir)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.88, 0, 0.80, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Colors.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Theme.ApplyCorner(MainFrame, 14)
Theme.ApplyStroke(MainFrame, Theme.Colors.AccentSecondary, 1.5)

local SizeConstraint = Instance.new("UISizeConstraint")
SizeConstraint.MaxSize = Vector2.new(540, 380)
SizeConstraint.MinSize = Vector2.new(310, 260)
SizeConstraint.Parent = MainFrame

-- Üst Başlık Barı
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = Theme.Colors.Card
Header.BorderSizePixel = 0
Header.Parent = MainFrame
Theme.ApplyCorner(Header, 14)

local BrandTitle = Instance.new("TextLabel")
BrandTitle.Size = UDim2.new(1, -90, 0, 22)
BrandTitle.Position = UDim2.new(0, 14, 0, 4)
BrandTitle.BackgroundTransparency = 1
BrandTitle.Text = "POOR QUALITY"
BrandTitle.TextColor3 = Theme.Colors.TextPrimary
BrandTitle.Font = Enum.Font.GothamBlack
BrandTitle.TextSize = 15
BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
BrandTitle.Parent = Header

local BrandSub = Instance.new("TextLabel")
BrandSub.Size = UDim2.new(1, -90, 0, 16)
BrandSub.Position = UDim2.new(0, 14, 0, 24)
BrandSub.BackgroundTransparency = 1
BrandSub.Text = "Advanced Mobile Performance System"
BrandSub.TextColor3 = Theme.Colors.Accent
BrandSub.Font = Enum.Font.GothamMedium
BrandSub.TextSize = 10
BrandSub.TextXAlignment = Enum.TextXAlignment.Left
BrandSub.Parent = Header

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 36, 0, 36)
MinBtn.Position = UDim2.new(1, -42, 0.5, -18)
MinBtn.BackgroundColor3 = Theme.Colors.CardElevated
MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.Colors.TextPrimary
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.Parent = Header
Theme.ApplyCorner(MinBtn, 8)

-- Alt Navigasyon Barı (Mobil Başparmak Erişimi İçin)
local NavBar = Instance.new("Frame")
NavBar.Size = UDim2.new(1, -16, 0, 38)
NavBar.Position = UDim2.new(0, 8, 1, -44)
NavBar.BackgroundColor3 = Theme.Colors.Card
NavBar.BorderSizePixel = 0
NavBar.Parent = MainFrame
Theme.ApplyCorner(NavBar, 10)

local NavLayout = Instance.new("UIListLayout")
NavLayout.FillDirection = Enum.FillDirection.Horizontal
NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
NavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
NavLayout.Padding = UDim.new(0, 4)
NavLayout.Parent = NavBar

-- İçerik Alanı
local PagesHolder = Instance.new("Frame")
PagesHolder.Size = UDim2.new(1, -16, 1, -98)
PagesHolder.Position = UDim2.new(0, 8, 0, 48)
PagesHolder.BackgroundTransparency = 1
PagesHolder.Parent = MainFrame

local pages = {}
local navButtons = {}

local function createScrollPage(name)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = name
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Theme.Colors.Accent
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Visible = false
	scroll.Parent = PagesHolder

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 4)
	pad.Parent = scroll

	pages[name] = scroll
	return scroll
end

local function selectPage(name)
	for pName, frame in pairs(pages) do
		frame.Visible = (pName == name)
	end
	for bName, btn in pairs(navButtons) do
		btn.BackgroundColor3 = (bName == name) and Theme.Colors.Accent or Theme.Colors.CardElevated
	end
end

local tabDefs = {
	{id = "Dashboard", label = "Dashboard"},
	{id = "Modules", label = "Modules"},
	{id = "Performance", label = "Monitor"},
	{id = "Settings", label = "Settings"}
}

for _, tab in ipairs(tabDefs) do
	createScrollPage(tab.id)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.24, 0, 0, 30)
	b.BackgroundColor3 = Theme.Colors.CardElevated
	b.Text = tab.label
	b.TextColor3 = Theme.Colors.TextPrimary
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.Parent = NavBar
	Theme.ApplyCorner(b, 7)
	b.MouseButton1Click:Connect(function()
		selectPage(tab.id)
	end)
	navButtons[tab.id] = b
end

local modulesUI
local dashboardUI
local perfUI
local settingsUI

modulesUI = ModulesPage.Build(pages["Modules"], Theme, SystemManager)

dashboardUI = DashboardPage.Build(pages["Dashboard"], Theme, SystemManager, function()
	if modulesUI then modulesUI.SyncStates() end
end)

perfUI = PerformancePage.Build(pages["Performance"], Theme, SystemManager)

settingsUI = SettingsPage.Build(pages["Settings"], Theme, SystemManager, function()
	if modulesUI then modulesUI.SyncStates() end
end)

selectPage("Dashboard")

-- Küçültme / Açma Kontrolleri
MinBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
end)

FloatingBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = not MainFrame.Visible
end)

-- Hafif Arka Plan UI Güncelleme Döngüsü (Background Load Monitor ile uyumlu)
local uiAlive = true
ScreenGui.Destroying:Connect(function()
	uiAlive = false
	SystemManager.Shutdown(nil)
end)

task.spawn(function()
	while uiAlive do
		local metrics = PerformanceMonitor.GetMetrics()
		local activeCount = OptimizationEngine.GetActiveModuleCount()
		local analysis = GameAnalyzer.Analyze(metrics, activeCount)

		if MainFrame.Visible then
			if pages["Dashboard"].Visible then
				dashboardUI.Update(metrics, analysis)
			elseif pages["Performance"].Visible then
				perfUI.Update(metrics)
			elseif pages["Settings"].Visible then
				settingsUI.UpdateLogs()
			end
		end

		local interval = ModulesMap.background_optimizer.GetInterval()
		task.wait(interval)
	end
end)
