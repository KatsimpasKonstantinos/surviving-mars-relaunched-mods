local max_limit = 80000000000
local min_limit = -80000000000
local interest_rate = 1

local function UpdateInterestRate()
    local options = CurrentModOptions
    if not options then
        print("CurrentModOptions is nil - keeping default interest rate")
        interest_rate = 1
        return
    end
    local interestrate_number = tonumber(options.Interestrate)
    if interestrate_number == nil then
        print("ERROR: Interestrate could not be converted to a number")
        interest_rate = 1
        return
    end
    
    interest_rate = interestrate_number
end

FundingSourceTexts = FundingSourceTexts or {}
FundingSourceTexts.DailyInterest = T(
    302535920011500,
    "Daily Interest"
)

local function CheckLimit(colony)
    if not colony or not colony.funds then
        return
    end
    local current_funding = colony.funds.funding
    if current_funding > max_limit then
        colony.funds:ChangeFunding(max_limit - current_funding)
    elseif current_funding < min_limit then
        colony.funds:ChangeFunding(min_limit - current_funding)
    end
end


PlaceObj('NotificationPreset', {
    CanAddNotification = function (self, ...) return not GameState.Tutorial end,
    Expiration = 60000,
    FxAction = "UINotificationFunding",
    GameTime = false,
    Image = "UI/IconsRemaster/Notifications/funding.png",
    RightTitle = T(
        604752595099,
        "<funding(sum(0,'number',objects))>"
    ),
    Title = T(
        302535920011336,
        "Daily Interest"
    ),
    group = "Default",
    id = "DailyInterest",
})
PlaceObj('NotificationPreset', {
    CanAddNotification = function (self, ...) return not GameState.Tutorial end,
    Expiration = 60000,
    FxAction = "UINotificationFunding",
    GameTime = false,
    Image = "UI/IconsRemaster/Notifications/funding.png",
    RightTitle = T(
        604752595099,
        "<funding(-sum(0,'number',objects))>"
    ),
    Title = T(
        302535920011337,
        "Debt Overdraft"
    ),
    group = "Default",
    id = "FundingLost",
})

local function AddInterest(colony)
    if not colony or not colony.funds then
        return
    end

    local current_funding = colony.funds.funding
    local actual_interest = MulDivRound(
        current_funding,
        interest_rate,
        100
    )
    
    if actual_interest == 0 then
        return
    end

    colony.funds:ChangeFunding(actual_interest)
    
    actual_interest = colony.funds.funding - current_funding

    if actual_interest > 0 then
        colony.funds.funding_gain_sol =
            colony.funds.funding_gain_sol or {}
        colony.funds.funding_gain_sol.DailyInterest =
            (colony.funds.funding_gain_sol.DailyInterest or 0)
            + actual_interest
    end
    local display_interest = MulDivRound(math.abs(actual_interest), 1, 1000000)

    if actual_interest > 0 then
        AddObjectToNotification({
            number = actual_interest,
            funds = actual_interest,
            ItemText = T{
                302535920011384,
                "You've received: <amount> M",
                amount = display_interest
            },
            amount = display_interest,
        }, nil, "DailyInterest")
    else
        AddObjectToNotification({
            number = math.abs(actual_interest),
            funds = actual_interest,
            ItemText = T{
                812499102342,
                "Interest charged: <amount> M",
                amount = display_interest
            },
            amount = display_interest,
        }, nil, "FundingLost")
    end
end

function OnMsg.NewDay()
    if not UIColony or not UIColony.funds then
        return
    end
    
    if UICity.day <= 1 then
        return
    end
    AddInterest(UIColony)
    CheckLimit(UIColony)
end

function OnMsg.ApplyModOptions(id)
    UpdateInterestRate()
end

function OnMsg.CityStart()
    UpdateInterestRate()
    if UIColony and UIColony.funds then
        CheckLimit(UIColony)
    end
end

function OnMsg.LoadGame()
    UpdateInterestRate()
    if UIColony and UIColony.funds then
        CheckLimit(UIColony)
    end
end
