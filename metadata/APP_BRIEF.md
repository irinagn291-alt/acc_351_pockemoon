<!-- gf-brief source=d23b16fc49ad286d42b1bba56a54f0f79ae1be0eab6e5273017d6453bbed7a2b written=2026-11-07T00:29:28+03:00 -->
# PockeMoon

## What it is

PockeMoon is a food journal for logging portions and viewing daily calories and macronutrients. It is for people who want to record meals, optionally set a daily calorie target, and review their weekly history.

## Launch and onboarding

On a normal cold launch, the app opens directly to the “Journal” tab for today. There is no onboarding or account setup.

The screen shows “PockeMoon”, “FOOD JOURNAL”, today’s date, “Today’s nutrition” and “Good habits, one portion at a time.” A new journal starts with zero totals and the empty state “Your first portion” and “Search for a food or scan the barcode on its packaging to start your log.” Tap “Add food” to begin.

## Screens

### “Journal”

The date control, accessible as “Choose date”, opens “Journal date”; select today or an earlier date and tap “Done”. Today is titled “Today’s nutrition”; an earlier date is titled “Daily journal”.

“Daily energy” shows calories, the number of portions and, if set, progress toward “Personal target”. Without a target it says “A little awareness, every day.” The “Protein”, “Fat” and “Carbs” tiles show totals. When values are missing, the screen says “Some labels have missing values. Totals include the nutrients reported.” and labels energy “kcal · reported values”.

“Add food” opens “Food catalog”. “Meal timeline” groups logged entries under “Breakfast”, “Lunch”, “Dinner” and “Snack”; tapping an entry opens it for editing. “Repeat a portion” lists up to five recent distinct foods; tapping one opens a new portion with its previous weight and meal.

### “Food catalog”

“Name, brand or barcode” filters foods on the device as text is entered. “Clear search” clears the field. “Search Open Food Facts” searches the online catalog; the keyboard search action does the same. Results appear under “On this device” or “Search results”, with product name, brand when available, and calories per 100 g. Tapping a product opens a new portion.

“Scan a barcode”, accompanied by “Find the label on your package”, opens “Barcode scanner”. “Enter label by hand” opens “New product”. “Close” returns to the journal.

The footer says “Product data comes from Open Food Facts contributors. Check the package for the current ingredients.” The link “Open Food Facts · Data ODbL · Photos CC BY-SA” opens the data and photo terms.

### “Barcode scanner”

The scanner says “Point the camera at the product barcode”. A recognized suitable code returns to the catalog and searches it. “Close” returns to the catalog.

If scanning is unavailable, “Scanner unavailable” appears with an explanation. “Back to search” returns to the catalog; “Open Settings” is offered when camera access has been denied.

### “New product”

Under “Product”, enter “Product name” and optionally “Brand”. Under “Per 100 g”, enter any available “Energy, kcal”, “Protein, g”, “Carbohydrates, g” and “Fat, g” values. The form says “Leave a field empty if the value is missing from the label.” Under “Ingredients”, “Ingredient list from the package” accepts optional text.

“Use this product” saves the product for selection and opens a new portion. The navigation back control returns to the catalog.

### “NEW PORTION” and “EDIT PORTION”

The portion screen shows the product name and brand, “Portion weight”, a weight field accessible as “Portion weight in grams”, and shortcuts “50 g”, “100 g”, “150 g” and “250 g”. It calculates “Portion energy” and “P”, “F” and “C” values for a valid weight.

Under “Meal & time”, “Meal” selects “Breakfast”, “Lunch”, “Dinner” or “Snack”; “Date and time” selects a time no later than the present. “Done” dismisses the weight keyboard. “Close” dismisses the editor without saving.

“Log portion” adds a new entry; “Save changes” updates an existing entry. For an existing entry, “Delete entry” opens “Delete this portion from your journal?” with “Delete” and “Cancel”.

### “Trends”

“Trends” says “See the rhythm of your week.” “Previous week” and “Next week” move between weeks. “Days logged” and “Portions” summarize the selected week, and “Energy this week” charts calories by day. Tapping an available day in the chart opens that day in “Journal”, as indicated by “Tap a day to explore its meals.”

“Daily log” lists available days with either “No entries” or a portion count and calorie total. Tapping a day opens it in “Journal”.

### “Profile”

“Your rhythm” says “A journal that works your way.” Under “Personal target”, the “Personal calorie target” field has the placeholder “No target”. “Save target” saves a whole-number daily calorie target or clears it when the field is blank; after saving, it says “Saved”.

“With you, on your wrist” explains: “Your journal stays on this device. Your paired Apple Watch receives today’s totals and your recent portions.” “Open Food Facts catalog” opens the catalog website. The screen also says “Nutrient totals scale with portion weight. A dash means the label has no value for that nutrient.”

