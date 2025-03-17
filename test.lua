local LuxField = loadstring(game:HttpGet("https://raw.githubusercontent.com/DeinGitHubName/DeinRepo/main/LuxField.lua"))()

local Window = LuxField:CreateWindow({
   Name = "Mein Cooles Modernes UI",
   Icon = 0,             -- oder "rewind" (String) / Roblox-Asset-ID
   LoadingTitle = "Lade UI...",
   LoadingSubtitle = "Bitte warten...",
   Theme = "Default"     -- oder "Dark", "Light", ...
})

-- Tab anlegen:
local Tab = Window:CreateTab("Beispiel-Tab", 4483362458)
Tab:Show()  -- Damit das Tab direkt sichtbar ist

-- Label
local Label = Tab:CreateLabel("Hallo Welt!")
Label:Set("Neuer Label-Text")

-- Button
local Button = Tab:CreateButton({
   Name = "Klick mich",
   Callback = function()
      print("Button geklickt!")
      Window:Notify({
          Title = "Info",
          Content = "Du hast den Button geklickt!",
          Duration = 3
      })
   end
})

-- Toggle
local ToggleObj = Tab:CreateToggle({
   Name = "Sound an/aus",
   CurrentValue = false,
   Callback = function(newValue)
       print("Toggle-Status:", newValue)
   end
})

-- Slider
local SliderObj = Tab:CreateSlider({
   Name = "Lautstärke",
   Range = {0,100},
   Increment = 5,
   CurrentValue = 50,
   Suffix = "%",
   Callback = function(value)
      print("Lautstärke:", value, "%")
   end
})

-- Input
local InputObj = Tab:CreateInput({
    Name = "Spielername",
    PlaceholderText = "Bitte Name eingeben...",
    Callback = function(text)
        print("Eingegebener Text:", text)
    end
})

-- Color Picker
local Picker = Tab:CreateColorPicker({
   Name = "Farbe auswählen",
   Color = Color3.new(1, 0, 0),
   Callback = function(col)
       print("Neue Farbe:", col)
   end
})

-- Dropdown
local DropdownObj = Tab:CreateDropdown({
   Name = "Auswahl",
   Options = {"Erster", "Zweiter", "Dritter"},
   CurrentOption = {"Erster"},
   MultipleOptions = false,
   Callback = function(sel)
      print("Dropdown gewählt:", table.concat(sel, ", "))
   end
})

-- Benachrichtigung (Test)
Window:Notify({
   Title = "Willkommen",
   Content = "Dieses moderne UI hat geladen!",
   Duration = 5
})
