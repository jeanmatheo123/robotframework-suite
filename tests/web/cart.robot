*** Settings ***
Documentation    Cart behaviour after logging in as the standard user.
Resource         ../../resources/web_keywords.resource
Test Setup       Open Sauce Demo
Test Teardown    Close All Browsers

*** Test Cases ***
Adding An Item Updates The Cart Badge
    Log In As    ${STANDARD_USER}    ${PASSWORD}
    Location Should Contain    inventory.html
    Add First Item To Cart
    Cart Badge Should Show    1

Cart Contents Persist Into The Cart Page
    Log In As    ${STANDARD_USER}    ${PASSWORD}
    Add First Item To Cart
    Click Element    css:[data-test='shopping-cart-link']
    Location Should Contain    cart.html
    Page Should Contain Element    css:[data-test='inventory-item']
