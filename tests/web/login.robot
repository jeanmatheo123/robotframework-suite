*** Settings ***
Documentation    Login scenarios against Sauce Demo's fixed set of test accounts.
Resource         ../../resources/web_keywords.resource
Test Setup       Open Sauce Demo
Test Teardown    Close All Browsers

*** Test Cases ***
Standard User Can Log In
    Log In As    ${STANDARD_USER}    ${PASSWORD}
    Location Should Contain    inventory.html

Locked Out User Is Rejected
    Log In As    ${LOCKED_USER}    ${PASSWORD}
    Login Error Should Contain    Sorry, this user has been locked out

Wrong Password Is Rejected
    Log In As    ${STANDARD_USER}    not-the-real-password
    Login Error Should Contain    do not match any user in this service

Empty Username Is Rejected Client Side
    Click Via Javascript    [data-test='login-button']
    Login Error Should Contain    Username is required
