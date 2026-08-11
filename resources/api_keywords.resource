*** Settings ***
Library    RequestsLibrary
Library    Collections

*** Variables ***
${BOOKER_URL}    https://restful-booker.herokuapp.com

*** Keywords ***
Create Booker Session
    # robotframework-requests defaults Create Session to verify=False —
    # unlike plain Python requests, which verifies by default. The site's
    # certificate is fine, so there's no reason to actually skip verification.
    Create Session    booker    ${BOOKER_URL}    verify=${True}

Authenticate And Get Token
    ${body}=    Create Dictionary    username=admin    password=password123
    ${response}=    POST On Session    booker    /auth    json=${body}
    Should Be Equal As Integers    ${response.status_code}    200
    RETURN    ${response.json()}[token]

Build Booking Payload
    [Arguments]    ${firstname}=Jean    ${lastname}=Navarro    ${price}=150
    ${dates}=    Create Dictionary    checkin=2026-09-01    checkout=2026-09-05
    ${booking}=    Create Dictionary
    ...    firstname=${firstname}
    ...    lastname=${lastname}
    ...    totalprice=${price}
    ...    depositpaid=${True}
    ...    bookingdates=${dates}
    ...    additionalneeds=Breakfast
    RETURN    ${booking}
