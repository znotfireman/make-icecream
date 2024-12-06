local Player = game:GetService("Players").LocalPlayer
local StarterGui = game:GetService("StarterGui")
local Main = Player.PlayerGui:WaitForChild("Main")
local TweenService = game:GetService("TweenService")

local Counter = Main:WaitForChild("Counter")
local Topbar = Main:WaitForChild("HideTopbar")
local Check = Counter:WaitForChild("Counter") --> serve and discard
local Scoops = Counter:WaitForChild("Scoops") --> ice cream flavors
local Toppings = Counter:WaitForChild("Toppings") --> toppings for ice cream

local Black = Main:WaitForChild("Black") --> nightime shifts

local Background = Main:WaitForChild("Background")
local Person = Background:WaitForChild("TemplatePerson") --> person to serve
local Dialogue = Background:WaitForChild("Dialogue") --> dialogue duh

local Serve = Check:WaitForChild("dServe")
local Discard = Check:WaitForChild("eDiscard")
local Failures = Check:WaitForChild("fFailures")

local Cup = Check:WaitForChild("Cup")
local CupContainer = Cup:WaitForChild("Container")
local Scoop = CupContainer:WaitForChild("Scoop")
local Topping = CupContainer:WaitForChild("Topping")

local Shift = 1 --> shift number
local People = 3 + Shift --> amount of people to serve for this shift
local TimeToMake = 10 --> duration to make icecream
local FailedOrders = 0

local SkipDialogue = false --> for debug purposes
local LastUsedFlavor = "None"

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) --> Bye!

-- Preparation
function ClearCup()
	for IndexContents, ValueContents in pairs(CupContainer:GetChildren()) do --> clean up old icecream
		local DontDelete = ValueContents:FindFirstChild("DontDelete")
		if not DontDelete then
			ValueContents:Destroy()
		end
	end
end

local TweenPerson = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)

local TweenNight = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true, 0)

-- Intro
function DisplayDialogue(Text, Duration) --> displays dialogue text
	if SkipDialogue then
		return
	end
	Dialogue.Text = Text
	Dialogue.Visible = true

	task.wait(Duration)

	Dialogue.Visible = false
end

---- Greetings
DisplayDialogue("Welcome employee! You will be tasked on serving icecream.", 3)
DisplayDialogue("Let's begin with a tour of your workspace.", 3)

-- Game mechanics
DisplayDialogue("On the left side is the counter, this is where you will serve your icecream.", 4)
DisplayDialogue("In the middle is the scoops, where you scoop the icecream flavor.", 4)
DisplayDialogue("Finally, at the right is the toppings, where you add toppings onto your icecream if required.", 5)
DisplayDialogue("If you have 2 failed orders during your shift, you will be fired.", 4)

DisplayDialogue("Goodluck and happy birthday!", 4)
task.wait(3)

