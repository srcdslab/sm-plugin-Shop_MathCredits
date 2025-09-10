# Copilot Instructions for sm-plugin-Shop_MathCredits

## Repository Overview

This repository contains a SourcePawn plugin for SourceMod called "Shop_MathCredits". The plugin creates mathematical questions that players can answer to earn shop credits in Source engine games. It integrates with the Shop-Core system and provides multilingual support.

### Key Features
- Automatically generates mathematical questions (addition, subtraction, multiplication, division)
- Awards configurable shop credits for correct answers
- Configurable timing and difficulty settings
- Multilingual support (English/Russian)
- Sound effects for winners
- Integration with external Shop system

## Technical Environment

### Core Technologies
- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11.0+ (minimum)
- **Build System**: SourceKnight 0.2
- **Compiler**: SourcePawn compiler (spcomp) via SourceKnight

### Dependencies
- **SourceMod**: Core framework (version 1.11.0-git6934)
- **MultiColors**: Colored chat functionality (GitHub: srcdslab/sm-plugin-MultiColors)
- **Shop-Core**: Credit system integration (GitHub: srcdslab/sm-plugin-Shop-Core)

## Project Structure

```
addons/sourcemod/
├── scripting/
│   └── Shop_MathCredits.sp          # Main plugin source
├── translations/
│   └── shop_mathcredits.phrases.txt # Language strings
common/
└── sound/shop/
    └── Applause.mp3                 # Winner sound effect
sourceknight.yaml                    # Build configuration
.github/workflows/ci.yml             # CI/CD pipeline
```

## Build & Development Workflow

### Prerequisites
- SourceKnight build system installed
- Dependencies are automatically downloaded during build

### Building the Plugin
```bash
# The build process is automated via SourceKnight
# CI runs: uses: maxime1907/action-sourceknight@v1 with cmd: build

# Local development would use:
sourceknight build
```

### Output
- Compiled plugin: `addons/sourcemod/plugins/Shop_MathCredits.smx`
- Package includes translations and sound files

## Code Style & Standards

### Formatting
- **Indentation**: Tabs (4 spaces equivalent)
- **Variables**: camelCase for local variables, PascalCase for functions
- **Global variables**: Prefix with "g_" (though current code uses direct naming)
- **Constants**: UPPERCASE with underscores

### SourcePawn Specific
- Always use `#pragma newdecls required`
- Always use `#pragma semicolon 1`
- Use `delete` for cleanup without null checks
- Use translation files for all user-facing text
- Handle timer cleanup properly

### Current Code Patterns
The existing code follows these patterns:
- ConVar-based configuration with change hooks
- Timer-based event scheduling
- Translation system integration
- Proper memory management with timers

## Working with This Codebase

### Key Components

#### 1. Configuration System
```sourcepawn
// ConVars are created in OnPluginStart() with change hooks
ConVar cvar = CreateConVar("sm_MathCredits_minimum_number", "1", "Minimum number in math question.");
HookConVarChange(cvar, CVAR_MinimumNumber);
```

All configuration variables:
- `sm_MathCredits_minimum_number`: Minimum number in questions (default: 1)
- `sm_MathCredits_maximum_number`: Maximum number in questions (default: 100)
- `sm_MathCredits_minimum_credits`: Min credits awarded (default: 5, min: 1)
- `sm_MathCredits_maximum_credits`: Max credits awarded (default: 100, min: 1)
- `sm_MathCredits_time_answer_questions`: Answer timeout in seconds (default: 15, min: 5)
- `sm_MathCredits_time_minamid_questions`: Min time between questions (default: 100, min: 5)
- `sm_MathCredits_time_maxamid_questions`: Max time between questions (default: 250, min: 10)

#### 2. Question Generation Logic
Located in `CreateQuestion()` function:
- Randomly selects operators from: `{"+", "-", "/", "*"}`
- Generates appropriate numbers based on operator
- **Division special handling**: `nbr1 = GetRandomInt(nbrmin/nbr2, nbrmax/nbr2) * nbr2` ensures whole results
- Uses ternary operators for calculation: `strcmp(op, PLUS) ? strcmp(op, MINUS) ? nbr1 * nbr2:nbr1 - nbr2:nbr1 + nbr2`

#### 3. Translation Integration
```sourcepawn
LoadTranslations("shop_mathcredits.phrases");
CPrintToChat(i, "%t", "MathQuestion", nbr1, op, nbr2, credits);
```

Translation phrases:
- `"MathQuestion"`: Question format with 4 parameters (num1, operator, num2, credits)
- `"Winner"`: Winner announcement with 2 parameters (player name, credits)
- `"NoAnswer"`: Timeout message (no parameters)