### Apple Watch

“PockeMoon” shows “FOOD JOURNAL”, today’s calories and portion count, target progress when set, and “Includes known values only” when totals are incomplete. “Repeat a portion” lists recent foods. Tapping one opens a sheet with “Log for today” and “Cancel”; logging sends the repeated portion to the iPhone or queues it until synchronization.

### Home Screen widget

The small and medium “PockeMoon” widgets show “DAILY RHYTHM”, today’s calories, portion count and optional target progress. The medium widget also shows “MACROS”: “Protein”, “Fat” and “Carbs”. Incomplete calories are labelled “kcal · partial total”.

## Features

- Log food portions by searching “Food catalog”, scanning a package barcode or using “Enter label by hand”.
- Record portion weight, meal and date and time; edit, delete or repeat portions.
- View “Daily energy”, “Protein”, “Fat”, “Carbs” and a “Meal timeline”.
- Set an optional “Personal target”.
- Review weekly “Trends” and open days from the chart or “Daily log”.
- View today’s totals and repeat recent portions on Apple Watch.
- View today’s calories and macros in a Home Screen widget.

## Behaviours that can look like bugs

- “Search Open Food Facts” is disabled until the search has at least two characters, and while a search is running. Local matches can still appear as the user types.
- With no local matches, the catalog says “No matches on this device. Search Open Food Facts or enter the details from the label.” An online search can say “No matches in Open Food Facts.” Search another term or use “Enter label by hand”.
- An unknown barcode can produce “This barcode isn’t in the catalog yet.” Other catalog messages include “The catalog is limiting requests. Try again in a minute.”, “Couldn’t load the product data. Try again.” and “Couldn’t reach the catalog. Use a saved product or enter the label by hand.”
- “Use this product” is disabled until “Product name” is filled in and any entered nutrient values are valid: energy must be 0–1,000 kcal per 100 g and each macronutrient 0–100 g. Nutrient fields may be left empty.
- “Log portion” and “Save changes” are disabled for an invalid weight. The screen says “Enter a weight greater than zero and no more than 10,000 g.” Enter a valid weight or use a weight shortcut.
- “Save target” is disabled for an invalid value and shows “Enter a whole number from 1 to 20,000.” Enter a value in that range or leave the field blank.
- “Next week” is disabled in the current week. Future days cannot be opened, and dates and times cannot be set in the future.
- Missing nutrient values appear as “—”; totals use the values that are available. Enter missing values from the package when creating a product if they are known.
- On Apple Watch, the initial “Repeat a portion” area says “Log your first portion in the iPhone journal.” After a portion is logged and synchronized, recent foods appear. A repeat may say “Portion queued. Your iPhone will log it when it syncs.”
- If journal storage fails, a “Journal” alert can say “Couldn’t open your journal. Restart the app to try again.”, “Journal storage is unavailable. Restart the app to try again.” or “Couldn’t save your changes. Check available storage and try again.” Dismiss it with “OK” and follow the message.

## Starter content and resume

A new journal has no logged portions or target. The food catalog includes an offline starter selection, and products found or entered are retained for later selection. Logged entries and the target persist between launches. An unsaved portion or product form is not presented as a resumable draft.

## Permissions

Camera access is requested when the user opens “Scan a barcode” for the first time on a supported device. The usage description is “Scan the barcode on a package to look up its food label.”

## Absent

Login or accounts, in-app purchases, ads, analytics, an account deletion flow and an App Tracking Transparency prompt are absent. The user can create food labels and journal entries locally; there is no visible feature for publishing them to other users.

## Data and support

The journal and target stay on the device and are shared with the paired Apple Watch and the app’s widget. Catalog searches and barcode lookups contact Open Food Facts, and product images may load from the internet. There is no on-screen Contact or Support control.

## Scanning and health

The scanner accepts common retail barcodes and QR codes, but uses a recognized payload only when it contains an 8–14 digit code suitable for a product lookup. A 12-digit code is normalized for lookup. If scanning is unavailable, users can type the digits in the search field.

The app shows food-label calories and macronutrients, scaled to the portion weight, and an optional user-set calorie target. It does not show medical advice or product-health ratings. The catalog attributes product data to Open Food Facts contributors and links to its data and photo terms; it advises checking the package for current ingredients.

## Platform

The app supports iPhone and iPad on iOS 17.0 or later, with a companion app for Apple Watch on watchOS 10.0 or later. iPhone supports portrait and both landscape orientations; iPad also supports upside-down portrait.

The interface is in English, with dates and numbers displayed using English formatting in the principal journal controls. The journal uses the device’s local calendar for days and meal timing; weekly trends run Monday through Sunday. No region-specific restrictions are shown.

## Category

Food & Drink.
