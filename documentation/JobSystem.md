# Job System Guide

Players get jobs from NPCs in `Workspace.JobNPCs`. Each NPC uses a ProximityPrompt named `JobProximity` with a `JobGroup` attribute. That group name must match a group in `JobOptions` (JobService). Talking to the NPC picks a random job from that group.

## Folder layout in Workspace

**Workspace.JobNPCs**  
Put all job NPCs here (models, parts, prompts). The game only looks in this folder.

**Workspace.JobLocations**  
Put stand and tool-work zones here. Each zone is a Part (it can be invisible). The part's Name is what you type in `Location` in JobOptions.

**Haul drop-off and pickup parts**  
Part names in a haul job (`PartA` / `PartB`) are searched in Workspace first. If they are not sitting directly under Workspace, put them in JobLocations instead and use that same name.

## Setting up an NPC

1. Put the NPC model in `Workspace.JobNPCs`.
2. Add a ProximityPrompt. Name it exactly `JobProximity`.
3. On that prompt, add an Attribute:
   - Name: `JobGroup`
   - Type: String
   - Value: the group name, for example `Standing`, `Mail`, `ToolWork`, or `Kills`
4. The value must match a group in JobOptions exactly. Capital letters matter.

**One NPC, random jobs from a pool**  
Set `JobGroup` to `Mail`. Add several haul jobs inside `JobOptions.Mail`. The NPC will pick one at random.

**One NPC, one specific job**  
Make a new group in JobOptions with only that one job, then set the NPC's `JobGroup` to that new name.

```lua
JobOptions.PostOfficeCrate = {
    {
        Type = "Haul",
        -- rest of the job
    },
}
```

NPC `JobGroup` = `PostOfficeCrate`

## Editing jobs (JobOptions)

Open `JobService > JobOptions`. Each group is a list of jobs in curly braces. Copy an existing job block and change the numbers and names.

### Fields on every job

**Type**  
Which kind of job this is. Must be one of: `StandZone`, `ToolZone`, `Haul`, `GetKills`.

**Payout**  
Money given when the job is finished (Greenbacks).

**Progress**  
Almost always `0`. This is the starting progress.

**FinishedProgress**  
How far they need to go to finish.

- StandZone and ToolZone: time in seconds (`300` = 5 minutes).
- GetKills: number of kills needed.
- Haul: usually `1` (deliver once).

**JobDescription**  
Text shown on the player's job HUD.

**ProgressDivisor** (optional)  
Only affects the HUD numbers, not the real job. Example: `FinishedProgress = 300` and `ProgressDivisor = 60` shows `0/5` instead of `0/300` (minutes instead of seconds). Leave this out if you want the raw numbers.

**ExtraData**  
Settings that depend on Type. See each job type below.

## Stand Zone (`Type = "StandZone"`)

The player stands inside a zone until the timer fills.

In Workspace, under JobLocations, add a Part named whatever you put in `Location`. Make the part big enough to stand in. It can be invisible (`Transparency` 1, `CanCollide` off). `CanCollide` can stay on if you want a platform.

```lua
ExtraData = {
    Location = "TestLocation", -- must match the Part's Name in JobLocations
}
```

Example group: `JobOptions.Standing`

## Tool Zone (`Type = "ToolZone"`)

The player must be in the zone and holding a tool they already own. This job does not give them the tool. They need it in their backpack (shop purchase, starter pack, and so on).

The zone is the same as StandZone: `JobLocations` > Part named `Location`.

```lua
ExtraData = {
    Location = "TestLocation",
    Tool = "JobShovel", -- exact Tool name, including capitals
}
```

Example group: `JobOptions.ToolWork`

## Haul (`Type = "Haul"`)

Gives the player a tool (crate, bag, and so on). They carry it to a drop-off and use the drop-off prompt while the tool is equipped.

**Tool template**  
Put a Tool as a child of the Haul module (`JobService > Haul`). The Tool's Name is `ToolName` in ExtraData. The game clones that tool.

**Drop-off part (PartB)**  
A Part named in `ExtraData.PartB`, under Workspace or JobLocations. That part must have a ProximityPrompt named exactly `HaulJob`. The player must have the haul tool equipped when they trigger it.

**Pickup name (PartA)**  
Optional. NPCs start the job, so this is not required to begin. Keep the name if you still use that part as a visual pickup spot. The name is looked up in Workspace the same way as PartB.

```lua
ExtraData = {
    PartA = "HaulJobStart", -- Workspace or JobLocations part name
    PartB = "HaulJobEnd", -- drop-off part name (required)
    ToolName = "Crate", -- Tool under the Haul module
    WalkSpeed = 8, -- speed while carrying (optional)
    StrictCarrying = true, -- unequipping destroys the tool and cancels the job
}
```

If `StrictCarrying` is false, they can put the tool in the backpack and the job stays until they deliver or leave.

Example group: `JobOptions.Mail`

## Get Kills (`Type = "GetKills"`)

Counts kills after the job starts using the player's `Kills` attribute. Your combat system must set the player attribute `Kills` to a number.

`ExtraData` can be empty: `ExtraData = {}`

`FinishedProgress` is how many new kills they need (for example `2`).

Example group: `JobOptions.Kills`

## HUD

Jobs show under the ActiveJobs GUI. Green means they are currently doing the job (in the zone, holding the crate, and so on). Grey means the job is assigned but not active right now. The HUD goes away when the job finishes or is cancelled.

## Quick recipe: new standing NPC with its own job

1. Duplicate a zone Part in JobLocations. Rename it, for example `DocksStand`.
2. In JobOptions add:

```lua
JobOptions.DocksStand = {
    {
        Type = "StandZone",
        Payout = 1,
        Progress = 0,
        FinishedProgress = 180,
        JobDescription = "Stand at the docks",
        ProgressDivisor = 60,
        ExtraData = {
            Location = "DocksStand",
        },
    },
}
```

3. Put the NPC in JobNPCs, with a prompt named `JobProximity` and attribute `JobGroup` = `DocksStand`.

## If something does not work

- `JobGroup` spelling must match the JobOptions group name.
- `JobProximity` must be a ProximityPrompt with that exact name.
- `Location` and `PartB` names must match the Part's Name.
- Stand and tool zones live in `Workspace.JobLocations` and must be Parts.
- The haul drop-off prompt must be named `HaulJob`.
- Haul tools live under the Haul module, not in the NPC.
- ToolZone tools must already be in the player's inventory.
- Output window warnings from JobOptions, Haul, or StandZone usually name the missing part or attribute.