#### 4. Timer Management
- `timerQuestionEnd`: Handle for answer timeout timer
- Question scheduling: `CreateTimer(GetRandomFloat(minquestion, maxquestion), CreateQuestion)`
- Answer timeout: `CreateTimer(timeanswer, EndQuestion)`
- Always uses `TIMER_FLAG_NO_MAPCHANGE` to prevent map change issues
- Proper cleanup: `delete timerQuestionEnd` sets handle to null

#### 5. Answer Detection System
Uses `OnClientSayCommand_Post()` hook:
- Converts chat input to integer with `StringToInt()`
- Compares against `questionResult` global variable
- Special handling for zero answers: `strcmp(sArgs, "0") == 0`
- Awards credits immediately on correct answer

### Common Modification Patterns

#### Adding New Configuration Options
1. Create ConVar in `OnPluginStart()` with proper validation:
```sourcepawn
HookConVarChange(cvar = CreateConVar("sm_MathCredits_new_option", "default", "Description.", _, true, 1.0), CVAR_NewOption);
```
2. Add corresponding change hook function:
```sourcepawn
public void CVAR_NewOption(ConVar convar, const char[] oldValue, const char[] newValue)
{
    newOptionValue = convar.IntValue; // or FloatValue
}
```
3. Add global variable to store value
4. Use `AutoExecConfig(true)` to auto-generate config file

#### Modifying Question Logic
- Edit `CreateQuestion()` function
- **Critical**: Test division operator logic carefully - it generates `(random * nbr2) / nbr2` to ensure whole numbers
- Current operator selection: `operators[GetRandomInt(0,sizeof(operators)-1)]`
- Result calculation uses nested ternary for efficiency

#### Adding Translation Strings
1. Add to `shop_mathcredits.phrases.txt` following this format:
```
"StringKey"
{
    "#format" "{1:d},{2:s}" // specify parameter types
    "en" "English text with {1} and {2}"
    "ru" "Russian text with {1} and {2}"
}
```
2. Include both "en" and "ru" translations (required for this plugin)
3. Use proper format strings: `{1:d}` (integer), `{1:s}` (string), `{1:N}` (player name), `{1:f}` (float)

#### Sound Management
```sourcepawn
// OnMapStart() - precache and download
PrecacheSound(soundplay, true);
AddFileToDownloadsTable(Sound_download);

// Engine-specific path handling
strcopy(soundplay[view_as<int>(GetEngineVersion() == Engine_CSGO)], sizeof(soundplay), Sound_download[6]);
```
- Sounds must be precached in `OnMapStart()`
- Add to downloads table for client download
- Handle engine differences (CSGO vs others) - CSGO needs different path format

## Code Patterns & Architecture

### Unique Patterns in This Plugin

#### 1. Backward Loop Optimization
```sourcepawn
void SendEndQuestion(int client = 0)
{
    int i = MaxClients;
    while(i)
    {
        if(IsClientInGame(i)) 
        {
            // Process client
        }
        --i;
    }
}
```
- Loops from MaxClients down to 1 for efficiency
- Pre-decrement operator for performance

#### 2. String Array for Operators
```sourcepawn
char operators[][] = {PLUS, MINUS, DIVISOR, MULTIPL};
// Where: #define PLUS "+" etc.
```
- Uses 2D char array for operator storage
- Random selection with `sizeof(operators)-1`

#### 3. Conditional Sound Path Handling
```sourcepawn
char Sound_download[] = "sound/shop/Applause.mp3";
char soundplay[sizeof(Sound_download) - 5] = "*";
strcopy(soundplay[view_as<int>(GetEngineVersion() == Engine_CSGO)], sizeof(soundplay), Sound_download[6]);
```
- Different engines require different sound path formats
- CSGO needs path without "sound/" prefix
- Calculated at plugin start based on engine

#### 4. Nested Ternary for Math Operations
```sourcepawn
questionResult = strcmp(op, PLUS) ? strcmp(op, MINUS) ? nbr1 * nbr2:nbr1 - nbr2:nbr1 + nbr2;
```
- Efficient single-line calculation for +, -, *
- Division handled separately due to special logic

#### 5. Global State Management
- `questionResult`: Stores correct answer
- `timerQuestionEnd`: Handle for cleanup
- Configuration values cached in global variables
- No client-specific state (questions are server-wide)

