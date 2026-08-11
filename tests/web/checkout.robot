*** Settings ***
Documentation    Checkout flow for the standard user, including the price
...              math the overview page shows before placing the order.
Resource         ../../resources/web_keywords.resource
Test Setup       Open Sauce Demo
Test Teardown    Close All Browsers

*** Test Cases ***
Completes An Order End To End
    Log In As    ${STANDARD_USER}    ${PASSWORD}
    Add First Item To Cart
    Go To Checkout
    Fill Checkout Information    Jean    Navarro    01310-100
    Finish Checkout
    Order Should Be Complete

Tax Is Calculated As Eight Percent Of The Subtotal
    Log In As    ${STANDARD_USER}    ${PASSWORD}
    Add First Item To Cart
    Go To Checkout
    Fill Checkout Information    Jean    Navarro    01310-100

    ${subtotal}    ${tax}    ${total}=    Get Price Breakdown
    ${expected_tax}=      Evaluate    round(${subtotal} * 0.08, 2)
    ${expected_total}=    Evaluate    ${subtotal} + ${tax}
    Should Be Equal As Numbers    ${tax}      ${expected_tax}
    Should Be Equal As Numbers    ${total}    ${expected_total}
