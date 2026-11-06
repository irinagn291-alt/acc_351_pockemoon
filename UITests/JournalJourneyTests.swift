import XCTest

final class JournalJourneyTests: XCTestCase {
    private struct Seed: Decodable {
        let code: String
        let product_name: String?
        let product_name_en: String?
        var name: String { product_name_en ?? product_name ?? "" }
    }
    private struct Shelf: Decodable { let products: [Seed] }

    @MainActor
    func testLogEditAndReopen() throws {
        continueAfterFailure = false
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "OfflineProducts", withExtension: "json"))
        let products = try JSONDecoder().decode(Shelf.self, from: Data(contentsOf: url)).products
        let first = try XCTUnwrap(products.first { !$0.name.isEmpty })
        let second = try XCTUnwrap(products.first { $0.code != first.code && !$0.name.isEmpty })
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["Add food"].waitForExistence(timeout: 15))
        capture(app, "01-empty-journal")

        func add(_ food: Seed, _ size: String, _ meal: String) {
            app.buttons["Add food"].tap()
            let search = app.textFields["Name, brand or barcode"]
            XCTAssertTrue(search.waitForExistence(timeout: 15))
            if food.code == first.code { capture(app, "02-food-catalog") }
            search.tap()
            search.typeText(food.code)
            let item = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", food.name)).firstMatch
            XCTAssertTrue(item.waitForExistence(timeout: 15))
            item.tap()
            let weight = app.buttons[size]
            XCTAssertTrue(weight.waitForExistence(timeout: 18))
            weight.tap()
            app.segmentedControls.buttons[meal].tap()
            if food.code == first.code { capture(app, "03-portion-editor") }
            app.buttons["Log portion"].tap()
            XCTAssertTrue(app.buttons["Add food"].waitForExistence(timeout: 15))
        }
        add(first, "150 g", "Breakfast")
        add(second, "100 g", "Lunch")

        let row = app.buttons["meal-" + first.code].firstMatch
        XCTAssertTrue(row.exists)
        if !row.isHittable { app.swipeUp() }
        row.tap()
        XCTAssertTrue(app.buttons["250 g"].waitForExistence(timeout: 15))
        app.buttons["250 g"].tap()
        app.buttons["Save changes"].tap()

        app.terminate()
        app.launch()
        let edited = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "meal-" + first.code, "250 g")).firstMatch
        XCTAssertTrue(edited.waitForExistence(timeout: 18), "Edited portion persists after restart")
        selectTab("Trends", in: app)
        XCTAssertTrue(app.staticTexts["Daily log"].waitForExistence(timeout: 5))
        capture(app, "04-trends")
        selectTab("Profile", in: app)
        let goal = app.textFields["Personal calorie target"]
        XCTAssertTrue(goal.waitForExistence(timeout: 5))
        goal.tap()
        goal.typeText("2100")
        app.buttons["Save target"].tap()
        XCTAssertTrue(app.buttons["Saved"].waitForExistence(timeout: 5))
        selectTab("Journal", in: app)
        XCTAssertTrue(app.buttons["Add food"].waitForExistence(timeout: 5))
        selectTab("Profile", in: app)
        XCTAssertEqual(app.textFields["Personal calorie target"].value as? String, "2100")
        capture(app, "05-profile")
        selectTab("Journal", in: app)
        app.swipeDown()
        capture(app, "06-journal")
        app.buttons["Choose date"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
        capture(app, "07-calendar")
        app.buttons["Done"].tap()
        app.buttons["Add food"].tap()
        let manual = app.buttons["Enter label by hand"]
        for _ in 0..<8 {
            if manual.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(manual.isHittable)
        manual.tap()
        XCTAssertTrue(app.textFields["Product name"].waitForExistence(timeout: 5))
        capture(app, "08-manual-label")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Add food"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Personal target · 2,100 kcal"].exists)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "PockeMoon-preview"
        image.lifetime = .keepAlways
        self.add(image)
    }

    @MainActor
    func testCancelPortion() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["Add food"].waitForExistence(timeout: 15))
        app.buttons["Add food"].tap()
        let search = app.textFields["Name, brand or barcode"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("3168930003632")
        let food = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Quaker Oats")).firstMatch
        XCTAssertTrue(food.waitForExistence(timeout: 10))
        food.tap()
        XCTAssertTrue(app.buttons["Log portion"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Close"].isHittable)
        capture(app, "09-portion-close")
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Add food"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["meal-3168930003632"].exists)
    }

    @MainActor
    private func selectTab(_ name: String, in app: XCUIApplication) {
        let phoneTab = app.tabBars.buttons[name]
        if phoneTab.exists {
            phoneTab.tap()
        } else {
            // iPadOS exposes its top tab strip as cells instead of a TabBar.
            let tab = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", name))
                .allElementsBoundByIndex.first { $0.isHittable }
            XCTAssertNotNil(tab, "Expected a visible \(name) tab")
            tab?.tap()
        }
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }

}