### Manual Testing Checklist
- [ ] Plugin compiles without errors
- [ ] Questions generate correctly for all operators
- [ ] Timer system works (question timeout, next question scheduling)
- [ ] Credit awarding functions properly
- [ ] Translation strings display correctly
- [ ] Sound effects play for winners
- [ ] Configuration changes apply immediately

### Common Issues to Watch
- **Division by zero**: Code handles this by generating appropriate ranges
- **Timer cleanup**: Always `delete` timers when stopping them
- **Client validation**: Check `IsClientInGame()` before operations
- **Sound path handling**: Different engines require different path formats

## Integration Points

### Shop-Core Dependency
```sourcepawn
Shop_GiveClientCredits(client, credits);
```
- Ensure Shop-Core is loaded before this plugin
- Credits are awarded through the shop system

### MultiColors Dependency
```sourcepawn
CPrintToChat(i, "%t", "MathQuestion", nbr1, op, nbr2, credits);
```
- Provides colored chat functionality
- Translation strings include color codes (`{fullred}`, `{white}`)

## Performance Considerations

### Current Optimizations
- Efficient timer usage (single timer for questions, single timer for timeout)
- Minimal string operations
- Direct array access for operators
- Loop optimization in `SendEndQuestion()`

### Areas to Monitor
- Timer frequency (controlled by min/max question intervals)
- Client iteration loops (done backwards for efficiency)
- String operations in question generation

## Debugging Tips

### Common Issues & Solutions

1. **Timer not firing**
   - Check `TIMER_FLAG_NO_MAPCHANGE` usage
   - Verify timer cleanup: `delete timerQuestionEnd` sets to null
   - Map changes kill timers without the flag

2. **Credits not awarded**
   - Verify Shop-Core dependency loaded: `Shop_GiveClientCredits()` call
   - Check client validity with `IsClientInGame()`
   - Ensure question timer is active (`timerQuestionEnd != null`)

3. **Translations not loading**
   - File path: `addons/sourcemod/translations/shop_mathcredits.phrases.txt`
   - Ensure `LoadTranslations("shop_mathcredits.phrases")` in `OnPluginStart()`
   - Check format string parameters match function calls

4. **Sound not playing**
   - Verify precaching in `OnMapStart()`: `PrecacheSound(soundplay, true)`
   - Check download table: `AddFileToDownloadsTable(Sound_download)`
   - Engine-specific paths: CSGO vs other Source engines

5. **Math calculation errors**
   - Division logic: `(nbrmin/nbr2, nbrmax/nbr2) * nbr2` ensures whole numbers
   - Zero handling: Special case for `strcmp(sArgs, "0") == 0`
   - Operator string comparison uses `strcmp()` return values

### Testing Workflow

#### Manual Testing Steps
1. **Plugin Loading**: Check console for loading errors
2. **Configuration**: Verify ConVars created and respond to changes
3. **Question Generation**: 
   - Wait for first question (uses random timer)
   - Test all 4 operators appear
   - Verify division results are whole numbers
4. **Answer System**:
   - Test correct answers award credits
   - Test incorrect answers ignored
   - Test timeout functionality
5. **Sound & Chat**:
   - Winner sound plays
   - Colored chat messages display
   - Both languages work if available

#### Debug Console Commands
```
// Force plugin reload for testing
sm plugins reload Shop_MathCredits

// Check plugin status
sm plugins list | grep -i math

// Monitor ConVar values
sm_MathCredits_minimum_number
sm_MathCredits_maximum_number
sm_MathCredits_minimum_credits
sm_MathCredits_maximum_credits
sm_MathCredits_time_answer_questions
sm_MathCredits_time_minamid_questions
sm_MathCredits_time_maxamid_questions

// Check Shop-Core integration
shop_credits [player] // View credits
```

### Performance Monitoring

#### Timer Usage Patterns
- **Question Timer**: Single recurring timer, self-scheduling
- **Answer Timer**: Created per question, cleaned up on answer/timeout
- **Frequency**: Controlled by min/max question interval ConVars

#### Memory Considerations
- Global arrays are static (operators, sound paths)
- Timer handles properly cleaned with `delete`
- No dynamic memory allocation during runtime
- Translation strings cached by SourceMod

#### CPU Impact
- Minimal: Only active during question generation and answer checking
- Client iteration: O(n) where n = MaxClients
- String operations: Minimal (mostly integer comparisons)

## Version Management

- Current version: 1.2.1
- Version defined in plugin info structure
- Use semantic versioning for releases
- CI automatically creates releases from tags

## Security Considerations

- Input validation on chat commands (checks for numeric input only)
- No SQL injection risks (no database operations)
- File operations limited to sound precaching/downloads
- No admin-only functions exposed to regular users