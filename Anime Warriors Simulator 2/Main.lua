if not syn then
	syn = {}
	
	syn.protect_gui = function(a)
		return 0; -- makes ui compatible with other exploits (too lazy to remove it in the gui code)
	end
end

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local function FireButton(btn)
	for i,v in pairs(getconnections(btn.Activated)) do
		v.Function()
	end
end

local function SigButton(btn)
	for i,v in pairs(getconnections(btn.Activated)) do
		v.Fire()
	end
end

function GetWorlds()
    local Worlds = {}
    for i,v in ipairs(game.Workspace.Maps:GetChildren()) do
        if not table.find(Worlds, v.Name) then
            table.insert(Worlds, v.Name)
        end
    end
    return Worlds
end

function GetWorldEnemies(World)
    local Enemies = {}
    for i,v in ipairs(game.ReplicatedStorage.Enemies[World]:GetChildren()) do
        if not table.find(Enemies, v.Name) then
            table.insert(Enemies, v.Name)
        end
    end
    return Enemies
end

function OverrideWarriorWalk()
    local RS = game:GetService("ReplicatedStorage")
    local Knit = require(RS.Packages.Knit)
    local Client = game:GetService("Players").LocalPlayer
    local Warrior = require(Client.PlayerScripts.Client.Modules.Classes.Warrior)
    Warrior.Walk = function(self,Position,...)
        self.Instance:PivotTo(CFrame.new(Position))
        if self:GetValue("Enemy") then
            Knit.GetController("EnemyController"):StartWarriorRuntime(self._data.Hash);
        end
    end
end

local Modifiers = {
    'Tiny',
    'Giant',
    'Shiny',
}

function EnemyNameCheck(Enemy)
    local Root = Enemy:FindFirstChild('HumanoidRootPart')
    local HealthBar = Root:FindFirstChild('EnemyHealthBar')
    local Title = HealthBar.Title

    if shared.AcceptModifiers then
        for i,v in pairs(Modifiers) do
             if string.find(Title.Text, ' ') then
                 local Split = string.split(Title.Text, ' ')
                 if Split[1] == v and Split[2] == shared.EnemyToTarget then
                    return true
                 end
             end
        end
     end

    if shared.NameCheckType == 'Loose' then
        if string.match(Title.Text, shared.EnemyToTarget) then
            return true
        end
    elseif shared.NameCheckType == 'Strict' then
        if Title.Text == shared.EnemyToTarget then
            return true
        end
    end

    return false
end

function GetClosestEnemy()
    local TABLE = {Enemy = nil, Distance = math.huge}
    for i,v in ipairs(game.Workspace.ClientEnemies:GetChildren()) do
        if #game.Workspace.ClientEnemies:GetChildren() > 0 and v and v.HumanoidRootPart:FindFirstChild('EnemyHealthBar') then
            if --[[v.HumanoidRootPart.EnemyHealthBar.Title.Text == shared.EnemyToTarget]] EnemyNameCheck(v) then
                local Distance = (game.Players.LocalPlayer.Character.PrimaryPart.Position - v.PrimaryPart.Position).Magnitude
                if Distance < TABLE.Distance then
                    TABLE.Distance = Distance
                    TABLE.Enemy = v
                end
            end
        end
    end
    return TABLE
end

shared.WorldGoTo = nil
shared.EnemyWorld = nil
shared.EnemyToTarget = nil
shared.CurrentEnemy = nil
shared.AutoDrops = false
shared.AutoAttack = false
shared.AcceptModifiers = false
shared.NameCheckType = 'Strict'

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/notarchs/public/main/Anime%20Warriors%20Simulator%202/UI.lua", true))()

local main = Library:CreateWindow("awesome script")

local Teleports = main:AddFolder('Teleports')
Teleports:AddList({text = 'World: ', values = GetWorlds(), callback = function(v) shared.WorldGoTo = v end})
Teleports:AddButton({text = 'Teleport', callback = function() if shared.WorldGoTo then game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Maps[shared.WorldGoTo].Fountain:GetPivot() + Vector3.new(0,10,0) end end})

local Exploits = main:AddFolder('Exploits')
Exploits:AddButton({text = 'Instant Warrior TP', callback = function() OverrideWarriorWalk() end})

local Farms = main:AddFolder('Farms')
Farms:AddBox({text = 'Enemy Name: ', callback = function(v) shared.EnemyToTarget = v end})
Farms:AddList({text = 'Name Check: ', values = {'Strict', 'Loose'}, callback = function(v) shared.NameCheckType = v end})
Farms:AddToggle({text = 'Accept Enemy Modifiers', callback = function(v) shared.AcceptModifiers = v end})
Farms:AddToggle({text = 'Auto Collect Drops', callback = function(v) shared.AutoDrops = v end})
Farms:AddToggle({text = 'Auto Attack Enemy', callback = function(v) shared.AutoAttack = v end})

Library:Init()

task.spawn(function()
    game.Workspace.Drops.ChildAdded:Connect(function(CHILD)
        if shared.AutoDrops then
            game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.4.7"].knit.Services.DropService.RE.CollectDrop:FireServer(CHILD.Name)
        end
    end)
end)

task.spawn(function()
    while task.wait() do
        if shared.AutoAttack then
            if shared.CurrentEnemy == nil then
                local Enemy = GetClosestEnemy()
                if Enemy.Enemy ~= nil then
                    game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.4.7"].knit.Services.EnemyService.RE.AttackEnemy:FireServer(Enemy.Enemy.Name)
                    shared.CurrentEnemy = Enemy.Enemy.Name
                end
            end
        end
    end
end)

task.spawn(function()
    game.Workspace.ClientEnemies.ChildRemoved:Connect(function(CHILD)
        if CHILD.Name == shared.CurrentEnemy then
            shared.CurrentEnemy = nil
        end
    end)    
end)
