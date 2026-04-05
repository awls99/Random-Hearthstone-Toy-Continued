# Hearthstone Localization Update Instructions

## Context
This is a World of Warcraft addon that maintains a list of Hearthstone items across multiple languages. The addon uses Lua files with the naming pattern `AllHearthToyIndex_XX.lua` where `XX` is the language code.

## File Structure
Each language file contains a Lua table mapping item IDs to spell IDs and localized names:
```lua
[ITEM_ID] = { spellId = SPELL_ID, name = "Localized Name" },
```

## Language Files
- `AllHearthToyIndex_en.lua` - English (reference/master)
- `AllHearthToyIndex_de.lua` - German (de)
- `AllHearthToyIndex_es.lua` - Spanish (es)
- `AllHearthToyIndex_fr.lua` - French (fr)
- `AllHearthToyIndex_ko.lua` - Korean (ko)
- `AllHearthToyIndex_ru.lua` - Russian (ru)
- `AllHearthToyIndex_cn.lua` - Chinese Simplified (cn)
- `AllHearthToyIndex_tw.lua` - Chinese Traditional (tw)
- `AllHearthToyIndex_pt.lua` - Portuguese (pt)

## Update Process

### Step 1: Identify New Items
Check the English file (`AllHearthToyIndex_en.lua`) to identify which items are new. These will typically be at the end of the list.

For each new item, note:
- **Item ID**: The number in brackets `[ITEM_ID]`
- **Spell ID**: The number after `spellId =`
- **English Name**: The string after `name =`

Example:
```lua
[263933] = { spellId = 1270814, name = "Preyseeker's Hearthstone" },
```
- Item ID: `263933`
- Spell ID: `1270814`
- English Name: "Preyseeker's Hearthstone"

### Step 2: Get Localized Names from Wowhead
**CRITICAL**: You must use Wowhead to get the CORRECT localized names. NEVER translate names yourself.

For each language and each new item:
1. Construct the Wowhead URL: `https://XX.wowhead.com/item=ITEM_ID`
   - Replace `XX` with the language code (de, es, fr, ko, ru, cn, tw, pt)
   - Replace `ITEM_ID` with the actual item ID

2. Visit the URL and extract the localized name from:
   - The page title (shows in browser tab)
   - The URL slug (the last part of the URL after the item ID)
   - The main heading on the page

**Language-specific Wowhead URLs:**
- German: `https://de.wowhead.com/item=ITEM_ID`
- Spanish: `https://es.wowhead.com/item=ITEM_ID`
- French: `https://fr.wowhead.com/item=ITEM_ID`
- Korean: `https://ko.wowhead.com/item=ITEM_ID`
- Russian: `https://ru.wowhead.com/item=ITEM_ID`
- Chinese Simplified: `https://cn.wowhead.com/item=ITEM_ID`
- Chinese Traditional: `https://tw.wowhead.com/item=ITEM_ID`
- Portuguese: `https://pt.wowhead.com/item=ITEM_ID`

### Step 3: Update Each Language File
For each language file, add the new entries following the existing pattern:

1. Read the current file to understand its format
2. Add new entries at the end, before the closing brace `}`
3. Maintain consistent formatting with the existing entries
4. Include proper spacing/indentation

Example entry format:
```lua
[263933] = { spellId = 1270814, name = "Localized Name Here"},
```

### Step 4: Verify Updates
After updating all files:
1. Double-check that each new item has been added to ALL language files
2. Verify that item IDs and spell IDs match across all languages
3. Ensure the localized names are correctly obtained from Wowhead
4. Check that Lua syntax is valid (balanced braces, proper commas)

## Common Pitfalls to Avoid

1. **NEVER translate names yourself** - Always use Wowhead for official localized names
2. **Don't mix up item IDs and spell IDs** - These are different numbers
3. **Don't forget any language files** - All 9 files should be updated
4. **Maintain consistent formatting** - Match the existing style in each file
5. **Check for special characters** - Some languages use special characters that need proper encoding

## Example Workflow

If the English file has these new entries:
```lua
[263933] = { spellId = 1270814, name = "Preyseeker's Hearthstone" },
[257736] = { spellId = 1261979, name = "Lightcalled Hearthstone" },
```

You would:
1. Visit `https://de.wowhead.com/item=263933` → get "Ruhestein des Beutesuchers"
2. Visit `https://de.wowhead.com/item=257736` → get "Lichtgerufener Ruhestein"
3. Add to German file:
```lua
[263933] = { spellId = 1270814, name = "Ruhestein des Beutesuchers"},
[257736] = { spellId = 1261979, name = "Lichtgerufener Ruhestein"},
```
4. Repeat steps 1-3 for all other languages (es, fr, ko, ru, cn, tw, pt)

## Testing
After updates are complete, the addon should:
- Load without Lua syntax errors
- Display all Hearthstone names correctly in each locale
- Maintain the same item IDs and spell IDs across all languages

## Notes
- The English file (`AllHearthToyIndex_en.lua`) serves as the reference/master
- Item IDs and spell IDs must be identical across all language files
- Only the `name` field should differ between languages
- Some items may be commented out due to bugs - respect these comments