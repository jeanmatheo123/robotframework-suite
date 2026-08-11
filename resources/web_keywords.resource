*** Settings ***
Library    SeleniumLibrary

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
    Open Browser    ${BASE_URL}    ${BROWSER}
    Set Window Size    1366    768
    Set Selenium Timeout    10s
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
    Click Button    xpath://div[@class='inventory_item'][1]//button

Cart Badge Should Show
    [Arguments]    ${count}
    Wait Until Element Is Visible    css:[data-test='shopping-cart-badge']
    Element Should Contain           css:[data-test='shopping-cart-badge']    ${count}