-- Game loop
while FailedOrders < 2 do
	DisplayDialogue("Shift " .. tostring(Shift) .. ", " .. tostring(People) .. " customers", 2)
	FailedOrders = 0
	Failures.Text = string.format("You have %d/2 failures during this shift.", FailedOrders)

	local Index = 1
	while Index < People do
		-- Ice Cream generation
		local Flavors = {
			Scoops:WaitForChild("Chocolate"),
			Scoops:WaitForChild("Strawberry"),
			Scoops:WaitForChild("Vanilla"),
			Scoops:WaitForChild("Cookies"),
		}

		local Toppings = {
			Toppings:WaitForChild("Chips"),
			Toppings:WaitForChild("Gummies"),
			Toppings:WaitForChild("Sprinkles"),
			Toppings:WaitForChild("Oreo"),
		}

		local WillUseToppings = math.random(1, 2) --> 50% of an order requiring a topping

		local FlavorToUse = Flavors[math.random(#Flavors)]
		local ToppingToUse

		if WillUseToppings == 1 then --> we will need a topping for this order
			WillUseToppings = true --> converts it to a bool for later use
			ToppingToUse = Toppings[math.random(#Toppings)]
		else --> we do not need a topping for this order
			WillUseToppings = false
			ToppingToUse = "No Topping"
		end

		-- Deliver message to person
		local Text = "Hello! I would like a " .. FlavorToUse:WaitForChild("Label").Text .. " cup"
		if WillUseToppings then
			Text = Text .. ", with the " .. ToppingToUse:WaitForChild("Label").Text .. " topping"
		end
		Text = Text .. ". Thank you! (You have %d seconds to make the icecream.)"

		local NewPerson = Person:Clone()
		NewPerson.Parent = Background
		NewPerson.Name = "Person" .. tostring(Index) --> to not confuse people with template

		-- Tweens
		local TweenEnter = TweenService:Create(NewPerson, TweenPerson, { Position = UDim2.new(0.5, 0, 0.1, 0) })
		local TweenExit = TweenService:Create(NewPerson, TweenPerson, { Position = UDim2.new(1.25, 0, 0.1, 0) })

		NewPerson.Visible = true
		TweenEnter:Play()
		TweenEnter.Completed:Wait()

		task.wait(1)

		NewPerson:WaitForChild("Dialogue").Text = string.format(Text, TimeToMake)
		NewPerson:WaitForChild("Dialogue").Visible = true

		-- Player makes ice cream + countdown
		local ConnectionFlavors = {}
		local ConnectionToppings = {}
		local FlavorUsing = nil
		local ToppingUsing = nil

		local Debounce = false

		local Countdown = TimeToMake

		ClearCup()
		Serve.MouseButton1Click:Connect(function()
			Countdown = 0
		end)

		while Countdown > 0 do
			NewPerson:WaitForChild("Dialogue").Text = string.format(Text, Countdown)
			task.wait(1)
			Countdown = Countdown - 1

			Discard.MouseButton1Click:Connect(function()
				ClearCup()
				FlavorUsing = nil
				ToppingUsing = nil
			end)

			-- Flavors
			for IndexFlavors, ValueFlavors in Flavors do
				ConnectionFlavors[IndexFlavors] = ValueFlavors.MouseButton1Click:Connect(function()
					if Debounce then
						task.wait(0.2)
						Debounce = false
						return
					end
					Debounce = true

					if FlavorUsing ~= nil then
						return
					end
					FlavorUsing = ValueFlavors

					local NewScoop = Scoop:Clone() --> new scoop to add
					NewScoop.Parent = CupContainer
					NewScoop.BackgroundColor3 = ValueFlavors.BackgroundColor3
					NewScoop.Visible = true

					NewScoop:WaitForChild("DontDelete"):Destroy()
				end)
			end

			-- Toppings
			for IndexToppings, ValueToppings in Toppings do
				ConnectionToppings[IndexToppings] = ValueToppings.MouseButton1Click:Connect(function()
					if Debounce then
						task.wait(0.2)
						Debounce = false
						return
					end
					Debounce = true

					if ToppingUsing ~= nil then
						return
					end
					ToppingUsing = ValueToppings

					local NewTopping = Topping:Clone() --> new topping to add
					NewTopping.Parent = CupContainer
					NewTopping.BackgroundColor3 = ValueToppings.BackgroundColor3
					NewTopping.Visible = true

					NewTopping:WaitForChild("DontDelete"):Destroy()
				end)
			end
		end

		-- Check if ice cream matches order
		local Fail = false
		if FlavorUsing == FlavorToUse then --> first check
			if ToppingUsing == nil then --> prevent any heaches by converting ToppingUsing
				ToppingUsing = "No Topping"
			end

			if ToppingUsing ~= ToppingToUse then --> second check
				FailedOrders = FailedOrders + 1
				NewPerson.Text = ":("
			end
		else
			FailedOrders = FailedOrders + 1
			NewPerson.Text = ":("
		end

		-- If fail, update fail count
		Failures.Text = string.format("You have %d/2 failures during this shift.", FailedOrders)
		if FailedOrders >= 2 then
			NewPerson.Text = ":("

			Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Topbar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Counter.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			Dialogue.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			Dialogue.TextColor3 = Color3.fromRGB(100, 100, 100)
			Cup.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			NewPerson.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			Failures.TextColor3 = Color3.fromRGB(255, 0, 0)
			NewPerson.TextColor3 = Color3.fromRGB(255, 0, 0)
			break
		end

		NewPerson:WaitForChild("Dialogue").Visible = false --> prevents the person talking if we served instead of waited
		TweenExit:Play()
		TweenExit.Completed:Wait()

		task.wait(1)
		NewPerson:Destroy()

		Index = Index + 1
		task.wait(2)
	end

	-- If it is end of the shift, buff the next shift
	Shift = Shift + 1
	People = 3 + Shift

	if Shift % 5 == 0 then --> difficulty
		TimeToMake = TimeToMake - 1
	end

	-- jet lag the game nightime thing
	if FailedOrders < 2 then
		local Tween = TweenService:Create(Black, TweenNight, { Size = UDim2.new(20, 0, 20, 0) })
		Tween:Play()
		Tween.Completed:Wait()

		Black.Size = UDim2.new(0, 0, 0, 0)
	end
	task.wait(1)
end

DisplayDialogue("You have failed your shift. Goodbye.", 4)
Player:Kick("You have failed your shift. Goodbye. (Score: " .. Shift .. ")")
