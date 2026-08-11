*** Settings ***
Library    SeleniumLibrary
Library    String

*** Variables ***
${BASE_URL}         https://www.saucedemo.com
${BROWSER}          headlesschrome
${STANDARD_USER}    standard_user
${LOCKED_USER}      locked_out_user
${PASSWORD}         secret_sauce

*** Keywords ***
Open Sauce Demo
    # A fresh browser per test, rather than one shared across a whole suite,
    # trades a little speed for guaranteeing no state (cookies, JS memory,
    # a half-finished previous interaction) leaks from one test into the next.
    # --no-sandbox and --disable-dev-shm-usage are the standard fix for Chrome
    # behaving unreliably (crashes, clicks that silently don't register) in a
    # containerized Linux CI runner — a purely local Windows run never hits
    # this, which is exactly why it wasn't obvious until CI actually ran it.
    Open Browser    ${BASE_URL}    ${BROWSER}
    ...    options=add_argument("--no-sandbox");add_argument("--disable-dev-shm-usage");add_argument("--disable-gpu")
    Set Window Size    1366    768
    # generous on purpose: shared CI runners are noticeably slower/noisier
    # than a local dev machine, and a fresh headless Chrome + SPA hydration
    # on every single test needs more headroom there than 10s reliably gives
    Set Selenium Timeout    20s
    # Sauce Demo is a client-rendered SPA — the button exists in the DOM as
    # soon as the page responds, but its click handler isn't wired up until
    # the JS bundle finishes hydrating, so wait for that before doing anything.
    Wait Until Element Is Enabled    css:[data-test='login-button']

Log In As
    [Arguments]    ${username}    ${password}
    Input Text      css:[data-test='username']    ${username}
    Input Text      css:[data-test='password']     ${password}
    Click Button    css:[data-test='login-button']

Login Error Should Contain
    [Arguments]    ${expected_text}
    # unlike Cypress/Playwright, SeleniumLibrary's "Should" keywords don't
    # retry — they check once, immediately. The error banner is rendered by a
    # client-side state update after the click, so this needs an explicit
    # wait instead of assuming it's already in the DOM.
    Wait Until Element Is Visible    css:[data-test='error']
    Element Should Contain           css:[data-test='error']    ${expected_text}

Add First Item To Cart
    Wait Until Element Is Enabled    xpath://div[@class='inventory_item'][1]//button
    Click Button                     xpath://div[@class='inventory_item'][1]//button

Cart Badge Should Show
    [Arguments]    ${count}
    Wait Until Element Is Visible    css:[data-test='shopping-cart-badge']
    Element Should Contain           css:[data-test='shopping-cart-badge']    ${count}

Go To Checkout
    Click Element    css:[data-test='shopping-cart-link']
    # matches the same class of hydration race the login button has: the
    # button is visible in the DOM before its React click handler is
    # actually wired up, so this test occasionally clicked before Sauce
    # Demo's SPA was ready to respond to it — waiting for "enabled" rather
    # than just "visible" is what fixed the equivalent issue on the login
    # page, and this closed the same gap in the wait chain.
    Wait Until Element Is Enabled    css:[data-test='checkout']
    # a condition wait alone still isn't fully reliable against this SPA —
    # "enabled" can be true a beat before the click handler actually does
    # anything. A short fixed pause here is a deliberate belt-and-suspenders
    # addition on top of the condition wait, not a replacement for it.
    Sleep    0.3s
    Click Button                     css:[data-test='checkout']
    Wait Until Location Contains     checkout-step-one.html

Fill Checkout Information
    [Arguments]    ${first_name}    ${last_name}    ${postal_code}
    Wait Until Element Is Enabled    css:[data-test='firstName']
    Input Text      css:[data-test='firstName']      ${first_name}
    Input Text      css:[data-test='lastName']       ${last_name}
    Input Text      css:[data-test='postalCode']     ${postal_code}
    Sleep    0.3s
    Click Button    css:[data-test='continue']
    Wait Until Location Contains    checkout-step-two.html

Get Price Breakdown
    ${subtotal_text}=    Get Text    css:[data-test='subtotal-label']
    ${tax_text}=          Get Text    css:[data-test='tax-label']
    ${total_text}=        Get Text    css:[data-test='total-label']
    ${subtotal}=    Fetch From Right    ${subtotal_text}    $
    ${tax}=          Fetch From Right    ${tax_text}    $
    ${total}=        Fetch From Right    ${total_text}    $
    RETURN    ${subtotal}    ${tax}    ${total}

Finish Checkout
    Wait Until Element Is Enabled    css:[data-test='finish']
    Sleep    0.3s
    Click Button                     css:[data-test='finish']
    Wait Until Location Contains     checkout-complete.html

Order Should Be Complete
    Wait Until Element Is Visible    css:[data-test='complete-header']
    Element Should Contain           css:[data-test='complete-header']    Thank you for your order!
