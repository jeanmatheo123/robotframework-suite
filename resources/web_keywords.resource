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
    # behaving unreliably in a containerized Linux CI runner — a purely local
    # Windows run never hits this, which is why it wasn't obvious until CI
    # actually ran it.
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

Click Via Javascript
    [Arguments]    ${selector}
    # a native WebDriver click resolves an element's bounding box and clicks
    # its center point — on this headless-Linux-CI setup, clicks on this SPA
    # have intermittently landed on nothing this way, for buttons all over
    # the app, not just one spot. Calling .click() through the DOM API
    # directly sidesteps that; it doesn't care where the element is drawn.
    Execute Javascript    document.querySelector("${selector}").click();

Type Via Javascript
    [Arguments]    ${data_test}    ${text}
    # sendKeys through Input Text has, on the same setup, left this
    # React-controlled field reading back empty — a keystroke-simulation
    # issue, not a focus one. Setting the value through React's own tracked
    # native setter and firing the events it listens for actually reaches
    # its state.
    Execute Javascript
    ...    var el = document.querySelector("[data-test='${data_test}']");
    ...    var setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
    ...    setter.call(el, "${text}");
    ...    el.dispatchEvent(new Event('input', { bubbles: true }));
    ...    el.dispatchEvent(new Event('change', { bubbles: true }));

Log In As
    [Arguments]    ${username}    ${password}
    Type Via Javascript     username    ${username}
    Type Via Javascript     password    ${password}
    Click Via Javascript    [data-test='login-button']
    # covers both outcomes so callers don't each need their own settle wait:
    # success renders the inventory page, a rejected login renders #error —
    # either one shows up only after the SPA finishes handling the click.
    Wait Until Page Contains Element    css:[data-test='inventory-container'], [data-test='error']

Login Error Should Contain
    [Arguments]    ${expected_text}
    # unlike Cypress/Playwright, SeleniumLibrary's "Should" keywords don't
    # retry — they check once, immediately. The error banner is rendered by a
    # client-side state update after the click, so this needs an explicit
    # wait instead of assuming it's already in the DOM.
    Wait Until Element Is Visible    css:[data-test='error']
    Element Should Contain           css:[data-test='error']    ${expected_text}

Add First Item To Cart
    Wait Until Page Contains Element    css:[data-test^='add-to-cart-']
    Click Via Javascript                [data-test^='add-to-cart-']

Cart Badge Should Show
    [Arguments]    ${count}
    Wait Until Element Is Visible    css:[data-test='shopping-cart-badge']
    Element Should Contain           css:[data-test='shopping-cart-badge']    ${count}

Go To Checkout
    Click Via Javascript    [data-test='shopping-cart-link']
    Wait Until Element Is Enabled    css:[data-test='checkout']
    Click Via Javascript            [data-test='checkout']
    Wait Until Location Contains    checkout-step-one.html

Fill Checkout Information
    [Arguments]    ${first_name}    ${last_name}    ${postal_code}
    Wait Until Element Is Enabled    css:[data-test='firstName']
    Type Via Javascript    firstName      ${first_name}
    Type Via Javascript    lastName       ${last_name}
    Type Via Javascript    postalCode     ${postal_code}
    # a direct, immediate check here fails with an honest message right at
    # the actual problem, instead of a confusing "didn't navigate" error
    # three steps downstream if a field silently didn't take the input.
    ${actual_first_name}=    Get Value    css:[data-test='firstName']
    Should Be Equal    ${actual_first_name}    ${first_name}
    Click Via Javascript    [data-test='continue']
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
    Click Via Javascript            [data-test='finish']
    Wait Until Location Contains     checkout-complete.html

Order Should Be Complete
    Wait Until Element Is Visible    css:[data-test='complete-header']
    Element Should Contain           css:[data-test='complete-header']    Thank you for your order!
