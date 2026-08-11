*** Settings ***
Documentation    Full CRUD lifecycle against the restful-booker API, plus the
...              auth checks that gate the write operations.
Resource         ../../resources/api_keywords.resource
Suite Setup      Create Booker Session

*** Test Cases ***
Health Check Responds
    ${response}=    GET On Session    booker    /ping    expected_status=201

Auth Returns A Token For Valid Credentials
    ${token}=    Authenticate And Get Token
    Should Not Be Empty    ${token}

Auth Rejects Wrong Credentials
    ${body}=    Create Dictionary    username=admin    password=definitely-wrong
    ${response}=    POST On Session    booker    /auth    json=${body}
    Should Be Equal As Integers    ${response.status_code}    200
    Dictionary Should Contain Key    ${response.json()}    reason

Full Booking Lifecycle: Create, Read, Update, Delete
    ${token}=    Authenticate And Get Token
    ${payload}=    Build Booking Payload

    # create — no auth required for this one
    ${create_response}=    POST On Session    booker    /booking    json=${payload}
    Should Be Equal As Integers    ${create_response.status_code}    200
    ${booking_id}=    Set Variable    ${create_response.json()}[bookingid]
    Dictionary Should Contain Item    ${create_response.json()}[booking]    firstname    Jean

    # read
    ${get_response}=    GET On Session    booker    /booking/${booking_id}
    Should Be Equal    ${get_response.json()}[lastname]    Navarro

    # update — requires the auth cookie
    ${updated_payload}=    Build Booking Payload    price=200
    ${put_response}=    PUT On Session    booker    /booking/${booking_id}
    ...    json=${updated_payload}    cookies=${{ {'token': $token} }}
    Should Be Equal As Integers    ${put_response.status_code}    200
    Should Be Equal As Integers    ${put_response.json()}[totalprice]    200

    # delete — also requires the auth cookie
    ${delete_response}=    DELETE On Session    booker    /booking/${booking_id}
    ...    cookies=${{ {'token': $token} }}    expected_status=201

    # confirm it's actually gone
    GET On Session    booker    /booking/${booking_id}    expected_status=404

Update Without A Token Is Rejected
    ${payload}=    Build Booking Payload
    ${create_response}=    POST On Session    booker    /booking    json=${payload}
    ${booking_id}=    Set Variable    ${create_response.json()}[bookingid]

    ${response}=    PUT On Session    booker    /booking/${booking_id}
    ...    json=${payload}    expected_status=403

    # clean up using a real token since this booking did get created
    ${token}=    Authenticate And Get Token
    DELETE On Session    booker    /booking/${booking_id}    cookies=${{ {'token': $token} }}    expected_status=201
