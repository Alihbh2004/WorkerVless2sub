from playwright.sync_api import sync_playwright
import time
import os

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context(viewport={'width': 1280, 'height': 800})
    page = context.new_page()

    # Increase timeout just in case
    page.set_default_timeout(30000)

    print("Navigating to http://localhost:5173")
    try:
        page.goto("http://localhost:5173")

        # Wait for the main title to be visible
        print("Waiting for title...")
        page.wait_for_selector("text=ALI HABIBZADEH")

        # Wait a bit for animations and 3D scene to initialize
        print("Waiting for animations...")
        time.sleep(5)

        # Take a screenshot of the Hero section
        print("Taking hero screenshot...")
        os.makedirs("verification", exist_ok=True)
        page.screenshot(path="verification/hero.png")

        # Scroll down to About section
        print("Scrolling to About...")
        page.locator("#about").scroll_into_view_if_needed()
        time.sleep(2)
        page.screenshot(path="verification/about.png")

        # Scroll to Skills
        print("Scrolling to Skills...")
        page.locator("#skills").scroll_into_view_if_needed()
        time.sleep(2)
        page.screenshot(path="verification/skills.png")

        # Scroll to Contact
        print("Scrolling to Contact...")
        page.locator("#contact").scroll_into_view_if_needed()
        time.sleep(2)
        page.screenshot(path="verification/contact.png")

        print("Verification complete!")

    except Exception as e:
        print(f"Error: {e}")
        # Take screenshot on failure
        page.screenshot(path="verification/error.png")
        raise e
    finally:
        browser.close()

if __name__ == "__main__":
    with sync_playwright() as playwright:
        run(playwright)
